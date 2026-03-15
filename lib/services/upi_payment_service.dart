/// ESUN UPI Payment Service
/// 
/// Handles UPI payment operations including demo/mock payments.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_service.dart';
import '../core/utils/utils.dart';

/// UPI Payment Service Provider
final upiPaymentServiceProvider = Provider<UPIPaymentService>((ref) {
  final api = ref.watch(apiServiceProvider);
  return UPIPaymentService(api);
});

/// UPI Payment State
class UPIPaymentState {
  final bool isLoading;
  final String? error;
  final DemoBalance? balance;
  final PaymentLinkResult? paymentLink;
  final PaymentSimulationResult? lastPayment;

  const UPIPaymentState({
    this.isLoading = false,
    this.error,
    this.balance,
    this.paymentLink,
    this.lastPayment,
  });

  UPIPaymentState copyWith({
    bool? isLoading,
    String? error,
    DemoBalance? balance,
    PaymentLinkResult? paymentLink,
    PaymentSimulationResult? lastPayment,
  }) {
    return UPIPaymentState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      balance: balance ?? this.balance,
      paymentLink: paymentLink ?? this.paymentLink,
      lastPayment: lastPayment ?? this.lastPayment,
    );
  }
}

/// Demo balance model
class DemoBalance {
  final double totalBalance;
  final double availableBalance;
  final List<DemoAccount> accounts;
  final double monthlyIncome;
  final double monthlySpending;
  final Map<String, double> spendingByCategory;

  DemoBalance({
    required this.totalBalance,
    required this.availableBalance,
    required this.accounts,
    required this.monthlyIncome,
    required this.monthlySpending,
    required this.spendingByCategory,
  });

