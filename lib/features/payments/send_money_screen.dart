/// ESUN Send Money Screen
/// 
/// Functional UPI/Bank transfer screen with static data and success animation.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../state/transaction_state.dart';
import '../../state/aa_data_state.dart';
import '../../core/utils/utils.dart';
import 'bill_payment_screen.dart';

class SendMoneyScreen extends ConsumerStatefulWidget {
  final String? recipientName;
  final String? recipientPhone;
  final String? recipientUpiId;
  final Color? avatarColor;

  const SendMoneyScreen({
    super.key,
    this.recipientName,
    this.recipientPhone,
    this.recipientUpiId,
    this.avatarColor,
  });

  @override
  ConsumerState<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends ConsumerState<SendMoneyScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  bool _isLoading = false;
  String? _selectedAccount;
  
  List<String> get _accounts {
    final aaData = ref.read(aaDataProvider);
    final bankAccounts = aaData.bankAccounts;
    if (bankAccounts.isEmpty) {
      return ['HDFC Bank SAVINGS •• 1234', 'ICICI Bank SAVINGS •• 5678', 'SBI CURRENT •• 9012'];
    }
    return bankAccounts.map((a) {
      final last4 = a.accountNumber.length >= 4 
          ? a.accountNumber.substring(a.accountNumber.length - 4) 
          : a.accountNumber;
      return '${a.bankName} ${a.accountType} •• $last4';
    }).toList();
  }
  
  String get _currentAccount {
    final accounts = _accounts;
    if (_selectedAccount != null && accounts.contains(_selectedAccount)) {
      return _selectedAccount!;
    }
    return accounts.first;
  }
  
  // Quick amounts
  final List<String> _quickAmounts = ['500', '1000', '2000', '5000', '10000'];
  
  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
  
  String get _recipientInitials {
    final name = widget.recipientName ?? 'User';
    final parts = name.split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }
  
