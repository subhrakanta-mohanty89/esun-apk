/// Data Export Providers
///
/// Riverpod providers for secure data export and advisor sharing.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_service.dart';

// ============================================================================
// Data Models
// ============================================================================

/// Export format options
enum ExportFormat { csv, pdf }

/// Sharing method options
enum ShareMethod { secureLink, pgpEncrypted }

/// Export status
enum ExportStatus {
  pending,
  processing,
  completed,
  expired,
  failed,
  downloaded,
}

/// Export category
enum ExportCategory {
  transactions,
  accounts,
  investments,
  loans,
  insurance,
  creditReport,
  financialSummary,
  personaAnalysis,
}

extension ExportCategoryX on ExportCategory {
  String get apiValue {
    switch (this) {
      case ExportCategory.transactions:
        return 'transactions';
      case ExportCategory.accounts:
        return 'accounts';
      case ExportCategory.investments:
        return 'investments';
      case ExportCategory.loans:
        return 'loans';
      case ExportCategory.insurance:
        return 'insurance';
      case ExportCategory.creditReport:
        return 'credit_report';
      case ExportCategory.financialSummary:
        return 'financial_summary';
      case ExportCategory.personaAnalysis:
        return 'persona_analysis';
    }
  }

  String get displayName {
    switch (this) {
      case ExportCategory.transactions:
        return 'Transactions';
      case ExportCategory.accounts:
        return 'Bank Accounts';
      case ExportCategory.investments:
        return 'Investments';
      case ExportCategory.loans:
        return 'Loans';
      case ExportCategory.insurance:
        return 'Insurance';
      case ExportCategory.creditReport:
        return 'Credit Report';
      case ExportCategory.financialSummary:
        return 'Financial Summary';
      case ExportCategory.personaAnalysis:
        return 'Persona Analysis';
    }
  }

  String get description {
    switch (this) {
      case ExportCategory.transactions:
        return 'Bank and card transactions';
      case ExportCategory.accounts:
        return 'Linked bank accounts';
      case ExportCategory.investments:
        return 'Mutual funds, stocks, and other investments';
      case ExportCategory.loans:
        return 'Active loans and EMIs';
      case ExportCategory.insurance:
        return 'Insurance policies';
      case ExportCategory.creditReport:
        return 'Credit score and history';
      case ExportCategory.financialSummary:
        return 'Overall financial overview';
      case ExportCategory.personaAnalysis:
        return 'AI-generated financial persona';
    }
  }
}

/// Data export model
class DataExport {
  final String id;
  final ExportFormat format;
  final List<String> categories;
  final ExportStatus status;
  final bool isEncrypted;
  final int? fileSizeBytes;
  final ShareMethod? shareMethod;
  final String? sharedWithEmail;
  final DateTime? linkExpiresAt;
  final int downloadCount;
  final int maxDownloads;
  final bool consentGiven;
  final DateTime createdAt;
  final String? downloadUrl;
  final String? encryptionKey;

  const DataExport({
    required this.id,
    required this.format,
    required this.categories,
    required this.status,
    this.isEncrypted = true,
    this.fileSizeBytes,
    this.shareMethod,
    this.sharedWithEmail,
    this.linkExpiresAt,
    this.downloadCount = 0,
    this.maxDownloads = 1,
    this.consentGiven = false,
    required this.createdAt,
    this.downloadUrl,
    this.encryptionKey,
  });

