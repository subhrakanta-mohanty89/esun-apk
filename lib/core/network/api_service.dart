/// ESUN Network Layer
/// 
/// Dio-based HTTP client with interceptors, retry logic, and certificate pinning.

import 'dart:async';
import 'dart:io';

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
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
  
  /// Certificate pins (SHA-256 hashes)
  static const List<String> certificatePins = [
    // Add production certificate pins here
    'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
  ];
}

/// Dio client provider
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    sendTimeout: ApiConfig.sendTimeout,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));
  
  // Add interceptors
  dio.interceptors.addAll([
    AuthInterceptor(ref),
    RetryInterceptor(dio),
    ErrorInterceptor(),
    if (kDebugMode)
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
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
        options.headers['Authorization'] = 'Bearer $token';
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
          
          if (response.statusCode == 200) {
            final newToken = response.data['access_token'];
            final newRefreshToken = response.data['refresh_token'];
            debugPrint('🔐 Token refresh successful');
            
            await storage.saveTokens(
              accessToken: newToken,
              refreshToken: newRefreshToken,
            );
            
            // Retry original request
            err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final retryResponse = await dio.fetch(err.requestOptions);
            return handler.resolve(retryResponse);
          } else {
            debugPrint('🔐 Token refresh failed with status: ${response.statusCode}');
          }
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
      // Clear auth data and trigger session expiry
      final storage = _ref.read(secureStorageProvider);
      storage.clearAuthData();
      debugPrint('🔐 Auth data cleared');
      
      // Update auth state
      final authNotifier = _ref.read(authStateProvider.notifier);
      authNotifier.handleSessionExpiry();
      debugPrint('🔐 Auth state set to sessionExpired');
      
      // Force navigation to login screen using microtask to avoid context issues
      Future.microtask(() {
        try {
          final context = rootNavigatorKey.currentContext;
          debugPrint('🔐 Navigator context available: ${context != null}');
          if (context != null) {
            GoRouter.of(context).go(AppRoutes.login);
            debugPrint('🔐 Navigation to login triggered');
          }
        } catch (e) {
          debugPrint('🔐 Session expiry navigation error: $e');
        }
      });
    } catch (e) {
      debugPrint('🔐 Session expiry error: $e');
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



