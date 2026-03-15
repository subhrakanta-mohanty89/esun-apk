/// Persona Analysis Service
/// 
/// Service for calling the persona analysis API endpoints.
/// Supports structured vs unstructured financial profile analysis.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../core/network/api_service.dart';

/// Persona Service Provider
final personaServiceProvider = Provider<PersonaService>((ref) {
  return PersonaService(ref.watch(dioProvider));
});

/// Persona Type Enum
enum PersonaType {
  structured,
  unstructured,
  mixed,
  unknown;

  static PersonaType fromString(String value) {
    return PersonaType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => PersonaType.unknown,
    );
  }
}

/// Health Score Enum
enum HealthScore {
  excellent,
  good,
  fair,
  poor,
  critical;

  static HealthScore fromString(String value) {
    return HealthScore.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => HealthScore.fair,
    );
  }

  String get displayName {
    switch (this) {
      case HealthScore.excellent:
        return 'Excellent';
      case HealthScore.good:
        return 'Good';
      case HealthScore.fair:
        return 'Fair';
      case HealthScore.poor:
        return 'Poor';
      case HealthScore.critical:
        return 'Critical';
    }
  }
}

/// Persona Insights Model
class PersonaInsights {
  final String userId;
  final PersonaType personaType;
  final HealthScore healthScore;
  final double healthScoreNumeric;
  final FinancialSummary summary;
  final WealthSummary wealth;
  final FinancialRatios ratios;
  final CreditInfo credit;
  final List<LoanSummary> loans;
  final List<String> riskIndicators;
  final List<String> positiveIndicators;
  final ComparisonMetrics comparisonMetrics;
  final DateTime generatedAt;

  // Structured-specific
  final List<EMIScheduleEntry>? emiSchedule;
  final NetWorthBreakdown? netWorthBreakdown;
  final List<String>? optimizationSuggestions;

  // Unstructured-specific
  final double? liquidityStressScore;
  final InterestBurden? interestBurden;
  final List<ConsolidationOption>? consolidationOptions;

  PersonaInsights({
    required this.userId,
    required this.personaType,
    required this.healthScore,
    required this.healthScoreNumeric,
    required this.summary,
    required this.wealth,
    required this.ratios,
    required this.credit,
    required this.loans,
    required this.riskIndicators,
    required this.positiveIndicators,
    required this.comparisonMetrics,
    required this.generatedAt,
    this.emiSchedule,
    this.netWorthBreakdown,
    this.optimizationSuggestions,
    this.liquidityStressScore,
    this.interestBurden,
    this.consolidationOptions,
  });

  factory PersonaInsights.fromJson(Map<String, dynamic> json) {
    return PersonaInsights(
      userId: json['user_id'] ?? '',
      personaType: PersonaType.fromString(json['persona_type'] ?? 'unknown'),
      healthScore: HealthScore.fromString(json['health_score'] ?? 'fair'),
      healthScoreNumeric: (json['health_score_numeric'] ?? 50).toDouble(),
      summary: FinancialSummary.fromJson(json['summary'] ?? {}),
      wealth: WealthSummary.fromJson(json['wealth'] ?? {}),
      ratios: FinancialRatios.fromJson(json['ratios'] ?? {}),
      credit: CreditInfo.fromJson(json['credit'] ?? {}),
      loans: (json['loans'] as List<dynamic>? ?? [])
          .map((e) => LoanSummary.fromJson(e))
          .toList(),
      riskIndicators: List<String>.from(json['risk_indicators'] ?? []),
      positiveIndicators: List<String>.from(json['positive_indicators'] ?? []),
      comparisonMetrics: ComparisonMetrics.fromJson(json['comparison_metrics'] ?? {}),
      generatedAt: DateTime.tryParse(json['generated_at'] ?? '') ?? DateTime.now(),
      emiSchedule: (json['emi_schedule'] as List<dynamic>?)
          ?.map((e) => EMIScheduleEntry.fromJson(e))
          .toList(),
      netWorthBreakdown: json['net_worth_breakdown'] != null
          ? NetWorthBreakdown.fromJson(json['net_worth_breakdown'])
          : null,
      optimizationSuggestions: json['optimization_suggestions'] != null
          ? List<String>.from(json['optimization_suggestions'])
          : null,
      liquidityStressScore: json['liquidity_stress_score']?.toDouble(),
      interestBurden: json['interest_burden'] != null
          ? InterestBurden.fromJson(json['interest_burden'])
          : null,
      consolidationOptions: (json['consolidation_options'] as List<dynamic>?)
          ?.map((e) => ConsolidationOption.fromJson(e))
          .toList(),
    );
  }
}

