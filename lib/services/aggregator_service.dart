/// ESUN Aggregator Service
/// 
/// Handles Account Aggregator data operations including:
/// - Consent management
/// - FIP listing
/// - Data fetching
/// - Account summaries
/// - Transaction insights

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_service.dart';
import '../state/app_state.dart';

// ============================================================================
// Providers
// ============================================================================

/// Aggregator Service Provider
final aggregatorServiceProvider = Provider<AggregatorService>((ref) {
  final api = ref.watch(apiServiceProvider);
  return AggregatorService(api);
});

/// Aggregator State Provider
final aggregatorStateProvider =
    StateNotifierProvider<AggregatorStateNotifier, AggregatorState>((ref) {
  return AggregatorStateNotifier(ref);
});

// ============================================================================
// State
// ============================================================================

class AggregatorState {
  final bool isLoading;
  final String? error;
  final List<ConsentInfo> consents;
  final ConsentInfo? activeConsent;
  final List<FIPInfo> availableFips;
  final List<LinkedAccount> accounts;
  final FinancialSummary? summary;
  final TransactionInsights? transactionInsights;
  final FetchStatus? currentFetchStatus;

  const AggregatorState({
    this.isLoading = false,
    this.error,
    this.consents = const [],
    this.activeConsent,
    this.availableFips = const [],
    this.accounts = const [],
    this.summary,
    this.transactionInsights,
    this.currentFetchStatus,
  });

  AggregatorState copyWith({
    bool? isLoading,
    String? error,
    List<ConsentInfo>? consents,
    ConsentInfo? activeConsent,
    List<FIPInfo>? availableFips,
    List<LinkedAccount>? accounts,
    FinancialSummary? summary,
    TransactionInsights? transactionInsights,
    FetchStatus? currentFetchStatus,
  }) {
    return AggregatorState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      consents: consents ?? this.consents,
      activeConsent: activeConsent ?? this.activeConsent,
      availableFips: availableFips ?? this.availableFips,
      accounts: accounts ?? this.accounts,
      summary: summary ?? this.summary,
      transactionInsights: transactionInsights ?? this.transactionInsights,
      currentFetchStatus: currentFetchStatus ?? this.currentFetchStatus,
    );
  }

  bool get hasActiveConsent => 
      activeConsent != null && 
      (activeConsent!.status == 'active' || activeConsent!.status == 'approved');
  
  bool get hasLinkedAccounts => accounts.isNotEmpty;
}

// ============================================================================
// State Notifier
// ============================================================================

class AggregatorStateNotifier extends StateNotifier<AggregatorState> {
  final Ref _ref;

  AggregatorStateNotifier(this._ref) : super(const AggregatorState());

  AggregatorService get _service => _ref.read(aggregatorServiceProvider);

  /// Sync auth state with aggregator linking status
  void _syncAuthState({bool? hasActiveConsent, bool? hasAccounts}) {
    final isLinked = (hasActiveConsent == true) || (hasAccounts == true);
    _ref.read(authStateProvider.notifier).updateLinkingStatus(aaConnected: isLinked);
  }

