/// ESUN Loans Screen — All Loan Products
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../state/aa_data_state.dart';

class LoansScreen extends ConsumerWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLoans = ref.watch(aaDataProvider).loans;

    return Scaffold(
      backgroundColor: ESUNColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200, pinned: true,
            backgroundColor: const Color(0xFF1B5E20),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(ESUNSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.account_balance, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: ESUNSpacing.md),
                        Text('Loans', style: ESUNTypography.headlineLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Explore loan options & manage active loans', style: ESUNTypography.bodyMedium.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Active Loans
          if (activeLoans.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.xl, ESUNSpacing.lg, ESUNSpacing.sm),
                child: Text('Active Loans', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final loan = activeLoans[i];
                    return _ActiveLoanCard(
                      type: loan.type, lender: loan.lenderName,
                      outstanding: loan.outstandingAmount, emi: loan.emiAmount,
                      rate: loan.interestRate, remaining: loan.remainingTenure ?? 0,
                    );
                  },
                  childCount: activeLoans.length,
                ),
              ),
            ),
          ],

          // Loan Products
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.xxl, ESUNSpacing.lg, ESUNSpacing.sm),
              child: Text('Explore Loan Products', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.1,
              ),
              delegate: SliverChildListDelegate([
                _LoanProductCard(icon: Icons.home, name: 'Home Loan', rate: 'From 8.35%', maxAmt: 'Up to ₹5Cr', color: const Color(0xFF1565C0)),
                _LoanProductCard(icon: Icons.person, name: 'Personal Loan', rate: 'From 10.49%', maxAmt: 'Up to ₹40L', color: const Color(0xFF6A1B9A)),
                _LoanProductCard(icon: Icons.directions_car, name: 'Car Loan', rate: 'From 8.70%', maxAmt: 'Up to ₹1Cr', color: const Color(0xFF00695C)),
                _LoanProductCard(icon: Icons.school, name: 'Education Loan', rate: 'From 7.25%', maxAmt: 'Up to ₹75L', color: const Color(0xFFE65100)),
                _LoanProductCard(icon: Icons.business, name: 'Business Loan', rate: 'From 14%', maxAmt: 'Up to ₹2Cr', color: const Color(0xFF37474F)),
                _LoanProductCard(icon: Icons.diamond, name: 'Gold Loan', rate: 'From 7.50%', maxAmt: 'Up to ₹1.5Cr', color: const Color(0xFFF57F17)),
              ]),
            ),
          ),

          // Quick Tools
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: ESUNSpacing.md),
                  Text('Quick Tools', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: ESUNSpacing.md),
                  _QuickToolTile(icon: Icons.calculate, title: 'EMI Calculator', subtitle: 'Calculate your monthly EMI', color: Colors.blue),
                  _QuickToolTile(icon: Icons.compare_arrows, title: 'Compare Loans', subtitle: 'Find the best rates across banks', color: Colors.green),
                  _QuickToolTile(icon: Icons.check_circle, title: 'Check Eligibility', subtitle: 'Pre-qualify without affecting your score', color: Colors.purple),
                  _QuickToolTile(icon: Icons.receipt_long, title: 'Loan Statement', subtitle: 'Download statements for tax filing', color: Colors.orange),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _ActiveLoanCard extends StatelessWidget {
  final String type, lender;
  final double outstanding, emi, rate;
  final int remaining;
  const _ActiveLoanCard({required this.type, required this.lender, required this.outstanding, required this.emi, required this.rate, required this.remaining});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: ESUNColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(_iconFor(type), color: ESUNColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(type.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w).join(' '), style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
              Text(lender, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('₹${(outstanding / 1000).toStringAsFixed(0)}K', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
              Text('outstanding', style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
            ]),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _LoanStat('EMI', '₹${emi.toStringAsFixed(0)}'),
            _LoanStat('Rate', '${rate.toStringAsFixed(1)}%'),
            _LoanStat('Remaining', '$remaining months'),
          ]),
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
    final t = type.toLowerCase();
    if (t.contains('home')) return Icons.home;
    if (t.contains('car')) return Icons.directions_car;
    if (t.contains('personal')) return Icons.person;
    if (t.contains('credit')) return Icons.credit_card;
    return Icons.account_balance;
  }
}

class _LoanStat extends StatelessWidget {
  final String label, value;
  const _LoanStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Text(label, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
      Text(value, style: ESUNTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
    ]));
  }
}

class _LoanProductCard extends StatelessWidget {
  final IconData icon;
  final String name, rate, maxAmt;
  final Color color;
  const _LoanProductCard({required this.icon, required this.name, required this.rate, required this.maxAmt, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          Text(name, style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(rate, style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.success, fontWeight: FontWeight.w600)),
            Text(maxAmt, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
          ]),
        ],
      ),
    );
  }
}

class _QuickToolTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  const _QuickToolTile({required this.icon, required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: ESUNTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
          Text(subtitle, style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
        ])),
        Icon(Icons.chevron_right, color: Colors.grey[400]),
      ]),
    );
  }
}
