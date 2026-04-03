/// ESUN Cards Screen — Credit & Debit Card Products
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../state/aa_data_state.dart';

class CardsScreen extends ConsumerWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loans = ref.watch(aaDataProvider).loans;
    final creditCards = loans.where((l) => l.type.toLowerCase().contains('credit')).toList();

    return Scaffold(
      backgroundColor: ESUNColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF1A237E),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
                  ),
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
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.credit_card, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: ESUNSpacing.md),
                        Text('Cards', style: ESUNTypography.headlineLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Manage & explore credit cards', style: ESUNTypography.bodyMedium.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // My Cards section
          if (creditCards.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.xl, ESUNSpacing.lg, ESUNSpacing.sm),
                child: Text('My Cards', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
                  scrollDirection: Axis.horizontal,
                  itemCount: creditCards.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final card = creditCards[i];
                    return _CreditCardWidget(
                      bankName: card.lenderName,
                      cardNumber: card.accountNumber,
                      outstanding: card.outstandingAmount,
                      limit: card.principalAmount,
                    );
                  },
                ),
              ),
            ),
          ],

          // Recommended Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.xxl, ESUNSpacing.lg, ESUNSpacing.sm),
              child: Row(
                children: [
                  Text('Recommended for You', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('View All', style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.primary)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _RecommendedCard(
                  name: 'HDFC Millennia',
                  issuer: 'HDFC Bank',
                  benefit: '5% Cashback on Amazon, Flipkart',
                  fee: '₹1,000/yr (waived on ₹1L spend)',
                  color: const Color(0xFF1A237E),
                  rating: 4.5,
                ),
                const SizedBox(height: 12),
                _RecommendedCard(
                  name: 'SBI SimplyCLICK',
                  issuer: 'SBI Card',
                  benefit: '10X rewards on partner brands',
                  fee: '₹499/yr',
                  color: const Color(0xFF1B5E20),
                  rating: 4.3,
                ),
                const SizedBox(height: 12),
                _RecommendedCard(
                  name: 'Axis Flipkart',
                  issuer: 'Axis Bank',
                  benefit: '5% unlimited cashback on Flipkart',
                  fee: '₹500/yr',
                  color: const Color(0xFF4A148C),
                  rating: 4.4,
                ),
                const SizedBox(height: 12),
                _RecommendedCard(
                  name: 'ICICI Amazon Pay',
                  issuer: 'ICICI Bank',
                  benefit: '5% back on Amazon for Prime members',
                  fee: 'Lifetime free',
                  color: const Color(0xFFE65100),
                  rating: 4.6,
                ),
              ]),
            ),
          ),

          // Card Benefits Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: ESUNSpacing.md),
                  Text('Why get a Credit Card?', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: ESUNSpacing.md),
                  _BenefitTile(icon: Icons.monetization_on, title: 'Earn Rewards', subtitle: 'Get cashback & reward points on every spend', color: Colors.amber),
                  _BenefitTile(icon: Icons.shield, title: 'Purchase Protection', subtitle: 'Buyer protection & insurance on purchases', color: Colors.blue),
                  _BenefitTile(icon: Icons.trending_up, title: 'Build Credit Score', subtitle: 'Responsible usage improves your CIBIL score', color: Colors.green),
                  _BenefitTile(icon: Icons.flight, title: 'Travel Benefits', subtitle: 'Airport lounge access & travel insurance', color: Colors.purple),
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

class _CreditCardWidget extends StatelessWidget {
  final String bankName;
  final String cardNumber;
  final double outstanding;
  final double limit;

  const _CreditCardWidget({
    required this.bankName, required this.cardNumber,
    required this.outstanding, required this.limit,
  });

  @override
  Widget build(BuildContext context) {
    final utilization = limit > 0 ? (outstanding / limit) : 0.0;
    return Container(
      width: 300,
      padding: const EdgeInsets.all(ESUNSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(bankName, style: ESUNTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
              const Icon(Icons.contactless, color: Colors.white54, size: 28),
            ],
          ),
          const Spacer(),
          Text(cardNumber, style: ESUNTypography.titleLarge.copyWith(color: Colors.white, letterSpacing: 2)),
          const SizedBox(height: ESUNSpacing.md),
          Row(
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Outstanding', style: ESUNTypography.labelSmall.copyWith(color: Colors.white54)),
                Text('₹${outstanding.toStringAsFixed(0)}', style: ESUNTypography.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              ]),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Utilization', style: ESUNTypography.labelSmall.copyWith(color: Colors.white54)),
                Text('${(utilization * 100).toStringAsFixed(0)}%', style: ESUNTypography.bodyLarge.copyWith(
                  color: utilization > 0.7 ? Colors.redAccent : Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                )),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  final String name, issuer, benefit, fee;
  final Color color;
  final double rating;
  const _RecommendedCard({required this.name, required this.issuer, required this.benefit, required this.fee, required this.color, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.credit_card, color: color, size: 28),
          ),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(name, style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 2),
                  Text(rating.toString(), style: ESUNTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
                ]),
                Text(issuer, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
                const SizedBox(height: 4),
                Text(benefit, style: ESUNTypography.bodySmall.copyWith(color: color, fontWeight: FontWeight.w500)),
                Text(fee, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('Apply', style: ESUNTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  const _BenefitTile({required this.icon, required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.md),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: ESUNSpacing.md),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: ESUNTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
            Text(subtitle, style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
          ],
        )),
      ]),
    );
  }
}
