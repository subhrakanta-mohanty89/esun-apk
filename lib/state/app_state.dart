/// ESUN App State
/// 
/// Global application state providers using Riverpod.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/secure_storage.dart';
import '../core/network/api_service.dart';
import '../core/utils/utils.dart';

/// Theme Mode Provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final Ref _ref;
  
  ThemeModeNotifier(this._ref) : super(ThemeMode.light) {
    _loadThemeMode();
  }
  
  Future<void> _loadThemeMode() async {
    final cache = _ref.read(cacheStorageProvider);
    final stored = cache.getPref<String>(PrefKeys.themeMode);
    
    if (stored != null) {
      state = ThemeMode.values.firstWhere(
        (m) => m.name == stored,
        orElse: () => ThemeMode.system,
      );
    }
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final cache = _ref.read(cacheStorageProvider);
    await cache.savePref(PrefKeys.themeMode, mode.name);
  }
  
  void toggleTheme() {
    if (state == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }
}

/// Auth State
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  sessionExpired,
}

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref);
});

class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? userName;
  final bool isBiometricEnabled;
  final bool isLoading;
  final String? error;
  final bool isOnboarded;  // Server-side AA onboarding status
  final bool aaConnected;  // Account Aggregator connection status
  final bool creditBureauConnected;  // Credit Bureau connection status
  final bool linkDataPopupDismissed;  // User dismissed popup this session
  
  const AuthState({
    this.status = AuthStatus.initial,
    this.userId,
    this.userName,
    this.isBiometricEnabled = false,
    this.isLoading = true,  // Start as loading until auth check completes
    this.error,
    this.isOnboarded = true,  // Default true to avoid popup on initial load
    this.aaConnected = false,
    this.creditBureauConnected = false,
    this.linkDataPopupDismissed = false,
  });
  
  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? userName,
    bool? isBiometricEnabled,
    bool? isLoading,
    String? error,
    bool? isOnboarded,
    bool? aaConnected,
    bool? creditBureauConnected,
    bool? linkDataPopupDismissed,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      aaConnected: aaConnected ?? this.aaConnected,
      creditBureauConnected: creditBureauConnected ?? this.creditBureauConnected,
      linkDataPopupDismissed: linkDataPopupDismissed ?? this.linkDataPopupDismissed,
    );
  }
}

/// Helper class for token validation result
class _TokenValidationResult {
  final bool isValid;
  final String? userName;
  final bool aaConnected;
  final bool creditBureauConnected;
  final bool isOnboarded;
  final String? error;
  
  const _TokenValidationResult({
    required this.isValid,
    this.userName,
    this.aaConnected = false,
    this.creditBureauConnected = false,
    this.isOnboarded = false,
    this.error,
  });
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  
  AuthStateNotifier(this._ref) : super(const AuthState()) {
    _checkAuthStatus();
  }
  
  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final storage = _ref.read(secureStorageProvider);
      final hasTokens = await storage.isLoggedIn();
      final isBiometricEnabled = await storage.isBiometricEnabled();
      
