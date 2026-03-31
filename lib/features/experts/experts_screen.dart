/// ESUN Experts Screen
/// 
/// Connect with financial advisors and experts.
/// Features search, filters, and location-based discovery.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../shared/widgets/widgets.dart';
import 'expert_provider.dart';
import 'expert_filter_sheet.dart';

class ExpertsScreen extends ConsumerStatefulWidget {
  const ExpertsScreen({super.key});

  @override
  ConsumerState<ExpertsScreen> createState() => _ExpertsScreenState();
}

class _ExpertsScreenState extends ConsumerState<ExpertsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when near the bottom
      ref.read(expertSearchProvider.notifier).loadMore();
    }
  }

  Future<void> _openFilterSheet() async {
    final currentFilters = ref.read(expertSearchProvider).filters;
    final newFilters = await showExpertFilterSheet(
      context,
      currentFilters: currentFilters,
    );
    if (newFilters != null) {
      ref.read(expertSearchProvider.notifier).updateFilters(newFilters);
      setState(() => _showSearchResults = true);
    }
  }

  void _onSearch(String query) {
    ref.read(expertSearchProvider.notifier).setSearchQuery(query);
    if (query.isNotEmpty) {
      ref.read(expertSearchProvider.notifier).search();
      setState(() => _showSearchResults = true);
    } else {
      setState(() => _showSearchResults = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(expertSearchProvider);
    final filterCount = searchState.filters.activeFilterCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Experts'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _openFilterSheet,
              ),
              if (filterCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(ESUNSpacing.xs),
                    decoration: const BoxDecoration(
                      color: ESUNColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$filterCount',
                      style: ESUNTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          
          // Content
          Expanded(
            child: _showSearchResults
                ? _buildSearchResults(searchState)
                : _buildDiscoveryView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search experts by name or specialty...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch('');
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.my_location),
                  tooltip: 'Find nearby experts',
                  onPressed: _showLocationSearch,
                ),
          border: OutlineInputBorder(
            borderRadius: ESUNRadius.lgRadius,
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: ESUNColors.surfaceVariant,
        ),
        onChanged: _onSearch,
        onSubmitted: _onSearch,
      ),
    );
  }

  void _showLocationSearch() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _LocationSearchSheet(
        onLocationSelected: (city, state) {
          ref.read(expertSearchProvider.notifier).setLocation(
            city: city,
            locationState: state,
          );
          Navigator.pop(context);
          setState(() => _showSearchResults = true);
        },
      ),
    );
  }

  Widget _buildSearchResults(ExpertSearchState state) {
    if (state.isLoading && state.experts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.experts.isEmpty) {
      return _buildErrorState(state.error!);
    }

    if (state.experts.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Results header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
          child: Row(
            children: [
              Text(
                '${state.pagination.total} experts found',
                style: ESUNTypography.bodyMedium.copyWith(
                  color: ESUNColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (state.filters.hasActiveFilters)
                TextButton.icon(
                  onPressed: () {
                    ref.read(expertSearchProvider.notifier).resetFilters();
                    _searchController.clear();
                    setState(() => _showSearchResults = false);
                  },
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear'),
                ),
            ],
          ),
        ),
        // Results list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(ESUNSpacing.lg, ESUNSpacing.lg, ESUNSpacing.lg, 100),
            itemCount: state.experts.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.experts.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(ESUNSpacing.lg),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return _buildExpertResultCard(state.experts[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExpertResultCard(Expert expert) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.md),
      child: FPCard(
        onTap: () => _showExpertDetail(expert),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: _getSpecializationColor(expert.primarySpecialization).withOpacity(0.1),
                  child: Text(
                    expert.initials,
                    style: ESUNTypography.titleSmall.copyWith(
                      color: _getSpecializationColor(expert.primarySpecialization),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (expert.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: ESUNColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: ESUNSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        expert.name,
                        style: ESUNTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (expert.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 16, color: ESUNColors.info),
                      ],
                    ],
                  ),
                  Text(
                    expert.primarySpecialization,
                    style: ESUNTypography.bodySmall.copyWith(
                      color: _getSpecializationColor(expert.primarySpecialization),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      Text(
                        ' ${expert.averageRating} (${expert.totalReviews})',
                        style: ESUNTypography.labelSmall.copyWith(
                          color: ESUNColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: ESUNSpacing.md),
                      if (expert.distanceKm != null) ...[
                        const Icon(Icons.location_on, size: 14, color: ESUNColors.textTertiary),
                        Text(
                          ' ${expert.distanceKm!.toStringAsFixed(1)} km',
                          style: ESUNTypography.labelSmall.copyWith(
                            color: ESUNColors.textSecondary,
                          ),
                        ),
                      ] else if (expert.city != null) ...[
                        const Icon(Icons.location_on, size: 14, color: ESUNColors.textTertiary),
                        Text(
                          ' ${expert.city}',
                          style: ESUNTypography.labelSmall.copyWith(
                            color: ESUNColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Price & Book
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${expert.consultationFee.toInt()}',
                  style: ESUNTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ElevatedButton(
                  onPressed: () => _showBookingSheet(context, _convertToLocalExpert(expert)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Book'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showExpertDetail(Expert expert) {
    // Show expert detail modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExpertDetailSheet(expert: expert),
    );
  }

  Widget _buildDiscoveryView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expert categories
          _buildCategories(context),
          
          // Featured experts
          _buildFeaturedExperts(context),
          
          // Book Consultation Banner
          _buildConsultationBanner(context),
          
          // All Experts
          _buildAllExperts(context),
          
          // Upcoming Sessions
          _buildUpcomingSessions(context),
          
          const SizedBox(height: 72),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: ESUNColors.error),
          const SizedBox(height: ESUNSpacing.lg),
          Text(
            'Something went wrong',
            style: ESUNTypography.titleMedium,
          ),
          const SizedBox(height: ESUNSpacing.sm),
          Text(
            error,
            style: ESUNTypography.bodySmall.copyWith(
              color: ESUNColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ESUNSpacing.lg),
          FPButton(
            label: 'Retry',
            onPressed: () => ref.read(expertSearchProvider.notifier).search(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: ESUNColors.textTertiary),
          const SizedBox(height: ESUNSpacing.lg),
          Text(
            'No experts found',
            style: ESUNTypography.titleMedium,
          ),
          const SizedBox(height: ESUNSpacing.sm),
          Text(
            'Try adjusting your filters or search query',
            style: ESUNTypography.bodySmall.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          FPButton(
            label: 'Clear Filters',
            variant: FPButtonVariant.outline,
            onPressed: () {
              ref.read(expertSearchProvider.notifier).resetFilters();
              _searchController.clear();
              setState(() => _showSearchResults = false);
            },
          ),
        ],
      ),
    );
  }

  Color _getSpecializationColor(String specialization) {
    final spec = specialization.toLowerCase();
    if (spec.contains('tax')) return Colors.green;
    if (spec.contains('investment')) return Colors.blue;
    if (spec.contains('insurance')) return Colors.orange;
    if (spec.contains('loan')) return Colors.purple;
    if (spec.contains('retirement')) return Colors.teal;
    if (spec.contains('legal')) return Colors.red;
    if (spec.contains('mutual')) return Colors.indigo;
    return ESUNColors.primary;
  }

  _Expert _convertToLocalExpert(Expert expert) {
    return _Expert(
      name: expert.name,
      expertise: expert.primarySpecialization,
      experience: '${expert.experienceYears}+ years',
      rating: expert.averageRating,
      reviews: expert.totalReviews,
      fee: '₹${expert.consultationFee.toInt()}',
      color: _getSpecializationColor(expert.primarySpecialization),
    );
  }

  Widget _buildCategories(BuildContext context) {
    final categories = [
      _ExpertCategory('Tax', Icons.receipt_long, Colors.green),
      _ExpertCategory('Investment', Icons.trending_up, Colors.blue),
      _ExpertCategory('Insurance', Icons.shield, Colors.orange),
      _ExpertCategory('Loan', Icons.account_balance, Colors.purple),
      _ExpertCategory('Retirement', Icons.elderly, Colors.teal),
      _ExpertCategory('Legal', Icons.gavel, Colors.red),
    ];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expert Categories',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: ESUNSpacing.md),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: cat.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cat.icon, color: cat.color, size: 24),
                      ),
                      const SizedBox(height: ESUNSpacing.xs),
                      Text(
                        cat.name,
                        style: ESUNTypography.labelSmall,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeaturedExperts(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Rated',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildExpertCard(
                  context,
                  'Dr. Anita Sharma',
                  'Tax Consultant',
                  '15+ years',
                  4.9,
                  234,
                  '₹500',
                  Colors.green,
                ),
                _buildExpertCard(
                  context,
                  'Rajesh Kumar',
                  'Investment Advisor',
                  '12+ years',
                  4.8,
                  189,
                  '₹750',
                  Colors.blue,
                ),
                _buildExpertCard(
                  context,
                  'Priya Patel',
                  'Insurance Expert',
                  '10+ years',
                  4.7,
                  156,
                  '₹400',
                  Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExpertCard(
    BuildContext context,
    String name,
    String expertise,
    String experience,
    double rating,
    int reviews,
    String fee,
    Color color,
  ) {
    final expert = _Expert(
      name: name,
      expertise: expertise,
      experience: experience,
      rating: rating,
      reviews: reviews,
      fee: fee,
      color: color,
    );

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: ESUNSpacing.md),
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: ESUNColors.surface,
        borderRadius: ESUNRadius.lgRadius,
        border: Border.all(color: ESUNColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.1),
                child: Text(
                  name.split(' ').map((e) => e[0]).take(2).join(),
                  style: ESUNTypography.titleSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: ESUNSpacing.badgeInsets,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: ESUNRadius.fullRadius,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      rating.toString(),
                      style: ESUNTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          Text(
            name,
            style: ESUNTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            expertise,
            style: ESUNTypography.bodySmall.copyWith(
              color: color,
            ),
          ),
          Text(
            experience,
            style: ESUNTypography.labelSmall.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                fee,
                style: ESUNTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '/session',
                style: ESUNTypography.labelSmall.copyWith(
                  color: ESUNColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '$reviews reviews',
                style: ESUNTypography.labelSmall.copyWith(
                  color: ESUNColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.sm),
          FPButton(
            label: 'Book',
            size: FPButtonSize.small,
            onPressed: () => _showBookingSheet(context, expert),
            isExpanded: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildConsultationBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
          ),
          borderRadius: ESUNRadius.lgRadius,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Free 15-min Consultation',
                    style: ESUNTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'First-time users get a free consultation with any expert',
                    style: ESUNTypography.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: ESUNSpacing.md),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0EA5E9),
                    ),
                    child: const Text('Book Now'),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.support_agent,
              size: 70,
              color: Colors.white24,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAllExperts(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Experts',
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
          _buildExpertListItem(
            context,
            'Vikram Mehta',
            'Retirement Planning',
            4.6,
            145,
            '₹600',
            Colors.teal,
            true,
          ),
          _buildExpertListItem(
            context,
            'Sunita Joshi',
            'Mutual Funds Expert',
            4.5,
            98,
            '₹450',
            Colors.purple,
            false,
          ),
          _buildExpertListItem(
            context,
            'Amit Gupta',
            'Personal Finance Coach',
            4.8,
            267,
            '₹350',
            Colors.blue,
            true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildExpertListItem(
    BuildContext context,
    String name,
    String expertise,
    double rating,
    int reviews,
    String fee,
    Color color,
    bool isOnline,
  ) {
    final expert = _Expert(
      name: name,
      expertise: expertise,
      experience: '10+ years',
      rating: rating,
      reviews: reviews,
      fee: fee,
      color: color,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.md),
      child: FPCard(
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: color.withOpacity(0.1),
                  child: Text(
                    name.split(' ').map((e) => e[0]).take(2).join(),
                    style: ESUNTypography.titleSmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: ESUNColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: ESUNSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: ESUNTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    expertise,
                    style: ESUNTypography.bodySmall.copyWith(
                      color: ESUNColors.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      Text(
                        ' $rating ($reviews)',
                        style: ESUNTypography.labelSmall.copyWith(
                          color: ESUNColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fee,
                  style: ESUNTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ElevatedButton(
                  onPressed: () => _showBookingSheet(context, expert),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Book'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUpcomingSessions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Sessions',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          FPCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(ESUNSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: ESUNRadius.smRadius,
                      ),
                      child: const Icon(Icons.video_call, color: Colors.blue),
                    ),
                    const SizedBox(width: ESUNSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tax Planning Session',
                            style: ESUNTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'with Dr. Anita Sharma',
                            style: ESUNTypography.bodySmall.copyWith(
                              color: ESUNColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: ESUNColors.success.withOpacity(0.1),
                        borderRadius: ESUNRadius.fullRadius,
                      ),
                      child: Text(
                        'Confirmed',
                        style: ESUNTypography.labelSmall.copyWith(
                          color: ESUNColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: ESUNSpacing.xl),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: ESUNColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Tomorrow, 3:00 PM',
                      style: ESUNTypography.bodySmall.copyWith(
                        color: ESUNColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _showPreJoinDialog(context),
                      child: const Text('Reschedule'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _showPreJoinDialog(context),
                      child: const Text('Join'),
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
}

class _ExpertCategory {
  final String name;
  final IconData icon;
  final Color color;
  
  _ExpertCategory(this.name, this.icon, this.color);
}

class _Expert {
  final String name;
  final String expertise;
  final String experience;
  final double rating;
  final int reviews;
  final String fee;
  final Color color;

  _Expert({
    required this.name,
    required this.expertise,
    required this.experience,
    required this.rating,
    required this.reviews,
    required this.fee,
      required this.color,
  });
}

void _showBookingSheet(BuildContext context, _Expert expert) {
  // First show consultation type selection
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: ESUNSpacing.lg),
                decoration: BoxDecoration(
                  color: ESUNColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: expert.color.withOpacity(0.12),
                  child: Text(
                    expert.name.split(' ').map((e) => e[0]).take(2).join(),
                    style: ESUNTypography.titleMedium.copyWith(
                      color: expert.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: ESUNSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expert.name,
                        style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        expert.expertise,
                        style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: ESUNSpacing.xl),
            Text(
              'How would you like to consult?',
              style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: ESUNSpacing.md),
            // Chat Option
            _buildConsultTypeOption(
              context: context,
              icon: Icons.chat_bubble_outline,
              title: 'Chat',
              subtitle: 'Text-based consultation • Instant',
              price: '₹199',
              color: Colors.green,
              onTap: () {
                Navigator.pop(ctx);
                _showChatBookingFlow(context, expert);
              },
            ),
            const SizedBox(height: ESUNSpacing.sm),
            // Call Option
            _buildConsultTypeOption(
              context: context,
              icon: Icons.phone_outlined,
              title: 'Voice Call',
              subtitle: 'Audio consultation • 30 mins',
              price: expert.fee,
              color: Colors.blue,
              isRecommended: true,
              onTap: () {
                Navigator.pop(ctx);
                _showDateTimeBookingSheet(context, expert, 'call');
              },
            ),
            const SizedBox(height: ESUNSpacing.sm),
            // Video Call Option
            _buildConsultTypeOption(
              context: context,
              icon: Icons.videocam_outlined,
              title: 'Video Call',
              subtitle: 'Face-to-face consultation • 30 mins',
              price: '₹${int.parse(expert.fee.replaceAll(RegExp(r'[^0-9]'), '')) + 100}',
              color: Colors.purple,
              onTap: () {
                Navigator.pop(ctx);
                _showDateTimeBookingSheet(context, expert, 'video');
              },
            ),
            const SizedBox(height: ESUNSpacing.sm),
            // Walk-in Option
            _buildConsultTypeOption(
              context: context,
              icon: Icons.location_on_outlined,
              title: 'Walk-in Visit',
              subtitle: 'In-person meeting at office',
              price: '₹${int.parse(expert.fee.replaceAll(RegExp(r'[^0-9]'), '')) + 200}',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(ctx);
                _showWalkInBookingSheet(context, expert);
              },
            ),
            const SizedBox(height: ESUNSpacing.lg),
          ],
        ),
      );
    },
  );
}

Widget _buildConsultTypeOption({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String subtitle,
  required String price,
  required Color color,
  required VoidCallback onTap,
  bool isRecommended = false,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: ESUNRadius.mdRadius,
        border: Border.all(
          color: isRecommended ? color : color.withOpacity(0.2),
          width: isRecommended ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.md),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: ESUNRadius.smRadius,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: ESUNTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (isRecommended) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: ESUNRadius.fullRadius,
                        ),
                        child: Text(
                          'RECOMMENDED',
                          style: ESUNTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  subtitle,
                  style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: ESUNTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: ESUNColors.textTertiary),
            ],
          ),
        ],
      ),
    ),
  );
}

void _showChatBookingFlow(BuildContext context, _Expert expert) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ESUNColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: ESUNSpacing.lg),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: expert.color.withOpacity(0.12),
                        child: Text(
                          expert.name.split(' ').map((e) => e[0]).take(2).join(),
                          style: ESUNTypography.titleSmall.copyWith(
                            color: expert.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: ESUNSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chat with ${expert.name}',
                              style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: ESUNColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Online now',
                                  style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.success),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(ESUNSpacing.lg),
                children: [
                  _buildChatBubble(
                    'Hello! I\'m ${expert.name}. How can I help you today with your ${expert.expertise.toLowerCase()} needs?',
                    true,
                    expert.color,
                  ),
                  _buildChatBubble(
                    'Feel free to ask any questions about tax planning, investments, or financial advice.',
                    true,
                    expert.color,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(ESUNSpacing.md),
              decoration: BoxDecoration(
                color: ESUNColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(
                          borderRadius: ESUNRadius.fullRadius,
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: ESUNColors.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message sent!')),
                      );
                    },
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildChatBubble(String text, bool isExpert, Color color) {
  return Align(
    alignment: isExpert ? Alignment.centerLeft : Alignment.centerRight,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(ESUNSpacing.md),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: isExpert ? color.withOpacity(0.1) : ESUNColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: ESUNTypography.bodyMedium.copyWith(
          color: isExpert ? ESUNColors.textPrimary : Colors.white,
        ),
      ),
    ),
  );
}

void _showWalkInBookingSheet(BuildContext context, _Expert expert) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
      String selectedSlot = '10:00 AM';
      final slots = ['10:00 AM', '11:30 AM', '2:00 PM', '4:30 PM'];

      return StatefulBuilder(
        builder: (context, setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: ESUNSpacing.lg),
                      decoration: BoxDecoration(
                        color: ESUNColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Walk-in Consultation',
                        style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: ESUNSpacing.lg),
                  // Office Location Card
                  Container(
                    padding: const EdgeInsets.all(ESUNSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.05),
                      borderRadius: ESUNRadius.mdRadius,
                      border: Border.all(color: Colors.orange.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(ESUNSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: ESUNRadius.smRadius,
                          ),
                          child: const Icon(Icons.business, color: Colors.orange, size: 28),
                        ),
                        const SizedBox(width: ESUNSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${expert.name}\'s Office',
                                style: ESUNTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '123, Financial District, Mumbai - 400001',
                                style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.directions, size: 14, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Text(
                                    '2.5 km away • 15 min drive',
                                    style: ESUNTypography.labelSmall.copyWith(color: Colors.blue),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ESUNSpacing.xl),
                  Text('Select Date', style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: ESUNSpacing.sm),
                  SizedBox(
                    height: 86,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (_, i) {
                        final date = DateTime.now().add(Duration(days: i + 1));
                        final isSelected = date.day == selectedDate.day && date.month == selectedDate.month;
                        return GestureDetector(
                          onTap: () => setState(() => selectedDate = date),
                          child: Container(
                            width: 68,
                            padding: const EdgeInsets.all(ESUNSpacing.md),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.orange.withOpacity(0.12) : ESUNColors.surfaceVariant,
                              borderRadius: ESUNRadius.mdRadius,
                              border: Border.all(color: isSelected ? Colors.orange : ESUNColors.border),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'][date.weekday % 7],
                                  style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  date.day.toString().padLeft(2, '0'),
                                  style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: ESUNSpacing.sm),
                      itemCount: 10,
                    ),
                  ),
                  const SizedBox(height: ESUNSpacing.lg),
                  Text('Available Slots', style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: ESUNSpacing.sm),
                  Wrap(
                    spacing: ESUNSpacing.sm,
                    runSpacing: ESUNSpacing.sm,
                    children: slots.map((slot) {
                      final isSelected = slot == selectedSlot;
                      return ChoiceChip(
                        label: Text(slot),
                        selected: isSelected,
                        onSelected: (_) => setState(() => selectedSlot = slot),
                        selectedColor: Colors.orange.withOpacity(0.15),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: ESUNSpacing.xl),
                  // What to bring section
                  Container(
                    padding: const EdgeInsets.all(ESUNSpacing.md),
                    decoration: BoxDecoration(
                      color: ESUNColors.surfaceVariant,
                      borderRadius: ESUNRadius.mdRadius,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What to bring',
                          style: ESUNTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: ESUNSpacing.sm),
                        _buildBringItem(Icons.badge, 'Valid ID Proof'),
                        _buildBringItem(Icons.description, 'Relevant documents'),
                        _buildBringItem(Icons.phone_android, 'Your device for verification'),
                      ],
                    ),
                  ),
                  const SizedBox(height: ESUNSpacing.xl),
                  // Payment summary
                  Text('Payment Summary', style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: ESUNSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(ESUNSpacing.md),
                    decoration: BoxDecoration(
                      color: ESUNColors.surfaceVariant,
                      borderRadius: ESUNRadius.mdRadius,
                    ),
                    child: Column(
                      children: [
                        _priceRow('Consultation fee', '₹${int.parse(expert.fee.replaceAll(RegExp(r'[^0-9]'), '')) + 200}'),
                        _priceRow('Booking fee', '₹49'),
                        const Divider(height: ESUNSpacing.xl),
                        _priceRow('Total', '₹${int.parse(expert.fee.replaceAll(RegExp(r'[^0-9]'), '')) + 249}', isBold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: ESUNSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Walk-in appointment booked! You will receive a confirmation.')),
                        );
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Confirm Booking'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
                      ),
                    ),
                  ),
                  const SizedBox(height: ESUNSpacing.lg),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildBringItem(IconData icon, String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 18, color: ESUNColors.textSecondary),
        const SizedBox(width: 8),
        Text(text, style: ESUNTypography.bodySmall),
      ],
    ),
  );
}

void _showDateTimeBookingSheet(BuildContext context, _Expert expert, String type) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
      String selectedSlot = '10:00 AM';
      final slots = ['10:00 AM', '11:30 AM', '2:00 PM', '4:30 PM', '7:00 PM'];

      return StatefulBuilder(
        builder: (context, setState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 24,
                      offset: Offset(0, -8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(ESUNSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: ESUNSpacing.lg),
                          decoration: BoxDecoration(
                            color: ESUNColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: expert.color.withOpacity(0.12),
                            child: Text(
                              expert.name.split(' ').map((e) => e[0]).take(2).join(),
                              style: ESUNTypography.titleMedium.copyWith(
                                color: expert.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: ESUNSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expert.name,
                                  style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  expert.expertise,
                                  style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      type == 'video' ? Icons.videocam : Icons.phone,
                                      size: 14,
                                      color: type == 'video' ? Colors.purple : Colors.blue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      type == 'video' ? 'Video Call' : 'Voice Call',
                                      style: ESUNTypography.labelSmall.copyWith(
                                        color: type == 'video' ? Colors.purple : Colors.blue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                type == 'video' 
                                    ? '₹${int.parse(expert.fee.replaceAll(RegExp(r'[^0-9]'), '')) + 100}'
                                    : expert.fee,
                                style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text('/30 min', style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: ESUNSpacing.xl),
                      Text('Choose date', style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: ESUNSpacing.sm),
                      SizedBox(
                        height: 86,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (_, i) {
                            final date = DateTime.now().add(Duration(days: i));
                            final isSelected = date.day == selectedDate.day && date.month == selectedDate.month;
                            return GestureDetector(
                              onTap: () => setState(() => selectedDate = date),
                              child: Container(
                                width: 68,
                                padding: const EdgeInsets.all(ESUNSpacing.md),
                                decoration: BoxDecoration(
                                  color: isSelected ? ESUNColors.primary.withOpacity(0.12) : ESUNColors.surfaceVariant,
                                  borderRadius: ESUNRadius.mdRadius,
                                  border: Border.all(color: isSelected ? ESUNColors.primary : ESUNColors.border),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'][date.weekday % 7],
                                      style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      date.day.toString().padLeft(2, '0'),
                                      style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(width: ESUNSpacing.sm),
                          itemCount: 10,
                        ),
                      ),
                      const SizedBox(height: ESUNSpacing.lg),
                      Text('Select time slot', style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: ESUNSpacing.sm),
                      Wrap(
                        spacing: ESUNSpacing.sm,
                        runSpacing: ESUNSpacing.sm,
                        children: slots.map((slot) {
                          final isSelected = slot == selectedSlot;
                          return ChoiceChip(
                            label: Text(slot),
                            selected: isSelected,
                            onSelected: (_) => setState(() => selectedSlot = slot),
                            selectedColor: ESUNColors.primary.withOpacity(0.15),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: ESUNSpacing.xl),
                      Text('Payment summary', style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: ESUNSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(ESUNSpacing.md),
                        decoration: BoxDecoration(
                          color: ESUNColors.surfaceVariant,
                          borderRadius: ESUNRadius.mdRadius,
                        ),
                        child: Column(
                          children: [
                            _priceRow('Consultation fee', type == 'video' 
                                ? '₹${int.parse(expert.fee.replaceAll(RegExp(r'[^0-9]'), '')) + 100}'
                                : expert.fee),
                            _priceRow('Platform fee', '₹29'),
                            _priceRow('Tax', '₹18'),
                            const Divider(height: ESUNSpacing.xl),
                            _priceRow('Total', _sumTotal(type == 'video' 
                                ? '₹${int.parse(expert.fee.replaceAll(RegExp(r'[^0-9]'), '')) + 100}'
                                : expert.fee, 29, 18), isBold: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: ESUNSpacing.lg),
                      FPButton(
                        label: 'Pay & Book',
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${type == 'video' ? 'Video' : 'Voice'} call session booked. Payment processed.')),
                          );
                        },
                        isExpanded: true,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

Widget _priceRow(String label, String value, {bool isBold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Text(label, style: isBold ? ESUNTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700) : ESUNTypography.bodyMedium),
        const Spacer(),
        Text(value, style: isBold ? ESUNTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700) : ESUNTypography.bodyMedium),
      ],
    ),
  );
}

String _sumTotal(String fee, int platform, int tax) {
  final numeric = int.tryParse(fee.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  final total = numeric + platform + tax;
  return '₹$total';
}

void _showPreJoinDialog(BuildContext context) {
  bool micOn = true;
  bool camOn = true;
  bool speakerOn = true;

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: ESUNRadius.lgRadius),
            title: const Text('Prepare to join'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enable devices before entering the call.', style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textSecondary)),
                const SizedBox(height: ESUNSpacing.md),
                Wrap(
                  spacing: ESUNSpacing.sm,
                  children: [
                    FilterChip(
                      label: Text(micOn ? 'Mic On' : 'Mic Off'),
                      selected: micOn,
                      onSelected: (_) => setState(() => micOn = !micOn),
                      avatar: Icon(micOn ? Icons.mic : Icons.mic_off, size: 18),
                    ),
                    FilterChip(
                      label: Text(camOn ? 'Camera On' : 'Camera Off'),
                      selected: camOn,
                      onSelected: (_) => setState(() => camOn = !camOn),
                      avatar: Icon(camOn ? Icons.videocam : Icons.videocam_off, size: 18),
                    ),
                    FilterChip(
                      label: Text(speakerOn ? 'Speaker' : 'Earpiece'),
                      selected: speakerOn,
                      onSelected: (_) => setState(() => speakerOn = !speakerOn),
                      avatar: Icon(Icons.volume_up, size: 18),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _showCallUi(context, micOn: micOn, camOn: camOn, speakerOn: speakerOn);
                },
                child: const Text('Join now'),
              ),
            ],
          );
        },
      );
    },
  );
}

void _showCallUi(BuildContext context, {required bool micOn, required bool camOn, required bool speakerOn}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    color: Colors.grey.shade900,
                    child: const Center(
                      child: Icon(Icons.videocam, color: Colors.white24, size: 120),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 16,
                  child: Container(
                    width: 110,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: ESUNRadius.mdRadius,
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Center(
                      child: Icon(Icons.person, color: Colors.white38, size: 48),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(ESUNSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: ESUNRadius.mdRadius,
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.timer, color: Colors.white70, size: 16),
                            SizedBox(width: 6),
                            Text('00:24', style: TextStyle(color: Colors.white70)),
                            Spacer(),
                            Icon(Icons.lock, color: Colors.white70, size: 16),
                            SizedBox(width: 6),
                            Text('End-to-end encrypted', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                      const SizedBox(height: ESUNSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _callButton(
                            icon: micOn ? Icons.mic : Icons.mic_off,
                            color: micOn ? Colors.white : Colors.red,
                            label: 'Mic',
                            onTap: () => setState(() => micOn = !micOn),
                          ),
                          _callButton(
                            icon: camOn ? Icons.videocam : Icons.videocam_off,
                            color: camOn ? Colors.white : Colors.red,
                            label: 'Video',
                            onTap: () => setState(() => camOn = !camOn),
                          ),
                          _callButton(
                            icon: Icons.screen_share,
                            color: Colors.white,
                            label: 'Share',
                            onTap: () {},
                          ),
                          _callButton(
                            icon: speakerOn ? Icons.volume_up : Icons.hearing,
                            color: Colors.white,
                            label: 'Audio',
                            onTap: () => setState(() => speakerOn = !speakerOn),
                          ),
                          _callButton(
                            icon: Icons.chat,
                            color: Colors.white,
                            label: 'Chat',
                            onTap: () {},
                          ),
                          _callButton(
                            icon: Icons.call_end,
                            color: Colors.red,
                            label: 'Leave',
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _callButton({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
  return Column(
    children: [
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white12,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, color: color),
        ),
      ),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ],
  );
}

// ============================================================================
// Location Search Sheet
// ============================================================================

class _LocationSearchSheet extends StatefulWidget {
  final void Function(String city, String? state) onLocationSelected;

  const _LocationSearchSheet({required this.onLocationSelected});

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  final _controller = TextEditingController();
  String? _selectedCity;

  static const _popularCities = [
    ('Mumbai', 'Maharashtra'),
    ('Delhi', 'Delhi'),
    ('Bangalore', 'Karnataka'),
    ('Hyderabad', 'Telangana'),
    ('Chennai', 'Tamil Nadu'),
    ('Pune', 'Maharashtra'),
    ('Kolkata', 'West Bengal'),
    ('Ahmedabad', 'Gujarat'),
    ('Jaipur', 'Rajasthan'),
    ('Lucknow', 'Uttar Pradesh'),
    ('Chandigarh', 'Punjab'),
    ('Kochi', 'Kerala'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: ESUNRadius.sheetRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: ESUNColors.primary),
              const SizedBox(width: ESUNSpacing.sm),
              Text(
                'Find Experts Near You',
                style: ESUNTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.lg),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Enter city name...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: ESUNRadius.mdRadius,
              ),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                widget.onLocationSelected(value, null);
              }
            },
          ),
          const SizedBox(height: ESUNSpacing.lg),
          Text(
            'Popular Cities',
            style: ESUNTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: ESUNColors.textSecondary,
            ),
          ),
          const SizedBox(height: ESUNSpacing.sm),
          Wrap(
            spacing: ESUNSpacing.sm,
            runSpacing: ESUNSpacing.sm,
            children: _popularCities.map((city) {
              final isSelected = _selectedCity == city.$1;
              return ActionChip(
                avatar: Icon(
                  Icons.location_city,
                  size: 16,
                  color: isSelected ? ESUNColors.primary : ESUNColors.textSecondary,
                ),
                label: Text(city.$1),
                backgroundColor: isSelected 
                    ? ESUNColors.primary.withOpacity(0.1) 
                    : ESUNColors.surfaceVariant,
                labelStyle: TextStyle(
                  color: isSelected ? ESUNColors.primary : ESUNColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                onPressed: () {
                  setState(() => _selectedCity = city.$1);
                  widget.onLocationSelected(city.$1, city.$2);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: ESUNSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement GPS location detection
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('GPS location coming soon!')),
                );
              },
              icon: const Icon(Icons.my_location),
              label: const Text('Use My Current Location'),
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
        ],
      ),
    );
  }
}

// ============================================================================
// Expert Detail Sheet
// ============================================================================

class _ExpertDetailSheet extends StatelessWidget {
  final Expert expert;

  const _ExpertDetailSheet({required this.expert});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: ESUNRadius.sheetRadius,
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ESUNColors.divider,
              borderRadius: ESUNRadius.fullRadius,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              children: [
                // Profile Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: ESUNColors.primary.withOpacity(0.1),
                      child: Text(
                        expert.initials,
                        style: ESUNTypography.titleLarge.copyWith(
                          color: ESUNColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: ESUNSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  expert.name,
                                  style: ESUNTypography.titleLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (expert.isVerified)
                                const Icon(Icons.verified, color: ESUNColors.info),
                            ],
                          ),
                          Text(
                            expert.primarySpecialization,
                            style: ESUNTypography.bodyMedium.copyWith(
                              color: ESUNColors.primary,
                            ),
                          ),
                          Text(
                            '${expert.experienceYears}+ years experience',
                            style: ESUNTypography.bodySmall.copyWith(
                              color: ESUNColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ESUNSpacing.lg),
                
                // Stats Row
                Container(
                  padding: const EdgeInsets.all(ESUNSpacing.md),
                  decoration: BoxDecoration(
                    color: ESUNColors.surfaceVariant,
                    borderRadius: ESUNRadius.mdRadius,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat(Icons.star, '${expert.averageRating}', 'Rating'),
                      _buildDivider(),
                      _buildStat(Icons.rate_review, '${expert.totalReviews}', 'Reviews'),
                      _buildDivider(),
                      _buildStat(Icons.people, '${expert.totalConsultations}', 'Sessions'),
                    ],
                  ),
                ),
                const SizedBox(height: ESUNSpacing.lg),
                
                // Bio
                if (expert.bio != null) ...[
                  Text(
                    'About',
                    style: ESUNTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: ESUNSpacing.sm),
                  Text(
                    expert.bio!,
                    style: ESUNTypography.bodyMedium.copyWith(
                      color: ESUNColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: ESUNSpacing.lg),
                ],
                
                // Specializations
                Text(
                  'Expertise',
                  style: ESUNTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: ESUNSpacing.sm),
                Wrap(
                  spacing: ESUNSpacing.sm,
                  runSpacing: ESUNSpacing.sm,
                  children: expert.specializations.map((spec) {
                    return Chip(
                      label: Text(spec.replaceAll('_', ' ').toUpperCase()),
                      backgroundColor: ESUNColors.primary.withOpacity(0.1),
                      labelStyle: ESUNTypography.labelSmall.copyWith(
                        color: ESUNColors.primary,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: ESUNSpacing.lg),
                
                // Details
                Text(
                  'Details',
                  style: ESUNTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: ESUNSpacing.sm),
                _buildDetailRow(Icons.location_on, 'Location', expert.locationString),
                _buildDetailRow(Icons.language, 'Languages', expert.languages.join(', ')),
                _buildDetailRow(
                  Icons.videocam,
                  'Session Type',
                  [
                    if (expert.offersOnline) 'Online',
                    if (expert.offersInPerson) 'In-Person',
                  ].join(', '),
                ),
                _buildDetailRow(Icons.schedule, 'Duration', '${expert.sessionDurationMinutes} minutes'),
                const SizedBox(height: ESUNSpacing.xxl),
              ],
            ),
          ),
          
          // Bottom CTA
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${expert.consultationFee.toInt()}',
                      style: ESUNTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'per session',
                      style: ESUNTypography.bodySmall.copyWith(
                        color: ESUNColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                FPButton(
                  label: 'Book Consultation',
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Open booking flow
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: ESUNColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: ESUNTypography.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: ESUNTypography.labelSmall.copyWith(
            color: ESUNColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: ESUNColors.divider,
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: ESUNColors.textSecondary),
          const SizedBox(width: ESUNSpacing.md),
          Text(
            label,
            style: ESUNTypography.bodyMedium.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: ESUNTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}



