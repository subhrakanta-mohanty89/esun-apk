/// ESUN Mutual Funds Screen — Browse & Invest
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class MutualFundsScreen extends StatelessWidget {
  const MutualFundsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ESUNColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200, pinned: true,
            backgroundColor: const Color(0xFF0D47A1),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(ESUNSpacing.xl),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.pie_chart, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: ESUNSpacing.md),
                      Text('Mutual Funds', style: ESUNTypography.headlineLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Invest in top-rated funds, start SIPs', style: ESUNTypography.bodyMedium.copyWith(color: Colors.white70)),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: Row(children: [
                Expanded(child: _QuickBtn(icon: Icons.trending_up, label: 'Start SIP', desc: 'From ₹100/mo', color: const Color(0xFF0D47A1))),
                const SizedBox(width: 12),
                Expanded(child: _QuickBtn(icon: Icons.flash_on, label: 'Lumpsum', desc: 'One-time invest', color: const Color(0xFF6A1B9A))),
              ]),
            ),
          ),

          // Fund Categories
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.md, ESUNSpacing.lg, ESUNSpacing.md),
              child: Text('Browse by Category', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
                children: [
                  _CategoryChip('Equity', true), _CategoryChip('Debt', false), _CategoryChip('Hybrid', false),
                  _CategoryChip('Index', false), _CategoryChip('ELSS', false), _CategoryChip('Liquid', false),
                ],
              ),
            ),
          ),

          // Top Performing
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.xl, ESUNSpacing.lg, ESUNSpacing.sm),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Top Performers', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                Text('See All', style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.primary, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _FundCard(name: 'Quant Small Cap Fund', category: 'Equity - Small Cap', return3y: '32.4%', return1y: '18.7%', rating: 5, aum: '₹8,200 Cr', minSip: '₹1,000'),
                _FundCard(name: 'Parag Parikh Flexi Cap', category: 'Equity - Flexi Cap', return3y: '22.1%', return1y: '15.3%', rating: 5, aum: '₹46,500 Cr', minSip: '₹1,000'),
                _FundCard(name: 'Mirae Asset Large Cap', category: 'Equity - Large Cap', return3y: '18.5%', return1y: '13.2%', rating: 4, aum: '₹35,200 Cr', minSip: '₹500'),
                _FundCard(name: 'HDFC Mid-Cap Opportunities', category: 'Equity - Mid Cap', return3y: '28.7%', return1y: '21.4%', rating: 5, aum: '₹42,100 Cr', minSip: '₹100'),
                _FundCard(name: 'SBI Equity Hybrid Fund', category: 'Hybrid - Aggressive', return3y: '15.2%', return1y: '11.8%', rating: 4, aum: '₹62,300 Cr', minSip: '₹500'),
                _FundCard(name: 'Axis Bluechip Fund', category: 'Equity - Large Cap', return3y: '14.8%', return1y: '12.1%', rating: 4, aum: '₹28,400 Cr', minSip: '₹500'),
              ]),
            ),
          ),

          // Tax-Saving CTA
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.xl, ESUNSpacing.lg, 80),
              child: Container(
                padding: const EdgeInsets.all(ESUNSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Save Tax with ELSS', style: ESUNTypography.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Save up to ₹46,800 under Section 80C', style: ESUNTypography.bodySmall.copyWith(color: Colors.white70)),
                  ])),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.savings, color: Colors.white, size: 26),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label, desc;
  final Color color;
  const _QuickBtn({required this.icon, required this.label, required this.desc, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: ESUNTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
          Text(desc, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
        ]),
      ]),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  const _CategoryChip(this.label, this.selected);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? ESUNColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? ESUNColors.primary : Colors.grey.withOpacity(0.3)),
      ),
      child: Text(label, style: ESUNTypography.bodySmall.copyWith(color: selected ? Colors.white : ESUNColors.textSecondary, fontWeight: FontWeight.w600)),
    );
  }
}

class _FundCard extends StatelessWidget {
  final String name, category, return3y, return1y, aum, minSip;
  final int rating;
  const _FundCard({required this.name, required this.category, required this.return3y, required this.return1y, required this.rating, required this.aum, required this.minSip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: ESUNTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(category, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
          ])),
          Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) => Icon(Icons.star, color: i < rating ? Colors.amber : Colors.grey[300], size: 14))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _FundStat('3Y Returns', return3y, Colors.green),
          _FundStat('1Y Returns', return1y, Colors.green),
          _FundStat('AUM', aum, null),
          _FundStat('Min SIP', minSip, null),
        ]),
      ]),
    );
  }
}

class _FundStat extends StatelessWidget {
  final String label, value;
  final Color? valColor;
  const _FundStat(this.label, this.value, this.valColor);

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Text(label, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary, fontSize: 10)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: valColor)),
    ]));
  }
}
