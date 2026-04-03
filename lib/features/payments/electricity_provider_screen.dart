/// ESUN Electricity Bill Payment Screen
///
/// Provider selection screen for electricity bill payments with official logos,
/// state-wise providers, saved connections, and bill history.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../core/constants/brand_logos.dart';
import '../../shared/widgets/pay_via_apps.dart';
import 'bill_payment_screen.dart';

String? _getElectricityLogo(String key) => BrandLogos.brands[key];

// ============================================================================
// Data Models
// ============================================================================

class _ElectricityProvider {
  final String name;
  final String shortName;
  final String state;
  final Color color;
  final String? logoUrl;

  const _ElectricityProvider({
    required this.name,
    required this.shortName,
    required this.state,
    required this.color,
    this.logoUrl,
  });
}

class _SavedConnection {
  final String consumerName;
  final String consumerNumber;
  final String provider;
  final String state;
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
    required this.state,
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

class ElectricityProviderScreen extends ConsumerStatefulWidget {
  const ElectricityProviderScreen({super.key});

  @override
  ConsumerState<ElectricityProviderScreen> createState() =>
      _ElectricityProviderScreenState();
}

class _ElectricityProviderScreenState
    extends ConsumerState<ElectricityProviderScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static final _providers = [
    _ElectricityProvider(
      name: 'TPCODL (TP Central Odisha)',
      shortName: 'TPCODL',
      state: 'Odisha',
      color: const Color(0xFF1565C0),
      logoUrl: _getElectricityLogo('tpcodl'),
    ),
    _ElectricityProvider(
      name: 'TPSODL (TP Southern Odisha)',
      shortName: 'TPSODL',
      state: 'Odisha',
      color: const Color(0xFF0D47A1),
      logoUrl: _getElectricityLogo('tpsodl'),
    ),
    _ElectricityProvider(
      name: 'TPNODL (TP Northern Odisha)',
      shortName: 'TPNODL',
      state: 'Odisha',
      color: const Color(0xFF1976D2),
      logoUrl: _getElectricityLogo('tpnodl'),
    ),
    _ElectricityProvider(
      name: 'TPWODL (TP Western Odisha)',
      shortName: 'TPWODL',
      state: 'Odisha',
      color: const Color(0xFF2196F3),
      logoUrl: _getElectricityLogo('tpwodl'),
    ),
    _ElectricityProvider(
      name: 'Tata Power',
      shortName: 'Tata Power',
      state: 'Mumbai',
      color: const Color(0xFF00529B),
      logoUrl: _getElectricityLogo('tata power'),
    ),
    _ElectricityProvider(
      name: 'Adani Electricity',
      shortName: 'Adani',
      state: 'Mumbai',
      color: const Color(0xFF003B73),
      logoUrl: _getElectricityLogo('adani electricity'),
    ),
    _ElectricityProvider(
      name: 'BESCOM',
      shortName: 'BESCOM',
      state: 'Karnataka',
      color: const Color(0xFF2E7D32),
      logoUrl: _getElectricityLogo('bescom'),
    ),
    _ElectricityProvider(
      name: 'BSES Rajdhani',
      shortName: 'BSES-R',
      state: 'Delhi',
      color: const Color(0xFFEF5350),
      logoUrl: _getElectricityLogo('bses rajdhani'),
    ),
    _ElectricityProvider(
      name: 'BSES Yamuna',
      shortName: 'BSES-Y',
      state: 'Delhi',
      color: const Color(0xFFF44336),
      logoUrl: _getElectricityLogo('bses yamuna'),
    ),
    _ElectricityProvider(
      name: 'TPDDL',
      shortName: 'TPDDL',
      state: 'Delhi',
      color: const Color(0xFF1A237E),
      logoUrl: _getElectricityLogo('tpddl'),
    ),
    _ElectricityProvider(
      name: 'MSEDCL',
      shortName: 'MSEDCL',
      state: 'Maharashtra',
      color: const Color(0xFFFF6F00),
      logoUrl: _getElectricityLogo('msedcl'),
    ),
    _ElectricityProvider(
      name: 'CESC',
      shortName: 'CESC',
      state: 'West Bengal',
      color: const Color(0xFF5C6BC0),
      logoUrl: _getElectricityLogo('cesc'),
    ),
    _ElectricityProvider(
      name: 'Torrent Power',
      shortName: 'Torrent',
      state: 'Gujarat',
      color: const Color(0xFF00897B),
      logoUrl: _getElectricityLogo('torrent power'),
    ),
    _ElectricityProvider(
      name: 'TANGEDCO',
      shortName: 'TANGEDCO',
      state: 'Tamil Nadu',
      color: const Color(0xFF6A1B9A),
      logoUrl: _getElectricityLogo('tangedco'),
    ),
  ];

