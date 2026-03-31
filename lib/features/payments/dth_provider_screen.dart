/// ESUN DTH Recharge Screen
///
/// Provider selection for DTH recharge with official logos,
/// saved connections, and plan selection.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../core/constants/brand_logos.dart';
import '../../shared/widgets/pay_via_apps.dart';
import 'bill_payment_screen.dart';

String? _getDthLogo(String key) => BrandLogos.brands[key];

// ============================================================================
// Data Models
// ============================================================================

class _DthProvider {
  final String name;
  final String shortName;
  final String tagline;
  final Color color;
  final String? logoUrl;
  final List<_DthPlan> popularPlans;

  const _DthProvider({
    required this.name,
    required this.shortName,
    required this.tagline,
    required this.color,
    this.logoUrl,
    this.popularPlans = const [],
  });
}

class _DthPlan {
  final String name;
  final String price;
  final String channels;
  final String validity;

  const _DthPlan({
    required this.name,
    required this.price,
    required this.channels,
    required this.validity,
  });
}

class _SavedDth {
  final String name;
  final String subscriberId;
  final String provider;
  final Color providerColor;
  final String? logoUrl;
  final String lastRecharge;
  final String lastAmount;
  final String planName;
  final bool isExpiringSoon;

  const _SavedDth({
    required this.name,
    required this.subscriberId,
    required this.provider,
    required this.providerColor,
    this.logoUrl,
    required this.lastRecharge,
    required this.lastAmount,
    required this.planName,
    this.isExpiringSoon = false,
  });
}

// ============================================================================
// Screen
// ============================================================================

class DthProviderScreen extends ConsumerStatefulWidget {
  const DthProviderScreen({super.key});

  @override
  ConsumerState<DthProviderScreen> createState() => _DthProviderScreenState();
}

class _DthProviderScreenState extends ConsumerState<DthProviderScreen> {
  static final _providers = [
    _DthProvider(
      name: 'Tata Play',
      shortName: 'Tata Play',
      tagline: 'Isko laga dala to life jingalala',
      color: const Color(0xFF6A1B9A),
      logoUrl: _getDthLogo('tata play'),
      popularPlans: const [
        _DthPlan(
            name: 'Hindi Lite',
            price: '₹249',
            channels: '200+',
            validity: '1 Month'),
        _DthPlan(
            name: 'Hindi Smart',
            price: '₹399',
            channels: '300+',
            validity: '1 Month'),
        _DthPlan(
            name: 'Hindi Premium',
            price: '₹599',
            channels: '400+',
            validity: '1 Month'),
      ],
    ),
    _DthProvider(
      name: 'Airtel Digital TV',
      shortName: 'Airtel DTH',
      tagline: 'Entertainment ka baap',
      color: const Color(0xFFED1C24),
      logoUrl: _getDthLogo('airtel dth'),
      popularPlans: const [
        _DthPlan(
            name: 'Value Lite HD',
            price: '₹265',
            channels: '220+',
            validity: '1 Month'),
        _DthPlan(
            name: 'Popular HD',
            price: '₹408',
            channels: '280+',
            validity: '1 Month'),
      ],
    ),
    _DthProvider(
      name: 'Dish TV',
      shortName: 'Dish TV',
      tagline: 'Jingalala Entertainment',
      color: const Color(0xFFFF6F00),
      logoUrl: _getDthLogo('dish tv'),
      popularPlans: const [
        _DthPlan(
            name: 'Silver HD',
            price: '₹300',
            channels: '200+',
            validity: '1 Month'),
        _DthPlan(
            name: 'Titanium HD',
            price: '₹550',
            channels: '350+',
            validity: '1 Month'),
      ],
    ),
    _DthProvider(
      name: 'D2H',
      shortName: 'D2H',
      tagline: 'Seedhi baat, no bakwas',
      color: const Color(0xFF1565C0),
      logoUrl: _getDthLogo('d2h'),
      popularPlans: const [
        _DthPlan(
            name: 'Silver',
            price: '₹252',
            channels: '170+',
            validity: '1 Month'),
        _DthPlan(
            name: 'Gold',
            price: '₹440',
            channels: '280+',
            validity: '1 Month'),
      ],
    ),
    _DthProvider(
      name: 'Sun Direct',
      shortName: 'Sun Direct',
      tagline: 'South India\'s leading DTH',
      color: const Color(0xFFF9A825),
      logoUrl: _getDthLogo('sun direct'),
      popularPlans: const [
        _DthPlan(
            name: 'Prime Value',
            price: '₹231',
            channels: '155+',
            validity: '1 Month'),
        _DthPlan(
            name: 'Prime Premium',
            price: '₹499',
            channels: '310+',
            validity: '1 Month'),
      ],
    ),
  ];

