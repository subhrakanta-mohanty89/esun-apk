/// ESUN More Screen — Additional Categories
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';

class MoreCategoriesScreen extends StatelessWidget {
  const MoreCategoriesScreen({super.key});

  static const _categories = [
    _Cat('Tax Planning', Icons.receipt_long, 'Save tax with 80C/80D', Color(0xFF1565C0)),
    _Cat('Budget Planner', Icons.pie_chart, 'Track income & expenses', Color(0xFF2E7D32)),
    _Cat('Credit Score', Icons.speed, 'Free monthly score check', Color(0xFFE65100)),
    _Cat('Bill Payments', Icons.payments, 'Electricity, gas, broadband', Color(0xFF6A1B9A)),
    _Cat('Rewards Store', Icons.card_giftcard, 'Redeem points for gifts', Color(0xFFC62828)),
    _Cat('Refer & Earn', Icons.group_add, 'Earn ₹500 per referral', Color(0xFF00695C)),
    _Cat('Bonds', Icons.account_balance, 'Govt & corporate bonds', Color(0xFF37474F)),
    _Cat('NPS', Icons.elderly, 'National Pension System', Color(0xFF4A148C)),
    _Cat('PPF', Icons.savings, 'Public Provident Fund', Color(0xFF0D47A1)),
    _Cat('Forex', Icons.currency_exchange, 'Buy & sell foreign currency', Color(0xFFF57F17)),
    _Cat('Health Plans', Icons.favorite, 'Compare health insurance', Color(0xFFE53935)),
    _Cat('Gift Cards', Icons.redeem, 'Amazon, Flipkart & more', Color(0xFF880E4F)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ESUNColors.background,
      appBar: AppBar(
        backgroundColor: ESUNColors.primary,
        foregroundColor: Colors.white,
        title: const Text('More'),
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Search
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Row(children: [
                  Icon(Icons.search, color: Colors.grey[400]),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(
                    decoration: InputDecoration(hintText: 'Search services...', hintStyle: TextStyle(color: Colors.grey[400]), border: InputBorder.none),
                  )),
                ]),
              ),
            ),
          ),

          // Grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, 0, ESUNSpacing.lg, 80),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.82),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final c = _categories[i];
                  return GestureDetector(
                    onTap: () => _showComingSoon(context, c.name),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: c.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Icon(c.icon, color: c.color, size: 26),
                        ),
                        const SizedBox(height: 10),
                        Text(c.name, style: ESUNTypography.bodySmall.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(c.desc, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary, fontSize: 9), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                  );
                },
                childCount: _categories.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name — Coming Soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _Cat {
  final String name, desc;
  final IconData icon;
  final Color color;
  const _Cat(this.name, this.icon, this.desc, this.color);
}
