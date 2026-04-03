/// ESUN Security Services
/// 
/// Biometric authentication, device binding, fraud detection, and security utilities.
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

import '../storage/secure_storage.dart';
import '../utils/utils.dart';

/// Biometric Auth Provider
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService(ref);
});

/// Device Security Provider
final deviceSecurityProvider = Provider<DeviceSecurityService>((ref) {
  return DeviceSecurityService(ref);
});

/// Fraud Detection Provider
final fraudDetectionProvider = Provider<FraudDetectionService>((ref) {
  return FraudDetectionService(ref);
});

/// Biometric authentication result
enum BiometricResult {
  success,
  failed,
  notAvailable,
  notEnrolled,
  lockedOut,
  cancelled,
  error,
}

/// Biometric Service
class BiometricService {
  final Ref _ref;
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  BiometricService(this._ref);
  
  /// Check if biometrics are available
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      debugPrint('Biometric check failed: $e');
      return false;
    }
  }
  
  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Failed to get biometrics: $e');
      return [];
    }
  }
  
  /// Authenticate with biometrics
  Future<BiometricResult> authenticate({
    String reason = 'Authenticate to access ESUN',
    bool biometricOnly = false,
  }) async {
    try {
      final available = await isAvailable();
      if (!available) return BiometricResult.notAvailable;
      
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
        ),
      );
      
      if (authenticated) {
        // Update last successful auth time
        final storage = _ref.read(secureStorageProvider);
        await storage.saveSessionExpiry(
          DateTime.now().add(const Duration(hours: 24)),
        );
        return BiometricResult.success;
      }
      
      return BiometricResult.failed;
    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return BiometricResult.error;
    }
  }
  
  BiometricResult _handlePlatformException(PlatformException e) {
    switch (e.code) {
      case auth_error.notAvailable:
        return BiometricResult.notAvailable;
      case auth_error.notEnrolled:
        return BiometricResult.notEnrolled;
      case auth_error.lockedOut:
      case auth_error.permanentlyLockedOut:
        return BiometricResult.lockedOut;
      default:
        return BiometricResult.error;
    }
  }
  
  /// Enable biometric authentication
  Future<bool> enableBiometric() async {
    final result = await authenticate(
      reason: 'Verify your identity to enable biometric login',
    );
    
    if (result == BiometricResult.success) {
      final storage = _ref.read(secureStorageProvider);
      await storage.setBiometricEnabled(true);
      return true;
    }
    
    return false;
  }
  
  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    final storage = _ref.read(secureStorageProvider);
    await storage.setBiometricEnabled(false);
  }
  
  /// Check if biometric is enabled for this user
  Future<bool> isBiometricEnabled() async {
    final storage = _ref.read(secureStorageProvider);
    return storage.isBiometricEnabled();
  }
}

/// Device Security Service
class DeviceSecurityService {
  final Ref _ref;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  DeviceSecurityService(this._ref);
  
  /// Generate unique device ID
  Future<String> generateDeviceId() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      
      final deviceData = [
        androidInfo.id,
        androidInfo.device,
        androidInfo.model,
        androidInfo.product,
        androidInfo.hardware,
      ].join('|');
      
      // Hash the device data
      final bytes = utf8.encode(deviceData);
      final hash = sha256.convert(bytes);
      
