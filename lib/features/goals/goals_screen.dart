/// ESUN Goals Screen
/// 
/// Financial goal tracking and management.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../shared/widgets/widgets.dart';
import '../../core/utils/utils.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Add new goal
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Goals Summary
            _buildGoalsSummary(context),
            
            // Active Goals
            _buildActiveGoals(context),
            
            // Suggested Goals
            _buildSuggestedGoals(context),
            
            // Completed Goals
            _buildCompletedGoals(context),
            
            const SizedBox(height: ESUNSpacing.xxl),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
    );
  }
  
  Widget _buildGoalsSummary(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: FPGradientCard(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A62B8), Color(0xFF2E4A9A)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Savings towards Goals',
              style: ESUNTypography.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: ESUNSpacing.sm),
            Text(
              510000.toINR(),
              style: ESUNTypography.amountLarge.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: ESUNSpacing.lg),
            Row(
              children: [
                _buildSummaryItem('Active', '4', Icons.flag),
                const SizedBox(width: ESUNSpacing.xl),
                _buildSummaryItem('Completed', '2', Icons.check_circle),
                const SizedBox(width: ESUNSpacing.xl),
                _buildSummaryItem('On Track', '3', Icons.trending_up),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: ESUNTypography.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: ESUNTypography.labelSmall.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
  
  Widget _buildActiveGoals(BuildContext context) {
    final goals = [
      _Goal(
        name: 'Emergency Fund',
        target: 300000,
        saved: 180000,
        deadline: DateTime(2024, 6, 30),
        icon: Icons.shield_outlined,
        color: Colors.blue,
      ),
      _Goal(
        name: 'New Car',
        target: 800000,
        saved: 240000,
        deadline: DateTime(2025, 12, 31),
        icon: Icons.directions_car,
        color: Colors.orange,
      ),
      _Goal(
        name: 'Vacation',
        target: 150000,
        saved: 90000,
        deadline: DateTime(2024, 4, 15),
        icon: Icons.flight,
        color: Colors.purple,
      ),
      _Goal(
        name: 'Home Down Payment',
        target: 2000000,
        saved: 450000,
        deadline: DateTime(2027, 1, 1),
        icon: Icons.home,
        color: Colors.green,
      ),
    ];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Goals',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          ...goals.map((goal) => _buildGoalCard(goal)),
        ],
      ),
    );
  }
  
  Widget _buildGoalCard(_Goal goal) {
    final progress = goal.saved / goal.target;
    final daysLeft = goal.deadline.difference(DateTime.now()).inDays;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.md),
      child: FPCard(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: goal.color.withOpacity(0.1),
                    borderRadius: ESUNRadius.mdRadius,
                  ),
                  child: Icon(goal.icon, color: goal.color, size: 24),
                ),
                const SizedBox(width: ESUNSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: ESUNTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$daysLeft days left',
                        style: ESUNTypography.labelSmall.copyWith(
                          color: daysLeft < 30 
                              ? ESUNColors.warning 
                              : ESUNColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: ESUNTypography.titleMedium.copyWith(
                        color: goal.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: ESUNSpacing.md),
            ClipRRect(
              borderRadius: ESUNRadius.fullRadius,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: goal.color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(goal.color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: ESUNSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${goal.saved.toINR()} saved',
                  style: ESUNTypography.bodySmall.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
                Text(
                  'Target: ${goal.target.toINR()}',
                  style: ESUNTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ESUNSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Add Money'),
                  ),
                ),
                const SizedBox(width: ESUNSpacing.md),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSuggestedGoals(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggested Goals',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildSuggestedCard(
                  'Retirement Fund',
                  'Start early, retire wealthy',
                  Icons.elderly,
                  Colors.teal,
                ),
                _buildSuggestedCard(
                  'Child Education',
                  'Secure their future',
                  Icons.school,
                  Colors.indigo,
                ),
                _buildSuggestedCard(
                  'Wedding Fund',
                  'Dream celebration',
                  Icons.favorite,
                  Colors.pink,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuggestedCard(
    String title, 
    String subtitle, 
    IconData icon, 
    Color color,
  ) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: ESUNSpacing.md),
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: ESUNRadius.lgRadius,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(
            title,
            style: ESUNTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: ESUNTypography.labelSmall.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompletedGoals(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completed',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          FPCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ESUNColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: ESUNColors.success,
                  ),
                ),
                const SizedBox(width: ESUNSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'iPhone 15 Pro',
                        style: ESUNTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Completed on Dec 10, 2024',
                        style: ESUNTypography.bodySmall.copyWith(
                          color: ESUNColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹1,50,000',
                  style: ESUNTypography.titleSmall.copyWith(
                    color: ESUNColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Goal {
  final String name;
  final double target;
  final double saved;
  final DateTime deadline;
  final IconData icon;
  final Color color;
  
  _Goal({
    required this.name,
    required this.target,
    required this.saved,
    required this.deadline,
    required this.icon,
    required this.color,
  });
}



