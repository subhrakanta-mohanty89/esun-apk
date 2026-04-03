/// ESUN Bill Payment Screen
/// 
/// Functional bill payment screen with static data and success animation.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../state/transaction_state.dart';

class BillPaymentScreen extends ConsumerStatefulWidget {
  final String billType;
  final IconData icon;
  final Color color;
  final String? prefillNumber;
  final String? prefillAmount;

  const BillPaymentScreen({
    super.key,
    required this.billType,
    required this.icon,
    required this.color,
    this.prefillNumber,
    this.prefillAmount,
  });

  @override
  ConsumerState<BillPaymentScreen> createState() => _BillPaymentScreenState();
}

class _BillPaymentScreenState extends ConsumerState<BillPaymentScreen> {
  final _numberController = TextEditingController();
  final _amountController = TextEditingController();
  
  bool _isLoading = false;
  bool _isFetching = false;
  bool _billFetched = false;
  
  // Static bill details
  String _consumerName = '';
  String _billDate = '';
  String _dueDate = '';
  String _billNumber = '';
  
  @override
  void initState() {
    super.initState();
    if (widget.prefillNumber != null) {
      _numberController.text = widget.prefillNumber!;
    }
    if (widget.prefillAmount != null) {
      _amountController.text = widget.prefillAmount!;
    }
  }
  
