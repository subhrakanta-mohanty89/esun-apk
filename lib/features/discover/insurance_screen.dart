/// ESUN Insurance Screen — Manage & Explore Insurance
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../state/aa_data_state.dart';

class InsuranceScreen extends ConsumerWidget {
  const InsuranceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policies = ref.watch(aaDataProvider).insurances;

    return Scaffold(
      backgroundColor: ESUNColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero
          SliverAppBar(
            expandedHeight: 200, pinned: true,
            backgroundColor: const Color(0xFFE65100),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFE65100), Color(0xFFFF6D00), Color(0xFFFF9100)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(ESUNSpacing.xl),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.shield, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: ESUNSpacing.md),
                      Text('Insurance', style: ESUNTypography.headlineLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Secure your family & assets', style: ESUNTypography.bodyMedium.copyWith(color: Colors.white70)),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          // My Policies
          if (policies.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.xl, ESUNSpacing.lg, ESUNSpacing.sm),
                child: Text('My Policies', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 170,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
                  itemCount: policies.length,
                  itemBuilder: (_, i) {
                    final p = policies[i];
                    final expired = p.status.toLowerCase().contains('expir');
                    return Container(
                      width: 260, margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(ESUNSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: expired ? [const Color(0xFFE53935), const Color(0xFFEF5350)] : [const Color(0xFF2E7D32), const Color(0xFF43A047)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Row(children: [
                          Expanded(child: Text(p.type.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w).join(' '), style: ESUNTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                            child: Text(expired ? 'EXPIRED' : 'ACTIVE', style: ESUNTypography.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ]),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.providerName, style: ESUNTypography.bodySmall.copyWith(color: Colors.white70)),
                          const SizedBox(height: 4),
                          Text('Coverage ₹${(p.sumAssured / 100000).toStringAsFixed(1)}L', style: ESUNTypography.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('Premium ₹${p.premiumAmount.toStringAsFixed(0)}/${p.premiumFrequency}', style: ESUNTypography.bodySmall.copyWith(color: Colors.white70)),
                        ]),
                      ]),
                    );
                  },
                ),
              ),
            ),
          ],

          // Insurance Categories
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.xxl, ESUNSpacing.lg, ESUNSpacing.md),
              child: Text('Explore Insurance', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.85),
              delegate: SliverChildListDelegate([
                _CategoryCard(icon: Icons.favorite, name: 'Health', desc: 'From ₹400/mo', color: const Color(0xFFE53935)),
                _CategoryCard(icon: Icons.family_restroom, name: 'Life', desc: 'From ₹500/mo', color: const Color(0xFF1565C0)),
                _CategoryCard(icon: Icons.directions_car, name: 'Motor', desc: 'From ₹200/mo', color: const Color(0xFF00695C)),
                _CategoryCard(icon: Icons.flight, name: 'Travel', desc: 'From ₹50/trip', color: const Color(0xFF6A1B9A)),
                _CategoryCard(icon: Icons.home, name: 'Home', desc: 'From ₹250/mo', color: const Color(0xFFFF6F00)),
                _CategoryCard(icon: Icons.business_center, name: 'Business', desc: 'Customised', color: const Color(0xFF37474F)),
              ]),
            ),
          ),

          // Featured Plans
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.xxl, ESUNSpacing.lg, ESUNSpacing.sm),
              child: Text('Featured Plans', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, 0, ESUNSpacing.lg, 80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _FeaturedPlan(insurer: 'Star Health', plan: 'Family Floater', cover: '₹10L', premium: '₹1,200/mo', rating: 4.5, claimRatio: '92%'),
                _FeaturedPlan(insurer: 'HDFC Life', plan: 'Click 2 Protect', cover: '₹1Cr', premium: '₹700/mo', rating: 4.6, claimRatio: '98%'),
                _FeaturedPlan(insurer: 'ICICI Lombard', plan: 'Motor Shield', cover: 'IDV Based', premium: '₹450/mo', rating: 4.3, claimRatio: '95%'),
                _FeaturedPlan(insurer: 'Max Life', plan: 'Smart Secure Plus', cover: '₹75L', premium: '₹580/mo', rating: 4.7, claimRatio: '99%'),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String name, desc;
  final Color color;
  const _CategoryCard({required this.icon, required this.name, required this.desc, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(name, style: ESUNTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(desc, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
      ]),
    );
  }
}

class _FeaturedPlan extends StatelessWidget {
  final String insurer, plan, cover, premium, claimRatio;
  final double rating;
  const _FeaturedPlan({required this.insurer, required this.plan, required this.cover, required this.premium, required this.rating, required this.claimRatio});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFE65100).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.shield, color: Color(0xFFE65100), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(plan, style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
            Text(insurer, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 2),
              Text(rating.toString(), style: ESUNTypography.labelSmall.copyWith(fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _PlanStat('Cover', cover),
          _PlanStat('Premium', premium),
          _PlanStat('Claim Ratio', claimRatio),
        ]),
      ]),
    );
  }
}

class _PlanStat extends StatelessWidget {
  final String label, value;
  const _PlanStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Text(label, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
      const SizedBox(height: 2),
      Text(value, style: ESUNTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
    ]));
  }
}
