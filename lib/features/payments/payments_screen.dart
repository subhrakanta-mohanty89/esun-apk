/// ESUN Pay Screen - Production Level
/// 
/// Inspired by Google Pay and PhonePe with modern UX patterns
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:permission_handler/permission_handler.dart';

import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../shared/widgets/widgets.dart';
import '../../shared/widgets/qr_sheet.dart';
import '../../routes/app_routes.dart';
import '../../state/aa_data_state.dart';
import '../../core/utils/utils.dart';
import 'payment_history_screen.dart' hide TransactionType;
import 'bill_payment_screen.dart';
import 'send_money_screen.dart';
import 'mobile_recharge_screen.dart';
import 'electricity_provider_screen.dart';
import '../profile/profile_screen.dart';
import '../../state/transaction_state.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> with SingleTickerProviderStateMixin {
  String get _name {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    return profile?['full_name'] ?? 'User';
  }
  
  String get _upiId {
    final name = _name.toLowerCase().replaceAll(' ', '.');
    return '$name@ESUN';
  }
  
  String get _bankLabel {
    final banks = ref.watch(aaDataProvider).bankAccounts;
    if (banks.isNotEmpty) {
      final b = banks.first;
      final last4 = b.accountNumber.length >= 4
          ? b.accountNumber.substring(b.accountNumber.length - 4)
          : b.accountNumber;
      return '${b.bankName} • $last4';
    }
    return 'Link Bank';
  }

  bool _contactsGranted = false;
  List<_PaymentContact> _contacts = [];
  bool _permissionAsked = false;
  
  late AnimationController _scanPulseController;
  
  final TextEditingController _searchController = TextEditingController();
  
  // Recent transactions for quick repeat - derived from transaction state
  List<_RecentPerson> get _recentPeople {
    final txns = ref.watch(transactionStateProvider).transactions;
    final seen = <String>{};
    final people = <_RecentPerson>[];
    final colors = [ESUNColors.primary, ESUNColors.primaryLight, ESUNColors.primary400, ESUNColors.primary300, ESUNColors.primary200];
    for (final t in txns) {
      if (t.recipientName != null && t.recipientName!.isNotEmpty && !seen.contains(t.recipientName)) {
        seen.add(t.recipientName!);
        final initials = t.recipientName!.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
        people.add(_RecentPerson(t.recipientName!, initials, '₹${t.amount.toStringAsFixed(0)}', colors[people.length % colors.length]));
        if (people.length >= 5) break;
      }
    }
    if (people.isEmpty) {
      return [
        _RecentPerson('Rahul S', 'RS', '₹5,000', ESUNColors.primary),
        _RecentPerson('Priya M', 'PM', '₹2,500', ESUNColors.primaryLight),
        _RecentPerson('Amit K', 'AK', '₹1,200', ESUNColors.primary400),
      ];
    }
    return people;
  }

  @override
  void initState() {
    super.initState();
    _scanPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRequestContacts();
    });
  }
  
  @override
  void dispose() {
    _scanPulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _maybeRequestContacts() async {
    if (_permissionAsked) return;
    _permissionAsked = true;
    
    final status = await Permission.contacts.status;
    if (status.isGranted) {
      await _loadContacts(requestPermission: false);
    }
  }

  Future<void> _loadContacts({bool requestPermission = false}) async {

    final status = await Permission.contacts.status;
    var granted = status.isGranted;
    if (!granted && requestPermission) {
      final result = await Permission.contacts.request();
      granted = result.isGranted;
    }

    if (!mounted) return;

    if (!granted) {
      setState(() {
        _contactsGranted = false;
        _contacts = [];
      });
      return;
    }

    try {
      final list = await fc.FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      
      if (!mounted) return;

      final colors = [ESUNColors.primary, ESUNColors.primaryLight, ESUNColors.primary400, ESUNColors.primary300, ESUNColors.primary200, ESUNColors.primaryDark, ESUNColors.primary500];
      
      final mapped = list
          .where((c) => (c.displayName.isNotEmpty) || c.phones.isNotEmpty)
          .take(15)
          .toList()
          .asMap()
          .map((index, c) {
            final initials = _initialsFromName(c.displayName);
            final rawPhone = c.phones.isNotEmpty ? c.phones.first.number : '';
            final phone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
            return MapEntry(index, _PaymentContact(
              c.displayName, 
              initials, 
              phone, 
              colors[index % colors.length],
            ));
          })
          .values
          .toList();

      setState(() {
        _contactsGranted = true;
        _contacts = mapped;
      });
    } catch (e) {
      setState(() {
        _contactsGranted = true;
      });
    }
  }

  String _initialsFromName(String name) {
    if (name.trim().isEmpty) return '+';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Profile & Help
              _buildTopBar(context),
              
              // Wallet Banner
              _buildWalletBanner(context),
              
              // Money Transfers Section
              _buildMoneyTransfersSection(context),
              
              // Quick Action Cards
              _buildQuickActionCards(context),
              
              // Recharge & Bills Section
              _buildRechargeBillsSection(context),
              
              // Loans Section
              _buildLoansSection(context),
              
              // Offers & Rewards
              _buildOffersBanner(context),
              
              // Recent Transactions
              _buildRecentTransactions(context),
              
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Profile Avatar with QR badge
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: ESUNColors.primary,
                  child: Text(
                    _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF5F6FA), width: 1.5),
                    ),
                    child: const Icon(Icons.qr_code, size: 12, color: ESUNColors.primary),
                  ),
                ),
              ],
            ),
          ),
          // Right side: Rewards + Help
          Row(
            children: [
              // Rewards button
              GestureDetector(
                onTap: () => context.push(AppRoutes.rewards),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ESUNColors.primary, ESUNColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: ESUNColors.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.card_giftcard_rounded, color: Colors.amber, size: 16),
                      SizedBox(width: 5),
                      Text(
                        'Rewards',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Help Icon
              GestureDetector(
                onTap: () => _showHelpSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ESUNColors.primary.withValues(alpha: 0.2), width: 1.5),
                  ),
                  child: const Icon(Icons.help_outline, color: ESUNColors.primary, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildWalletBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBalanceSheet(context),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ESUNColors.primary.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/images/payment-hero.png',
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback navy gradient if image not found
              return Container(
                height: 180,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ESUNColors.primary,
                      ESUNColors.primaryLight,
                      ESUNColors.primary400,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.white.withValues(alpha: 0.7), size: 48),
                      const SizedBox(height: 8),
                      const Text('Payments', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildMoneyTransfersSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Money Transfers',
                style: ESUNTypography.titleSmall.copyWith(
                  color: ESUNColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              // Refer & Earn
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: ESUNColors.primary900,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ESUNColors.primary700, width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: ESUNColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.currency_rupee, color: Colors.white, size: 12),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Refer → ₹200',
                      style: TextStyle(
                        color: ESUNColors.secondaryLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Transfer Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTransferAction(
                Icons.phone_android,
                'To Mobile\nNumber',
                ESUNColors.primary,
                () => _showPayToPhone(context),
              ),
              _buildTransferAction(
                Icons.account_balance,
                'To Bank &\nSelf A/c',
                ESUNColors.primary,
                () => _showBankTransferSheet(context),
              ),
              _buildTransferAction(
                Icons.download_rounded,
                'Receive\nMoney',
                ESUNColors.primary,
                () => showQrBottomSheet(context, name: _name, upiId: _upiId, bankLabel: _bankLabel),
              ),
              _buildTransferAction(
                Icons.currency_rupee,
                'Check\nBalance',
                ESUNColors.primary,
                () => _showBalanceSheet(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTransferAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: ESUNColors.textSecondary,
              fontSize: 11,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  void _showBalanceSheet(BuildContext context) {
    final aaData = ref.read(aaDataProvider);
    final accounts = aaData.bankAccounts;
    final totalBalance = accounts.fold<double>(0, (sum, a) => sum + a.balance);
    
    final accountColors = [
      ESUNColors.primary,
      ESUNColors.primaryLight,
      ESUNColors.primary400,
      ESUNColors.primary300,
    ];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Account Balances', style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(ESUNSpacing.md),
                decoration: BoxDecoration(
                  color: ESUNColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Balance', style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textSecondary)),
                    Text(totalBalance.toINR(), style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: ESUNColors.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(accounts.length, (i) {
                final account = accounts[i];
                final color = accountColors[i % accountColors.length];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(ESUNSpacing.md),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withValues(alpha: 0.2)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: account.effectiveLogoUrl != null
                              ? Image.network(account.effectiveLogoUrl!, fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Icon(Icons.account_balance, color: color, size: 20))
                              : Icon(Icons.account_balance, color: color, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(account.bankName, style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                            Text('${account.accountType} •••• ${account.accountNumber.length >= 4 ? account.accountNumber.substring(account.accountNumber.length - 4) : account.accountNumber}',
                              style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
                          ],
                        ),
                      ),
                      Text(account.balance.toINR(), style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.bold, color: color)),
                    ],
                  ),
                );
              }),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuickActionCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Save VISA Card
          Expanded(
            child: GestureDetector(
              onTap: () => _showCreditCardPayment(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ESUNColors.primary.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Text('VISA', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Save VISA Card to pay faster',
                        style: TextStyle(color: ESUNColors.textSecondary, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Start saving in Silver
          Expanded(
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Silver savings coming soon!')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ESUNColors.primary.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.monetization_on, color: Colors.grey.shade500, size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Start saving in pure Silver',
                        style: TextStyle(color: ESUNColors.textSecondary, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRechargeBillsSection(BuildContext context) {
    final items = [
      _BillItem(Icons.phone_android, 'Mobile\nRecharge', ESUNColors.primary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileRechargeScreen()))),
      _BillItem(Icons.credit_card, 'Credit Card\nBill', ESUNColors.secondary, () => _showCreditCardPayment(context)),
      _BillItem(Icons.lightbulb_outline, 'Electricity\nBill', ESUNColors.warning, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ElectricityProviderScreen()))),
      _BillItem(Icons.calendar_today, 'Loan\nRepayment', ESUNColors.primaryLight, () => _showBillPayment(context, 'Loan Repayment', Icons.calendar_today, ESUNColors.primaryLight)),
    ];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recharge & Bills',
            style: ESUNTypography.titleSmall.copyWith(
              color: ESUNColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) => _buildBillAction(item)).toList(),
          ),
          const SizedBox(height: 16),
          // Bottom row with Jio SIM and More
          Row(
            children: [
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileRechargeScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ESUNColors.primary.withValues(alpha: 0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Buy Jio SIM:Home Delivered',
                            style: TextStyle(color: ESUNColors.textSecondary, fontSize: 12),
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Center(
                            child: Text('Jio', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showMoreBills(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ESUNColors.primary.withValues(alpha: 0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'More',
                          style: TextStyle(color: ESUNColors.textSecondary, fontSize: 13),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, color: ESUNColors.textSecondary, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildBillAction(_BillItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: SizedBox(
        width: 75,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ESUNColors.primary.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(item.icon, color: item.color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: const TextStyle(
                color: ESUNColors.textSecondary,
                fontSize: 10.5,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoansSection(BuildContext context) {
    final loanItems = [
      {'icon': Icons.person, 'label': 'Personal\nLoan', 'color': ESUNColors.primary},
      {'icon': Icons.bar_chart, 'label': 'Mutual\nFunds', 'color': ESUNColors.accent},
      {'icon': Icons.card_giftcard, 'label': 'Gold\nLoan', 'color': ESUNColors.warning},
      {'icon': Icons.speed, 'label': 'Credit\nScore', 'color': ESUNColors.error},
    ];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Loans',
            style: ESUNTypography.titleSmall.copyWith(
              color: ESUNColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: loanItems.map((item) {
              return GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${(item['label'] as String).replaceAll('\n', ' ')} coming soon!')),
                  );
                },
                child: SizedBox(
                  width: 75,
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: ESUNColors.primary.withValues(alpha: 0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 26),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['label'] as String,
                        style: const TextStyle(
                          color: ESUNColors.textSecondary,
                          fontSize: 10.5,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBusinessSection(BuildContext context) {
    return const SizedBox.shrink();
  }
  
  Widget _buildOffersBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ESUNColors.primary,
            ESUNColors.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ESUNColors.primary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_offer, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get ₹50 Cashback',
                  style: ESUNTypography.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'On your first bill payment',
                  style: ESUNTypography.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: ESUNSpacing.chipInsets,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Claim',
              style: ESUNTypography.labelSmall.copyWith(
                color: ESUNColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRewardsBanner(BuildContext context) {
    return const SizedBox.shrink();
  }
  
  Widget _buildRecentTransactions(BuildContext context) {
    final recentTransactions = ref.watch(recentTransactionsProvider);
    
    String getTimeAgo(DateTime dateTime) {
      final now = DateTime.now();
      final diff = now.difference(dateTime);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${(diff.inDays / 7).floor()}w ago';
    }
    
    IconData getIcon(TransactionType type) {
      switch (type) {
        case TransactionType.billPayment: return Icons.receipt_long_rounded;
        case TransactionType.upiTransfer: return Icons.send_rounded;
        case TransactionType.bankTransfer: return Icons.account_balance_rounded;
        case TransactionType.recharge: return Icons.smartphone_rounded;
        case TransactionType.income: return Icons.account_balance_rounded;
        case TransactionType.refund: return Icons.replay_rounded;
      }
    }
    
    Color getIconColor(TransactionType type, bool isDebit) {
      if (!isDebit) return ESUNColors.success;
      switch (type) {
        case TransactionType.billPayment: return ESUNColors.primary;
        case TransactionType.upiTransfer: return ESUNColors.primary;
        case TransactionType.bankTransfer: return ESUNColors.primary;
        case TransactionType.recharge: return ESUNColors.primary;
        case TransactionType.income: return ESUNColors.success;
        case TransactionType.refund: return ESUNColors.success;
      }
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transaction History',
                style: ESUNTypography.titleSmall.copyWith(
                  color: ESUNColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () => _openHistory(context),
                child: Text(
                  'See All',
                  style: ESUNTypography.labelSmall.copyWith(
                    color: ESUNColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (recentTransactions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(ESUNSpacing.xxl),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text('No transactions yet', style: ESUNTypography.bodyMedium.copyWith(color: const Color(0xFF718096))),
                  ],
                ),
              ),
            )
          else
            ...recentTransactions.take(5).map((tx) {
              final iconColor = getIconColor(tx.type, tx.isDebit);
              final amountText = tx.isDebit ? '-₹${tx.amount.toStringAsFixed(0)}' : '+₹${tx.amount.toStringAsFixed(0)}';
              final category = tx.category ?? (tx.isDebit ? 'Payment' : 'Income');
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(ESUNSpacing.md),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(getIcon(tx.type), color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tx.title, style: ESUNTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500, color: ESUNColors.primary)),
                          Text('$category • ${getTimeAgo(tx.timestamp)}', style: ESUNTypography.labelSmall.copyWith(color: const Color(0xFF718096))),
                        ],
                      ),
                    ),
                    Text(
                      amountText,
                      style: ESUNTypography.bodyMedium.copyWith(
                        color: tx.isDebit ? ESUNColors.error : ESUNColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
  
  // Bottom Sheets
  void _showPayToContact(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SendMoneyScreen(
          recipientName: 'Select Contact',
        ),
      ),
    );
  }
  
  void _showPayToPhone(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PayToPhoneSheet(
        contacts: _contacts,
        contactsGranted: _contactsGranted,
        onLoadContacts: () => _loadContacts(requestPermission: true),
        onSelectContact: (name, phone) {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SendMoneyScreen(
                recipientName: name,
                recipientPhone: phone,
                avatarColor: ESUNColors.primary,
              ),
            ),
          );
        },
        onContinueWithPhone: (phone) {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SendMoneyScreen(
                recipientName: 'Phone User',
                recipientPhone: phone,
                avatarColor: ESUNColors.primary,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showBankTransferSheet(BuildContext context) {
    final accountController = TextEditingController();
    final ifscController = TextEditingController();
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String transferMode = 'IMPS';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(ESUNSpacing.xl),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(ESUNSpacing.md),
                        decoration: BoxDecoration(
                          color: ESUNColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.account_balance, color: ESUNColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Text('Bank Transfer', style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Transfer Mode Chips
                      Row(
                        children: ['IMPS', 'NEFT', 'RTGS'].map((mode) {
                          final isSelected = transferMode == mode;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => transferMode = mode),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? ESUNColors.primary : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    mode,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      _buildInputField(accountController, 'Account Number', Icons.account_balance_wallet_outlined, TextInputType.number),
                      const SizedBox(height: 16),
                      _buildInputField(ifscController, 'IFSC Code', Icons.code, TextInputType.text, textCaps: true),
                      const SizedBox(height: 16),
                      _buildInputField(nameController, 'Beneficiary Name', Icons.person_outline, TextInputType.name),
                      const SizedBox(height: 16),
                      _buildInputField(amountController, 'Amount (₹)', Icons.currency_rupee, TextInputType.number),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          if (accountController.text.isEmpty || ifscController.text.isEmpty || amountController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill all required fields')),
                            );
                            return;
                          }
                          final amount = double.tryParse(amountController.text) ?? 0;
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentSuccessScreen(
                                amount: amount,
                                transactionId: 'BANK${DateTime.now().millisecondsSinceEpoch}',
                                payeeName: nameController.text.isNotEmpty ? nameController.text : 'Beneficiary',
                                paymentType: '$transferMode Transfer',
                                icon: Icons.account_balance,
                                color: ESUNColors.primary,
                              ),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Transfer Now', style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          transferMode == 'IMPS' ? 'Instant transfer, 24x7 available' :
                          transferMode == 'NEFT' ? 'Settlement every 30 mins' : 'For amounts > ₹2L',
                          style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textTertiary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Show UPI PIN entry dialog for payment authentication
  void _showUpiPinDialog(
    BuildContext context, {
    required double amount,
    required String payeeName,
    required Color color,
    required VoidCallback onSuccess,
  }) {
    String pin = '';
    bool isVerifying = false;
    
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(ESUNSpacing.xl),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    Column(
                      children: [
                        Text(
                          'Enter UPI PIN',
                          style: ESUNTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'to pay ₹${amount.toStringAsFixed(0)} to $payeeName',
                          style: ESUNTypography.bodySmall.copyWith(
                            color: ESUNColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final isFilled = index < pin.length;
                  return Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? color : Colors.transparent,
                      border: Border.all(
                        color: isFilled ? color : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              
              if (isVerifying) ...[
                const SizedBox(height: 12),
                const CircularProgressIndicator(),
              ],
              
              const Spacer(),
              
              // Number pad
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    for (var row in [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9'], ['', '0', 'del']])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: row.map((key) {
                            if (key.isEmpty) return const SizedBox(width: 60, height: 60);
                            final isDelete = key == 'del';
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: isVerifying ? null : () {
                                  if (isDelete) {
                                    if (pin.isNotEmpty) {
                                      setState(() => pin = pin.substring(0, pin.length - 1));
                                    }
                                  } else if (pin.length < 6) {
                                    setState(() => pin += key);
                                    if (pin.length == 6) {
                                      setState(() => isVerifying = true);
                                      Future.delayed(const Duration(milliseconds: 700), () {
                                        Navigator.pop(ctx);
                                        onSuccess();
                                      });
                                    }
                                  }
                                },
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDelete ? Colors.transparent : Colors.grey.shade100,
                                  ),
                                  child: Center(
                                    child: isDelete
                                        ? const Icon(Icons.backspace_outlined, size: 20)
                                        : Text(key, style: ESUNTypography.titleLarge),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('Secured by UPI', style: ESUNTypography.labelSmall.copyWith(color: Colors.grey[600])),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInputField(TextEditingController controller, String label, IconData icon, TextInputType type, {bool textCaps = false}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      textCapitalization: textCaps ? TextCapitalization.characters : TextCapitalization.none,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
      ),
    );
  }

  void _showSelfTransferSheet(BuildContext context) {
    final amountController = TextEditingController();
    
    final aaData = ref.read(aaDataProvider);
    final bankAccounts = aaData.bankAccounts;
    final accounts = bankAccounts.isEmpty
        ? ['HDFC Bank SAVINGS •• 1234', 'ICICI Bank SAVINGS •• 5678', 'SBI CURRENT •• 9012']
        : bankAccounts.map((a) {
            final last4 = a.accountNumber.length >= 4 
                ? a.accountNumber.substring(a.accountNumber.length - 4) 
                : a.accountNumber;
            return '${a.bankName} ${a.accountType} •• $last4';
          }).toList();
    
    String fromAccount = accounts.first;
    String toAccount = accounts.length > 1 ? accounts[1] : accounts.first;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(ESUNSpacing.xl),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(ESUNSpacing.md),
                      decoration: BoxDecoration(
                        color: ESUNColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.swap_horiz, color: ESUNColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Text('Self Transfer', style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildAccountSelector('From', fromAccount, accounts, (val) => setState(() => fromAccount = val!)),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            final temp = fromAccount;
                            fromAccount = toAccount;
                            toAccount = temp;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(ESUNSpacing.md),
                          decoration: BoxDecoration(
                            color: ESUNColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.swap_vert, color: ESUNColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAccountSelector('To', toAccount, accounts, (val) => setState(() => toAccount = val!)),
                    const SizedBox(height: 12),
                    _buildInputField(amountController, 'Amount (₹)', Icons.currency_rupee, TextInputType.number),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        if (amountController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter amount')),
                          );
                          return;
                        }
                        if (fromAccount == toAccount) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Select different accounts')),
                          );
                          return;
                        }
                        final amount = double.tryParse(amountController.text) ?? 0;
                        // Show UPI PIN dialog before completing transfer
                        _showUpiPinDialog(
                          context,
                          amount: amount,
                          payeeName: toAccount,
                          color: ESUNColors.primary,
                          onSuccess: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentSuccessScreen(
                                  amount: amount,
                                  transactionId: 'SELF${DateTime.now().millisecondsSinceEpoch}',
                                  payeeName: toAccount,
                                  paymentType: 'Self Transfer',
                                  icon: Icons.swap_horiz,
                                  color: ESUNColors.primary,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: ESUNColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Transfer', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAccountSelector(String label, String value, List<String> accounts, void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down),
            items: accounts.map((acc) => DropdownMenuItem(value: acc, child: Text(acc))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // ============== NEW HELPER METHODS ==============

  void _openHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PaymentHistoryScreen()),
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ESUNSpacing.xl),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(ESUNSpacing.md),
                    decoration: BoxDecoration(
                      color: ESUNColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.help_outline, color: ESUNColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Text('Help & Support', style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildHelpItem(Icons.payment, 'Payment Issues', 'Get help with failed or pending payments', () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening payment support...')),
                    );
                  }),
                  _buildHelpItem(Icons.receipt_long, 'Transaction Disputes', 'Raise a dispute for incorrect transaction', () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening dispute form...')),
                    );
                  }),
                  _buildHelpItem(Icons.security, 'Report Fraud', 'Report suspicious activity', () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening fraud report...')),
                    );
                  }),
                  _buildHelpItem(Icons.account_balance, 'Bank Account Issues', 'Help linking or removing accounts', () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening account support...')),
                    );
                  }),
                  _buildHelpItem(Icons.chat_bubble_outline, 'Chat with Us', '24/7 customer support', () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Connecting to support...')),
                    );
                  }),
                  _buildHelpItem(Icons.phone, 'Call Support', '+91 1800-123-4567', () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Calling support...')),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(ESUNSpacing.md),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.grey[700]),
      ),
      title: Text(title, style: ESUNTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: ESUNTypography.labelSmall.copyWith(color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showVoiceSearch(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(ESUNSpacing.xxl),
              decoration: BoxDecoration(
                color: ESUNColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, size: 48, color: ESUNColors.primary),
            ),
            const SizedBox(height: 12),
            const Text('Listening...', style: ESUNTypography.titleMedium),
            const SizedBox(height: 8),
            Text('Say a name or UPI ID', style: ESUNTypography.bodyMedium.copyWith(color: Colors.grey)),
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
        ),
      ),
    );
    
    // Auto close after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice search coming soon')),
        );
      }
    });
  }

  void _showAllContacts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(ESUNSpacing.xl),
                child: Row(
                  children: [
                    Text('All Contacts', style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _contacts.isEmpty && !_contactsGranted
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.contacts, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('No contacts available'),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _loadContacts(requestPermission: true);
                              },
                              child: const Text('Allow Contacts Access'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: controller,
                        itemCount: _contacts.isEmpty ? _recentPeople.length : _contacts.length,
                        itemBuilder: (context, index) {
                          if (_contacts.isEmpty) {
                            final person = _recentPeople[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: person.color,
                                child: Text(person.initials, style: const TextStyle(color: Colors.white)),
                              ),
                              title: Text(person.name),
                              subtitle: Text(person.lastAmount),
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(
                                    builder: (_) => SendMoneyScreen(
                                      recipientName: person.name,
                                      recipientUpiId: '${person.name.toLowerCase().replaceAll(' ', '.')}@upi',
                                      avatarColor: person.color,
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                          final contact = _contacts[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: contact.color.withOpacity(0.2),
                              child: Text(contact.initial, style: TextStyle(color: contact.color)),
                            ),
                            title: Text(contact.name),
                            subtitle: Text(contact.phone),
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context, 
                                MaterialPageRoute(
                                  builder: (_) => SendMoneyScreen(
                                    recipientName: contact.name,
                                    recipientPhone: contact.phone,
                                    avatarColor: contact.color,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBillPayment(BuildContext context, String billType, IconData icon, Color color) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillPaymentScreen(
          billType: billType,
          icon: icon,
          color: color,
        ),
      ),
    );
  }

  void _showCreditCardPayment(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ESUNSpacing.xl),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(ESUNSpacing.md),
                    decoration: BoxDecoration(
                      color: ESUNColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.credit_card, color: ESUNColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Text('Credit Card Bill', style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildCreditCardItem('HDFC Credit Card', '•••• 4532', '₹45,678', 'Due: Mar 15', ESUNColors.primary),
                  _buildCreditCardItem('ICICI Amazon Pay', '•••• 8901', '₹12,340', 'Due: Mar 18', ESUNColors.primaryLight),
                  _buildCreditCardItem('SBI Card', '•••• 2345', '₹8,500', 'Due: Mar 20', ESUNColors.primaryDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCardItem(String name, String number, String amount, String due, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(number, style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Due', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(amount, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  final parsedAmount = double.tryParse(amount.replaceAll(RegExp(r'[₹,]'), '')) ?? 0;
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (_) => PaymentSuccessScreen(
                        amount: parsedAmount,
                        transactionId: 'CC${DateTime.now().millisecondsSinceEpoch}',
                        payeeName: name,
                        paymentType: 'Credit Card Bill',
                        icon: Icons.credit_card,
                        color: color,
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: color,
                ),
                child: const Text('Pay Now'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(due, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  void _showMoreBills(BuildContext context) {
    final moreBills = [
      {'icon': Icons.apartment, 'label': 'Rent', 'color': ESUNColors.primary},
      {'icon': Icons.school, 'label': 'Education', 'color': ESUNColors.primary},
      {'icon': Icons.local_hospital, 'label': 'Hospital', 'color': ESUNColors.primary},
      {'icon': Icons.directions_car, 'label': 'Challan', 'color': ESUNColors.primary},
      {'icon': Icons.flight, 'label': 'Travel', 'color': ESUNColors.primary},
      {'icon': Icons.movie, 'label': 'Entertainment', 'color': ESUNColors.primary},
      {'icon': Icons.shopping_cart, 'label': 'Shopping', 'color': ESUNColors.primary},
      {'icon': Icons.fitness_center, 'label': 'Gym', 'color': ESUNColors.primary},
    ];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ESUNSpacing.xl),
              child: Text('More Bills & Payments', style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(ESUNSpacing.xl),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                ),
                itemCount: moreBills.length,
                itemBuilder: (context, index) {
                  final bill = moreBills[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showBillPayment(context, bill['label'] as String, bill['icon'] as IconData, bill['color'] as Color);
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(ESUNSpacing.lg),
                          decoration: BoxDecoration(
                            color: (bill['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(bill['icon'] as IconData, color: bill['color'] as Color, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bill['label'] as String,
                          style: ESUNTypography.labelSmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMerchantPayment(BuildContext context) {
    final merchantController = TextEditingController();
    final amountController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(ESUNSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(ESUNSpacing.md),
                    decoration: BoxDecoration(
                      color: ESUNColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.store, color: ESUNColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Text('Pay Merchant', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: merchantController,
                decoration: InputDecoration(
                  labelText: 'Merchant UPI ID or Name',
                  prefixIcon: const Icon(Icons.store),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.05),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.05),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push(AppRoutes.scanQr);
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan QR'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (merchantController.text.isEmpty || amountController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all fields')),
                          );
                          return;
                        }
                        final amount = double.tryParse(amountController.text) ?? 0;
                        Navigator.pop(ctx);
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (_) => PaymentSuccessScreen(
                              amount: amount,
                              transactionId: 'MER${DateTime.now().millisecondsSinceEpoch}',
                              payeeName: merchantController.text,
                              paymentType: 'Merchant Payment',
                              icon: Icons.store,
                              color: ESUNColors.primary,
                            ),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: ESUNColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Pay'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showInvoicePayment(BuildContext context) {
    final invoiceController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(ESUNSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(ESUNSpacing.md),
                    decoration: BoxDecoration(
                      color: ESUNColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long, color: ESUNColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Text('Pay Invoice', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: invoiceController,
                decoration: InputDecoration(
                  labelText: 'Invoice Number',
                  prefixIcon: const Icon(Icons.receipt),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.05),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (invoiceController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter invoice number')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    // Navigate to bill payment for invoice
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BillPaymentScreen(
                          billType: 'Invoice Payment',
                          icon: Icons.receipt_long,
                          color: ESUNColors.primary,
                          prefillNumber: invoiceController.text,
                          prefillAmount: '15000',
                        ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: ESUNColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Fetch Invoice'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showVendorPayment(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ESUNSpacing.xl),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(ESUNSpacing.md),
                    decoration: BoxDecoration(
                      color: ESUNColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.local_shipping, color: ESUNColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Text('Pay Vendor', style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildVendorItem('ABC Supplies', 'Pending: ₹25,000', 'Due: Mar 12', ESUNColors.primary),
                  _buildVendorItem('XYZ Electronics', 'Pending: ₹15,500', 'Due: Mar 15', ESUNColors.primaryLight),
                  _buildVendorItem('Office Mart', 'Pending: ₹8,200', 'Due: Mar 20', ESUNColors.primary400),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ESUNSpacing.xl),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showBankTransferSheet(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Vendor'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorItem(String name, String amount, String due, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.md),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.business, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: ESUNTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                Text(amount, style: ESUNTypography.bodySmall.copyWith(color: Colors.grey[600])),
                Text(due, style: ESUNTypography.labelSmall.copyWith(color: color)),
              ],
            ),
          ),
          FilledButton(
            onPressed: () {
              // Parse amount from string like "Pending: ₹25,000"
              final amountStr = amount.replaceAll(RegExp(r'[^0-9]'), '');
              final parsedAmount = double.tryParse(amountStr) ?? 0;
              Navigator.pop(context);
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (_) => PaymentSuccessScreen(
                    amount: parsedAmount,
                    transactionId: 'VEN${DateTime.now().millisecondsSinceEpoch}',
                    payeeName: name,
                    paymentType: 'Vendor Payment',
                    icon: Icons.local_shipping,
                    color: color,
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: color,
              minimumSize: const Size(70, 36),
            ),
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }
}

// --- Pay to Phone Bottom Sheet Widget ---
class _PayToPhoneSheet extends StatefulWidget {
  final List<_PaymentContact> contacts;
  final bool contactsGranted;
  final VoidCallback onLoadContacts;
  final void Function(String name, String phone) onSelectContact;
  final void Function(String phone) onContinueWithPhone;

  const _PayToPhoneSheet({
    required this.contacts,
    required this.contactsGranted,
    required this.onLoadContacts,
    required this.onSelectContact,
    required this.onContinueWithPhone,
  });

  @override
  State<_PayToPhoneSheet> createState() => _PayToPhoneSheetState();
}

class _PayToPhoneSheetState extends State<_PayToPhoneSheet> {
  final _phoneController = TextEditingController();
  final _focusNode = FocusNode();
  List<_PaymentContact> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.contacts;
    _phoneController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    final query = _phoneController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.contacts;
      } else {
        _filtered = widget.contacts.where((c) {
          return c.name.toLowerCase().contains(query) ||
              c.phone.contains(query);
        }).toList();
      }
    });
  }

  bool get _isValidPhone {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(ESUNSpacing.xl, ESUNSpacing.lg, ESUNSpacing.xl, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(ESUNSpacing.md),
                  decoration: BoxDecoration(
                    color: ESUNColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.phone_android, color: ESUNColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pay to Number',
                    style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(ESUNSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Search / phone input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _phoneController,
              focusNode: _focusNode,
              keyboardType: TextInputType.phone,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter number or search contacts',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 8),
                  child: Icon(Icons.search_rounded, color: Colors.grey.shade500, size: 22),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 44),
                suffixIcon: _phoneController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _phoneController.clear();
                          setState(() {});
                        },
                        child: Icon(Icons.cancel, size: 20, color: Colors.grey.shade400),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: ESUNColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Continue button when valid phone entered
          if (_isValidPhone)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
                    widget.onContinueWithPhone(digits.length > 10 ? digits.substring(digits.length - 10) : digits);
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text('Pay to ${_phoneController.text}', style: const TextStyle(fontSize: 15)),
                  style: FilledButton.styleFrom(
                    backgroundColor: ESUNColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),

          const Divider(height: 20),

          // Contacts section
          if (!widget.contactsGranted)
            // Permission not granted - show prompt
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: InkWell(
                onTap: widget.onLoadContacts,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(ESUNSpacing.lg),
                  decoration: BoxDecoration(
                    color: ESUNColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ESUNColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(ESUNSpacing.sm),
                        decoration: BoxDecoration(
                          color: ESUNColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.contacts_rounded, color: ESUNColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Allow Contact Access', style: ESUNTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('Search & select from your contacts', style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textTertiary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: ESUNColors.primary),
                    ],
                  ),
                ),
              ),
            )
          else if (widget.contacts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(ESUNSpacing.xxl),
              child: Column(
                children: [
                  Icon(Icons.person_search_rounded, size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text('No contacts found', style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textTertiary)),
                ],
              ),
            )
          else ...[
              // Section header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.people_alt_rounded, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(
                      _phoneController.text.isEmpty ? 'Your Contacts' : '${_filtered.length} result${_filtered.length == 1 ? '' : 's'}',
                      style: ESUNTypography.labelMedium.copyWith(
                        color: ESUNColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Contact list
              Flexible(
                child: _filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(ESUNSpacing.xxl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded, size: 36, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text('No matching contacts', style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textTertiary)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
                        itemBuilder: (context, index) {
                          final c = _filtered[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: c.color.withOpacity(0.15),
                              child: Text(c.initial, style: TextStyle(color: c.color, fontWeight: FontWeight.w600, fontSize: 14)),
                            ),
                            title: Text(c.name, style: ESUNTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
                            subtitle: c.phone.isNotEmpty
                                ? Text(c.phone, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textTertiary))
                                : null,
                            trailing: Container(
                              padding: ESUNSpacing.chipInsets,
                              decoration: BoxDecoration(
                                color: ESUNColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Pay', style: TextStyle(color: ESUNColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onTap: () {
                              if (c.phone.isNotEmpty) {
                                widget.onSelectContact(c.name, c.phone);
                              }
                            },
                          );
                        },
                      ),
              ),
            ],

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

// Data Classes
class _PaymentContact {
  final String name;
  final String initial;
  final String phone;
  final Color color;
  
  _PaymentContact(this.name, this.initial, this.phone, this.color);
}

class _RecentPerson {
  final String name;
  final String initials;
  final String lastAmount;
  final Color color;
  
  _RecentPerson(this.name, this.initials, this.lastAmount, this.color);
}

class _QuickPayAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  
  _QuickPayAction(this.icon, this.label, this.color, this.onTap);
}

class _BillItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  
  _BillItem(this.icon, this.label, this.color, this.onTap);
}


