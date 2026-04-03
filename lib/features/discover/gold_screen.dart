/// ESUN Gold Screen — Digital & Physical Gold
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class GoldScreen extends StatelessWidget {
  const GoldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ESUNColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero
          SliverAppBar(
            expandedHeight: 220, pinned: true,
            backgroundColor: const Color(0xFFF57F17),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFF57F17), Color(0xFFFBC02D), Color(0xFFFFD54F)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(ESUNSpacing.xl),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.diamond, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: ESUNSpacing.md),
                      Text('Gold', style: ESUNTypography.headlineLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Buy, sell & invest in 24K digital gold', style: ESUNTypography.bodyMedium.copyWith(color: Colors.white.withOpacity(0.85))),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          // Live Price Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(ESUNSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Live Gold Price (24K)', style: ESUNTypography.bodySmall.copyWith(color: Colors.white60)),
                    const SizedBox(height: 4),
                    Text('₹7,245 /gm', style: ESUNTypography.headlineMedium.copyWith(color: Colors.amber, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.arrow_upward, color: Colors.greenAccent, size: 14),
                      Text(' +0.72% today', style: ESUNTypography.bodySmall.copyWith(color: Colors.greenAccent)),
                    ]),
                  ])),
                  Column(children: [
                    _GoldActionBtn('Buy', Icons.add_circle_outline, Colors.greenAccent),
                    const SizedBox(height: 8),
                    _GoldActionBtn('Sell', Icons.remove_circle_outline, Colors.redAccent),
                  ]),
                ]),
              ),
            ),
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
              child: Row(children: [
                Expanded(child: _QuickAction(icon: Icons.account_balance_wallet, label: 'Buy Gold', color: const Color(0xFFF57F17))),
                const SizedBox(width: 12),
                Expanded(child: _QuickAction(icon: Icons.savings, label: 'Gold SIP', color: const Color(0xFF6A1B9A))),
                const SizedBox(width: 12),
                Expanded(child: _QuickAction(icon: Icons.card_giftcard, label: 'Gift Gold', color: const Color(0xFFE53935))),
              ]),
            ),
          ),

          // My Holdings
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.xxl, ESUNSpacing.lg, ESUNSpacing.sm),
              child: Text('My Holdings', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(ESUNSpacing.lg),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.diamond, color: Colors.amber, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Digital Gold', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      Text('SafeGold Vault', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ])),
                    const Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('2.35 gm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('≈ ₹17,026', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ]),
                  ]),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      _HoldingStat('Invested', '₹15,800'),
                      _HoldingStat('Current', '₹17,026'),
                      _HoldingStat('Returns', '+₹1,226 (7.8%)', isProfit: true),
                    ]),
                  ),
                ]),
              ),
            ),
          ),

          // Gold Products
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.xxl, ESUNSpacing.lg, ESUNSpacing.md),
              child: Text('Gold Investment Options', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, 0, ESUNSpacing.lg, 80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _GoldProduct(icon: Icons.phone_android, name: 'Digital Gold', desc: 'Buy 24K gold starting ₹10', tag: '24K Pure Gold', color: const Color(0xFFF57F17)),
                _GoldProduct(icon: Icons.savings, name: 'Gold SIP', desc: 'Auto-invest daily, weekly or monthly', tag: 'Start ₹100', color: const Color(0xFF6A1B9A)),
                _GoldProduct(icon: Icons.account_balance, name: 'Sovereign Gold Bond', desc: 'Govt-backed, earn 2.5% interest p.a.', tag: 'Tax Free', color: const Color(0xFF1565C0)),
                _GoldProduct(icon: Icons.trending_up, name: 'Gold ETF', desc: 'Trade gold like stocks on exchanges', tag: 'Low Cost', color: const Color(0xFF2E7D32)),
                _GoldProduct(icon: Icons.local_shipping, name: 'Physical Delivery', desc: 'Get gold coins & bars delivered home', tag: 'Hallmarked', color: const Color(0xFFE65100)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _GoldActionBtn(this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _QuickAction({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(label, style: ESUNTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _HoldingStat extends StatelessWidget {
  final String label, value;
  final bool isProfit;
  const _HoldingStat(this.label, this.value, {this.isProfit = false});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
      const SizedBox(height: 2),
      Text(value, style: ESUNTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: isProfit ? Colors.green : null)),
    ]);
  }
}

class _GoldProduct extends StatelessWidget {
  final IconData icon;
  final String name, desc, tag;
  final Color color;
  const _GoldProduct({required this.icon, required this.name, required this.desc, required this.tag, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(desc, style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
          child: Text(tag, style: ESUNTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}
