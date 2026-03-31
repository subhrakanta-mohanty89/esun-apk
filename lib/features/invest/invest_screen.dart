/// ESUN Wealth Manager Screen
/// 
/// Wealth management hub for stocks, mutual funds, FDs, and more.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../theme/theme.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/widgets.dart';
import '../../core/utils/utils.dart';
import '../../state/aa_data_state.dart';

class InvestScreen extends ConsumerWidget {
  const InvestScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? ESUNColors.darkBackground : ESUNColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? ESUNColors.darkSurface : ESUNColors.surface,
        elevation: 0,
        title: const Text('Wealth Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.pie_chart_outline),
            onPressed: () => context.push(AppRoutes.portfolio),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portfolio & Net Worth Slider
            _buildPortfolioSlider(context),
            
            // Net Worth Breakdown - Priority section
            _NetWorthBreakdownSection(),
            
            // Credit & Health Scores
            _buildScoresCard(context, ref),
            
            // Investment Categories
            _buildCategories(context),
            
            // Wealth Allocation Pie Chart
            _buildWealthAllocationChart(context),
            
            // Portfolio Performance Bar Chart
            _buildPerformanceBarChart(context),
            
            // Demat & Broker Integration
            _buildDematIntegration(context),
            
            // Live Stocks Data
            _buildLiveStocksSection(context),
            
            // IPO Data
            _buildIPOSection(context),
            
            // Holdings
            _buildHoldings(context, ref),
            
            // SIP Overview
            _buildSIPOverview(context),
            
            // Market Overview
            _buildMarketOverview(context),
            
            // Top Picks
            _buildTopPicks(context),
            
            // Explore Funds
            _buildExploreFunds(context),
            
            const SizedBox(height: 72),
          ],
        ),
      ),
    );
  }
  
  // Portfolio & Net Worth Slider with PageView
  Widget _buildPortfolioSlider(BuildContext context) {
    return SizedBox(
      height: 220,
      child: _PortfolioSliderWidget(),
    );
  }
  
  // ignore: unused_element
  Widget _buildPortfolioSummary(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: FPGradientCard(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF059669), Color(0xFF047857)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Portfolio',
                  style: ESUNTypography.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
                Container(
                  padding: ESUNSpacing.badgeInsets,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: ESUNRadius.fullRadius,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '+12.5%',
                        style: ESUNTypography.labelSmall.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: ESUNSpacing.sm),
            Text(
              '₹8,45,230',
              style: ESUNTypography.amountLarge.copyWith(color: Colors.white),
            ),
            const SizedBox(height: ESUNSpacing.xs),
            Text(
              'Invested: ₹7,50,000 • Returns: ₹95,230',
              style: ESUNTypography.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: ESUNSpacing.lg),
            Row(
              children: [
                _buildPortfolioStat('Day P&L', '+₹2,340', '+0.28%', true),
                const SizedBox(width: ESUNSpacing.lg),
                _buildPortfolioStat('Total P&L', '+₹95,230', '+12.7%', true),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPortfolioStat(String label, String value, String percent, bool isPositive) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(ESUNSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: ESUNRadius.smRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: ESUNTypography.labelSmall.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  value,
                  style: ESUNTypography.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  percent,
                  style: ESUNTypography.labelSmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategories(BuildContext context) {
    final categories = [
      _InvestCategory(Icons.candlestick_chart, 'Stocks', '₹3.2L', Colors.blue),
      _InvestCategory(Icons.pie_chart, 'Mutual Funds', '₹4.1L', Colors.purple),
      _InvestCategory(Icons.account_balance, 'FDs', '₹1.0L', Colors.orange),
      _InvestCategory(Icons.workspace_premium, 'Gold', '₹15K', Colors.amber),
    ];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: Row(
        children: categories.map((cat) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildCategoryChip(cat),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildCategoryChip(_InvestCategory category) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.sm),
      decoration: BoxDecoration(
        color: category.color.withOpacity(0.1),
        borderRadius: ESUNRadius.mdRadius,
      ),
      child: Column(
        children: [
          Icon(category.icon, color: category.color, size: 24),
          const SizedBox(height: 4),
          Text(
            category.label,
            style: ESUNTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            category.value,
            style: ESUNTypography.labelSmall.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Wealth Allocation Pie Chart
  Widget _buildWealthAllocationChart(BuildContext context) {
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
                  'Wealth Allocation',
                  style: ESUNTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: ESUNSpacing.badgeInsets,
                  decoration: BoxDecoration(
                    color: ESUNColors.success.withOpacity(0.1),
                    borderRadius: ESUNRadius.fullRadius,
                  ),
                  child: Text(
                    'Live',
                    style: ESUNTypography.labelSmall.copyWith(
                      color: ESUNColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ESUNSpacing.lg),
            Row(
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 35,
                      sections: [
                        PieChartSectionData(
                          value: 38,
                          title: '38%',
                          color: Colors.blue,
                          radius: 40,
                          titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        PieChartSectionData(
                          value: 30,
                          title: '30%',
                          color: Colors.purple,
                          radius: 40,
                          titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        PieChartSectionData(
                          value: 18,
                          title: '18%',
                          color: Colors.orange,
                          radius: 40,
                          titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        PieChartSectionData(
                          value: 10,
                          title: '10%',
                          color: Colors.amber,
                          radius: 40,
                          titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        PieChartSectionData(
                          value: 4,
                          title: '4%',
                          color: Colors.teal,
                          radius: 40,
                          titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: ESUNSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAllocationLegend('Stocks', '₹3,21,280', Colors.blue),
                      _buildAllocationLegend('Mutual Funds', '₹2,53,570', Colors.purple),
                      _buildAllocationLegend('FDs', '₹1,52,140', Colors.orange),
                      _buildAllocationLegend('Gold', '₹84,520', Colors.amber),
                      _buildAllocationLegend('Crypto', '₹33,720', Colors.teal),
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

  Widget _buildAllocationLegend(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
            value,
            style: ESUNTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Portfolio Performance Bar Chart
  Widget _buildPerformanceBarChart(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: FPCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Performance',
                  style: ESUNTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: ESUNSpacing.badgeInsets,
                  decoration: BoxDecoration(
                    color: ESUNColors.primary.withOpacity(0.1),
                    borderRadius: ESUNRadius.fullRadius,
                  ),
                  child: Text(
                    'Last 6 Months',
                    style: ESUNTypography.labelSmall.copyWith(
                      color: ESUNColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ESUNSpacing.lg),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 15,
                  minY: -5,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = ['Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb'];
                          return Text(
                            months[value.toInt()],
                            style: ESUNTypography.labelSmall,
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: ESUNTypography.labelSmall,
                          );
                        },
                        reservedSize: 35,
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: ESUNColors.border,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _makeBarGroup(0, 5.2),
                    _makeBarGroup(1, 8.4),
                    _makeBarGroup(2, -2.1),
                    _makeBarGroup(3, 12.3),
                    _makeBarGroup(4, 6.8),
                    _makeBarGroup(5, 9.5),
                  ],
                ),
              ),
            ),
            const SizedBox(height: ESUNSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.trending_up, color: ESUNColors.success, size: 18),
                const SizedBox(width: 4),
                Text(
                  'Average Monthly Return: +6.68%',
                  style: ESUNTypography.bodySmall.copyWith(
                    color: ESUNColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: y >= 0 ? ESUNColors.success : ESUNColors.error,
          width: 22,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }

  // Live Stocks Section
  Widget _buildLiveStocksSection(BuildContext context) {
    final stocks = [
      _StockData('RELIANCE', 'Reliance Industries', 2876.50, 32.40, 1.14, true),
      _StockData('TCS', 'Tata Consultancy', 3945.75, -28.15, -0.71, false),
      _StockData('HDFCBANK', 'HDFC Bank', 1687.20, 15.80, 0.95, true),
      _StockData('INFY', 'Infosys Ltd', 1562.30, 22.45, 1.46, true),
      _StockData('ICICIBANK', 'ICICI Bank', 1045.60, -8.25, -0.78, false),
      _StockData('BHARTIARTL', 'Bharti Airtel', 1234.85, 18.90, 1.55, true),
    ];

    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Live Stocks',
                    style: ESUNTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: ESUNSpacing.tagInsets,
                    decoration: BoxDecoration(
                      color: ESUNColors.success,
                      borderRadius: ESUNRadius.fullRadius,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: ESUNTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.sm),
          ...stocks.map((stock) => _buildStockTile(stock)),
        ],
      ),
    );
  }

  Widget _buildStockTile(_StockData stock) {
    final logoUrl = stock.effectiveLogoUrl;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
              color: Colors.white,
              borderRadius: ESUNRadius.smRadius,
              border: Border.all(color: ESUNColors.border),
            ),
            child: ClipRRect(
              borderRadius: ESUNRadius.smRadius,
              child: logoUrl != null
                  ? Padding(
                      padding: const EdgeInsets.all(ESUNSpacing.sm),
                      child: Image.network(
                        logoUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            stock.symbol.substring(0, 2),
                            style: ESUNTypography.titleSmall.copyWith(
                              color: stock.isUp ? ESUNColors.success : ESUNColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        stock.symbol.substring(0, 2),
                        style: ESUNTypography.titleSmall.copyWith(
                          color: stock.isUp ? ESUNColors.success : ESUNColors.error,
                          fontWeight: FontWeight.bold,
                        ),
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
                  stock.symbol,
                  style: ESUNTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  stock.name,
                  style: ESUNTypography.labelSmall.copyWith(
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
                '₹${stock.price.toStringAsFixed(2)}',
                style: ESUNTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Icon(
                    stock.isUp ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 12,
                    color: stock.isUp ? ESUNColors.success : ESUNColors.error,
                  ),
                  Text(
                    '${stock.change > 0 ? '+' : ''}${stock.change.toStringAsFixed(2)} (${stock.changePercent.toStringAsFixed(2)}%)',
                    style: ESUNTypography.labelSmall.copyWith(
                      color: stock.isUp ? ESUNColors.success : ESUNColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // IPO Section
  Widget _buildIPOSection(BuildContext context) {
    final ipos = [
      _IPOData('Swiggy Ltd', 'Food Delivery', '₹371-391', 'Mar 6-8', 'Open', ESUNColors.success),
      _IPOData('Ola Electric', 'EV Manufacturing', '₹72-76', 'Mar 10-12', 'Upcoming', Colors.orange),
      _IPOData('FirstCry', 'E-commerce', '₹440-465', 'Mar 15-18', 'Upcoming', Colors.orange),
      _IPOData('Boat', 'Electronics', '₹285-300', 'Feb 28', 'Closed', ESUNColors.error),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'IPO Watch',
                style: ESUNTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.sm),
          SizedBox(
            height: 195,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: ipos.length,
              itemBuilder: (context, index) {
                final ipo = ipos[index];
                return _buildIPOCard(ipo);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIPOCard(_IPOData ipo) {
    final logoUrl = ipo.effectiveLogoUrl;
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: ESUNSpacing.md),
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: ESUNColors.surface,
        borderRadius: ESUNRadius.lgRadius,
        border: Border.all(color: ESUNColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: ESUNColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: logoUrl != null
                      ? Padding(
                          padding: const EdgeInsets.all(ESUNSpacing.xs),
                          child: Image.network(
                            logoUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(
                                Icons.business_rounded,
                                size: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.business_rounded,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
              Expanded(
                child: Text(
                  ipo.company,
                  style: ESUNTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            ipo.sector,
            style: ESUNTypography.labelSmall.copyWith(
              color: ESUNColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            padding: ESUNSpacing.tagInsets,
            decoration: BoxDecoration(
              color: ipo.statusColor.withOpacity(0.1),
              borderRadius: ESUNRadius.fullRadius,
            ),
            child: Text(
              ipo.status,
              style: ESUNTypography.labelSmall.copyWith(
                color: ipo.statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Price Band',
                    style: ESUNTypography.labelSmall.copyWith(
                      color: ESUNColors.textSecondary,
                    ),
                  ),
                  Text(
                    ipo.priceRange,
                    style: ESUNTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Dates',
                    style: ESUNTypography.labelSmall.copyWith(
                      color: ESUNColors.textSecondary,
                    ),
                  ),
                  Text(
                    ipo.dates,
                    style: ESUNTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: ipo.status == 'Open' ? () {} : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(ipo.status == 'Open' ? 'Apply Now' : ipo.status),
            ),
          ),
        ],
      ),
    );
  }

  // Demat & Broker Integration
  Widget _buildDematIntegration(BuildContext context) {
    final brokers = [
      _BrokerData('Zerodha', 'assets/icons/zerodha.png', 'Connected', true, '₹3,21,456'),
      _BrokerData('Groww', 'assets/icons/groww.png', 'Connect', false, null),
      _BrokerData('Upstox', 'assets/icons/upstox.png', 'Connect', false, null),
      _BrokerData('Angel One', 'assets/icons/angel.png', 'Connect', false, null),
      _BrokerData('5Paisa', 'assets/icons/5paisa.png', 'Connect', false, null),
    ];

    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Demat Accounts',
                style: ESUNTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddBrokerSheet(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.sm),
          ...brokers.map((broker) => _buildBrokerTile(context, broker)),
        ],
      ),
    );
  }

  Widget _buildBrokerTile(BuildContext context, _BrokerData broker) {
    final logoUrl = broker.effectiveLogoUrl;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: ESUNColors.surface,
        borderRadius: ESUNRadius.mdRadius,
        border: Border.all(
          color: broker.isConnected ? ESUNColors.success.withOpacity(0.3) : ESUNColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: ESUNRadius.smRadius,
              border: Border.all(color: ESUNColors.border),
            ),
            child: ClipRRect(
              borderRadius: ESUNRadius.smRadius,
              child: logoUrl != null
                  ? Padding(
                      padding: const EdgeInsets.all(ESUNSpacing.sm),
                      child: Image.network(
                        logoUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            broker.name.substring(0, 2).toUpperCase(),
                            style: ESUNTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: ESUNColors.primary,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        broker.name.substring(0, 2).toUpperCase(),
                        style: ESUNTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ESUNColors.primary,
                        ),
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
                  broker.name,
                  style: ESUNTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (broker.isConnected && broker.portfolioValue != null)
                  Text(
                    'Portfolio: ${broker.portfolioValue}',
                    style: ESUNTypography.labelSmall.copyWith(
                      color: ESUNColors.success,
                    ),
                  ),
              ],
            ),
          ),
          if (broker.isConnected)
            Container(
              padding: ESUNSpacing.chipInsets,
              decoration: BoxDecoration(
                color: ESUNColors.success.withOpacity(0.1),
                borderRadius: ESUNRadius.fullRadius,
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: ESUNColors.success, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Connected',
                    style: ESUNTypography.labelSmall.copyWith(
                      color: ESUNColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            OutlinedButton(
              onPressed: () => _connectBroker(context, broker),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg, vertical: ESUNSpacing.sm),
              ),
              child: const Text('Connect'),
            ),
        ],
      ),
    );
  }

  void _showAddBrokerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: ESUNSpacing.lg),
            Text(
              'Connect Your Broker',
              style: ESUNTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: ESUNSpacing.sm),
            Text(
              'Link your demat account to track all investments in one place',
              style: ESUNTypography.bodyMedium.copyWith(
                color: ESUNColors.textSecondary,
              ),
            ),
            const SizedBox(height: ESUNSpacing.lg),
            _buildBrokerOption(context, 'Zerodha', Icons.show_chart),
            _buildBrokerOption(context, 'Groww', Icons.trending_up),
            _buildBrokerOption(context, 'Upstox', Icons.candlestick_chart),
            _buildBrokerOption(context, 'Angel One', Icons.analytics),
            _buildBrokerOption(context, '5Paisa', Icons.account_balance),
            const SizedBox(height: ESUNSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildBrokerOption(BuildContext context, String name, IconData icon) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(ESUNSpacing.md),
        decoration: BoxDecoration(
          color: ESUNColors.primary.withOpacity(0.1),
          borderRadius: ESUNRadius.smRadius,
        ),
        child: Icon(icon, color: ESUNColors.primary),
      ),
      title: Text(name),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connecting to $name...')),
        );
      },
    );
  }

  void _connectBroker(BuildContext context, _BrokerData broker) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connecting to ${broker.name}...'),
        action: SnackBarAction(label: 'Cancel', onPressed: () {}),
      ),
    );
  }

  // Net Worth Card
  // ignore: unused_element
  Widget _buildNetWorthCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: FPGradientCard(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net Worth',
                  style: ESUNTypography.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
                Container(
                  padding: ESUNSpacing.badgeInsets,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: ESUNRadius.fullRadius,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '+8.2% this year',
                        style: ESUNTypography.labelSmall.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: ESUNSpacing.sm),
            Text(
              '₹24,85,230',
              style: ESUNTypography.displaySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: ESUNSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _buildNetWorthItem('Assets', '₹28,50,000', Icons.account_balance_wallet, true),
                ),
                const SizedBox(width: ESUNSpacing.md),
                Expanded(
                  child: _buildNetWorthItem('Liabilities', '₹3,64,770', Icons.credit_card, false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetWorthItem(String label, String value, IconData icon, bool isAsset) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: ESUNRadius.smRadius,
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: ESUNTypography.labelSmall.copyWith(
                  color: Colors.white70,
                ),
              ),
              Text(
                value,
                style: ESUNTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Credit & Health Score
  Widget _buildScoresCard(BuildContext context, WidgetRef ref) {
    final aaData = ref.watch(aaDataProvider);
    final healthScore = aaData.healthScore;
    final healthLabel = aaData.healthLabel;
    final creditScore = aaData.creditScore;
    final creditLabel = aaData.creditLabel;
    final healthColor = healthScore >= 65
        ? Colors.blue
        : healthScore >= 50
            ? ESUNColors.warning
            : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg, vertical: ESUNSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: _buildScoreCard(
              'Credit Score',
              creditScore,
              900,
              creditLabel,
              ESUNColors.success,
              Icons.verified,
            ),
          ),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: _buildScoreCard(
              'Financial Health',
              healthScore,
              100,
              healthLabel,
              healthColor,
              Icons.favorite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String title, int score, int maxScore, String status, Color color, IconData icon) {
    final percentage = score / maxScore;
    return FPCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: ESUNTypography.labelMedium.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score.toString(),
                style: ESUNTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                '/$maxScore',
                style: ESUNTypography.bodySmall.copyWith(
                  color: ESUNColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.sm),
          ClipRRect(
            borderRadius: ESUNRadius.fullRadius,
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: ESUNSpacing.sm),
          Container(
            padding: ESUNSpacing.tagInsets,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: ESUNRadius.fullRadius,
            ),
            child: Text(
              status,
              style: ESUNTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHoldings(BuildContext context, WidgetRef ref) {
    final aaData = ref.watch(aaDataProvider);
    final investments = aaData.investments;
    
    // Get color for investment based on type
    Color getInvestmentColor(String type) {
      switch (type.toLowerCase()) {
        case 'stock': return Colors.blue;
        case 'mutual_fund': return Colors.indigo;
        case 'etf': return Colors.purple;
        case 'bond': return Colors.teal;
        default: return Colors.grey;
      }
    }
    
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Holdings',
                style: ESUNTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.sm),
          if (investments.isNotEmpty)
            ...investments.take(3).map((inv) => Padding(
              padding: const EdgeInsets.only(bottom: ESUNSpacing.sm),
              child: _buildHoldingCard(
                inv.name,
                inv.exchange ?? 'NSE',
                inv.currentValue / inv.quantity,
                inv.avgCost,
                inv.quantity.toInt(),
                getInvestmentColor(inv.type),
              ),
            ))
          else ...[
            _buildHoldingCard('HDFC Bank', 'NSE', 1600, 1525, 50, Colors.blue),
            const SizedBox(height: ESUNSpacing.sm),
            _buildHoldingCard('Infosys', 'NSE', 1450, 1380, 30, Colors.indigo),
            const SizedBox(height: ESUNSpacing.sm),
            _buildHoldingCard('Reliance', 'NSE', 2850, 2720, 20, Colors.purple),
          ],
        ],
      ),
    );
  }
  
  Widget _buildHoldingCard(
    String name,
    String exchange,
    double currentPrice,
    double avgPrice,
    int quantity,
    Color color,
  ) {
    final change = currentPrice - avgPrice;
    final changePercent = (change / avgPrice) * 100;
    final isPositive = change >= 0;
    final totalValue = currentPrice * quantity;
    final totalPL = change * quantity;
    
    // Resolve logo
    final holdingLogos = <String, String>{
      'hdfc bank': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://hdfcbank.com&size=128',
      'hdfc': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://hdfcbank.com&size=128',
      'infosys': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://infosys.com&size=128',
      'reliance': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://ril.com&size=128',
      'tcs': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://tcs.com&size=128',
      'icici': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://icicibank.com&size=128',
      'axis': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://axisbank.com&size=128',
      'wipro': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://wipro.com&size=128',
      'bharti': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://airtel.in&size=128',
      'tata': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://tatamotors.com&size=128',
      'sbi': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://onlinesbi.sbi&size=128',
      'kotak': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://kotak.com&size=128',
      'maruti': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://marutisuzuki.com&size=128',
      'itc': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://itcportal.com&size=128',
    };
    final n = name.toLowerCase();
    String? logoUrl;
    for (final e in holdingLogos.entries) {
      if (n.contains(e.key)) { logoUrl = e.value; break; }
    }

    return FPCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: ESUNRadius.smRadius,
              border: Border.all(color: ESUNColors.border),
            ),
            child: ClipRRect(
              borderRadius: ESUNRadius.smRadius,
              child: logoUrl != null
                  ? Padding(
                      padding: const EdgeInsets.all(ESUNSpacing.sm),
                      child: Image.network(
                        logoUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            name.substring(0, 2).toUpperCase(),
                            style: ESUNTypography.titleSmall.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        name.substring(0, 2).toUpperCase(),
                        style: ESUNTypography.titleSmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
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
                  name,
                  style: ESUNTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$exchange • $quantity shares',
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
                totalValue.toINR(),
                style: ESUNTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 12,
                    color: isPositive ? ESUNColors.success : ESUNColors.error,
                  ),
                  Text(
                    '${totalPL.toINR()} (${changePercent.toStringAsFixed(1)}%)',
                    style: ESUNTypography.labelSmall.copyWith(
                      color: isPositive ? ESUNColors.success : ESUNColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSIPOverview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: FPCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active SIPs',
                  style: ESUNTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: ESUNSpacing.chipInsets,
                  decoration: BoxDecoration(
                    color: ESUNColors.primary.withOpacity(0.1),
                    borderRadius: ESUNRadius.fullRadius,
                  ),
                  child: Text(
                    '5 SIPs',
                    style: ESUNTypography.labelMedium.copyWith(
                      color: ESUNColors.primary,
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
                  child: _buildSIPStat('Monthly', '₹25,000', ESUNColors.primary),
                ),
                Container(width: 1, height: 40, color: ESUNColors.border),
                Expanded(
                  child: _buildSIPStat('Invested', '₹3,50,000', Colors.blue),
                ),
                Container(width: 1, height: 40, color: ESUNColors.border),
                Expanded(
                  child: _buildSIPStat('Current', '₹4,12,000', ESUNColors.success),
                ),
              ],
            ),
            const SizedBox(height: ESUNSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Next SIP: 5th Jan - ₹10,000',
                  style: ESUNTypography.bodySmall.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Manage'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSIPStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: ESUNTypography.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: ESUNTypography.labelSmall.copyWith(
            color: ESUNColors.textSecondary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMarketOverview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Market Overview',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildIndexCard('NIFTY 50', '21,731.40', '+0.52%', true),
              ),
              const SizedBox(width: ESUNSpacing.md),
              Expanded(
                child: _buildIndexCard('SENSEX', '71,941.57', '+0.48%', true),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildIndexCard(String name, String value, String change, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: isPositive 
            ? ESUNColors.success.withOpacity(0.05) 
            : ESUNColors.error.withOpacity(0.05),
        borderRadius: ESUNRadius.mdRadius,
        border: Border.all(
          color: isPositive 
              ? ESUNColors.success.withOpacity(0.2)
              : ESUNColors.error.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: ESUNTypography.labelMedium.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: isPositive ? ESUNColors.success : ESUNColors.error,
              ),
              Text(
                change,
                style: ESUNTypography.labelMedium.copyWith(
                  color: isPositive ? ESUNColors.success : ESUNColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopPicks(BuildContext context) {
    final topPicks = [
      _FundPick('axis-bluechip', 'Axis Bluechip Fund', 'Large Cap', '+15.2% (1Y)', '★ 5', Colors.blue),
      _FundPick('hdfc-midcap', 'HDFC Mid-Cap', 'Mid Cap', '+22.8% (1Y)', '★ 4', Colors.purple),
      _FundPick('sbi-smallcap', 'SBI Small Cap', 'Small Cap', '+28.5% (1Y)', '★ 5', Colors.orange),
      _FundPick('icici-flexicap', 'ICICI Flexicap', 'Flexi Cap', '+18.3% (1Y)', '★ 4', Colors.teal),
    ];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Picks for You',
                style: ESUNTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.mutualFunds),
                child: Text('View All', style: TextStyle(color: ESUNColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: topPicks.length,
              itemBuilder: (context, index) {
                final pick = topPicks[index];
                return _buildPickCard(
                  context,
                  pick.id,
                  pick.name,
                  pick.category,
                  pick.returns,
                  pick.rating,
                  pick.color,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPickCard(
    BuildContext context,
    String id,
    String name,
    String category,
    String returns,
    String rating,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => _showFundDetails(context, id, name, category, returns, rating, color),
      child: Container(
        width: 200,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(ESUNSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: ESUNRadius.smRadius,
                ),
                child: Icon(Icons.pie_chart, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: ESUNSpacing.badgeInsets,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: ESUNRadius.fullRadius,
                ),
                child: Text(
                  rating,
                  style: ESUNTypography.labelSmall.copyWith(
                    color: Colors.amber.shade700,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            name,
            style: ESUNTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            category,
            style: ESUNTypography.labelSmall.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
          const SizedBox(height: ESUNSpacing.sm),
          Text(
            returns,
            style: ESUNTypography.titleSmall.copyWith(
              color: ESUNColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
    );
  }
  
  void _showFundDetails(BuildContext context, String id, String name, String category, String returns, String rating, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: ESUNSpacing.md),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(ESUNSpacing.xl),
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(ESUNSpacing.md),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.pie_chart, color: color, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: ESUNTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                              Text(category, style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textSecondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: ESUNSpacing.chipInsets,
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(rating, style: TextStyle(color: Colors.amber.shade700, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: ESUNSpacing.lg),
                    _buildFundStatRow('1Y Returns', returns, ESUNColors.success),
                    _buildFundStatRow('3Y Returns', '+42.5%', ESUNColors.success),
                    _buildFundStatRow('5Y Returns', '+65.2%', ESUNColors.success),
                    _buildFundStatRow('NAV', '₹52.34', ESUNColors.textPrimary),
                    _buildFundStatRow('AUM', '₹12,450 Cr', ESUNColors.textPrimary),
                    _buildFundStatRow('Expense Ratio', '1.05%', ESUNColors.textPrimary),
                    _buildFundStatRow('Min. Investment', '₹500', ESUNColors.textPrimary),
                    const SizedBox(height: ESUNSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('SIP for $name started!')),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
                              side: BorderSide(color: color),
                            ),
                            child: Text('Start SIP', style: TextStyle(color: color)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('One-time investment in $name!')),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: color,
                              padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
                            ),
                            child: const Text('Invest Now', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFundStatRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textSecondary)),
          Text(value, style: ESUNTypography.bodyLarge.copyWith(color: valueColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
  
  Widget _buildExploreFunds(BuildContext context) {
    final categories = [
      _FundCategory('Tax Saving', Icons.savings, Colors.green, 'tax-saving'),
      _FundCategory('High Returns', Icons.rocket_launch, Colors.orange, 'high-returns'),
      _FundCategory('Low Risk', Icons.shield, Colors.blue, 'low-risk'),
      _FundCategory('Index Funds', Icons.bar_chart, Colors.purple, 'index'),
      _FundCategory('Debt Funds', Icons.account_balance, Colors.teal, 'debt'),
      _FundCategory('Equity Funds', Icons.trending_up, Colors.indigo, 'equity'),
    ];
    
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Explore Collections',
                style: ESUNTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.mutualFunds),
                child: Text('More', style: TextStyle(color: ESUNColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          ...categories.map((cat) => Padding(
            padding: const EdgeInsets.only(bottom: ESUNSpacing.sm),
            child: FPCard(
              onTap: () => _showCollectionFunds(context, cat.name, cat.color, cat.categoryId),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(ESUNSpacing.md),
                    decoration: BoxDecoration(
                      color: cat.color.withOpacity(0.1),
                      borderRadius: ESUNRadius.smRadius,
                    ),
                    child: Icon(cat.icon, color: cat.color),
                  ),
                  const SizedBox(width: ESUNSpacing.md),
                  Expanded(
                    child: Text(
                      cat.name,
                      style: ESUNTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: ESUNColors.textTertiary),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
  
  void _showCollectionFunds(BuildContext context, String collectionName, Color color, String categoryId) {
    // Sample funds for each collection
    final fundsMap = {
      'tax-saving': [
        _FundPick('elss-axis', 'Axis Long Term Equity', 'ELSS', '+18.5% (1Y)', '★ 5', Colors.green),
        _FundPick('elss-mirae', 'Mirae Asset Tax Saver', 'ELSS', '+22.3% (1Y)', '★ 5', Colors.green),
        _FundPick('elss-canara', 'Canara Robeco ELSS', 'ELSS', '+16.8% (1Y)', '★ 4', Colors.green),
      ],
      'high-returns': [
        _FundPick('quant-small', 'Quant Small Cap', 'Small Cap', '+45.2% (1Y)', '★ 5', Colors.orange),
        _FundPick('nippon-small', 'Nippon Small Cap', 'Small Cap', '+38.6% (1Y)', '★ 4', Colors.orange),
        _FundPick('tata-digital', 'Tata Digital India', 'Sectoral', '+32.1% (1Y)', '★ 4', Colors.orange),
      ],
      'low-risk': [
        _FundPick('hdfc-liquid', 'HDFC Liquid Fund', 'Liquid', '+6.8% (1Y)', '★ 5', Colors.blue),
        _FundPick('sbi-overnight', 'SBI Overnight Fund', 'Overnight', '+6.2% (1Y)', '★ 5', Colors.blue),
        _FundPick('icici-ultra', 'ICICI Ultra Short', 'Ultra Short', '+7.1% (1Y)', '★ 4', Colors.blue),
      ],
      'index': [
        _FundPick('uti-nifty', 'UTI Nifty 50 Index', 'Index', '+12.5% (1Y)', '★ 5', Colors.purple),
        _FundPick('hdfc-sensex', 'HDFC Index Sensex', 'Index', '+11.8% (1Y)', '★ 5', Colors.purple),
        _FundPick('motilal-sp500', 'Motilal S&P 500 Index', 'Index', '+15.2% (1Y)', '★ 4', Colors.purple),
      ],
      'debt': [
        _FundPick('kotak-bond', 'Kotak Bond Fund', 'Debt', '+8.5% (1Y)', '★ 4', Colors.teal),
        _FundPick('aditya-corp', 'Aditya Birla Corporate Bond', 'Debt', '+7.8% (1Y)', '★ 4', Colors.teal),
        _FundPick('icici-gilt', 'ICICI Gilt Fund', 'Debt', '+9.2% (1Y)', '★ 4', Colors.teal),
      ],
      'equity': [
        _FundPick('parag-flexi', 'Parag Parikh Flexicap', 'Flexi Cap', '+20.5% (1Y)', '★ 5', Colors.indigo),
        _FundPick('kotak-flexi', 'Kotak Flexicap Fund', 'Flexi Cap', '+18.2% (1Y)', '★ 4', Colors.indigo),
        _FundPick('hdfc-flexi', 'HDFC Flexicap Fund', 'Flexi Cap', '+16.8% (1Y)', '★ 4', Colors.indigo),
      ],
    };
    
    final funds = fundsMap[categoryId] ?? [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: ESUNSpacing.md),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(ESUNSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(ESUNSpacing.md),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.folder_special, color: color),
                    ),
                    const SizedBox(width: 12),
                    Text(collectionName, style: ESUNTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
                  itemCount: funds.length,
                  itemBuilder: (context, index) {
                    final fund = funds[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () {
                          Navigator.pop(ctx);
                          _showFundDetails(context, fund.id, fund.name, fund.category, fund.returns, fund.rating, fund.color);
                        },
                        leading: Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(ESUNSpacing.sm),
                          decoration: BoxDecoration(
                            color: fund.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: fund.logoUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    fund.logoUrl!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(Icons.pie_chart, color: fund.color, size: 24),
                                  ),
                                )
                              : Icon(Icons.pie_chart, color: fund.color, size: 24),
                        ),
                        title: Text(fund.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(fund.category),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(fund.returns, style: TextStyle(color: ESUNColors.success, fontWeight: FontWeight.w600)),
                            Text(fund.rating, style: TextStyle(color: Colors.amber.shade700, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showSearchSheet(BuildContext context) {
    final searchController = TextEditingController();
    final allFunds = [
      _FundPick('axis-bluechip', 'Axis Bluechip Fund', 'Large Cap', '+15.2% (1Y)', '★ 5', Colors.blue),
      _FundPick('hdfc-midcap', 'HDFC Mid-Cap', 'Mid Cap', '+22.8% (1Y)', '★ 4', Colors.purple),
      _FundPick('sbi-smallcap', 'SBI Small Cap', 'Small Cap', '+28.5% (1Y)', '★ 5', Colors.orange),
      _FundPick('quant-small', 'Quant Small Cap', 'Small Cap', '+45.2% (1Y)', '★ 5', Colors.orange),
      _FundPick('parag-flexi', 'Parag Parikh Flexicap', 'Flexi Cap', '+20.5% (1Y)', '★ 5', Colors.indigo),
      _FundPick('uti-nifty', 'UTI Nifty 50 Index', 'Index', '+12.5% (1Y)', '★ 5', Colors.purple),
      _FundPick('hdfc-liquid', 'HDFC Liquid Fund', 'Liquid', '+6.8% (1Y)', '★ 5', Colors.blue),
      _FundPick('kotak-bond', 'Kotak Bond Fund', 'Debt', '+8.5% (1Y)', '★ 4', Colors.teal),
    ];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final query = searchController.text.toLowerCase();
          final filteredFunds = query.isEmpty 
              ? allFunds 
              : allFunds.where((f) => f.name.toLowerCase().contains(query) || f.category.toLowerCase().contains(query)).toList();
          
          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, controller) => Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: ESUNSpacing.md),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(ESUNSpacing.lg),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search funds, stocks...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.1),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
                      itemCount: filteredFunds.length,
                      itemBuilder: (context, index) {
                        final fund = filteredFunds[index];
                        return ListTile(
                          onTap: () {
                            Navigator.pop(ctx);
                            _showFundDetails(context, fund.id, fund.name, fund.category, fund.returns, fund.rating, fund.color);
                          },
                          leading: Container(
                            padding: const EdgeInsets.all(ESUNSpacing.sm),
                            decoration: BoxDecoration(
                              color: fund.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.pie_chart, color: fund.color),
                          ),
                          title: Text(fund.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(fund.category),
                          trailing: Text(fund.returns, style: TextStyle(color: ESUNColors.success, fontWeight: FontWeight.w600)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Portfolio Slider Widget with PageView
class _PortfolioSliderWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PortfolioSliderWidget> createState() => _PortfolioSliderWidgetState();
}

class _PortfolioSliderWidgetState extends ConsumerState<_PortfolioSliderWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isBalanceHidden = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            children: [
              _buildNetWorthSlide(),
              _buildPortfolioSlide(),
            ],
          ),
        ),
        const SizedBox(height: ESUNSpacing.sm),
        // Page Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? ESUNColors.primary
                    : ESUNColors.textTertiary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: ESUNSpacing.sm),
      ],
    );
  }

  Widget _buildNetWorthSlide() {
    final aaData = ref.watch(aaDataProvider);
    final snapshot = aaData.snapshot ?? FinancialSnapshot.mock;
    
    String formatAmount(double amount) {
      if (amount >= 10000000) {
        return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
      } else if (amount >= 100000) {
        return '₹${(amount / 100000).toStringAsFixed(2)} L';
      } else {
        return '₹${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
      }
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          ),
          borderRadius: ESUNRadius.lgRadius,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Net Worth',
                      style: ESUNTypography.bodyMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _isBalanceHidden = !_isBalanceHidden),
                      child: Icon(
                        _isBalanceHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: ESUNSpacing.badgeInsets,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: ESUNRadius.fullRadius,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _isBalanceHidden ? '+•••%' : '+${snapshot.netWorthChange.toStringAsFixed(1)}% this year',
                        style: ESUNTypography.labelSmall.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              _isBalanceHidden ? '₹••••••••' : formatAmount(snapshot.netWorth),
              style: ESUNTypography.displaySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: ESUNSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(ESUNSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: ESUNRadius.smRadius,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 18),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Assets', style: ESUNTypography.labelSmall.copyWith(color: Colors.white70)),
                            Text(_isBalanceHidden ? '₹••••••' : formatAmount(snapshot.totalAssets), style: ESUNTypography.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: ESUNSpacing.sm),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(ESUNSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: ESUNRadius.smRadius,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.credit_card, color: Colors.white70, size: 18),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Liabilities', style: ESUNTypography.labelSmall.copyWith(color: Colors.white70)),
                            Text(_isBalanceHidden ? '₹••••••' : formatAmount(snapshot.totalLiabilities), style: ESUNTypography.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
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

  Widget _buildPortfolioSlide() {
    final aaData = ref.watch(aaDataProvider);
    final investments = aaData.investments;
    
    // Calculate total portfolio value from AA investments
    final totalPortfolio = investments.fold(0.0, (sum, inv) => sum + inv.currentValue);
    final totalInvested = investments.fold(0.0, (sum, inv) => sum + (inv.avgCost * inv.quantity));
    final totalReturns = totalPortfolio - totalInvested;
    final totalReturnsPerc = totalInvested > 0 ? (totalReturns / totalInvested) * 100 : 12.5;
    final dayPL = totalPortfolio * 0.003; // Mock day P&L
    final dayPLPerc = 0.28;
    
    String formatAmount(double amount) {
      if (amount >= 10000000) {
        return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
      } else if (amount >= 100000) {
        return '₹${(amount / 100000).toStringAsFixed(2)} L';
      } else {
        return '₹${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
      }
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF059669), Color(0xFF047857)],
          ),
          borderRadius: ESUNRadius.lgRadius,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Total Portfolio',
                      style: ESUNTypography.bodyMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _isBalanceHidden = !_isBalanceHidden),
                      child: Icon(
                        _isBalanceHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: ESUNSpacing.badgeInsets,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: ESUNRadius.fullRadius,
                  ),
                  child: Row(
                    children: [
                      Icon(totalReturnsPerc >= 0 ? Icons.trending_up : Icons.trending_down, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _isBalanceHidden ? '+•••%' : '${totalReturnsPerc >= 0 ? '+' : ''}${totalReturnsPerc.toStringAsFixed(1)}%',
                        style: ESUNTypography.labelSmall.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              _isBalanceHidden ? '₹••••••••' : formatAmount(totalPortfolio),
              style: ESUNTypography.displaySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _isBalanceHidden ? 'Invested: ₹••••• • Returns: ₹•••••' : 'Invested: ${formatAmount(totalInvested)} • Returns: ${formatAmount(totalReturns)}',
              style: ESUNTypography.labelSmall.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: ESUNSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(ESUNSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: ESUNRadius.smRadius,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Day P&L', style: ESUNTypography.labelSmall.copyWith(color: Colors.white70)),
                        Row(
                          children: [
                            Text(_isBalanceHidden ? '+₹••••' : '+${formatAmount(dayPL)}', style: ESUNTypography.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 4),
                            Text(_isBalanceHidden ? '+•••%' : '+${dayPLPerc.toStringAsFixed(2)}%', style: ESUNTypography.labelSmall.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: ESUNSpacing.sm),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(ESUNSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: ESUNRadius.smRadius,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total P&L', style: ESUNTypography.labelSmall.copyWith(color: Colors.white70)),
                        Row(
                          children: [
                            Text(_isBalanceHidden ? '+₹•••••' : '${totalReturns >= 0 ? '+' : ''}${formatAmount(totalReturns)}', style: ESUNTypography.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 4),
                            Text(_isBalanceHidden ? '+•••%' : '${totalReturnsPerc >= 0 ? '+' : ''}${totalReturnsPerc.toStringAsFixed(1)}%', style: ESUNTypography.labelSmall.copyWith(color: Colors.white70)),
                          ],
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
}

class _InvestCategory {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  
  _InvestCategory(this.icon, this.label, this.value, this.color);
}

class _FundCategory {
  final String name;
  final IconData icon;
  final Color color;
  final String categoryId;
  
  _FundCategory(this.name, this.icon, this.color, this.categoryId);
}

class _FundPick {
  final String id;
  final String name;
  final String category;
  final String returns;
  final String rating;
  final Color color;
  
  _FundPick(this.id, this.name, this.category, this.returns, this.rating, this.color);

  String? get logoUrl {
    final n = name.toLowerCase();
    for (final entry in _amcLogos.entries) {
      if (n.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static final Map<String, String> _amcLogos = {
    'axis': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://axismf.com&size=128',
    'hdfc': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://hdfcfund.com&size=128',
    'sbi': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://sbimf.com&size=128',
    'icici': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://icicipruamc.com&size=128',
    'kotak': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://kotakmf.com&size=128',
    'nippon': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://mf.nipponindiaim.com&size=128',
    'parag': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://amc.ppfas.com&size=128',
    'quant': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://quantmutual.com&size=128',
    'tata': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://tatamutualfund.com&size=128',
    'aditya': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://adityabirlacapital.com&size=128',
    'uti': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://utimf.com&size=128',
    'mirae': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://miraeassetmf.co.in&size=128',
    'canara': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://canararobeco.com&size=128',
    'motilal': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://motilaloswalmf.com&size=128',
  };
}

class _StockData {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double changePercent;
  final bool isUp;

  _StockData(this.symbol, this.name, this.price, this.change, this.changePercent, this.isUp);

  // Get logo URL based on symbol
  String? get effectiveLogoUrl {
    final normalized = symbol.toLowerCase().trim();
    return _stockLogos[normalized];
  }

  static final Map<String, String> _stockLogos = {
    'reliance': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://ril.com&size=128',
    'tcs': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://tcs.com&size=128',
    'hdfcbank': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://hdfcbank.com&size=128',
    'infy': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://infosys.com&size=128',
    'icicibank': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://icicibank.com&size=128',
    'bhartiartl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://airtel.in&size=128',
    'sbin': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://onlinesbi.sbi&size=128',
    'axisbank': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://axisbank.com&size=128',
    'kotakbank': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://kotak.com&size=128',
    'wipro': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://wipro.com&size=128',
    'hcltech': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://hcltech.com&size=128',
    'tatamotors': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://tatamotors.com&size=128',
    'maruti': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://marutisuzuki.com&size=128',
    'itc': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://itcportal.com&size=128',
    'hindunilvr': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://hul.co.in&size=128',
    'asianpaint': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://www.asianpaints.com&size=128',
    'bajfinance': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://bajajfinserv.in&size=128',
    'techm': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://techmahindra.com&size=128',
    'sunpharma': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://sunpharma.com&size=128',
    'titan': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://titancompany.in&size=128',
  };
}

class _IPOData {
  final String company;
  final String sector;
  final String priceRange;
  final String dates;
  final String status;
  final Color statusColor;
  
  _IPOData(this.company, this.sector, this.priceRange, this.dates, this.status, this.statusColor);
  
  // Get logo URL based on company name
  String? get effectiveLogoUrl {
    final normalized = company.toLowerCase().trim();
    if (_ipoLogos.containsKey(normalized)) {
      return _ipoLogos[normalized];
    }
    final match = _ipoLogos.entries.firstWhere(
      (e) => normalized.contains(e.key) || e.key.contains(normalized),
      orElse: () => const MapEntry('', ''),
    );
    return match.value.isNotEmpty ? match.value : null;
  }
  
  static final Map<String, String> _ipoLogos = {
    'swiggy': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://swiggy.com&size=128',
    'ola': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://olaelectric.com&size=128',
    'ola electric': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://olaelectric.com&size=128',
    'boat': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://boat-lifestyle.com&size=128',
    'firstcry': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://firstcry.com&size=128',
    'nykaa': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://nykaa.com&size=128',
    'zomato': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://zomato.com&size=128',
    'paytm': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://paytm.com&size=128',
    'policybazaar': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://policybazaar.com&size=128',
  };
}

class _BrokerData {
  final String name;
  final String iconPath;
  final String status;
  final bool isConnected;
  final String? portfolioValue;

  _BrokerData(this.name, this.iconPath, this.status, this.isConnected, this.portfolioValue);

  // Get logo URL based on broker name
  String? get effectiveLogoUrl {
    final normalized = name.toLowerCase().trim();
    return _brokerLogos[normalized];
  }

  static final Map<String, String> _brokerLogos = {
    'zerodha': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://zerodha.com&size=128',
    'groww': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://groww.in&size=128',
    'upstox': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://upstox.com&size=128',
    'angel one': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://angelone.in&size=128',
    '5paisa': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://5paisa.com&size=128',
    'icici direct': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://icicidirect.com&size=128',
    'hdfc securities': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://hdfcsec.com&size=128',
    'kotak securities': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://kotaksecurities.com&size=128',
    'sharekhan': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://sharekhan.com&size=128',
    'motilal oswal': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://motilaloswal.com&size=128',
  };
}

// ============================================================================
// Net Worth Breakdown Section
// ============================================================================

class _NetWorthBreakdownSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aaData = ref.watch(aaDataProvider);
    final snapshot = aaData.snapshot ?? FinancialSnapshot.mock;
    final assets = aaData.assetBreakdown ?? AssetBreakdown.mock;
    final insurances = aaData.insurances;
    
    String formatAmount(double amount) {
      if (amount >= 10000000) {
        return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
      } else if (amount >= 100000) {
        return '₹${(amount / 100000).toStringAsFixed(2)} L';
      } else if (amount >= 1000) {
        return '₹${(amount / 1000).toStringAsFixed(1)} K';
      }
      return '₹${amount.toStringAsFixed(0)}';
    }
    
    // Calculate totals
    final totalInvestments = assets.mutualFunds + assets.stocks + assets.etfs;
    final totalInsurance = insurances.fold(0.0, (sum, i) => sum + i.sumAssured);
    final totalSavings = assets.bankBalance + assets.fixedDeposits;
    final totalOthers = assets.gold + assets.realEstate + assets.others;
    
    // Main categories for 2x2 grid
    final mainCategories = [
      _AssetItem('Total Investments', totalInvestments, Icons.trending_up_rounded, const Color(0xFF2E4A9A)),
      _AssetItem('Total Insurance', totalInsurance, Icons.shield_rounded, const Color(0xFF059669)),
      _AssetItem('Savings & Deposits', totalSavings, Icons.savings_rounded, const Color(0xFF0891B2)),
      _AssetItem('Others (Gold, PPF)', totalOthers, Icons.monetization_on_rounded, const Color(0xFFF59E0B)),
    ];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg, vertical: ESUNSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(ESUNSpacing.sm),
                    decoration: BoxDecoration(
                      color: ESUNColors.primary.withOpacity(0.1),
                      borderRadius: ESUNRadius.smRadius,
                    ),
                    child: Icon(Icons.pie_chart_rounded, color: ESUNColors.primary, size: 20),
                  ),
                  const SizedBox(width: ESUNSpacing.sm),
                  Text(
                    'Wealth Breakdown',
                    style: ESUNTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: ESUNSpacing.badgeInsets,
                decoration: BoxDecoration(
                  color: ESUNColors.success.withOpacity(0.1),
                  borderRadius: ESUNRadius.fullRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, color: ESUNColors.success, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '+${snapshot.netWorthChange.toStringAsFixed(1)}% YTD',
                      style: ESUNTypography.labelSmall.copyWith(
                        color: ESUNColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.sm),
          
          // Assets vs Liabilities Summary Row
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.md),
            decoration: BoxDecoration(
              color: ESUNColors.surfaceVariant,
              borderRadius: ESUNRadius.mdRadius,
              border: Border.all(color: ESUNColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Assets',
                    formatAmount(snapshot.totalAssets),
                    Icons.trending_up_rounded,
                    ESUNColors.success,
                  ),
                ),
                Container(
                  height: 50,
                  width: 1,
                  color: ESUNColors.border,
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Liabilities',
                    formatAmount(snapshot.totalLiabilities),
                    Icons.trending_down_rounded,
                    ESUNColors.error,
                  ),
                ),
                Container(
                  height: 50,
                  width: 1,
                  color: ESUNColors.border,
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Net Worth',
                    formatAmount(snapshot.netWorth),
                    Icons.account_balance_wallet_rounded,
                    ESUNColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ESUNSpacing.xs),
          
          // Main Categories - 2x2 layout
          ..._buildCategoryRows(mainCategories, formatAmount, totalInvestments + totalInsurance + totalSavings + totalOthers),
        ],
      ),
    );
  }
  
  List<Widget> _buildCategoryRows(List<_AssetItem> items, String Function(double) formatAmount, double totalAssetValue) {
    Widget buildCard(_AssetItem item) {
      final percentage = totalAssetValue > 0 
          ? ((item.value / totalAssetValue) * 100).toStringAsFixed(1) 
          : '0';
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(ESUNSpacing.md),
          decoration: BoxDecoration(
            color: ESUNColors.cardBackground,
            borderRadius: ESUNRadius.mdRadius,
            border: Border.all(color: ESUNColors.border),
            boxShadow: [
              BoxShadow(
                color: ESUNColors.cardShadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(ESUNSpacing.xs),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.1),
                      borderRadius: ESUNRadius.smRadius,
                    ),
                    child: Icon(item.icon, color: item.color, size: 16),
                  ),
                  const Spacer(),
                  Container(
                    padding: ESUNSpacing.tagInsets,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.1),
                      borderRadius: ESUNRadius.fullRadius,
                    ),
                    child: Text(
                      '$percentage%',
                      style: ESUNTypography.labelSmall.copyWith(
                        color: item.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: ESUNTypography.bodySmall.copyWith(
                  color: ESUNColors.textSecondary,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                formatAmount(item.value),
                style: ESUNTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ESUNColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return [
      Row(
        children: [
          buildCard(items[0]),
          const SizedBox(width: ESUNSpacing.sm),
          buildCard(items[1]),
        ],
      ),
      const SizedBox(height: ESUNSpacing.sm),
      Row(
        children: [
          buildCard(items[2]),
          const SizedBox(width: ESUNSpacing.sm),
          buildCard(items[3]),
        ],
      ),
    ];
  }
  
  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: ESUNTypography.labelMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: ESUNTypography.labelSmall.copyWith(
            color: ESUNColors.textSecondary,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _AssetItem {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  
  _AssetItem(this.label, this.value, this.icon, this.color);
}



