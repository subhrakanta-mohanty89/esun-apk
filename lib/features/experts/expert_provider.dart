/// Expert Marketplace Providers
///
/// Riverpod providers for expert search, filtering, and pagination.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_service.dart';

// ============================================================================
// Data Models
// ============================================================================

/// Expert model from API
class Expert {
  final String id;
  final String name;
  final String? profileImageUrl;
  final String? bio;
  final List<String> specializations;
  final int experienceYears;
  final List<String> qualifications;
  final List<String> certifications;
  final List<String> languages;
  final double consultationFee;
  final String currency;
  final int sessionDurationMinutes;
  final bool freeConsultationAvailable;
  final String? city;
  final String? state;
  final String? country;
  final bool offersOnline;
  final bool offersInPerson;
  final double averageRating;
  final int totalReviews;
  final int totalConsultations;
  final bool isOnline;
  final bool isFeatured;
  final bool isVerified;
  final double? distanceKm;

  const Expert({
    required this.id,
    required this.name,
    this.profileImageUrl,
    this.bio,
    this.specializations = const [],
    this.experienceYears = 0,
    this.qualifications = const [],
    this.certifications = const [],
    this.languages = const [],
    this.consultationFee = 0,
    this.currency = 'INR',
    this.sessionDurationMinutes = 30,
    this.freeConsultationAvailable = false,
    this.city,
    this.state,
    this.country,
    this.offersOnline = true,
    this.offersInPerson = false,
    this.averageRating = 0,
    this.totalReviews = 0,
    this.totalConsultations = 0,
    this.isOnline = false,
    this.isFeatured = false,
    this.isVerified = false,
    this.distanceKm,
  });

