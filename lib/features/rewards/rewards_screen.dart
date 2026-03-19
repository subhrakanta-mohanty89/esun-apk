/// ESUN Rewards Screen
///
/// Professional rewards hub with gamification, cashback, gift cards, and more.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../theme/theme.dart';
import '../../shared/widgets/cards.dart';
import '../../core/utils/utils.dart';

/// Rewards Screen
class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen>
    with TickerProviderStateMixin {
  late Timer _dailyTimer;
  late Duration _timeRemaining;
  
  // User rewards data - state managed for session
  int _coinBalance = 19546;
  int _cashbackBalance = 247;
  int _scratchCards = 5;
  int _currentStreak = 7;
  int _totalEarned = 45230;
  int _level = 12;
  double _levelProgress = 0.68;
  bool _dailyClaimed = false;

  @override
  void initState() {
    super.initState();
    // Calculate actual time remaining until midnight
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _timeRemaining = midnight.difference(now);
    _startDailyTimer();
  }

  void _startDailyTimer() {
    _dailyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining.inSeconds > 0) {
        setState(() {
          _timeRemaining = _timeRemaining - const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _dailyTimer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return twoDigits(d.inHours) + ':' + twoDigits(d.inMinutes.remainder(60)) + ':' + twoDigits(d.inSeconds.remainder(60));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showRewardsHistory(),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showHowItWorks(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats & Level Card
              _buildStatsCard(),

              // Quick Actions Grid
              _buildQuickActions(),

              // Daily Streak
              _buildDailyStreak(),

              // Featured Rewards
              _buildFeaturedRewards(),

              // Gift Cards
              _buildGiftCardsSection(),

              // Cashback Offers
              _buildCashbackSection(),

              // Earnings Chart
              _buildEarningsChart(),

              // Referral Card
              _buildReferralCard(),

              const SizedBox(height: 72),
            ],
          ),
        ),
      ),
    );
  }

  // Stats & Level Card
  Widget _buildStatsCard() {
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      child: FPGradientCard(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E4A9A), Color(0xFF223474)],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Level Badge
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'LVL',
                        style: ESUNTypography.labelSmall.copyWith(
                          color: Colors.white70,
                          fontSize: 9,
                        ),
                      ),
                      Text(
                        _level.toString(),
                        style: ESUNTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: ESUNSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Gold Member',
                            style: ESUNTypography.titleSmall.copyWith(
                              color: Colors.amber,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            (_levelProgress * 100).toInt().toString() + '%',
                            style: ESUNTypography.labelSmall.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _levelProgress,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(Colors.amber),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '1,280 XP to Platinum',
                        style: ESUNTypography.labelSmall.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: ESUNSpacing.md),
            Container(
              padding: const EdgeInsets.all(ESUNSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: ESUNRadius.mdRadius,
              ),
              child: Row(
                children: [
                  _buildStatItem(Icons.monetization_on, Colors.amber, _coinBalance.toString(), 'Coins'),
                  _buildStatDivider(),
                  _buildStatItem(Icons.currency_rupee, Colors.greenAccent, _cashbackBalance.toCurrency(decimals: 0), 'Cashback'),
                  _buildStatDivider(),
                  _buildStatItem(Icons.card_giftcard, Colors.pinkAccent, _scratchCards.toString(), 'Scratches'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color color, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: ESUNTypography.titleSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: ESUNTypography.labelSmall.copyWith(
              color: Colors.white60,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white24,
    );
  }

  // Quick Actions Grid
  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(Icons.inventory_2, 'Daily', const Color(0xFF059669), _formatDuration(_timeRemaining)),
      _QuickAction(Icons.casino, 'Spin', const Color(0xFFF59E0B), 'FREE'),
      _QuickAction(Icons.store, 'Store', const Color(0xFF2E4A9A), null),
      _QuickAction(Icons.credit_card, 'Offers', const Color(0xFFEC4899), '12'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.md),
      child: Row(
        children: actions.map((action) => Expanded(
          child: GestureDetector(
            onTap: () => _handleQuickAction(action.label),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.sm),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.1),
                borderRadius: ESUNRadius.mdRadius,
                border: Border.all(color: action.color.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: action.color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(action.icon, color: action.color, size: 20),
                      ),
                      if (action.badge != null)
                        Positioned(
                          right: -8,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: action.color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              action.badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    action.label,
                    style: ESUNTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  // Daily Streak
  Widget _buildDailyStreak() {
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      child: FPCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Daily Streak',
                      style: ESUNTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: ESUNRadius.fullRadius,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orange, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _currentStreak.toString() + ' days',
                        style: ESUNTypography.labelSmall.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: ESUNSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final isCompleted = index < _currentStreak;
                final isToday = index == _currentStreak - 1;
                return _buildStreakDay(
                  'D' + (index + 1).toString(),
                  ((index + 1) * 10).toString(),
                  isCompleted,
                  isToday,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakDay(String day, String coins, bool completed, bool isToday) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed
                ? const Color(0xFF059669)
                : ESUNColors.surface,
            border: Border.all(
              color: isToday
                  ? Colors.orange
                  : completed
                      ? const Color(0xFF059669)
                      : ESUNColors.border,
              width: isToday ? 2 : 1,
            ),
          ),
          child: Center(
            child: completed
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    coins,
                    style: ESUNTypography.labelSmall.copyWith(
                      color: ESUNColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          day,
          style: ESUNTypography.labelSmall.copyWith(
            color: completed ? const Color(0xFF059669) : ESUNColors.textTertiary,
            fontSize: 10,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // Featured Rewards
  Widget _buildFeaturedRewards() {
    final symbol = CurrencyFormatter.symbol;
    final rewards = [
      _FeaturedReward('Amazon Echo', '${symbol}4,999', 5000, Colors.blue, Icons.speaker),
      _FeaturedReward('Swiggy ${symbol}200', '${symbol}180', 2000, Colors.orange, Icons.fastfood),
      _FeaturedReward('Spotify 1M', '${symbol}119', 1500, Colors.green, Icons.music_note),
      _FeaturedReward('Netflix 1M', '${symbol}199', 2500, Colors.red, Icons.movie),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Featured Rewards', 'View All'),
          const SizedBox(height: ESUNSpacing.sm),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: rewards.length,
              itemBuilder: (context, index) {
                final reward = rewards[index];
                return _buildFeaturedRewardCard(reward);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedRewardCard(_FeaturedReward reward) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: ESUNSpacing.sm),
      decoration: BoxDecoration(
        color: ESUNColors.surface,
        borderRadius: ESUNRadius.mdRadius,
        border: Border.all(color: ESUNColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: reward.color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Center(
              child: _buildBrandLogo(reward.name, reward.color, reward.icon, 28),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  style: ESUNTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  reward.value,
                  style: ESUNTypography.bodySmall.copyWith(
                    color: ESUNColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      reward.coins.toString(),
                      style: ESUNTypography.labelSmall.copyWith(
                        color: ESUNColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
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

  // Gift Cards Section
  Widget _buildGiftCardsSection() {
    final cards = [
      _GiftCardData('Amazon', 5, Colors.orange, Icons.shopping_bag),
      _GiftCardData('Flipkart', 3, Colors.blue, Icons.shop),
      _GiftCardData('Swiggy', 10, Colors.deepOrange, Icons.delivery_dining),
      _GiftCardData('Myntra', 8, Colors.pink, Icons.checkroom),
    ];

    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Gift Cards', 'All Cards'),
          const SizedBox(height: ESUNSpacing.sm),
          Row(
            children: cards.map((card) => Expanded(
              child: GestureDetector(
                onTap: () => _showGiftCard(card.brand),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(ESUNSpacing.sm),
                  decoration: BoxDecoration(
                    color: ESUNColors.surface,
                    borderRadius: ESUNRadius.mdRadius,
                    border: Border.all(color: ESUNColors.border),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: card.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: _buildBrandLogo(card.brand, card.color, card.icon, 18),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        card.brand,
                        style: ESUNTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        card.discount.toString() + '% off',
                        style: ESUNTypography.labelSmall.copyWith(
                          color: const Color(0xFF059669),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // Cashback Section
  Widget _buildCashbackSection() {
    final symbol = CurrencyFormatter.symbol;
    final offers = [
      _CashbackData('Pay Rent', '${symbol}500', Icons.home, Colors.blue),
      _CashbackData('Credit Card', '1%', Icons.credit_card, Colors.purple),
      _CashbackData('Electricity', '${symbol}50', Icons.electric_bolt, Colors.amber),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Cashback Offers', 'View All'),
          const SizedBox(height: ESUNSpacing.sm),
          ...offers.map((offer) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(ESUNSpacing.sm),
            decoration: BoxDecoration(
              color: ESUNColors.surface,
              borderRadius: ESUNRadius.mdRadius,
              border: Border.all(color: ESUNColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: offer.color.withOpacity(0.1),
                    borderRadius: ESUNRadius.smRadius,
                  ),
                  child: Icon(offer.icon, color: offer.color, size: 20),
                ),
                const SizedBox(width: ESUNSpacing.sm),
                Expanded(
                  child: Text(
                    offer.title,
                    style: ESUNTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withOpacity(0.1),
                    borderRadius: ESUNRadius.fullRadius,
                  ),
                  child: Text(
                    offer.cashback,
                    style: ESUNTypography.labelSmall.copyWith(
                      color: const Color(0xFF059669),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // Earnings Chart
  Widget _buildEarningsChart() {
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      child: FPCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Earnings Overview',
                  style: ESUNTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ESUNColors.primary.withOpacity(0.1),
                    borderRadius: ESUNRadius.fullRadius,
                  ),
                  child: Text(
                    'Last 6 Months',
                    style: ESUNTypography.labelSmall.copyWith(
                      color: ESUNColors.primary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ESUNSpacing.sm),
            Row(
              children: [
                _buildEarningStat('Total Earned', '\u20B9' + _totalEarned.toString(), const Color(0xFF059669)),
                const SizedBox(width: ESUNSpacing.md),
                _buildEarningStat('This Month', '\u20B94,520', ESUNColors.primary),
              ],
            ),
            const SizedBox(height: ESUNSpacing.md),
            SizedBox(
              height: 120,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 8000,
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
                            style: ESUNTypography.labelSmall.copyWith(fontSize: 9),
                          );
                        },
                        reservedSize: 20,
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _makeBarGroup(0, 3200),
                    _makeBarGroup(1, 4800),
                    _makeBarGroup(2, 2900),
                    _makeBarGroup(3, 5600),
                    _makeBarGroup(4, 7200),
                    _makeBarGroup(5, 4520),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(ESUNSpacing.sm),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: ESUNRadius.smRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: ESUNTypography.labelSmall.copyWith(
                color: ESUNColors.textSecondary,
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: ESUNTypography.titleSmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
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
          gradient: const LinearGradient(
            colors: [Color(0xFF2E4A9A), Color(0xFF223474)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 16,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }

  // Referral Card
  Widget _buildReferralCard() {
    final symbol = CurrencyFormatter.symbol;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(ESUNSpacing.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E4A9A), Color(0xFF223474)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: ESUNRadius.lgRadius,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people, color: Colors.white, size: 24),
            ),
            const SizedBox(width: ESUNSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invite & Earn ${symbol}100',
                    style: ESUNTypography.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Share with friends & family',
                    style: ESUNTypography.labelSmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: ESUNRadius.smRadius,
              ),
              child: Text(
                'Share',
                style: ESUNTypography.labelSmall.copyWith(
                  color: const Color(0xFF223474),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section Header
  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: ESUNTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Text(
            action,
            style: ESUNTypography.labelSmall.copyWith(
              color: ESUNColors.primary,
            ),
          ),
        ),
      ],
    );
  }
  
  // Brand Logo Widget - Uses text-based logos for reliability
  Widget _buildBrandLogo(String brandName, Color color, IconData fallbackIcon, double iconSize) {
    final normalized = brandName.toLowerCase();
    
    // Brand logo URL mapping
    final brandLogos = <String, String>{
      'amazon': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://amazon.in&size=128',
      'flipkart': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://flipkart.com&size=128',
      'swiggy': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://swiggy.com&size=128',
      'myntra': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://myntra.com&size=128',
      'spotify': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://spotify.com&size=128',
      'netflix': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://netflix.com&size=128',
      'zomato': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://zomato.com&size=128',
    };

    String? logoUrl;
    for (final entry in brandLogos.entries) {
      if (normalized.contains(entry.key)) {
        logoUrl = entry.value;
        break;
      }
    }

    if (logoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          logoUrl,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(fallbackIcon, color: color, size: iconSize),
        ),
      );
    }
    
    return Icon(fallbackIcon, color: color, size: iconSize);
  }

  // Action Handlers
  void _handleQuickAction(String action) {
    switch (action) {
      case 'Daily':
        _showDailyReward();
        break;
      case 'Spin':
        _showSpinWheel();
        break;
      case 'Store':
        _showStore();
        break;
      case 'Offers':
        _showOffers();
        break;
    }
  }

  void _showRewardsHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ESUNColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rewards History',
              style: ESUNTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: ESUNSpacing.md),
            _buildHistoryItem('Gift Card Purchase', '-5,000 coins', 'Today', false),
            _buildHistoryItem('Spin & Win', '+500 coins', 'Yesterday', true),
            _buildHistoryItem('Daily Reward', '+100 coins', '2 days ago', true),
            _buildHistoryItem('Referral Bonus', '+1,000 coins', '3 days ago', true),
            const SizedBox(height: ESUNSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String title, String points, String date, bool isPositive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isPositive ? const Color(0xFF059669) : Colors.red).withOpacity(0.1),
              borderRadius: ESUNRadius.smRadius,
            ),
            child: Icon(
              isPositive ? Icons.arrow_downward : Icons.arrow_upward,
              color: isPositive ? const Color(0xFF059669) : Colors.red,
              size: 18,
            ),
          ),
          const SizedBox(width: ESUNSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ESUNTypography.bodySmall),
                Text(
                  date,
                  style: ESUNTypography.labelSmall.copyWith(
                    color: ESUNColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            points,
            style: ESUNTypography.bodySmall.copyWith(
              color: isPositive ? const Color(0xFF059669) : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showHowItWorks() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ESUNColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How Rewards Work',
              style: ESUNTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: ESUNSpacing.md),
            _buildHowItWorksStep('1', 'Earn coins by paying bills & transacting'),
            _buildHowItWorksStep('2', 'Maintain streaks for bonus rewards'),
            _buildHowItWorksStep('3', 'Redeem coins for gift cards & cashback'),
            _buildHowItWorksStep('4', 'Level up for exclusive benefits'),
            const SizedBox(height: ESUNSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: ESUNColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: ESUNTypography.labelSmall.copyWith(
                  color: ESUNColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: ESUNSpacing.sm),
          Expanded(
            child: Text(text, style: ESUNTypography.bodySmall),
          ),
        ],
      ),
    );
  }

  void _showDailyReward() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ESUNColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Daily Reward',
          style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.card_giftcard, color: Colors.amber, size: 32),
            ),
            const SizedBox(height: ESUNSpacing.md),
            if (_dailyClaimed)
              Text(
                'Come back in ${_formatDuration(_timeRemaining)}',
                style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
              )
            else
              Text(
                'Claim your 100 coins!',
                style: ESUNTypography.bodyMedium.copyWith(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Day $_currentStreak streak 🔥',
              style: ESUNTypography.labelMedium,
            ),
          ],
        ),
        actions: [
          if (!_dailyClaimed)
            FilledButton(
              onPressed: () {
                setState(() {
                  _coinBalance += 100;
                  _totalEarned += 100;
                  _currentStreak++;
                  _dailyClaimed = true;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('+100 coins claimed!')),
                );
              },
              child: const Text('Claim'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_dailyClaimed ? 'OK' : 'Later'),
          ),
        ],
      ),
    );
  }

  void _showSpinWheel() {
    final prizes = [50, 100, 200, 500, 1000, 25];
    final won = prizes[(DateTime.now().millisecondsSinceEpoch % prizes.length)];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🎰 Spin & Win!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, size: 48, color: Colors.amber),
            const SizedBox(height: 12),
            Text('You won $won coins!', style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold, color: ESUNColors.success)),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              setState(() { _coinBalance += won; _totalEarned += won; });
              Navigator.pop(ctx);
            },
            child: const Text('Collect'),
          ),
        ],
      ),
    );
  }

  void _showStore() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rewards Store', style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: ESUNSpacing.lg),
            ListTile(
              leading: const Icon(Icons.card_giftcard, color: Colors.orange),
              title: const Text('Amazon Gift Card'),
              subtitle: const Text('500 coins = ₹50'),
              trailing: FilledButton(
                onPressed: _coinBalance >= 500 ? () {
                  setState(() { _coinBalance -= 500; _cashbackBalance += 50; });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('₹50 Amazon voucher redeemed!')));
                } : null,
                child: const Text('Redeem'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.local_cafe, color: Colors.brown),
              title: const Text('Starbucks Voucher'),
              subtitle: const Text('1000 coins = ₹100'),
              trailing: FilledButton(
                onPressed: _coinBalance >= 1000 ? () {
                  setState(() { _coinBalance -= 1000; _cashbackBalance += 100; });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('₹100 Starbucks voucher redeemed!')));
                } : null,
                child: const Text('Redeem'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOffers() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Offers', style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: ESUNSpacing.lg),
            ListTile(
              leading: const Icon(Icons.percent, color: Colors.green),
              title: const Text('5% Cashback on Investments'),
              subtitle: const Text('Min ₹5,000 investment'),
            ),
            ListTile(
              leading: const Icon(Icons.flash_on, color: Colors.orange),
              title: const Text('2x Coins on Bill Payments'),
              subtitle: const Text('Valid this week'),
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.blue),
              title: const Text('Refer & Earn ₹500'),
              subtitle: const Text('Per successful referral'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGiftCard(String brand) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$brand Gift Card', style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: ESUNSpacing.lg),
            Text('Redeem your coins for $brand vouchers', style: ESUNTypography.bodyMedium),
            const SizedBox(height: ESUNSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$brand voucher added to wallet')));
                },
                child: const Text('Redeem 1000 Coins'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Data Classes
class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String? badge;

  _QuickAction(this.icon, this.label, this.color, this.badge);
}

class _FeaturedReward {
  final String name;
  final String value;
  final int coins;
  final Color color;
  final IconData icon;

  _FeaturedReward(this.name, this.value, this.coins, this.color, this.icon);
  
  static const Map<String, String> _brandLogos = {
    'amazon': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://amazon.in&size=128',
    'swiggy': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://swiggy.com&size=128',
    'spotify': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://spotify.com&size=128',
    'netflix': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://netflix.com&size=128',
    'zomato': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://zomato.com&size=128',
    'flipkart': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://flipkart.com&size=128',
    'myntra': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://myntra.com&size=128',
  };
  
  String? get effectiveLogoUrl {
    final normalized = name.toLowerCase();
    for (final entry in _brandLogos.entries) {
      if (normalized.contains(entry.key)) return entry.value;
    }
    return null;
  }
}

class _GiftCardData {
  final String brand;
  final int discount;
  final Color color;
  final IconData icon;

  _GiftCardData(this.brand, this.discount, this.color, this.icon);
  
  static const Map<String, String> _brandLogos = {
    'amazon': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://amazon.in&size=128',
    'flipkart': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://flipkart.com&size=128',
    'swiggy': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://swiggy.com&size=128',
    'myntra': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://myntra.com&size=128',
    'zomato': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://zomato.com&size=128',
    'spotify': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://spotify.com&size=128',
    'netflix': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://netflix.com&size=128',
    'paytm': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://paytm.com&size=128',
    'google play': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://play.google.com&size=128',
    'uber': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://uber.com&size=128',
    'ola': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://uber.com&size=128',
    'bookmyshow': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://bookmyshow.com&size=128',
    'mitra': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://amazon.in&size=128',
  };
  
  String? get effectiveLogoUrl {
    final normalized = brand.toLowerCase();
    if (_brandLogos.containsKey(normalized)) {
      return _brandLogos[normalized];
    }
    return null;
  }
}

class _CashbackData {
  final String title;
  final String cashback;
  final IconData icon;
  final Color color;

  _CashbackData(this.title, this.cashback, this.icon, this.color);
}



