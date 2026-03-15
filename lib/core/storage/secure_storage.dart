/// ESUN Secure Storage
/// 
/// Encrypted storage for sensitive data like tokens, credentials, and user preferences.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Secure storage keys
abstract class StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String deviceId = 'device_id';
  static const String userId = 'user_id';
  static const String biometricEnabled = 'biometric_enabled';
  static const String pinHash = 'pin_hash';
  static const String lastLogin = 'last_login';
  static const String sessionExpiry = 'session_expiry';
  static const String deviceBinding = 'device_binding';
  static const String fraudChecksum = 'fraud_checksum';
}

/// Cache keys for Hive
abstract class CacheKeys {
  static const String userProfile = 'user_profile';
  static const String accounts = 'accounts';
  static const String transactions = 'transactions';
  static const String portfolio = 'portfolio';
  static const String preferences = 'preferences';
  static const String searchHistory = 'search_history';
}

/// Hive box names
abstract class HiveBoxes {
  static const String cache = 'ESUN_cache';
  static const String preferences = 'ESUN_prefs';
  static const String offlineQueue = 'offline_queue';
}

/// Secure Storage Provider
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Cache Storage Provider
final cacheStorageProvider = Provider<CacheStorageService>((ref) {
  return CacheStorageService();
});

/// Secure Storage Service - For highly sensitive data
class SecureStorageService {
  final FlutterSecureStorage _storage;
  
  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
            sharedPreferencesName: 'ESUN_secure_prefs',
            preferencesKeyPrefix: 'ESUN_',
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
            accountName: 'ESUN',
          ),
        );
  
  /// Save access and refresh tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: StorageKeys.accessToken, value: accessToken),
      _storage.write(key: StorageKeys.refreshToken, value: refreshToken),
      _storage.write(
        key: StorageKeys.lastLogin,
        value: DateTime.now().toIso8601String(),
      ),
    ]);
  }
  
  /// Get access token
  Future<String?> getAccessToken() async {
    return _storage.read(key: StorageKeys.accessToken);
  }
  
  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return _storage.read(key: StorageKeys.refreshToken);
  }
  
  /// Clear all auth data
  Future<void> clearAuthData() async {
    await Future.wait([
      _storage.delete(key: StorageKeys.accessToken),
      _storage.delete(key: StorageKeys.refreshToken),
      _storage.delete(key: StorageKeys.sessionExpiry),
    ]);
  }
  
  /// Save device ID for device binding
  Future<void> saveDeviceId(String deviceId) async {
    await _storage.write(key: StorageKeys.deviceId, value: deviceId);
  }
  
  /// Get device ID
  Future<String?> getDeviceId() async {
    return _storage.read(key: StorageKeys.deviceId);
  }
  
  /// Save user ID
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: StorageKeys.userId, value: userId);
  }
  
  /// Get user ID
  Future<String?> getUserId() async {
    return _storage.read(key: StorageKeys.userId);
  }
  
  /// Enable/disable biometric auth
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: StorageKeys.biometricEnabled,
      value: enabled.toString(),
    );
  }
  
  /// Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: StorageKeys.biometricEnabled);
    return value == 'true';
  }
  
  /// Save PIN hash
  Future<void> savePinHash(String pinHash) async {
    await _storage.write(key: StorageKeys.pinHash, value: pinHash);
  }
  
  /// Get PIN hash
  Future<String?> getPinHash() async {
    return _storage.read(key: StorageKeys.pinHash);
  }
  
  /// Save session expiry
  Future<void> saveSessionExpiry(DateTime expiry) async {
    await _storage.write(
      key: StorageKeys.sessionExpiry,
      value: expiry.toIso8601String(),
    );
  }
  
  /// Get session expiry
  Future<DateTime?> getSessionExpiry() async {
    final value = await _storage.read(key: StorageKeys.sessionExpiry);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }
  
  /// Check if session is expired
  Future<bool> isSessionExpired() async {
    final expiry = await getSessionExpiry();
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry);
  }
  
  /// Save device binding info
  Future<void> saveDeviceBinding(Map<String, String> binding) async {
    final encoded = binding.entries
        .map((e) => '${e.key}:${e.value}')
        .join('|');
    await _storage.write(key: StorageKeys.deviceBinding, value: encoded);
  }
  
  /// Get device binding info
  Future<Map<String, String>?> getDeviceBinding() async {
    final value = await _storage.read(key: StorageKeys.deviceBinding);
    if (value == null) return null;
    
    final map = <String, String>{};
    for (final entry in value.split('|')) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        map[parts[0]] = parts[1];
      }
    }
    return map;
  }
  
  /// Clear all secure storage
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
  
  /// Check if user is logged in
  /// Only checks for token presence - session expiry is handled separately for refresh
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}

