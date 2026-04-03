/// ESUN Goals Screen
/// 
/// Financial goal tracking and management.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../shared/widgets/widgets.dart';
import '../../core/utils/utils.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});
  
  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  List<_Goal> _goals = [];
  List<_Goal> _completedGoals = [];
  
  @override
  void initState() {
    super.initState();
    _goals = [
      _Goal(
        name: 'Emergency Fund',
        target: 300000,
        saved: 180000,
        deadline: DateTime(2026, 6, 30),
        icon: Icons.shield_outlined,
        color: Colors.blue,
      ),
      _Goal(
        name: 'New Car',
        target: 800000,
        saved: 240000,
        deadline: DateTime(2027, 12, 31),
        icon: Icons.directions_car,
        color: Colors.orange,
      ),
      _Goal(
        name: 'Vacation',
        target: 150000,
        saved: 90000,
        deadline: DateTime(2026, 8, 15),
        icon: Icons.flight,
        color: Colors.purple,
      ),
      _Goal(
        name: 'Home Down Payment',
        target: 2000000,
        saved: 450000,
        deadline: DateTime(2028, 1, 1),
        icon: Icons.home,
        color: Colors.green,
      ),
    ];
    _completedGoals = [
      _Goal(
        name: 'iPhone 15 Pro',
        target: 150000,
        saved: 150000,
        deadline: DateTime(2025, 12, 10),
        icon: Icons.phone_iphone,
        color: ESUNColors.success,
      ),
    ];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGoalSheet(context),
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
            
            const SizedBox(height: 72),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalSheet(context),
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
              _goals.fold<double>(0, (s, g) => s + g.saved).toINR(),
              style: ESUNTypography.amountLarge.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: ESUNSpacing.lg),
            Row(
              children: [
                _buildSummaryItem('Active', '${_goals.length}', Icons.flag),
                const SizedBox(width: ESUNSpacing.xl),
                _buildSummaryItem('Completed', '${_completedGoals.length}', Icons.check_circle),
                const SizedBox(width: ESUNSpacing.xl),
                _buildSummaryItem('On Track', '${_goals.where((g) => g.saved / g.target >= 0.3).length}', Icons.trending_up),
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
          ..._goals.asMap().entries.map((entry) => _buildGoalCard(entry.value, entry.key)),
        ],
      ),
    );
  }
  
  Widget _buildGoalCard(_Goal goal, int index) {
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
                  padding: const EdgeInsets.all(ESUNSpacing.md),
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
                    onPressed: () => _showAddMoneySheet(context, goal, index),
                    child: const Text('Add Money'),
                  ),
                ),
                const SizedBox(width: ESUNSpacing.md),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showGoalOptions(context, goal, index),
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
    if (_completedGoals.isEmpty) return const SizedBox.shrink();
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
          ..._completedGoals.map((goal) => Padding(
            padding: const EdgeInsets.only(bottom: ESUNSpacing.sm),
            child: FPCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(ESUNSpacing.md),
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
                          goal.name,
                          style: ESUNTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Completed on ${goal.deadline.day}/${goal.deadline.month}/${goal.deadline.year}',
                          style: ESUNTypography.bodySmall.copyWith(
                            color: ESUNColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    goal.target.toINR(),
                    style: ESUNTypography.titleSmall.copyWith(
                      color: ESUNColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
  
  // ---- CRUD Operations ----
  
  void _showAddGoalSheet(BuildContext context) {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    final icons = [Icons.shield_outlined, Icons.directions_car, Icons.flight, Icons.home, Icons.school, Icons.phone_iphone, Icons.favorite, Icons.savings];
    final colors = [Colors.blue, Colors.orange, Colors.purple, Colors.green, Colors.indigo, Colors.teal, Colors.pink, Colors.amber];
    int selectedIcon = 0;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: ESUNSpacing.lg, right: ESUNSpacing.lg, top: ESUNSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + ESUNSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create New Goal', style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: ESUNSpacing.lg),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Goal Name', prefixIcon: Icon(Icons.flag)),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: ESUNSpacing.md),
              TextField(
                controller: targetController,
                decoration: const InputDecoration(labelText: 'Target Amount (₹)', prefixIcon: Icon(Icons.currency_rupee)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: ESUNSpacing.md),
              const Text('Choose Icon', style: ESUNTypography.bodyMedium),
              const SizedBox(height: ESUNSpacing.sm),
              Wrap(
                spacing: 8,
                children: List.generate(icons.length, (i) => GestureDetector(
                  onTap: () => setSheetState(() => selectedIcon = i),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: selectedIcon == i ? colors[i] : colors[i].withOpacity(0.1),
                    child: Icon(icons[i], color: selectedIcon == i ? Colors.white : colors[i], size: 20),
                  ),
                )),
              ),
              const SizedBox(height: ESUNSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final target = double.tryParse(targetController.text) ?? 0;
                    if (name.isEmpty || target <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid name and target amount')),
                      );
                      return;
                    }
                    setState(() {
                      _goals.add(_Goal(
                        name: name,
                        target: target,
                        saved: 0,
                        deadline: DateTime.now().add(const Duration(days: 365)),
                        icon: icons[selectedIcon],
                        color: colors[selectedIcon],
                      ));
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Goal "$name" created!')),
                    );
                  },
                  child: const Text('Create Goal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showAddMoneySheet(BuildContext context, _Goal goal, int index) {
    final amountController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: ESUNSpacing.lg, right: ESUNSpacing.lg, top: ESUNSpacing.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + ESUNSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Money to ${goal.name}', style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Saved: ${goal.saved.toINR()} / ${goal.target.toINR()}', style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
            const SizedBox(height: ESUNSpacing.lg),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount (₹)', prefixIcon: Icon(Icons.currency_rupee)),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: ESUNSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text) ?? 0;
                  if (amount <= 0) return;
                  setState(() {
                    final newSaved = goal.saved + amount;
                    if (newSaved >= goal.target) {
                      _completedGoals.add(_Goal(name: goal.name, target: goal.target, saved: goal.target, deadline: DateTime.now(), icon: goal.icon, color: ESUNColors.success));
                      _goals.removeAt(index);
                    } else {
                      _goals[index] = _Goal(name: goal.name, target: goal.target, saved: newSaved, deadline: goal.deadline, icon: goal.icon, color: goal.color);
                    }
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('₹${amount.toStringAsFixed(0)} added to ${goal.name}')),
                  );
                },
                child: const Text('Add Money'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showGoalOptions(BuildContext context, _Goal goal, int index) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Goal'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditGoalSheet(context, goal, index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Goal', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _goals.removeAt(index));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${goal.name} deleted')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showEditGoalSheet(BuildContext context, _Goal goal, int index) {
    final nameController = TextEditingController(text: goal.name);
    final targetController = TextEditingController(text: goal.target.toStringAsFixed(0));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: ESUNSpacing.lg, right: ESUNSpacing.lg, top: ESUNSpacing.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + ESUNSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Goal', style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: ESUNSpacing.lg),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Goal Name')),
            const SizedBox(height: ESUNSpacing.md),
            TextField(controller: targetController, decoration: const InputDecoration(labelText: 'Target Amount (₹)'), keyboardType: TextInputType.number),
            const SizedBox(height: ESUNSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final target = double.tryParse(targetController.text) ?? goal.target;
                  if (name.isEmpty) return;
                  setState(() {
                    _goals[index] = _Goal(name: name, target: target, saved: goal.saved, deadline: goal.deadline, icon: goal.icon, color: goal.color);
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
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