  factory DataExport.fromJson(Map<String, dynamic> json) {
    return DataExport(
      id: json['id'] as String,
      format: ExportFormat.values.firstWhere(
        (e) => e.name == (json['export_format'] as String? ?? 'csv'),
        orElse: () => ExportFormat.csv,
      ),
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      status: _parseStatus(json['status'] as String?),
      isEncrypted: json['is_encrypted'] as bool? ?? true,
      fileSizeBytes: json['file_size_bytes'] as int?,
      shareMethod: json['share_method'] != null
          ? (json['share_method'] == 'secure_link'
              ? ShareMethod.secureLink
              : ShareMethod.pgpEncrypted)
          : null,
      sharedWithEmail: json['shared_with_email'] as String?,
      linkExpiresAt: json['link_expires_at'] != null
          ? DateTime.parse(json['link_expires_at'] as String)
          : null,
      downloadCount: json['download_count'] as int? ?? 0,
      maxDownloads: json['max_downloads'] as int? ?? 1,
      consentGiven: json['consent_given'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      downloadUrl: json['download_url'] as String?,
      encryptionKey: json['encryption_key'] as String?,
    );
  }

  static ExportStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return ExportStatus.pending;
      case 'processing':
        return ExportStatus.processing;
      case 'completed':
        return ExportStatus.completed;
      case 'expired':
        return ExportStatus.expired;
      case 'failed':
        return ExportStatus.failed;
      case 'downloaded':
        return ExportStatus.downloaded;
      default:
        return ExportStatus.pending;
    }
  }

  String get statusDisplay {
    switch (status) {
      case ExportStatus.pending:
        return 'Pending';
      case ExportStatus.processing:
        return 'Processing';
      case ExportStatus.completed:
        return 'Ready';
      case ExportStatus.expired:
        return 'Expired';
      case ExportStatus.failed:
        return 'Failed';
      case ExportStatus.downloaded:
        return 'Downloaded';
    }
  }

  String get fileSizeDisplay {
    if (fileSizeBytes == null) return '-';
    if (fileSizeBytes! < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes! < 1048576) return '${(fileSizeBytes! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes! / 1048576).toStringAsFixed(1)} MB';
  }
}

/// Audit log entry
class ExportAuditLog {
  final String id;
  final String exportId;
  final String action;
  final DateTime actionTimestamp;
  final String? ipAddress;
  final List<String>? fieldsExported;
  final int? recordCount;
  final String? recipientEmail;
  final String? recipientType;

  const ExportAuditLog({
    required this.id,
    required this.exportId,
    required this.action,
    required this.actionTimestamp,
    this.ipAddress,
    this.fieldsExported,
    this.recordCount,
    this.recipientEmail,
    this.recipientType,
  });

