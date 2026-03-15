/// ESUN Search Screen
/// 
/// Universal search for transactions, contacts, and features.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../shared/widgets/widgets.dart';

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
          children: [
            _buildSearchChip('Amazon'),
            _buildSearchChip('Salary'),
            _buildSearchChip('Electricity'),
            _buildSearchChip('SIP'),
          ],
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
        _buildQuickAction(Icons.send, 'Send Money', 'UPI, Bank Transfer'),
        _buildQuickAction(Icons.receipt_long, 'Pay Bills', 'Electricity, Mobile, DTH'),
        _buildQuickAction(Icons.trending_up, 'Invest', 'Stocks, Mutual Funds'),
        _buildQuickAction(Icons.account_balance, 'Bank Statement', 'Download statements'),
        
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
  
  Widget _buildQuickAction(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.sm),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
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
        onTap: () {},
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
            padding: const EdgeInsets.all(12),
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
          padding: const EdgeInsets.all(10),
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
        onTap: () {},
      ),
    );
  }
  
  List<_SearchResult> _getSearchResults(String query) {
    final lowerQuery = query.toLowerCase();
    
    final allResults = [
      _SearchResult(
        icon: Icons.shopping_bag,
        title: 'Amazon',
        subtitle: 'Shopping • Dec 20, 2024',
        amount: '-₹2,499',
        color: Colors.orange,
      ),
      _SearchResult(
        icon: Icons.account_balance,
        title: 'Salary Credit',
        subtitle: 'Income • Dec 1, 2024',
        amount: '+₹75,000',
        color: ESUNColors.success,
      ),
      _SearchResult(
        icon: Icons.bolt,
        title: 'Electricity Bill',
        subtitle: 'Bills • Nov 15, 2024',
        amount: '-₹2,340',
        color: Colors.amber,
      ),
      _SearchResult(
        icon: Icons.trending_up,
        title: 'SIP Investment',
        subtitle: 'Investment • Dec 5, 2024',
        amount: '-₹10,000',
        color: Colors.blue,
      ),
    ];
    
    return allResults.where((r) => 
      r.title.toLowerCase().contains(lowerQuery) ||
      r.subtitle.toLowerCase().contains(lowerQuery)
    ).toList();
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



