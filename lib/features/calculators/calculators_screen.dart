/// Financial Calculators
///
/// Interactive calculators for financial planning:
/// - EMI Calculator
/// - Retirement Calculator
/// - Emergency Fund Calculator
/// - SIP Calculator (bonus)
library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../theme/theme.dart';
import '../../shared/widgets/cards.dart';
import '../../core/utils/utils.dart';

// ============================================================================
// Calculator Models
// ============================================================================

/// EMI calculation result
class EMIResult {
  final double monthlyEMI;
  final double totalPayment;
  final double totalInterest;
  final double principalAmount;
  final List<EMIBreakdown> yearlyBreakdown;

  const EMIResult({
    required this.monthlyEMI,
    required this.totalPayment,
    required this.totalInterest,
    required this.principalAmount,
    required this.yearlyBreakdown,
  });
}

class EMIBreakdown {
  final int year;
  final double principalPaid;
  final double interestPaid;
  final double balance;

  const EMIBreakdown({
    required this.year,
    required this.principalPaid,
    required this.interestPaid,
    required this.balance,
  });
}

/// Retirement calculation result
class RetirementResult {
  final double corpusRequired;
  final double monthlyInvestmentNeeded;
  final double currentSavingsValue;
  final double shortfall;
  final int yearsToRetirement;
  final double monthlyExpenseAtRetirement;

  const RetirementResult({
    required this.corpusRequired,
    required this.monthlyInvestmentNeeded,
    required this.currentSavingsValue,
    required this.shortfall,
    required this.yearsToRetirement,
    required this.monthlyExpenseAtRetirement,
  });
}

/// Emergency Fund calculation result
class EmergencyFundResult {
  final double recommendedFund;
  final double currentCoverage;
  final int monthsCovered;
  final double monthlyContribution;
  final int monthsToGoal;
  final String riskLevel;

  const EmergencyFundResult({
    required this.recommendedFund,
    required this.currentCoverage,
    required this.monthsCovered,
    required this.monthlyContribution,
    required this.monthsToGoal,
    required this.riskLevel,
  });
}

// ============================================================================
// Calculator Logic
// ============================================================================

class FinancialCalculators {
  /// Calculate EMI for a loan
  static EMIResult calculateEMI({
    required double principal,
    required double annualRate,
    required int tenureMonths,
  }) {
    final monthlyRate = annualRate / 12 / 100;
    
    double emi;
    if (monthlyRate == 0) {
      emi = principal / tenureMonths;
    } else {
      emi = principal *
          monthlyRate *
          pow(1 + monthlyRate, tenureMonths) /
          (pow(1 + monthlyRate, tenureMonths) - 1);
    }

    final totalPayment = emi * tenureMonths;
    final totalInterest = totalPayment - principal;

    // Calculate yearly breakdown
    final yearlyBreakdown = <EMIBreakdown>[];
    double balance = principal;
    int years = (tenureMonths / 12).ceil();

    for (int year = 1; year <= years; year++) {
      int monthsInYear = year == years ? tenureMonths % 12 : 12;
      if (monthsInYear == 0) monthsInYear = 12;

      double yearPrincipal = 0;
      double yearInterest = 0;

      for (int month = 0; month < monthsInYear && balance > 0; month++) {
        final interestForMonth = balance * monthlyRate;
        final principalForMonth = emi - interestForMonth;
        yearInterest += interestForMonth;
        yearPrincipal += principalForMonth;
        balance -= principalForMonth;
        if (balance < 0) balance = 0;
      }

      yearlyBreakdown.add(EMIBreakdown(
        year: year,
        principalPaid: yearPrincipal,
        interestPaid: yearInterest,
        balance: balance,
      ));
    }

    return EMIResult(
      monthlyEMI: emi,
      totalPayment: totalPayment,
      totalInterest: totalInterest,
      principalAmount: principal,
      yearlyBreakdown: yearlyBreakdown,
    );
  }