  factory ExportAuditLog.fromJson(Map<String, dynamic> json) {
    return ExportAuditLog(
      id: json['id'] as String,
      exportId: json['export_id'] as String,
      action: json['action'] as String,
      actionTimestamp: DateTime.parse(json['action_timestamp'] as String),
      ipAddress: json['ip_address'] as String?,
      fieldsExported: (json['fields_exported'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      recordCount: json['record_count'] as int?,
      recipientEmail: json['recipient_email'] as String?,
      recipientType: json['recipient_type'] as String?,
    );
  }

  String get actionDisplay {
    switch (action) {
      case 'created':
        return 'Export Created';
      case 'consent_given':
        return 'Consent Given';
      case 'exported':
        return 'File Generated';
      case 'shared':
        return 'Shared with Advisor';
      case 'downloaded':
        return 'Downloaded';
      case 'expired':
        return 'Link Expired';
      default:
        return action;
    }
  }
}

/// Share result after creating a secure share
class ShareResult {
  final ShareMethod method;
  final String? downloadUrl;
  final DateTime? expiresAt;
  final int? maxDownloads;
  final String? pgpKeyId;
  final String recipientEmail;
  final String? message;

  const ShareResult({
    required this.method,
    this.downloadUrl,
    this.expiresAt,
    this.maxDownloads,
    this.pgpKeyId,
    required this.recipientEmail,
    this.message,
  });

  factory ShareResult.fromJson(Map<String, dynamic> json) {
    return ShareResult(
      method: json['share_method'] == 'secure_link'
          ? ShareMethod.secureLink
          : ShareMethod.pgpEncrypted,
      downloadUrl: json['download_url'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      maxDownloads: json['max_downloads'] as int?,
      pgpKeyId: json['pgp_key_id'] as String?,
      recipientEmail: json['recipient_email'] as String,
      message: json['message'] as String?,
    );
  }
}

// ============================================================================
// State
// ============================================================================

class ExportState {
  final List<DataExport> exports;
  final bool isLoading;
  final bool isCreating;
  final bool isProcessing;
  final bool isSharing;
  final String? error;
  final DataExport? lastCreatedExport;
  final ShareResult? lastShareResult;
  final List<ExportAuditLog> auditLogs;

  const ExportState({
    this.exports = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.isProcessing = false,
    this.isSharing = false,
    this.error,
    this.lastCreatedExport,
    this.lastShareResult,
    this.auditLogs = const [],
  });

  ExportState copyWith({
    List<DataExport>? exports,
    bool? isLoading,
    bool? isCreating,
    bool? isProcessing,
    bool? isSharing,
    String? error,
    DataExport? lastCreatedExport,
    ShareResult? lastShareResult,
    List<ExportAuditLog>? auditLogs,
  }) {
    return ExportState(
      exports: exports ?? this.exports,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isProcessing: isProcessing ?? this.isProcessing,
      isSharing: isSharing ?? this.isSharing,
      error: error,
      lastCreatedExport: lastCreatedExport ?? this.lastCreatedExport,
      lastShareResult: lastShareResult ?? this.lastShareResult,
      auditLogs: auditLogs ?? this.auditLogs,
    );
  }
}

// ============================================================================
// Notifier
// ============================================================================

class ExportNotifier extends StateNotifier<ExportState> {
  final ApiService _api;

  ExportNotifier(this._api) : super(const ExportState());

  /// Load user's exports
  Future<void> loadExports() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/exports',
      parser: (data) => data as Map<String, dynamic>,
    );

    result.when(
      success: (data) {
        final exports = (data['exports'] as List<dynamic>)
            .map((e) => DataExport.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(
          exports: exports,
          isLoading: false,
        );
      },
      error: (e) {
        state = state.copyWith(
          isLoading: false,
          error: e.message,
        );
      },
    );
  }

  /// Create a new export with consent
  Future<DataExport?> createExport({
    required ExportFormat format,
    required List<ExportCategory> categories,
    DateTime? dateRangeStart,
    DateTime? dateRangeEnd,
    Map<String, List<String>>? fieldConfig,
  }) async {
    state = state.copyWith(isCreating: true, error: null);

    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/exports',
      data: {
        'format': format.name,
        'categories': categories.map((c) => c.apiValue).toList(),
        if (dateRangeStart != null)
          'date_range_start': dateRangeStart.toIso8601String(),
        if (dateRangeEnd != null)
          'date_range_end': dateRangeEnd.toIso8601String(),
        if (fieldConfig != null) 'field_config': fieldConfig,
        'consent': true,
        'consent_statement':
            'I consent to export my financial data as per ESUN privacy policy.',
      },
      parser: (data) => data as Map<String, dynamic>,
    );

    return result.when(
      success: (data) {
        final export =
            DataExport.fromJson(data['export'] as Map<String, dynamic>);
        state = state.copyWith(
          isCreating: false,
          lastCreatedExport: export,
          exports: [export, ...state.exports],
        );
        return export;
      },
      error: (e) {
        state = state.copyWith(
          isCreating: false,
          error: e.message,
        );
        return null;
      },
    );
  }

  /// Process export and generate file
  Future<DataExport?> processExport(String exportId, {String? userName}) async {
    state = state.copyWith(isProcessing: true, error: null);

    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/exports/$exportId/process',
      data: {
        if (userName != null) 'user_name': userName,
      },
      parser: (data) => data as Map<String, dynamic>,
    );

    return result.when(
      success: (data) {
        final export =
            DataExport.fromJson(data['export'] as Map<String, dynamic>);
        
        // Include encryption key from response
        final encryptionKey = data['encryption_key'] as String?;
        final exportWithKey = DataExport(
          id: export.id,
          format: export.format,
          categories: export.categories,
          status: export.status,
          isEncrypted: export.isEncrypted,
          fileSizeBytes: export.fileSizeBytes,
          shareMethod: export.shareMethod,
          sharedWithEmail: export.sharedWithEmail,
          linkExpiresAt: export.linkExpiresAt,
          downloadCount: export.downloadCount,
          maxDownloads: export.maxDownloads,
          consentGiven: export.consentGiven,
          createdAt: export.createdAt,
          encryptionKey: encryptionKey,
        );

        // Update exports list
        final updatedExports = state.exports.map((e) {
          return e.id == exportId ? exportWithKey : e;
        }).toList();

        state = state.copyWith(
          isProcessing: false,
          lastCreatedExport: exportWithKey,
          exports: updatedExports,
        );
        return exportWithKey;
      },
      error: (e) {
        state = state.copyWith(
          isProcessing: false,
          error: e.message,
        );
        return null;
      },
    );
  }