  void setError(String? error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Load all aggregator data
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load consents and accounts in parallel
      final results = await Future.wait([
        _service.getConsents(),
        _service.getAccounts(),
        _service.getFinancialSummary(),
      ]);

      final consentsResult = results[0] as AggregatorResult<List<ConsentInfo>>;
      final accountsResult = results[1] as AggregatorResult<List<LinkedAccount>>;
      final summaryResult = results[2] as AggregatorResult<FinancialSummary>;

      ConsentInfo? activeConsent;
      if (consentsResult.success && consentsResult.data != null) {
        final active = consentsResult.data!.where(
          (c) => c.status == 'active' || c.status == 'approved'
        ).toList();
        if (active.isNotEmpty) {
          activeConsent = active.first;
        }
      }

      state = state.copyWith(
        isLoading: false,
        consents: consentsResult.data ?? [],
        activeConsent: activeConsent,
        accounts: accountsResult.data ?? [],
        summary: summaryResult.data,
      );

      // Sync auth state with linking status
      _syncAuthState(
        hasActiveConsent: activeConsent != null,
        hasAccounts: (accountsResult.data ?? []).isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create a new consent
  Future<bool> createConsent({
    required String purpose,
    required List<String> fipIds,
    String fetchType = 'ONETIME',
    int dataRangeMonths = 12,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _service.createConsent(
      purpose: purpose,
      fipIds: fipIds,
      fetchType: fetchType,
      dataRangeMonths: dataRangeMonths,
    );

    if (result.success && result.data != null) {
      final consents = List<ConsentInfo>.from(state.consents)..add(result.data!);
      state = state.copyWith(
        isLoading: false,
        consents: consents,
        activeConsent: result.data,
      );

      // Update auth state to reflect successful linking
      _syncAuthState(hasActiveConsent: true);
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
      return false;
    }
  }

  /// Revoke a consent
  Future<bool> revokeConsent(String consentId, {String? reason}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _service.revokeConsent(consentId, reason: reason);

    if (result.success) {
      // Reload consents and sync auth state
      await loadConsents();
      // Check if we still have active consents or accounts
      _syncAuthState(
        hasActiveConsent: state.hasActiveConsent,
        hasAccounts: state.hasLinkedAccounts,
      );
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
      return false;
    }
  }

  /// Load available FIPs
  Future<void> loadFips({String? fiType}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _service.getFips(fiType: fiType);

    state = state.copyWith(
      isLoading: false,
      availableFips: result.data ?? [],
      error: result.success ? null : result.error,
    );
  }

  /// Load consents
  Future<void> loadConsents() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _service.getConsents();

    ConsentInfo? activeConsent;
    if (result.success && result.data != null) {
      final active = result.data!.where(
        (c) => c.status == 'active' || c.status == 'approved'
      ).toList();
      if (active.isNotEmpty) {
        activeConsent = active.first;
      }
    }

    state = state.copyWith(
      isLoading: false,
      consents: result.data ?? [],
      activeConsent: activeConsent,
      error: result.success ? null : result.error,
    );

    // Sync auth state with consent status
    _syncAuthState(
      hasActiveConsent: activeConsent != null,
      hasAccounts: state.hasLinkedAccounts,
    );
  }

  /// Fetch data from FIPs
  Future<bool> fetchData(String consentId, {List<String>? fiTypes}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _service.fetchData(consentId, fiTypes: fiTypes);

    if (result.success && result.data != null) {
      state = state.copyWith(
        isLoading: false,
        currentFetchStatus: result.data,
      );
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
      return false;
    }
  }

  /// Check fetch status
  Future<void> checkFetchStatus(String sessionId) async {
    final result = await _service.getFetchStatus(sessionId);

    if (result.success && result.data != null) {
      state = state.copyWith(currentFetchStatus: result.data);
    }
  }

  /// Load linked accounts
  Future<void> loadAccounts({String? accountType, bool includeInactive = false}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _service.getAccounts(
      accountType: accountType,
      includeInactive: includeInactive,
    );

    final accounts = result.data ?? [];
    state = state.copyWith(
      isLoading: false,
      accounts: accounts,
      error: result.success ? null : result.error,
    );

    // Sync auth state with account linking status
    _syncAuthState(
      hasActiveConsent: state.hasActiveConsent,
      hasAccounts: accounts.isNotEmpty,
    );
  }

  /// Load financial summary
  Future<void> loadSummary() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _service.getFinancialSummary();

    state = state.copyWith(
      isLoading: false,
      summary: result.data,
      error: result.success ? null : result.error,
    );
  }

  /// Load transaction insights
  Future<void> loadTransactionInsights({String? accountId, int months = 3}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _service.getTransactionInsights(
      accountId: accountId,
      months: months,
    );

    state = state.copyWith(
      isLoading: false,
      transactionInsights: result.data,
      error: result.success ? null : result.error,
    );
  }

  /// Sync/refresh data
  Future<bool> syncData({String? consentId}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _service.syncData(consentId: consentId);

    if (result.success) {
      // Reload accounts and summary after sync
      await loadAll();
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
      return false;
    }
  }
}

// ============================================================================
// Service
// ============================================================================

class AggregatorService {
  final ApiService _api;
  static const String _basePath = '${ApiConfig.apiPrefix}/aggregator';

  AggregatorService(this._api);

  /// Create a new consent
  Future<AggregatorResult<ConsentInfo>> createConsent({
    required String purpose,
    required List<String> fipIds,
    String fetchType = 'ONETIME',
    int dataRangeMonths = 12,
  }) async {
    final result = await _api.post<Map<String, dynamic>>(
      '$_basePath/consent',
      data: {
        'purpose': purpose,
        'fip_ids': fipIds,
        'fetch_type': fetchType,
        'data_range_months': dataRangeMonths,
      },
    );

    if (result.isError || result.data?['success'] != true) {
      return AggregatorResult.failure(
        result.data?['error']?['message'] ?? 'Failed to create consent',
      );
    }

    final data = result.data!['data'] as Map<String, dynamic>;
    return AggregatorResult.success(ConsentInfo.fromJson(data));
  }