  /// Calculate retirement corpus and monthly investment needed
  static RetirementResult calculateRetirement({
    required int currentAge,
    required int retirementAge,
    required double currentMonthlyExpense,
    required double currentSavings,
    required double expectedInflation,
    required double expectedReturns,
    required int yearsAfterRetirement,
  }) {
    final yearsToRetirement = retirementAge - currentAge;
    
    // Adjust expense for inflation at retirement
    final monthlyExpenseAtRetirement = currentMonthlyExpense *
        pow(1 + expectedInflation / 100, yearsToRetirement);
    
    // Calculate corpus required (assuming 4% safe withdrawal rate)
    // Or use present value of annuity formula
    final realReturn = (expectedReturns - expectedInflation) / 100;
    final annualExpenseAtRetirement = monthlyExpenseAtRetirement * 12;
    
    // Corpus = Annual Expense * ((1 - (1+r)^-n) / r) where n = years after retirement
    double corpusRequired;
    if (realReturn == 0) {
      corpusRequired = annualExpenseAtRetirement * yearsAfterRetirement;
    } else {
      corpusRequired = annualExpenseAtRetirement *
          (1 - pow(1 + realReturn, -yearsAfterRetirement)) / realReturn;
    }
    
    // Future value of current savings
    final currentSavingsValue = currentSavings *
        pow(1 + expectedReturns / 100, yearsToRetirement);
    
    // Shortfall
    final shortfall = corpusRequired - currentSavingsValue;
    
    // Monthly investment needed (PMT formula)
    final monthlyReturn = expectedReturns / 12 / 100;
    final totalMonths = yearsToRetirement * 12;
    
    double monthlyInvestment;
    if (shortfall <= 0) {
      monthlyInvestment = 0;
    } else if (monthlyReturn == 0) {
      monthlyInvestment = shortfall / totalMonths;
    } else {
      monthlyInvestment = shortfall * monthlyReturn /
          (pow(1 + monthlyReturn, totalMonths) - 1);
    }
    
    return RetirementResult(
      corpusRequired: corpusRequired,
      monthlyInvestmentNeeded: monthlyInvestment,
      currentSavingsValue: currentSavingsValue,
      shortfall: shortfall > 0 ? shortfall : 0,
      yearsToRetirement: yearsToRetirement,
      monthlyExpenseAtRetirement: monthlyExpenseAtRetirement,
    );
  }

  /// Calculate emergency fund requirements
  static EmergencyFundResult calculateEmergencyFund({
    required double monthlyExpense,
    required double currentEmergencyFund,
    required bool hasStableIncome,
    required bool hasDependents,
    required double monthlyContribution,
  }) {
    // Determine recommended months of coverage
    int recommendedMonths;
    String riskLevel;
    
    if (!hasStableIncome && hasDependents) {
      recommendedMonths = 12;
      riskLevel = 'High Risk';
    } else if (!hasStableIncome || hasDependents) {
      recommendedMonths = 9;
      riskLevel = 'Medium-High Risk';
    } else {
      recommendedMonths = 6;
      riskLevel = 'Standard Risk';
    }
    
    final recommendedFund = monthlyExpense * recommendedMonths;
    final currentCoverage = (currentEmergencyFund / monthlyExpense * 100).clamp(0.0, 200.0);
    final monthsCovered = (currentEmergencyFund / monthlyExpense).floor();
    
    // Calculate months to goal
    final shortfall = recommendedFund - currentEmergencyFund;
    int monthsToGoal;
    if (shortfall <= 0) {
      monthsToGoal = 0;
    } else if (monthlyContribution <= 0) {
      monthsToGoal = -1; // Infinite
    } else {
      monthsToGoal = (shortfall / monthlyContribution).ceil();
    }
    
    return EmergencyFundResult(
      recommendedFund: recommendedFund,
      currentCoverage: currentCoverage,
      monthsCovered: monthsCovered,
      monthlyContribution: monthlyContribution,
      monthsToGoal: monthsToGoal,
      riskLevel: riskLevel,
    );
  }
}