  static final _savedDth = [
    _SavedDth(
      name: 'Living Room TV',
      subscriberId: '1004-8812-3345',
      provider: 'Tata Play',
      providerColor: const Color(0xFF6A1B9A),
      logoUrl: _getDthLogo('tata play'),
      lastRecharge: '12 Feb 2026',
      lastAmount: '₹449',
      planName: 'Hindi Smart HD',
      isExpiringSoon: true,
    ),
  ];

  void _navigateToRecharge(String provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillPaymentScreen(
          billType: 'DTH Recharge',
          icon: Icons.tv,
          color: const Color(0xFF7C4DFF),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ESUNColors.background,
      appBar: AppBar(
        backgroundColor: ESUNColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'DTH Recharge',
          style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderBanner(),
            if (_savedDth.isNotEmpty) _buildSavedDth(),
            _buildSectionHeader('Choose DTH Provider'),
            ..._providers.map((p) => _buildProviderCard(p)),
            const PayViaAppsSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ESUNSpacing.xl),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [ESUNColors.primary, ESUNColors.primaryLight],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.tv, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recharge your DTH',
                    style: ESUNTypography.titleLarge.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Select your DTH provider for quick recharge',
                    style: ESUNTypography.bodySmall
                        .copyWith(color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedDth() {
    return Column(
      children: [
        _buildSectionHeader('My DTH Connections'),
        ..._savedDth.map((dth) => _buildSavedDthCard(dth)),
      ],
    );
  }

  Widget _buildSavedDthCard(_SavedDth dth) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: dth.isExpiringSoon
            ? Border.all(color: const Color(0xFFFF6D00).withOpacity(0.5))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildProviderLogo(dth.providerColor, dth.provider,
                  logoUrl: dth.logoUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dth.name,
                        style: ESUNTypography.titleSmall
                            .copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('${dth.provider} • ${dth.subscriberId}',
                        style: ESUNTypography.bodySmall
                            .copyWith(color: ESUNColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text('Plan: ${dth.planName}',
                        style: ESUNTypography.bodySmall
                            .copyWith(color: ESUNColors.textTertiary)),
                    if (dth.isExpiringSoon)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6D00).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Expiring soon! Recharge now',
                            style: ESUNTypography.labelSmall.copyWith(
                                color: const Color(0xFFFF6D00),
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: 38,
                child: FilledButton(
                  onPressed: () => _navigateToRecharge(dth.provider),
                  style: FilledButton.styleFrom(
                    backgroundColor: ESUNColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 0),
                  ),
                  child: Text('Recharge',
                      style: ESUNTypography.labelMedium.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(_DthProvider provider) {
    return InkWell(
      onTap: () => _navigateToRecharge(provider.shortName),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildProviderLogo(provider.color, provider.shortName,
                    logoUrl: provider.logoUrl, size: 52),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(provider.name,
                          style: ESUNTypography.titleSmall
                              .copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(provider.tagline,
                          style: ESUNTypography.bodySmall
                              .copyWith(color: ESUNColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(ESUNSpacing.sm),
                  decoration: BoxDecoration(
                    color: provider.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chevron_right,
                      color: provider.color, size: 20),
                ),
              ],
            ),
            if (provider.popularPlans.isNotEmpty) ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: provider.popularPlans.map((plan) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: provider.color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: provider.color.withOpacity(0.2)),
                      ),
                      child: Text(
                        '${plan.name} ${plan.price}',
                        style: ESUNTypography.labelSmall.copyWith(
                          color: provider.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: ESUNColors.surfaceVariant,
      child: Text(
        title,
        style: ESUNTypography.titleSmall.copyWith(
          fontWeight: FontWeight.w600,
          color: ESUNColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildProviderLogo(Color color, String shortName,
      {String? logoUrl, double size = 44}) {
    if (logoUrl != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: ESUNColors.divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipOval(
          child: Padding(
            padding: EdgeInsets.all(size * 0.15),
            child: Image.network(
              logoUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  _buildFallbackLogo(color, shortName, size),
            ),
          ),
        ),
      );
    }
    return _buildFallbackLogo(color, shortName, size);
  }

  Widget _buildFallbackLogo(Color color, String shortName, double size) {
    final display =
        shortName.length > 2 ? shortName.substring(0, 2) : shortName;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Center(
        child: Text(
          display,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.28,
          ),
        ),
      ),
    );
  }
}
