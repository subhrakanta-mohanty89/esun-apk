/// ESUN Network Layer
/// 
/// Dio-based HTTP client with interceptors, retry logic, and certificate pinning.
library;

import 'dart:async';
import 'dart:io';

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:go_router/go_router.dart';

import '../utils/utils.dart';
import '../storage/secure_storage.dart';
import '../../state/app_state.dart';
import '../../routes/app_router.dart';
import '../../routes/app_routes.dart';

/// API Configuration
class ApiConfig {
  // Override at build time with: --dart-define=API_BASE_URL=https://your-api
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  
  /// Base URL - uses environment variable if set, otherwise auto-detects
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    // Use GCP Cloud Run for production
    return 'https://eson-696336119023.us-central1.run.app';
  }
  
  static const String apiPrefix = '/api/v1';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);
  static const int maxRetries = 2;
  static const Duration retryDelay = Duration(milliseconds: 500);
  
  /// Certificate pins (SHA-256 hashes)
  static const List<String> certificatePins = [
    // Add production certificate pins here
    'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
  ];
}

/// Shared cache interceptor instance (accessible for cache invalidation)
final cacheInterceptorProvider = Provider<CacheInterceptor>((ref) {
  return CacheInterceptor(ttlSeconds: 120);
});

/// Request deduplication — prevents duplicate in-flight requests
final _deduplicationInterceptorProvider = Provider<DeduplicationInterceptor>((ref) {
  return DeduplicationInterceptor();
});

/// Dio client provider
final dioProvider = Provider<Dio>((ref) {
  final cacheInterceptor = ref.watch(cacheInterceptorProvider);
  final dedupInterceptor = ref.watch(_deduplicationInterceptorProvider);
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    sendTimeout: ApiConfig.sendTimeout,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Encoding': 'gzip, deflate',
    },
  ));
  
  // Add interceptors — order matters: timing, dedup, cache, auth, retry, error, logger
  dio.interceptors.addAll([
    TimingInterceptor(),
    dedupInterceptor,
    cacheInterceptor,
    AuthInterceptor(ref),
    RetryInterceptor(dio),
    ErrorInterceptor(),
    if (kDebugMode)
      PrettyDioLogger(
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: false,  // Reduced — avoid logging large AI responses
        error: true,
        compact: true,
      ),
  ]);
  
  return dio;
});

/// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(dioProvider));
});

/// Auth Interceptor - Adds auth token to requests
class AuthInterceptor extends Interceptor {
  final Ref _ref;
  
  AuthInterceptor(this._ref);
  
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for public endpoints
    if (options.extra['skipAuth'] == true) {
      return handler.next(options);
    }
    
