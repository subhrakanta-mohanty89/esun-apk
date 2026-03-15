/// ESUN Budgets Screen
/// 
/// Budget management and tracking.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../shared/widgets/widgets.dart';
import '../../core/utils/utils.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});
  
  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  late List<_BudgetCategory> _budgets;

  @override
  void initState() {
    super.initState();
    _budgets = [
      _BudgetCategory('Food & Dining', 15000, 12500, Icons.restaurant, Colors.orange),
      _BudgetCategory('Shopping', 10000, 8400, Icons.shopping_bag, Colors.pink),
      _BudgetCategory('Transport', 8000, 6200, Icons.directions_car, Colors.blue),
      _BudgetCategory('Entertainment', 5000, 4500, Icons.movie, Colors.purple),
      _BudgetCategory('Bills', 25000, 15800, Icons.receipt_long, Colors.green),
      _BudgetCategory('Others', 17000, 4940, Icons.more_horiz, Colors.grey),
    ];
  }

  void _addOrEditBudget({_BudgetCategory? budget, int? index}) {
    final nameCtrl = TextEditingController(text: budget?.name ?? '');
    final limitCtrl = TextEditingController(text: budget?.limit.toStringAsFixed(0) ?? '');
    final spentCtrl = TextEditingController(text: budget?.spent.toStringAsFixed(0) ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: ESUNSpacing.lg,
            right: ESUNSpacing.lg,
            top: ESUNSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + ESUNSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                budget == null ? 'Create Budget' : 'Adjust Budget',
                style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: ESUNSpacing.md),
              FPTextField(
                controller: nameCtrl,
                label: 'Category',
                hint: 'e.g., Groceries',
              ),
              const SizedBox(height: ESUNSpacing.md),
              FPTextField(
                controller: limitCtrl,
                label: 'Monthly Limit (₹)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: ESUNSpacing.md),
              FPTextField(
                controller: spentCtrl,
                label: 'Spent so far (₹)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: ESUNSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final limit = double.tryParse(limitCtrl.text) ?? 0;
                    final spent = double.tryParse(spentCtrl.text) ?? 0;
                    if (nameCtrl.text.trim().isEmpty || limit <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a name and a valid limit')),
                      );
                      return;
                    }
                    final updated = _BudgetCategory(
                      nameCtrl.text.trim(),
                      limit,
                      spent.clamp(0, limit * 2),
                      budget?.icon ?? Icons.pie_chart,
                      budget?.color ?? ESUNColors.primary,
                    );

                    setState(() {
                      if (index != null) {
                        _budgets[index] = updated;
                      } else {
                        _budgets.insert(0, updated);
                      }
                    });
                    Navigator.pop(ctx);
                  },
                  child: Text(budget == null ? 'Save Budget' : 'Update Budget'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addOrEditBudget(),
            tooltip: 'Create budget',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monthly Overview
            _buildMonthlyOverview(context),
            
            // Category Budgets
            _buildCategoryBudgets(context),
            
            // Budget Tips
            _buildBudgetTips(context),
            
            const SizedBox(height: ESUNSpacing.xxl),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMonthlyOverview(BuildContext context) {
    const totalBudget = 80000.0;
    const spent = 52340.0;
    const remaining = totalBudget - spent;
    const progress = spent / totalBudget;
    
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: FPCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'January 2024',
                  style: ESUNTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: progress < 0.75 
                        ? ESUNColors.success.withOpacity(0.1)
                        : ESUNColors.warning.withOpacity(0.1),
                    borderRadius: ESUNRadius.fullRadius,
                  ),
                  child: Text(
                    progress < 0.75 ? 'On Track' : 'Watch Out',
                    style: ESUNTypography.labelSmall.copyWith(
                      color: progress < 0.75 
                          ? ESUNColors.success 
                          : ESUNColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ESUNSpacing.lg),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 12,
                            backgroundColor: ESUNColors.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation(
                              progress < 0.75 ? ESUNColors.primary : ESUNColors.warning,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: ESUNTypography.headlineSmall.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'used',
                              style: ESUNTypography.labelSmall.copyWith(
                                color: ESUNColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildOverviewRow('Budget', totalBudget.toINR(), ESUNColors.textPrimary),
                      const SizedBox(height: 8),
                      _buildOverviewRow('Spent', spent.toINR(), ESUNColors.warning),
                      const SizedBox(height: 8),
                      _buildOverviewRow('Remaining', remaining.toINR(), ESUNColors.success),
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
  
  Widget _buildOverviewRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: ESUNTypography.bodyMedium.copyWith(
            color: ESUNColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: ESUNTypography.titleSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCategoryBudgets(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Budgets',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          ..._budgets.asMap().entries.map((entry) => _buildBudgetCard(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(int index, _BudgetCategory budget) {
    final progress = budget.spent / budget.limit;
    final isOverBudget = progress > 1.0;
    final remaining = budget.limit - budget.spent;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.sm),
      child: FPCard(
        onTap: () => _addOrEditBudget(budget: budget, index: index),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: budget.color.withOpacity(0.1),
                    borderRadius: ESUNRadius.smRadius,
                  ),
                  child: Icon(budget.icon, color: budget.color, size: 20),
                ),
                const SizedBox(width: ESUNSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.name,
                        style: ESUNTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        isOverBudget 
                            ? 'Over by ${(-remaining).toINR()}' 
                            : '${remaining.toINR()} remaining',
                        style: ESUNTypography.labelSmall.copyWith(
                          color: isOverBudget ? ESUNColors.error : ESUNColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${budget.spent.toINR()} / ${budget.limit.toINR()}',
                  style: ESUNTypography.labelMedium.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Adjust budget',
                  onPressed: () => _addOrEditBudget(budget: budget, index: index),
                ),
              ],
            ),
            const SizedBox(height: ESUNSpacing.sm),
            ClipRRect(
              borderRadius: ESUNRadius.fullRadius,
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: budget.color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(
                  isOverBudget ? ESUNColors.error : budget.color,
                ),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBudgetTips(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: FPCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                ),
                const SizedBox(width: ESUNSpacing.md),
                Text(
                  'Budget Tip',
                  style: ESUNTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ESUNSpacing.md),
            Text(
              'Your Food & Dining spending is 25% higher than last month. '
              'Consider meal prepping to save up to ₹5,000 this month!',
              style: ESUNTypography.bodyMedium.copyWith(
                color: ESUNColors.textSecondary,
              ),
            ),
            const SizedBox(height: ESUNSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Budget Tip'),
                          content: const Text(
                            'Focus on your top two overspending categories and set weekly caps to stay on track.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Got it'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Learn More'),
                  ),
                ),
                const SizedBox(width: ESUNSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_budgets.isEmpty) {
                        _addOrEditBudget();
                      } else {
                        _addOrEditBudget(budget: _budgets.first, index: 0);
                      }
                    },
                    child: const Text('Adjust Budget'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCategory {
  final String name;
  final double limit;
  final double spent;
  final IconData icon;
  final Color color;
  
  _BudgetCategory(this.name, this.limit, this.spent, this.icon, this.color);
}