/// Financial Summary
class FinancialSummary {
  final double totalMonthlyIncome;
  final double totalMonthlyExpense;
  final double totalMonthlyEmi;
  final double netMonthlySurplus;

  FinancialSummary({
    required this.totalMonthlyIncome,
    required this.totalMonthlyExpense,
    required this.totalMonthlyEmi,
    required this.netMonthlySurplus,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      totalMonthlyIncome: (json['total_monthly_income'] ?? 0).toDouble(),
      totalMonthlyExpense: (json['total_monthly_expense'] ?? 0).toDouble(),
      totalMonthlyEmi: (json['total_monthly_emi'] ?? 0).toDouble(),
      netMonthlySurplus: (json['net_monthly_surplus'] ?? 0).toDouble(),
    );
  }
}

/// Wealth Summary
class WealthSummary {
  final double totalAssets;
  final double liquidAssets;
  final double totalLiabilities;
  final double netWorth;

  WealthSummary({
    required this.totalAssets,
    required this.liquidAssets,
    required this.totalLiabilities,
    required this.netWorth,
  });

  factory WealthSummary.fromJson(Map<String, dynamic> json) {
    return WealthSummary(
      totalAssets: (json['total_assets'] ?? 0).toDouble(),
      liquidAssets: (json['liquid_assets'] ?? 0).toDouble(),
      totalLiabilities: (json['total_liabilities'] ?? 0).toDouble(),
      netWorth: (json['net_worth'] ?? 0).toDouble(),
    );
  }
}

/// Financial Ratios
class FinancialRatios {
  final double debtToIncome;
  final double emiToIncome;
  final double expenseToIncome;
  final double creditUtilization;
  final double savingsRate;

  FinancialRatios({
    required this.debtToIncome,
    required this.emiToIncome,
    required this.expenseToIncome,
    required this.creditUtilization,
    required this.savingsRate,
  });

  factory FinancialRatios.fromJson(Map<String, dynamic> json) {
    return FinancialRatios(
      debtToIncome: (json['debt_to_income'] ?? 0).toDouble(),
      emiToIncome: (json['emi_to_income'] ?? 0).toDouble(),
      expenseToIncome: (json['expense_to_income'] ?? 0).toDouble(),
      creditUtilization: (json['credit_utilization'] ?? 0).toDouble(),
      savingsRate: (json['savings_rate'] ?? 0).toDouble(),
    );
  }
}

/// Credit Info
class CreditInfo {
  final int? score;
  final double totalLimit;
  final double utilized;

  CreditInfo({
    this.score,
    required this.totalLimit,
    required this.utilized,
  });

  factory CreditInfo.fromJson(Map<String, dynamic> json) {
    return CreditInfo(
      score: json['score'],
      totalLimit: (json['total_limit'] ?? 0).toDouble(),
      utilized: (json['utilized'] ?? 0).toDouble(),
    );
  }
}

/// Loan Summary
class LoanSummary {
  final String loanType;
  final String lenderName;
  final double originalAmount;
  final double outstanding;
  final double interestRate;
  final double emiAmount;
  final int tenureMonths;
  final int remainingMonths;
  final bool isSecured;

  LoanSummary({
    required this.loanType,
    required this.lenderName,
    required this.originalAmount,
    required this.outstanding,
    required this.interestRate,
    required this.emiAmount,
    required this.tenureMonths,
    required this.remainingMonths,
    required this.isSecured,
  });

  factory LoanSummary.fromJson(Map<String, dynamic> json) {
    return LoanSummary(
      loanType: json['loan_type'] ?? 'other',
      lenderName: json['lender_name'] ?? 'Unknown',
      originalAmount: (json['original_amount'] ?? 0).toDouble(),
      outstanding: (json['outstanding'] ?? 0).toDouble(),
      interestRate: (json['interest_rate'] ?? 0).toDouble(),
      emiAmount: (json['emi_amount'] ?? 0).toDouble(),
      tenureMonths: json['tenure_months'] ?? 0,
      remainingMonths: json['remaining_months'] ?? 0,
      isSecured: json['is_secured'] ?? false,
    );
  }
}

