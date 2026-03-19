/// ESUN Payment History Screen
///
/// Shows transaction history with static demo data and filtering options.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../theme/theme.dart';

/// Transaction model
class PaymentTransaction {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime dateTime;
  final TransactionType type;
  final TransactionStatus status;
  final String? upiId;
  final String? bankAccount;
  final String? referenceId;
  final IconData icon;
  final Color color;

  PaymentTransaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.dateTime,
    required this.type,
    this.status = TransactionStatus.success,
    this.upiId,
    this.bankAccount,
    this.referenceId,
    required this.icon,
    required this.color,
  });

  bool get isCredit => type == TransactionType.received || type == TransactionType.cashback;
}

enum TransactionType {
  sent,
  received,
  billPayment,
  recharge,
  cashback,
  bankTransfer,
}

enum TransactionStatus {
  success,
  pending,
  failed,
}

/// Static transaction data provider
final transactionHistoryProvider = Provider<List<PaymentTransaction>>((ref) {
  final now = DateTime.now();
  return [
    // Today
    PaymentTransaction(
      id: 'TXN001',
      title: 'Rahul Sharma',
      subtitle: 'Money Transfer',
      amount: 5000,
      dateTime: now.subtract(const Duration(hours: 2)),
      type: TransactionType.sent,
      upiId: 'rahul.sharma@ybl',
      referenceId: 'UPI/402815623548',
      icon: Icons.person,
      color: Colors.blue,
    ),
    PaymentTransaction(
      id: 'TXN002',
      title: 'Cashback Received',
      subtitle: 'Bill Payment Reward',
      amount: 50,
      dateTime: now.subtract(const Duration(hours: 4)),
      type: TransactionType.cashback,
      referenceId: 'CBK/402815623549',
      icon: Icons.card_giftcard,
      color: Colors.green,
    ),
    PaymentTransaction(
      id: 'TXN003',
      title: 'Amazon Pay',
      subtitle: 'Shopping',
      amount: 2499,
      dateTime: now.subtract(const Duration(hours: 6)),
      type: TransactionType.sent,
      upiId: 'amazon@apl',
      referenceId: 'UPI/402815623550',
      icon: Icons.shopping_bag,
      color: Colors.orange,
    ),
    // Yesterday
    PaymentTransaction(
      id: 'TXN004',
      title: 'Jio Prepaid',
      subtitle: 'Mobile Recharge',
      amount: 599,
      dateTime: now.subtract(const Duration(days: 1, hours: 10)),
      type: TransactionType.recharge,
      referenceId: 'RCH/402815623551',
      icon: Icons.phone_android,
      color: Colors.blue.shade700,
    ),
    PaymentTransaction(
      id: 'TXN005',
      title: 'Priya Mehta',
      subtitle: 'Money Received',
      amount: 12000,
      dateTime: now.subtract(const Duration(days: 1, hours: 14)),
      type: TransactionType.received,
      upiId: 'priya.mehta@paytm',
      referenceId: 'UPI/402815623552',
      icon: Icons.person,
      color: Colors.purple,
    ),
    PaymentTransaction(
      id: 'TXN006',
      title: 'Swiggy',
      subtitle: 'Food Order',
      amount: 456,
      dateTime: now.subtract(const Duration(days: 1, hours: 20)),
      type: TransactionType.sent,
      upiId: 'swiggy@ybl',
      referenceId: 'UPI/402815623553',
      icon: Icons.restaurant,
      color: Colors.deepOrange,
    ),
    // 2 days ago
    PaymentTransaction(
      id: 'TXN007',
      title: 'BESCOM',
      subtitle: 'Electricity Bill',
      amount: 2340,
      dateTime: now.subtract(const Duration(days: 2, hours: 9)),
      type: TransactionType.billPayment,
      referenceId: 'BILL/402815623554',
      icon: Icons.bolt,
      color: Colors.amber,
    ),
    PaymentTransaction(
      id: 'TXN008',
      title: 'Netflix',
      subtitle: 'Subscription',
      amount: 649,
      dateTime: now.subtract(const Duration(days: 2, hours: 15)),
      type: TransactionType.sent,
      upiId: 'netflix@axisbank',
      referenceId: 'UPI/402815623555',
      icon: Icons.movie,
      color: Colors.red,
    ),
    // 3 days ago
    PaymentTransaction(
      id: 'TXN009',
      title: 'Amit Kumar',
      subtitle: 'Money Transfer',
      amount: 1500,
      dateTime: now.subtract(const Duration(days: 3, hours: 11)),
      type: TransactionType.sent,
      upiId: 'amit.k@oksbi',
      referenceId: 'UPI/402815623556',
      icon: Icons.person,
      color: Colors.teal,
    ),
    PaymentTransaction(
      id: 'TXN010',
      title: 'Salary Credit',
      subtitle: 'HDFC Bank',
      amount: 85000,
      dateTime: now.subtract(const Duration(days: 3, hours: 6)),
      type: TransactionType.received,
      bankAccount: 'HDFC •• 1234',
      referenceId: 'NEFT/402815623557',
      icon: Icons.account_balance,
      color: Colors.indigo,
    ),
    // 5 days ago
    PaymentTransaction(
      id: 'TXN011',
      title: 'Uber',
      subtitle: 'Cab Ride',
      amount: 234,
      dateTime: now.subtract(const Duration(days: 5, hours: 18)),
      type: TransactionType.sent,
      upiId: 'uber@axisbank',
      referenceId: 'UPI/402815623558',
      icon: Icons.local_taxi,
      color: Colors.black87,
    ),
    PaymentTransaction(
      id: 'TXN012',
      title: 'Tata Sky DTH',
      subtitle: 'DTH Recharge',
      amount: 450,
      dateTime: now.subtract(const Duration(days: 5, hours: 10)),
      type: TransactionType.recharge,
      referenceId: 'RCH/402815623559',
      icon: Icons.tv,
      color: Colors.blue.shade800,
    ),
    // Last week
    PaymentTransaction(
      id: 'TXN013',
      title: 'Sneha Patel',
      subtitle: 'Money Received',
      amount: 3500,
      dateTime: now.subtract(const Duration(days: 7, hours: 14)),
      type: TransactionType.received,
      upiId: 'sneha.p@ybl',
      referenceId: 'UPI/402815623560',
      icon: Icons.person,
      color: Colors.pink,
    ),
    PaymentTransaction(
      id: 'TXN014',
      title: 'BigBasket',
      subtitle: 'Groceries',
      amount: 1876,
      dateTime: now.subtract(const Duration(days: 8, hours: 11)),
      type: TransactionType.sent,
      upiId: 'bigbasket@ybl',
      referenceId: 'UPI/402815623561',
      icon: Icons.shopping_cart,
      color: Colors.green.shade700,
    ),
    PaymentTransaction(
      id: 'TXN015',
      title: 'Airtel Broadband',
      subtitle: 'Internet Bill',
      amount: 999,
      dateTime: now.subtract(const Duration(days: 10, hours: 9)),
      type: TransactionType.billPayment,
      referenceId: 'BILL/402815623562',
      icon: Icons.wifi,
      color: Colors.red.shade600,
    ),
    // 2 weeks ago
    PaymentTransaction(
      id: 'TXN016',
      title: 'Flipkart',
      subtitle: 'Electronics Purchase',
      amount: 15999,
      dateTime: now.subtract(const Duration(days: 12, hours: 16)),
      type: TransactionType.sent,
      upiId: 'flipkart@axl',
      referenceId: 'UPI/402815623563',
      icon: Icons.shopping_bag,
      color: Colors.blue.shade600,
    ),
    PaymentTransaction(
      id: 'TXN017',
      title: 'LIC Premium',
      subtitle: 'Insurance',
      amount: 8500,
      dateTime: now.subtract(const Duration(days: 15, hours: 10)),
      type: TransactionType.billPayment,
      referenceId: 'BILL/402815623564',
      icon: Icons.security,
      color: Colors.blue.shade900,
    ),
    PaymentTransaction(
      id: 'TXN018',
      title: 'Vikram Reddy',
      subtitle: 'Money Transfer',
      amount: 25000,
      dateTime: now.subtract(const Duration(days: 18, hours: 14)),
      type: TransactionType.sent,
      upiId: 'vikram.r@icici',
      referenceId: 'UPI/402815623565',
      icon: Icons.person,
      color: Colors.cyan,
    ),
    // Last month
    PaymentTransaction(
      id: 'TXN019',
      title: 'Credit Card Bill',
      subtitle: 'HDFC Credit Card',
      amount: 45678,
      dateTime: now.subtract(const Duration(days: 25, hours: 11)),
      type: TransactionType.billPayment,
      referenceId: 'BILL/402815623566',
      icon: Icons.credit_card,
      color: Colors.red.shade800,
    ),
    PaymentTransaction(
      id: 'TXN020',
      title: 'Rent Payment',
      subtitle: 'Bank Transfer',
      amount: 35000,
      dateTime: now.subtract(const Duration(days: 28, hours: 9)),
      type: TransactionType.bankTransfer,
      bankAccount: 'ICICI •• 5678',
      referenceId: 'NEFT/402815623567',
      icon: Icons.home,
      color: Colors.brown,
    ),
  ];
});

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  String _selectedFilter = 'All';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final _filters = ['All', 'Sent', 'Received', 'Bills', 'Recharge'];

  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PaymentTransaction> _filterTransactions(List<PaymentTransaction> transactions) {
    var filtered = transactions;

    // Apply type filter
    switch (_selectedFilter) {
      case 'Sent':
        filtered = filtered.where((t) => t.type == TransactionType.sent || t.type == TransactionType.bankTransfer).toList();
        break;
      case 'Received':
        filtered = filtered.where((t) => t.type == TransactionType.received || t.type == TransactionType.cashback).toList();
        break;
      case 'Bills':
        filtered = filtered.where((t) => t.type == TransactionType.billPayment).toList();
        break;
      case 'Recharge':
        filtered = filtered.where((t) => t.type == TransactionType.recharge).toList();
        break;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) => 
        t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        t.subtitle.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return filtered;
  }

  Map<String, List<PaymentTransaction>> _groupByDate(List<PaymentTransaction> transactions) {
    final grouped = <String, List<PaymentTransaction>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final txn in transactions) {
      final txnDate = DateTime(txn.dateTime.year, txn.dateTime.month, txn.dateTime.day);
      String dateLabel;

      if (txnDate == today) {
        dateLabel = 'Today';
      } else if (txnDate == yesterday) {
        dateLabel = 'Yesterday';
      } else if (now.difference(txnDate).inDays < 7) {
        dateLabel = DateFormat('EEEE').format(txn.dateTime);
      } else {
        dateLabel = DateFormat('MMM d, y').format(txn.dateTime);
      }

      grouped.putIfAbsent(dateLabel, () => []).add(txn);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionHistoryProvider);
    final filteredTransactions = _filterTransactions(transactions);
    final groupedTransactions = _groupByDate(filteredTransactions);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: ESUNColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showDownloadOptions(context),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showAdvancedFilters(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter Chips
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(filter),
                          onSelected: (_) => setState(() => _selectedFilter = filter),
                          selectedColor: ESUNColors.primary.withOpacity(0.2),
                          checkmarkColor: ESUNColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? ESUNColors.primary : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [ESUNColors.primary, Color(0xFF3D5CB8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Sent',
                    _currencyFormat.format(
                      transactions
                          .where((t) => !t.isCredit)
                          .fold(0.0, (sum, t) => sum + t.amount),
                    ),
                    Icons.arrow_upward,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white24),
                Expanded(
                  child: _buildSummaryItem(
                    'Total Received',
                    _currencyFormat.format(
                      transactions
                          .where((t) => t.isCredit)
                          .fold(0.0, (sum, t) => sum + t.amount),
                    ),
                    Icons.arrow_downward,
                  ),
                ),
              ],
            ),
          ),

          // Transaction List
          Expanded(
            child: filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions found',
                          style: ESUNTypography.bodyLarge.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: groupedTransactions.length,
                    itemBuilder: (context, index) {
                      final dateLabel = groupedTransactions.keys.elementAt(index);
                      final dayTransactions = groupedTransactions[dateLabel]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              dateLabel,
                              style: ESUNTypography.labelMedium.copyWith(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Transactions for this date
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                              children: dayTransactions.asMap().entries.map((entry) {
                                final txn = entry.value;
                                final isLast = entry.key == dayTransactions.length - 1;
                                return _buildTransactionTile(txn, isLast);
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String amount, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(PaymentTransaction txn, bool isLast) {
    return InkWell(
      onTap: () => _showTransactionDetails(txn),
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(16))
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: txn.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(txn.icon, color: txn.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.title,
                    style: ESUNTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${txn.subtitle} • ${DateFormat.jm().format(txn.dateTime)}',
                    style: ESUNTypography.labelSmall.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${txn.isCredit ? '+' : '-'}${_currencyFormat.format(txn.amount)}',
                  style: ESUNTypography.bodyMedium.copyWith(
                    color: txn.isCredit ? Colors.green : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (txn.status != TransactionStatus.success)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: txn.status == TransactionStatus.pending
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      txn.status == TransactionStatus.pending ? 'Pending' : 'Failed',
                      style: TextStyle(
                        fontSize: 10,
                        color: txn.status == TransactionStatus.pending
                            ? Colors.orange
                            : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(PaymentTransaction txn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
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
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Status Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: txn.isCredit
                            ? Colors.green.withOpacity(0.1)
                            : txn.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        txn.status == TransactionStatus.success
                            ? (txn.isCredit ? Icons.arrow_downward : Icons.arrow_upward)
                            : (txn.status == TransactionStatus.pending
                                ? Icons.hourglass_empty
                                : Icons.close),
                        color: txn.isCredit ? Colors.green : txn.color,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Amount
                    Text(
                      '${txn.isCredit ? '+' : '-'}${_currencyFormat.format(txn.amount)}',
                      style: ESUNTypography.headlineLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: txn.isCredit ? Colors.green : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: txn.status == TransactionStatus.success
                            ? Colors.green.withOpacity(0.1)
                            : (txn.status == TransactionStatus.pending
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        txn.status == TransactionStatus.success
                            ? 'Successful'
                            : (txn.status == TransactionStatus.pending ? 'Pending' : 'Failed'),
                        style: TextStyle(
                          color: txn.status == TransactionStatus.success
                              ? Colors.green
                              : (txn.status == TransactionStatus.pending
                                  ? Colors.orange
                                  : Colors.red),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Details Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('To/From', txn.title),
                          _buildDetailRow('Type', txn.subtitle),
                          if (txn.upiId != null) _buildDetailRow('UPI ID', txn.upiId!),
                          if (txn.bankAccount != null)
                            _buildDetailRow('Account', txn.bankAccount!),
                          _buildDetailRow(
                            'Date & Time',
                            DateFormat('MMM d, y • h:mm a').format(txn.dateTime),
                          ),
                          _buildDetailRow('Reference ID', txn.referenceId ?? 'N/A'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Receipt downloaded')),
                              );
                            },
                            icon: const Icon(Icons.download),
                            label: const Text('Download'),
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
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Receipt shared')),
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
                    if (!txn.isCredit) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Repeat payment to ${txn.title}')),
                            );
                          },
                          icon: const Icon(Icons.replay),
                          label: const Text('Repeat Payment'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: ESUNTypography.bodyMedium.copyWith(color: Colors.grey.shade600),
          ),
          Flexible(
            child: Text(
              value,
              style: ESUNTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  void _showDownloadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Download Statement', style: ESUNTypography.titleLarge),
            const SizedBox(height: 12),
            _buildDownloadOption('Last 30 Days', Icons.calendar_today),
            _buildDownloadOption('Last 3 Months', Icons.date_range),
            _buildDownloadOption('Last 6 Months', Icons.calendar_month),
            _buildDownloadOption('Custom Date Range', Icons.edit_calendar),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadOption(String label, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: ESUNColors.primary),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloading $label statement...')),
        );
      },
    );
  }

  void _showAdvancedFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter Transactions', style: ESUNTypography.titleLarge),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date Range'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Amount Range'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Transaction Status'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
