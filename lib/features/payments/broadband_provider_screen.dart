/// ESUN Broadband Bill Payment Screen
///
/// Provider selection for broadband/fiber internet bill payments with
/// official logos, saved connections, and plan details.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../core/constants/brand_logos.dart';
import '../../shared/widgets/pay_via_apps.dart';
import 'bill_payment_screen.dart';

String? _getBroadbandLogo(String key) => BrandLogos.brands[key];

// ============================================================================
// Data Models
// ============================================================================

class _BroadbandProvider {
  final String name;
  final String shortName;
  final String type; // 'Fiber' or 'Broadband'
  final Color color;
  final String? logoUrl;
  final List<String> speeds;

  const _BroadbandProvider({
    required this.name,
    required this.shortName,
    required this.type,
    required this.color,
    this.logoUrl,
    this.speeds = const [],
  });
}

class _SavedConnection {
  final String accountName;
  final String accountNumber;
  final String provider;
  final Color providerColor;
  final String? logoUrl;
  final String plan;
  final String lastPaid;
  final String lastAmount;
  final bool hasDueBill;
  final String? dueAmount;

  const _SavedConnection({
    required this.accountName,
    required this.accountNumber,
    required this.provider,
    required this.providerColor,
    this.logoUrl,
    required this.plan,
    required this.lastPaid,
    required this.lastAmount,
    this.hasDueBill = false,
    this.dueAmount,
  });
}

// ============================================================================
// Screen
// ============================================================================

class BroadbandProviderScreen extends ConsumerStatefulWidget {
  const BroadbandProviderScreen({super.key});

  @override
  ConsumerState<BroadbandProviderScreen> createState() =>
      _BroadbandProviderScreenState();
}

class _BroadbandProviderScreenState
    extends ConsumerState<BroadbandProviderScreen> {
  static final _providers = [
    _BroadbandProvider(
      name: 'JioFiber',
      shortName: 'JioFiber',
      type: 'Fiber',
      color: const Color(0xFF0A3D91),
      logoUrl: _getBroadbandLogo('jio fiber'),
      speeds: ['30 Mbps', '100 Mbps', '300 Mbps', '1 Gbps'],
    ),
    _BroadbandProvider(
      name: 'Airtel Xstream Fiber',
      shortName: 'Airtel',
      type: 'Fiber',
      color: const Color(0xFFED1C24),
      logoUrl: _getBroadbandLogo('airtel xstream'),
      speeds: ['40 Mbps', '100 Mbps', '200 Mbps', '1 Gbps'],
    ),
    _BroadbandProvider(
      name: 'ACT Fibernet',
      shortName: 'ACT',
      type: 'Fiber',
      color: const Color(0xFFE91E63),
      logoUrl: _getBroadbandLogo('act fibernet'),
      speeds: ['75 Mbps', '150 Mbps', '300 Mbps'],
    ),
    _BroadbandProvider(
      name: 'BSNL Bharat Fiber',
      shortName: 'BSNL',
      type: 'Fiber / DSL',
      color: const Color(0xFF00A651),
      logoUrl: _getBroadbandLogo('bsnl broadband'),
      speeds: ['30 Mbps', '60 Mbps', '100 Mbps', '200 Mbps'],
    ),
    _BroadbandProvider(
      name: 'Hathway Broadband',
      shortName: 'Hathway',
      type: 'Cable / Fiber',
      color: const Color(0xFF1976D2),
      logoUrl: _getBroadbandLogo('hathway'),
      speeds: ['50 Mbps', '100 Mbps', '150 Mbps'],
    ),
    _BroadbandProvider(
      name: 'Tikona Digital',
      shortName: 'Tikona',
      type: 'Wireless / Fiber',
      color: const Color(0xFF388E3C),
      logoUrl: _getBroadbandLogo('tikona'),
      speeds: ['10 Mbps', '50 Mbps', '100 Mbps'],
    ),
  ];

  static final _savedConnections = [
    _SavedConnection(
      accountName: 'Arjun - Home WiFi',
      accountNumber: 'JF-2024567890',
      provider: 'JioFiber',
      providerColor: const Color(0xFF0A3D91),
      logoUrl: _getBroadbandLogo('jio fiber'),
      plan: '100 Mbps Unlimited',
      lastPaid: '05 Mar 2026',
      lastAmount: '₹999',
      hasDueBill: true,
      dueAmount: '₹999',
    ),
  ];

  void _navigateToPayment(String provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillPaymentScreen(
          billType: 'Broadband Bill',
          icon: Icons.wifi,
          color: const Color(0xFF00897B),
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
          'Broadband / Fiber',
          style: ESUNTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderBanner(),
            if (_savedConnections.isNotEmpty) _buildSavedConnections(),
            _buildSectionHeader('Internet Providers'),
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
            child: const Icon(Icons.wifi, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pay Broadband Bill',
                    style: ESUNTypography.titleLarge.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Select your internet service provider',
                    style: ESUNTypography.bodySmall
                        .copyWith(color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedConnections() {
    return Column(
      children: [
        _buildSectionHeader('My Connections'),
        ..._savedConnections.map((conn) => _buildSavedConnectionCard(conn)),
      ],
    );
  }

  Widget _buildSavedConnectionCard(_SavedConnection conn) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: conn.hasDueBill
            ? Border.all(color: ESUNColors.primary.withOpacity(0.5))
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
              _buildProviderLogo(conn.providerColor, conn.provider,
                  logoUrl: conn.logoUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(conn.accountName,
                        style: ESUNTypography.titleSmall
                            .copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('${conn.provider} • ${conn.accountNumber}',
                        style: ESUNTypography.bodySmall
                            .copyWith(color: ESUNColors.textSecondary)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.speed, size: 14, color: ESUNColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(conn.plan,
                            style: ESUNTypography.bodySmall
                                .copyWith(color: ESUNColors.textTertiary)),
                      ],
                    ),
                    if (conn.hasDueBill)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: ESUNColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Due: ${conn.dueAmount}',
                            style: ESUNTypography.labelSmall.copyWith(
                              color: ESUNColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: 38,
                child: FilledButton(
                  onPressed: () => _navigateToPayment(conn.provider),
                  style: FilledButton.styleFrom(
                    backgroundColor: ESUNColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 0),
                  ),
                  child: Text('Pay Bill',
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

  Widget _buildProviderCard(_BroadbandProvider provider) {
    return InkWell(
      onTap: () => _navigateToPayment(provider.shortName),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: provider.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(provider.type,
                            style: ESUNTypography.labelSmall.copyWith(
                                color: provider.color,
                                fontWeight: FontWeight.w500,
                                fontSize: 10)),
                      ),
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
            if (provider.speeds.isNotEmpty) ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: provider.speeds.map((speed) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.speed,
                              size: 12, color: provider.color),
                          const SizedBox(width: 4),
                          Text(speed,
                              style: ESUNTypography.labelSmall.copyWith(
                                  color: ESUNColors.textSecondary,
                                  fontSize: 10)),
                        ],
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