  /// Share export with advisor
  Future<ShareResult?> shareExport({
    required String exportId,
    required ShareMethod method,
    required String recipientEmail,
    String? recipientName,
    int expiryHours = 24,
    int maxDownloads = 1,
    String? pgpPublicKey,
  }) async {
    state = state.copyWith(isSharing: true, error: null);

    final result = await _api.post<Map<String, dynamic>>(
      '/api/v1/exports/$exportId/share',
      data: {
        'method': method == ShareMethod.secureLink
            ? 'secure_link'
            : 'pgp_encrypted',
        'recipient_email': recipientEmail,
        if (recipientName != null) 'recipient_name': recipientName,
        'expiry_hours': expiryHours,
        'max_downloads': maxDownloads,
        if (pgpPublicKey != null) 'pgp_public_key': pgpPublicKey,
      },
      parser: (data) => data as Map<String, dynamic>,
    );

    return result.when(
      success: (data) {
        final shareResult =
            ShareResult.fromJson(data['share'] as Map<String, dynamic>);
        state = state.copyWith(
          isSharing: false,
          lastShareResult: shareResult,
        );
        return shareResult;
      },
      error: (e) {
        state = state.copyWith(
          isSharing: false,
          error: e.message,
        );
        return null;
      },
    );
  }

  /// Load audit log for an export
  Future<void> loadAuditLog(String exportId) async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/v1/exports/$exportId/audit',
      parser: (data) => data as Map<String, dynamic>,
    );

    result.when(
      success: (data) {
        final logs = (data['audit_logs'] as List<dynamic>)
            .map((e) => ExportAuditLog.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(auditLogs: logs);
      },
      error: (e) {
        state = state.copyWith(error: e.message);
      },
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear last results
  void clearLastResults() {
    state = state.copyWith(
      lastCreatedExport: null,
      lastShareResult: null,
    );
  }
}

// ============================================================================
// Providers
// ============================================================================

/// Main export state provider
final exportProvider =
    StateNotifierProvider<ExportNotifier, ExportState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return ExportNotifier(api);
});

/// Available export categories
final exportCategoriesProvider = Provider<List<ExportCategory>>((ref) {
  return ExportCategory.values;
});

/// Consent text for export
final exportConsentTextProvider = Provider<String>((ref) {
  return '''
I understand and consent to the following:

1. My financial data will be exported and may be shared with third parties I designate.

2. The export will include the categories I have selected, which may contain sensitive financial information.

3. This data is protected under RBI, SEBI, IRDAI, and PFRDA regulations.

4. I am responsible for the secure handling of any downloaded files or shared links.

5. ESUN maintains audit logs of all export activities for compliance purposes.

6. Shared links will expire after the specified time period.

By proceeding, I confirm that I have read and agree to these terms.
''';
});
