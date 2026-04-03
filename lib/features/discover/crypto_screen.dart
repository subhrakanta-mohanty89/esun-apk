/// ESUN Crypto Screen — Crypto Investments
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class CryptoScreen extends StatelessWidget {
  const CryptoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ESUNColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200, pinned: true,
            backgroundColor: const Color(0xFF1A237E),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(ESUNSpacing.xl),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.currency_bitcoin, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: ESUNSpacing.md),
                      Text('Crypto', style: ESUNTypography.headlineLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Explore & invest in digital assets', style: ESUNTypography.bodyMedium.copyWith(color: Colors.white70)),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          // Market Overview
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(ESUNSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0D0D1A), Color(0xFF1A1A2E)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Market Overview', style: ESUNTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _MarketStat('Total Market Cap', '\$2.4T', Colors.white)),
                    Expanded(child: _MarketStat('24h Volume', '\$68.5B', Colors.white)),
                    Expanded(child: _MarketStat('BTC Dominance', '52.1%', Colors.amber)),
                  ]),
                ]),
              ),
            ),
          ),

          // Trending Coins
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.md, ESUNSpacing.lg, ESUNSpacing.sm),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Trending Coins', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                Text('View All', style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.primary, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _CoinTile(symbol: 'BTC', name: 'Bitcoin', price: '₹57,82,430', change: '+2.34%', isUp: true, color: const Color(0xFFF7931A)),
                _CoinTile(symbol: 'ETH', name: 'Ethereum', price: '₹3,12,650', change: '+1.87%', isUp: true, color: const Color(0xFF627EEA)),
                _CoinTile(symbol: 'SOL', name: 'Solana', price: '₹14,820', change: '+5.62%', isUp: true, color: const Color(0xFF00FFA3)),
                _CoinTile(symbol: 'XRP', name: 'Ripple', price: '₹188.50', change: '-0.43%', isUp: false, color: const Color(0xFF346AA9)),
                _CoinTile(symbol: 'ADA', name: 'Cardano', price: '₹68.30', change: '+3.15%', isUp: true, color: const Color(0xFF0033AD)),
                _CoinTile(symbol: 'MATIC', name: 'Polygon', price: '₹95.40', change: '-1.20%', isUp: false, color: const Color(0xFF8247E5)),
              ]),
            ),
          ),

          // Categories
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.xxl, ESUNSpacing.lg, ESUNSpacing.md),
              child: Text('Explore Categories', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.8),
              delegate: SliverChildListDelegate([
                _CryptoCategory('DeFi', Icons.account_tree, '132 coins', const Color(0xFF6A1B9A)),
                _CryptoCategory('NFTs', Icons.palette, '78 coins', const Color(0xFFE65100)),
                _CryptoCategory('Layer 2', Icons.layers, '45 coins', const Color(0xFF1565C0)),
                _CryptoCategory('Gaming', Icons.sports_esports, '63 coins', const Color(0xFF00695C)),
                _CryptoCategory('AI & Data', Icons.auto_awesome, '28 coins', const Color(0xFFE53935)),
                _CryptoCategory('Stablecoins', Icons.lock, '12 coins', const Color(0xFF37474F)),
              ]),
            ),
          ),

          // Disclaimer
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.xxl, ESUNSpacing.lg, 80),
              child: Container(
                padding: const EdgeInsets.all(ESUNSpacing.md),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.withOpacity(0.2))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Crypto investments are subject to high market risk. Please do your own research before investing.', style: ESUNTypography.bodySmall.copyWith(color: Colors.orange[800]))),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MarketStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: ESUNTypography.labelSmall.copyWith(color: Colors.white54)),
      const SizedBox(height: 4),
      Text(value, style: ESUNTypography.titleMedium.copyWith(color: color, fontWeight: FontWeight.bold)),
    ]);
  }
}

class _CoinTile extends StatelessWidget {
  final String symbol, name, price, change;
  final bool isUp;
  final Color color;
  const _CoinTile({required this.symbol, required this.name, required this.price, required this.change, required this.isUp, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
          child: Center(child: Text(symbol.substring(0, 1), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: ESUNTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
          Text(symbol, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(price, style: ESUNTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward, size: 12, color: isUp ? Colors.green : Colors.red),
            Text(change, style: ESUNTypography.labelSmall.copyWith(color: isUp ? Colors.green : Colors.red, fontWeight: FontWeight.w600)),
          ]),
        ]),
      ]),
    );
  }
}

class _CryptoCategory extends StatelessWidget {
  final String name;
  final IconData icon;
  final String count;
  final Color color;
  const _CryptoCategory(this.name, this.icon, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: ESUNTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          Text(count, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
        ]),
      ]),
    );
  }
}