  factory Expert.fromJson(Map<String, dynamic> json) {
    return Expert(
      id: json['id'] as String,
      name: json['name'] as String,
      profileImageUrl: json['profile_image_url'] as String?,
      bio: json['bio'] as String?,
      specializations: (json['specializations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      experienceYears: json['experience_years'] as int? ?? 0,
      qualifications: (json['qualifications'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      certifications: (json['certifications'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      languages: (json['languages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      consultationFee: (json['consultation_fee'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      sessionDurationMinutes: json['session_duration_minutes'] as int? ?? 30,
      freeConsultationAvailable: json['free_consultation_available'] as bool? ?? false,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      offersOnline: json['offers_online'] as bool? ?? true,
      offersInPerson: json['offers_in_person'] as bool? ?? false,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      totalConsultations: json['total_consultations'] as int? ?? 0,
      isOnline: json['is_online'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }

  String get initials => name
      .split(' ')
      .map((e) => e.isNotEmpty ? e[0] : '')
      .take(2)
      .join()
      .toUpperCase();

  String get locationString {
    if (city != null && state != null) {
      return '$city, $state';
    }
    return city ?? state ?? country ?? 'India';
  }

  String get primarySpecialization {
    if (specializations.isEmpty) return 'Financial Expert';
    return specializations.first
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1)}' 
            : '')
        .join(' ');
  }
}

/// Specialization category
class Specialization {
  final String key;
  final String label;

  const Specialization({required this.key, required this.label});

  factory Specialization.fromJson(Map<String, dynamic> json) {
    return Specialization(
      key: json['key'] as String,
      label: json['label'] as String,
    );
  }
}

/// Pagination info
class PaginationInfo {
  final int page;
  final int perPage;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const PaginationInfo({
    this.page = 1,
    this.perPage = 20,
    this.total = 0,
    this.totalPages = 0,
    this.hasNext = false,
    this.hasPrev = false,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 0,
      hasNext: json['has_next'] as bool? ?? false,
      hasPrev: json['has_prev'] as bool? ?? false,
    );
  }
}

// ============================================================================
// Filter State
// ============================================================================

/// Expert search/filter state
class ExpertFilterState {
  final String searchQuery;
  final List<String> specializations;
  final double? ratingMin;
  final double? ratingMax;
  final double? priceMin;
  final double? priceMax;
  final bool? isOnline;
  final bool? isVerified;
  final bool? offersOnline;
  final bool? offersInPerson;
  final String? city;
  final String? state;
  final double? userLat;
  final double? userLng;
  final double? distanceKm;
  final String sortBy;
  final String sortOrder;
  final int page;
  final int perPage;

  const ExpertFilterState({
    this.searchQuery = '',
    this.specializations = const [],
    this.ratingMin,
    this.ratingMax,
    this.priceMin,
    this.priceMax,
    this.isOnline,
    this.isVerified,
    this.offersOnline,
    this.offersInPerson,
    this.city,
    this.state,
    this.userLat,
    this.userLng,
    this.distanceKm,
    this.sortBy = 'rating',
    this.sortOrder = 'desc',
    this.page = 1,
    this.perPage = 20,
  });

  ExpertFilterState copyWith({
    String? searchQuery,
    List<String>? specializations,
    double? ratingMin,
    double? ratingMax,
    double? priceMin,
    double? priceMax,
    bool? isOnline,
    bool? isVerified,
    bool? offersOnline,
    bool? offersInPerson,
    String? city,
    String? state,
    double? userLat,
    double? userLng,
    double? distanceKm,
    String? sortBy,
    String? sortOrder,
    int? page,
    int? perPage,
    bool clearRatingMin = false,
    bool clearRatingMax = false,
    bool clearPriceMin = false,
    bool clearPriceMax = false,
    bool clearIsOnline = false,
    bool clearIsVerified = false,
    bool clearOffersOnline = false,
    bool clearOffersInPerson = false,
    bool clearCity = false,
    bool clearState = false,
    bool clearUserLat = false,
    bool clearUserLng = false,
    bool clearDistanceKm = false,
  }) {
    return ExpertFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      specializations: specializations ?? this.specializations,
      ratingMin: clearRatingMin ? null : (ratingMin ?? this.ratingMin),
      ratingMax: clearRatingMax ? null : (ratingMax ?? this.ratingMax),
      priceMin: clearPriceMin ? null : (priceMin ?? this.priceMin),
      priceMax: clearPriceMax ? null : (priceMax ?? this.priceMax),
      isOnline: clearIsOnline ? null : (isOnline ?? this.isOnline),
      isVerified: clearIsVerified ? null : (isVerified ?? this.isVerified),
      offersOnline: clearOffersOnline ? null : (offersOnline ?? this.offersOnline),
      offersInPerson: clearOffersInPerson ? null : (offersInPerson ?? this.offersInPerson),
      city: clearCity ? null : (city ?? this.city),
      state: clearState ? null : (state ?? this.state),
      userLat: clearUserLat ? null : (userLat ?? this.userLat),
      userLng: clearUserLng ? null : (userLng ?? this.userLng),
      distanceKm: clearDistanceKm ? null : (distanceKm ?? this.distanceKm),
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }

  /// Build query parameters for API call
  Map<String, String> toQueryParams() {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      'sort_by': sortBy,
      'sort_order': sortOrder,
    };

    if (searchQuery.isNotEmpty) {
      params['q'] = searchQuery;
    }
    if (specializations.isNotEmpty) {
      params['specialization'] = specializations.join(',');
    }
    if (ratingMin != null) {
      params['rating_min'] = ratingMin.toString();
    }
    if (ratingMax != null) {
      params['rating_max'] = ratingMax.toString();
    }
    if (priceMin != null) {
      params['price_min'] = priceMin.toString();
    }
    if (priceMax != null) {
      params['price_max'] = priceMax.toString();
    }
    if (isOnline == true) {
      params['is_online'] = 'true';
    }
    if (isVerified == true) {
      params['is_verified'] = 'true';
    }
    if (offersOnline == true) {
      params['offers_online'] = 'true';
    }
    if (offersInPerson == true) {
      params['offers_in_person'] = 'true';
    }
    if (city != null && city!.isNotEmpty) {
      params['city'] = city!;
    }
    if (state != null && state!.isNotEmpty) {
      params['state'] = state!;
    }
    if (userLat != null) {
      params['lat'] = userLat.toString();
    }
    if (userLng != null) {
      params['lng'] = userLng.toString();
    }
    if (distanceKm != null) {
      params['distance_km'] = distanceKm.toString();
    }

    return params;
  }

  /// Count active filters
  int get activeFilterCount {
    int count = 0;
    if (specializations.isNotEmpty) count++;
    if (ratingMin != null || ratingMax != null) count++;
    if (priceMin != null || priceMax != null) count++;
    if (isOnline == true) count++;
    if (isVerified == true) count++;
    if (offersOnline == true || offersInPerson == true) count++;
    if (city != null || state != null) count++;
    if (distanceKm != null) count++;
    return count;
  }

  /// Check if any filters are active
  bool get hasActiveFilters => activeFilterCount > 0 || searchQuery.isNotEmpty;

  /// Reset all filters
  ExpertFilterState reset() {
    return const ExpertFilterState();
  }
}

// ============================================================================
// Search Results State
// ============================================================================

class ExpertSearchState {
  final List<Expert> experts;
  final PaginationInfo pagination;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final ExpertFilterState filters;

  const ExpertSearchState({
    this.experts = const [],
    this.pagination = const PaginationInfo(),
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.filters = const ExpertFilterState(),
  });

  ExpertSearchState copyWith({
    List<Expert>? experts,
    PaginationInfo? pagination,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    ExpertFilterState? filters,
    bool clearError = false,
  }) {
    return ExpertSearchState(
      experts: experts ?? this.experts,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      filters: filters ?? this.filters,
    );
  }
}

// ============================================================================
// Providers
// ============================================================================

/// Expert search state notifier
class ExpertSearchNotifier extends StateNotifier<ExpertSearchState> {
  final ApiService _api;

  ExpertSearchNotifier(this._api) : super(const ExpertSearchState()) {
    // Initial load
    search();
  }

  /// Search experts with current filters
  Future<void> search({bool resetPage = true}) async {
    if (state.isLoading) return;

    final filters = resetPage 
        ? state.filters.copyWith(page: 1) 
        : state.filters;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      filters: filters,
    );

    try {
      final result = await _api.get<Map<String, dynamic>>(
        '${ApiConfig.apiPrefix}/experts/search',
        queryParameters: filters.toQueryParams(),
      );

      if (result.isError || result.data == null) {
        state = state.copyWith(
          isLoading: false,
          error: result.error?.message ?? 'Failed to load experts',
        );
        return;
      }

      final data = result.data!['data'] as Map<String, dynamic>;
      final expertsList = (data['experts'] as List<dynamic>)
          .map((e) => Expert.fromJson(e as Map<String, dynamic>))
          .toList();
      final pagination = PaginationInfo.fromJson(
          data['pagination'] as Map<String, dynamic>);

      state = state.copyWith(
        experts: expertsList,
        pagination: pagination,
        isLoading: false,
        filters: filters,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more experts (pagination)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.pagination.hasNext) return;

    state = state.copyWith(isLoadingMore: true);

    final nextPage = state.filters.page + 1;
    final filters = state.filters.copyWith(page: nextPage);

    try {
      final result = await _api.get<Map<String, dynamic>>(
        '${ApiConfig.apiPrefix}/experts/search',
        queryParameters: filters.toQueryParams(),
      );

      if (result.isError || result.data == null) {
        state = state.copyWith(isLoadingMore: false);
        return;
      }

      final data = result.data!['data'] as Map<String, dynamic>;
      final newExperts = (data['experts'] as List<dynamic>)
          .map((e) => Expert.fromJson(e as Map<String, dynamic>))
          .toList();
      final pagination = PaginationInfo.fromJson(
          data['pagination'] as Map<String, dynamic>);

      state = state.copyWith(
        experts: [...state.experts, ...newExperts],
        pagination: pagination,
        isLoadingMore: false,
        filters: filters,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Update search query
  void setSearchQuery(String query) {
    state = state.copyWith(
      filters: state.filters.copyWith(searchQuery: query, page: 1),
    );
  }

  /// Update filters
  void updateFilters(ExpertFilterState filters) {
    state = state.copyWith(filters: filters.copyWith(page: 1));
    search();
  }

  /// Set location filter
  void setLocation({String? city, String? locationState, double? lat, double? lng, double? distance}) {
    super.state = super.state.copyWith(
      filters: super.state.filters.copyWith(
        city: city,
        state: locationState,
        userLat: lat,
        userLng: lng,
        distanceKm: distance,
        page: 1,
      ),
    );
    search();
  }

  /// Clear location filter
  void clearLocation() {
    state = state.copyWith(
      filters: state.filters.copyWith(
        clearCity: true,
        clearState: true,
        clearUserLat: true,
        clearUserLng: true,
        clearDistanceKm: true,
        page: 1,
      ),
    );
    search();
  }

  /// Set sort option
  void setSort(String sortBy, {String sortOrder = 'desc'}) {
    state = state.copyWith(
      filters: state.filters.copyWith(sortBy: sortBy, sortOrder: sortOrder, page: 1),
    );
    search();
  }

  /// Reset all filters
  void resetFilters() {
    state = state.copyWith(filters: const ExpertFilterState());
    search();
  }
}

/// Expert search provider
final expertSearchProvider = StateNotifierProvider<ExpertSearchNotifier, ExpertSearchState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return ExpertSearchNotifier(api);
});

/// Featured experts provider
final featuredExpertsProvider = FutureProvider<List<Expert>>((ref) async {
  final api = ref.read(apiServiceProvider);
  
  final result = await api.get<Map<String, dynamic>>(
    '${ApiConfig.apiPrefix}/experts/featured',
    queryParameters: {'limit': '6'},
  );

  if (result.isError || result.data == null) {
    return [];
  }

  final data = result.data!['data'] as Map<String, dynamic>;
  return (data['experts'] as List<dynamic>)
      .map((e) => Expert.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Available specializations provider
final expertSpecializationsProvider = FutureProvider<List<Specialization>>((ref) async {
  final api = ref.read(apiServiceProvider);
  
  final result = await api.get<Map<String, dynamic>>(
    '${ApiConfig.apiPrefix}/experts/specializations',
  );

  if (result.isError || result.data == null) {
    // Return default specializations
    return const [
      Specialization(key: 'tax', label: 'Tax'),
      Specialization(key: 'investment', label: 'Investment'),
      Specialization(key: 'insurance', label: 'Insurance'),
      Specialization(key: 'loans', label: 'Loans'),
      Specialization(key: 'retirement', label: 'Retirement'),
      Specialization(key: 'mutual_funds', label: 'Mutual Funds'),
      Specialization(key: 'personal_finance', label: 'Personal Finance'),
      Specialization(key: 'legal', label: 'Legal'),
    ];
  }

  final data = result.data!['data'] as Map<String, dynamic>;
  return (data['specializations'] as List<dynamic>)
      .map((e) => Specialization.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Available cities provider
final expertCitiesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiServiceProvider);
  
  final result = await api.get<Map<String, dynamic>>(
    '${ApiConfig.apiPrefix}/experts/cities',
  );

  if (result.isError || result.data == null) {
    return [];
  }

  final data = result.data!['data'] as Map<String, dynamic>;
  return (data['cities'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList();
});
