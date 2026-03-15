/// Feature Flags Provider
///
/// Manages feature flags state and caching for A/B testing and feature toggles.
/// Automatically fetches flags on startup and caches them.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'analytics_api_service.dart';

/// Feature flag keys
abstract class FeatureFlags {
  // Dashboard features
  static const String newDashboard = 'new_dashboard';
  static const String dashboardWidgets = 'dashboard_widgets';
  
  // AA/CB Linking features
  static const String aaPromptV2 = 'aa_prompt_v2';
  static const String cbSmartFetch = 'cb_smart_fetch';
  static const String linkingReminders = 'linking_reminders';
  
  // Export features
  static const String pdfExportV2 = 'pdf_export_v2';
  static const String excelExport = 'excel_export';
  static const String shareToApps = 'share_to_apps';
  
  // Coaching features
  static const String financialCoach = 'financial_coach';
  static const String aiInsights = 'ai_insights';
  static const String calculators = 'calculators';
  
  // UX features
  static const String bottomNav = 'bottom_nav';
  static const String darkMode = 'dark_mode';
  static const String biometricLogin = 'biometric_login';
}

/// Feature flags state
class FeatureFlagsState {
  final Map<String, bool> flags;
  final Map<String, String> variants;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;
  
  const FeatureFlagsState({
    this.flags = const {},
    this.variants = const {},
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });
  
  FeatureFlagsState copyWith({
    Map<String, bool>? flags,
    Map<String, String>? variants,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return FeatureFlagsState(
      flags: flags ?? this.flags,
      variants: variants ?? this.variants,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  /// Check if a feature is enabled
  bool isEnabled(String featureKey) {
    return flags[featureKey] ?? false;
  }
  
  /// Get variant for A/B testing
  String? getVariant(String featureKey) {
    return variants[featureKey];
  }
}

/// Feature flags notifier
class FeatureFlagsNotifier extends StateNotifier<FeatureFlagsState> {
  final AnalyticsApiService _api;
  static const String _cacheKey = 'feature_flags_cache';
  static const Duration _cacheExpiry = Duration(minutes: 30);
  
  FeatureFlagsNotifier(this._api) : super(const FeatureFlagsState()) {
    _loadCachedFlags();
  }
  
  /// Load cached flags from SharedPreferences
  Future<void> _loadCachedFlags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      
      if (cached != null) {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        final cachedAt = DateTime.parse(data['cached_at'] as String);
        
        // Check if cache is still valid
        if (DateTime.now().difference(cachedAt) < _cacheExpiry) {
          state = state.copyWith(
            flags: Map<String, bool>.from(data['flags'] ?? {}),
            variants: Map<String, String>.from(data['variants'] ?? {}),
            lastUpdated: cachedAt,
          );
        }
      }
    } catch (e) {
      // Ignore cache errors
    }
    
    // Always fetch fresh flags
    await fetchFlags();
  }
  
  /// Fetch feature flags from backend
  Future<void> fetchFlags() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _api.evaluateFlags();
    
    result.when(
      success: (response) async {
        state = state.copyWith(
          flags: response.flags,
          variants: response.variants,
          isLoading: false,
          lastUpdated: DateTime.now(),
        );
        
        // Cache flags
        await _cacheFlags(response.flags, response.variants);
      },
      error: (error) {
        state = state.copyWith(
          isLoading: false,
          error: error.message,
        );
      },
    );
  }
  
  /// Cache flags to SharedPreferences
  Future<void> _cacheFlags(
    Map<String, bool> flags,
    Map<String, String> variants,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'flags': flags,
        'variants': variants,
        'cached_at': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_cacheKey, jsonEncode(data));
    } catch (e) {
      // Ignore cache errors
    }
  }
  
  /// Force refresh flags
  Future<void> refresh() => fetchFlags();
  
  /// Check if feature is enabled (convenience method)
  bool isEnabled(String featureKey) => state.isEnabled(featureKey);
  
  /// Get variant (convenience method)
  String? getVariant(String featureKey) => state.getVariant(featureKey);
}

/// Provider for feature flags
final featureFlagsProvider = StateNotifierProvider<FeatureFlagsNotifier, FeatureFlagsState>((ref) {
  final api = ref.watch(analyticsApiServiceProvider);
  return FeatureFlagsNotifier(api);
});

/// Convenience provider to check a single feature
final featureEnabledProvider = Provider.family<bool, String>((ref, featureKey) {
  return ref.watch(featureFlagsProvider).isEnabled(featureKey);
});

/// Convenience provider to get feature variant
final featureVariantProvider = Provider.family<String?, String>((ref, featureKey) {
  return ref.watch(featureFlagsProvider).getVariant(featureKey);
});
