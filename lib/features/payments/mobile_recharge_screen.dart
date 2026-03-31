/// ESUN Mobile Recharge Screen
///
/// Full-featured mobile recharge screen with provider logos, saved numbers,
/// recent recharges, and quick recharge plans — light theme design.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../core/constants/brand_logos.dart';
import 'bill_payment_screen.dart';

// Helper to get telecom logo from BrandLogos
String? _getTelecomLogo(String key) => BrandLogos.brands[key];

// ============================================================================
// Data Models
// ============================================================================

class _TelecomProvider {
  final String name;
  final String shortName;
  final Color color;
  final String? logoUrl;

  const _TelecomProvider({
    required this.name,
    required this.shortName,
    required this.color,
    this.logoUrl,
  });
}

class _SavedNumber {
  final String name;
  final String number;
  final String provider;
  final Color providerColor;
  final String? logoUrl;
  final String addedDate;
  final bool isPlanExpiring;
  final bool isPrimary;

  const _SavedNumber({
    required this.name,
    required this.number,
    required this.provider,
    required this.providerColor,
    this.logoUrl,
    required this.addedDate,
    this.isPlanExpiring = false,
    this.isPrimary = false,
  });
}

class _RechargeHistory {
  final String name;
  final String number;
  final String provider;
  final Color providerColor;
  final String? logoUrl;
  final String amount;
  final String date;

  const _RechargeHistory({
    required this.name,
    required this.number,
    required this.provider,
    required this.providerColor,
    this.logoUrl,
    required this.amount,
    required this.date,
  });
}

class _QuickPlan {
  final String data;
  final String price;
  final String validity;
  final bool isPopular;

  const _QuickPlan({
    required this.data,
    required this.price,
    required this.validity,
    this.isPopular = false,
  });
}

// ============================================================================
// Screen
// ============================================================================

class MobileRechargeScreen extends ConsumerStatefulWidget {
  const MobileRechargeScreen({super.key});

  @override
  ConsumerState<MobileRechargeScreen> createState() =>
      _MobileRechargeScreenState();
}

class _MobileRechargeScreenState extends ConsumerState<MobileRechargeScreen> {
  final _numberController = TextEditingController();
  final _focusNode = FocusNode();

  // Static providers data
  static final _providers = [
    _TelecomProvider(
      name: 'Jio',
      shortName: 'Jio',
      color: const Color(0xFF0A3D91),
      logoUrl: _getTelecomLogo('jio'),
    ),
    _TelecomProvider(
      name: 'Airtel',
      shortName: 'Airtel',
      color: const Color(0xFFED1C24),
      logoUrl: _getTelecomLogo('airtel'),
    ),
    _TelecomProvider(
      name: 'Vi',
      shortName: 'Vi',
      color: const Color(0xFFE4002B),
      logoUrl: _getTelecomLogo('vi'),
    ),
    _TelecomProvider(
      name: 'BSNL',
      shortName: 'BSNL',
      color: const Color(0xFF00A651),
      logoUrl: _getTelecomLogo('bsnl'),
    ),
    _TelecomProvider(
      name: 'MTNL',
      shortName: 'MTNL',
      color: const Color(0xFFFF6600),
    ),
  ];

  // User's saved numbers
  static final _savedNumbers = [
    _SavedNumber(
      name: 'SIM 1',
      number: '9900001111',
      provider: 'Jio',
      providerColor: const Color(0xFF0A3D91),
      logoUrl: _getTelecomLogo('jio'),
      addedDate: '04 Jan',
      isPrimary: true,
    ),
    _SavedNumber(
      name: 'SIM 2',
      number: '9900002222',
      provider: 'Airtel',
      providerColor: const Color(0xFFED1C24),
      logoUrl: _getTelecomLogo('airtel'),
      addedDate: '10 Feb',
      isPlanExpiring: true,
    ),
  ];

  // Quick plans for primary SIM
  static const _quickPlans = [
    _QuickPlan(data: '1 GB', price: '₹19', validity: '1 Day', isPopular: true),
    _QuickPlan(data: '2 GB', price: '₹29', validity: '2 Days'),
    _QuickPlan(data: '25 GB', price: '₹49', validity: '7 Days'),
  ];

