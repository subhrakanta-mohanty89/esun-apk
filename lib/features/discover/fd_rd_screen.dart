/// ESUN FD/RD Screen — Fixed & Recurring Deposits
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class FdRdScreen extends StatelessWidget {
  const FdRdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ESUNColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200, pinned: true,
            backgroundColor: const Color(0xFF4A148C),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF4A148C), Color(0xFF6A1B9A), Color(0xFF8E24AA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(ESUNSpacing.xl),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.lock_clock, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: ESUNSpacing.md),
                      Text('FD / RD', style: ESUNTypography.headlineLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Guaranteed returns with fixed deposits', style: ESUNTypography.bodyMedium.copyWith(color: Colors.white70)),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          // Rate Highlights
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(ESUNSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Top FD Rates Today', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _RateChip('1 Year', '7.25%', const Color(0xFF4A148C))),
                    const SizedBox(width: 10),
                    Expanded(child: _RateChip('2 Years', '7.50%', const Color(0xFF6A1B9A))),
                    const SizedBox(width: 10),
                    Expanded(child: _RateChip('5 Years', '7.75%', const Color(0xFF8E24AA))),
                  ]),
                ]),
              ),
            ),
          ),

          // FD Options
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.md, ESUNSpacing.lg, ESUNSpacing.sm),
              child: Text('Fixed Deposits', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _FdCard(bank: 'Bajaj Finance', rate: '8.25%', tenure: '12-60 months', minAmt: '₹15,000', tag: 'Highest Rate', tagColor: Colors.green),
                _FdCard(bank: 'SBI', rate: '7.10%', tenure: '7 days - 10 yrs', minAmt: '₹1,000', tag: 'Govt Backed', tagColor: Colors.blue),
                _FdCard(bank: 'HDFC Bank', rate: '7.25%', tenure: '7 days - 10 yrs', minAmt: '₹5,000', tag: 'Popular', tagColor: Colors.purple),
                _FdCard(bank: 'ICICI Bank', rate: '7.10%', tenure: '7 days - 10 yrs', minAmt: '₹10,000', tag: 'iWish Flex', tagColor: Colors.orange),
                _FdCard(bank: 'Shriram Finance', rate: '8.05%', tenure: '12-60 months', minAmt: '₹5,000', tag: 'Top NBFC', tagColor: Colors.teal),
              ]),
            ),
          ),

          // RD Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.xxl, ESUNSpacing.lg, ESUNSpacing.sm),
              child: Text('Recurring Deposits', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
                children: [
                  _RdCard(bank: 'SBI', rate: '6.80%', minAmt: '₹100/mo', color: const Color(0xFF1565C0)),
                  _RdCard(bank: 'HDFC', rate: '7.00%', minAmt: '₹500/mo', color: const Color(0xFF4A148C)),
                  _RdCard(bank: 'Axis Bank', rate: '7.10%', minAmt: '₹500/mo', color: const Color(0xFF880E4F)),
                  _RdCard(bank: 'ICICI', rate: '6.90%', minAmt: '₹1,000/mo', color: const Color(0xFFE65100)),
                ],
              ),
            ),
          ),

          // Calculator CTA
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.xxl, ESUNSpacing.lg, 80),
              child: Container(
                padding: const EdgeInsets.all(ESUNSpacing.xl),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('FD Calculator', style: ESUNTypography.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Calculate your maturity amount', style: ESUNTypography.bodyMedium.copyWith(color: Colors.white70)),
                  ])),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.calculate, color: Colors.white, size: 28),
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

class _RateChip extends StatelessWidget {
  final String tenure, rate;
  final Color color;
  const _RateChip(this.tenure, this.rate, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(tenure, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
        const SizedBox(height: 4),
        Text(rate, style: ESUNTypography.titleMedium.copyWith(color: color, fontWeight: FontWeight.bold)),
        Text('p.a.', style: ESUNTypography.labelSmall.copyWith(color: color)),
      ]),
    );
  }
}

class _FdCard extends StatelessWidget {
  final String bank, rate, tenure, minAmt, tag;
  final Color tagColor;
  const _FdCard({required this.bank, required this.rate, required this.tenure, required this.minAmt, required this.tag, required this.tagColor});

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
          width: 44, height: 44,
          decoration: BoxDecoration(color: Colors.purple.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.account_balance, color: Color(0xFF6A1B9A), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(bank, style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: tagColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(tag, style: TextStyle(color: tagColor, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 4),
          Text('$tenure • Min $minAmt', style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(rate, style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF4A148C))),
          Text('p.a.', style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
        ]),
      ]),
    );
  }
}

class _RdCard extends StatelessWidget {
  final String bank, rate, minAmt;
  final Color color;
  const _RdCard({required this.bank, required this.rate, required this.minAmt, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160, margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(bank, style: ESUNTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(rate, style: ESUNTypography.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          Text(minAmt, style: ESUNTypography.bodySmall.copyWith(color: Colors.white70)),
        ]),
      ]),
    );
  }
}
