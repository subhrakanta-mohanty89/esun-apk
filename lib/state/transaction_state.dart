/// ESUN Transaction State
/// 
/// Unified state management for all transactions, payments, and balance updates.
/// This creates a cohesive financial flow for the MVP demo.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_service.dart';
import 'aa_data_state.dart';

// ============================================================================
// Transaction Models
// ============================================================================

enum TransactionType {
  billPayment,
  upiTransfer,
  bankTransfer,
  recharge,
  income,
  refund,
}

enum TransactionStatus {
  pending,
  success,
  failed,
}

class Transaction {
  final String id;
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final String title;
  final String? subtitle;
  final String? recipientName;
  final String? recipientUpi;
  final String? recipientAccount;
  final String? sourceAccount;
  final String? category;
  final String? billType;
  final String? transactionRef;
  final DateTime timestamp;
  final String? logoUrl;
  final bool isDebit;

  Transaction({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.title,
    this.subtitle,
    this.recipientName,
    this.recipientUpi,
    this.recipientAccount,
    this.sourceAccount,
    this.category,
    this.billType,
    this.transactionRef,
    required this.timestamp,
    this.logoUrl,
    this.isDebit = true,
  });

  Transaction copyWith({
    String? id,
    TransactionType? type,
    TransactionStatus? status,
    double? amount,
    String? title,
    String? subtitle,
    String? recipientName,
    String? recipientUpi,
    String? recipientAccount,
    String? sourceAccount,
    String? category,
    String? billType,
    String? transactionRef,
    DateTime? timestamp,
    String? logoUrl,
    bool? isDebit,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      recipientName: recipientName ?? this.recipientName,
      recipientUpi: recipientUpi ?? this.recipientUpi,
      recipientAccount: recipientAccount ?? this.recipientAccount,
      sourceAccount: sourceAccount ?? this.sourceAccount,
      category: category ?? this.category,
      billType: billType ?? this.billType,
      transactionRef: transactionRef ?? this.transactionRef,
      timestamp: timestamp ?? this.timestamp,
      logoUrl: logoUrl ?? this.logoUrl,
      isDebit: isDebit ?? this.isDebit,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'status': status.name,
    'amount': amount,
    'title': title,
    'subtitle': subtitle,
    'recipient_name': recipientName,
    'recipient_upi': recipientUpi,
    'recipient_account': recipientAccount,
    'source_account': sourceAccount,
    'category': category,
    'bill_type': billType,
    'transaction_ref': transactionRef,
    'timestamp': timestamp.toIso8601String(),
    'logo_url': logoUrl,
    'is_debit': isDebit,
  };
}

// ============================================================================
// Transaction State
// ============================================================================

class TransactionState {
  final List<Transaction> transactions;
  final double totalSpentToday;
  final double totalSpentThisMonth;
  final bool isLoading;
  final String? error;

  const TransactionState({
    this.transactions = const [],
    this.totalSpentToday = 0,
    this.totalSpentThisMonth = 0,
    this.isLoading = false,
    this.error,
  });