  static final _savedConnections = [
    _SavedConnection(
      consumerName: 'Arjun Mehta',
      consumerNumber: '3204-2187-5531',
      provider: 'TPCODL',
      state: 'Odisha',
      providerColor: const Color(0xFF1565C0),
      logoUrl: _getElectricityLogo('tpcodl'),
      lastPaid: '15 Feb 2026',
      lastAmount: '₹2,340',
      hasDueBill: true,
      dueAmount: '₹2,580',
    ),
  ];

  List<_ElectricityProvider> get _filteredProviders {
    if (_searchQuery.isEmpty) return _providers;
    final q = _searchQuery.toLowerCase();
    return _providers
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.shortName.toLowerCase().contains(q) ||
            p.state.toLowerCase().contains(q))
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
        builder: (context) => const BillPaymentScreen(
          billType: 'Electricity Bill',
          icon: Icons.bolt,
          color: Color(0xFFF59E0B),
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
          'Electricity Bill',
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
            _buildProviderGrid(),
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
            child: const Icon(Icons.bolt, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pay Electricity Bill',
                  style: ESUNTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select your electricity provider below',
                  style: ESUNTypography.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
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
          hintText: 'Search by provider name or state...',
          hintStyle: ESUNTypography.bodyMedium
              .copyWith(color: ESUNColors.textTertiary),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: ESUNColors.surfaceVariant,
          child: Text(
            'Saved Connections',
            style: ESUNTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: ESUNColors.textSecondary,
            ),
          ),
        ),
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
                    if (conn.hasDueBill) ...[
                      const SizedBox(height: 4),
                      Container(
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
                    ],
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
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  ),
                  child: Text('Pay Bill',
                      style: ESUNTypography.labelMedium
                          .copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
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

  Widget _buildProviderGrid() {
    final filtered = _filteredProviders;
    // Group by state
    final grouped = <String, List<_ElectricityProvider>>{};
    for (final p in filtered) {
      grouped.putIfAbsent(p.state, () => []).add(p);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: ESUNColors.surfaceVariant,
          child: Text(
            'All Providers',
            style: ESUNTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: ESUNColors.textSecondary,
            ),
          ),
        ),
        ...grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  entry.key,
                  style: ESUNTypography.labelMedium.copyWith(
                    color: ESUNColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...entry.value.map((provider) => _buildProviderTile(provider)),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildProviderTile(_ElectricityProvider provider) {
    return InkWell(
      onTap: () => _navigateToPayment(provider.shortName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border:
              Border(bottom: BorderSide(color: ESUNColors.divider, width: 0.5)),
        ),
        child: Row(
          children: [
            _buildProviderLogo(provider.color, provider.shortName,
                logoUrl: provider.logoUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(provider.name,
                      style: ESUNTypography.titleSmall
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(provider.state,
                      style: ESUNTypography.bodySmall
                          .copyWith(color: ESUNColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: ESUNColors.textTertiary, size: 20),
          ],
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
    final display = shortName.length > 2 ? shortName.substring(0, 2) : shortName;
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