  /// Get all consents
  Future<AggregatorResult<List<ConsentInfo>>> getConsents() async {
    final result = await _api.get<Map<String, dynamic>>('$_basePath/consent');

    if (result.isError || result.data?['success'] != true) {
      return AggregatorResult.failure(
        result.data?['error']?['message'] ?? 'Failed to get consents',
      );
    }

    final data = result.data!['data'] as List?;
    final consents = data?.map((c) => ConsentInfo.fromJson(c)).toList() ?? [];
    return AggregatorResult.success(consents);
  }

  /// Get specific consent
  Future<AggregatorResult<ConsentInfo>> getConsent(String consentId) async {
    final result = await _api.get<Map<String, dynamic>>(
      '$_basePath/consent/$consentId',
    );

    if (result.isError || result.data?['success'] != true) {
      return AggregatorResult.failure(
        result.data?['error']?['message'] ?? 'Consent not found',
      );
    }

    final data = result.data!['data'] as Map<String, dynamic>;
    return AggregatorResult.success(ConsentInfo.fromJson(data));
  }

  /// Revoke consent
  Future<AggregatorResult<void>> revokeConsent(String consentId, {String? reason}) async {
    final result = await _api.post<Map<String, dynamic>>(
      '$_basePath/consent/$consentId/revoke',
      data: reason != null ? {'reason': reason} : null,
    );

    if (result.isError || result.data?['success'] != true) {
      return AggregatorResult.failure(
        result.data?['error']?['message'] ?? 'Failed to revoke consent',
      );
    }

    return AggregatorResult.success(null);
  }

  /// Get available FIPs
  Future<AggregatorResult<List<FIPInfo>>> getFips({String? fiType}) async {
    final queryParams = fiType != null ? {'fi_type': fiType} : null;
    final result = await _api.get<Map<String, dynamic>>(
      '$_basePath/fips',
      queryParameters: queryParams,
    );

    if (result.isError || result.data?['success'] != true) {
      return AggregatorResult.failure(
        result.data?['error']?['message'] ?? 'Failed to get FIPs',
      );
    }

    final data = result.data!['data'] as List?;
    final fips = data?.map((f) => FIPInfo.fromJson(f)).toList() ?? [];
    return AggregatorResult.success(fips);
  }

  /// Initiate data fetch
  Future<AggregatorResult<FetchStatus>> fetchData(
    String consentId, {
    List<String>? fiTypes,
  }) async {
    final result = await _api.post<Map<String, dynamic>>(
      '$_basePath/fetch',
      data: {
        'consent_id': consentId,
        if (fiTypes != null) 'fi_types': fiTypes,
      },
    );

    if (result.isError || result.data?['success'] != true) {
      return AggregatorResult.failure(
        result.data?['error']?['message'] ?? 'Failed to initiate fetch',
      );
    }

    final data = result.data!['data'] as Map<String, dynamic>;
    return AggregatorResult.success(FetchStatus.fromJson(data));
  }

  /// Get fetch status
  Future<AggregatorResult<FetchStatus>> getFetchStatus(String sessionId) async {
    final result = await _api.get<Map<String, dynamic>>(
      '$_basePath/fetch/$sessionId/status',
    );

    if (result.isError || result.data?['success'] != true) {
      return AggregatorResult.failure(
        result.data?['error']?['message'] ?? 'Failed to get fetch status',
      );
    }

    final data = result.data!['data'] as Map<String, dynamic>;
    return AggregatorResult.success(FetchStatus.fromJson(data));
  }

