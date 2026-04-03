/// Expert Filter Sheet
///
/// Bottom sheet for filtering experts by specialization, rating, price,
/// availability, and location.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';
import '../../shared/widgets/widgets.dart';
import 'expert_provider.dart';

/// Show expert filter bottom sheet
Future<ExpertFilterState?> showExpertFilterSheet(
  BuildContext context, {
  required ExpertFilterState currentFilters,
}) async {
  return showModalBottomSheet<ExpertFilterState>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ExpertFilterSheet(currentFilters: currentFilters),
  );
}

class ExpertFilterSheet extends ConsumerStatefulWidget {
  final ExpertFilterState currentFilters;

  const ExpertFilterSheet({
    super.key,
    required this.currentFilters,
  });

  @override
  ConsumerState<ExpertFilterSheet> createState() => _ExpertFilterSheetState();
}

class _ExpertFilterSheetState extends ConsumerState<ExpertFilterSheet> {
  late ExpertFilterState _filters;
  final _cityController = TextEditingController();
  
  // Price range
  static const double _minPrice = 0;
  static const double _maxPrice = 2000;
  late RangeValues _priceRange;
  
  // Rating
  double _ratingMin = 0;

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
    _cityController.text = _filters.city ?? '';
    _priceRange = RangeValues(
      _filters.priceMin ?? _minPrice,
      _filters.priceMax ?? _maxPrice,
    );
    _ratingMin = _filters.ratingMin ?? 0;
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final specializationsAsync = ref.watch(expertSpecializationsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? ESUNColors.darkSurface : ESUNColors.surface,
        borderRadius: ESUNRadius.sheetRadius,
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: const BoxDecoration(
              color: ESUNColors.divider,
              borderRadius: ESUNRadius.fullRadius,
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            child: Row(
              children: [
                Text(
                  'Filter Experts',
                  style: ESUNTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Reset'),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          const FPDivider.subtle(),
          
          // Filter content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              children: [
                // Specialization
                _buildSectionHeader('Specialization'),
                const SizedBox(height: ESUNSpacing.sm),
                specializationsAsync.when(
                  data: (specs) => _buildSpecializationChips(specs),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => _buildSpecializationChips([]),
                ),
                const SizedBox(height: ESUNSpacing.xl),
                
                // Rating
                _buildSectionHeader('Minimum Rating'),
                const SizedBox(height: ESUNSpacing.sm),
                _buildRatingFilter(),
                const SizedBox(height: ESUNSpacing.xl),
                
                // Price Range
                _buildSectionHeader('Price Range'),
                const SizedBox(height: ESUNSpacing.sm),
                _buildPriceRangeFilter(),
                const SizedBox(height: ESUNSpacing.xl),
                
                // Availability
                _buildSectionHeader('Availability'),
                const SizedBox(height: ESUNSpacing.sm),
                _buildAvailabilityFilters(),
                const SizedBox(height: ESUNSpacing.xl),
                
                // Session Type
                _buildSectionHeader('Session Type'),
                const SizedBox(height: ESUNSpacing.sm),
                _buildSessionTypeFilters(),
                const SizedBox(height: ESUNSpacing.xl),
                
                // Location
                _buildSectionHeader('Location'),
                const SizedBox(height: ESUNSpacing.sm),
                _buildLocationFilter(),
                const SizedBox(height: ESUNSpacing.xl),
                
                // Sort
                _buildSectionHeader('Sort By'),
                const SizedBox(height: ESUNSpacing.sm),
                _buildSortOptions(),
                const SizedBox(height: ESUNSpacing.xxl),
              ],
            ),
          ),
          
          // Apply button
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? ESUNColors.darkSurface : ESUNColors.surface,
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
                Text(
                  '${_filters.activeFilterCount} filter${_filters.activeFilterCount != 1 ? 's' : ''} applied',
                  style: ESUNTypography.bodySmall.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
                const Spacer(),
                FPButton(
                  label: 'Apply Filters',
                  onPressed: _applyFilters,
                  size: FPButtonSize.medium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: ESUNTypography.titleSmall.copyWith(
        fontWeight: FontWeight.w600,
        color: ESUNColors.textSecondary,
      ),
    );
  }

  Widget _buildSpecializationChips(List<Specialization> specs) {
    final defaultSpecs = [
      const Specialization(key: 'tax', label: 'Tax'),
      const Specialization(key: 'investment', label: 'Investment'),
      const Specialization(key: 'insurance', label: 'Insurance'),
      const Specialization(key: 'loans', label: 'Loans'),
      const Specialization(key: 'retirement', label: 'Retirement'),
      const Specialization(key: 'mutual_funds', label: 'Mutual Funds'),
      const Specialization(key: 'personal_finance', label: 'Personal Finance'),
      const Specialization(key: 'legal', label: 'Legal'),
    ];

    final allSpecs = specs.isEmpty ? defaultSpecs : specs;

    return Wrap(
      spacing: ESUNSpacing.sm,
      runSpacing: ESUNSpacing.sm,
      children: allSpecs.map((spec) {
        final isSelected = _filters.specializations.contains(spec.key);
        return FilterChip(
          label: Text(spec.label),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _filters = _filters.copyWith(
                  specializations: [..._filters.specializations, spec.key],
                );
              } else {
                _filters = _filters.copyWith(
                  specializations: _filters.specializations
                      .where((s) => s != spec.key)
                      .toList(),
                );
              }
            });
          },
          backgroundColor: ESUNColors.surfaceVariant,
          selectedColor: ESUNColors.primary.withOpacity(0.2),
          checkmarkColor: ESUNColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? ESUNColors.primary : ESUNColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (int i = 1; i <= 5; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _ratingMin = i.toDouble();
                      _filters = _filters.copyWith(ratingMin: _ratingMin);
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.sm),
                    decoration: BoxDecoration(
                      color: i <= _ratingMin
                          ? ESUNColors.warning.withOpacity(0.1)
                          : ESUNColors.surfaceVariant,
                      borderRadius: ESUNRadius.smRadius,
                      border: Border.all(
                        color: i <= _ratingMin
                            ? ESUNColors.warning
                            : ESUNColors.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.star,
                          color: i <= _ratingMin
                              ? ESUNColors.warning
                              : ESUNColors.textTertiary,
                          size: 20,
                        ),
                        Text(
                          '$i+',
                          style: ESUNTypography.labelSmall.copyWith(
                            color: i <= _ratingMin
                                ? ESUNColors.warning
                                : ESUNColors.textTertiary,
                            fontWeight: i <= _ratingMin
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_ratingMin > 0) ...[
          const SizedBox(height: ESUNSpacing.sm),
          Text(
            'Show experts with ${_ratingMin.toInt()}+ stars',
            style: ESUNTypography.bodySmall.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceRangeFilter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '₹${_priceRange.start.toInt()}',
              style: ESUNTypography.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _priceRange.end >= _maxPrice 
                  ? '₹${_priceRange.end.toInt()}+' 
                  : '₹${_priceRange.end.toInt()}',
              style: ESUNTypography.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: ESUNSpacing.sm),
        RangeSlider(
          values: _priceRange,
          min: _minPrice,
          max: _maxPrice,
          divisions: 20,
          labels: RangeLabels(
            '₹${_priceRange.start.toInt()}',
            '₹${_priceRange.end.toInt()}',
          ),
          onChanged: (values) {
            setState(() {
              _priceRange = values;
              _filters = _filters.copyWith(
                priceMin: values.start > _minPrice ? values.start : null,
                priceMax: values.end < _maxPrice ? values.end : null,
                clearPriceMin: values.start <= _minPrice,
                clearPriceMax: values.end >= _maxPrice,
              );
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Min: ₹0',
              style: ESUNTypography.labelSmall.copyWith(
                color: ESUNColors.textTertiary,
              ),
            ),
            Text(
              'Max: ₹2000+',
              style: ESUNTypography.labelSmall.copyWith(
                color: ESUNColors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvailabilityFilters() {
    return Column(
      children: [
        _buildFilterSwitch(
          'Online Now',
          'Show only experts currently online',
          Icons.circle,
          _filters.isOnline == true,
          (value) {
            setState(() {
              _filters = _filters.copyWith(
                isOnline: value ? true : null,
                clearIsOnline: !value,
              );
            });
          },
          iconColor: ESUNColors.success,
        ),
        const SizedBox(height: ESUNSpacing.sm),
        _buildFilterSwitch(
          'Verified Only',
          'Show only verified experts',
          Icons.verified,
          _filters.isVerified == true,
          (value) {
            setState(() {
              _filters = _filters.copyWith(
                isVerified: value ? true : null,
                clearIsVerified: !value,
              );
            });
          },
          iconColor: ESUNColors.info,
        ),
      ],
    );
  }

  Widget _buildSessionTypeFilters() {
    return Row(
      children: [
        Expanded(
          child: _buildOptionCard(
            'Online',
            Icons.videocam_outlined,
            _filters.offersOnline == true,
            () {
              setState(() {
                _filters = _filters.copyWith(
                  offersOnline: _filters.offersOnline != true ? true : null,
                  clearOffersOnline: _filters.offersOnline == true,
                );
              });
            },
          ),
        ),
        const SizedBox(width: ESUNSpacing.md),
        Expanded(
          child: _buildOptionCard(
            'In-Person',
            Icons.person_outline,
            _filters.offersInPerson == true,
            () {
              setState(() {
                _filters = _filters.copyWith(
                  offersInPerson: _filters.offersInPerson != true ? true : null,
                  clearOffersInPerson: _filters.offersInPerson == true,
                );
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(ESUNSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? ESUNColors.primary.withOpacity(0.1)
              : ESUNColors.surfaceVariant,
          borderRadius: ESUNRadius.mdRadius,
          border: Border.all(
            color: isSelected ? ESUNColors.primary : ESUNColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? ESUNColors.primary : ESUNColors.textSecondary,
              size: 28,
            ),
            const SizedBox(height: ESUNSpacing.xs),
            Text(
              label,
              style: ESUNTypography.bodyMedium.copyWith(
                color: isSelected ? ESUNColors.primary : ESUNColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationFilter() {
    return Column(
      children: [
        // City input
        TextField(
          controller: _cityController,
          decoration: InputDecoration(
            hintText: 'Enter city name',
            prefixIcon: const Icon(Icons.location_city),
            suffixIcon: _cityController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _cityController.clear();
                      setState(() {
                        _filters = _filters.copyWith(clearCity: true);
                      });
                    },
                  )
                : null,
            border: const OutlineInputBorder(
              borderRadius: ESUNRadius.mdRadius,
            ),
          ),
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(
                city: value.isNotEmpty ? value : null,
                clearCity: value.isEmpty,
              );
            });
          },
        ),
        const SizedBox(height: ESUNSpacing.md),
        
        // Quick city selection
        Wrap(
          spacing: ESUNSpacing.sm,
          runSpacing: ESUNSpacing.sm,
          children: [
            'Mumbai',
            'Delhi',
            'Bangalore',
            'Hyderabad',
            'Chennai',
            'Pune',
          ].map((city) {
            final isSelected = _filters.city == city;
            return ActionChip(
              label: Text(city),
              onPressed: () {
                setState(() {
                  if (isSelected) {
                    _cityController.clear();
                    _filters = _filters.copyWith(clearCity: true);
                  } else {
                    _cityController.text = city;
                    _filters = _filters.copyWith(city: city);
                  }
                });
              },
              backgroundColor: isSelected
                  ? ESUNColors.primary.withOpacity(0.2)
                  : ESUNColors.surfaceVariant,
              labelStyle: TextStyle(
                color: isSelected ? ESUNColors.primary : ESUNColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        
        // Distance filter (when location is set)
        if (_filters.city != null && _filters.city!.isNotEmpty) ...[
          const SizedBox(height: ESUNSpacing.lg),
          Row(
            children: [
              const Icon(Icons.near_me, size: 18, color: ESUNColors.textSecondary),
              const SizedBox(width: ESUNSpacing.sm),
              Text(
                'Within ${_filters.distanceKm?.toInt() ?? 50} km',
                style: ESUNTypography.bodyMedium,
              ),
            ],
          ),
          Slider(
            value: _filters.distanceKm ?? 50,
            min: 5,
            max: 200,
            divisions: 39,
            label: '${(_filters.distanceKm ?? 50).toInt()} km',
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(distanceKm: value);
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSortOptions() {
    final sortOptions = [
      ('rating', 'Rating'),
      ('price', 'Price'),
      ('reviews', 'Reviews'),
      ('experience', 'Experience'),
      ('distance', 'Distance'),
    ];

    return Wrap(
      spacing: ESUNSpacing.sm,
      runSpacing: ESUNSpacing.sm,
      children: sortOptions.map((option) {
        final isSelected = _filters.sortBy == option.$1;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(option.$2),
              if (isSelected) ...[
                const SizedBox(width: 4),
                Icon(
                  _filters.sortOrder == 'desc'
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  size: 14,
                ),
              ],
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                // Toggle sort order if already selected
                if (_filters.sortBy == option.$1) {
                  _filters = _filters.copyWith(
                    sortOrder: _filters.sortOrder == 'desc' ? 'asc' : 'desc',
                  );
                } else {
                  _filters = _filters.copyWith(
                    sortBy: option.$1,
                    sortOrder: 'desc',
                  );
                }
              });
            }
          },
          backgroundColor: ESUNColors.surfaceVariant,
          selectedColor: ESUNColors.primary.withOpacity(0.2),
        );
      }).toList(),
    );
  }

  Widget _buildFilterSwitch(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged, {
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: const BoxDecoration(
        color: ESUNColors.surfaceVariant,
        borderRadius: ESUNRadius.mdRadius,
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? ESUNColors.primary, size: 20),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ESUNTypography.bodyMedium),
                Text(
                  subtitle,
                  style: ESUNTypography.bodySmall.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _filters = const ExpertFilterState();
      _cityController.clear();
      _priceRange = const RangeValues(_minPrice, _maxPrice);
      _ratingMin = 0;
    });
  }

  void _applyFilters() {
    Navigator.pop(context, _filters);
  }
}
