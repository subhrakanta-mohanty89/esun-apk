/// ESUN Search Screen
/// 
/// Universal search for transactions, contacts, and features.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../theme/theme.dart';
import '../../shared/widgets/widgets.dart';
import '../../state/transaction_state.dart';
import '../../routes/app_routes.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Search transactions, contacts, features...',
            border: InputBorder.none,
            hintStyle: ESUNTypography.bodyLarge.copyWith(
              color: ESUNColors.textTertiary,
            ),
          ),
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
          },
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: query.isEmpty ? _buildSuggestions() : _buildResults(query),
    );
  }
  
  Widget _buildSuggestions() {
    final transactions = ref.watch(transactionStateProvider).transactions;
    // Use recent transaction titles as search chips, fallback to defaults
    final recentSearches = transactions.isNotEmpty
        ? transactions.take(4).map((t) => t.title).toSet().toList()
        : ['Amazon', 'Salary', 'Electricity', 'SIP'];
    
    return ListView(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      children: [
        // Recent searches
        Text(
          'Recent Searches',
          style: ESUNTypography.titleSmall.copyWith(
            color: ESUNColors.textSecondary,
          ),
        ),
        const SizedBox(height: ESUNSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: recentSearches.map((s) => _buildSearchChip(s)).toList(),
        ),
        const SizedBox(height: ESUNSpacing.xl),
        
        // Quick Actions
        Text(
          'Quick Actions',
          style: ESUNTypography.titleSmall.copyWith(
            color: ESUNColors.textSecondary,
          ),
        ),
        const SizedBox(height: ESUNSpacing.md),
        _buildQuickAction(Icons.send, 'Send Money', 'UPI, Bank Transfer', () => context.push(AppRoutes.payments)),
        _buildQuickAction(Icons.receipt_long, 'Pay Bills', 'Electricity, Mobile, DTH', () => context.push(AppRoutes.billPayments)),
        _buildQuickAction(Icons.trending_up, 'Invest', 'Stocks, Mutual Funds', () => context.push(AppRoutes.invest)),
        _buildQuickAction(Icons.account_balance, 'Bank Statement', 'Download statements', () => context.push(AppRoutes.reports)),
        
        const SizedBox(height: ESUNSpacing.xl),
        
        // Categories
        Text(
          'Browse Categories',
          style: ESUNTypography.titleSmall.copyWith(
            color: ESUNColors.textSecondary,
          ),
        ),
        const SizedBox(height: ESUNSpacing.md),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          childAspectRatio: 0.9,
          children: [
            _buildCategoryItem(Icons.shopping_bag, 'Shopping', Colors.orange),
            _buildCategoryItem(Icons.restaurant, 'Food', Colors.red),
            _buildCategoryItem(Icons.directions_car, 'Transport', Colors.blue),
            _buildCategoryItem(Icons.movie, 'Entertainment', Colors.purple),
            _buildCategoryItem(Icons.local_hospital, 'Health', Colors.pink),
            _buildCategoryItem(Icons.school, 'Education', Colors.green),
            _buildCategoryItem(Icons.flight, 'Travel', Colors.cyan),
            _buildCategoryItem(Icons.more_horiz, 'More', Colors.grey),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSearchChip(String text) {
    return ActionChip(
      avatar: const Icon(Icons.history, size: 16),
      label: Text(text),
      onPressed: () {
        _searchController.text = text;
        ref.read(searchQueryProvider.notifier).state = text;
      },
    );
  }
  
  Widget _buildQuickAction(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.sm),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(ESUNSpacing.md),
          decoration: BoxDecoration(
            color: ESUNColors.primary.withOpacity(0.1),
            borderRadius: ESUNRadius.smRadius,
          ),
          child: Icon(icon, color: ESUNColors.primary),
        ),
        title: Text(title, style: ESUNTypography.bodyLarge),
        subtitle: Text(
          subtitle,
          style: ESUNTypography.bodySmall.copyWith(
            color: ESUNColors.textSecondary,
          ),
        ),
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
      ),
    );
  }
  
  Widget _buildCategoryItem(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        _searchController.text = label;
        ref.read(searchQueryProvider.notifier).state = label;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.md),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: ESUNTypography.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildResults(String query) {
    // Simulated search results
    final results = _getSearchResults(query);
    
    if (results.isEmpty) {
      return FPEmptyState(
        icon: Icons.search_off,
        title: 'No results found',
        description: 'Try searching for something else',
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return _buildResultItem(result);
      },
    );
  }
  
  Widget _buildResultItem(_SearchResult result) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.sm),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(ESUNSpacing.md),
          decoration: BoxDecoration(
            color: result.color.withOpacity(0.1),
            borderRadius: ESUNRadius.smRadius,
          ),
          child: Icon(result.icon, color: result.color),
        ),
        title: Text(result.title, style: ESUNTypography.bodyLarge),
        subtitle: Text(
          result.subtitle,
          style: ESUNTypography.bodySmall.copyWith(
            color: ESUNColors.textSecondary,
          ),
        ),
        trailing: result.amount != null
            ? Text(
                result.amount!,
                style: ESUNTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: result.amount!.startsWith('+') 
                      ? ESUNColors.success 
                      : ESUNColors.textPrimary,
                ),
              )
            : const Icon(Icons.chevron_right, color: ESUNColors.textTertiary),
        contentPadding: EdgeInsets.zero,
        onTap: () {
          // If it's a feature result (no amount), navigate
          if (result.amount == null) {
            final routes = {
              'Send Money': AppRoutes.payments,
              'Pay Bills': AppRoutes.billPayments,
              'Invest': AppRoutes.invest,
              'Bank Statement': AppRoutes.reports,
              'Borrow': AppRoutes.borrow,
              'Rewards': AppRoutes.rewards,
            };
            final route = routes[result.title];
            if (route != null) context.push(route);
          }
        },
      ),
    );
  }
  
  List<_SearchResult> _getSearchResults(String query) {
    final lowerQuery = query.toLowerCase();
    final transactions = ref.read(transactionStateProvider).transactions;
    final formatter = NumberFormat('#,##0', 'en_IN');
    
    // Map transactions to search results
    final results = transactions.where((txn) {
      final title = txn.title.toLowerCase();
      final subtitle = (txn.subtitle ?? '').toLowerCase();
      final category = (txn.category ?? '').toLowerCase();
      final recipient = (txn.recipientName ?? '').toLowerCase();
      return title.contains(lowerQuery) ||
          subtitle.contains(lowerQuery) ||
          category.contains(lowerQuery) ||
          recipient.contains(lowerQuery);
    }).map((txn) {
      final isCredit = txn.type == TransactionType.income || txn.type == TransactionType.refund;
      final amountStr = '${isCredit ? '+' : '-'}₹${formatter.format(txn.amount)}';
      
      IconData icon;
      Color color;
      switch (txn.type) {
        case TransactionType.billPayment:
          icon = Icons.receipt_long;
          color = Colors.amber;
          break;
        case TransactionType.upiTransfer:
          icon = Icons.send;
          color = ESUNColors.primary;
          break;
        case TransactionType.bankTransfer:
          icon = Icons.account_balance;
          color = Colors.blue;
          break;
        case TransactionType.recharge:
          icon = Icons.phone_android;
          color = Colors.green;
          break;
        case TransactionType.income:
          icon = Icons.account_balance;
          color = ESUNColors.success;
          break;
        case TransactionType.refund:
          icon = Icons.replay;
          color = ESUNColors.success;
          break;
      }
      
      final dateStr = DateFormat('MMM d, yyyy').format(txn.timestamp);
      
      return _SearchResult(
        icon: icon,
        title: txn.title,
        subtitle: '${txn.category ?? txn.type.name} • $dateStr',
        amount: amountStr,
        color: color,
      );
    }).toList();
    
    // Also search feature keywords
    final featureResults = <_SearchResult>[];
    final features = {
      'send money': _SearchResult(icon: Icons.send, title: 'Send Money', subtitle: 'UPI, Bank Transfer', color: ESUNColors.primary),
      'pay bills': _SearchResult(icon: Icons.receipt_long, title: 'Pay Bills', subtitle: 'Electricity, Mobile, DTH', color: Colors.amber),
      'invest': _SearchResult(icon: Icons.trending_up, title: 'Invest', subtitle: 'Stocks, Mutual Funds', color: Colors.blue),
      'bank statement': _SearchResult(icon: Icons.account_balance, title: 'Bank Statement', subtitle: 'Download statements', color: Colors.teal),
      'borrow': _SearchResult(icon: Icons.credit_card, title: 'Borrow', subtitle: 'Loans, EMI Calculator', color: Colors.deepPurple),
      'rewards': _SearchResult(icon: Icons.card_giftcard, title: 'Rewards', subtitle: 'Coins, Gift Cards', color: Colors.orange),
    };
    
    for (final entry in features.entries) {
      if (entry.key.contains(lowerQuery) || lowerQuery.contains(entry.key.split(' ').first)) {
        featureResults.add(entry.value);
      }
    }
    
    return [...featureResults, ...results];
  }
}

class _SearchResult {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? amount;
  final Color color;
  
  _SearchResult({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.amount,
    required this.color,
  });
}