// ============================================================================
// Calculators Screen
// ============================================================================

class CalculatorsScreen extends ConsumerStatefulWidget {
  const CalculatorsScreen({super.key});

  @override
  ConsumerState<CalculatorsScreen> createState() => _CalculatorsScreenState();
}

class _CalculatorsScreenState extends ConsumerState<CalculatorsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Calculators'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(ESUNSpacing.md),
        children: [
          // Header
          Text(
            'Plan Your Financial Future',
            style: ESUNTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: ESUNSpacing.xs),
          Text(
            'Use these tools to make informed financial decisions. Your financial coach Kantha recommends starting with an emergency fund.',
            style: ESUNTypography.bodyMedium.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
          const SizedBox(height: ESUNSpacing.xl),
          
          // Calculator Cards
          _buildCalculatorCard(
            icon: Icons.account_balance,
            title: 'EMI Calculator',
            subtitle: 'Calculate loan EMI, interest, and payment schedule',
            color: const Color(0xFF2E4A9A),
            onTap: () => _showEMICalculator(context),
          ),
          const SizedBox(height: ESUNSpacing.md),
          
          _buildCalculatorCard(
            icon: Icons.elderly,
            title: 'Retirement Calculator',
            subtitle: 'Plan your retirement corpus and monthly savings',
            color: const Color(0xFF059669),
            onTap: () => _showRetirementCalculator(context),
          ),
          const SizedBox(height: ESUNSpacing.md),
          
          _buildCalculatorCard(
            icon: Icons.savings,
            title: 'Emergency Fund Calculator',
            subtitle: 'Calculate your ideal emergency fund size',
            color: const Color(0xFFF59E0B),
            onTap: () => _showEmergencyFundCalculator(context),
          ),
          const SizedBox(height: ESUNSpacing.md),
          
          _buildCalculatorCard(
            icon: Icons.trending_up,
            title: 'SIP Calculator',
            subtitle: 'Project your SIP returns over time',
            color: const Color(0xFFEC4899),
            onTap: () => _showSIPCalculator(context),
            badge: 'NEW',
          ),
          
          const SizedBox(height: ESUNSpacing.xxl),
          
          // Coach Tip
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ESUNColors.primary.withOpacity(0.1),
                  ESUNColors.secondary.withOpacity(0.1),
                ],
              ),
              borderRadius: ESUNRadius.lgRadius,
              border: Border.all(color: ESUNColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(ESUNSpacing.md),
                  decoration: BoxDecoration(
                    color: ESUNColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    color: ESUNColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: ESUNSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coach Kantha\'s Tip',
                        style: ESUNTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ESUNColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Build your emergency fund first, then focus on high-interest debt, and finally invest for the future.',
                        style: ESUNTypography.bodySmall.copyWith(
                          color: ESUNColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return FPCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.md),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: ESUNRadius.mdRadius,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: ESUNTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: ESUNSpacing.tagInsets,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: ESUNRadius.fullRadius,
                        ),
                        child: Text(
                          badge,
                          style: ESUNTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: ESUNTypography.bodySmall.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: ESUNColors.textTertiary),
        ],
      ),
    );
  }

  void _showEMICalculator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EMICalculatorSheet(),
    );
  }

  void _showRetirementCalculator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RetirementCalculatorSheet(),
    );
  }

  void _showEmergencyFundCalculator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EmergencyFundCalculatorSheet(),
    );
  }

  void _showSIPCalculator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SIPCalculatorSheet(),
    );
  }
}

// ============================================================================
// EMI Calculator Sheet
// ============================================================================

class EMICalculatorSheet extends StatefulWidget {
  const EMICalculatorSheet({super.key});

  @override
  State<EMICalculatorSheet> createState() => _EMICalculatorSheetState();
}

