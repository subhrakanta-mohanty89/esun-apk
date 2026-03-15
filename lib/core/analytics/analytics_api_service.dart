/// Analytics API Service
///
/// Client for backend analytics API integration.
/// Handles event reporting, dashboard data fetching, and feature flags.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_service.dart';
import '../utils/utils.dart';

/// Provider for AnalyticsApiService
final analyticsApiServiceProvider = Provider<AnalyticsApiService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AnalyticsApiService(apiService);
});

/// Analytics event data class
class AnalyticsEventData {
  final String eventType;
  final String eventCategory;
  final String? sessionId;
  final String? action;
  final String? label;
  final double? value;
  final Map<String, dynamic>? metadata;
  
  AnalyticsEventData({
    required this.eventType,
    this.eventCategory = 'usage',
    this.sessionId,
    this.action,
    this.label,
    this.value,
    this.metadata,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'event_type': eventType,
      'event_category': eventCategory,
      if (sessionId != null) 'session_id': sessionId,
      if (action != null) 'action': action,
      if (label != null) 'label': label,
      if (value != null) 'value': value,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

/// Feature flags response
class FeatureFlagsResponse {
  final Map<String, bool> flags;
  final Map<String, String> variants;
  
  FeatureFlagsResponse({
    required this.flags,
    required this.variants,
  });
  
  factory FeatureFlagsResponse.fromJson(Map<String, dynamic> json) {
    return FeatureFlagsResponse(
      flags: Map<String, bool>.from(json['flags'] ?? {}),
      variants: Map<String, String>.from(json['variants'] ?? {}),
    );
  }
  
  /// Check if a feature is enabled
  bool isEnabled(String featureKey) {
    return flags[featureKey] ?? false;
  }
  
  /// Get variant for a feature (A/B test)
  String? getVariant(String featureKey) {
    return variants[featureKey];
  }
}

/// Analytics API Service
/// 
/// Handles:
/// - Event tracking (sync with backend)
/// - Feature flag evaluation
/// - Dashboard data fetching (for admin screens)
class AnalyticsApiService {
  final ApiService _api;
  
  static const String _basePath = '/api/v1/analytics';
  static const String _featureFlagsPath = '/api/v1/feature-flags';
  
  AnalyticsApiService(this._api);
  
  // =========================================================================
  // Event Tracking
  // =========================================================================
  
  /// Track an event via backend API
  ///
  /// Use this for events that need server-side tracking in addition to
  /// Firebase Analytics.
  Future<Result<bool>> trackEvent(AnalyticsEventData event) async {
    final result = await _api.post<Map<String, dynamic>>(
      '$_basePath/events',
      data: event.toJson(),
    );
    
    return result.isSuccess ? const Success(true) : Error(result.error ?? const AppException(message: 'Failed to track event'));
  }
  
  /// Track multiple events in batch
  Future<Result<bool>> trackEvents(List<AnalyticsEventData> events) async {
    final results = await Future.wait(
      events.map((e) => trackEvent(e)),
    );
    
    // Return success if all events tracked
    final allSuccess = results.every((r) => r.isSuccess);
    
    return allSuccess 
      ? const Success(true)
      : const Error(AppException(message: 'Some events failed to track'));
  }
  
  // =========================================================================
  // Feature Flags
  // =========================================================================
  
  /// Evaluate all feature flags for current user
  Future<Result<FeatureFlagsResponse>> evaluateFlags() async {
    final result = await _api.get<Map<String, dynamic>>(
      '$_featureFlagsPath/evaluate',
    );
    
    return result.isSuccess 
        ? Success(FeatureFlagsResponse.fromJson(result.data!))
        : Error(result.error ?? const AppException(message: 'Failed to evaluate flags'));
  }
  
  /// Evaluate a single feature flag
  Future<Result<bool>> isFeatureEnabled(String featureKey) async {
    final result = await _api.get<Map<String, dynamic>>(
      '$_featureFlagsPath/evaluate/$featureKey',
    );
    
    return result.isSuccess 
        ? Success(result.data!['is_enabled'] == true)
        : Error(result.error ?? const AppException(message: 'Failed to check feature'));
  }
  
  /// Get feature variant (for A/B testing)
  Future<Result<String?>> getFeatureVariant(String featureKey) async {
    final result = await _api.get<Map<String, dynamic>>(
      '$_featureFlagsPath/evaluate/$featureKey',
    );
    
    return result.isSuccess 
        ? Success(result.data!['variant'] as String?)
        : Error(result.error ?? const AppException(message: 'Failed to get variant'));
  }
  
  // =========================================================================
  // Admin Dashboard (for admin screens)
  // =========================================================================
  
  /// Get dashboard KPIs
  Future<Result<Map<String, dynamic>>> getDashboard({
    int days = 30,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{'days': days};
    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate.toIso8601String();
    }
    
    return _api.get<Map<String, dynamic>>(
      '$_basePath/dashboard',
      queryParameters: queryParams,
    );
  }
  
  /// Get conversion funnel data
  Future<Result<Map<String, dynamic>>> getConversionFunnel(
    String funnelType, {
    int days = 30,
  }) async {
    return _api.get<Map<String, dynamic>>(
      '$_basePath/conversion/$funnelType',
      queryParameters: {'days': days},
    );
  }
  
  /// Get export usage statistics
  Future<Result<Map<String, dynamic>>> getExportStats({int days = 30}) async {
    return _api.get<Map<String, dynamic>>(
      '$_basePath/exports',
      queryParameters: {'days': days},
    );
  }
  
  /// Get error metrics
  Future<Result<Map<String, dynamic>>> getErrorMetrics({int days = 7}) async {
    return _api.get<Map<String, dynamic>>(
      '$_basePath/errors',
      queryParameters: {'days': days},
    );
  }
  
  /// Get active alerts
  Future<Result<List<Map<String, dynamic>>>> getAlerts() async {
    final result = await _api.get<Map<String, dynamic>>(
      '$_basePath/alerts',
    );
    
    if (result.isSuccess && result.data != null) {
      final alerts = result.data!['alerts'] as List<dynamic>? ?? [];
      return Success(alerts.cast<Map<String, dynamic>>());
    }
    return Error(result.error ?? const AppException(message: 'Failed to get alerts'));
  }
  
  /// Resolve an alert
  Future<Result<bool>> resolveAlert(
    String alertId, {
    String? resolutionNotes,
  }) async {
    final result = await _api.put<Map<String, dynamic>>(
      '$_basePath/alerts/$alertId/resolve',
      data: {
        if (resolutionNotes != null) 'resolution_notes': resolutionNotes,
      },
    );
    
    return result.isSuccess 
        ? const Success(true)
        : Error(result.error ?? const AppException(message: 'Failed to resolve alert'));
  }
}
