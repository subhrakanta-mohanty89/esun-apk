/// ESUN Analytics Service
///
/// Centralized analytics logging for tracking user events and actions.
/// Integrates with Firebase Analytics and backend API for dual tracking.

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_api_service.dart';

/// Analytics event names
abstract class AnalyticsEvents {
  // Data Linking Events
  static const String linkDataPopupShown = 'link_data_popup_shown';
  static const String linkDataPopupDismissed = 'link_data_popup_dismissed';
  static const String linkAccountAggregatorClicked = 'link_account_aggregator_clicked';
  static const String linkCreditBureauClicked = 'link_credit_bureau_clicked';
  static const String remindMeLaterClicked = 'remind_me_later_clicked';
  
  // AA Events (Conversion Funnel)
  static const String aaPromptShown = 'aa_prompt_shown';
  static const String aaPromptClicked = 'aa_prompt_clicked';
  static const String aaOnboardingStarted = 'aa_onboarding_started';
  static const String aaOnboardingCompleted = 'aa_onboarding_completed';
  static const String aaPanVerified = 'aa_pan_verified';
  static const String aaAccountsDiscovered = 'aa_accounts_discovered';
  static const String aaConsentGiven = 'aa_consent_given';
  static const String aaConsentDenied = 'aa_consent_denied';
  static const String aaLinkedSuccess = 'aa_linked_success';
  static const String aaLinkedFailed = 'aa_linked_failed';
  static const String aaRemindLater = 'aa_remind_later';
  
  // Credit Bureau Events (Conversion Funnel)
  static const String cbPromptShown = 'cb_prompt_shown';
  static const String cbPromptClicked = 'cb_prompt_clicked';
  static const String creditBureauFlowStarted = 'credit_bureau_flow_started';
  static const String creditBureauConsentGiven = 'credit_bureau_consent_given';
  static const String creditBureauConnected = 'credit_bureau_connected';
  
  // Export Events (Usage)
  static const String exportInitiated = 'export_initiated';
  static const String exportCompleted = 'export_completed';
  static const String exportDownload = 'export_download';
  static const String exportShared = 'export_shared';
  static const String exportFailed = 'export_failed';
  
  // Auth Events
  static const String loginSuccess = 'login_success';
  static const String loginFailed = 'login_failed';
  static const String registrationStarted = 'registration_started';
  static const String registrationCompleted = 'registration_completed';
  static const String logout = 'logout';
}

/// Event categories for backend tracking
abstract class EventCategories {
  static const String conversion = 'conversion';
  static const String usage = 'usage';
  static const String error = 'error';
  static const String performance = 'performance';
}

/// Analytics service provider
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final apiService = ref.watch(analyticsApiServiceProvider);
  return AnalyticsService(apiService);
});

