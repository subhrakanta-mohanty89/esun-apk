/// ESUN UPI Payment Demo Screen
/// 
/// Interactive demo screen for UPI payments.
/// Shows balance, allows making demo payments that deduct from balance.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../theme/theme.dart';
import '../../shared/widgets/widgets.dart';
import '../../services/upi_payment_service.dart';

class UPIPaymentDemoScreen extends ConsumerStatefulWidget {
  const UPIPaymentDemoScreen({super.key});

  @override
  ConsumerState<UPIPaymentDemoScreen> createState() => _UPIPaymentDemoScreenState();
}

class _UPIPaymentDemoScreenState extends ConsumerState<UPIPaymentDemoScreen> {
  final _amountController = TextEditingController();
  final _vpaController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedAccountId;
  bool _isVerifyingVpa = false;
  VPAVerificationResult? _vpaVerification;
  
  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  
  @override
  void initState() {
    super.initState();
    // Load balance on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(upiPaymentStateProvider.notifier).loadBalance();
    });
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    _vpaController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(upiPaymentStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('UPI Payment Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(upiPaymentStateProvider.notifier).loadBalance();
            },
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Demo Mode Banner
                  _buildDemoBanner(),
                  const SizedBox(height: ESUNSpacing.lg),
                  
                  // Balance Overview
                  if (state.balance != null) ...[
                    _buildBalanceCard(state.balance!),
                    const SizedBox(height: ESUNSpacing.lg),
                    
                    // Account Selector
                    _buildAccountSelector(state.balance!.accounts),
                    const SizedBox(height: ESUNSpacing.lg),
                  ] else ...[
                    _buildSeedDataCard(),
                    const SizedBox(height: ESUNSpacing.lg),
                  ],
                  
                  // Payment Form
                  _buildPaymentForm(state),
                  
                  // Error Display
                  if (state.error != null) ...[
                    const SizedBox(height: ESUNSpacing.md),
                    _buildErrorCard(state.error!),
                  ],
                  
                  // Last Payment Result
                  if (state.lastPayment != null) ...[
                    const SizedBox(height: ESUNSpacing.lg),
                    _buildPaymentSuccessCard(state.lastPayment!),
                  ],
                  
                  const SizedBox(height: ESUNSpacing.xxl),
                ],
              ),
            ),
    );
  }
  
  Widget _buildDemoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade400,
            Colors.orange.shade600,
          ],
        ),
        borderRadius: ESUNRadius.lgRadius,
      ),
      child: Row(
        children: [
          const Icon(Icons.science, color: Colors.white, size: 32),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demo Mode',
                  style: ESUNTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Payments work with mock data. No real transactions.',
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
  
  Widget _buildSeedDataCard() {
    return FPCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.data_object, color: ESUNColors.primary),
              const SizedBox(width: ESUNSpacing.sm),
              Text(
                'Setup Demo Data',
                style: ESUNTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          Text(
            'Click the button below to create demo bank accounts and transaction history.',
            style: ESUNTypography.bodyMedium.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final success = await ref.read(upiPaymentStateProvider.notifier).seedDemoData();
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Demo data created successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add_circle),
              label: const Text('Create Demo Data'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBalanceCard(DemoBalance balance) {
    return FPCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Total Balance',
                style: ESUNTypography.labelMedium.copyWith(
                  color: ESUNColors.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ESUNSpacing.sm,
                  vertical: ESUNSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: ESUNRadius.smRadius,
                ),
                child: Text(
                  'Demo',
                  style: ESUNTypography.labelSmall.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.xs),
          Text(
            _currencyFormat.format(balance.totalBalance),
            style: ESUNTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: ESUNColors.primary,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Available',
                  _currencyFormat.format(balance.availableBalance),
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: ESUNSpacing.md),
              Expanded(
                child: _buildMiniStat(
                  'This Month',
                  '-${_currencyFormat.format(balance.monthlySpending)}',
                  Icons.trending_down,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: ESUNRadius.smRadius,
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: ESUNSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: ESUNTypography.labelSmall.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: ESUNTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAccountSelector(List<DemoAccount> accounts) {
    return FPCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Account',
            style: ESUNTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          ...accounts.map((account) => _buildAccountTile(account)),
        ],
      ),
    );
  }
  
  Widget _buildAccountTile(DemoAccount account) {
    final isSelected = _selectedAccountId == account.id;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAccountId = account.id;
        });
      },
      borderRadius: ESUNRadius.mdRadius,
      child: Container(
        padding: const EdgeInsets.all(ESUNSpacing.md),
        margin: const EdgeInsets.only(bottom: ESUNSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? ESUNColors.primary : ESUNColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: ESUNRadius.mdRadius,
          color: isSelected ? ESUNColors.primary.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ESUNColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance,
                color: ESUNColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: ESUNSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.bankName,
                    style: ESUNTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (account.upiId != null)
                    Text(
                      account.upiId!,
                      style: ESUNTypography.labelSmall.copyWith(
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
                  _currencyFormat.format(account.balance),
                  style: ESUNTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  account.accountType,
                  style: ESUNTypography.labelSmall.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: ESUNSpacing.sm),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? ESUNColors.primary : ESUNColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentForm(UPIPaymentState state) {
    return FPCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Make UPI Payment',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          
          // Amount Input
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '₹ ',
              hintText: '0.00',
              border: OutlineInputBorder(
                borderRadius: ESUNRadius.mdRadius,
              ),
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          
          // VPA Input
          TextField(
            controller: _vpaController,
            decoration: InputDecoration(
              labelText: 'Payee UPI ID',
              hintText: 'example@upi',
              border: OutlineInputBorder(
                borderRadius: ESUNRadius.mdRadius,
              ),
              suffixIcon: _isVerifyingVpa
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.verified_user),
                      onPressed: () => _verifyVpa(),
                    ),
            ),
            onChanged: (_) {
              setState(() {
                _vpaVerification = null;
              });
            },
          ),
          
          // VPA Verification Result
          if (_vpaVerification != null) ...[
            const SizedBox(height: ESUNSpacing.sm),
            Container(
              padding: const EdgeInsets.all(ESUNSpacing.sm),
              decoration: BoxDecoration(
                color: _vpaVerification!.isValid
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: ESUNRadius.smRadius,
              ),
              child: Row(
                children: [
                  Icon(
                    _vpaVerification!.isValid ? Icons.check_circle : Icons.error,
                    color: _vpaVerification!.isValid ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: ESUNSpacing.sm),
                  Expanded(
                    child: Text(
                      _vpaVerification!.isValid
                          ? 'Verified: ${_vpaVerification!.accountHolder}'
                          : _vpaVerification!.error ?? 'Invalid VPA',
                      style: ESUNTypography.bodySmall.copyWith(
                        color: _vpaVerification!.isValid ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: ESUNSpacing.md),
          
          // Description Input
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'Payment for...',
              border: OutlineInputBorder(
                borderRadius: ESUNRadius.mdRadius,
              ),
            ),
          ),
          const SizedBox(height: ESUNSpacing.xl),
          
          // Pay Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_selectedAccountId != null && !state.isLoading)
                  ? () => _makePayment()
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: ESUNColors.primary,
              ),
              child: state.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Pay Now',
                      style: ESUNTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          
          // Quick amounts
          const SizedBox(height: ESUNSpacing.md),
          Text(
            'Quick Amounts',
            style: ESUNTypography.labelSmall.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
          const SizedBox(height: ESUNSpacing.sm),
          Wrap(
            spacing: ESUNSpacing.sm,
            children: [100, 500, 1000, 2000, 5000].map((amount) {
              return ActionChip(
                label: Text('₹$amount'),
                onPressed: () {
                  _amountController.text = amount.toString();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: ESUNRadius.mdRadius,
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: Text(
              error,
              style: ESUNTypography.bodyMedium.copyWith(color: Colors.red),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () {
              ref.read(upiPaymentStateProvider.notifier).clearError();
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentSuccessCard(PaymentSimulationResult payment) {
    return FPCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 32,
                ),
              ),
              const SizedBox(width: ESUNSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Successful!',
                      style: ESUNTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      payment.transactionId,
                      style: ESUNTypography.labelSmall.copyWith(
                        color: ESUNColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.lg),
          const Divider(),
          const SizedBox(height: ESUNSpacing.md),
          _buildPaymentDetail('Amount', _currencyFormat.format(payment.amount)),
          _buildPaymentDetail('Paid To', payment.payeeVpa),
          _buildPaymentDetail(
            'Previous Balance',
            _currencyFormat.format(payment.oldBalance),
          ),
          _buildPaymentDetail(
            'New Balance',
            _currencyFormat.format(payment.newBalance),
            highlight: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentDetail(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: ESUNTypography.bodyMedium.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: ESUNTypography.bodyMedium.copyWith(
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              color: highlight ? ESUNColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _verifyVpa() async {
    final vpa = _vpaController.text.trim();
    if (vpa.isEmpty) return;
    
    setState(() {
      _isVerifyingVpa = true;
      _vpaVerification = null;
    });
    
    final service = ref.read(upiPaymentServiceProvider);
    final result = await service.verifyVPA(vpa);
    
    if (!mounted) return;
    
    result.when(
      success: (verification) {
        setState(() {
          _vpaVerification = verification;
          _isVerifyingVpa = false;
        });
      },
      error: (e) {
        setState(() {
          _vpaVerification = VPAVerificationResult(
            isValid: false,
            vpa: vpa,
            error: e.message,
          );
          _isVerifyingVpa = false;
        });
      },
    );
  }
  
  Future<void> _makePayment() async {
    final amount = double.tryParse(_amountController.text);
    final vpa = _vpaController.text.trim();
    final description = _descriptionController.text.trim();
    
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (vpa.isEmpty || !vpa.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid UPI ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an account'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final notifier = ref.read(upiPaymentStateProvider.notifier);
    
    // Step 1: Create payment link
    final createSuccess = await notifier.createPayment(
      amount: amount,
      payeeVpa: vpa,
      accountId: _selectedAccountId!,
      description: description.isNotEmpty ? description : 'UPI Payment',
    );
    
    if (!createSuccess) return;
    
    // Step 2: Simulate payment (instant success for demo)
    final paySuccess = await notifier.simulatePayment(_selectedAccountId!);
    
    if (paySuccess && mounted) {
      // Clear form
      _amountController.clear();
      _vpaController.clear();
      _descriptionController.clear();
      _vpaVerification = null;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful! Balance updated.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
