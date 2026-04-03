/// ESUN Real Estate Screen — Property Investments
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class RealEstateScreen extends StatelessWidget {
  const RealEstateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ESUNColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200, pinned: true,
            backgroundColor: const Color(0xFF00695C),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF00695C), Color(0xFF00897B), Color(0xFF26A69A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(ESUNSpacing.xl),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.apartment, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: ESUNSpacing.md),
                      Text('Real Estate', style: ESUNTypography.headlineLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Invest in properties & earn rental yields', style: ESUNTypography.bodyMedium.copyWith(color: Colors.white70)),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          // Fractional Investment Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(ESUNSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.tealAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text('NEW', style: ESUNTypography.labelSmall.copyWith(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  Text('Fractional Real Estate', style: ESUNTypography.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Own a fraction of premium commercial properties starting ₹10,000', style: ESUNTypography.bodyMedium.copyWith(color: Colors.white70)),
                  const SizedBox(height: 14),
                  Row(children: [
                    _StatsChip('Avg Returns', '8-12% p.a.', Colors.tealAccent),
                    const SizedBox(width: 10),
                    _StatsChip('Min Investment', '₹10,000', Colors.amber),
                  ]),
                ]),
              ),
            ),
          ),

          // Featured Properties
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.md, ESUNSpacing.lg, ESUNSpacing.sm),
              child: Text('Featured Properties', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 230,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
                children: const [
                  _PropertyCard(name: 'Brigade Tech Gardens', location: 'Whitefield, Bangalore', type: 'Commercial Office', yield_: '9.2%', funded: 87, minAmt: '₹25,000', color: Color(0xFF00695C)),
                  _PropertyCard(name: 'DLF Cyber Hub', location: 'Gurugram, NCR', type: 'Retail Space', yield_: '8.5%', funded: 62, minAmt: '₹10,000', color: Color(0xFF1565C0)),
                  _PropertyCard(name: 'Embassy Manyata', location: 'Hebbal, Bangalore', type: 'Tech Park', yield_: '10.1%', funded: 94, minAmt: '₹50,000', color: Color(0xFF4A148C)),
                ],
              ),
            ),
          ),

          // Investment Types
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.xxl, ESUNSpacing.lg, ESUNSpacing.md),
              child: Text('Investment Types', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.15),
              delegate: SliverChildListDelegate([
                _TypeCard(icon: Icons.business, name: 'Commercial', desc: 'Offices & tech parks', yield_: '8-12%', color: const Color(0xFF00695C)),
                _TypeCard(icon: Icons.home_work, name: 'Residential', desc: 'Apartments & villas', yield_: '3-5%', color: const Color(0xFF1565C0)),
                _TypeCard(icon: Icons.store, name: 'Retail', desc: 'Shops & malls', yield_: '6-9%', color: const Color(0xFFE65100)),
                _TypeCard(icon: Icons.warehouse, name: 'Warehousing', desc: 'Logistics & storage', yield_: '7-10%', color: const Color(0xFF37474F)),
              ]),
            ),
          ),

          // REITs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.xxl, ESUNSpacing.lg, ESUNSpacing.sm),
              child: Text('REITs (Listed)', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, 0, ESUNSpacing.lg, 80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ReitTile(name: 'Embassy Office Parks', price: '₹345', change: '+1.2%', yield_: '6.8%', isUp: true),
                _ReitTile(name: 'Mindspace Business', price: '₹298', change: '-0.5%', yield_: '7.1%', isUp: false),
                _ReitTile(name: 'Brookfield India', price: '₹265', change: '+0.8%', yield_: '7.5%', isUp: true),
                _ReitTile(name: 'Nexus Select Trust', price: '₹138', change: '+2.1%', yield_: '6.3%', isUp: true),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatsChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: ESUNTypography.labelSmall.copyWith(color: color.withOpacity(0.8))),
        Text(value, style: ESUNTypography.bodyMedium.copyWith(color: color, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final String name, location, type, yield_, minAmt;
  final int funded;
  final Color color;
  const _PropertyCard({required this.name, required this.location, required this.type, required this.yield_, required this.funded, required this.minAmt, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250, margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(type, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
            const Spacer(),
            Text('$funded% funded', style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
          ]),
          const SizedBox(height: 12),
          Text(name, style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.location_on, size: 12, color: Colors.grey),
            const SizedBox(width: 2),
            Text(location, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
          ]),
        ]),
        Column(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: funded / 100, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation(color), minHeight: 4),
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Yield: $yield_', style: ESUNTypography.bodySmall.copyWith(color: Colors.green, fontWeight: FontWeight.w600)),
            Text('Min: $minAmt', style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
          ]),
        ]),
      ]),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String name, desc, yield_;
  final Color color;
  const _TypeCard({required this.icon, required this.name, required this.desc, required this.yield_, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
          Text(desc, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
        ]),
        Text('Yield: $yield_', style: ESUNTypography.bodySmall.copyWith(color: Colors.green, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _ReitTile extends StatelessWidget {
  final String name, price, change, yield_;
  final bool isUp;
  const _ReitTile({required this.name, required this.price, required this.change, required this.yield_, required this.isUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: const Color(0xFF00695C).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.apartment, color: Color(0xFF00695C), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: ESUNTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          Text('Yield: $yield_', style: ESUNTypography.labelSmall.copyWith(color: Colors.green)),
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
