/// ESUN Cache-First Data Layer
///
/// Pattern: render → fetch → update (like Instagram/PhonePe)
/// 1. Return cached data INSTANTLY from Hive
/// 2. Trigger background API refresh
/// 3. Update UI when fresh data arrives
/// 4. On error, keep showing cached data (graceful degradation)

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Cache entry with metadata
class CacheEntry {
  final String data;
  final DateTime cachedAt;
  final String? etag;

  CacheEntry({required this.data, required this.cachedAt, this.etag});

  bool isStale(Duration maxAge) =>
      DateTime.now().difference(cachedAt) > maxAge;

  Map<String, dynamic> toJson() => {
        'data': data,
        'cachedAt': cachedAt.toIso8601String(),
        'etag': etag,
      };

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
        data: json['data'] as String,
        cachedAt: DateTime.parse(json['cachedAt'] as String),
        etag: json['etag'] as String?,
      );
}

/// Persistent cache using Hive
class HiveCache {
  static const String _boxName = 'esun_data_cache';
  static Box? _box;

  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  static Box get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError('HiveCache not initialized. Call HiveCache.init() first.');
    }
    return _box!;
  }

  /// Get cached entry
  static CacheEntry? get(String key) {
    try {
      final raw = box.get(key) as String?;
      if (raw == null) return null;
      return CacheEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[Cache] Error reading key=$key: $e');
      return null;
    }
  }

  /// Store cache entry
  static Future<void> put(String key, dynamic data, {String? etag}) async {
    try {
      final entry = CacheEntry(
        data: jsonEncode(data),
        cachedAt: DateTime.now(),
        etag: etag,
      );
      await box.put(key, jsonEncode(entry.toJson()));
    } catch (e) {
      debugPrint('[Cache] Error writing key=$key: $e');
    }
  }

  /// Delete specific key
  static Future<void> delete(String key) async {
    await box.delete(key);
  }

  /// Delete keys matching prefix
  static Future<void> invalidatePrefix(String prefix) async {
    final keys = box.keys.where((k) => k.toString().startsWith(prefix));
    for (final key in keys) {
      await box.delete(key);
    }
  }

  /// Clear all cache
  static Future<void> clearAll() async {
    await box.clear();
  }
}

/// State for cache-first data
class CacheFirstState<T> {
  final T? data;
  final bool isRefreshing;
  final bool isFromCache;
  final String? error;
  final DateTime? lastUpdated;

  const CacheFirstState({
    this.data,
    this.isRefreshing = false,
    this.isFromCache = false,
    this.error,
    this.lastUpdated,
  });

  bool get hasData => data != null;
  bool get isLoading => !hasData && isRefreshing;

  CacheFirstState<T> copyWith({
    T? data,
    bool? isRefreshing,
    bool? isFromCache,
    String? error,
    DateTime? lastUpdated,
  }) {
    return CacheFirstState<T>(
      data: data ?? this.data,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isFromCache: isFromCache ?? this.isFromCache,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Base class for cache-first notifiers
///
/// Usage:
/// ```dart
/// class SummaryNotifier extends CacheFirstNotifier<FinancialSummary> {
///   @override
///   String get cacheKey => 'cfo_summary';
///
///   @override
///   Duration get staleAfter => const Duration(minutes: 5);
///
///   @override
///   Future<FinancialSummary> fetchFromApi() async {
///     final response = await dio.get('/api/v1/cfo/summary');
///     return FinancialSummary.fromJson(response.data['data']);
///   }
///
///   @override
///   FinancialSummary parseFromCache(String json) {
///     return FinancialSummary.fromJson(jsonDecode(json));
///   }
/// }
/// ```
abstract class CacheFirstNotifier<T>
    extends StateNotifier<CacheFirstState<T>> {
  CacheFirstNotifier() : super(const CacheFirstState()) {
    _loadCachedThenRefresh();
  }

  /// Unique key for this data in Hive
  String get cacheKey;

  /// How long before cached data is considered stale
  Duration get staleAfter => const Duration(minutes: 5);

  /// Fetch fresh data from API
  Future<T> fetchFromApi();

  /// Parse cached JSON string into T
  T parseFromCache(String json);

  /// Convert T to JSON-encodable for caching
  dynamic toJson(T data) => data;

  /// Load from cache first, then refresh if stale
  Future<void> _loadCachedThenRefresh() async {
    // Step 1: Load cached data instantly
    final cached = HiveCache.get(cacheKey);
    if (cached != null) {
      try {
        final data = parseFromCache(cached.data);
        state = state.copyWith(
          data: data,
          isFromCache: true,
          lastUpdated: cached.cachedAt,
        );
      } catch (e) {
        debugPrint('[CacheFirst] Parse error for $cacheKey: $e');
      }
    }

    // Step 2: Background refresh if stale or no cache
    if (cached == null || cached.isStale(staleAfter)) {
      await refresh();
    }
  }

  /// Force refresh from API
  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true);
    try {
      final data = await fetchFromApi();
      await HiveCache.put(cacheKey, toJson(data));
      state = CacheFirstState<T>(
        data: data,
        isRefreshing: false,
        isFromCache: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      // Keep showing cached data on error (graceful degradation)
      state = state.copyWith(
        isRefreshing: false,
        error: state.hasData ? null : e.toString(),
      );
      if (state.hasData) {
        debugPrint('[CacheFirst] Refresh failed for $cacheKey, showing cached: $e');
      }
    }
  }

  /// Invalidate cache and refresh
  Future<void> invalidateAndRefresh() async {
    await HiveCache.delete(cacheKey);
    await refresh();
  }
}