class _EMICalculatorSheetState extends State<EMICalculatorSheet> {
  double _principal = 1000000;
  double _interestRate = 8.5;
  int _tenureYears = 5;
  EMIResult? _result;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    setState(() {
      _result = FinancialCalculators.calculateEMI(
        principal: _principal,
        annualRate: _interestRate,
        tenureMonths: _tenureYears * 12,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? ESUNColors.darkSurface : ESUNColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: const BoxDecoration(
              color: ESUNColors.border,
              borderRadius: ESUNRadius.fullRadius,
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(ESUNSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E4A9A).withOpacity(0.1),
                    borderRadius: ESUNRadius.mdRadius,
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Color(0xFF2E4A9A),
                  ),
                ),
                const SizedBox(width: ESUNSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EMI Calculator',
                        style: ESUNTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Calculate your loan EMI',
                        style: ESUNTypography.bodySmall.copyWith(
                          color: ESUNColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Principal Amount
                  _buildSliderSection(
                    title: 'Loan Amount',
                    value: _principal,
                    min: 100000,
                    max: 10000000,
                    divisions: 99,
                    displayValue: _principal.toCompactCurrency(),
                    onChanged: (v) {
                      _principal = v;
                      _calculate();
                    },
                  ),
                  
                  // Interest Rate
                  _buildSliderSection(
                    title: 'Interest Rate (% p.a.)',
                    value: _interestRate,
                    min: 5,
                    max: 20,
                    divisions: 30,
                    displayValue: '${_interestRate.toStringAsFixed(1)}%',
                    onChanged: (v) {
                      _interestRate = v;
                      _calculate();
                    },
                  ),
                  
                  // Tenure
                  _buildSliderSection(
                    title: 'Loan Tenure',
                    value: _tenureYears.toDouble(),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    displayValue: '$_tenureYears years',
                    onChanged: (v) {
                      _tenureYears = v.round();
                      _calculate();
                    },
                  ),
                  
                  const SizedBox(height: ESUNSpacing.xl),
                  
                  // Results
                  if (_result != null) ...[
                    // Monthly EMI
                    Container(
                      padding: const EdgeInsets.all(ESUNSpacing.lg),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2E4A9A), Color(0xFF223474)],
                        ),
                        borderRadius: ESUNRadius.lgRadius,
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Monthly EMI',
                            style: ESUNTypography.bodyMedium.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _result!.monthlyEMI.toCurrency(decimals: 0),
                            style: ESUNTypography.headlineMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: ESUNSpacing.lg),
                    
                    // Breakdown
                    Row(
                      children: [
                        Expanded(
                          child: _buildResultCard(
                            'Principal',
                            _result!.principalAmount.toCompactCurrency(),
                            const Color(0xFF2E4A9A),
                          ),
                        ),
                        const SizedBox(width: ESUNSpacing.sm),
                        Expanded(
                          child: _buildResultCard(
                            'Total Interest',
                            _result!.totalInterest.toCompactCurrency(),
                            const Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: ESUNSpacing.sm),
                        Expanded(
                          child: _buildResultCard(
                            'Total Payment',
                            _result!.totalPayment.toCompactCurrency(),
                            const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: ESUNSpacing.lg),
                    
                    // Pie Chart
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: _result!.principalAmount,
                              color: const Color(0xFF2E4A9A),
                              title: 'Principal',
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              radius: 60,
                            ),
                            PieChartSectionData(
                              value: _result!.totalInterest,
                              color: const Color(0xFFF59E0B),
                              title: 'Interest',
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              radius: 60,
                            ),
                          ],
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: ESUNSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSection({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: ESUNTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              displayValue,
              style: ESUNTypography.titleSmall.copyWith(
                color: ESUNColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: ESUNColors.primary,
          onChanged: onChanged,
        ),
        const SizedBox(height: ESUNSpacing.sm),
      ],
    );
  }

  Widget _buildResultCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: ESUNRadius.mdRadius,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: ESUNTypography.labelSmall.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: ESUNTypography.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Retirement Calculator Sheet
// ============================================================================

class RetirementCalculatorSheet extends StatefulWidget {
  const RetirementCalculatorSheet({super.key});

  @override
  State<RetirementCalculatorSheet> createState() => _RetirementCalculatorSheetState();
}

class _RetirementCalculatorSheetState extends State<RetirementCalculatorSheet> {
  int _currentAge = 30;
  int _retirementAge = 60;
  double _monthlyExpense = 50000;
  double _currentSavings = 500000;
  final double _expectedInflation = 6.0;
  double _expectedReturns = 12.0;
  final int _yearsAfterRetirement = 25;
  RetirementResult? _result;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    setState(() {
      _result = FinancialCalculators.calculateRetirement(
        currentAge: _currentAge,
        retirementAge: _retirementAge,
        currentMonthlyExpense: _monthlyExpense,
        currentSavings: _currentSavings,
        expectedInflation: _expectedInflation,
        expectedReturns: _expectedReturns,
        yearsAfterRetirement: _yearsAfterRetirement,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? ESUNColors.darkSurface : ESUNColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: const BoxDecoration(
              color: ESUNColors.border,
              borderRadius: ESUNRadius.fullRadius,
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(ESUNSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withOpacity(0.1),
                    borderRadius: ESUNRadius.mdRadius,
                  ),
                  child: const Icon(
                    Icons.elderly,
                    color: Color(0xFF059669),
                  ),
                ),
                const SizedBox(width: ESUNSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Retirement Calculator',
                        style: ESUNTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Plan your retirement corpus',
                        style: ESUNTypography.bodySmall.copyWith(
                          color: ESUNColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Age
                  _buildSliderSection(
                    title: 'Current Age',
                    value: _currentAge.toDouble(),
                    min: 20,
                    max: 55,
                    divisions: 35,
                    displayValue: '$_currentAge years',
                    onChanged: (v) {
                      _currentAge = v.round();
                      if (_retirementAge <= _currentAge) {
                        _retirementAge = _currentAge + 5;
                      }
                      _calculate();
                    },
                  ),
                  
                  // Retirement Age
                  _buildSliderSection(
                    title: 'Retirement Age',
                    value: _retirementAge.toDouble(),
                    min: _currentAge + 5,
                    max: 70,
                    divisions: 70 - _currentAge - 5,
                    displayValue: '$_retirementAge years',
                    onChanged: (v) {
                      _retirementAge = v.round();
                      _calculate();
                    },
                  ),
                  
                  // Monthly Expense
                  _buildSliderSection(
                    title: 'Current Monthly Expense',
                    value: _monthlyExpense,
                    min: 20000,
                    max: 500000,
                    divisions: 48,
                    displayValue: _monthlyExpense.toCompactCurrency(),
                    onChanged: (v) {
                      _monthlyExpense = v;
                      _calculate();
                    },
                  ),
                  
                  // Current Savings
                  _buildSliderSection(
                    title: 'Current Retirement Savings',
                    value: _currentSavings,
                    min: 0,
                    max: 10000000,
                    divisions: 100,
                    displayValue: _currentSavings.toCompactCurrency(),
                    onChanged: (v) {
                      _currentSavings = v;
                      _calculate();
                    },
                  ),
                  
                  // Expected Returns
                  _buildSliderSection(
                    title: 'Expected Returns (% p.a.)',
                    value: _expectedReturns,
                    min: 6,
                    max: 18,
                    divisions: 24,
                    displayValue: '${_expectedReturns.toStringAsFixed(1)}%',
                    onChanged: (v) {
                      _expectedReturns = v;
                      _calculate();
                    },
                  ),
                  
                  const SizedBox(height: ESUNSpacing.xl),
                  
                  // Results
                  if (_result != null) ...[
                    Container(
                      padding: const EdgeInsets.all(ESUNSpacing.lg),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                        ),
                        borderRadius: ESUNRadius.lgRadius,
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Retirement Corpus Needed',
                            style: ESUNTypography.bodyMedium.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _result!.corpusRequired.toCompactCurrency(),
                            style: ESUNTypography.headlineMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: ESUNSpacing.md),
                          Container(
                            padding: const EdgeInsets.all(ESUNSpacing.md),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: ESUNRadius.mdRadius,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.trending_up, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Start investing ${_result!.monthlyInvestmentNeeded.toCurrency(decimals: 0)}/month',
                                  style: ESUNTypography.titleSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: ESUNSpacing.lg),
                    
                    // Details
                    FPCard(
                      child: Column(
                        children: [
                          _buildDetailRow('Years to Retirement', '${_result!.yearsToRetirement} years'),
                          const Divider(),
                          _buildDetailRow('Monthly Expense at Retirement', _result!.monthlyExpenseAtRetirement.toCurrency(decimals: 0)),
                          const Divider(),
                          _buildDetailRow('Current Savings Future Value', _result!.currentSavingsValue.toCompactCurrency()),
                          const Divider(),
                          _buildDetailRow('Shortfall to Bridge', _result!.shortfall.toCompactCurrency()),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: ESUNSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSection({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: ESUNTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              displayValue,
              style: ESUNTypography.titleSmall.copyWith(
                color: const Color(0xFF059669),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions > 0 ? divisions : 1,
          activeColor: const Color(0xFF059669),
          onChanged: onChanged,
        ),
        const SizedBox(height: ESUNSpacing.sm),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: ESUNTypography.bodySmall.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: ESUNTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Emergency Fund Calculator Sheet
// ============================================================================

class EmergencyFundCalculatorSheet extends StatefulWidget {
  const EmergencyFundCalculatorSheet({super.key});

  @override
  State<EmergencyFundCalculatorSheet> createState() => _EmergencyFundCalculatorSheetState();
}

class _EmergencyFundCalculatorSheetState extends State<EmergencyFundCalculatorSheet> {
  double _monthlyExpense = 50000;
  double _currentFund = 100000;
  bool _hasStableIncome = true;
  bool _hasDependents = true;
  double _monthlyContribution = 10000;
  EmergencyFundResult? _result;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    setState(() {
      _result = FinancialCalculators.calculateEmergencyFund(
        monthlyExpense: _monthlyExpense,
        currentEmergencyFund: _currentFund,
        hasStableIncome: _hasStableIncome,
        hasDependents: _hasDependents,
        monthlyContribution: _monthlyContribution,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? ESUNColors.darkSurface : ESUNColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: const BoxDecoration(
              color: ESUNColors.border,
              borderRadius: ESUNRadius.fullRadius,
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(ESUNSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: ESUNRadius.mdRadius,
                  ),
                  child: const Icon(
                    Icons.savings,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: ESUNSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency Fund Calculator',
                        style: ESUNTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Calculate your safety net',
                        style: ESUNTypography.bodySmall.copyWith(
                          color: ESUNColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Monthly Expense
                  _buildSliderSection(
                    title: 'Monthly Expenses',
                    value: _monthlyExpense,
                    min: 10000,
                    max: 300000,
                    divisions: 29,
                    displayValue: _monthlyExpense.toCurrency(decimals: 0),
                    onChanged: (v) {
                      _monthlyExpense = v;
                      _calculate();
                    },
                  ),
                  
                  // Current Fund
                  _buildSliderSection(
                    title: 'Current Emergency Savings',
                    value: _currentFund,
                    min: 0,
                    max: 2000000,
                    divisions: 40,
                    displayValue: _currentFund.toCurrency(decimals: 0),
                    onChanged: (v) {
                      _currentFund = v;
                      _calculate();
                    },
                  ),
                  
                  // Monthly Contribution
                  _buildSliderSection(
                    title: 'Monthly Contribution',
                    value: _monthlyContribution,
                    min: 0,
                    max: 100000,
                    divisions: 20,
                    displayValue: _monthlyContribution.toCurrency(decimals: 0),
                    onChanged: (v) {
                      _monthlyContribution = v;
                      _calculate();
                    },
                  ),
                  
                  const SizedBox(height: ESUNSpacing.md),
                  
                  // Toggles
                  FPCard(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Stable Income'),
                          subtitle: Text(
                            'Do you have a regular, stable income?',
                            style: ESUNTypography.bodySmall.copyWith(
                              color: ESUNColors.textSecondary,
                            ),
                          ),
                          value: _hasStableIncome,
                          activeColor: const Color(0xFFF59E0B),
                          onChanged: (v) {
                            setState(() {
                              _hasStableIncome = v;
                              _calculate();
                            });
                          },
                        ),
                        const Divider(),
                        SwitchListTile(
                          title: const Text('Dependents'),
                          subtitle: Text(
                            'Do you have family members depending on you?',
                            style: ESUNTypography.bodySmall.copyWith(
                              color: ESUNColors.textSecondary,
                            ),
                          ),
                          value: _hasDependents,
                          activeColor: const Color(0xFFF59E0B),
                          onChanged: (v) {
                            setState(() {
                              _hasDependents = v;
                              _calculate();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: ESUNSpacing.xl),
                  
                  // Results
                  if (_result != null) ...[
                    Container(
                      padding: const EdgeInsets.all(ESUNSpacing.lg),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                        ),
                        borderRadius: ESUNRadius.lgRadius,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: ESUNRadius.fullRadius,
                                ),
                                child: Text(
                                  _result!.riskLevel,
                                  style: ESUNTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: ESUNSpacing.md),
                          Text(
                            'Recommended Emergency Fund',
                            style: ESUNTypography.bodyMedium.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _result!.recommendedFund.toCurrency(decimals: 0),
                            style: ESUNTypography.headlineMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: ESUNSpacing.lg),
                    
                    // Progress
                    FPCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Current Coverage',
                                style: ESUNTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${_result!.monthsCovered} months',
                                style: ESUNTypography.titleSmall.copyWith(
                                  color: const Color(0xFFF59E0B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: ESUNSpacing.md),
                          ClipRRect(
                            borderRadius: ESUNRadius.smRadius,
                            child: LinearProgressIndicator(
                              value: (_result!.currentCoverage / 100).clamp(0.0, 1.0),
                              backgroundColor: ESUNColors.border,
                              valueColor: AlwaysStoppedAnimation(
                                _result!.currentCoverage >= 100
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFF59E0B),
                              ),
                              minHeight: 10,
                            ),
                          ),
                          const SizedBox(height: ESUNSpacing.md),
                          if (_result!.monthsToGoal > 0)
                            Container(
                              padding: const EdgeInsets.all(ESUNSpacing.md),
                              decoration: BoxDecoration(
                                color: ESUNColors.primary.withOpacity(0.1),
                                borderRadius: ESUNRadius.mdRadius,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    color: ESUNColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'At your current contribution rate, you\'ll reach your goal in ${_result!.monthsToGoal} months.',
                                      style: ESUNTypography.bodySmall.copyWith(
                                        color: ESUNColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (_result!.monthsToGoal == 0)
                            Container(
                              padding: const EdgeInsets.all(ESUNSpacing.md),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withOpacity(0.1),
                                borderRadius: ESUNRadius.mdRadius,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF059669),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Congratulations! You\'ve reached your emergency fund goal.',
                                    style: ESUNTypography.bodySmall.copyWith(
                                      color: const Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: ESUNSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSection({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: ESUNTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              displayValue,
              style: ESUNTypography.titleSmall.copyWith(
                color: const Color(0xFFF59E0B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: const Color(0xFFF59E0B),
          onChanged: onChanged,
        ),
        const SizedBox(height: ESUNSpacing.sm),
      ],
    );
  }
}

// ============================================================================
// SIP Calculator Sheet (Bonus)
// ============================================================================

class SIPCalculatorSheet extends StatefulWidget {
  const SIPCalculatorSheet({super.key});

  @override
  State<SIPCalculatorSheet> createState() => _SIPCalculatorSheetState();
}

class _SIPCalculatorSheetState extends State<SIPCalculatorSheet> {
  double _monthlyInvestment = 10000;
  double _expectedReturn = 12.0;
  int _tenureYears = 10;
  
  double get _investedAmount => _monthlyInvestment * _tenureYears * 12;
  double get _futureValue {
    final monthlyRate = _expectedReturn / 12 / 100;
    final months = _tenureYears * 12;
    if (monthlyRate == 0) return _investedAmount;
    return _monthlyInvestment *
        ((pow(1 + monthlyRate, months) - 1) / monthlyRate) *
        (1 + monthlyRate);
  }
  double get _wealthGained => _futureValue - _investedAmount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? ESUNColors.darkSurface : ESUNColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: const BoxDecoration(
              color: ESUNColors.border,
              borderRadius: ESUNRadius.fullRadius,
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(ESUNSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withOpacity(0.1),
                    borderRadius: ESUNRadius.mdRadius,
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Color(0xFFEC4899),
                  ),
                ),
                const SizedBox(width: ESUNSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SIP Calculator',
                        style: ESUNTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Project your SIP returns',
                        style: ESUNTypography.bodySmall.copyWith(
                          color: ESUNColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Monthly Investment
                  _buildSliderSection(
                    title: 'Monthly Investment',
                    value: _monthlyInvestment,
                    min: 500,
                    max: 100000,
                    divisions: 199,
                    displayValue: _monthlyInvestment.toCurrency(decimals: 0),
                    onChanged: (v) => setState(() => _monthlyInvestment = v),
                  ),
                  
                  // Expected Return
                  _buildSliderSection(
                    title: 'Expected Return (% p.a.)',
                    value: _expectedReturn,
                    min: 6,
                    max: 18,
                    divisions: 24,
                    displayValue: '${_expectedReturn.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() => _expectedReturn = v),
                  ),
                  
                  // Tenure
                  _buildSliderSection(
                    title: 'Investment Period',
                    value: _tenureYears.toDouble(),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    displayValue: '$_tenureYears years',
                    onChanged: (v) => setState(() => _tenureYears = v.round()),
                  ),
                  
                  const SizedBox(height: ESUNSpacing.xl),
                  
                  // Future Value
                  Container(
                    padding: const EdgeInsets.all(ESUNSpacing.lg),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                      ),
                      borderRadius: ESUNRadius.lgRadius,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Future Value',
                          style: ESUNTypography.bodyMedium.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _futureValue.toCompactCurrency(),
                          style: ESUNTypography.headlineMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: ESUNSpacing.lg),
                  
                  // Breakdown
                  Row(
                    children: [
                      Expanded(
                        child: _buildResultCard(
                          'Invested',
                          _investedAmount.toCompactCurrency(),
                          const Color(0xFFEC4899),
                        ),
                      ),
                      const SizedBox(width: ESUNSpacing.sm),
                      Expanded(
                        child: _buildResultCard(
                          'Wealth Gained',
                          _wealthGained.toCompactCurrency(),
                          const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: ESUNSpacing.lg),
                  
                  // Pie Chart
                  SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: _investedAmount,
                            color: const Color(0xFFEC4899),
                            title: 'Invested',
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            radius: 55,
                          ),
                          PieChartSectionData(
                            value: _wealthGained,
                            color: const Color(0xFF059669),
                            title: 'Returns',
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            radius: 55,
                          ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 35,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: ESUNSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSection({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: ESUNTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              displayValue,
              style: ESUNTypography.titleSmall.copyWith(
                color: const Color(0xFFEC4899),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: const Color(0xFFEC4899),
          onChanged: onChanged,
        ),
        const SizedBox(height: ESUNSpacing.sm),
      ],
    );
  }

  Widget _buildResultCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: ESUNRadius.mdRadius,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: ESUNTypography.labelSmall.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: ESUNTypography.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
