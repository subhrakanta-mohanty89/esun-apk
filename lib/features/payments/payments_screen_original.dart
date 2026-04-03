/// ESUN Payments Screen
/// 
/// Payment hub for UPI, bills, transfers and more.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:permission_handler/permission_handler.dart';

import '../../theme/theme.dart';
import '../../shared/widgets/widgets.dart';
import '../../shared/widgets/qr_sheet.dart';
import '../../state/aa_data_state.dart';
import 'upi_payment_demo_screen.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  static const String _upiId = 'john.doe@ESUN';
  static const String _name = 'John Doe';
  static const String _bankLabel = 'HDFC • 1234';

  bool _isLoadingContacts = false;
  bool _contactsGranted = false;
  List<_PaymentContact> _contacts = [];
  bool _permissionAsked = false;
  String? _permissionError;

  @override
  void initState() {
    super.initState();
    // Defer contact request to after the first frame to avoid showDialog errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRequestContacts();
    });
  }

  Future<void> _maybeRequestContacts() async {
    if (_permissionAsked) return;
    _permissionAsked = true;

    // Ask the user before requesting contact permission
    final wantsPermission = await _showContactsPrompt();
    if (!mounted || wantsPermission != true) return;

    await _loadContacts(requestPermission: true);
  }

  Future<bool?> _showContactsPrompt() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Allow contact access?'),
        content: const Text(
          'Quick Pay can show your saved contacts so you can send money faster. We need access to your contacts to display their names and numbers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadContacts({bool requestPermission = false}) async {
    setState(() {
      _isLoadingContacts = true;
      _permissionError = null;
    });

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
        _permissionError = 'Contacts permission denied';
        _contacts = [];
      });
      return;
    }

    try {
      final list = await fc.FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      final mapped = list
          .where((c) => (c.displayName.isNotEmpty) || c.phones.isNotEmpty)
          .take(20)
          .map((c) {
            final initials = _initialsFromName(c.displayName);
            // Keep only digits and + for a clean display in Quick Pay
            final rawPhone = c.phones.isNotEmpty ? c.phones.first.number : '';
            final phone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
            return _PaymentContact(c.displayName, initials, phone, ESUNColors.primary);
          })
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
        _permissionError = 'Failed to load contacts';
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
      backgroundColor: isDark ? ESUNColors.darkBackground : ESUNColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? ESUNColors.darkSurface : ESUNColors.surface,
        elevation: 0,
        title: const Text('Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // UPI Section
            _buildUPISection(context),
            
            // Quick Pay
            _buildQuickPay(context),
            
            // Bill Payments
            _buildBillPayments(context),
            
            // Recharge & Bills
            _buildRechargeSection(context),
            
            // Bank Transfer
            _buildBankTransfer(context),
            
            // Payment History
            _buildRecentPayments(context),
            
            const SizedBox(height: 72),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUPISection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: FPCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(ESUNSpacing.md),
                  decoration: BoxDecoration(
                    color: ESUNColors.primary.withOpacity(0.1),
                    borderRadius: ESUNRadius.smRadius,
                  ),
                  child: const Icon(Icons.qr_code, color: ESUNColors.primary),
                ),
                const SizedBox(width: ESUNSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UPI ID',
                        style: ESUNTypography.labelSmall.copyWith(
                          color: ESUNColors.textSecondary,
                        ),
                      ),
                      Text(
                        _upiId,
                        style: ESUNTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('UPI ID copied!')),
                    );
                  },
                ),
                TextButton.icon(
                  onPressed: () {
                    showQrBottomSheet(
                      context,
                      name: _name,
                      upiId: _upiId,
                      bankLabel: _bankLabel,
                    );
                  },
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: const Text('View QR'),
                ),
              ],
            ),
            const Divider(height: ESUNSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildUPIAction(Icons.qr_code_scanner, 'Scan QR', () {}),
                _buildUPIAction(Icons.send, 'Pay', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UPIPaymentDemoScreen(),
                    ),
                  );
                }),
                _buildUPIAction(Icons.request_page, 'Request', () {}),
                _buildUPIAction(
                  Icons.qr_code_2,
                  'My QR',
                  () => showQrBottomSheet(
                    context,
                    name: _name,
                    upiId: _upiId,
                    bankLabel: _bankLabel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUPIAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.md),
            decoration: const BoxDecoration(
              color: ESUNColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: ESUNColors.primary),
          ),
          const SizedBox(height: ESUNSpacing.xs),
          Text(label, style: ESUNTypography.labelSmall),
        ],
      ),
    );
  }
  
  Widget _buildQuickPay(BuildContext context) {
    Widget content;

    if (_isLoadingContacts) {
      content = const Center(child: Padding(
        padding: EdgeInsets.all(ESUNSpacing.lg),
        child: CircularProgressIndicator(),
      ));
    } else if (!_contactsGranted) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Pay',
            style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: ESUNSpacing.sm),
          FPCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'See your contacts here',
                  style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: ESUNSpacing.xs),
                Text(
                  'Allow contact access to quickly pay saved numbers.',
                  style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
                ),
                const SizedBox(height: ESUNSpacing.sm),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.contact_phone_outlined),
                      label: const Text('Allow Contacts'),
                      onPressed: () => _loadContacts(requestPermission: true),
                    ),
                    const SizedBox(width: ESUNSpacing.sm),
                    if (_permissionError != null)
                      Flexible(
                        child: Text(
                          _permissionError!,
                          style: ESUNTypography.labelSmall.copyWith(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    } else if (_contacts.isEmpty) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Pay',
            style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: ESUNSpacing.sm),
          FPCard(
            child: Text(
              'No contacts found. Try adding contacts with phone numbers.',
              style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
            ),
          ),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Pay',
                style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () => _loadContacts(requestPermission: false),
                child: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return Padding(
                  padding: const EdgeInsets.only(right: ESUNSpacing.md),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: contact.color.withOpacity(0.1),
                        child: Text(
                          contact.initial,
                          style: ESUNTypography.titleLarge.copyWith(
                            color: contact.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: ESUNSpacing.xs),
                      SizedBox(
                        width: 92,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              contact.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ESUNTypography.labelSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              contact.phone.isNotEmpty ? contact.phone : 'No number',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ESUNTypography.labelSmall.copyWith(
                                color: ESUNColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: content,
    );
  }
  
  Widget _buildBillPayments(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Bills',
                style: ESUNTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.sm),
          _buildBillCard(
            'Electricity Bill',
            'BESCOM',
            '₹2,340',
            'Due in 3 days',
            Icons.bolt,
            Colors.amber,
          ),
          const SizedBox(height: ESUNSpacing.sm),
          _buildBillCard(
            'Credit Card',
            'HDFC Bank',
            '₹15,890',
            'Due in 7 days',
            Icons.credit_card,
            Colors.blue,
          ),
        ],
      ),
    );
  }
  
  Widget _buildBillCard(
    String title,
    String subtitle,
    String amount,
    String due,
    IconData icon,
    Color color,
  ) {
    return FPCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.md),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: ESUNRadius.smRadius,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ESUNTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: ESUNTypography.bodySmall.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: ESUNTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                due,
                style: ESUNTypography.labelSmall.copyWith(
                  color: ESUNColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildRechargeSection(BuildContext context) {
    final items = [
      _RechargeItem(Icons.phone_android, 'Mobile', Colors.green),
      _RechargeItem(Icons.tv, 'DTH', Colors.purple),
      _RechargeItem(Icons.wifi, 'Broadband', Colors.blue),
      _RechargeItem(Icons.local_gas_station, 'Gas', Colors.orange),
      _RechargeItem(Icons.water_drop, 'Water', Colors.cyan),
      _RechargeItem(Icons.bolt, 'Electricity', Colors.amber),
      _RechargeItem(Icons.flight, 'FASTag', Colors.indigo),
      _RechargeItem(Icons.more_horiz, 'More', Colors.grey),
    ];
    
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recharge & Pay Bills',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.85,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildRechargeItem(item);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildRechargeItem(_RechargeItem item) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color),
          ),
          const SizedBox(height: ESUNSpacing.xs),
          Text(
            item.label,
            style: ESUNTypography.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildBankTransfer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: FPCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bank Transfer',
              style: ESUNTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: ESUNSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildTransferOption(
                    Icons.account_balance,
                    'To Bank',
                    'IMPS/NEFT',
                    Colors.blue,
                    () => _showBankTransferSheet(context),
                  ),
                ),
                const SizedBox(width: ESUNSpacing.md),
                Expanded(
                  child: _buildTransferOption(
                    Icons.account_balance_wallet,
                    'Self Transfer',
                    'Own accounts',
                    Colors.green,
                    () => _showSelfTransferSheet(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransferOption(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(ESUNSpacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: ESUNRadius.mdRadius,
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: ESUNSpacing.sm),
            Text(
              title,
              style: ESUNTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: ESUNTypography.labelSmall.copyWith(
                color: ESUNColors.textSecondary,
              ),
            ),
          ],
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
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(ESUNSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(ESUNSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.account_balance, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Text('Bank Transfer', style: ESUNTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Transfer Mode
                      Text('Transfer Mode', style: ESUNTypography.labelMedium.copyWith(color: ESUNColors.textSecondary)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => transferMode = 'IMPS'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: transferMode == 'IMPS' ? Colors.blue : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text('IMPS', style: TextStyle(color: transferMode == 'IMPS' ? Colors.white : Colors.black, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => transferMode = 'NEFT'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: transferMode == 'NEFT' ? Colors.blue : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text('NEFT', style: TextStyle(color: transferMode == 'NEFT' ? Colors.white : Colors.black, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => transferMode = 'RTGS'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: transferMode == 'RTGS' ? Colors.blue : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text('RTGS', style: TextStyle(color: transferMode == 'RTGS' ? Colors.white : Colors.black, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: accountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Account Number',
                          hintText: 'Enter account number',
                          prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: ifscController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'IFSC Code',
                          hintText: 'e.g., HDFC0001234',
                          prefixIcon: const Icon(Icons.code),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Beneficiary Name',
                          hintText: 'Account holder name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          hintText: 'Enter amount',
                          prefixIcon: const Icon(Icons.currency_rupee),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
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
                            SnackBar(content: Text('₹${amountController.text} transferred via $transferMode to ${nameController.text.isNotEmpty ? nameController.text : 'beneficiary'}')),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
                        ),
                        child: const Text('Transfer Now', style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        transferMode == 'IMPS' ? 'Instant transfer, available 24x7' :
                        transferMode == 'NEFT' ? 'Settlement in batches, every 30 mins' :
                        'For amounts above ₹2 Lakhs, instant',
                        textAlign: TextAlign.center,
                        style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary),
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
        builder: (context, setState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(ESUNSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(ESUNSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.swap_horiz, color: Colors.green),
                      ),
                      const SizedBox(width: 12),
                      Text('Self Transfer', style: ESUNTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // From Account
                      Text('From Account', style: ESUNTypography.labelMedium.copyWith(color: ESUNColors.textSecondary)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<String>(
                          value: fromAccount,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: accounts.map((acc) => DropdownMenuItem(value: acc, child: Text(acc))).toList(),
                          onChanged: (val) => setState(() => fromAccount = val!),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Swap Icon
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
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.swap_vert, color: Colors.green),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // To Account
                      Text('To Account', style: ESUNTypography.labelMedium.copyWith(color: ESUNColors.textSecondary)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<String>(
                          value: toAccount,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: accounts.map((acc) => DropdownMenuItem(value: acc, child: Text(acc))).toList(),
                          onChanged: (val) => setState(() => toAccount = val!),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          hintText: 'Enter amount to transfer',
                          prefixIcon: const Icon(Icons.currency_rupee),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
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
                              const SnackBar(content: Text('From and To accounts cannot be same')),
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('₹${amountController.text} transferred from $fromAccount to $toAccount')),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
                        ),
                        child: const Text('Transfer', style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Instant transfer between your linked accounts',
                        textAlign: TextAlign.center,
                        style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary),
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
  
  Widget _buildRecentPayments(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Payments',
                style: ESUNTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.sm),
          FPTransactionCard(
            icon: Icons.person,
            iconBackgroundColor: Colors.blue.withOpacity(0.1),
            iconColor: Colors.blue,
            title: 'Rahul Sharma',
            subtitle: 'UPI • Today, 2:30 PM',
            amount: '-₹5,000',
            amountColor: ESUNColors.textPrimary,
          ),
          FPTransactionCard(
            icon: Icons.phone_android,
            iconBackgroundColor: Colors.green.withOpacity(0.1),
            iconColor: Colors.green,
            title: 'Mobile Recharge',
            subtitle: 'Jio • Yesterday',
            amount: '-₹599',
            amountColor: ESUNColors.textPrimary,
          ),
        ],
      ),
    );
  }
}

class _PaymentContact {
  final String name;
  final String initial;
  final String phone;
  final Color color;
  
  _PaymentContact(this.name, this.initial, this.phone, this.color);
}

class _RechargeItem {
  final IconData icon;
  final String label;
  final Color color;
  
  _RechargeItem(this.icon, this.label, this.color);
}



