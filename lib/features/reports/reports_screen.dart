/// ESUN Reports Screen
/// 
/// Financial reports and analytics.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../shared/widgets/widgets.dart';
import '../../core/utils/utils.dart';

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
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {},
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
            _buildOverviewTab(),
            _buildIncomeTab(),
            _buildExpensesTab(),
            _buildNetWorthTab(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selector
          _buildPeriodSelector(),
          const SizedBox(height: ESUNSpacing.lg),
          
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Income',
                  '₹1,20,000',
                  '+8.5%',
                  Icons.arrow_upward,
                  ESUNColors.success,
                ),
              ),
              const SizedBox(width: ESUNSpacing.md),
              Expanded(
                child: _buildSummaryCard(
                  'Expenses',
                  '₹52,340',
                  '-12.3%',
                  Icons.arrow_downward,
                  ESUNColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Savings',
                  '₹67,660',
                  '+15.2%',
                  Icons.savings,
                  ESUNColors.primary,
                ),
              ),
              const SizedBox(width: ESUNSpacing.md),
              Expanded(
                child: _buildSummaryCard(
                  'Investments',
                  '₹35,000',
                  '+5.0%',
                  Icons.trending_up,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.xl),
          
          // Cash Flow Chart Placeholder
          Text(
            'Cash Flow',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: ESUNColors.surfaceVariant,
              borderRadius: ESUNRadius.lgRadius,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 48,
                    color: ESUNColors.textTertiary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cash Flow Chart',
                    style: ESUNTypography.bodyMedium.copyWith(
                      color: ESUNColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: ESUNSpacing.xl),
          
          // Spending by Category
          Text(
            'Spending by Category',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          _buildCategoryBreakdown(),
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
  
  Widget _buildCategoryBreakdown() {
    final categories = [
      _CategoryData('Food & Dining', 12500, Colors.orange, 0.24),
      _CategoryData('Shopping', 8400, Colors.pink, 0.16),
      _CategoryData('Transport', 6200, Colors.blue, 0.12),
      _CategoryData('Entertainment', 4500, Colors.purple, 0.09),
      _CategoryData('Bills', 15800, Colors.green, 0.30),
      _CategoryData('Others', 4940, Colors.grey, 0.09),
    ];
    
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
  
  Widget _buildIncomeTab() {
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
                Text(
                  'Total Income',
                  style: ESUNTypography.bodyMedium.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹1,20,000',
                  style: ESUNTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ESUNColors.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          
          Text(
            'Income Sources',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          
          _buildIncomeSource('Salary', '₹75,000', Icons.work, Colors.blue),
          _buildIncomeSource('Freelance', '₹25,000', Icons.laptop, Colors.purple),
          _buildIncomeSource('Investments', '₹15,000', Icons.trending_up, Colors.green),
          _buildIncomeSource('Other', '₹5,000', Icons.more_horiz, Colors.grey),
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
              padding: const EdgeInsets.all(10),
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
  
  Widget _buildExpensesTab() {
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
                Text(
                  'Total Expenses',
                  style: ESUNTypography.bodyMedium.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹52,340',
                  style: ESUNTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ESUNColors.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '↓ 12.3% vs last month',
                  style: ESUNTypography.labelMedium.copyWith(
                    color: ESUNColors.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          
          Text(
            'Expense Trends',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: ESUNColors.surfaceVariant,
              borderRadius: ESUNRadius.lgRadius,
            ),
            child: const Center(
              child: Text('Expense Trend Chart'),
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          
          Text(
            'Top Expenses',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          
          _buildExpenseItem('Bills & Utilities', '₹15,800', Icons.receipt_long, Colors.green),
          _buildExpenseItem('Food & Dining', '₹12,500', Icons.restaurant, Colors.orange),
          _buildExpenseItem('Shopping', '₹8,400', Icons.shopping_bag, Colors.pink),
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
              padding: const EdgeInsets.all(10),
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
  
  Widget _buildNetWorthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FPGradientCard(
            gradient: const LinearGradient(
              colors: [ESUNColors.primary, ESUNColors.primaryDark],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Net Worth',
                  style: ESUNTypography.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹18,45,230',
                  style: ESUNTypography.amountLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
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
                child: _buildAssetLiabilityCard(
                  'Assets',
                  '₹23,45,230',
                  ESUNColors.success,
                  Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: ESUNSpacing.md),
              Expanded(
                child: _buildAssetLiabilityCard(
                  'Liabilities',
                  '₹5,00,000',
                  ESUNColors.error,
                  Icons.credit_card,
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.lg),
          
          Text(
            'Asset Breakdown',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          
          _buildAssetRow('Bank Balance', '₹5,42,350', Colors.blue),
          _buildAssetRow('Investments', '₹8,45,230', Colors.green),
          _buildAssetRow('Fixed Deposits', '₹3,00,000', Colors.orange),
          _buildAssetRow('Gold', '₹2,50,000', Colors.amber),
          _buildAssetRow('Other Assets', '₹4,07,650', Colors.grey),
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



