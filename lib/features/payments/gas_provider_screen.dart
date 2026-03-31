/// ESUN Gas Bill / Cylinder Booking Screen
///
/// Provider selection for LPG cylinder booking and piped gas payments
/// with official logos for Bharat Gas, HP Gas, Indane, and piped gas providers.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../core/constants/brand_logos.dart';
import '../../shared/widgets/pay_via_apps.dart';
import 'bill_payment_screen.dart';

String? _getGasLogo(String key) => BrandLogos.brands[key];

// ============================================================================
// Data Models
// ============================================================================

class _GasProvider {
  final String name;
  final String shortName;
  final String description;
  final Color color;
  final String? logoUrl;
  final String type; // 'lpg' or 'piped'

  const _GasProvider({
    required this.name,
    required this.shortName,
    required this.description,
    required this.color,
    this.logoUrl,
    required this.type,
  });
}

class _SavedConnection {
  final String consumerName;
  final String consumerNumber;
  final String provider;
  final Color providerColor;
  final String? logoUrl;
  final String lastBooked;
  final String lastAmount;
  final String type;

  const _SavedConnection({
    required this.consumerName,
    required this.consumerNumber,
    required this.provider,
    required this.providerColor,
    this.logoUrl,
    required this.lastBooked,
    required this.lastAmount,
    required this.type,
  });
}

// ============================================================================
// Screen
// ============================================================================

class GasProviderScreen extends ConsumerStatefulWidget {
  const GasProviderScreen({super.key});

  @override
  ConsumerState<GasProviderScreen> createState() => _GasProviderScreenState();
}

class _GasProviderScreenState extends ConsumerState<GasProviderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static final _lpgProviders = [
    _GasProvider(
      name: 'Indane Gas (Indian Oil)',
      shortName: 'Indane',
      description: 'Indian Oil Corporation LPG',
      color: const Color(0xFF1B5E20),
      logoUrl: _getGasLogo('indane'),
      type: 'lpg',
    ),
    _GasProvider(
      name: 'HP Gas (Hindustan Petroleum)',
      shortName: 'HP Gas',
      description: 'Hindustan Petroleum LPG',
      color: const Color(0xFF0D47A1),
      logoUrl: _getGasLogo('hp gas'),
      type: 'lpg',
    ),
    _GasProvider(
      name: 'Bharat Gas (BPCL)',
      shortName: 'Bharat Gas',
      description: 'Bharat Petroleum LPG',
      color: const Color(0xFFC62828),
      logoUrl: _getGasLogo('bharat gas'),
      type: 'lpg',
    ),
  ];

  static final _pipedGasProviders = [
    _GasProvider(
      name: 'Mahanagar Gas Limited',
      shortName: 'MGL',
      description: 'Mumbai & MMR Region',
      color: const Color(0xFF00838F),
      logoUrl: _getGasLogo('mahanagar gas'),
      type: 'piped',
    ),
    _GasProvider(
      name: 'Indraprastha Gas Limited',
      shortName: 'IGL',
      description: 'Delhi NCR Region',
      color: const Color(0xFF283593),
      logoUrl: _getGasLogo('indraprastha gas'),
      type: 'piped',
    ),
    _GasProvider(
      name: 'Adani Total Gas',
      shortName: 'ATGL',
      description: 'Gujarat & other cities',
      color: const Color(0xFF1565C0),
      logoUrl: _getGasLogo('adani gas'),
      type: 'piped',
    ),
    _GasProvider(
      name: 'GAIL Gas Limited',
      shortName: 'GAIL Gas',
      description: 'Multiple cities across India',
      color: const Color(0xFF4527A0),
      logoUrl: _getGasLogo('gail gas'),
      type: 'piped',
    ),
  ];

  static final _savedConnections = [
    _SavedConnection(
      consumerName: 'Arjun Mehta',
      consumerNumber: 'IND-301456789',
      provider: 'Indane',
      providerColor: const Color(0xFF1B5E20),
      logoUrl: _getGasLogo('indane'),
      lastBooked: '10 Feb 2026',
      lastAmount: '₹950',
      type: 'LPG Cylinder',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToPayment(String provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillPaymentScreen(
          billType: 'Gas Cylinder',
          icon: Icons.local_gas_station,
          color: const Color(0xFFEF6C00),
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
          'Gas Bill & Cylinder',
          style: ESUNTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'LPG Cylinder'),
            Tab(text: 'Piped Gas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLPGTab(),
          _buildPipedGasTab(),
        ],
      ),
    );
  }

  Widget _buildLPGTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBanner(
            'Book LPG Cylinder',
            'Select your gas provider to book or pay',
            Icons.propane_tank,
          ),
          if (_savedConnections.isNotEmpty) _buildSavedConnections(),
          _buildSectionHeader('LPG Providers'),
          ..._lpgProviders.map((p) => _buildProviderCard(p)),
          const SizedBox(height: 20),
          _buildInfoCard(
            'LPG Subsidy',
            'Your LPG subsidy is directly transferred to your bank account via PAHAL (DBTL) scheme.',
            Icons.info_outline,
          ),
          const PayViaAppsSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPipedGasTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBanner(
            'Piped Natural Gas',
            'Pay your piped gas bill instantly',
            Icons.gas_meter,
          ),
          _buildSectionHeader('Piped Gas Providers'),
          ..._pipedGasProviders.map((p) => _buildProviderCard(p)),
          const PayViaAppsSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner(String title, String subtitle, IconData icon) {
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
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: ESUNTypography.titleLarge.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle,
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
        _buildSectionHeader('Saved Connections'),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildProviderLogo(conn.providerColor, conn.provider,
              logoUrl: conn.logoUrl),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(conn.consumerName,
                    style: ESUNTypography.titleSmall
                        .copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('${conn.provider} • ${conn.consumerNumber}',
                    style: ESUNTypography.bodySmall
                        .copyWith(color: ESUNColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                    'Last: ${conn.lastAmount} on ${conn.lastBooked} (${conn.type})',
                    style: ESUNTypography.bodySmall
                        .copyWith(color: ESUNColors.textTertiary)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              child: Text('Book / Pay',
                  style: ESUNTypography.labelMedium.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(_GasProvider provider) {
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
        child: Row(
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
                  Text(provider.description,
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
              child: Icon(Icons.chevron_right, color: provider.color, size: 20),
            ),
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

  Widget _buildInfoCard(String title, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCE93D8).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7B1FA2), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: ESUNTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7B1FA2))),
                const SizedBox(height: 4),
                Text(description,
                    style: ESUNTypography.bodySmall
                        .copyWith(color: const Color(0xFF9C27B0))),
              ],
            ),
          ),
        ],
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