/// EMI Schedule Entry
class EMIScheduleEntry {
  final int month;
  final int year;
  final DateTime paymentDate;
  final double principal;
  final double interest;
  final double totalEmi;
  final double outstandingAfter;
  final String loanName;
  final String loanType;

  EMIScheduleEntry({
    required this.month,
    required this.year,
    required this.paymentDate,
    required this.principal,
    required this.interest,
    required this.totalEmi,
    required this.outstandingAfter,
    required this.loanName,
    required this.loanType,
  });

  factory EMIScheduleEntry.fromJson(Map<String, dynamic> json) {
    return EMIScheduleEntry(
      month: json['month'] ?? 1,
      year: json['year'] ?? 2026,
      paymentDate: DateTime.tryParse(json['payment_date'] ?? '') ?? DateTime.now(),
      principal: (json['principal'] ?? 0).toDouble(),
      interest: (json['interest'] ?? 0).toDouble(),
      totalEmi: (json['total_emi'] ?? 0).toDouble(),
      outstandingAfter: (json['outstanding_after'] ?? 0).toDouble(),
      loanName: json['loan_name'] ?? '',
      loanType: json['loan_type'] ?? '',
    );
  }
}

/// Net Worth Breakdown
class NetWorthBreakdown {
  final Map<String, double> assetsBreakdown;
  final double assetsTotal;
  final double liquidPercentage;
  final Map<String, double> liabilitiesBreakdown;
  final double liabilitiesTotal;
  final double securedPercentage;
  final double netWorth;
  final double assetLiabilityRatio;

  NetWorthBreakdown({
    required this.assetsBreakdown,
    required this.assetsTotal,
    required this.liquidPercentage,
    required this.liabilitiesBreakdown,
    required this.liabilitiesTotal,
    required this.securedPercentage,
    required this.netWorth,
    required this.assetLiabilityRatio,
  });

  factory NetWorthBreakdown.fromJson(Map<String, dynamic> json) {
    final assets = json['assets'] as Map<String, dynamic>? ?? {};
    final liabilities = json['liabilities'] as Map<String, dynamic>? ?? {};

    return NetWorthBreakdown(
      assetsBreakdown: Map<String, double>.from(
        (assets['breakdown'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, (value ?? 0).toDouble()),
        ),
      ),
      assetsTotal: (assets['total'] ?? 0).toDouble(),
      liquidPercentage: (assets['liquid_percentage'] ?? 0).toDouble(),
      liabilitiesBreakdown: Map<String, double>.from(
        (liabilities['breakdown'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, (value ?? 0).toDouble()),
        ),
      ),
      liabilitiesTotal: (liabilities['total'] ?? 0).toDouble(),
      securedPercentage: (liabilities['secured_percentage'] ?? 0).toDouble(),
      netWorth: (json['net_worth'] ?? 0).toDouble(),
      assetLiabilityRatio: (json['asset_liability_ratio'] ?? 1).toDouble(),
    );
  }
}

/// Interest Burden
class InterestBurden {
  final double monthly;
  final double annual;

  InterestBurden({
    required this.monthly,
    required this.annual,
  });

  factory InterestBurden.fromJson(Map<String, dynamic> json) {
    return InterestBurden(
      monthly: (json['monthly'] ?? 0).toDouble(),
      annual: (json['annual'] ?? 0).toDouble(),
    );
  }
}

/// Consolidation Option
class ConsolidationOption {
  final double consolidationAmount;
  final double currentTotalEmi;
  final double proposedEmi;
  final double monthlySavings;
  final double currentAvgRate;
  final double proposedRate;
  final double totalInterestSavings;
  final String recommendation;

  ConsolidationOption({
    required this.consolidationAmount,
    required this.currentTotalEmi,
    required this.proposedEmi,
    required this.monthlySavings,
    required this.currentAvgRate,
    required this.proposedRate,
    required this.totalInterestSavings,
    required this.recommendation,
  });

  factory ConsolidationOption.fromJson(Map<String, dynamic> json) {
    return ConsolidationOption(
      consolidationAmount: (json['consolidation_amount'] ?? 0).toDouble(),
      currentTotalEmi: (json['current_total_emi'] ?? 0).toDouble(),
      proposedEmi: (json['proposed_emi'] ?? 0).toDouble(),
      monthlySavings: (json['monthly_savings'] ?? 0).toDouble(),
      currentAvgRate: (json['current_avg_rate'] ?? 0).toDouble(),
      proposedRate: (json['proposed_rate'] ?? 0).toDouble(),
      totalInterestSavings: (json['total_interest_savings'] ?? 0).toDouble(),
      recommendation: json['recommendation'] ?? '',
    );
  }
}

