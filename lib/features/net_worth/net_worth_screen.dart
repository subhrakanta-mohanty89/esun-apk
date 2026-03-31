/// Net Worth Screens
/// 
/// Displays user's net worth breakdown with data from Account Aggregator.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../theme/theme.dart';
import '../../routes/app_routes.dart';
import '../../state/aa_data_state.dart';

// ============================================================================
// Net Worth Screen (Main)
// ============================================================================

class NetWorthScreen extends ConsumerStatefulWidget {
  const NetWorthScreen({super.key});

  @override
  ConsumerState<NetWorthScreen> createState() => _NetWorthScreenState();
}

class _NetWorthScreenState extends ConsumerState<NetWorthScreen> {
  bool _isAmountHidden = false;
  
  @override
  void initState() {
    super.initState();
    // Load AA data if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final aaData = ref.read(aaDataProvider);
      if (!aaData.isLoaded) {
        ref.read(aaDataProvider.notifier).loadMockData();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final aaData = ref.watch(aaDataProvider);
    final snapshot = aaData.snapshot ?? FinancialSnapshot.mock;
    final assetBreakdown = aaData.assetBreakdown ?? AssetBreakdown.mock;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Net Worth'),
        actions: [
          IconButton(
            icon: Icon(_isAmountHidden ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _isAmountHidden = !_isAmountHidden),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(aaDataProvider.notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(aaDataProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Net Worth Card
              _buildNetWorthCard(snapshot),
              
              // Asset Allocation Chart
              _buildAssetAllocationChart(assetBreakdown),
              
              // Asset Breakdown
              _buildAssetBreakdown(assetBreakdown),
              
              // Liabilities Section
              _buildLiabilitiesSection(aaData),
              
              // Monthly Trend
              _buildMonthlyTrendChart(snapshot),
              
              // Quick Actions
              _buildQuickActions(context),
              
              const SizedBox(height: 72),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNetWorthCard(FinancialSnapshot snapshot) {
    final change = snapshot.netWorth * 0.182; // 18.2% growth
    final isPositive = change >= 0;
    
    return Container(
      margin: const EdgeInsets.all(ESUNSpacing.lg),
      padding: const EdgeInsets.all(ESUNSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E4A9A), Color(0xFF1C2961)],
        ),
        borderRadius: ESUNRadius.lgRadius,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E4A9A).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(ESUNSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: ESUNRadius.smRadius,
                    ),
                    child: const Icon(Icons.pie_chart_outline, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: ESUNSpacing.md),
                  Text(
                    'Total Net Worth',
                    style: ESUNTypography.titleMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: ESUNSpacing.chipInsets,
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                  borderRadius: ESUNRadius.fullRadius,
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+18.2%',
                      style: ESUNTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.lg),
          Text(
            _isAmountHidden ? '₹••••••••' : '₹${_formatAmount(snapshot.netWorth)}',
            style: ESUNTypography.amountLarge.copyWith(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: ESUNSpacing.sm),
          Text(
            'Updated ${_formatDate(snapshot.snapshotDate)}',
            style: ESUNTypography.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: ESUNRadius.mdRadius,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Assets',
                    _isAmountHidden ? '₹••••' : '₹${_formatAmount(snapshot.totalAssets)}',
                    Icons.arrow_upward_rounded,
                    Colors.green,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Liabilities',
                    _isAmountHidden ? '₹••••' : '₹${_formatAmount(snapshot.totalLiabilities)}',
                    Icons.arrow_downward_rounded,
                    Colors.red.shade300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          // Monthly Income vs Expense
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: ESUNRadius.mdRadius,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Monthly Income', style: ESUNTypography.bodySmall.copyWith(color: Colors.white70)),
                    Text(
                      _isAmountHidden ? '₹••••' : '₹${_formatAmount(snapshot.totalMonthlyIncome)}',
                      style: ESUNTypography.bodyMedium.copyWith(color: Colors.greenAccent, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Monthly Expense', style: ESUNTypography.bodySmall.copyWith(color: Colors.white70)),
                    Text(
                      _isAmountHidden ? '₹••••' : '₹${_formatAmount(snapshot.totalMonthlyExpense)}',
                      style: ESUNTypography.bodyMedium.copyWith(color: Colors.redAccent.shade100, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Savings Rate', style: ESUNTypography.bodySmall.copyWith(color: Colors.white70)),
                    Text(
                      '${snapshot.savingsRate.toStringAsFixed(1)}%',
                      style: ESUNTypography.bodyMedium.copyWith(color: Colors.amberAccent, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: ESUNTypography.labelSmall.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: ESUNTypography.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAssetAllocationChart(AssetBreakdown breakdown) {
    final sections = [
      if (breakdown.mutualFunds > 0)
        PieChartSectionData(
          value: breakdown.mutualFunds,
          color: const Color(0xFF2E4A9A),
          title: '',
          radius: 50,
        ),
      if (breakdown.stocks > 0)
        PieChartSectionData(
          value: breakdown.stocks,
          color: const Color(0xFF3B82F6),
          title: '',
          radius: 50,
        ),
      if (breakdown.etfs > 0)
        PieChartSectionData(
          value: breakdown.etfs,
          color: const Color(0xFF10B981),
          title: '',
          radius: 50,
        ),
      if (breakdown.bankBalance > 0)
        PieChartSectionData(
          value: breakdown.bankBalance,
          color: const Color(0xFFF59E0B),
          title: '',
          radius: 50,
        ),
      if (breakdown.fixedDeposits > 0)
        PieChartSectionData(
          value: breakdown.fixedDeposits,
          color: const Color(0xFFEF4444),
          title: '',
          radius: 50,
        ),
      if (breakdown.gold > 0)
        PieChartSectionData(
          value: breakdown.gold,
          color: const Color(0xFFD97706),
          title: '',
          radius: 50,
        ),
      if (breakdown.others > 0)
        PieChartSectionData(
          value: breakdown.others,
          color: const Color(0xFF8B5CF6),
          title: '',
          radius: 50,
        ),
    ];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        color: ESUNColors.surface,
        borderRadius: ESUNRadius.lgRadius,
        border: Border.all(color: ESUNColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Portfolio Allocation',
                style: ESUNTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: ESUNSpacing.badgeInsets,
                decoration: BoxDecoration(
                  color: ESUNColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total: ₹${_formatAmount(breakdown.total)}',
                  style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.success, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.lg),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 35,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(width: ESUNSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('Mutual Funds', const Color(0xFF2E4A9A), breakdown.mutualFunds),
                    _buildLegendItem('Stocks', const Color(0xFF3B82F6), breakdown.stocks),
                    _buildLegendItem('ETFs', const Color(0xFF10B981), breakdown.etfs),
                    _buildLegendItem('Bank Balance', const Color(0xFFF59E0B), breakdown.bankBalance),
                    _buildLegendItem('Fixed Deposits', const Color(0xFFEF4444), breakdown.fixedDeposits),
                    _buildLegendItem('Gold', const Color(0xFFD97706), breakdown.gold),
                    _buildLegendItem('PPF & Others', const Color(0xFF8B5CF6), breakdown.others),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          // Top Performers row
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.md),
            decoration: BoxDecoration(
              color: ESUNColors.success.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ESUNColors.success.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Top Performers', style: ESUNTypography.labelSmall.copyWith(fontWeight: FontWeight.w600, color: ESUNColors.success)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildPerformerChip('Stocks', '+35.0%', Colors.blue),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPerformerChip('ETFs', '+13.0%', Colors.green),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPerformerChip('MF', '+12.5%', Colors.purple),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPerformerChip(String label, String change, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: ESUNTypography.labelSmall.copyWith(fontWeight: FontWeight.w600, color: color)),
          Text(change, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.success, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
  
  Widget _buildLegendItem(String label, Color color, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: ESUNTypography.bodySmall,
            ),
          ),
          Text(
            _isAmountHidden ? '₹••••' : '₹${_formatAmount(value)}',
            style: ESUNTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAssetBreakdown(AssetBreakdown breakdown) {
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Asset Breakdown',
                style: ESUNTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.netWorthDetails),
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          _buildAssetCard(
            'Mutual Funds',
            Icons.pie_chart,
            breakdown.mutualFunds,
            Colors.purple,
            '+12.5%',
          ),
          _buildAssetCard(
            'Stocks',
            Icons.candlestick_chart,
            breakdown.stocks,
            Colors.blue,
            '+35.0%',
          ),
          _buildAssetCard(
            'ETFs',
            Icons.show_chart,
            breakdown.etfs,
            Colors.green,
            '+13.04%',
          ),
          _buildAssetCard(
            'Bank Balance',
            Icons.account_balance_wallet,
            breakdown.bankBalance,
            Colors.orange,
            '',
          ),
          _buildAssetCard(
            'Fixed Deposits',
            Icons.savings,
            breakdown.fixedDeposits,
            Colors.red,
            '+7.5%',
          ),
        ],
      ),
    );
  }
  
  Widget _buildAssetCard(String name, IconData icon, double value, Color color, String change) {
    return Container(
      margin: const EdgeInsets.only(bottom: ESUNSpacing.sm),
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: ESUNColors.surface,
        borderRadius: ESUNRadius.mdRadius,
        border: Border.all(color: ESUNColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: ESUNRadius.smRadius,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: ESUNTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (change.isNotEmpty)
                  Text(
                    change,
                    style: ESUNTypography.bodySmall.copyWith(
                      color: change.startsWith('+') ? ESUNColors.success : ESUNColors.error,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            _isAmountHidden ? '₹••••' : '₹${_formatAmount(value)}',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLiabilitiesSection(AADataState aaData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Liabilities',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          if (aaData.loans.isEmpty)
            Container(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              decoration: BoxDecoration(
                color: ESUNColors.surface,
                borderRadius: ESUNRadius.mdRadius,
                border: Border.all(color: ESUNColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: ESUNColors.success,
                    size: 24,
                  ),
                  const SizedBox(width: ESUNSpacing.md),
                  Text(
                    'No active loans',
                    style: ESUNTypography.bodyMedium.copyWith(
                      color: ESUNColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ...aaData.loans.map((loan) => _buildLoanCard(loan)),
        ],
      ),
    );
  }
  
  Widget _buildLoanCard(LoanData loan) {
    final progress = 1 - (loan.outstandingAmount / loan.principalAmount);
    
    return Container(
      margin: const EdgeInsets.only(bottom: ESUNSpacing.sm),
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: ESUNColors.surface,
        borderRadius: ESUNRadius.mdRadius,
        border: Border.all(color: ESUNColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: ESUNRadius.smRadius,
                ),
                child: Icon(
                  _getLoanIcon(loan.loanType),
                  color: Colors.red.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: ESUNSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${loan.loanType} Loan',
                      style: ESUNTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      loan.lenderName,
                      style: ESUNTypography.bodySmall.copyWith(
                        color: ESUNColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _isAmountHidden ? '₹••••' : '₹${_formatAmount(loan.outstandingAmount)}',
                    style: ESUNTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  Text(
                    'Outstanding',
                    style: ESUNTypography.labelSmall.copyWith(
                      color: ESUNColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: ESUNColors.border,
                  color: ESUNColors.primary,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: ESUNSpacing.md),
              Text(
                '${(progress * 100).toStringAsFixed(0)}% paid',
                style: ESUNTypography.labelSmall.copyWith(
                  color: ESUNColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  IconData _getLoanIcon(String loanType) {
    switch (loanType.toUpperCase()) {
      case 'HOME':
        return Icons.home;
      case 'VEHICLE':
        return Icons.directions_car;
      case 'EDUCATION':
        return Icons.school;
      case 'PERSONAL':
      default:
        return Icons.account_balance;
    }
  }
  
  Widget _buildMonthlyTrendChart(FinancialSnapshot snapshot) {
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        decoration: BoxDecoration(
          color: ESUNColors.surface,
          borderRadius: ESUNRadius.lgRadius,
          border: Border.all(color: ESUNColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Net Worth Trend',
              style: ESUNTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: ESUNSpacing.lg),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 500000,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: ESUNColors.border,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '₹${(value / 100000).toStringAsFixed(0)}L',
                            style: ESUNTypography.labelSmall.copyWith(
                              color: ESUNColors.textTertiary,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                          if (value.toInt() >= 0 && value.toInt() < months.length) {
                            return Text(
                              months[value.toInt()],
                              style: ESUNTypography.labelSmall.copyWith(
                                color: ESUNColors.textTertiary,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 1200000),
                        const FlSpot(1, 1300000),
                        const FlSpot(2, 1280000),
                        const FlSpot(3, 1400000),
                        const FlSpot(4, 1480000),
                        const FlSpot(5, 1562825),
                      ],
                      isCurved: true,
                      color: const Color(0xFF2E4A9A),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF2E4A9A).withOpacity(0.3),
                            const Color(0xFF2E4A9A).withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                  minY: 1000000,
                  maxY: 1800000,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Add Account',
                  Icons.add_circle_outline,
                  Colors.blue,
                  () => context.push(AppRoutes.aaVerifyPan),
                ),
              ),
              const SizedBox(width: ESUNSpacing.md),
              Expanded(
                child: _buildActionCard(
                  'Manage Consents',
                  Icons.security,
                  Colors.purple,
                  () => context.push(AppRoutes.aaMyConsents),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: ESUNRadius.mdRadius,
      child: Container(
        padding: const EdgeInsets.all(ESUNSpacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: ESUNRadius.mdRadius,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: ESUNSpacing.sm),
            Text(
              label,
              style: ESUNTypography.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)} K';
    }
    return amount.toStringAsFixed(0);
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    }
  }
}

// ============================================================================
// Net Worth Details Screen
// ============================================================================

class NetWorthDetailsScreen extends ConsumerWidget {
  const NetWorthDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aaData = ref.watch(aaDataProvider);
    final assetBreakdown = aaData.assetBreakdown ?? AssetBreakdown.mock;
    
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Asset Details'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Investments'),
              Tab(text: 'Bank Accounts'),
              Tab(text: 'Fixed Deposits'),
              Tab(text: 'Other'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Investments Tab
            _buildInvestmentsTab(aaData, context),
            
            // Bank Accounts Tab
            _buildBankAccountsTab(aaData, context),
            
            // Fixed Deposits Tab
            _buildFixedDepositsTab(aaData, context),
            
            // Other Assets Tab
            _buildOtherAssetsTab(assetBreakdown, context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInvestmentsTab(AADataState aaData, BuildContext context) {
    final investments = aaData.investments;
    
    if (investments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.trending_up,
              size: 64,
              color: ESUNColors.textTertiary,
            ),
            const SizedBox(height: ESUNSpacing.md),
            Text(
              'No investments found',
              style: ESUNTypography.bodyLarge.copyWith(
                color: ESUNColors.textSecondary,
              ),
            ),
            const SizedBox(height: ESUNSpacing.md),
            OutlinedButton(
              onPressed: () => context.push(AppRoutes.invest),
              child: const Text('Start Investing'),
            ),
          ],
        ),
      );
    }
    
    // Group by type
    final stocks = investments.where((i) => i.type.toUpperCase() == 'STOCK').toList();
    final mutualFunds = investments.where((i) => i.type.toUpperCase() == 'MUTUAL_FUND').toList();
    final etfs = investments.where((i) => i.type.toUpperCase() == 'ETF').toList();
    
    return ListView(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      children: [
        if (stocks.isNotEmpty) ...[
          _buildSectionHeader('Stocks', stocks.length),
          ...stocks.map((inv) => _buildInvestmentCard(inv)),
          const SizedBox(height: ESUNSpacing.lg),
        ],
        if (mutualFunds.isNotEmpty) ...[
          _buildSectionHeader('Mutual Funds', mutualFunds.length),
          ...mutualFunds.map((inv) => _buildInvestmentCard(inv)),
          const SizedBox(height: ESUNSpacing.lg),
        ],
        if (etfs.isNotEmpty) ...[
          _buildSectionHeader('ETFs', etfs.length),
          ...etfs.map((inv) => _buildInvestmentCard(inv)),
        ],
      ],
    );
  }
  
  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.md),
      child: Row(
        children: [
          Text(
            title,
            style: ESUNTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: ESUNSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: ESUNColors.primary.withOpacity(0.1),
              borderRadius: ESUNRadius.fullRadius,
            ),
            child: Text(
              '$count',
              style: ESUNTypography.labelSmall.copyWith(
                color: ESUNColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInvestmentCard(InvestmentHolding inv) {
    final isPositive = inv.returns >= 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: ESUNSpacing.sm),
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: ESUNColors.surface,
        borderRadius: ESUNRadius.mdRadius,
        border: Border.all(color: ESUNColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ESUNColors.primary.withOpacity(0.1),
                  borderRadius: ESUNRadius.smRadius,
                ),
                child: Center(
                  child: Text(
                    inv.symbol?.substring(0, 1).toUpperCase() ?? inv.name.substring(0, 1),
                    style: ESUNTypography.titleMedium.copyWith(
                      color: ESUNColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: ESUNSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.name,
                      style: ESUNTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${inv.quantity.toStringAsFixed(2)} units @ ₹${inv.avgBuyPrice.toStringAsFixed(2)}',
                      style: ESUNTypography.bodySmall.copyWith(
                        color: ESUNColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${_formatAmount(inv.currentValue)}',
                    style: ESUNTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: isPositive ? ESUNColors.success : ESUNColors.error,
                        size: 16,
                      ),
                      Text(
                        '${inv.returnsPercentage.toStringAsFixed(1)}%',
                        style: ESUNTypography.labelSmall.copyWith(
                          color: isPositive ? ESUNColors.success : ESUNColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (inv.provider != null) ...[
            const SizedBox(height: ESUNSpacing.sm),
            Row(
              children: [
                Icon(Icons.account_balance, size: 12, color: ESUNColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  inv.provider!,
                  style: ESUNTypography.labelSmall.copyWith(
                    color: ESUNColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildBankAccountsTab(AADataState aaData, BuildContext context) {
    final accounts = aaData.bankAccounts;
    
    if (accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance,
              size: 64,
              color: ESUNColors.textTertiary,
            ),
            const SizedBox(height: ESUNSpacing.md),
            Text(
              'No bank accounts linked',
              style: ESUNTypography.bodyLarge.copyWith(
                color: ESUNColors.textSecondary,
              ),
            ),
            const SizedBox(height: ESUNSpacing.md),
            OutlinedButton(
              onPressed: () => context.push(AppRoutes.aaVerifyPan),
              child: const Text('Link Bank Account'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        return _buildBankAccountCard(account);
      },
    );
  }
  
  Widget _buildBankAccountCard(BankAccountData account) {
    return Container(
      margin: const EdgeInsets.only(bottom: ESUNSpacing.sm),
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: ESUNColors.surface,
        borderRadius: ESUNRadius.mdRadius,
        border: Border.all(color: ESUNColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getBankColor(account.bankName).withOpacity(0.1),
              borderRadius: ESUNRadius.smRadius,
            ),
            child: Icon(
              Icons.account_balance,
              color: _getBankColor(account.bankName),
              size: 24,
            ),
          ),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.bankName,
                  style: ESUNTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${account.accountType} • ${account.accountNumber}',
                  style: ESUNTypography.bodySmall.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${_formatAmount(account.balance)}',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFixedDepositsTab(AADataState aaData, BuildContext context) {
    final fds = aaData.fixedDeposits;
    
    if (fds.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.savings,
              size: 64,
              color: ESUNColors.textTertiary,
            ),
            const SizedBox(height: ESUNSpacing.md),
            Text(
              'No fixed deposits found',
              style: ESUNTypography.bodyLarge.copyWith(
                color: ESUNColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      itemCount: fds.length,
      itemBuilder: (context, index) {
        final fd = fds[index];
        return _buildFDCard(fd);
      },
    );
  }
  
  Widget _buildFDCard(FixedDepositData fd) {
    return Container(
      margin: const EdgeInsets.only(bottom: ESUNSpacing.sm),
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: ESUNColors.surface,
        borderRadius: ESUNRadius.mdRadius,
        border: Border.all(color: ESUNColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: ESUNRadius.smRadius,
                ),
                child: const Icon(Icons.savings, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: ESUNSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fd.bankName,
                      style: ESUNTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'FD ${fd.accountNumber}',
                      style: ESUNTypography.bodySmall.copyWith(
                        color: ESUNColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${_formatAmount(fd.principal)}',
                    style: ESUNTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${fd.interestRate}% p.a.',
                    style: ESUNTypography.labelSmall.copyWith(
                      color: ESUNColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          Row(
            children: [
              _buildFDInfo('Maturity', '₹${_formatAmount(fd.maturityAmount)}'),
              const SizedBox(width: ESUNSpacing.xl),
              _buildFDInfo('Matures on', _formatDate(fd.maturityDate)),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFDInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ESUNTypography.labelSmall.copyWith(
            color: ESUNColors.textTertiary,
          ),
        ),
        Text(
          value,
          style: ESUNTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildOtherAssetsTab(AssetBreakdown breakdown, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      children: [
        if (breakdown.realEstate > 0)
          _buildOtherAssetCard('Real Estate', Icons.home, breakdown.realEstate, Colors.brown),
        if (breakdown.gold > 0)
          _buildOtherAssetCard('Gold', Icons.workspace_premium, breakdown.gold, Colors.amber),
        if (breakdown.others > 0)
          _buildOtherAssetCard('Other Assets', Icons.category, breakdown.others, Colors.grey),
        if (breakdown.realEstate == 0 && breakdown.gold == 0 && breakdown.others == 0)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(ESUNSpacing.xxl),
              child: Column(
                children: [
                  Icon(
                    Icons.category,
                    size: 64,
                    color: ESUNColors.textTertiary,
                  ),
                  const SizedBox(height: ESUNSpacing.md),
                  Text(
                    'No other assets recorded',
                    style: ESUNTypography.bodyLarge.copyWith(
                      color: ESUNColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildOtherAssetCard(String name, IconData icon, double value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: ESUNSpacing.sm),
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: ESUNColors.surface,
        borderRadius: ESUNRadius.mdRadius,
        border: Border.all(color: ESUNColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: ESUNRadius.smRadius,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: Text(
              name,
              style: ESUNTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '₹${_formatAmount(value)}',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getBankColor(String bankName) {
    final colors = {
      'HDFC Bank': const Color(0xFF004C8F),
      'ICICI Bank': const Color(0xFFB02A30),
      'SBI': const Color(0xFF22409A),
      'State Bank of India': const Color(0xFF22409A),
      'Axis Bank': const Color(0xFF97144D),
      'Kotak Mahindra Bank': const Color(0xFFED1C24),
    };
    return colors[bankName] ?? ESUNColors.primary;
  }
  
  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)} K';
    }
    return amount.toStringAsFixed(0);
  }
  
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
