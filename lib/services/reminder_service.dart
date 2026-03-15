/// ESUN Reminder Service
///
/// Handles reminder scheduling for data linking via backend API.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_service.dart';

/// Reminder type enum
enum ReminderType {
  accountAggregator('account_aggregator'),
  creditBureau('credit_bureau');

  final String value;
  const ReminderType(this.value);
}

/// Reminder channel enum
enum ReminderChannel {
  push('push'),
  email('email'),
  both('both');

  final String value;
  const ReminderChannel(this.value);
}

/// Reminder hours options
enum ReminderHours {
  hours24(24, '24 hours'),
  hours72(72, '3 days'),
  hours168(168, '7 days');

  final int hours;
  final String label;
  const ReminderHours(this.hours, this.label);
}

/// Linking status model
class LinkingStatus {
  final ConnectionInfo accountAggregator;
  final ConnectionInfo creditBureau;
  final bool needsAttention;
  final bool hasErrors;
  final DashboardBadge? badge;

  const LinkingStatus({
    required this.accountAggregator,
    required this.creditBureau,
    required this.needsAttention,
    required this.hasErrors,
    this.badge,
  });

  factory LinkingStatus.fromJson(Map<String, dynamic> json) {
    return LinkingStatus(
      accountAggregator: ConnectionInfo.fromJson(
        json['account_aggregator'] as Map<String, dynamic>? ?? {},
      ),
      creditBureau: ConnectionInfo.fromJson(
        json['credit_bureau'] as Map<String, dynamic>? ?? {},
      ),
      needsAttention: json['needs_attention'] as bool? ?? false,
      hasErrors: json['has_errors'] as bool? ?? false,
      badge: json['dashboard_badge'] != null
          ? DashboardBadge.fromJson(json['dashboard_badge'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Connection info model
class ConnectionInfo {
  final String connectionId;
  final String status;
  final bool isConnected;
  final bool hasError;
  final String? errorMessage;
  final DateTime? expiry;
  final bool requiresRelink;
  final String? ctaText;
  final String? ctaAction;

  const ConnectionInfo({
    required this.connectionId,
    required this.status,
    required this.isConnected,
    required this.hasError,
    this.errorMessage,
    this.expiry,
    required this.requiresRelink,
    this.ctaText,
    this.ctaAction,
  });

  factory ConnectionInfo.fromJson(Map<String, dynamic> json) {
    return ConnectionInfo(
      connectionId: json['connection_id'] as String? ?? '',
      status: json['status'] as String? ?? 'not_linked',
      isConnected: json['is_connected'] as bool? ?? false,
      hasError: json['has_error'] as bool? ?? false,
      errorMessage: json['error_message'] as String?,
      expiry: json['expiry'] != null
          ? DateTime.tryParse(json['expiry'] as String)
          : null,
      requiresRelink: json['requires_relink'] as bool? ?? false,
      ctaText: json['cta_text'] as String?,
      ctaAction: json['cta_action'] as String?,
    );
  }
}

/// Dashboard badge model
class DashboardBadge {
  final String type;
  final String message;
  final String priority;

  const DashboardBadge({
    required this.type,
    required this.message,
    required this.priority,
  });

  factory DashboardBadge.fromJson(Map<String, dynamic> json) {
    return DashboardBadge(
      type: json['type'] as String? ?? 'warning',
      message: json['message'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
    );
  }
}

/// Reminder service class
class ReminderService {
  final ApiService _api;

  ReminderService(this._api);

  /// Set a "remind me later" reminder
  Future<bool> setReminder({
    required ReminderType type,
    required ReminderHours hours,
    ReminderChannel channel = ReminderChannel.push,
  }) async {
    final result = await _api.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/reminders/remind-later',
      data: {
        'reminder_type': type.value,
        'reminder_hours': hours.hours,
        'channel': channel.value,
      },
    );

    return result.isSuccess;
  }

  /// Get linking status for dashboard
  Future<LinkingStatus?> getLinkingStatus() async {
    final result = await _api.get<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/reminders/linking-status',
    );

    if (result.isError || result.data == null) {
      return null;
    }

    final data = result.data!['data'] as Map<String, dynamic>? ?? {};
    return LinkingStatus.fromJson(data);
  }

  /// Record a linking failure
  Future<bool> recordFailure({
    required ReminderType type,
    required String reason,
  }) async {
    final result = await _api.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/reminders/record-failure',
      data: {
        'connection_type': type.value,
        'failure_reason': reason,
      },
    );

    return result.isSuccess;
  }

  /// Dismiss a reminder
  Future<bool> dismissReminder(String reminderId) async {
    final result = await _api.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/reminders/reminders/$reminderId/dismiss',
    );

    return result.isSuccess;
  }
}

/// Provider for reminder service
final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService(ref.read(apiServiceProvider));
});

/// Provider for linking status
final linkingStatusProvider = FutureProvider<LinkingStatus?>((ref) async {
  final service = ref.read(reminderServiceProvider);
  return service.getLinkingStatus();
});