/// Comparison Metrics
class ComparisonMetrics {
  final MetricValues current;
  final MetricValues structuredBenchmark;
  final MetricValues unstructuredTypical;
  final MetricValues deviationFromBenchmark;
  final String personaType;

  ComparisonMetrics({
    required this.current,
    required this.structuredBenchmark,
    required this.unstructuredTypical,
    required this.deviationFromBenchmark,
    required this.personaType,
  });

  factory ComparisonMetrics.fromJson(Map<String, dynamic> json) {
    return ComparisonMetrics(
      current: MetricValues.fromJson(json['current'] ?? {}),
      structuredBenchmark: MetricValues.fromJson(json['structured_benchmark'] ?? {}),
      unstructuredTypical: MetricValues.fromJson(json['unstructured_typical'] ?? {}),
      deviationFromBenchmark: MetricValues.fromJson(json['deviation_from_benchmark'] ?? {}),
      personaType: json['persona_type'] ?? 'unknown',
    );
  }
}

/// Metric Values
class MetricValues {
  final double dti;
  final double emiRatio;
  final double creditUtilization;
  final double savingsRate;
  final double healthScore;

  MetricValues({
    required this.dti,
    required this.emiRatio,
    required this.creditUtilization,
    required this.savingsRate,
    required this.healthScore,
  });

  factory MetricValues.fromJson(Map<String, dynamic> json) {
    return MetricValues(
      dti: (json['dti'] ?? 0).toDouble(),
      emiRatio: (json['emi_ratio'] ?? 0).toDouble(),
      creditUtilization: (json['credit_utilization'] ?? 0).toDouble(),
      savingsRate: (json['savings_rate'] ?? 0).toDouble(),
      healthScore: (json['health_score'] ?? 0).toDouble(),
    );
  }
}

/// Persona Service
class PersonaService {
  final Dio _dio;

  PersonaService(this._dio);

  /// Classify user persona
  Future<Map<String, dynamic>> classifyPersona() async {
    final response = await _dio.get('/api/v1/persona/classify');
    return response.data;
  }

  /// Get comprehensive persona insights
  Future<PersonaInsights> getInsights() async {
    final response = await _dio.get('/api/v1/persona/insights');
    return PersonaInsights.fromJson(response.data);
  }

  /// Get EMI schedule
  Future<Map<String, dynamic>> getEmiSchedule({int months = 12}) async {
    final response = await _dio.get(
      '/api/v1/persona/emi-schedule',
      queryParameters: {'months': months},
    );
    return response.data;
  }

  /// Get net worth breakdown
  Future<NetWorthBreakdown> getNetWorthBreakdown() async {
    final response = await _dio.get('/api/v1/persona/net-worth');
    return NetWorthBreakdown.fromJson(response.data);
  }

  /// Get optimization suggestions
  Future<Map<String, dynamic>> getOptimizationSuggestions() async {
    final response = await _dio.get('/api/v1/persona/optimization');
    return response.data;
  }

  /// Get liquidity stress analysis
  Future<Map<String, dynamic>> getLiquidityStress() async {
    final response = await _dio.get('/api/v1/persona/liquidity-stress');
    return response.data;
  }

  /// Get consolidation options
  Future<Map<String, dynamic>> getConsolidationOptions() async {
    final response = await _dio.get('/api/v1/persona/consolidation');
    return response.data;
  }

  /// Get comparison metrics
  Future<Map<String, dynamic>> getComparisonMetrics() async {
    final response = await _dio.get('/api/v1/persona/comparison');
    return response.data;
  }
}

/// Persona Insights State Notifier
class PersonaInsightsNotifier extends StateNotifier<AsyncValue<PersonaInsights?>> {
  final PersonaService _service;

  PersonaInsightsNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> loadInsights() async {
    state = const AsyncValue.loading();
    try {
      final insights = await _service.getInsights();
      state = AsyncValue.data(insights);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Persona Insights Provider
final personaInsightsProvider =
    StateNotifierProvider<PersonaInsightsNotifier, AsyncValue<PersonaInsights?>>((ref) {
  return PersonaInsightsNotifier(ref.watch(personaServiceProvider));
});