      if (hasTokens) {
        // Tokens exist locally - validate with server
        final validationResult = await _validateTokensWithServer();
        
        if (validationResult.isValid) {
          final userId = await storage.getUserId();
          state = state.copyWith(
            status: AuthStatus.authenticated,
            userId: userId,
            userName: validationResult.userName,
            isBiometricEnabled: isBiometricEnabled,
            aaConnected: validationResult.aaConnected,
            creditBureauConnected: validationResult.creditBureauConnected,
            isOnboarded: validationResult.isOnboarded,
            isLoading: false,
          );
        } else {
          // Token validation failed - clear tokens and require re-login
          await storage.clearAuthData();
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            isLoading: false,
            error: validationResult.error,
          );
        }
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
        );
      }
    } catch (e) {
      // Clear any stored tokens on error for security
      try {
        final storage = _ref.read(secureStorageProvider);
        await storage.clearAuthData();
      } catch (_) {}
      
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  /// Validate tokens with the server by fetching user profile
  /// Returns validation result with user data or error
  Future<_TokenValidationResult> _validateTokensWithServer() async {
    try {
      final api = _ref.read(apiServiceProvider);
      final result = await api.get<Map<String, dynamic>>('${ApiConfig.apiPrefix}/users/me');
      
      if (result.isSuccess && result.data != null) {
        final body = result.data!;
        final success = body['success'] == true;
        
        if (!success) {
          return _TokenValidationResult(
            isValid: false,
            error: 'Server returned unsuccessful response',
          );
        }
        
        final user = body['data'] as Map<String, dynamic>? ?? body;
        
        return _TokenValidationResult(
          isValid: true,
          userName: user['full_name']?.toString(),
          aaConnected: user['aa_connected'] == true,
          creditBureauConnected: user['credit_bureau_connected'] == true,
          isOnboarded: user['onboarded'] == true || user['aa_connected'] == true || user['credit_bureau_connected'] == true,
        );
      } else {
        // API call failed - check if it's an auth error
        final errorCode = result.error?.code;
        final isAuthError = errorCode == 'UNAUTHORIZED' || errorCode == 'FORBIDDEN';
        
        return _TokenValidationResult(
          isValid: false,
          error: isAuthError 
              ? 'Session expired. Please login again.' 
              : 'Unable to connect to server. Please check your connection.',
        );
      }
    } catch (e) {
      return _TokenValidationResult(
        isValid: false,
        error: 'Connection error. Please try again.',
      );
    }
  }
  
  /// Login with tokens directly (used for password-based login)
  Future<bool> loginWithTokens({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
    String? deviceId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final storage = _ref.read(secureStorageProvider);
      await storage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      
      final userId = user['id']?.toString();
      if (userId != null) {
        await storage.saveUserId(userId);
      }
      if (deviceId != null) {
        await storage.saveDeviceId(deviceId);
      }
      
      // Extract onboarding status from user data
      final isOnboarded = user['onboarded'] == true;
      final aaConnected = user['aa_connected'] == true;
      final creditBureauConnected = user['credit_bureau_connected'] == true;
      final userName = user['full_name']?.toString();
      
      state = state.copyWith(
        status: AuthStatus.authenticated,
        userId: userId,
        userName: userName,
        isLoading: false,
        isOnboarded: isOnboarded,
        aaConnected: aaConnected,
        creditBureauConnected: creditBureauConnected,
        linkDataPopupDismissed: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
  
  Future<bool> login({
    required String identifier,
    required String otp,
    String? fullName,
    String? email,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final api = _ref.read(apiServiceProvider);
      final payload = identifier.contains('@')
          ? {'email': identifier, 'otp': otp}
          : {'phone': identifier, 'otp': otp};
      // Add full_name for registration
      if (fullName != null && fullName.isNotEmpty) {
        payload['full_name'] = fullName;
      }
      // Add email for registration verification fallback
      if (email != null && email.isNotEmpty && !identifier.contains('@')) {
        payload['email'] = email;
      }
      final result = await api.post<Map<String, dynamic>>(
        '${ApiConfig.apiPrefix}/auth/verify',
        data: payload,
        skipAuth: true,
      );

      if (result.isError || result.data == null) {
        state = state.copyWith(
          isLoading: false,
          error: result.error?.message ?? 'Login failed',
        );
        return false;
      }

      final body = result.data!;
      final ok = body['success'] == true;
      if (!ok) {
        final msg = body['error']?['message'] ?? 'Invalid OTP';
        state = state.copyWith(isLoading: false, error: msg);
        return false;
      }

      final data = body['data'] as Map<String, dynamic>? ?? {};
      final tokens = data['tokens'] as Map<String, dynamic>? ?? {};
      final accessToken = tokens['access_token'] ?? tokens['access'] ?? '';
      final refreshToken = tokens['refresh_token'] ?? tokens['refresh'] ?? '';
      final user = data['user'] as Map<String, dynamic>?;
      final userId = user?['id']?.toString();
      final deviceId = data['device_id']?.toString();

      if (accessToken.isEmpty || refreshToken.isEmpty) {
        state = state.copyWith(isLoading: false, error: 'Missing tokens');
        return false;
      }

      // Extract onboarding status from user data first for faster state update
      final isOnboarded = user?['onboarded'] == true;
      final aaConnected = user?['aa_connected'] == true;
      final creditBureauConnected = user?['credit_bureau_connected'] == true;
      final userName = user?['full_name']?.toString();
      
      // Update state immediately for faster UI response
      state = state.copyWith(
        status: AuthStatus.authenticated,
        userId: userId,
        userName: userName,
        isLoading: false,
        isOnboarded: isOnboarded,
        aaConnected: aaConnected,
        creditBureauConnected: creditBureauConnected,
        linkDataPopupDismissed: false,
      );

      // Save to storage in parallel (non-blocking for UI)
      final storage = _ref.read(secureStorageProvider);
      final accessExpiresIn = tokens['expires_in'] ?? tokens['access_expires_in'];
      
      // Fire and forget storage operations for faster response
      unawaited(Future.wait([
        storage.saveTokens(accessToken: accessToken, refreshToken: refreshToken),
        if (userId != null) storage.saveUserId(userId),
        if (deviceId != null) storage.saveDeviceId(deviceId),
        if (accessExpiresIn is int) 
          storage.saveSessionExpiry(DateTime.now().add(Duration(seconds: accessExpiresIn))),
      ]));
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
  
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final api = _ref.read(apiServiceProvider);
      // Best-effort logout; ignore errors
      await api.post('${ApiConfig.apiPrefix}/auth/logout', skipAuth: false);
    } catch (_) {
      // swallow
    }
    try {
      final storage = _ref.read(secureStorageProvider);
      await storage.clearAuthData();
      
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  void handleSessionExpiry() {
    state = state.copyWith(status: AuthStatus.sessionExpired);
  }
  
  /// Dismiss the link data popup for this session
  void dismissLinkDataPopup() {
    state = state.copyWith(linkDataPopupDismissed: true);
  }
  
  /// Update linking status after AA/Credit Bureau connection
  void updateLinkingStatus({bool? aaConnected, bool? creditBureauConnected}) {
    state = state.copyWith(
      aaConnected: aaConnected,
      creditBureauConnected: creditBureauConnected,
      isOnboarded: (aaConnected ?? state.aaConnected) || (creditBureauConnected ?? state.creditBureauConnected),
    );
  }
  
  /// Refresh user profile from server to get latest linking status
  Future<void> refreshUserProfile() async {
    try {
      final api = _ref.read(apiServiceProvider);
      final result = await api.get<Map<String, dynamic>>('${ApiConfig.apiPrefix}/users/me');
      
      if (result.isSuccess && result.data != null) {
        final body = result.data!;
        if (body['success'] == true) {
          final user = body['data'] as Map<String, dynamic>? ?? body;
          state = state.copyWith(
            userName: user['full_name']?.toString(),
            aaConnected: user['aa_connected'] == true,
            creditBureauConnected: user['credit_bureau_connected'] == true,
            isOnboarded: user['onboarded'] == true || user['aa_connected'] == true || user['credit_bureau_connected'] == true,
          );
        }
      }
    } catch (e) {
      // Silently fail - don't interrupt user
    }
  }
  
  Future<void> authenticateWithBiometrics() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // TODO: Implement actual biometric check
      await Future.delayed(const Duration(milliseconds: 500));
      
      state = state.copyWith(
        status: AuthStatus.authenticated,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

/// Connectivity State
final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier();
});

class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier() : super(true) {
    // TODO: Listen to connectivity changes
  }
  
  void setConnected(bool connected) {
    state = connected;
  }
}

/// App Settings
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier(ref);
});

class AppSettings {
  final String locale;
  final String currency;
  final bool notificationsEnabled;
  final bool biometricPromptEnabled;
  final bool aiConsentGiven;
  final bool hasCompletedOnboarding;
  final bool transactionAlertsEnabled;
  final bool billRemindersEnabled;
  
  const AppSettings({
    this.locale = 'en',
    this.currency = 'INR',
    this.notificationsEnabled = true,
    this.biometricPromptEnabled = true,
    this.aiConsentGiven = false,
    this.hasCompletedOnboarding = false,
    this.transactionAlertsEnabled = true,
    this.billRemindersEnabled = true,
  });
  
  // Alias for compatibility
  bool get biometricEnabled => biometricPromptEnabled;
  
  AppSettings copyWith({
    String? locale,
    String? currency,
    bool? notificationsEnabled,
    bool? biometricPromptEnabled,
    bool? aiConsentGiven,
    bool? hasCompletedOnboarding,
    bool? transactionAlertsEnabled,
    bool? billRemindersEnabled,
  }) {
    return AppSettings(
      locale: locale ?? this.locale,
      currency: currency ?? this.currency,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      biometricPromptEnabled: biometricPromptEnabled ?? this.biometricPromptEnabled,
      aiConsentGiven: aiConsentGiven ?? this.aiConsentGiven,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      transactionAlertsEnabled: transactionAlertsEnabled ?? this.transactionAlertsEnabled,
      billRemindersEnabled: billRemindersEnabled ?? this.billRemindersEnabled,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final Ref _ref;
  
  AppSettingsNotifier(this._ref) : super(const AppSettings()) {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final cache = _ref.read(cacheStorageProvider);
    
    final currency = cache.getPref<String>(PrefKeys.currency) ?? 'INR';
    
    // Sync with CurrencyFormatter
    CurrencyFormatter.setCurrencyByCode(currency);
    
    state = AppSettings(
      locale: cache.getPref<String>(PrefKeys.locale) ?? 'en',
      currency: currency,
      notificationsEnabled: cache.getPref<bool>(PrefKeys.notificationsEnabled) ?? true,
      biometricPromptEnabled: cache.getPref<bool>(PrefKeys.biometricPromptEnabled) ?? true,
      aiConsentGiven: cache.getPref<bool>(PrefKeys.aiConsentGiven) ?? false,
      hasCompletedOnboarding: cache.getPref<bool>(PrefKeys.onboardingComplete) ?? false,
    );
  }
  
  Future<void> setLocale(String locale) async {
    state = state.copyWith(locale: locale);
    final cache = _ref.read(cacheStorageProvider);
    await cache.savePref(PrefKeys.locale, locale);
  }
  
  Future<void> setCurrency(String currency) async {
    state = state.copyWith(currency: currency);
    
    // Sync with CurrencyFormatter for locale-aware formatting
    CurrencyFormatter.setCurrencyByCode(currency);
    
    final cache = _ref.read(cacheStorageProvider);
    await cache.savePref(PrefKeys.currency, currency);
  }
  
  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    final cache = _ref.read(cacheStorageProvider);
    await cache.savePref(PrefKeys.notificationsEnabled, enabled);
  }
  
  Future<void> setBiometricPromptEnabled(bool enabled) async {
    state = state.copyWith(biometricPromptEnabled: enabled);
    final cache = _ref.read(cacheStorageProvider);
    await cache.savePref(PrefKeys.biometricPromptEnabled, enabled);
  }
  
  Future<void> setAIConsentGiven(bool given) async {
    state = state.copyWith(aiConsentGiven: given);
    final cache = _ref.read(cacheStorageProvider);
    await cache.savePref(PrefKeys.aiConsentGiven, given);
  }
  
  Future<void> completeOnboarding() async {
    state = state.copyWith(hasCompletedOnboarding: true);
    final cache = _ref.read(cacheStorageProvider);
    await cache.savePref(PrefKeys.onboardingComplete, true);
  }
  
  Future<void> toggleBiometric() async {
    await setBiometricPromptEnabled(!state.biometricPromptEnabled);
  }
  
  Future<void> toggleNotifications() async {
    await setNotificationsEnabled(!state.notificationsEnabled);
  }
  
  Future<void> toggleTransactionAlerts() async {
    state = state.copyWith(transactionAlertsEnabled: !state.transactionAlertsEnabled);
  }
  
  Future<void> toggleBillReminders() async {
    state = state.copyWith(billRemindersEnabled: !state.billRemindersEnabled);
  }
}



