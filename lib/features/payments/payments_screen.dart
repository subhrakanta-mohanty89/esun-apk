/// ESUN Pay Screen - Production Level
/// 
/// Inspired by Google Pay and PhonePe with modern UX patterns

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
import 'upi_payment_demo_screen.dart';
import 'payment_history_screen.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> with SingleTickerProviderStateMixin {
  static const String _upiId = 'john.doe@ESUN';
  static const String _name = 'John Doe';
  static const String _bankLabel = 'HDFC • 1234';

  bool _isLoadingContacts = false;
  bool _contactsGranted = false;
  List<_PaymentContact> _contacts = [];
  bool _permissionAsked = false;
  
  late AnimationController _scanPulseController;
  
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchFocused = false;
  
  // Recent transactions for quick repeat
  final List<_RecentPerson> _recentPeople = [
    _RecentPerson('Rahul S', 'RS', '₹5,000', Colors.blue),
    _RecentPerson('Priya M', 'PM', '₹2,500', Colors.purple),
    _RecentPerson('Amit K', 'AK', '₹1,200', Colors.green),
    _RecentPerson('Sneha P', 'SP', '₹800', Colors.orange),
    _RecentPerson('Vikram R', 'VR', '₹3,500', Colors.teal),
  ];

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
    setState(() => _isLoadingContacts = true);

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
        _isLoadingContacts = false;
        _contacts = [];
      });
      return;
    }

    try {
      final list = await fc.FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      
      final colors = [Colors.blue, Colors.purple, Colors.green, Colors.orange, Colors.teal, Colors.pink, Colors.indigo];
      
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
        _isLoadingContacts = false;
        _contacts = mapped;
      });
    } catch (e) {
      setState(() {
        _contactsGranted = true;
        _isLoadingContacts = false;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? ESUNColors.darkBackground : const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with gradient
          _buildSliverAppBar(context, isDark),
          
          // Main Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Search Bar
                _buildSearchBar(context, isDark),
                
                // Scan & Pay Hero Section
                _buildScanPayHero(context),
                
                // Quick Actions Grid
                _buildQuickActionsGrid(context),
                
                // People Section
                _buildPeopleSection(context),
                
                // Bills & Recharge
                _buildBillsRechargeSection(context),
                
                // Business Payments
                _buildBusinessSection(context),
                
                // Offers Banner
                _buildOffersBanner(context),
                
                // Recent Transactions
                _buildRecentTransactions(context),
                
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSliverAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: ESUNColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A3A7A),
                Color(0xFF2E4A9A),
                Color(0xFF3D5CB8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Pay',
                        style: ESUNTypography.headlineLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified, color: Colors.greenAccent, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              _upiId,
                              style: ESUNTypography.labelSmall.copyWith(color: Colors.white),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: _upiId));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('UPI ID copied!'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: const Icon(Icons.copy, color: Colors.white70, size: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildAppBarAction(
                        Icons.qr_code_2_rounded,
                        'QR',
                        () => showQrBottomSheet(context, name: _name, upiId: _upiId, bankLabel: _bankLabel),
                      ),
                      const SizedBox(width: 12),
                      _buildAppBarAction(Icons.history, 'History', () => _openHistory(context)),
                      const SizedBox(width: 12),
                      _buildAppBarAction(Icons.help_outline, 'Help', () => _showHelpSheet(context)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAppBarAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label, style: ESUNTypography.labelSmall.copyWith(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? ESUNColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        onTap: () => setState(() => _isSearchFocused = true),
        onEditingComplete: () => setState(() => _isSearchFocused = false),
        decoration: InputDecoration(
          hintText: 'Pay by name, phone, UPI ID, or bank',
          hintStyle: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textTertiary),
          prefixIcon: const Icon(Icons.search, color: ESUNColors.textTertiary),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 1,
                height: 24,
                color: Colors.grey.withOpacity(0.3),
              ),
              IconButton(
                icon: const Icon(Icons.mic, color: ESUNColors.primary),
                onPressed: () => _showVoiceSearch(context),
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
  
  Widget _buildScanPayHero(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Scan & Pay Button
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                context.push(AppRoutes.scanQr);
              },
              child: AnimatedBuilder(
                animation: _scanPulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ESUNColors.primary.withOpacity(0.9 + _scanPulseController.value * 0.1),
                          const Color(0xFF3D5CB8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: ESUNColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scan & Pay',
                                style: ESUNTypography.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pay any UPI QR code',
                                style: ESUNTypography.labelSmall.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Check Balance
          Expanded(
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Balance: ₹5,42,350.75')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: Colors.green, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Balance',
                      style: ESUNTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w600,
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
  
  Widget _buildQuickActionsGrid(BuildContext context) {
    final actions = [
      _QuickPayAction(Icons.person_add_rounded, 'To Contact', Colors.blue, () => _showPayToContact(context)),
      _QuickPayAction(Icons.phone_android_rounded, 'To Phone', Colors.green, () => _showPayToPhone(context)),
      _QuickPayAction(Icons.account_balance_rounded, 'To Bank', Colors.purple, () => _showBankTransferSheet(context)),
      _QuickPayAction(Icons.swap_horiz_rounded, 'Self Transfer', Colors.teal, () => _showSelfTransferSheet(context)),
    ];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Money Transfer',
            style: ESUNTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: actions.map((action) => _buildQuickAction(action)).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickAction(_QuickPayAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: action.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(action.icon, color: action.color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            action.label,
            style: ESUNTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPeopleSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                'People',
                style: ESUNTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => _showAllContacts(context),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Recent People
          if (_recentPeople.isNotEmpty) ...[
            SizedBox(
              height: 85,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _recentPeople.length + (_contactsGranted ? 0 : 1),
                itemBuilder: (context, index) {
                  if (!_contactsGranted && index == _recentPeople.length) {
                    // Add contacts button
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: () => _loadContacts(requestPermission: true),
                        child: Column(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.withOpacity(0.3), style: BorderStyle.solid),
                              ),
                              child: const Icon(Icons.person_add, color: Colors.grey, size: 24),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Add',
                              style: ESUNTypography.labelSmall.copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  final person = _recentPeople[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UPIPaymentDemoScreen(),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  person.color,
                                  person.color.withOpacity(0.7),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                person.initials,
                                style: ESUNTypography.titleSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 60,
                            child: Text(
                              person.name,
                              style: ESUNTypography.labelSmall.copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Text(
                            person.lastAmount,
                            style: ESUNTypography.labelSmall.copyWith(
                              fontSize: 10,
                              color: ESUNColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          
          // Contacts from phone
          if (_contactsGranted && _contacts.isNotEmpty) ...[
            const Divider(height: 24),
            Text(
              'From Contacts',
              style: ESUNTypography.labelSmall.copyWith(
                color: ESUNColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 75,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _contacts.length,
                itemBuilder: (context, index) {
                  final contact = _contacts[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UPIPaymentDemoScreen(),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: contact.color.withOpacity(0.15),
                            child: Text(
                              contact.initial,
                              style: ESUNTypography.titleSmall.copyWith(
                                color: contact.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 56,
                            child: Text(
                              contact.name.split(' ').first,
                              style: ESUNTypography.labelSmall.copyWith(fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildBillsRechargeSection(BuildContext context) {
    final items = [
      _BillItem(Icons.phone_android, 'Mobile', Colors.green, () => _showBillPayment(context, 'Mobile Recharge', Icons.phone_android, Colors.green)),
      _BillItem(Icons.bolt, 'Electricity', Colors.amber, () => _showBillPayment(context, 'Electricity Bill', Icons.bolt, Colors.amber)),
      _BillItem(Icons.tv, 'DTH', Colors.purple, () => _showBillPayment(context, 'DTH Recharge', Icons.tv, Colors.purple)),
      _BillItem(Icons.wifi, 'Broadband', Colors.blue, () => _showBillPayment(context, 'Broadband Bill', Icons.wifi, Colors.blue)),
      _BillItem(Icons.water_drop, 'Water', Colors.cyan, () => _showBillPayment(context, 'Water Bill', Icons.water_drop, Colors.cyan)),
      _BillItem(Icons.local_gas_station, 'Gas Cylinder', Colors.orange, () => _showBillPayment(context, 'Gas Cylinder', Icons.local_gas_station, Colors.orange)),
      _BillItem(Icons.credit_card, 'Credit Card', Colors.red, () => _showCreditCardPayment(context)),
      _BillItem(Icons.more_horiz, 'More', Colors.grey, () => _showMoreBills(context)),
    ];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                'Bills & Recharge',
                style: ESUNTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '2 Due',
                  style: ESUNTypography.labelSmall.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.9,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: item.onTap,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.icon, color: item.color, size: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.label,
                      style: ESUNTypography.labelSmall.copyWith(fontSize: 10),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildBusinessSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Payments',
            style: ESUNTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBusinessItem(
                  Icons.store,
                  'Pay Merchant',
                  Colors.indigo,
                  () => _showMerchantPayment(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBusinessItem(
                  Icons.receipt_long,
                  'Pay Invoice',
                  Colors.teal,
                  () => _showInvoicePayment(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBusinessItem(
                  Icons.local_shipping,
                  'Pay Vendor',
                  Colors.orange,
                  () => _showVendorPayment(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildBusinessItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: ESUNTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOffersBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6B4EFF),
            Color(0xFF9B6BFF),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
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
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Claim',
              style: ESUNTypography.labelSmall.copyWith(
                color: const Color(0xFF6B4EFF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentTransactions(BuildContext context) {
    final transactions = [
      _Transaction('Rahul Sharma', 'Sent • Today, 2:30 PM', '₹5,000', Icons.person, Colors.blue, false),
      _Transaction('Mobile Recharge', 'Jio • Yesterday', '₹599', Icons.phone_android, Colors.green, false),
      _Transaction('Electricity Bill', 'BESCOM • 3 days ago', '₹2,340', Icons.bolt, Colors.amber, false),
      _Transaction('Priya Mehta', 'Received • 5 days ago', '₹12,000', Icons.person, Colors.purple, true),
    ];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => _openHistory(context),
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...transactions.map((txn) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: txn.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(txn.icon, color: txn.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        txn.title,
                        style: ESUNTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        txn.subtitle,
                        style: ESUNTypography.labelSmall.copyWith(
                          color: ESUNColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  txn.isCredit ? '+${txn.amount}' : '-${txn.amount}',
                  style: ESUNTypography.bodyMedium.copyWith(
                    color: txn.isCredit ? Colors.green : ESUNColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
  
  // Bottom Sheets
  void _showPayToContact(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UPIPaymentDemoScreen()),
    );
  }
  
  void _showPayToPhone(BuildContext context) {
    final phoneController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.phone_android, color: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Pay to Phone Number',
                    style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter 10-digit mobile number',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 16, right: 8),
                    child: Text('+91', style: TextStyle(fontSize: 16)),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 50),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.05),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UPIPaymentDemoScreen()),
                    );
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Continue', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
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
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.account_balance, color: Colors.purple),
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
                      const SizedBox(height: 20),
                      _buildInputField(accountController, 'Account Number', Icons.account_balance_wallet_outlined, TextInputType.number),
                      const SizedBox(height: 16),
                      _buildInputField(ifscController, 'IFSC Code', Icons.code, TextInputType.text, textCaps: true),
                      const SizedBox(height: 16),
                      _buildInputField(nameController, 'Beneficiary Name', Icons.person_outline, TextInputType.name),
                      const SizedBox(height: 16),
                      _buildInputField(amountController, 'Amount (₹)', Icons.currency_rupee, TextInputType.number),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () {
                          if (accountController.text.isEmpty || ifscController.text.isEmpty || amountController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill all required fields')),
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('₹${amountController.text} transferred via $transferMode')),
                          );
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
    String fromAccount = 'HDFC Savings •• 1234';
    String toAccount = 'ICICI Savings •• 5678';
    
    final accounts = [
      'HDFC Savings •• 1234',
      'ICICI Savings •• 5678',
      'SBI Savings •• 9012',
      'Axis Current •• 3456',
    ];
    
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
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.swap_horiz, color: Colors.teal),
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.swap_vert, color: Colors.teal),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAccountSelector('To', toAccount, accounts, (val) => setState(() => toAccount = val!)),
                    const SizedBox(height: 20),
                    _buildInputField(amountController, 'Amount (₹)', Icons.currency_rupee, TextInputType.number),
                    const SizedBox(height: 24),
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
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('₹${amountController.text} transferred')),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
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
        padding: const EdgeInsets.all(10),
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ESUNColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, size: 48, color: ESUNColors.primary),
            ),
            const SizedBox(height: 20),
            Text('Listening...', style: ESUNTypography.titleMedium),
            const SizedBox(height: 8),
            Text('Say a name or UPI ID', style: ESUNTypography.bodyMedium.copyWith(color: Colors.grey)),
            const SizedBox(height: 20),
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
                padding: const EdgeInsets.all(20),
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
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const UPIPaymentDemoScreen()));
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
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const UPIPaymentDemoScreen()));
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
    final numberController = TextEditingController();
    final amountController = TextEditingController();
    
    // Sample bill amounts
    final sampleAmount = {
      'Mobile Recharge': '599',
      'Electricity Bill': '2,340',
      'DTH Recharge': '450',
      'Broadband Bill': '999',
      'Water Bill': '350',
      'Gas Cylinder': '950',
    };
    
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Text(billType, style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: numberController,
                keyboardType: billType == 'Mobile Recharge' ? TextInputType.phone : TextInputType.text,
                decoration: InputDecoration(
                  labelText: billType == 'Mobile Recharge' ? 'Mobile Number' : 'Consumer/Account Number',
                  prefixIcon: Icon(billType == 'Mobile Recharge' ? Icons.phone : Icons.numbers),
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
                  hintText: sampleAmount[billType] ?? '0',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.05),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const UPIPaymentDemoScreen()));
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Pay ${sampleAmount[billType] != null ? '₹${sampleAmount[billType]}' : 'Now'}'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
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
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.credit_card, color: Colors.red),
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
                  _buildCreditCardItem('HDFC Credit Card', '•••• 4532', '₹45,678', 'Due: Mar 15', Colors.red.shade700),
                  _buildCreditCardItem('ICICI Amazon Pay', '•••• 8901', '₹12,340', 'Due: Mar 18', Colors.orange.shade700),
                  _buildCreditCardItem('SBI Card', '•••• 2345', '₹8,500', 'Due: Mar 20', Colors.blue.shade700),
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
      padding: const EdgeInsets.all(16),
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
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const UPIPaymentDemoScreen()));
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
      {'icon': Icons.apartment, 'label': 'Rent', 'color': Colors.brown},
      {'icon': Icons.school, 'label': 'Education', 'color': Colors.indigo},
      {'icon': Icons.local_hospital, 'label': 'Hospital', 'color': Colors.pink},
      {'icon': Icons.directions_car, 'label': 'Challan', 'color': Colors.red},
      {'icon': Icons.flight, 'label': 'Travel', 'color': Colors.cyan},
      {'icon': Icons.movie, 'label': 'Entertainment', 'color': Colors.purple},
      {'icon': Icons.shopping_cart, 'label': 'Shopping', 'color': Colors.green},
      {'icon': Icons.fitness_center, 'label': 'Gym', 'color': Colors.orange},
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
              padding: const EdgeInsets.all(20),
              child: Text('More Bills & Payments', style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
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
                          padding: const EdgeInsets.all(14),
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.store, color: Colors.indigo),
                  ),
                  const SizedBox(width: 12),
                  Text('Pay Merchant', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 24),
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const UPIPaymentDemoScreen()));
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long, color: Colors.teal),
                  ),
                  const SizedBox(width: 12),
                  Text('Pay Invoice', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fetching invoice details...')),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.local_shipping, color: Colors.orange),
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
                  _buildVendorItem('ABC Supplies', 'Pending: ₹25,000', 'Due: Mar 12', Colors.orange),
                  _buildVendorItem('XYZ Electronics', 'Pending: ₹15,500', 'Due: Mar 15', Colors.blue),
                  _buildVendorItem('Office Mart', 'Pending: ₹8,200', 'Due: Mar 20', Colors.green),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
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
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UPIPaymentDemoScreen()));
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

class _Transaction {
  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final Color color;
  final bool isCredit;
  
  _Transaction(this.title, this.subtitle, this.amount, this.icon, this.color, this.isCredit);
}