  factory DemoBalance.fromJson(Map<String, dynamic> json) {
    return DemoBalance(
      totalBalance: (json['total_balance'] as num?)?.toDouble() ?? 0.0,
      availableBalance: (json['available_balance'] as num?)?.toDouble() ?? 0.0,
      accounts: (json['accounts'] as List?)
          ?.map((a) => DemoAccount.fromJson(a))
          .toList() ?? [],
      monthlyIncome: (json['monthly_income'] as num?)?.toDouble() ?? 0.0,
      monthlySpending: (json['monthly_spending'] as num?)?.toDouble() ?? 0.0,
      spendingByCategory: (json['spending_by_category'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {},
    );
  }
}

/// Demo account model
class DemoAccount {
  final String id;
  final String bankName;
  final String accountType;
  final double balance;
  final String? upiId;

  DemoAccount({
    required this.id,
    required this.bankName,
    required this.accountType,
    required this.balance,
    this.upiId,
  });

  factory DemoAccount.fromJson(Map<String, dynamic> json) {
    return DemoAccount(
      id: json['id'] as String,
      bankName: json['bank_name'] as String,
      accountType: json['account_type'] as String,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      upiId: json['upi_id'] as String?,
    );
  }
}

/// Payment link result
class PaymentLinkResult {
  final String providerRef;
  final String? upiLink;
  final String? shortUrl;
  final String? qrCode;
  final String referenceId;
  final bool isMock;

  PaymentLinkResult({
    required this.providerRef,
    this.upiLink,
    this.shortUrl,
    this.qrCode,
    required this.referenceId,
    this.isMock = true,
  });

  factory PaymentLinkResult.fromJson(Map<String, dynamic> json) {
    return PaymentLinkResult(
      providerRef: json['provider_ref'] as String,
      upiLink: json['upi_link'] as String?,
      shortUrl: json['short_url'] as String?,
      qrCode: json['qr_code'] as String?,
      referenceId: json['reference_id'] as String,
      isMock: json['is_mock'] as bool? ?? true,
    );
  }
}

/// Payment simulation result
class PaymentSimulationResult {
  final String status;
  final String transactionId;
  final double amount;
  final double oldBalance;
  final double newBalance;
  final String payeeVpa;
  final String? paidAt;

  PaymentSimulationResult({
    required this.status,
    required this.transactionId,
    required this.amount,
    required this.oldBalance,
    required this.newBalance,
    required this.payeeVpa,
    this.paidAt,
  });

  factory PaymentSimulationResult.fromJson(Map<String, dynamic> json) {
    final setuTxn = json['setu_transaction'] as Map<String, dynamic>? ?? {};
    final balanceUpdate = json['balance_update'] as Map<String, dynamic>? ?? {};
    
    return PaymentSimulationResult(
      status: setuTxn['status'] as String? ?? 'SUCCESS',
      transactionId: balanceUpdate['transaction_id'] as String? ?? setuTxn['transaction_id'] as String? ?? '',
      amount: (balanceUpdate['amount'] as num?)?.toDouble() ?? 0.0,
      oldBalance: (balanceUpdate['old_balance'] as num?)?.toDouble() ?? 0.0,
      newBalance: (balanceUpdate['new_balance'] as num?)?.toDouble() ?? 0.0,
      payeeVpa: balanceUpdate['payee_vpa'] as String? ?? '',
      paidAt: setuTxn['paid_at'] as String?,
    );
  }
}

/// VPA verification result
class VPAVerificationResult {
  final bool isValid;
  final String vpa;
  final String? accountHolder;
  final String? error;

  VPAVerificationResult({
    required this.isValid,
    required this.vpa,
    this.accountHolder,
    this.error,
  });

  factory VPAVerificationResult.fromJson(Map<String, dynamic> json) {
    return VPAVerificationResult(
      isValid: json['valid'] as bool? ?? false,
      vpa: json['vpa'] as String,
      accountHolder: json['account_holder'] as String?,
      error: json['error'] as String?,
    );
  }
}

/// UPI Payment Service
class UPIPaymentService {
  final ApiService _api;
  
  UPIPaymentService(this._api);
  
  static const String _basePath = '/api/v1/payments';
  
  /// Seed demo data for user
  Future<Result<Map<String, dynamic>>> seedDemoData({int monthsHistory = 3}) async {
    final result = await _api.post<Map<String, dynamic>>(
      '$_basePath/demo/seed',
      data: {'months_history': monthsHistory},
    );
    return result;
  }
  
  /// Get demo balance breakdown
  Future<Result<DemoBalance>> getDemoBalance() async {
    final result = await _api.get<Map<String, dynamic>>('$_basePath/demo/balance');
    
    return result.when(
      success: (data) {
        try {
          if (data['success'] == true && data['data'] != null) {
            return Success(DemoBalance.fromJson(data['data'] as Map<String, dynamic>));
          }
          return Error(AppException(
            message: data['error']?['message'] as String? ?? 'Failed to get balance',
          ));
        } catch (e) {
          return Error(AppException(message: e.toString()));
        }
      },
      error: (e) => Error(e),
    );
  }
  
  /// Verify a UPI VPA
  Future<Result<VPAVerificationResult>> verifyVPA(String vpa) async {
    final result = await _api.post<Map<String, dynamic>>(
      '$_basePath/verify-vpa',
      data: {'vpa': vpa},
    );
    
    return result.when(
      success: (data) {
        try {
          if (data['success'] == true && data['data'] != null) {
            return Success(VPAVerificationResult.fromJson(data['data'] as Map<String, dynamic>));
          }
          return Error(AppException(
            message: data['error']?['message'] as String? ?? 'Failed to verify VPA',
          ));
        } catch (e) {
          return Error(AppException(message: e.toString()));
        }
      },
      error: (e) => Error(e),
    );
  }
  
  /// Create a demo UPI payment link
  Future<Result<PaymentLinkResult>> createPaymentLink({
    required double amount,
    required String payeeVpa,
    required String accountId,
    String description = 'Demo Payment',
    int expiryMinutes = 5,
  }) async {
    final result = await _api.post<Map<String, dynamic>>(
      '$_basePath/demo/upi/create',
      data: {
        'amount': amount,
        'payee_vpa': payeeVpa,
        'account_id': accountId,
        'description': description,
        'expiry_minutes': expiryMinutes,
      },
    );
    
    return result.when(
      success: (data) {
        try {
          if (data['success'] == true && data['data'] != null) {
            return Success(PaymentLinkResult.fromJson(data['data'] as Map<String, dynamic>));
          }
          return Error(AppException(
            message: data['error']?['message'] as String? ?? 'Failed to create payment link',
          ));
        } catch (e) {
          return Error(AppException(message: e.toString()));
        }
      },
      error: (e) => Error(e),
    );
  }
  
  /// Simulate a demo UPI payment
  Future<Result<PaymentSimulationResult>> simulatePayment({
    required String platformBillId,
    required String accountId,
    String payerVpa = 'demo@upi',
  }) async {
    final result = await _api.post<Map<String, dynamic>>(
      '$_basePath/demo/upi/simulate',
      data: {
        'platform_bill_id': platformBillId,
        'account_id': accountId,
        'payer_vpa': payerVpa,
      },
    );
    
    return result.when(
      success: (data) {
        try {
          if (data['success'] == true && data['data'] != null) {
            return Success(PaymentSimulationResult.fromJson(data['data'] as Map<String, dynamic>));
          }
          return Error(AppException(
            message: data['error']?['message'] as String? ?? 'Payment simulation failed',
          ));
        } catch (e) {
          return Error(AppException(message: e.toString()));
        }
      },
      error: (e) => Error(e),
    );
  }
  
  /// Get payment status
  Future<Result<Map<String, dynamic>>> getPaymentStatus(String platformBillId) async {
    final result = await _api.get<Map<String, dynamic>>(
      '$_basePath/demo/upi/status/$platformBillId',
    );
    return result;
  }
  
  /// Cleanup demo data
  Future<Result<Map<String, dynamic>>> cleanupDemoData() async {
    final result = await _api.delete<Map<String, dynamic>>('$_basePath/demo/cleanup');
    return result;
  }
}

/// UPI Payment State Notifier
class UPIPaymentNotifier extends StateNotifier<UPIPaymentState> {
  final UPIPaymentService _service;
  
  UPIPaymentNotifier(this._service) : super(const UPIPaymentState());
  
  /// Load demo balance
  Future<void> loadBalance() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _service.getDemoBalance();
    
    result.when(
      success: (balance) {
        state = state.copyWith(isLoading: false, balance: balance);
      },
      error: (e) {
        state = state.copyWith(isLoading: false, error: e.message);
      },
    );
  }
  
  /// Create payment link
  Future<bool> createPayment({
    required double amount,
    required String payeeVpa,
    required String accountId,
    String description = 'Demo Payment',
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _service.createPaymentLink(
      amount: amount,
      payeeVpa: payeeVpa,
      accountId: accountId,
      description: description,
    );
    
    return result.when(
      success: (link) {
        state = state.copyWith(isLoading: false, paymentLink: link);
        return true;
      },
      error: (e) {
        state = state.copyWith(isLoading: false, error: e.message);
        return false;
      },
    );
  }
  
  /// Simulate payment (instant demo success)
  Future<bool> simulatePayment(String accountId) async {
    final link = state.paymentLink;
    if (link == null) {
      state = state.copyWith(error: 'No payment link created');
      return false;
    }
    
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _service.simulatePayment(
      platformBillId: link.providerRef,
      accountId: accountId,
    );
    
    return result.when(
      success: (payment) {
        state = state.copyWith(
          isLoading: false, 
          lastPayment: payment,
          paymentLink: null, // Clear the link after success
        );
        // Refresh balance
        loadBalance();
        return true;
      },
      error: (e) {
        state = state.copyWith(isLoading: false, error: e.message);
        return false;
      },
    );
  }
  
  /// Seed demo data
  Future<bool> seedDemoData() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _service.seedDemoData(monthsHistory: 3);
    
    return result.when(
      success: (_) {
        loadBalance();
        return true;
      },
      error: (e) {
        state = state.copyWith(isLoading: false, error: e.message);
        return false;
      },
    );
  }
  
  void clearError() {
    state = state.copyWith(error: null);
  }
  
  void clearPaymentLink() {
    state = state.copyWith(paymentLink: null);
  }
}

/// UPI Payment State Provider
final upiPaymentStateProvider = StateNotifierProvider<UPIPaymentNotifier, UPIPaymentState>((ref) {
  final service = ref.watch(upiPaymentServiceProvider);
  return UPIPaymentNotifier(service);
});