  @override
  void dispose() {
    _numberController.dispose();
    _amountController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchBillDetails() async {
    if (_numberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter consumer/account number')),
      );
      return;
    }
    
    setState(() => _isFetching = true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    // Generate static bill details based on bill type
    final billData = _getStaticBillData();
    
    setState(() {
      _isFetching = false;
      _billFetched = true;
      _consumerName = billData['name']!;
      _billDate = billData['billDate']!;
      _dueDate = billData['dueDate']!;
      _billNumber = billData['billNumber']!;
      _amountController.text = billData['amount']!;
    });
  }
  
  Map<String, String> _getStaticBillData() {
    switch (widget.billType) {
      case 'Mobile Recharge':
        return {
          'name': 'Prepaid Mobile',
          'billDate': '-',
          'dueDate': '-',
          'billNumber': 'PREP${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          'amount': '599',
        };
      case 'Electricity Bill':
        return {
          'name': 'Subhrakanta Miti',
          'billDate': '01 Mar 2026',
          'dueDate': '20 Mar 2026',
          'billNumber': 'EB2026030${_numberController.text.substring(0, 4)}',
          'amount': '2340',
        };
      case 'DTH Recharge':
        return {
          'name': 'Tata Sky HD',
          'billDate': '-',
          'dueDate': '-',
          'billNumber': 'DTH${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          'amount': '450',
        };
      case 'Broadband Bill':
        return {
          'name': 'JioFiber - Home',
          'billDate': '05 Mar 2026',
          'dueDate': '25 Mar 2026',
          'billNumber': 'BB${_numberController.text}',
          'amount': '999',
        };
      case 'Water Bill':
        return {
          'name': 'Municipal Water Supply',
          'billDate': '28 Feb 2026',
          'dueDate': '15 Mar 2026',
          'billNumber': 'WB2026${_numberController.text.substring(0, 6)}',
          'amount': '350',
        };
      case 'Gas Cylinder':
        return {
          'name': 'Indane LPG',
          'billDate': '-',
          'dueDate': '-',
          'billNumber': 'GAS${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
          'amount': '950',
        };
      default:
        return {
          'name': 'Consumer',
          'billDate': '01 Mar 2026',
          'dueDate': '15 Mar 2026',
          'billNumber': 'BILL${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          'amount': '500',
        };
    }
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
    
    // Show UPI PIN entry dialog
    final pinVerified = await _showUpiPinDialog(amount);
    if (!pinVerified || !mounted) return;
    
    setState(() => _isLoading = true);
    
    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Record transaction in state
    final transaction = await ref.read(transactionStateProvider.notifier).recordBillPayment(
      amount: amount,
      billType: widget.billType,
      consumerNumber: _numberController.text,
      providerName: _billFetched ? _consumerName : null,
      sourceAccount: 'HDFC Savings •• 1234',
    );
    
    setState(() => _isLoading = false);
    
    // Navigate to success screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSuccessScreen(
          amount: amount,
          transactionId: transaction.id,
          payeeName: _billFetched ? _consumerName : widget.billType,
          paymentType: widget.billType,
          icon: widget.icon,
          color: widget.color,
          billNumber: _billFetched ? _billNumber : null,
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
          height: MediaQuery.of(context).size.height * 0.7,
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
                  color: widget.color.withOpacity(0.1),
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
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(ESUNSpacing.md),
                          decoration: BoxDecoration(
                            color: widget.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(widget.icon, color: widget.color, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.billType,
                              style: ESUNTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_billFetched)
                              Text(
                                _consumerName,
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
                          ? (hasError ? ESUNColors.error : widget.color)
                          : Colors.transparent,
                      border: Border.all(
                        color: hasError 
                            ? ESUNColors.error 
                            : (isFilled ? widget.color : Colors.grey.shade300),
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
                              return const SizedBox(width: 64, height: 64);
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
                                    
                                    if (pin.length == 6) {
                                      setState(() => isVerifying = true);
                                      Future.delayed(const Duration(milliseconds: 800), () {
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
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDelete ? Colors.transparent : Colors.grey.shade100,
          ),
          child: Center(
            child: isDelete
                ? const Icon(Icons.backspace_outlined, size: 22)
                : Text(
                    key,
                    style: ESUNTypography.headlineSmall.copyWith(
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
        title: Text(widget.billType),
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ESUNSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bill Type Header
            _buildBillHeader(),
            const SizedBox(height: 16),
            
            // Consumer Number Input
            _buildConsumerInput(),
            const SizedBox(height: 16),
            
            // Fetch Bill Button
            if (!_billFetched && widget.billType != 'Mobile Recharge' && widget.billType != 'DTH Recharge' && widget.billType != 'Gas Cylinder')
              _buildFetchButton(),
            
            // Bill Details Card
            if (_billFetched) ...[
              const SizedBox(height: 12),
              _buildBillDetailsCard(),
            ],
            
            const SizedBox(height: 12),
            
            // Amount Input
            _buildAmountInput(),
            const SizedBox(height: 16),
            
            // Quick Amount Chips (for recharges)
            if (widget.billType == 'Mobile Recharge' || widget.billType == 'DTH Recharge')
              _buildQuickAmounts(),
            
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
  
  Widget _buildBillHeader() {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.xl),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(widget.icon, color: widget.color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.billType,
                  style: ESUNTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getProviderText(),
                  style: ESUNTypography.bodyMedium.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getProviderText() {
    switch (widget.billType) {
      case 'Mobile Recharge':
        return 'Jio, Airtel, Vi, BSNL';
      case 'Electricity Bill':
        return 'BESCOM, TPDDL, MSEDCL & more';
      case 'DTH Recharge':
        return 'Tata Sky, Airtel, Dish TV';
      case 'Broadband Bill':
        return 'JioFiber, Airtel, BSNL';
      case 'Water Bill':
        return 'Municipal water boards';
      case 'Gas Cylinder':
        return 'Indane, HP Gas, Bharat Gas';
      default:
        return 'Pay instantly';
    }
  }
  
  Widget _buildConsumerInput() {
    return TextField(
      controller: _numberController,
      keyboardType: widget.billType == 'Mobile Recharge' 
          ? TextInputType.phone 
          : TextInputType.text,
      maxLength: widget.billType == 'Mobile Recharge' ? 10 : null,
      decoration: InputDecoration(
        labelText: widget.billType == 'Mobile Recharge' 
            ? 'Mobile Number'
            : widget.billType == 'DTH Recharge'
                ? 'Subscriber ID / Registered Mobile'
                : 'Consumer / Account Number',
        hintText: widget.billType == 'Mobile Recharge' 
            ? 'Enter 10-digit number'
            : 'Enter your account number',
        prefixIcon: Icon(
          widget.billType == 'Mobile Recharge' ? Icons.phone : Icons.numbers,
          color: widget.color,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
        counterText: '',
      ),
      onChanged: (_) {
        if (_billFetched) {
          setState(() => _billFetched = false);
        }
      },
    );
  }
  
  Widget _buildFetchButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isFetching ? null : _fetchBillDetails,
        icon: _isFetching 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.search),
        label: Text(_isFetching ? 'Fetching...' : 'Fetch Bill'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: widget.color),
          foregroundColor: widget.color,
        ),
      ),
    );
  }
  
  Widget _buildBillDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        color: ESUNColors.success.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ESUNColors.success.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: ESUNColors.success, size: 20),
              const SizedBox(width: 8),
              Text(
                'Bill Found',
                style: ESUNTypography.titleSmall.copyWith(
                  color: ESUNColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildDetailRow('Consumer Name', _consumerName),
          _buildDetailRow('Bill Number', _billNumber),
          if (_billDate != '-') _buildDetailRow('Bill Date', _billDate),
          if (_dueDate != '-') _buildDetailRow('Due Date', _dueDate),
          _buildDetailRow('Amount Due', '₹${_amountController.text}', isAmount: true),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, {bool isAmount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
              fontWeight: isAmount ? FontWeight.bold : FontWeight.w500,
              color: isAmount ? widget.color : ESUNColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAmountInput() {
    return TextField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: ESUNTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: 'Amount',
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, top: 12),
          child: Text(
            '₹',
            style: ESUNTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: widget.color,
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
      ),
    );
  }
  
  Widget _buildQuickAmounts() {
    final amounts = widget.billType == 'Mobile Recharge'
        ? ['199', '299', '499', '599', '799', '999']
        : ['150', '250', '350', '450', '550', '650'];
    
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: amounts.map((amount) {
        final isSelected = _amountController.text == amount;
        return GestureDetector(
          onTap: () => setState(() => _amountController.text = amount),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? widget.color : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? widget.color : Colors.transparent,
              ),
            ),
            child: Text(
              '₹$amount',
              style: ESUNTypography.bodyMedium.copyWith(
                color: isSelected ? Colors.white : ESUNColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: _isLoading ? null : _processPayment,
        style: FilledButton.styleFrom(
          backgroundColor: widget.color,
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
                  const Icon(Icons.lock, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Pay Securely',
                    style: ESUNTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
  
  Widget _buildSecurityNotice() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shield, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '100% Safe & Secure Payment',
          style: ESUNTypography.labelSmall.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}


/// Payment Success Screen with Animation
class PaymentSuccessScreen extends StatefulWidget {
  final double amount;
  final String transactionId;
  final String payeeName;
  final String paymentType;
  final IconData icon;
  final Color color;
  final String? billNumber;

  const PaymentSuccessScreen({
    super.key,
    required this.amount,
    required this.transactionId,
    required this.payeeName,
    required this.paymentType,
    required this.icon,
    required this.color,
    this.billNumber,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _checkController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    );
    
    // Start animations
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _checkController.forward();
    });
    
    // Haptic feedback
    HapticFeedback.heavyImpact();
  }
  
  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.color,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Success Content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success Animation
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedBuilder(
                        animation: _checkAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: CheckmarkPainter(
                              progress: _checkAnimation.value,
                              color: widget.color,
                            ),
                            child: const SizedBox.expand(),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Amount
                  Text(
                    '₹${widget.amount.toStringAsFixed(0)}',
                    style: ESUNTypography.displayLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Payment Type
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          widget.paymentType,
                          style: ESUNTypography.bodyMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Success Message
                  Text(
                    'Payment Successful!',
                    style: ESUNTypography.headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Paid to ${widget.payeeName}',
                    style: ESUNTypography.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            // Transaction Details Card
            Container(
              margin: const EdgeInsets.all(ESUNSpacing.xl),
              padding: const EdgeInsets.all(ESUNSpacing.xl),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _buildDetailItem('Transaction ID', widget.transactionId),
                  const Divider(height: 24),
                  _buildDetailItem('Date & Time', _formatDateTime()),
                  if (widget.billNumber != null) ...[
                    const Divider(height: 24),
                    _buildDetailItem('Bill Number', widget.billNumber!),
                  ],
                  const Divider(height: 24),
                  _buildDetailItem('Payment Method', 'HDFC Bank •• 1234'),
                  const SizedBox(height: 12),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Receipt downloaded')),
                            );
                          },
                          icon: const Icon(Icons.download),
                          label: const Text('Receipt'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sharing...')),
                            );
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Done Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.color,
                        padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Done', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: ESUNTypography.bodyMedium.copyWith(
            color: ESUNColors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: ESUNTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
  
  String _formatDateTime() {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = now.hour > 12 ? now.hour - 12 : now.hour;
    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    return '${now.day} ${months[now.month - 1]} ${now.year}, '
           '${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $amPm';
  }
}


/// Custom Checkmark Painter for success animation
class CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;
  
  CheckmarkPainter({required this.progress, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;
    
    // Calculate checkmark points
    final start = Offset(center.dx - radius * 0.5, center.dy);
    final mid = Offset(center.dx - radius * 0.1, center.dy + radius * 0.4);
    final end = Offset(center.dx + radius * 0.6, center.dy - radius * 0.3);
    
    final path = Path();
    
    if (progress <= 0.5) {
      // First part of checkmark
      final t = progress * 2;
      final currentEnd = Offset.lerp(start, mid, t)!;
      path.moveTo(start.dx, start.dy);
      path.lineTo(currentEnd.dx, currentEnd.dy);
    } else {
      // Complete first part and animate second part
      path.moveTo(start.dx, start.dy);
      path.lineTo(mid.dx, mid.dy);
      
      final t = (progress - 0.5) * 2;
      final currentEnd = Offset.lerp(mid, end, t)!;
      path.lineTo(currentEnd.dx, currentEnd.dy);
    }
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
