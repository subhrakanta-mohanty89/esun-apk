/// ESUN Stocks & ETFs Screen — Stock Market & ETFs
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class StocksScreen extends StatelessWidget {
  const StocksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ESUNColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200, pinned: true,
            backgroundColor: const Color(0xFF880E4F),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF880E4F), Color(0xFFAD1457), Color(0xFFC62828)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(ESUNSpacing.xl),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.candlestick_chart, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: ESUNSpacing.md),
                      Text('Stocks & ETFs', style: ESUNTypography.headlineLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Trade stocks & invest in ETFs', style: ESUNTypography.bodyMedium.copyWith(color: Colors.white70)),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          // Market Indices
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: Row(children: [
                Expanded(child: _IndexCard(name: 'NIFTY 50', value: '22,147', change: '+128.50 (+0.58%)', isUp: true)),
                const SizedBox(width: 12),
                Expanded(child: _IndexCard(name: 'SENSEX', value: '72,831', change: '+412.30 (+0.57%)', isUp: true)),
              ]),
            ),
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
              child: Row(children: [
                Expanded(child: _ActionTile(icon: Icons.search, label: 'Search Stocks', color: const Color(0xFF880E4F))),
                const SizedBox(width: 10),
                Expanded(child: _ActionTile(icon: Icons.bookmark, label: 'Watchlist', color: const Color(0xFF1565C0))),
                const SizedBox(width: 10),
                Expanded(child: _ActionTile(icon: Icons.bar_chart, label: 'Screener', color: const Color(0xFF2E7D32))),
              ]),
            ),
          ),

          // Top Gainers
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.xxl, ESUNSpacing.lg, ESUNSpacing.sm),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Top Gainers', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                Text('View All', style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.primary, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _StockTile(name: 'Tata Motors', symbol: 'TATAMOTORS', price: '₹985.40', change: '+4.2%', isUp: true),
                _StockTile(name: 'Infosys', symbol: 'INFY', price: '₹1,654.30', change: '+2.8%', isUp: true),
                _StockTile(name: 'HDFC Bank', symbol: 'HDFCBANK', price: '₹1,532.15', change: '+1.9%', isUp: true),
                _StockTile(name: 'Reliance Ind.', symbol: 'RELIANCE', price: '₹2,897.60', change: '+1.5%', isUp: true),
              ]),
            ),
          ),

          // Popular ETFs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.xxl, ESUNSpacing.lg, ESUNSpacing.sm),
              child: Text('Popular ETFs', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 155,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
                children: const [
                  _EtfCard(name: 'Nifty 50 ETF', provider: 'Nippon India', price: '₹221.40', return1y: '+14.8%', expense: '0.07%', color: Color(0xFF0D47A1)),
                  _EtfCard(name: 'Gold BeES', provider: 'Nippon India', price: '₹53.20', return1y: '+12.1%', expense: '0.79%', color: Color(0xFFF57F17)),
                  _EtfCard(name: 'Next 50 ETF', provider: 'ICICI Pru', price: '₹47.85', return1y: '+22.3%', expense: '0.15%', color: Color(0xFF4A148C)),
                  _EtfCard(name: 'Bankex ETF', provider: 'SBI MF', price: '₹498.50', return1y: '+8.7%', expense: '0.20%', color: Color(0xFF880E4F)),
                ],
              ),
            ),
          ),

          // Sectors
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.xxl, ESUNSpacing.lg, ESUNSpacing.md),
              child: Text('Sectors', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, 0, ESUNSpacing.lg, 80),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.0),
              delegate: SliverChildListDelegate([
                _SectorTile('IT', Icons.computer, '+1.8%', true, const Color(0xFF1565C0)),
                _SectorTile('Banking', Icons.account_balance, '+0.7%', true, const Color(0xFF2E7D32)),
                _SectorTile('Pharma', Icons.medical_services, '-0.3%', false, const Color(0xFFE53935)),
                _SectorTile('Auto', Icons.directions_car, '+2.1%', true, const Color(0xFFE65100)),
                _SectorTile('FMCG', Icons.shopping_cart, '+0.4%', true, const Color(0xFF6A1B9A)),
                _SectorTile('Energy', Icons.bolt, '-1.2%', false, const Color(0xFFF57F17)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndexCard extends StatelessWidget {
  final String name, value, change;
  final bool isUp;
  const _IndexCard({required this.name, required this.value, required this.change, required this.isUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: isUp ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)] : [const Color(0xFFC62828), const Color(0xFFE53935)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: ESUNTypography.bodySmall.copyWith(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(value, style: ESUNTypography.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(change, style: ESUNTypography.labelSmall.copyWith(color: Colors.white.withOpacity(0.85))),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ActionTile({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(label, style: ESUNTypography.labelSmall.copyWith(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _StockTile extends StatelessWidget {
  final String name, symbol, price, change;
  final bool isUp;
  const _StockTile({required this.name, required this.symbol, required this.price, required this.change, required this.isUp});

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
          decoration: BoxDecoration(color: const Color(0xFF880E4F).withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(symbol.substring(0, 1), style: const TextStyle(color: Color(0xFF880E4F), fontWeight: FontWeight.bold, fontSize: 16))),
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

class _EtfCard extends StatelessWidget {
  final String name, provider, price, return1y, expense;
  final Color color;
  const _EtfCard({required this.name, required this.provider, required this.price, required this.return1y, required this.expense, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190, margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: ESUNTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          Text(provider, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(price, style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(return1y, style: ESUNTypography.labelSmall.copyWith(color: Colors.green, fontWeight: FontWeight.w600)),
            Text('ER: $expense', style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
          ]),
        ]),
      ]),
    );
  }
}

class _SectorTile extends StatelessWidget {
  final String name, change;
  final IconData icon;
  final bool isUp;
  final Color color;
  const _SectorTile(this.name, this.icon, this.change, this.isUp, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(name, style: ESUNTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        Text(change, style: ESUNTypography.labelSmall.copyWith(color: isUp ? Colors.green : Colors.red, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