  /// Get linked accounts
  Future<AggregatorResult<List<LinkedAccount>>> getAccounts({
    String? accountType,
    bool includeInactive = false,
  }) async {
    final queryParams = <String, dynamic>{};
    if (accountType != null) queryParams['account_type'] = accountType;
    if (includeInactive) queryParams['include_inactive'] = 'true';

    final result = await _api.get<Map<String, dynamic>>(
      '$_basePath/accounts',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (result.isError || result.data?['success'] != true) {
      return AggregatorResult.failure(
        result.data?['error']?['message'] ?? 'Failed to get accounts',
      );
    }

    final data = result.data!['data'] as List?;
    final accounts = data?.map((a) => LinkedAccount.fromJson(a)).toList() ?? [];
    return AggregatorResult.success(accounts);
  }

  /// Get financial summary
  Future<AggregatorResult<FinancialSummary>> getFinancialSummary() async {
    final result = await _api.get<Map<String, dynamic>>('$_basePath/summary');

    if (result.isError || result.data?['success'] != true) {
      return AggregatorResult.failure(
        result.data?['error']?['message'] ?? 'Failed to get summary',
      );
    }

    final data = result.data!['data'] as Map<String, dynamic>;
    return AggregatorResult.success(FinancialSummary.fromJson(data));
  }

  /// Get transaction insights
  Future<AggregatorResult<TransactionInsights>> getTransactionInsights({
    String? accountId,
    int months = 3,
  }) async {
    final queryParams = <String, dynamic>{'months': months.toString()};
    if (accountId != null) queryParams['account_id'] = accountId;

    final result = await _api.get<Map<String, dynamic>>(
      '$_basePath/transactions',
      queryParameters: queryParams,
    );

    if (result.isError || result.data?['success'] != true) {
      return AggregatorResult.failure(
        result.data?['error']?['message'] ?? 'Failed to get transactions',
      );
    }

    final data = result.data!['data'] as Map<String, dynamic>;
    return AggregatorResult.success(TransactionInsights.fromJson(data));
  }

  /// Sync/refresh data
  Future<AggregatorResult<FetchStatus>> syncData({String? consentId}) async {
    final result = await _api.post<Map<String, dynamic>>(
      '$_basePath/sync',
      data: consentId != null ? {'consent_id': consentId} : null,
    );

    if (result.isError || result.data?['success'] != true) {
      return AggregatorResult.failure(
        result.data?['error']?['message'] ?? 'Failed to sync data',
      );
    }

    final data = result.data!['data'] as Map<String, dynamic>;
    return AggregatorResult.success(FetchStatus.fromJson(data));
  }
}

// ============================================================================
// Models
// ============================================================================

/// Generic result wrapper
class AggregatorResult<T> {
  final bool success;
  final T? data;
  final String? error;

  AggregatorResult._({required this.success, this.data, this.error});

  factory AggregatorResult.success(T data) => AggregatorResult._(success: true, data: data);
  factory AggregatorResult.failure(String error) => AggregatorResult._(success: false, error: error);
}

/// Consent information
class ConsentInfo {
  final String consentId;
  final String status;
  final String purpose;
  final String fetchType;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final List<String> fipIds;

  ConsentInfo({
    required this.consentId,
    required this.status,
    required this.purpose,
    required this.fetchType,
    this.createdAt,
    this.expiresAt,
    this.fipIds = const [],
  });

  factory ConsentInfo.fromJson(Map<String, dynamic> json) {
    return ConsentInfo(
      consentId: json['consent_id'] as String? ?? json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      purpose: json['purpose'] as String? ?? '',
      fetchType: json['fetch_type'] as String? ?? 'ONETIME',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      expiresAt: json['expires_at'] != null 
          ? DateTime.tryParse(json['expires_at']) 
          : null,
      fipIds: (json['fip_ids'] as List?)?.cast<String>() ?? [],
    );
  }
}

/// FIP (Financial Information Provider) info
class FIPInfo {
  final String id;
  final String name;
  final String fiType;
  final String? logoUrl;
  final bool isActive;

  FIPInfo({
    required this.id,
    required this.name,
    required this.fiType,
    this.logoUrl,
    this.isActive = true,
  });