  Future<void> _processPayment() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter amount')),
      );
      return;
    }
    
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }
    
    if (amount > 100000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum limit is ₹1,00,000 per transaction')),
      );
      return;
    }
    
    // Show UPI PIN entry dialog
    final pinVerified = await _showUpiPinDialog(amount);
    if (!pinVerified || !mounted) return;
    
    setState(() => _isLoading = true);
    
    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Record transaction in state
    final transaction = await ref.read(transactionStateProvider.notifier).recordUpiTransfer(
      amount: amount,
      recipientName: widget.recipientName ?? 'Recipient',
      recipientUpi: widget.recipientUpiId,
      recipientPhone: widget.recipientPhone,
      sourceAccount: _currentAccount,
    );
    
    setState(() => _isLoading = false);
    
    // Navigate to success screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSuccessScreen(
          amount: amount,
          transactionId: transaction.id,
          payeeName: widget.recipientName ?? 'Recipient',
          paymentType: 'UPI Transfer',
          icon: Icons.person,
          color: widget.avatarColor ?? ESUNColors.primary,
        ),
      ),
    );
  }
  
  /// Show UPI PIN entry dialog for payment authentication
  Future<bool> _showUpiPinDialog(double amount) async {
    String pin = '';
    bool isVerifying = false;
    bool hasError = false;
    
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
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
                  color: (widget.avatarColor ?? ESUNColors.primary).withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx, false),
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
                              'to pay ₹${amount.toStringAsFixed(0)}',
                              style: ESUNTypography.bodyMedium.copyWith(
                                color: ESUNColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 48), // Balance the close button
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Recipient info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: widget.avatarColor ?? ESUNColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _recipientInitials,
                              style: ESUNTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.recipientName ?? 'Recipient',
                              style: ESUNTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              widget.recipientUpiId ?? widget.recipientPhone ?? '',
                              style: ESUNTypography.bodySmall.copyWith(
                                color: ESUNColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled 
                          ? (hasError ? ESUNColors.error : (widget.avatarColor ?? ESUNColors.primary))
                          : Colors.transparent,
                      border: Border.all(
                        color: hasError 
                            ? ESUNColors.error 
                            : (isFilled 
                                ? (widget.avatarColor ?? ESUNColors.primary) 
                                : Colors.grey.shade300),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              
              if (hasError) ...[
                const SizedBox(height: 12),
                Text(
                  'Incorrect PIN. Please try again.',
                  style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.error),
                ),
              ],
              
              if (isVerifying) ...[
                const SizedBox(height: 12),
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  'Verifying PIN...',
                  style: ESUNTypography.bodySmall.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
              ],
              
              const Spacer(),
              
              // Number pad
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    for (var row in [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9'], ['', '0', 'del']])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: row.map((key) {
                            if (key.isEmpty) {
                              return const SizedBox(width: 72, height: 72);
                            }
                            return _buildPinKey(
                              key, 
                              onTap: () {
                                if (isVerifying) return;
                                
                                if (key == 'del') {
                                  if (pin.isNotEmpty) {
                                    setState(() {
                                      pin = pin.substring(0, pin.length - 1);
                                      hasError = false;
                                    });
                                  }
                                } else {
                                  if (pin.length < 6) {
                                    setState(() {
                                      pin += key;
                                      hasError = false;
                                    });
                                    
                                    // Auto-submit when PIN is complete
                                    if (pin.length == 6) {
                                      setState(() => isVerifying = true);
                                      
                                      // Simulate PIN verification
                                      Future.delayed(const Duration(milliseconds: 800), () {
                                        // For demo, accept any 6-digit PIN
                                        // In production, this would verify against stored PIN
                                        Navigator.pop(ctx, true);
                                      });
                                    }
                                  }
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Security notice
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Secured by UPI',
                    style: ESUNTypography.labelSmall.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
    
    return result == true;
  }
  
  Widget _buildPinKey(String key, {required VoidCallback onTap}) {
    final isDelete = key == 'del';
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDelete ? Colors.transparent : Colors.grey.shade100,
          ),
          child: Center(
            child: isDelete
                ? const Icon(Icons.backspace_outlined, size: 24)
                : Text(
                    key,
                    style: ESUNTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Money'),
        backgroundColor: widget.avatarColor ?? ESUNColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Recipient Info
            _buildRecipientCard(),
            const SizedBox(height: 16),
            
            // Amount Input
            _buildAmountInput(),
            const SizedBox(height: 14),
            
            // Quick Amounts
            _buildQuickAmounts(),
            const SizedBox(height: 12),
            
            // Note Input
            _buildNoteInput(),
            const SizedBox(height: 12),
            
            // Account Selector
            _buildAccountSelector(),
            const SizedBox(height: 16),
            
            // Pay Button
            _buildPayButton(),
            const SizedBox(height: 12),
            
            // Security Notice
            _buildSecurityNotice(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecipientCard() {
    final color = widget.avatarColor ?? ESUNColors.primary;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.7)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _recipientInitials,
                style: ESUNTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recipientName ?? 'Recipient',
                  style: ESUNTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                if (widget.recipientPhone != null)
                  Text(
                    '+91 ${widget.recipientPhone}',
                    style: ESUNTypography.bodySmall.copyWith(
                      color: ESUNColors.textSecondary,
                    ),
                  ),
                if (widget.recipientUpiId != null)
                  Row(
                    children: [
                      const Icon(Icons.verified, color: ESUNColors.success, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        widget.recipientUpiId!,
                        style: ESUNTypography.bodySmall.copyWith(
                          color: ESUNColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAmountInput() {
    final color = widget.avatarColor ?? ESUNColors.primary;
    final hasAmount = _amountController.text.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasAmount ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Enter Amount',
            style: ESUNTypography.labelMedium.copyWith(
              color: ESUNColors.textTertiary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: hasAmount ? ESUNColors.textPrimary : ESUNColors.textTertiary,
                ),
              ),
              const SizedBox(width: 2),
              IntrinsicWidth(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 60, maxWidth: 220),
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: ESUNColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade300,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
            ],
          ),
          if (hasAmount) ...[
            const SizedBox(height: 8),
            Text(
              _amountInWords(_amountController.text),
              style: ESUNTypography.labelSmall.copyWith(
                color: ESUNColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  String _amountInWords(String amountStr) {
    final amount = int.tryParse(amountStr) ?? 0;
    if (amount == 0) return '';
    if (amount >= 10000000) return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(2)} L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '';
  }
  
  Widget _buildQuickAmounts() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _quickAmounts.map((amount) {
        final isSelected = _amountController.text == amount;
        final color = widget.avatarColor ?? ESUNColors.primary;
        return GestureDetector(
          onTap: () {
            setState(() {
              _amountController.text = amount;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : Colors.grey.withOpacity(0.25),
              ),
            ),
            child: Text(
              '₹$amount',
              style: ESUNTypography.labelMedium.copyWith(
                color: isSelected ? Colors.white : ESUNColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildNoteInput() {
    return TextField(
      controller: _noteController,
      maxLength: 50,
      decoration: InputDecoration(
        labelText: 'Add a note (optional)',
        hintText: 'What\'s this for?',
        prefixIcon: const Icon(Icons.note_alt_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
        counterText: '',
      ),
    );
  }
  
  Widget _buildAccountSelector() {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pay from',
            style: ESUNTypography.labelSmall.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(ESUNSpacing.md),
                decoration: BoxDecoration(
                  color: ESUNColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance, 
                  color: ESUNColors.primary, 
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _currentAccount,
                  isExpanded: true,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: _accounts.map((acc) {
                    return DropdownMenuItem(
                      value: acc,
                      child: Text(acc),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedAccount = val);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final aaData = ref.watch(aaDataProvider);
              final bankAccounts = aaData.bankAccounts;
              // Find the selected account's balance
              double selectedBalance = 0;
              for (final a in bankAccounts) {
                final last4 = a.accountNumber.length >= 4 
                    ? a.accountNumber.substring(a.accountNumber.length - 4) 
                    : a.accountNumber;
                final label = '${a.bankName} ${a.accountType} •• $last4';
                if (label == _currentAccount) {
                  selectedBalance = a.balance;
                  break;
                }
              }
              if (selectedBalance == 0 && bankAccounts.isNotEmpty) {
                selectedBalance = bankAccounts.first.balance;
              }
              return Text(
                'Balance: ${selectedBalance.toINR()}',
                style: ESUNTypography.labelSmall.copyWith(
                  color: ESUNColors.success,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildPayButton() {
    final amount = _amountController.text;
    final isValid = amount.isNotEmpty && (double.tryParse(amount) ?? 0) > 0;
    final color = widget.avatarColor ?? ESUNColors.primary;
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: isValid && !_isLoading ? _processPayment : null,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isValid ? 'Pay ₹$amount' : 'Enter Amount',
                    style: ESUNTypography.titleMedium.copyWith(
                      color: isValid ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
  
  Widget _buildSecurityNotice() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              'UPI Secured by NPCI',
              style: ESUNTypography.labelSmall.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSecurityBadge('Instant Transfer'),
            const SizedBox(width: 16),
            _buildSecurityBadge('Zero Charges'),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSecurityBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ESUNColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: ESUNColors.success, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: ESUNTypography.labelSmall.copyWith(
              color: ESUNColors.success,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
