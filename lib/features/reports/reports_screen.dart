/// ESUN Reports Screen
/// 
/// Financial reports and analytics.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../theme/theme.dart';
import '../../shared/widgets/widgets.dart';
import '../../core/utils/utils.dart';
import '../../state/aa_data_state.dart';
import '../../state/transaction_state.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports'),
          actions: [
            IconButton(
              icon: const Icon(Icons.download_outlined),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report downloaded')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {
                final aaData = ref.read(aaDataProvider);
                final snapshot = aaData.snapshot;
                Share.share(
                  'ESUN Financial Report\n'
                  'Income: ${snapshot?.totalMonthlyIncome.toINR() ?? "N/A"}\n'
                  'Expenses: ${snapshot?.totalMonthlyExpense.toINR() ?? "N/A"}\n'
                  'Net Worth: ${snapshot?.netWorth.toINR() ?? "N/A"}',
                );
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Income'),
              Tab(text: 'Expenses'),
              Tab(text: 'Net Worth'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(ref),
            _buildIncomeTab(ref),
            _buildExpensesTab(ref),
            _buildNetWorthTab(ref),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOverviewTab(WidgetRef ref) {
    final aaData = ref.watch(aaDataProvider);
    final snapshot = aaData.snapshot;
    final income = snapshot?.totalMonthlyIncome ?? 0;
    final expenses = snapshot?.totalMonthlyExpense ?? 0;
    final savings = income - expenses;
    final investmentValue = aaData.totalInvestmentValue;
    
    // Build category breakdown from transactions
    final txns = ref.watch(transactionStateProvider).transactions;
    final categoryMap = <String, double>{};
    for (final t in txns) {
      if (t.isDebit) {
        categoryMap[t.category ?? 'Others'] = (categoryMap[t.category ?? 'Others'] ?? 0) + t.amount;
      }
    }
    final totalCatSpend = categoryMap.values.fold<double>(0, (s, v) => s + v);
    final categoryColors = {'Transfers': Colors.blue, 'Utilities': Colors.green, 'Telecom': Colors.purple, 'Finance': Colors.orange, 'Bills': Colors.teal, 'Others': Colors.grey, 'Shopping': Colors.pink, 'Food & Dining': Colors.amber};
    final categories = categoryMap.entries.map((e) => _CategoryData(
      e.key,
      e.value,
      categoryColors[e.key] ?? Colors.grey,
      totalCatSpend > 0 ? e.value / totalCatSpend : 0,
    )).toList()..sort((a, b) => b.amount.compareTo(a.amount));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: ESUNSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard('Income', income.toINR(), '+8.5%', Icons.arrow_upward, ESUNColors.success),
              ),
              const SizedBox(width: ESUNSpacing.md),
              Expanded(
                child: _buildSummaryCard('Expenses', expenses.toINR(), '', Icons.arrow_downward, ESUNColors.error),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard('Savings', savings.toINR(), '', Icons.savings, ESUNColors.primary),
              ),
              const SizedBox(width: ESUNSpacing.md),
              Expanded(
                child: _buildSummaryCard('Investments', investmentValue.toINR(), '', Icons.trending_up, Colors.purple),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.xl),
          Text('Spending by Category', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: ESUNSpacing.md),
          if (categories.isEmpty)
            const Center(child: Text('No spending data yet'))
          else
            _buildCategoryBreakdown(categories),
        ],
      ),
    );
  }
  
  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: ESUNColors.surfaceVariant,
        borderRadius: ESUNRadius.fullRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPeriodChip('Week', false),
          _buildPeriodChip('Month', true),
          _buildPeriodChip('Year', false),
          _buildPeriodChip('All', false),
        ],
      ),
    );
  }
  
  Widget _buildPeriodChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? ESUNColors.primary : Colors.transparent,
        borderRadius: ESUNRadius.fullRadius,
      ),
      child: Text(
        label,
        style: ESUNTypography.labelMedium.copyWith(
          color: isSelected ? Colors.white : ESUNColors.textSecondary,
        ),
      ),
    );
  }
  
  Widget _buildSummaryCard(
    String label,
    String value,
    String change,
    IconData icon,
    Color color,
  ) {
    final isPositive = change.startsWith('+');
    
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: ESUNRadius.lgRadius,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: ESUNTypography.labelMedium.copyWith(
                  color: ESUNColors.textSecondary,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: ESUNTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$change vs last month',
            style: ESUNTypography.labelSmall.copyWith(
              color: isPositive ? ESUNColors.success : ESUNColors.error,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryBreakdown(List<_CategoryData> categories) {
    
    return Column(
      children: categories.map((cat) {
        return Padding(
          padding: const EdgeInsets.only(bottom: ESUNSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: cat.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: ESUNSpacing.md),
              Expanded(
                child: Text(
                  cat.name,
                  style: ESUNTypography.bodyMedium,
                ),
              ),
              Text(
                cat.amount.toINR(),
                style: ESUNTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: ESUNSpacing.md),
              SizedBox(
                width: 50,
                child: Text(
                  '${(cat.percentage * 100).toInt()}%',
                  style: ESUNTypography.labelMedium.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildIncomeTab(WidgetRef ref) {
    final aaData = ref.watch(aaDataProvider);
    final snapshot = aaData.snapshot;
    final totalIncome = snapshot?.totalMonthlyIncome ?? 0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: ESUNSpacing.lg),
          FPCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Income', style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textSecondary)),
                const SizedBox(height: 4),
                Text(totalIncome.toINR(), style: ESUNTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold, color: ESUNColors.success)),
              ],
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          Text('Income Sources', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: ESUNSpacing.md),
          _buildIncomeSource('Salary', (totalIncome * 0.625).toINR(), Icons.work, Colors.blue),
          _buildIncomeSource('Freelance', (totalIncome * 0.208).toINR(), Icons.laptop, Colors.purple),
          _buildIncomeSource('Investments', (totalIncome * 0.125).toINR(), Icons.trending_up, Colors.green),
          _buildIncomeSource('Other', (totalIncome * 0.042).toINR(), Icons.more_horiz, Colors.grey),
        ],
      ),
    );
  }
  
  Widget _buildIncomeSource(String name, String amount, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.sm),
      child: FPCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(ESUNSpacing.md),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: ESUNRadius.smRadius,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: ESUNSpacing.md),
            Expanded(
              child: Text(
                name,
                style: ESUNTypography.bodyLarge,
              ),
            ),
            Text(
              amount,
              style: ESUNTypography.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: ESUNColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExpensesTab(WidgetRef ref) {
    final aaData = ref.watch(aaDataProvider);
    final snapshot = aaData.snapshot;
    final totalExpenses = snapshot?.totalMonthlyExpense ?? 0;
    
    // Build top expenses from transactions
    final txns = ref.watch(transactionStateProvider).transactions;
    final catMap = <String, double>{};
    for (final t in txns) {
      if (t.isDebit) {
        catMap[t.category ?? 'Others'] = (catMap[t.category ?? 'Others'] ?? 0) + t.amount;
      }
    }
    final topExpenses = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final catIcons = {'Transfers': Icons.swap_horiz, 'Utilities': Icons.receipt_long, 'Bills': Icons.receipt, 'Telecom': Icons.phone_android, 'Shopping': Icons.shopping_bag, 'Food & Dining': Icons.restaurant};
    final catColors = {'Transfers': Colors.blue, 'Utilities': Colors.green, 'Bills': Colors.teal, 'Telecom': Colors.purple, 'Shopping': Colors.pink, 'Food & Dining': Colors.orange};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: ESUNSpacing.lg),
          FPCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Expenses', style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textSecondary)),
                const SizedBox(height: 4),
                Text(totalExpenses.toINR(), style: ESUNTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold, color: ESUNColors.error)),
              ],
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          Text('Top Expenses', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: ESUNSpacing.md),
          if (topExpenses.isEmpty)
            const Center(child: Text('No expenses tracked yet'))
          else
            ...topExpenses.take(5).map((e) => _buildExpenseItem(
              e.key,
              e.value.toINR(),
              catIcons[e.key] ?? Icons.more_horiz,
              catColors[e.key] ?? Colors.grey,
            )),
        ],
      ),
    );
  }
  
  Widget _buildExpenseItem(String name, String amount, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.sm),
      child: FPCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(ESUNSpacing.md),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: ESUNRadius.smRadius,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: ESUNSpacing.md),
            Expanded(
              child: Text(
                name,
                style: ESUNTypography.bodyLarge,
              ),
            ),
            Text(
              amount,
              style: ESUNTypography.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNetWorthTab(WidgetRef ref) {
    final aaData = ref.watch(aaDataProvider);
    final snapshot = aaData.snapshot;
    final netWorth = snapshot?.netWorth ?? aaData.calculatedNetWorth;
    final totalAssets = snapshot?.totalAssets ?? (aaData.totalBankBalance + aaData.totalInvestmentValue);
    final totalLiabilities = snapshot?.totalLiabilities ?? aaData.totalLoanOutstanding;
    final assets = aaData.assetBreakdown;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FPGradientCard(
            gradient: const LinearGradient(colors: [ESUNColors.primary, ESUNColors.primaryDark]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Net Worth', style: ESUNTypography.bodyMedium.copyWith(color: Colors.white.withOpacity(0.8))),
                const SizedBox(height: 4),
                Text(netWorth.toINR(), style: ESUNTypography.amountLarge.copyWith(color: Colors.white)),
                const SizedBox(height: 8),
                Text(
                  '↑ ₹2,34,500 (+14.6%) this year',
                  style: ESUNTypography.labelMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          
          Row(
            children: [
              Expanded(
                child: _buildAssetLiabilityCard('Assets', totalAssets.toINR(), ESUNColors.success, Icons.account_balance_wallet),
              ),
              const SizedBox(width: ESUNSpacing.md),
              Expanded(
                child: _buildAssetLiabilityCard('Liabilities', totalLiabilities.toINR(), ESUNColors.error, Icons.credit_card),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.lg),
          Text('Asset Breakdown', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: ESUNSpacing.md),
          _buildAssetRow('Bank Balance', aaData.totalBankBalance.toINR(), Colors.blue),
          _buildAssetRow('Mutual Funds', (assets?.mutualFunds ?? 0).toINR(), Colors.green),
          _buildAssetRow('Stocks', (assets?.stocks ?? 0).toINR(), Colors.purple),
          _buildAssetRow('Fixed Deposits', (assets?.fixedDeposits ?? 0).toINR(), Colors.orange),
          _buildAssetRow('Gold', (assets?.gold ?? 0).toINR(), Colors.amber),
        ],
      ),
    );
  }
  
  Widget _buildAssetLiabilityCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: ESUNRadius.lgRadius,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: ESUNTypography.labelMedium.copyWith(
                  color: ESUNColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: ESUNTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAssetRow(String name, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: Text(
              name,
              style: ESUNTypography.bodyMedium,
            ),
          ),
          Text(
            value,
            style: ESUNTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryData {
  final String name;
  final double amount;
  final Color color;
  final double percentage;
  
  _CategoryData(this.name, this.amount, this.color, this.percentage);
}