  factory FIPInfo.fromJson(Map<String, dynamic> json) {
    return FIPInfo(
      id: json['id'] as String? ?? json['fip_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      fiType: json['fi_type'] as String? ?? json['type'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

/// Linked account info
class LinkedAccount {
  final String accountId;
  final String fipId;
  final String accountType;
  final String? maskedNumber;
  final String? bankName;
  final bool isActive;
  final DateTime? lastSyncedAt;

  LinkedAccount({
    required this.accountId,
    required this.fipId,
    required this.accountType,
    this.maskedNumber,
    this.bankName,
    this.isActive = true,
    this.lastSyncedAt,
  });

  factory LinkedAccount.fromJson(Map<String, dynamic> json) {
    return LinkedAccount(
      accountId: json['account_id'] as String? ?? json['id'] as String? ?? '',
      fipId: json['fip_id'] as String? ?? '',
      accountType: json['account_type'] as String? ?? json['type'] as String? ?? '',
      maskedNumber: json['masked_number'] as String? ?? json['masked_account_number'] as String?,
      bankName: json['bank_name'] as String? ?? json['fip_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      lastSyncedAt: json['last_synced_at'] != null 
          ? DateTime.tryParse(json['last_synced_at']) 
          : null,
    );
  }
}

/// Financial summary
class FinancialSummary {
  final double totalBalance;
  final double totalAssets;
  final double totalLiabilities;
  final double netWorth;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double savingsRate;
  final Map<String, double> balanceByType;

  FinancialSummary({
    this.totalBalance = 0,
    this.totalAssets = 0,
    this.totalLiabilities = 0,
    this.netWorth = 0,
    this.monthlyIncome = 0,
    this.monthlyExpenses = 0,
    this.savingsRate = 0,
    this.balanceByType = const {},
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      totalBalance: (json['total_balance'] as num?)?.toDouble() ?? 0,
      totalAssets: (json['total_assets'] as num?)?.toDouble() ?? 0,
      totalLiabilities: (json['total_liabilities'] as num?)?.toDouble() ?? 0,
      netWorth: (json['net_worth'] as num?)?.toDouble() ?? 0,
      monthlyIncome: (json['monthly_income'] as num?)?.toDouble() ?? 0,
      monthlyExpenses: (json['monthly_expenses'] as num?)?.toDouble() ?? 0,
      savingsRate: (json['savings_rate'] as num?)?.toDouble() ?? 0,
      balanceByType: (json['balance_by_type'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {},
    );
  }
}

/// Transaction insights
class TransactionInsights {
  final int totalTransactions;
  final double totalIncome;
  final double totalExpenses;
  final Map<String, double> expensesByCategory;
  final Map<String, double> incomeBySource;
  final List<TransactionSummary> recentTransactions;

  TransactionInsights({
    this.totalTransactions = 0,
    this.totalIncome = 0,
    this.totalExpenses = 0,
    this.expensesByCategory = const {},
    this.incomeBySource = const {},
    this.recentTransactions = const [],
  });

  factory TransactionInsights.fromJson(Map<String, dynamic> json) {
    return TransactionInsights(
      totalTransactions: json['total_transactions'] as int? ?? 0,
      totalIncome: (json['total_income'] as num?)?.toDouble() ?? 0,
      totalExpenses: (json['total_expenses'] as num?)?.toDouble() ?? 0,
      expensesByCategory: (json['expenses_by_category'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {},
      incomeBySource: (json['income_by_source'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {},
      recentTransactions: (json['recent_transactions'] as List?)
          ?.map((t) => TransactionSummary.fromJson(t))
          .toList() ?? [],
    );
  }
}

/// Transaction summary
class TransactionSummary {
  final String id;
  final double amount;
  final String type;
  final String? category;
  final String? description;
  final DateTime? transactionDate;

  TransactionSummary({
    required this.id,
    required this.amount,
    required this.type,
    this.category,
    this.description,
    this.transactionDate,
  });

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      id: json['id'] as String? ?? json['transaction_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      type: json['type'] as String? ?? json['transaction_type'] as String? ?? '',
      category: json['category'] as String?,
      description: json['description'] as String? ?? json['narration'] as String?,
      transactionDate: json['transaction_date'] != null 
          ? DateTime.tryParse(json['transaction_date']) 
          : null,
    );
  }
}

/// Fetch status
class FetchStatus {
  final String sessionId;
  final String status;
  final int? progress;
  final String? message;
  final DateTime? startedAt;
  final DateTime? completedAt;

  FetchStatus({
    required this.sessionId,
    required this.status,
    this.progress,
    this.message,
    this.startedAt,
    this.completedAt,
  });

  factory FetchStatus.fromJson(Map<String, dynamic> json) {
    return FetchStatus(
      sessionId: json['session_id'] as String? ?? json['fetch_session_id'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      progress: json['progress'] as int?,
      message: json['message'] as String?,
      startedAt: json['started_at'] != null 
          ? DateTime.tryParse(json['started_at']) 
          : null,
      completedAt: json['completed_at'] != null 
          ? DateTime.tryParse(json['completed_at']) 
          : null,
    );
  }

  bool get isCompleted => status == 'completed' || status == 'success';
  bool get isFailed => status == 'failed' || status == 'error';
  bool get isInProgress => status == 'pending' || status == 'in_progress';
}
