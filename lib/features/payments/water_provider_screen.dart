/// ESUN Water Bill Payment Screen
///
/// Provider selection for municipal water board bill payments with
/// official logos, saved connections, and bill history.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../core/constants/brand_logos.dart';
import '../../shared/widgets/pay_via_apps.dart';
import 'bill_payment_screen.dart';

String? _getWaterLogo(String key) => BrandLogos.brands[key];

// ============================================================================
// Data Models
// ============================================================================

class _WaterProvider {
  final String name;
  final String shortName;
  final String city;
  final Color color;
  final String? logoUrl;

  const _WaterProvider({
    required this.name,
    required this.shortName,
    required this.city,
    required this.color,
    this.logoUrl,
  });
}

class _SavedConnection {
  final String consumerName;
  final String consumerNumber;
  final String provider;
  final Color providerColor;
  final String? logoUrl;
  final String lastPaid;
  final String lastAmount;
  final bool hasDueBill;
  final String? dueAmount;

  const _SavedConnection({
    required this.consumerName,
    required this.consumerNumber,
    required this.provider,
    required this.providerColor,
    this.logoUrl,
    required this.lastPaid,
    required this.lastAmount,
    this.hasDueBill = false,
    this.dueAmount,
  });
}

// ============================================================================
// Screen
// ============================================================================

class WaterProviderScreen extends ConsumerStatefulWidget {
  const WaterProviderScreen({super.key});

  @override
  ConsumerState<WaterProviderScreen> createState() =>
      _WaterProviderScreenState();
}

class _WaterProviderScreenState extends ConsumerState<WaterProviderScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static final _providers = [
    _WaterProvider(
      name: 'PHEO (Public Health Engineering Org.)',
      shortName: 'PHEO',
      city: 'Odisha',
      color: const Color(0xFF0277BD),
      logoUrl: _getWaterLogo('pheo odisha'),
    ),
    _WaterProvider(
      name: 'Delhi Jal Board',
      shortName: 'DJB',
      city: 'Delhi',
      color: const Color(0xFF0D47A1),
      logoUrl: _getWaterLogo('delhi jal board'),
    ),
    _WaterProvider(
      name: 'BMC Water Department',
      shortName: 'BMC Water',
      city: 'Mumbai',
      color: const Color(0xFF1565C0),
      logoUrl: _getWaterLogo('bmc water'),
    ),
    _WaterProvider(
      name: 'BWSSB (Bangalore Water Supply)',
      shortName: 'BWSSB',
      city: 'Bangalore',
      color: const Color(0xFF2E7D32),
      logoUrl: _getWaterLogo('bwssb'),
    ),
    _WaterProvider(
      name: 'CMWSSB (Chennai Metro Water)',
      shortName: 'CMWSSB',
      city: 'Chennai',
      color: const Color(0xFF6A1B9A),
      logoUrl: _getWaterLogo('cmwssb'),
    ),
    _WaterProvider(
      name: 'HMWSSB (Hyderabad Metro Water)',
      shortName: 'HMWSSB',
      city: 'Hyderabad',
      color: const Color(0xFFE65100),
      logoUrl: _getWaterLogo('hmwssb'),
    ),
  ];

  static final _savedConnections = [
    _SavedConnection(
      consumerName: 'Arjun Mehta',
      consumerNumber: 'PHEO-BLS-44210',
      provider: 'PHEO',
      providerColor: const Color(0xFF0277BD),
      logoUrl: _getWaterLogo('pheo odisha'),
      lastPaid: '20 Jan 2026',
      lastAmount: '₹350',
      hasDueBill: true,
      dueAmount: '₹380',
    ),
  ];

  List<_WaterProvider> get _filteredProviders {
    if (_searchQuery.isEmpty) return _providers;
    final q = _searchQuery.toLowerCase();
    return _providers
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.shortName.toLowerCase().contains(q) ||
            p.city.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToPayment(String provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillPaymentScreen(
          billType: 'Water Bill',
          icon: Icons.water_drop,
          color: const Color(0xFF0288D1),
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
          'Water Bill',
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
            _buildSearchBar(),
            if (_savedConnections.isNotEmpty) _buildSavedConnections(),
            _buildProviderList(),
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
            child: const Icon(Icons.water_drop, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pay Water Bill',
                    style: ESUNTypography.titleLarge.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Select your water board or authority',
                    style: ESUNTypography.bodySmall
                        .copyWith(color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search by board name or city...',
          hintStyle:
              ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textTertiary),
          prefixIcon: const Icon(Icons.search, color: ESUNColors.textTertiary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
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
                    Text(conn.consumerName,
                        style: ESUNTypography.titleSmall
                            .copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('${conn.provider} • ${conn.consumerNumber}',
                        style: ESUNTypography.bodySmall
                            .copyWith(color: ESUNColors.textSecondary)),
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
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 58),
              Text('Last paid ${conn.lastAmount} on ${conn.lastPaid}',
                  style: ESUNTypography.bodySmall
                      .copyWith(color: ESUNColors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderList() {
    final filtered = _filteredProviders;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('All Water Boards'),
        ...filtered.map((p) => _buildProviderTile(p)),
      ],
    );
  }

  Widget _buildProviderTile(_WaterProvider provider) {
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
                logoUrl: provider.logoUrl, size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(provider.name,
                      style: ESUNTypography.titleSmall
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(provider.city,
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
              child:
                  Icon(Icons.chevron_right, color: provider.color, size: 20),
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