  TransactionState copyWith({
    List<Transaction>? transactions,
    double? totalSpentToday,
    double? totalSpentThisMonth,
    bool? isLoading,
    String? error,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      totalSpentToday: totalSpentToday ?? this.totalSpentToday,
      totalSpentThisMonth: totalSpentThisMonth ?? this.totalSpentThisMonth,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Get recent transactions (last 10)
  List<Transaction> get recentTransactions => 
      transactions.take(10).toList();

  // Get transactions for a specific date range
  List<Transaction> getTransactionsInRange(DateTime start, DateTime end) {
    return transactions.where((t) => 
      t.timestamp.isAfter(start) && t.timestamp.isBefore(end)
    ).toList();
  }

  // Get today's transactions
  List<Transaction> get todayTransactions {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return transactions.where((t) => t.timestamp.isAfter(startOfDay)).toList();
  }

  // Get transactions by type
  List<Transaction> getByType(TransactionType type) {
    return transactions.where((t) => t.type == type).toList();
  }

  // Get spending by category
  Map<String, double> get spendingByCategory {
    final result = <String, double>{};
    for (final t in transactions.where((t) => t.isDebit && t.status == TransactionStatus.success)) {
      final cat = t.category ?? 'Others';
      result[cat] = (result[cat] ?? 0) + t.amount;
    }
    return result;
  }
}

// ============================================================================
// Transaction State Notifier
// ============================================================================

class TransactionStateNotifier extends StateNotifier<TransactionState> {
  final Ref _ref;

  TransactionStateNotifier(this._ref) : super(const TransactionState()) {
    // Initialize with sample transactions for demo
    _initializeMockTransactions();
    // Then fetch real transactions from backend and merge
    _fetchBackendTransactions();
  }

  /// Fetch real transactions from backend and prepend to state
  Future<void> _fetchBackendTransactions() async {
    try {
      final api = _ref.read(apiServiceProvider);
      final result = await api.get('/api/v1/aa/transactions?limit=50');
      final body = result.data is Map ? result.data as Map<String, dynamic> : <String, dynamic>{};
      final data = body['data'] ?? body;
      final List txnList = data['transactions'] ?? [];
      
      if (txnList.isEmpty) return;
      
      final backendTxns = txnList.map<Transaction>((t) {
        final isDebit = (t['type'] ?? 'debit') == 'debit';
        final category = (t['category'] ?? 'transfer').toString().replaceAll('_', ' ');
        final mode = (t['mode'] ?? 'upi').toString();
        final timestamp = t['transaction_timestamp'] != null
            ? DateTime.tryParse(t['transaction_timestamp']) ?? DateTime.now()
            : DateTime.now();
        
        TransactionType txnType;
        if (isDebit) {
          txnType = mode == 'upi' ? TransactionType.upiTransfer : TransactionType.bankTransfer;
        } else {
          txnType = TransactionType.income;
        }
        
        return Transaction(
          id: t['id'] ?? t['transaction_id'] ?? '',
          type: txnType,
          status: TransactionStatus.success,
          amount: (t['amount'] ?? 0).toDouble(),
          title: t['description'] ?? t['counterparty_name'] ?? 'Transaction',
          subtitle: t['counterparty_name'] ?? category,
          recipientName: t['counterparty_name'],
          category: category.isEmpty ? 'Transfers' : '${category[0].toUpperCase()}${category.substring(1)}',
          sourceAccount: 'Bank Account',
          timestamp: timestamp,
          isDebit: isDebit,
        );
      }).toList();
      
      // Prepend backend transactions (most recent first), deduplicating by id
      final existingIds = state.transactions.map((t) => t.id).toSet();
      final newTxns = backendTxns.where((t) => !existingIds.contains(t.id)).toList();
      
      if (newTxns.isNotEmpty) {
        final merged = [...newTxns, ...state.transactions];
        merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final startOfMonth = DateTime(now.year, now.month, 1);
        double todaySpent = 0;
        double monthSpent = 0;
        for (final t in merged) {
          if (t.isDebit && t.status == TransactionStatus.success) {
            if (t.timestamp.isAfter(startOfDay)) todaySpent += t.amount;
            if (t.timestamp.isAfter(startOfMonth)) monthSpent += t.amount;
          }
        }
        
        state = state.copyWith(
          transactions: merged,
          totalSpentToday: todaySpent,
          totalSpentThisMonth: monthSpent,
        );
      }
    } catch (_) {
      // Backend fetch is best-effort; mock data remains as fallback
    }
  }

  /// Add a new transaction and update balances
  Future<Transaction> addTransaction({
    required TransactionType type,
    required double amount,
    required String title,
    String? subtitle,
    String? recipientName,
    String? recipientUpi,
    String? recipientAccount,
    String? sourceAccount,
    String? category,
    String? billType,
    String? logoUrl,
    bool isDebit = true,
  }) async {
    final transaction = Transaction(
      id: 'TXN${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      status: TransactionStatus.success,
      amount: amount,
      title: title,
      subtitle: subtitle,
      recipientName: recipientName,
      recipientUpi: recipientUpi,
      recipientAccount: recipientAccount,
      sourceAccount: sourceAccount ?? 'HDFC Savings •• 1234',
      category: category ?? _getCategoryForType(type, billType),
      billType: billType,
      transactionRef: 'REF${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      logoUrl: logoUrl,
      isDebit: isDebit,
    );

    // Add to transaction list
    final updatedTransactions = [transaction, ...state.transactions];
    
    // Recalculate totals
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    double todaySpent = 0;
    double monthSpent = 0;
    
    for (final t in updatedTransactions) {
      if (t.isDebit && t.status == TransactionStatus.success) {
        if (t.timestamp.isAfter(startOfDay)) {
          todaySpent += t.amount;
        }
        if (t.timestamp.isAfter(startOfMonth)) {
          monthSpent += t.amount;
        }
      }
    }

    state = state.copyWith(
      transactions: updatedTransactions,
      totalSpentToday: todaySpent,
      totalSpentThisMonth: monthSpent,
    );

    // Map transaction type to backend mode
    String txnMode;
    switch (type) {
      case TransactionType.upiTransfer:
        txnMode = 'upi';
        break;
      case TransactionType.bankTransfer:
        txnMode = 'neft';
        break;
      case TransactionType.billPayment:
      case TransactionType.recharge:
        txnMode = 'auto_debit';
        break;
      default:
        txnMode = 'upi';
    }

    // Map category to backend format
    String txnCategory = (category ?? 'transfer').toLowerCase().replaceAll(' ', '_');

    // Update bank balances in AA data
    if (isDebit) {
      _ref.read(aaDataProvider.notifier).deductFromBalance(
        amount: amount,
        accountIdentifier: sourceAccount ?? 'HDFC',
        description: title,
        recipientName: recipientName,
        category: txnCategory,
        mode: txnMode,
      );
    } else {
      _ref.read(aaDataProvider.notifier).addToBalance(
        amount: amount,
        accountIdentifier: sourceAccount ?? 'HDFC',
        description: title,
        recipientName: recipientName,
        category: txnCategory,
        mode: txnMode,
      );
    }

    return transaction;
  }

  String _getCategoryForType(TransactionType type, String? billType) {
    switch (type) {
      case TransactionType.billPayment:
        if (billType != null) {
          if (billType.contains('Electric')) return 'Utilities';
          if (billType.contains('Mobile') || billType.contains('Broadband') || billType.contains('DTH')) return 'Telecom';
          if (billType.contains('Water') || billType.contains('Gas')) return 'Utilities';
          if (billType.contains('Credit Card')) return 'Finance';
          if (billType.contains('Rent') || billType.contains('Housing')) return 'Housing';
        }
        return 'Bills';
      case TransactionType.upiTransfer:
      case TransactionType.bankTransfer:
        return 'Transfers';
      case TransactionType.recharge:
        return 'Telecom';
      case TransactionType.income:
        return 'Income';
      case TransactionType.refund:
        return 'Refunds';
    }
  }

  /// Record a bill payment
  Future<Transaction> recordBillPayment({
    required double amount,
    required String billType,
    required String consumerNumber,
    String? providerName,
    String? sourceAccount,
    String? logoUrl,
  }) async {
    return addTransaction(
      type: TransactionType.billPayment,
      amount: amount,
      title: billType,
      subtitle: providerName ?? 'Bill Payment',
      category: _getCategoryForType(TransactionType.billPayment, billType),
      billType: billType,
      sourceAccount: sourceAccount,
      logoUrl: logoUrl,
      isDebit: true,
    );
  }

  /// Record a UPI transfer
  Future<Transaction> recordUpiTransfer({
    required double amount,
    required String recipientName,
    String? recipientUpi,
    String? recipientPhone,
    String? sourceAccount,
    String? note,
  }) async {
    return addTransaction(
      type: TransactionType.upiTransfer,
      amount: amount,
      title: 'To $recipientName',
      subtitle: recipientUpi ?? recipientPhone ?? 'UPI Transfer',
      recipientName: recipientName,
      recipientUpi: recipientUpi,
      sourceAccount: sourceAccount,
      category: 'Transfers',
      isDebit: true,
    );
  }

  /// Record a mobile recharge
  Future<Transaction> recordRecharge({
    required double amount,
    required String mobileNumber,
    String? operator,
    String? sourceAccount,
  }) async {
    return addTransaction(
      type: TransactionType.recharge,
      amount: amount,
      title: 'Mobile Recharge',
      subtitle: '+91 $mobileNumber',
      category: 'Telecom',
      billType: 'Mobile Recharge',
      sourceAccount: sourceAccount,
      isDebit: true,
    );
  }

  /// Initialize with mock transactions for demo
  void _initializeMockTransactions() {
    final now = DateTime.now();
    final mockTransactions = [
      // Today's transactions
      Transaction(
        id: 'TXN001',
        type: TransactionType.upiTransfer,
        status: TransactionStatus.success,
        amount: 1500,
        title: 'To Ravi Kumar',
        subtitle: 'ravi.k@okhdfc',
        recipientName: 'Ravi Kumar',
        recipientUpi: 'ravi.k@okhdfc',
        sourceAccount: 'HDFC Savings •• 1234',
        category: 'Transfers',
        timestamp: now.subtract(const Duration(hours: 2)),
        isDebit: true,
      ),
      Transaction(
        id: 'TXN002',
        type: TransactionType.billPayment,
        status: TransactionStatus.success,
        amount: 2450,
        title: 'Electricity Bill',
        subtitle: 'TATA Power',
        category: 'Utilities',
        billType: 'Electricity Bill',
        sourceAccount: 'HDFC Savings •• 1234',
        timestamp: now.subtract(const Duration(hours: 5)),
        isDebit: true,
      ),
      // Yesterday's transactions
      Transaction(
        id: 'TXN003',
        type: TransactionType.recharge,
        status: TransactionStatus.success,
        amount: 599,
        title: 'Mobile Recharge',
        subtitle: '+91 99000 01111',
        category: 'Telecom',
        billType: 'Mobile Recharge',
        sourceAccount: 'HDFC Savings •• 1234',
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
        isDebit: true,
      ),
      Transaction(
        id: 'TXN004',
        type: TransactionType.upiTransfer,
        status: TransactionStatus.success,
        amount: 3500,
        title: 'To Swiggy',
        subtitle: 'swiggy@ybl',
        recipientName: 'Swiggy',
        recipientUpi: 'swiggy@ybl',
        category: 'Food & Dining',
        sourceAccount: 'ICICI Savings •• 5678',
        timestamp: now.subtract(const Duration(days: 1, hours: 8)),
        logoUrl: 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://swiggy.com&size=128',
        isDebit: true,
      ),
      // This week transactions
      Transaction(
        id: 'TXN005',
        type: TransactionType.billPayment,
        status: TransactionStatus.success,
        amount: 999,
        title: 'Broadband Bill',
        subtitle: 'Airtel Xstream',
        category: 'Telecom',
        billType: 'Broadband Bill',
        sourceAccount: 'HDFC Savings •• 1234',
        timestamp: now.subtract(const Duration(days: 2)),
        logoUrl: 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://airtel.in&size=128',
        isDebit: true,
      ),
      Transaction(
        id: 'TXN006',
        type: TransactionType.income,
        status: TransactionStatus.success,
        amount: 185000,
        title: 'Salary Credit',
        subtitle: 'TechNova Solutions',
        category: 'Income',
        sourceAccount: 'HDFC Savings •• 1234',
        timestamp: now.subtract(const Duration(days: 3)),
        isDebit: false,
      ),
      Transaction(
        id: 'TXN007',
        type: TransactionType.upiTransfer,
        status: TransactionStatus.success,
        amount: 25000,
        title: 'To Anita Sharma',
        subtitle: 'anita.s@upi',
        recipientName: 'Anita Sharma',
        recipientUpi: 'anita.s@upi',
        category: 'Transfers',
        sourceAccount: 'HDFC Savings •• 1234',
        timestamp: now.subtract(const Duration(days: 4)),
        isDebit: true,
      ),
      Transaction(
        id: 'TXN008',
        type: TransactionType.billPayment,
        status: TransactionStatus.success,
        amount: 15000,
        title: 'Credit Card Bill',
        subtitle: 'HDFC Credit Card',
        category: 'Finance',
        billType: 'Credit Card Bill',
        sourceAccount: 'SBI Savings •• 9012',
        timestamp: now.subtract(const Duration(days: 5)),
        logoUrl: 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://hdfcbank.com&size=128',
        isDebit: true,
      ),
      Transaction(
        id: 'TXN009',
        type: TransactionType.upiTransfer,
        status: TransactionStatus.success,
        amount: 8500,
        title: 'To Amazon',
        subtitle: 'amazon@apl',
        recipientName: 'Amazon',
        recipientUpi: 'amazon@apl',
        category: 'Shopping',
        sourceAccount: 'HDFC Savings •• 1234',
        timestamp: now.subtract(const Duration(days: 6)),
        logoUrl: 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://amazon.in&size=128',
        isDebit: true,
      ),
      Transaction(
        id: 'TXN010',
        type: TransactionType.refund,
        status: TransactionStatus.success,
        amount: 1299,
        title: 'Refund - Flipkart',
        subtitle: 'Order #FK234567',
        category: 'Refunds',
        sourceAccount: 'HDFC Savings •• 1234',
        timestamp: now.subtract(const Duration(days: 7)),
        logoUrl: 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://flipkart.com&size=128',
        isDebit: false,
      ),
    ];

    // Calculate initial totals
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    double todaySpent = 0;
    double monthSpent = 0;
    
    for (final t in mockTransactions) {
      if (t.isDebit && t.status == TransactionStatus.success) {
        if (t.timestamp.isAfter(startOfDay)) {
          todaySpent += t.amount;
        }
        if (t.timestamp.isAfter(startOfMonth)) {
          monthSpent += t.amount;
        }
      }
    }

    state = state.copyWith(
      transactions: mockTransactions,
      totalSpentToday: todaySpent,
      totalSpentThisMonth: monthSpent,
    );
  }

  /// Clear all transactions
  void clearTransactions() {
    state = const TransactionState();
  }
}

// ============================================================================
// Providers
// ============================================================================

final transactionStateProvider = StateNotifierProvider<TransactionStateNotifier, TransactionState>((ref) {
  return TransactionStateNotifier(ref);
});

/// Get recent transactions
final recentTransactionsProvider = Provider<List<Transaction>>((ref) {
  return ref.watch(transactionStateProvider).recentTransactions;
});

/// Get today's spending
final todaySpendingProvider = Provider<double>((ref) {
  return ref.watch(transactionStateProvider).totalSpentToday;
});

/// Get this month's spending
final monthSpendingProvider = Provider<double>((ref) {
  return ref.watch(transactionStateProvider).totalSpentThisMonth;
});

/// Get spending breakdown by category
final spendingByCategoryProvider = Provider<Map<String, double>>((ref) {
  return ref.watch(transactionStateProvider).spendingByCategory;
});
