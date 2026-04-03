/// ESUN Payment History Screen
///
/// Shows transaction history with static demo data and filtering options.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../state/transaction_state.dart' as txn_state;
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

/// Maps live Transaction state to PaymentTransaction for the history screen.
/// Automatically updates when new payments are made.
final transactionHistoryProvider = Provider<List<PaymentTransaction>>((ref) {
  final state = ref.watch(txn_state.transactionStateProvider);
  return state.transactions.map((t) => _mapTransaction(t)).toList();
});

/// Icon / color mapping from transaction category/type
PaymentTransaction _mapTransaction(txn_state.Transaction t) {
  TransactionType type;
  switch (t.type) {
    case txn_state.TransactionType.upiTransfer:
    case txn_state.TransactionType.bankTransfer:
      type = t.isDebit ? TransactionType.sent : TransactionType.received;
      break;
    case txn_state.TransactionType.billPayment:
      type = TransactionType.billPayment;
      break;
    case txn_state.TransactionType.recharge:
      type = TransactionType.recharge;
      break;
    case txn_state.TransactionType.income:
      type = TransactionType.received;
      break;
    case txn_state.TransactionType.refund:
      type = TransactionType.cashback;
      break;
  }

  TransactionStatus status;
  switch (t.status) {
    case txn_state.TransactionStatus.success:
      status = TransactionStatus.success;
      break;
    case txn_state.TransactionStatus.pending:
      status = TransactionStatus.pending;
      break;
    case txn_state.TransactionStatus.failed:
      status = TransactionStatus.failed;
      break;
  }

  final cat = (t.category ?? '').toLowerCase();
  IconData icon;
  Color color;
  if (cat.contains('food') || cat.contains('dining') || cat.contains('restaurant')) {
    icon = Icons.restaurant;
    color = Colors.deepOrange;
  } else if (cat.contains('shopping')) {
    icon = Icons.shopping_bag;
    color = ESUNColors.primary;
  } else if (cat.contains('groceries') || cat.contains('grocery')) {
    icon = Icons.shopping_cart;
    color = ESUNColors.primary;
  } else if (cat.contains('entertainment') || cat.contains('movie')) {
    icon = Icons.movie;
    color = ESUNColors.primary;
  } else if (cat.contains('recharge') || cat.contains('telecom')) {
    icon = Icons.phone_android;
    color = ESUNColors.primary;
  } else if (cat.contains('electricity') || cat.contains('utility') || cat.contains('bill')) {
    icon = Icons.bolt;
    color = ESUNColors.primary;
  } else if (cat.contains('fuel') || cat.contains('transport') || cat.contains('cab')) {
    icon = Icons.local_taxi;
    color = Colors.black87;
  } else if (cat.contains('salary') || cat.contains('income')) {
    icon = Icons.account_balance;
    color = ESUNColors.primary;
  } else if (cat.contains('insurance')) {
    icon = Icons.security;
    color = ESUNColors.primary;
  } else if (cat.contains('rent') || cat.contains('home')) {
    icon = Icons.home;
    color = ESUNColors.primary;
  } else if (cat.contains('subscription')) {
    icon = Icons.subscriptions;
    color = ESUNColors.primary;
  } else if (!t.isDebit) {
    icon = Icons.card_giftcard;
    color = ESUNColors.success;
  } else if (t.recipientName != null && t.recipientName!.isNotEmpty) {
    icon = Icons.person;
    color = ESUNColors.primary;
  } else {
    icon = Icons.payment;
    color = ESUNColors.primary;
  }

  return PaymentTransaction(
    id: t.id,
    title: t.recipientName ?? t.title,
    subtitle: t.subtitle ?? t.category ?? 'Transaction',
    amount: t.amount,
    dateTime: t.timestamp,
    type: type,
    status: status,
    upiId: t.recipientUpi,
    bankAccount: t.recipientAccount ?? t.sourceAccount,
    referenceId: t.transactionRef,
    icon: icon,
    color: color,
  );
}

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
            padding: const EdgeInsets.all(ESUNSpacing.lg),
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
            margin: const EdgeInsets.all(ESUNSpacing.lg),
            padding: const EdgeInsets.all(ESUNSpacing.lg),
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
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(ESUNSpacing.md),
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
                    color: txn.isCredit ? ESUNColors.success : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (txn.status != TransactionStatus.success)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: ESUNSpacing.tagInsets,
                    decoration: BoxDecoration(
                      color: txn.status == TransactionStatus.pending
                          ? ESUNColors.warning.withOpacity(0.1)
                          : ESUNColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      txn.status == TransactionStatus.pending ? 'Pending' : 'Failed',
                      style: TextStyle(
                        fontSize: 10,
                        color: txn.status == TransactionStatus.pending
                            ? ESUNColors.warning
                            : ESUNColors.error,
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
                padding: const EdgeInsets.all(ESUNSpacing.xxl),
                child: Column(
                  children: [
                    // Status Icon
                    Container(
                      padding: const EdgeInsets.all(ESUNSpacing.xl),
                      decoration: BoxDecoration(
                        color: txn.isCredit
                            ? ESUNColors.success.withOpacity(0.1)
                            : txn.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        txn.status == TransactionStatus.success
                            ? (txn.isCredit ? Icons.arrow_downward : Icons.arrow_upward)
                            : (txn.status == TransactionStatus.pending
                                ? Icons.hourglass_empty
                                : Icons.close),
                        color: txn.isCredit ? ESUNColors.success : txn.color,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Amount
                    Text(
                      '${txn.isCredit ? '+' : '-'}${_currencyFormat.format(txn.amount)}',
                      style: ESUNTypography.headlineLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: txn.isCredit ? ESUNColors.success : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: txn.status == TransactionStatus.success
                            ? ESUNColors.success.withOpacity(0.1)
                            : (txn.status == TransactionStatus.pending
                                ? ESUNColors.warning.withOpacity(0.1)
                                : ESUNColors.error.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        txn.status == TransactionStatus.success
                            ? 'Successful'
                            : (txn.status == TransactionStatus.pending ? 'Pending' : 'Failed'),
                        style: TextStyle(
                          color: txn.status == TransactionStatus.success
                              ? ESUNColors.success
                              : (txn.status == TransactionStatus.pending
                                  ? ESUNColors.warning
                                  : ESUNColors.error),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Details Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(ESUNSpacing.xl),
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
        padding: const EdgeInsets.all(ESUNSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Download Statement', style: ESUNTypography.titleLarge),
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
        padding: const EdgeInsets.all(ESUNSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Transactions', style: ESUNTypography.titleLarge),
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