      return hash.toString();
    } catch (e) {
      // Fallback to random UUID if device info fails
      return _generateUUID();
    }
  }
  
  String _generateUUID() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
           '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
           '${hex.substring(20)}';
  }
  
  /// Bind device to account
  Future<Result<void>> bindDevice() async {
    try {
      final storage = _ref.read(secureStorageProvider);
      final deviceId = await generateDeviceId();
      final androidInfo = await _deviceInfo.androidInfo;
      
      final binding = {
        'deviceId': deviceId,
        'model': androidInfo.model,
        'manufacturer': androidInfo.manufacturer,
        'brand': androidInfo.brand,
        'sdkInt': androidInfo.version.sdkInt.toString(),
        'boundAt': DateTime.now().toIso8601String(),
      };
      
      await storage.saveDeviceId(deviceId);
      await storage.saveDeviceBinding(binding);
      
      return const Success(null);
    } catch (e, st) {
      return Error(AppException(
        message: 'Failed to bind device',
        originalError: e,
        stackTrace: st,
      ));
    }
  }
  
  /// Verify device binding
  Future<bool> verifyDeviceBinding() async {
    try {
      final storage = _ref.read(secureStorageProvider);
      final storedId = await storage.getDeviceId();
      
      if (storedId == null) return false;
      
      final currentId = await generateDeviceId();
      return storedId == currentId;
    } catch (e) {
      debugPrint('Device verification failed: $e');
      return false;
    }
  }
  
  /// Get device info for fraud detection
  Future<Map<String, dynamic>> getDeviceFingerprint() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      
      return {
        'deviceId': await generateDeviceId(),
        'model': androidInfo.model,
        'manufacturer': androidInfo.manufacturer,
        'brand': androidInfo.brand,
        'device': androidInfo.device,
        'hardware': androidInfo.hardware,
        'isPhysicalDevice': androidInfo.isPhysicalDevice,
        'sdkInt': androidInfo.version.sdkInt,
        'release': androidInfo.version.release,
        'securityPatch': androidInfo.version.securityPatch,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// Check if device is rooted/compromised
  Future<bool> isDeviceSecure() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      
      // Basic checks - in production, use more sophisticated root detection
      if (!androidInfo.isPhysicalDevice) return false;
      
      // Add more security checks here
      // - Check for root indicators
      // - Check for debugging
      // - Check for emulator
      
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Fraud Detection Service
class FraudDetectionService {
  final Ref _ref;
  
  // Risk thresholds
  static const int lowRiskThreshold = 30;
  static const int mediumRiskThreshold = 60;
  static const int highRiskThreshold = 80;
  
  FraudDetectionService(this._ref);
  
  /// Calculate transaction risk score
  Future<FraudRiskResult> analyzeTransaction({
    required double amount,
    required String merchantId,
    required String transactionType,
    Map<String, dynamic>? additionalData,
  }) async {
    int riskScore = 0;
    final flags = <String>[];
    
    // Amount-based risk
    if (amount > 100000) {
      riskScore += 30;
      flags.add('high_amount');
    } else if (amount > 50000) {
      riskScore += 15;
      flags.add('elevated_amount');
    }
    
    // Time-based risk (unusual hours)
    final hour = DateTime.now().hour;
    if (hour >= 0 && hour < 6) {
      riskScore += 20;
      flags.add('unusual_hours');
    }
    
    // Velocity check would happen here (multiple transactions in short time)
    // This would require transaction history comparison
    
    // Device verification
    final deviceSecurity = _ref.read(deviceSecurityProvider);
    final isDeviceVerified = await deviceSecurity.verifyDeviceBinding();
    if (!isDeviceVerified) {
      riskScore += 40;
      flags.add('unverified_device');
    }
    
    // Determine risk level
    FraudRiskLevel level;
    if (riskScore >= highRiskThreshold) {
      level = FraudRiskLevel.high;
    } else if (riskScore >= mediumRiskThreshold) {
      level = FraudRiskLevel.medium;
    } else if (riskScore >= lowRiskThreshold) {
      level = FraudRiskLevel.low;
    } else {
      level = FraudRiskLevel.minimal;
    }
    
    return FraudRiskResult(
      score: riskScore,
      level: level,
      flags: flags,
      shouldBlock: level == FraudRiskLevel.high,
      requiresVerification: level == FraudRiskLevel.medium,
    );
  }
  
  /// Log suspicious activity
  Future<void> logSuspiciousActivity({
    required String activityType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    // In production, send to fraud monitoring backend
    final deviceSecurity = _ref.read(deviceSecurityProvider);
    final fingerprint = await deviceSecurity.getDeviceFingerprint();
    
    final activityLog = {
      'type': activityType,
      'description': description,
      'timestamp': DateTime.now().toIso8601String(),
      'device': fingerprint,
      'metadata': metadata,
    };
    
    debugPrint('Suspicious activity: $activityLog');
    // TODO: Send to backend fraud detection service
  }
  
  /// Check for rate limiting
  Future<RateLimitResult> checkRateLimit({
    required String action,
    int maxAttempts = 5,
    Duration window = const Duration(minutes: 15),
  }) async {
    // In production, this would check against a rate limiting service
    // For now, return always allowed
    return RateLimitResult(
      allowed: true,
      remainingAttempts: maxAttempts,
      resetTime: DateTime.now().add(window),
    );
  }
}

/// Fraud Risk Level
enum FraudRiskLevel {
  minimal,
  low,
  medium,
  high,
}

/// Fraud Risk Result
class FraudRiskResult {
  final int score;
  final FraudRiskLevel level;
  final List<String> flags;
  final bool shouldBlock;
  final bool requiresVerification;
  
  const FraudRiskResult({
    required this.score,
    required this.level,
    required this.flags,
    required this.shouldBlock,
    required this.requiresVerification,
  });
}

/// Rate Limit Result
class RateLimitResult {
  final bool allowed;
  final int remainingAttempts;
  final DateTime resetTime;
  
  const RateLimitResult({
    required this.allowed,
    required this.remainingAttempts,
    required this.resetTime,
  });
}

/// PIN Utilities
class PinUtils {
  /// Hash a PIN for secure storage
  static String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
  
  /// Verify PIN against stored hash
  static bool verifyPin(String pin, String storedHash) {
    return hashPin(pin) == storedHash;
  }
  
  /// Generate OTP
  static String generateOTP({int length = 6}) {
    final random = Random.secure();
    return List.generate(length, (_) => random.nextInt(10)).join();
  }
}

/// Session Manager
class SessionManager {
  final SecureStorageService _storage;
  
  SessionManager(this._storage);
  
  /// Check if session is valid
  Future<bool> isSessionValid() async {
    return _storage.isLoggedIn();
  }
  
  /// Extend session
  Future<void> extendSession({Duration duration = const Duration(hours: 24)}) async {
    await _storage.saveSessionExpiry(DateTime.now().add(duration));
  }
  
  /// Invalidate session
  Future<void> invalidateSession() async {
    await _storage.clearAuthData();
  }
}



