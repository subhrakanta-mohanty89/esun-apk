/// Persona Comparison Screen
///
/// UI for comparing structured vs unstructured financial profiles.
/// Shows health score, key ratios, and persona-specific insights.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'persona_service.dart';

/// Persona Comparison Screen
class PersonaComparisonScreen extends ConsumerStatefulWidget {
  const PersonaComparisonScreen({super.key});

  @override
  ConsumerState<PersonaComparisonScreen> createState() =>
      _PersonaComparisonScreenState();
}

class _PersonaComparisonScreenState
    extends ConsumerState<PersonaComparisonScreen> {
  @override
  void initState() {
    super.initState();
    // Load insights when screen opens
    Future.microtask(() {
      ref.read(personaInsightsProvider.notifier).loadInsights();
    });
  }

  @override
  Widget build(BuildContext context) {
    final insightsAsync = ref.watch(personaInsightsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Health Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(personaInsightsProvider.notifier).loadInsights();
            },
          ),
        ],
      ),
      body: insightsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading insights: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(personaInsightsProvider.notifier).loadInsights();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (insights) {
          if (insights == null) {
            return const Center(child: Text('No insights available'));
          }
          return _buildContent(context, insights);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, PersonaInsights insights) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Persona Type Card
          _buildPersonaCard(context, insights),
          const SizedBox(height: 16),

          // Health Score Card
          _buildHealthScoreCard(context, insights),
          const SizedBox(height: 16),

          // Key Metrics Comparison
          _buildComparisonCard(context, insights),
          const SizedBox(height: 16),

          // Financial Summary
          _buildSummaryCard(context, insights),
          const SizedBox(height: 16),

          // Persona-specific section
          if (insights.personaType == PersonaType.structured)
            _buildStructuredSection(context, insights)
          else if (insights.personaType == PersonaType.unstructured)
            _buildUnstructuredSection(context, insights),

          // Indicators
          _buildIndicatorsSection(context, insights),
          const SizedBox(height: 16),

          // Loans Summary
          if (insights.loans.isNotEmpty) _buildLoansSection(context, insights),
        ],
      ),
    );
  }

  Widget _buildPersonaCard(BuildContext context, PersonaInsights insights) {
    final isStructured = insights.personaType == PersonaType.structured;
    final color = isStructured ? Colors.green : Colors.orange;
    final icon = isStructured ? Icons.account_balance : Icons.trending_down;
    final title = isStructured ? 'Structured Profile' : 'Unstructured Profile';
    final subtitle = isStructured
        ? 'Organized debt with secured loans and regular income'
        : 'Multiple unsecured loans with liquidity stress indicators';

    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthScoreCard(BuildContext context, PersonaInsights insights) {
    final score = insights.healthScoreNumeric;
    final healthScore = insights.healthScore;
    
    Color scoreColor;
    switch (healthScore) {
      case HealthScore.excellent:
        scoreColor = Colors.green;
        break;
      case HealthScore.good:
        scoreColor = Colors.lightGreen;
        break;
      case HealthScore.fair:
        scoreColor = Colors.orange;
        break;
      case HealthScore.poor:
        scoreColor = Colors.deepOrange;
        break;
      case HealthScore.critical:
        scoreColor = Colors.red;
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Financial Health Score',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    healthScore.displayName,
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 120,
                        width: 120,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: score / 100,
                              strokeWidth: 12,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation(scoreColor),
                            ),
                            Center(
                              child: Text(
                                '${score.toInt()}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: scoreColor,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildScoreIndicator('Credit Score',
                          insights.credit.score?.toString() ?? 'N/A'),
                      const SizedBox(height: 8),
                      _buildScoreIndicator('Net Worth',
                          _formatCurrency(insights.wealth.netWorth)),
                      const SizedBox(height: 8),
                      _buildScoreIndicator('Savings Rate',
                          '${insights.ratios.savingsRate.toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreIndicator(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildComparisonCard(BuildContext context, PersonaInsights insights) {
    final metrics = insights.comparisonMetrics;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Structured vs Unstructured Comparison',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildComparisonRow(
              'Debt-to-Income',
              metrics.current.dti,
              metrics.structuredBenchmark.dti,
              metrics.unstructuredTypical.dti,
              lowerIsBetter: true,
            ),
            const Divider(),
            _buildComparisonRow(
              'EMI-to-Income',
              metrics.current.emiRatio,
              metrics.structuredBenchmark.emiRatio,
              metrics.unstructuredTypical.emiRatio,
              lowerIsBetter: true,
            ),
            const Divider(),
            _buildComparisonRow(
              'Credit Utilization',
              metrics.current.creditUtilization,
              metrics.structuredBenchmark.creditUtilization,
              metrics.unstructuredTypical.creditUtilization,
              lowerIsBetter: true,
            ),
            const Divider(),
            _buildComparisonRow(
              'Savings Rate',
              metrics.current.savingsRate,
              metrics.structuredBenchmark.savingsRate,
              metrics.unstructuredTypical.savingsRate,
              lowerIsBetter: false,
            ),
            const Divider(),
            _buildComparisonRow(
              'Health Score',
              metrics.current.healthScore,
              metrics.structuredBenchmark.healthScore,
              metrics.unstructuredTypical.healthScore,
              lowerIsBetter: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(
    String label,
    double current,
    double structured,
    double unstructured, {
    required bool lowerIsBetter,
  }) {
    // Determine if current is closer to structured or unstructured
    final distToStructured = (current - structured).abs();
    final distToUnstructured = (current - unstructured).abs();
    final isCloserToStructured = distToStructured < distToUnstructured;

    Color currentColor;
    if (lowerIsBetter) {
      currentColor = current <= structured
          ? Colors.green
          : (current >= unstructured ? Colors.red : Colors.orange);
    } else {
      currentColor = current >= structured
          ? Colors.green
          : (current <= unstructured ? Colors.red : Colors.orange);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('You', style: TextStyle(fontSize: 10)),
                    Text(
                      '${current.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: currentColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text('Structured',
                        style: TextStyle(fontSize: 10, color: Colors.green)),
                    Text(
                      '${structured.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text('Unstructured',
                        style: TextStyle(fontSize: 10, color: Colors.orange)),
                    Text(
                      '${unstructured.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: (current - unstructured) / (structured - unstructured).abs(),
            backgroundColor: Colors.orange.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(
              isCloserToStructured ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, PersonaInsights insights) {
    final summary = insights.summary;
    final wealth = insights.wealth;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Monthly Income',
                    _formatCurrency(summary.totalMonthlyIncome),
                    Icons.arrow_upward,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Monthly Expense',
                    _formatCurrency(summary.totalMonthlyExpense),
                    Icons.arrow_downward,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Monthly EMI',
                    _formatCurrency(summary.totalMonthlyEmi),
                    Icons.payment,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Net Surplus',
                    _formatCurrency(summary.netMonthlySurplus),
                    Icons.savings,
                    summary.netMonthlySurplus >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Assets',
                    _formatCurrency(wealth.totalAssets),
                    Icons.account_balance_wallet,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Total Liabilities',
                    _formatCurrency(wealth.totalLiabilities),
                    Icons.credit_card,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStructuredSection(
      BuildContext context, PersonaInsights insights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Net Worth Breakdown
        if (insights.netWorthBreakdown != null)
          _buildNetWorthCard(context, insights.netWorthBreakdown!),
        const SizedBox(height: 16),

        // Optimization Suggestions
        if (insights.optimizationSuggestions != null &&
            insights.optimizationSuggestions!.isNotEmpty)
          _buildOptimizationCard(context, insights.optimizationSuggestions!),
        const SizedBox(height: 16),

        // EMI Schedule Preview
        if (insights.emiSchedule != null && insights.emiSchedule!.isNotEmpty)
          _buildEmiSchedulePreview(context, insights.emiSchedule!),
      ],
    );
  }

  Widget _buildNetWorthCard(BuildContext context, NetWorthBreakdown breakdown) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net Worth Breakdown',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _formatCurrency(breakdown.netWorth),
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Assets',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      ...breakdown.assetsBreakdown.entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatLabel(e.key),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  _formatCurrencyShort(e.value),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Liabilities',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      ...breakdown.liabilitiesBreakdown.entries.map(
                          (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatLabel(e.key),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      _formatCurrencyShort(e.value),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMetricChip(
                    'Liquid', '${breakdown.liquidPercentage.toInt()}%'),
                const SizedBox(width: 8),
                _buildMetricChip(
                    'Secured', '${breakdown.securedPercentage.toInt()}%'),
                const SizedBox(width: 8),
                _buildMetricChip(
                    'A/L Ratio', '${breakdown.assetLiabilityRatio.toStringAsFixed(1)}x'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationCard(
      BuildContext context, List<String> suggestions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Optimization Suggestions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...suggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child:
                            Text(s, style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmiSchedulePreview(
      BuildContext context, List<EMIScheduleEntry> schedule) {
    final nextThree = schedule.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming EMI Payments',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full EMI schedule
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...nextThree.map((e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Text(
                      '${e.month}',
                      style: const TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(e.loanName),
                  subtitle: Text(DateFormat('MMM yyyy').format(e.paymentDate)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(e.totalEmi),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'P: ${_formatCurrencyShort(e.principal)} | I: ${_formatCurrencyShort(e.interest)}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildUnstructuredSection(
      BuildContext context, PersonaInsights insights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Liquidity Stress
        if (insights.liquidityStressScore != null)
          _buildLiquidityStressCard(context, insights),
        const SizedBox(height: 16),

        // Interest Burden
        if (insights.interestBurden != null)
          _buildInterestBurdenCard(context, insights.interestBurden!),
        const SizedBox(height: 16),

        // Consolidation Options
        if (insights.consolidationOptions != null &&
            insights.consolidationOptions!.isNotEmpty)
          _buildConsolidationCard(context, insights.consolidationOptions!),
      ],
    );
  }

  Widget _buildLiquidityStressCard(
      BuildContext context, PersonaInsights insights) {
    final stress = insights.liquidityStressScore ?? 0;
    Color stressColor;
    String stressLabel;

    if (stress >= 70) {
      stressColor = Colors.red;
      stressLabel = 'Critical';
    } else if (stress >= 50) {
      stressColor = Colors.deepOrange;
      stressLabel = 'High';
    } else if (stress >= 30) {
      stressColor = Colors.orange;
      stressLabel = 'Moderate';
    } else {
      stressColor = Colors.green;
      stressLabel = 'Low';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: stressColor),
                    const SizedBox(width: 8),
                    Text(
                      'Liquidity Stress',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: stressColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    stressLabel,
                    style: TextStyle(
                      color: stressColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: stress / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(stressColor),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              'Score: ${stress.toInt()}/100',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStressMetric(
                    'Liquid Assets',
                    _formatCurrency(insights.wealth.liquidAssets),
                    Icons.account_balance_wallet,
                  ),
                ),
                Expanded(
                  child: _buildStressMetric(
                    'Monthly Outflow',
                    _formatCurrency(insights.summary.totalMonthlyExpense +
                        insights.summary.totalMonthlyEmi),
                    Icons.trending_down,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStressMetric(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildInterestBurdenCard(
      BuildContext context, InterestBurden burden) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.percent, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Interest Burden',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text('Monthly Interest',
                            style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(burden.monthly),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text('Annual Interest',
                            style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(burden.annual),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsolidationCard(
      BuildContext context, List<ConsolidationOption> options) {
    final option = options.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.merge_type, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Debt Consolidation Option',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.savings, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Save ${_formatCurrency(option.monthlySavings)}/month',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current',
                          style: TextStyle(color: Colors.grey)),
                      Text(
                        'EMI: ${_formatCurrency(option.currentTotalEmi)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Rate: ${option.currentAvgRate.toStringAsFixed(1)}%',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.grey),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Proposed',
                          style: TextStyle(color: Colors.green)),
                      Text(
                        'EMI: ${_formatCurrency(option.proposedEmi)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Rate: ${option.proposedRate.toStringAsFixed(1)}%',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              option.recommendation,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to consolidation flow
                },
                child: const Text('Explore Consolidation'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorsSection(
      BuildContext context, PersonaInsights insights) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Indicators',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (insights.positiveIndicators.isNotEmpty) ...[
              const Text('Strengths',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              ...insights.positiveIndicators.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.add_circle,
                            color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(p, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
            ],
            if (insights.riskIndicators.isNotEmpty) ...[
              const Text('Areas of Concern',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              ...insights.riskIndicators.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.remove_circle,
                            color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(r, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoansSection(BuildContext context, PersonaInsights insights) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Loans',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...insights.loans.map((loan) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                loan.isSecured ? Icons.lock : Icons.lock_open,
                                size: 16,
                                color: loan.isSecured
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatLabel(loan.loanType),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            '${loan.interestRate}%',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(loan.lenderName,
                          style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Outstanding',
                                  style: TextStyle(fontSize: 11)),
                              Text(
                                _formatCurrency(loan.outstanding),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text('EMI', style: TextStyle(fontSize: 11)),
                              Text(
                                _formatCurrency(loan.emiAmount),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Remaining',
                                  style: TextStyle(fontSize: 11)),
                              Text(
                                '${loan.remainingMonths} months',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // Formatting helpers
  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _formatCurrencyShort(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toInt()}';
  }

  String _formatLabel(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}
