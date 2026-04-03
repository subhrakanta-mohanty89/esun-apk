/// ESUN Digital Gold Screen (Investment Product)
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class DigitalGoldScreen extends StatelessWidget {
  const DigitalGoldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ESUNColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220, pinned: true,
            backgroundColor: const Color(0xFFBF360C),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFBF360C), Color(0xFFE65100), Color(0xFFFF6D00)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(ESUNSpacing.xl),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.monetization_on, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: ESUNSpacing.md),
                      Text('Digital Gold', style: ESUNTypography.headlineLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Buy 99.9% pure gold, starting ₹10', style: ESUNTypography.bodyMedium.copyWith(color: Colors.white.withOpacity(0.85))),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          // Live Price + Buy/Sell
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(ESUNSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(children: [
                  Row(children: [
                    const Icon(Icons.diamond, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text('24K Gold (99.9% pure)', style: ESUNTypography.bodySmall.copyWith(color: Colors.white60)),
                  ]),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Buy Price', style: ESUNTypography.labelSmall.copyWith(color: Colors.white54)),
                      Text('₹7,248/gm', style: ESUNTypography.titleLarge.copyWith(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                    ]),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('Sell Price', style: ESUNTypography.labelSmall.copyWith(color: Colors.white54)),
                      Text('₹7,210/gm', style: ESUNTypography.titleLarge.copyWith(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ]),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: ElevatedButton.icon(
                      onPressed: () {}, icon: const Icon(Icons.add, size: 18),
                      label: const Text('Buy Gold'), style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: OutlinedButton.icon(
                      onPressed: () {}, icon: const Icon(Icons.remove, size: 18),
                      label: const Text('Sell Gold'), style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    )),
                  ]),
                ]),
              ),
            ),
          ),

          // Gold SIP
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(ESUNSpacing.lg),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.amber.withOpacity(0.2))),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.autorenew, color: Colors.amber, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Gold SIP', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                    Text('Auto-invest from ₹100/month in 24K gold', style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)),
                    child: Text('Start', style: ESUNTypography.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ]),
              ),
            ),
          ),

          // Features
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.xxl, ESUNSpacing.lg, ESUNSpacing.md),
              child: Text('Why Digital Gold?', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.2),
              delegate: SliverChildListDelegate([
                _FeatureCard(icon: Icons.verified, title: '99.9% Pure', desc: 'Hallmarked 24K gold', color: Colors.amber),
                _FeatureCard(icon: Icons.security, title: 'Insured Storage', desc: 'Stored in MMTC vaults', color: const Color(0xFF1565C0)),
                _FeatureCard(icon: Icons.local_shipping, title: 'Home Delivery', desc: 'Get coins & bars delivered', color: const Color(0xFF2E7D32)),
                _FeatureCard(icon: Icons.currency_rupee, title: 'Start ₹10', desc: 'No minimum quantity', color: const Color(0xFFE65100)),
              ]),
            ),
          ),

          // How It Works
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.xxl, ESUNSpacing.lg, ESUNSpacing.md),
              child: Text('How It Works', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, 0, ESUNSpacing.lg, 80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _StepTile(step: '1', title: 'Choose amount', desc: 'Enter ₹ amount or grams you want to buy'),
                _StepTile(step: '2', title: 'Pay securely', desc: 'UPI, net banking, or debit card'),
                _StepTile(step: '3', title: 'Gold is stored', desc: 'Securely vaulted & insured by MMTC-PAMP'),
                _StepTile(step: '4', title: 'Sell or deliver', desc: 'Sell anytime or get physical gold delivered'),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  final Color color;
  const _FeatureCard({required this.icon, required this.title, required this.desc, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 10),
        Text(title, style: ESUNTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(desc, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
      ]),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String step, title, desc;
  const _StepTile({required this.step, required this.title, required this.desc});

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
          width: 36, height: 36,
          decoration: BoxDecoration(color: const Color(0xFFBF360C).withOpacity(0.1), borderRadius: BorderRadius.circular(18)),
          child: Center(child: Text(step, style: const TextStyle(color: Color(0xFFBF360C), fontWeight: FontWeight.bold, fontSize: 16))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: ESUNTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
          Text(desc, style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
        ])),
      ]),
    );
  }
}