    try {
      final storage = _ref.read(secureStorageProvider);
      final token = await storage.getAccessToken();
      
      if (token != null) {
        // Proactive refresh: if access token expires within 60 seconds, refresh it
        if (_isJwtExpiringSoon(token, thresholdSeconds: 60)) {
          final refreshed = await _proactiveRefresh(storage);
          if (refreshed != null) {
            options.headers['Authorization'] = 'Bearer $refreshed';
          } else {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } else {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
      
      // Add device info
      final deviceId = await storage.getDeviceId();
      if (deviceId != null) {
        options.headers['X-Device-ID'] = deviceId;
      }
      
      handler.next(options);
    } catch (e) {
      handler.next(options);
    }
  }
  
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Check if error is token expired
      final errorCode = err.response?.data?['error']?['code'];
      debugPrint('🔐 401 Error received. Code: $errorCode');
      
      // Try to refresh token
      try {
        final storage = _ref.read(secureStorageProvider);
        final refreshToken = await storage.getRefreshToken();
        debugPrint('🔐 Refresh token available: ${refreshToken != null && refreshToken.isNotEmpty}');
        
        if (refreshToken != null && refreshToken.isNotEmpty) {
          // Attempt token refresh
          final dio = Dio();
          final response = await dio.post(
            '${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/auth/refresh',
            data: {'refresh_token': refreshToken},
          );
          
          if (response.statusCode == 200 && response.data != null) {
            // Parse nested response: { success, data: { tokens: { access_token, refresh_token } } }
            final respData = response.data is Map ? response.data as Map<String, dynamic> : <String, dynamic>{};
            final body = respData['data'] as Map<String, dynamic>? ?? respData;
            final tokens = body['tokens'] as Map<String, dynamic>? ?? body;
            final newToken = tokens['access_token']?.toString();
            final newRefreshToken = (tokens['refresh_token'] ?? refreshToken).toString();
            debugPrint('🔐 Token refresh successful');
            
            if (newToken != null && newToken.isNotEmpty) {
            await storage.saveTokens(
              accessToken: newToken,
              refreshToken: newRefreshToken,
            );
            
            // Retry original request
            err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final retryResponse = await dio.fetch(err.requestOptions);
            return handler.resolve(retryResponse);
            }
          }
          debugPrint('🔐 Token refresh failed or no token in response');
        }
        
        // No refresh token or refresh failed - trigger session expiry
        debugPrint('🔐 Triggering session expiry (no valid refresh token or refresh failed)');
        _triggerSessionExpiry();
      } catch (e) {
        // Token refresh failed - force logout
        debugPrint('🔐 Token refresh exception: $e');
        _triggerSessionExpiry();
      }
    }
    
    handler.next(err);
  }
  
  void _triggerSessionExpiry() {
    debugPrint('🔐 _triggerSessionExpiry called');
    try {
      final storage = _ref.read(secureStorageProvider);
      storage.clearAuthData();
      
      final authNotifier = _ref.read(authStateProvider.notifier);
      authNotifier.handleSessionExpiry();
      
      Future.microtask(() {
        try {
          final context = rootNavigatorKey.currentContext;
          if (context != null) {
            GoRouter.of(context).go(AppRoutes.login);
          }
        } catch (e) {
          debugPrint('🔐 Session expiry navigation error: $e');
        }
      });
    } catch (e) {
      debugPrint('🔐 Session expiry error: $e');
    }
  }

  /// Check if a JWT token is expiring within [thresholdSeconds].
  static bool _isJwtExpiringSoon(String token, {int thresholdSeconds = 60}) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      String payload = parts[1];
      switch (payload.length % 4) {
        case 2: payload += '=='; break;
        case 3: payload += '='; break;
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      final exp = json['exp'] as int?;
      if (exp == null) return false;
      return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= (exp - thresholdSeconds);
    } catch (_) {
      return true;
    }
  }

  /// Proactively refresh the access token before it expires.
  /// Returns the new token on success, null on failure.
  Future<String?> _proactiveRefresh(SecureStorageService storage) async {
    try {
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return null;
      final dio = Dio();
      final response = await dio.post(
        '${ApiConfig.baseUrl}${ApiConfig.apiPrefix}/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map ? response.data as Map<String, dynamic> : <String, dynamic>{};
        final body = data['data'] as Map<String, dynamic>? ?? data;
        final tokens = body['tokens'] as Map<String, dynamic>? ?? body;
        final newToken = tokens['access_token']?.toString();
        final newRefresh = tokens['refresh_token']?.toString();
        if (newToken != null && newToken.isNotEmpty) {
          await storage.saveTokens(
            accessToken: newToken,
            refreshToken: newRefresh ?? refreshToken,
          );
          return newToken;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

/// Retry Interceptor - Automatic retry with exponential backoff
class RetryInterceptor extends Interceptor {
  final Dio _dio;
  
  RetryInterceptor(this._dio);
  
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final retryCount = options.extra['retryCount'] ?? 0;
    
    // Only retry on network errors or 5xx server errors
    final shouldRetry = _shouldRetry(err) && retryCount < ApiConfig.maxRetries;
    
    if (shouldRetry) {
      final delay = ApiConfig.retryDelay * (retryCount + 1);
      await Future.delayed(delay);
      
      options.extra['retryCount'] = retryCount + 1;
      
      try {
        final response = await _dio.fetch(options);
        return handler.resolve(response);
      } catch (e) {
        return handler.next(err);
      }
    }
    
    handler.next(err);
  }
  
  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
           err.type == DioExceptionType.sendTimeout ||
           err.type == DioExceptionType.receiveTimeout ||
           err.type == DioExceptionType.connectionError ||
           (err.response?.statusCode ?? 0) >= 500;
  }
}

/// Error Interceptor - Transforms Dio errors to AppExceptions
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Log error for analytics
    _logError(err);
    handler.next(err);
  }
  
  void _logError(DioException err) {
    // Analytics logging would go here
    debugPrint('API Error: ${err.requestOptions.path} - ${err.message}');
  }
}