/// Analytics Service
/// 
/// Handles all analytics event logging throughout the app.
/// Dual tracking: Firebase Analytics + Backend API.
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final AnalyticsApiService _apiService;
  
  String? _sessionId;
  
  AnalyticsService(this._apiService) {
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  /// Log a custom event with optional parameters
  /// Tracks to Firebase Analytics only (lightweight events)
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      // Silently fail - analytics should never break the app
      print('Analytics error: $e');
    }
  }
  
  /// Log event with dual tracking (Firebase + Backend)
  /// Use for important conversion and error events
  Future<void> logEventWithBackend({
    required String name,
    required String category,
    Map<String, Object>? parameters,
    String? action,
    String? label,
    double? value,
    bool isError = false,
  }) async {
    // Track to Firebase
    await logEvent(name: name, parameters: parameters);
    
    // Track to backend asynchronously
    _apiService.trackEvent(AnalyticsEventData(
      eventType: name,
      eventCategory: category,
      sessionId: _sessionId,
      action: action,
      label: label,
      value: value,
      metadata: parameters?.map((k, v) => MapEntry(k, v.toString())),
    ));
  }
  
  /// Log link data popup shown
  Future<void> logLinkDataPopupShown({
    required bool aaConnected,
    required bool creditBureauConnected,
  }) async {
    await logEvent(
      name: AnalyticsEvents.linkDataPopupShown,
      parameters: {
        'aa_connected': aaConnected,
        'credit_bureau_connected': creditBureauConnected,
      },
    );
  }
  
  /// Log link data popup action
  Future<void> logLinkDataAction(String action) async {
    await logEvent(
      name: action,
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
  
  /// Log screen view
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }
  
  /// Set user ID for analytics
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }
  
  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }
  
  // =========================================================================
  // AA Conversion Funnel Tracking
  // =========================================================================
  
  /// Log AA linking prompt shown
  Future<void> logAAPromptShown({bool aaConnected = false}) async {
    await logEventWithBackend(
      name: AnalyticsEvents.aaPromptShown,
      category: EventCategories.conversion,
      parameters: {
        'aa_connected': aaConnected,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
  
  /// Log AA linking prompt clicked
  Future<void> logAAPromptClicked() async {
    await logEventWithBackend(
      name: AnalyticsEvents.aaPromptClicked,
      category: EventCategories.conversion,
    );
  }
  
  /// Log AA linked successfully
  Future<void> logAALinkedSuccess({
    required int accountCount,
    required List<String> fips,
  }) async {
    await logEventWithBackend(
      name: AnalyticsEvents.aaLinkedSuccess,
      category: EventCategories.conversion,
      parameters: {
        'account_count': accountCount,
        'fips': fips.join(','),
        'timestamp': DateTime.now().toIso8601String(),
      },
      value: accountCount.toDouble(),
    );
  }
  
  /// Log AA linking failed
  Future<void> logAALinkedFailed({
    required String errorCode,
    String? errorMessage,
  }) async {
    await logEventWithBackend(
      name: AnalyticsEvents.aaLinkedFailed,
      category: EventCategories.error,
      isError: true,
      parameters: {
        'error_code': errorCode,
        'error_message': errorMessage ?? 'Unknown error',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
  
  // =========================================================================
  // Credit Bureau Funnel Tracking
  // =========================================================================
  
  /// Log Credit Bureau prompt shown
  Future<void> logCBPromptShown() async {
    await logEventWithBackend(
      name: AnalyticsEvents.cbPromptShown,
      category: EventCategories.conversion,
    );
  }
  
  /// Log Credit Bureau connected
  Future<void> logCBConnected({
    required String bureau,
    int? creditScore,
  }) async {
    await logEventWithBackend(
      name: AnalyticsEvents.creditBureauConnected,
      category: EventCategories.conversion,
      parameters: {
        'bureau': bureau,
        if (creditScore != null) 'credit_score': creditScore,
        'timestamp': DateTime.now().toIso8601String(),
      },
      value: creditScore?.toDouble(),
    );
  }
  
  // =========================================================================
  // Export Usage Tracking
  // =========================================================================
  
  /// Log export initiated
  Future<void> logExportInitiated({
    required String format,
    required List<String> categories,
  }) async {
    await logEventWithBackend(
      name: AnalyticsEvents.exportInitiated,
      category: EventCategories.usage,
      parameters: {
        'format': format,
        'categories': categories.join(','),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
  
  /// Log export download
  Future<void> logExportDownload({required String exportId}) async {
    await logEventWithBackend(
      name: AnalyticsEvents.exportDownload,
      category: EventCategories.usage,
      parameters: {
        'export_id': exportId,
        'timestamp': DateTime.now().toIso8601String(),
      },
      label: exportId,
    );
  }
  
  /// Log export shared
  Future<void> logExportShared({
    required String exportId,
    required String shareMethod,
  }) async {
    await logEventWithBackend(
      name: AnalyticsEvents.exportShared,
      category: EventCategories.usage,
      parameters: {
        'export_id': exportId,
        'share_method': shareMethod,
        'timestamp': DateTime.now().toIso8601String(),
      },
      action: shareMethod,
      label: exportId,
    );
  }
}
