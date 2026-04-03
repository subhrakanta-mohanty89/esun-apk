/// ESUN Fixed Deposits Screen (Investment Product)
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class FixedDepositsScreen extends StatelessWidget {
  const FixedDepositsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ESUNColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200, pinned: true,
            backgroundColor: const Color(0xFF33691E),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF33691E), Color(0xFF558B2F), Color(0xFF689F38)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(ESUNSpacing.xl),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.savings, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: ESUNSpacing.md),
                      Text('Fixed Deposits', style: ESUNTypography.headlineLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Compare & book FDs from top partners', style: ESUNTypography.bodyMedium.copyWith(color: Colors.white70)),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          // Rate Comparison
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(ESUNSpacing.lg),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Best FD Rates', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text('Updated today', style: ESUNTypography.labelSmall.copyWith(color: Colors.green, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  _RateRow('Bajaj Finance', '8.25%', '12-60 mo', true),
                  _RateRow('Shriram Finance', '8.05%', '12-60 mo', false),
                  _RateRow('Mahindra Finance', '7.95%', '12-60 mo', false),
                  _RateRow('HDFC Bank', '7.25%', '7d - 10y', false),
                  _RateRow('SBI', '7.10%', '7d - 10y', false),
                ]),
              ),
            ),
          ),

          // FD Types
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.md, ESUNSpacing.lg, ESUNSpacing.md),
              child: Text('FD Types', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.25),
              delegate: SliverChildListDelegate([
                _TypeCard(icon: Icons.lock, name: 'Regular FD', desc: 'Lock-in with higher rates', rate: 'Up to 8.25%', color: const Color(0xFF33691E)),
                _TypeCard(icon: Icons.elderly, name: 'Senior Citizen', desc: 'Extra 0.50% for 60+', rate: 'Up to 8.75%', color: const Color(0xFF6A1B9A)),
                _TypeCard(icon: Icons.receipt_long, name: 'Tax Saver FD', desc: '80C deduction, 5yr lock-in', rate: 'Up to 7.50%', color: const Color(0xFF1565C0)),
                _TypeCard(icon: Icons.flash_on, name: 'Flexi FD', desc: 'Withdraw anytime, FD rates', rate: 'Up to 7.00%', color: const Color(0xFFE65100)),
              ]),
            ),
          ),

          // Calculator
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.xxl, ESUNSpacing.lg, ESUNSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(ESUNSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF33691E), Color(0xFF558B2F)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.calculate, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('FD Maturity Calculator', style: ESUNTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('Calculate returns before investing', style: ESUNTypography.bodySmall.copyWith(color: Colors.white70)),
                  ])),
                  const Icon(Icons.chevron_right, color: Colors.white60),
                ]),
              ),
            ),
          ),

          // FAQs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.md, ESUNSpacing.lg, ESUNSpacing.sm),
              child: Text('Common Questions', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, 0, ESUNSpacing.lg, 80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _FaqTile('Is my money safe in FD?', 'Bank FDs up to ₹5L are insured by DICGC.'),
                _FaqTile('Can I break an FD early?', 'Yes, with a small penalty — usually 0.5-1% lower rate.'),
                _FaqTile('Which FD tenure gives best returns?', '2-3 year tenures typically offer the best rates.'),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  final String bank, rate, tenure;
  final bool isBest;
  const _RateRow(this.bank, this.rate, this.tenure, this.isBest);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          Text(bank, style: ESUNTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
          if (isBest) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(3)),
              child: Text('BEST', style: TextStyle(color: Colors.green[700], fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ],
        ])),
        Expanded(child: Text(rate, style: ESUNTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF33691E)))),
        Text(tenure, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
      ]),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String name, desc, rate;
  final Color color;
  const _TypeCard({required this.icon, required this.name, required this.desc, required this.rate, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: ESUNTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          Text(desc, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
        ]),
        Text(rate, style: ESUNTypography.bodySmall.copyWith(color: Colors.green, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String q, a;
  const _FaqTile(this.q, this.a);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.help_outline, size: 16, color: Color(0xFF33691E)),
          const SizedBox(width: 8),
          Expanded(child: Text(q, style: ESUNTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text(a, style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
        ),
      ]),
    );
  }
}