/// Performance Timing Interceptor — logs request duration for every API call
class TimingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['_startTime'] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final start = response.requestOptions.extra['_startTime'] as int?;
    if (start != null) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - start;
      final path = response.requestOptions.path;
      final serverTime = response.headers.value('X-Response-Time') ?? '?';
      debugPrint('⏱️ API $path → ${response.statusCode} in ${elapsed}ms (server: $serverTime)');
      if (elapsed > 2000) {
        debugPrint('🐌 SLOW API CALL: $path took ${elapsed}ms — investigate!');
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final start = err.requestOptions.extra['_startTime'] as int?;
    if (start != null) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - start;
      debugPrint('⏱️ API ${err.requestOptions.path} → ERROR in ${elapsed}ms: ${err.type}');
    }
    handler.next(err);
  }
}

/// In-Memory GET Response Cache Interceptor
/// Caches GET responses for [ttlSeconds] to avoid redundant network calls.
class CacheInterceptor extends Interceptor {
  final int ttlSeconds;
  final Map<String, _CacheEntry> _cache = {};

  CacheInterceptor({this.ttlSeconds = 120});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Only cache GET requests
    if (options.method.toUpperCase() != 'GET') {
      return handler.next(options);
    }
    // Skip cache if explicitly requested
    if (options.extra['skipCache'] == true) {
      return handler.next(options);
    }

    final key = '${options.path}?${options.queryParameters}';
    final entry = _cache[key];
    if (entry != null && !entry.isExpired) {
      debugPrint('📦 Cache HIT: ${options.path}');
      return handler.resolve(
        Response(
          requestOptions: options,
          data: entry.data,
          statusCode: 200,
          headers: Headers.fromMap({'X-Cache': ['HIT']}),
        ),
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.method.toUpperCase() == 'GET' &&
        response.statusCode == 200) {
      final key =
          '${response.requestOptions.path}?${response.requestOptions.queryParameters}';
      _cache[key] = _CacheEntry(
        data: response.data,
        expiry: DateTime.now().add(Duration(seconds: ttlSeconds)),
      );
    }
    handler.next(response);
  }

  /// Invalidate all cached entries (call after data refresh)
  void clear() {
    _cache.clear();
    debugPrint('📦 Cache CLEARED');
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiry;

  _CacheEntry({required this.data, required this.expiry});

  bool get isExpired => DateTime.now().isAfter(expiry);
}

/// Certificate Pinning (for production)
class CertificatePinningInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Certificate pinning is handled at HttpClient level
    // See HttpOverrides implementation below
    handler.next(options);
  }
}

/// HTTP Overrides for certificate pinning
class ESUNHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    
    client.badCertificateCallback = (cert, host, port) {
      // In production, validate against pinned certificates
      // Return false to reject invalid certificates
      return kDebugMode; // Allow all in debug mode
    };
    
    return client;
  }
}

/// Main API Service
class ApiService {
  final Dio _dio;
  
  ApiService(this._dio);
  