/// Cache Storage Service - For app data caching
class CacheStorageService {
  Box? _cacheBox;
  Box? _prefsBox;
  Box? _offlineBox;
  
  /// Initialize Hive boxes
  Future<void> initialize() async {
    await Hive.initFlutter();
    
    _cacheBox = await Hive.openBox(HiveBoxes.cache);
    _prefsBox = await Hive.openBox(HiveBoxes.preferences);
    _offlineBox = await Hive.openBox(HiveBoxes.offlineQueue);
  }
  
  /// Get cache box
  Box get cache {
    _cacheBox ??= Hive.box(HiveBoxes.cache);
    return _cacheBox!;
  }
  
  /// Get preferences box
  Box get preferences {
    _prefsBox ??= Hive.box(HiveBoxes.preferences);
    return _prefsBox!;
  }
  
  /// Get offline queue box
  Box get offlineQueue {
    _offlineBox ??= Hive.box(HiveBoxes.offlineQueue);
    return _offlineBox!;
  }
  
  /// Save to cache with expiry
  Future<void> saveWithExpiry<T>(
    String key,
    T data, {
    Duration expiry = const Duration(hours: 1),
  }) async {
    final expiryTime = DateTime.now().add(expiry).toIso8601String();
    await cache.put(key, {
      'data': data,
      'expiry': expiryTime,
    });
  }
  
  /// Get from cache (returns null if expired)
  T? getWithExpiry<T>(String key) {
    final cached = cache.get(key);
    if (cached == null) return null;
    
    final expiry = DateTime.tryParse(cached['expiry'] as String? ?? '');
    if (expiry == null || DateTime.now().isAfter(expiry)) {
      cache.delete(key);
      return null;
    }
    
    return cached['data'] as T?;
  }
  
  /// Save preference
  Future<void> savePref<T>(String key, T value) async {
    await preferences.put(key, value);
  }
  
  /// Get preference
  T? getPref<T>(String key, {T? defaultValue}) {
    return preferences.get(key, defaultValue: defaultValue) as T?;
  }
  
  /// Add to offline queue
  Future<void> queueOfflineRequest(Map<String, dynamic> request) async {
    final key = DateTime.now().millisecondsSinceEpoch.toString();
    await offlineQueue.put(key, request);
  }
  
  /// Get all offline requests
  List<Map<String, dynamic>> getOfflineRequests() {
    return offlineQueue.values.cast<Map<String, dynamic>>().toList();
  }
  
  /// Clear offline queue
  Future<void> clearOfflineQueue() async {
    await offlineQueue.clear();
  }
  
  /// Clear all cache
  Future<void> clearCache() async {
    await cache.clear();
  }
  
  /// Clear all data
  Future<void> clearAll() async {
    await Future.wait([
      cache.clear(),
      preferences.clear(),
      offlineQueue.clear(),
    ]);
  }
  
  /// Get cache size in bytes
  int get cacheSize {
    // Approximate size calculation
    int size = 0;
    for (final key in cache.keys) {
      final value = cache.get(key);
      size += key.toString().length + value.toString().length;
    }
    return size;
  }
}

/// Preference Keys
abstract class PrefKeys {
  static const String themeMode = 'theme_mode';
  static const String locale = 'locale';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String biometricPromptEnabled = 'biometric_prompt';
  static const String onboardingComplete = 'onboarding_complete';
  static const String lastSyncTime = 'last_sync_time';
  static const String aiConsentGiven = 'ai_consent';
  static const String defaultAccount = 'default_account';
  static const String currency = 'currency';
  static const String dateFormat = 'date_format';
}