  // Recharge history
  static final _rechargeHistory = [
    _RechargeHistory(
      name: 'Ravi',
      number: '9876543210',
      provider: 'Jio',
      providerColor: const Color(0xFF0A3D91),
      logoUrl: _getTelecomLogo('jio'),
      amount: '₹599',
      date: '01 Mar',
    ),
    _RechargeHistory(
      name: 'Anita',
      number: '9988776655',
      provider: 'BSNL',
      providerColor: const Color(0xFF00A651),
      logoUrl: _getTelecomLogo('bsnl'),
      amount: '₹199',
      date: '04 Nov 2025',
    ),
    _RechargeHistory(
      name: 'Mom ❤',
      number: '9871234567',
      provider: 'Airtel',
      providerColor: const Color(0xFFED1C24),
      logoUrl: _getTelecomLogo('airtel'),
      amount: '₹299',
      date: '28 Sep 2025',
    ),
    _RechargeHistory(
      name: 'Dad',
      number: '9812345678',
      provider: 'Jio',
      providerColor: const Color(0xFF0A3D91),
      logoUrl: _getTelecomLogo('jio'),
      amount: '₹239',
      date: '15 Aug 2025',
    ),
  ];

  @override
  void dispose() {
    _numberController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _navigateToRecharge(String number, String provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillPaymentScreen(
          billType: 'Mobile Recharge',
          icon: Icons.phone_android,
          color: const Color(0xFF10B981),
          prefillNumber: number,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ESUNColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ESUNColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Recharge or Pay Mobile Bill',
          style: ESUNTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: ESUNColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Promo Banner
            _buildPromoBanner(),

            // Enter Mobile Number Section
            _buildMobileNumberInput(),

            // My Numbers Section
            _buildMyNumbersSection(),

            // My Recharges & Bills Section
            _buildRechargesAndBillsSection(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // Promo Banner
  // ============================================================================

  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.sm, ESUNSpacing.lg, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_offer_rounded,
              color: Color(0xFF43A047),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '12% off on Canara GigStar Visa Debit Card',
              style: ESUNTypography.bodyMedium.copyWith(
                color: const Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'View All',
            style: ESUNTypography.labelMedium.copyWith(
              color: const Color(0xFF1B5E20),
              fontWeight: FontWeight.bold,
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF1B5E20), size: 18),
        ],
      ),
    );
  }

  // ============================================================================
  // Mobile Number Input with Provider Logos
  // ============================================================================