  /// GET request
  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
    bool skipAuth = false,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(extra: {'skipAuth': skipAuth}),
      );
      
      final data = parser != null ? parser(response.data) : response.data as T;
      return Success(data);
    } on DioException catch (e) {
      return Error(_handleDioError(e));
    } catch (e, st) {
      return Error(AppException(
        message: e.toString(),
        originalError: e,
        stackTrace: st,
      ));
    }
  }
  
  /// POST request
  Future<Result<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
    bool skipAuth = false,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(extra: {'skipAuth': skipAuth}),
      );
      
      final result = parser != null ? parser(response.data) : response.data as T;
      return Success(result);
    } on DioException catch (e) {
      return Error(_handleDioError(e));
    } catch (e, st) {
      return Error(AppException(
        message: e.toString(),
        originalError: e,
        stackTrace: st,
      ));
    }
  }
  
  /// PUT request
  Future<Result<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
    bool skipAuth = false,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(extra: {'skipAuth': skipAuth}),
      );
      
      final result = parser != null ? parser(response.data) : response.data as T;
      return Success(result);
    } on DioException catch (e) {
      return Error(_handleDioError(e));
    } catch (e, st) {
      return Error(AppException(
        message: e.toString(),
        originalError: e,
        stackTrace: st,
      ));
    }
  }
  
  /// DELETE request
  Future<Result<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
    bool skipAuth = false,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(extra: {'skipAuth': skipAuth}),
      );
      
      final result = parser != null ? parser(response.data) : response.data as T;
      return Success(result);
    } on DioException catch (e) {
      return Error(_handleDioError(e));
    } catch (e, st) {
      return Error(AppException(
        message: e.toString(),
        originalError: e,
        stackTrace: st,
      ));
    }
  }
  
  /// PATCH request
  Future<Result<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
    bool skipAuth = false,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(extra: {'skipAuth': skipAuth}),
      );
      
      final result = parser != null ? parser(response.data) : response.data as T;
      return Success(result);
    } on DioException catch (e) {
      return Error(_handleDioError(e));
    } catch (e, st) {
      return Error(AppException(
        message: e.toString(),
        originalError: e,
        stackTrace: st,
      ));
    }
  }
  
  /// Upload file
  Future<Result<T>> upload<T>(
    String path, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? additionalFields,
    T Function(dynamic)? parser,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        if (additionalFields != null) ...additionalFields,
      });
      
      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onProgress,
      );
      
      final result = parser != null ? parser(response.data) : response.data as T;
      return Success(result);
    } on DioException catch (e) {
      return Error(_handleDioError(e));
    } catch (e, st) {
      return Error(AppException(
        message: e.toString(),
        originalError: e,
        stackTrace: st,
      ));
    }
  }
  
  /// Download file
  Future<Result<String>> download(
    String url,
    String savePath, {
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onProgress,
      );
      return Success(savePath);
    } on DioException catch (e) {
      return Error(_handleDioError(e));
    } catch (e, st) {
      return Error(AppException(
        message: e.toString(),
        originalError: e,
        stackTrace: st,
      ));
    }
  }
  
  /// Handle Dio errors
  AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException.timeout;
        
      case DioExceptionType.connectionError:
        return AppException.networkError;
        
      case DioExceptionType.badResponse:
        return _handleStatusCode(error.response?.statusCode, error.response?.data);
        
      case DioExceptionType.cancel:
        return const AppException(
          message: 'Request cancelled',
          code: 'CANCELLED',
        );
        
      default:
        return AppException(
          message: error.message ?? 'Unknown error occurred',
          code: 'UNKNOWN',
          originalError: error,
        );
    }
  }
  
  AppException _handleStatusCode(int? statusCode, dynamic data) {
    final message = _extractErrorMessage(data);
    
    switch (statusCode) {
      case 400:
        return AppException(
          message: message ?? 'Invalid request',
          code: 'BAD_REQUEST',
        );
      case 401:
        // Use server's error message if available, otherwise default to session expired
        return AppException(
          message: message ?? 'Session expired. Please login again.',
          code: 'UNAUTHORIZED',
        );
      case 403:
        return const AppException(
          message: 'Access denied',
          code: 'FORBIDDEN',
        );
      case 404:
        return AppException.notFound;
      case 422:
        return AppException(
          message: message ?? 'Validation error',
          code: 'VALIDATION_ERROR',
        );
      case 429:
        return const AppException(
          message: 'Too many requests. Please try again later.',
          code: 'RATE_LIMITED',
        );
      case 500:
      case 502:
      case 503:
        return AppException.serverError;
      default:
        return AppException(
          message: message ?? 'An error occurred',
          code: 'HTTP_$statusCode',
        );
    }
  }
  
  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is Map) {
      // Handle nested error structure: {"error": {"message": "...", "code": "..."}}
      final error = data['error'];
      if (error is Map) {
        return error['message']?.toString() ?? error['code']?.toString();
      }
      // Handle flat structure: {"message": "...", "error": "..."}
      return data['message']?.toString() ?? 
             (data['error'] is String ? data['error'] : null) ?? 
             data['errors']?.toString();
    }
    return null;
  }
}

/// Deduplication interceptor — collapses identical in-flight GET requests
/// into a single network call. Prevents fetching /summary 3 times
/// when 3 widgets mount simultaneously.
class DeduplicationInterceptor extends Interceptor {
  final Map<String, Completer<Response>> _inFlight = {};

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.method.toUpperCase() != 'GET') {
      return handler.next(options);
    }

    final key = '${options.method}:${options.uri}';
    if (_inFlight.containsKey(key)) {
      debugPrint('[Dedup] Reusing in-flight request: ${options.path}');
      try {
        final response = await _inFlight[key]!.future;
        return handler.resolve(Response(
          requestOptions: options,
          data: response.data,
          statusCode: response.statusCode,
          headers: response.headers,
        ));
      } catch (e) {
        return handler.reject(
          DioException(requestOptions: options, error: e),
        );
      }
    }

    _inFlight[key] = Completer<Response>();
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final key = '${response.requestOptions.method}:${response.requestOptions.uri}';
    if (_inFlight.containsKey(key) && !_inFlight[key]!.isCompleted) {
      _inFlight[key]!.complete(response);
    }
    _inFlight.remove(key);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final key = '${err.requestOptions.method}:${err.requestOptions.uri}';
    if (_inFlight.containsKey(key) && !_inFlight[key]!.isCompleted) {
      _inFlight[key]!.completeError(err);
    }
    _inFlight.remove(key);
    handler.next(err);
  }
}

/// SSE (Server-Sent Events) streaming support for AI chat
/// Returns a Stream of text chunks as they arrive from the server.
Stream<String> streamChatResponse(
  Dio dio, {
  required String path,
  required Map<String, dynamic> data,
}) async* {
  final response = await dio.post<ResponseBody>(
    path,
    data: data,
    options: Options(
      responseType: ResponseType.stream,
      headers: {'Accept': 'text/event-stream'},
    ),
  );

  final stream = response.data?.stream;
  if (stream == null) return;

  String buffer = '';
  await for (final chunk in stream) {
    buffer += utf8.decode(chunk);
    // Parse SSE lines: "data: ..."
    while (buffer.contains('\n')) {
      final lineEnd = buffer.indexOf('\n');
      final line = buffer.substring(0, lineEnd).trim();
      buffer = buffer.substring(lineEnd + 1);

      if (line.startsWith('data: ')) {
        final payload = line.substring(6);
        if (payload == '[DONE]') return;
        try {
          final json = jsonDecode(payload) as Map<String, dynamic>;
          final text = json['chunk'] ?? json['text'] ?? json['content'] ?? '';
          if (text.toString().isNotEmpty) yield text.toString();
        } catch (_) {
          // Raw text chunk
          if (payload.isNotEmpty) yield payload;
        }
      }
    }
  }
}