  Widget _buildMobileNumberInput() {
    return Container(
      margin: const EdgeInsets.all(ESUNSpacing.lg),
      padding: const EdgeInsets.all(ESUNSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with provider logos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enter Mobile Number',
                style: ESUNTypography.titleSmall.copyWith(
                  color: ESUNColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: _providers.map((provider) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _buildProviderLogo(provider, size: 24),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Phone number input
          Container(
            decoration: BoxDecoration(
              color: ESUNColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ESUNColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: ESUNColors.border),
                    ),
                  ),
                  child: Text(
                    '+91 -',
                    style: ESUNTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ESUNColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _numberController,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: ESUNTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter number',
                      hintStyle: ESUNTypography.titleMedium.copyWith(
                        color: ESUNColors.textTertiary,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      counterText: '',
                    ),
                    onSubmitted: (value) {
                      if (value.length == 10) {
                        _navigateToRecharge(value, '');
                      }
                    },
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Contact picker placeholder
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(ESUNSpacing.md),
                      child: Icon(
                        Icons.contacts_rounded,
                        color: ESUNColors.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // My Numbers Section
  // ============================================================================

  Widget _buildMyNumbersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: ESUNColors.surfaceVariant,
          child: Text(
            'My Numbers - Subhra Kanta Mohanty',
            style: ESUNTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: ESUNColors.textSecondary,
            ),
          ),
        ),

        // Saved Numbers List
        ...List.generate(_savedNumbers.length, (index) {
          final number = _savedNumbers[index];
          return _buildSavedNumberCard(number, index);
        }),
      ],
    );
  }

  Widget _buildSavedNumberCard(_SavedNumber number, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: ESUNColors.divider, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Provider Logo
              _buildProviderLogo(
                _providers.firstWhere(
                  (p) => p.shortName == number.provider,
                  orElse: () => _providers.first,
                ),
                size: 44,
              ),
              const SizedBox(width: 14),

              // Number Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      number.name,
                      style: ESUNTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ESUNColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      number.number,
                      style: ESUNTypography.bodyMedium.copyWith(
                        color: ESUNColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (number.isPlanExpiring)
                      Text(
                        'Plan expiring soon! Recharge now',
                        style: ESUNTypography.bodySmall.copyWith(
                          color: ESUNColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      Text(
                        'Added on ${number.addedDate}',
                        style: ESUNTypography.bodySmall.copyWith(
                          color: ESUNColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),

              // Action Button
              SizedBox(
                height: 38,
                child: FilledButton(
                  onPressed: () =>
                      _navigateToRecharge(number.number, number.provider),
                  style: FilledButton.styleFrom(
                    backgroundColor: number.isPrimary
                        ? ESUNColors.primary
                        : const Color(0xFF00BCD4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                  ),
                  child: Text(
                    number.isPrimary ? 'Pay' : 'Recharge',
                    style: ESUNTypography.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Quick Plans (only for primary SIM)
          if (number.isPrimary) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickPlans.map((plan) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _buildQuickPlanChip(plan),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickPlanChip(_QuickPlan plan) {
    return InkWell(
      onTap: () => _navigateToRecharge(
        _savedNumbers.first.number,
        _savedNumbers.first.provider,
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ESUNColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (plan.isPopular) ...[
              Container(
                padding:
                    ESUNSpacing.tagInsets,
                decoration: BoxDecoration(
                  color: ESUNColors.error,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Popular',
                  style: ESUNTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              '${plan.data} for ${plan.price}',
              style: ESUNTypography.bodySmall.copyWith(
                color: ESUNColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 16, color: ESUNColors.primary),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // My Recharges & Bills Section
  // ============================================================================

  Widget _buildRechargesAndBillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: ESUNColors.surfaceVariant,
          child: Text(
            'My Recharges & Bills',
            style: ESUNTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: ESUNColors.textSecondary,
            ),
          ),
        ),

        // Recharge History List
        ...List.generate(_rechargeHistory.length, (index) {
          final item = _rechargeHistory[index];
          return _buildRechargeHistoryCard(item);
        }),
      ],
    );
  }

  Widget _buildRechargeHistoryCard(_RechargeHistory item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: ESUNColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Provider Logo
          _buildProviderLogo(
            _providers.firstWhere(
              (p) => p.shortName == item.provider,
              orElse: () => _providers.first,
            ),
            size: 44,
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.name.isNotEmpty)
                  Text(
                    item.name,
                    style: ESUNTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ESUNColors.textPrimary,
                    ),
                  ),
                Text(
                  item.number,
                  style: ESUNTypography.bodyMedium.copyWith(
                    color: item.name.isEmpty
                        ? ESUNColors.textPrimary
                        : ESUNColors.textSecondary,
                    fontWeight:
                        item.name.isEmpty ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.amount.isNotEmpty
                      ? 'Recharged ${item.amount} on ${item.date}'
                      : 'Added on ${item.date}',
                  style: ESUNTypography.bodySmall.copyWith(
                    color: ESUNColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          // Recharge Button
          SizedBox(
            height: 38,
            child: FilledButton(
              onPressed: () =>
                  _navigateToRecharge(item.number, item.provider),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              ),
              child: Text(
                'Recharge',
                style: ESUNTypography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Provider Logo Widget
  // ============================================================================

  Widget _buildProviderLogo(_TelecomProvider provider, {double size = 40}) {
    if (provider.logoUrl != null) {
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
              provider.logoUrl!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _buildFallbackLogo(provider, size),
            ),
          ),
        ),
      );
    }
    return _buildFallbackLogo(provider, size);
  }

  Widget _buildFallbackLogo(_TelecomProvider provider, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: provider.color.withOpacity(0.1),
        border: Border.all(color: provider.color.withOpacity(0.3), width: 1),
      ),
      child: Center(
        child: Text(
          provider.shortName.substring(0, provider.shortName.length > 2 ? 2 : provider.shortName.length),
          style: TextStyle(
            color: provider.color,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.3,
          ),
        ),
      ),
    );
  }
}
