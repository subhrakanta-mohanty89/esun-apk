/// ESUN Core Utilities
/// 
/// Common utilities and extensions used throughout the application.

library ESUN_utils;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ============================================================================
// Currency Configuration
// ============================================================================

/// Supported currencies with their configurations
enum SupportedCurrency {
  inr(
    code: 'INR',
    symbol: '₹',
    locale: 'en_IN',
    name: 'Indian Rupee',
    decimalDigits: 2,
    lakhs: true,
  ),
  usd(
    code: 'USD',
    symbol: '\$',
    locale: 'en_US',
    name: 'US Dollar',
    decimalDigits: 2,
    lakhs: false,
  ),
  eur(
    code: 'EUR',
    symbol: '€',
    locale: 'de_DE',
    name: 'Euro',
    decimalDigits: 2,
    lakhs: false,
  ),
  gbp(
    code: 'GBP',
    symbol: '£',
    locale: 'en_GB',
    name: 'British Pound',
    decimalDigits: 2,
    lakhs: false,
  ),
  aed(
    code: 'AED',
    symbol: 'د.إ',
    locale: 'ar_AE',
    name: 'UAE Dirham',
    decimalDigits: 2,
    lakhs: false,
  );

  const SupportedCurrency({
    required this.code,
    required this.symbol,
    required this.locale,
    required this.name,
    required this.decimalDigits,
    required this.lakhs,
  });

  final String code;
  final String symbol;
  final String locale;
  final String name;
  final int decimalDigits;
  final bool lakhs; // Use Indian Lakh/Crore system

  static SupportedCurrency fromCode(String code) {
    return SupportedCurrency.values.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => SupportedCurrency.inr, // Default to INR
    );
  }
}

/// Currency formatter service for locale-aware currency formatting
class CurrencyFormatter {
  static SupportedCurrency _currentCurrency = SupportedCurrency.inr;

  /// Set the current currency for the app
  static void setCurrency(SupportedCurrency currency) {
    _currentCurrency = currency;
  }

  /// Set currency by code
  static void setCurrencyByCode(String code) {
    _currentCurrency = SupportedCurrency.fromCode(code);
  }

  /// Get current currency
  static SupportedCurrency get currentCurrency => _currentCurrency;

  /// Get current currency symbol
  static String get symbol => _currentCurrency.symbol;

  /// Format amount with full precision
  static String format(
    num amount, {
    bool showSymbol = true,
    int? decimals,
    SupportedCurrency? currency,
  }) {
    final curr = currency ?? _currentCurrency;
    final formatter = NumberFormat.currency(
      locale: curr.locale,
      symbol: showSymbol ? curr.symbol : '',
      decimalDigits: decimals ?? curr.decimalDigits,
    );
    return formatter.format(amount);
  }

  /// Format amount without decimals
  static String formatWhole(
    num amount, {
    bool showSymbol = true,
    SupportedCurrency? currency,
  }) {
    return format(amount, showSymbol: showSymbol, decimals: 0, currency: currency);
  }

  /// Format amount in compact form (K, L, Cr, M, B)
  static String formatCompact(
    num amount, {
    bool showSymbol = true,
    SupportedCurrency? currency,
  }) {
    final curr = currency ?? _currentCurrency;
    final absValue = amount.abs();
    String suffix = '';
    double divisor = 1;

    if (curr.lakhs) {
      // Indian number system: Lakh, Crore
      if (absValue >= 10000000) {
        suffix = 'Cr';
        divisor = 10000000;
      } else if (absValue >= 100000) {
        suffix = 'L';
        divisor = 100000;
      } else if (absValue >= 1000) {
        suffix = 'K';
        divisor = 1000;
      }
    } else {
      // Western number system: K, M, B
      if (absValue >= 1000000000) {
        suffix = 'B';
        divisor = 1000000000;
      } else if (absValue >= 1000000) {
        suffix = 'M';
        divisor = 1000000;
      } else if (absValue >= 1000) {
        suffix = 'K';
        divisor = 1000;
      }
    }

    final formatted = (amount / divisor).toStringAsFixed(suffix.isEmpty ? 0 : 1);
    final prefix = showSymbol ? curr.symbol : '';
    return '$prefix$formatted$suffix'.trim();
  }

  /// Format for display in UI (no decimals, compact for large numbers)
  static String formatDisplay(
    num amount, {
    bool showSymbol = true,
    bool compact = true,
    SupportedCurrency? currency,
  }) {
    final absValue = amount.abs();
    if (compact && absValue >= 100000) {
      return formatCompact(amount, showSymbol: showSymbol, currency: currency);
    }
    return formatWhole(amount, showSymbol: showSymbol, currency: currency);
  }
}

/// Currency Formatter Extensions for numbers
extension CurrencyFormatterX on num {
  /// Format as currency using app's current currency setting
  String toCurrency({bool showSymbol = true, int? decimals}) {
    return CurrencyFormatter.format(this, showSymbol: showSymbol, decimals: decimals);
  }

  /// Format as Indian Rupees (legacy support)
  String toINR({bool showSymbol = true, int decimals = 2}) {
    return CurrencyFormatter.format(
      this,
      showSymbol: showSymbol,
      decimals: decimals,
      currency: SupportedCurrency.inr,
    );
  }
  
  /// Format as compact currency (1.2L, 3.5Cr for INR / 1.2M, 3.5B for USD)
  String toCompactCurrency({bool showSymbol = true}) {
    return CurrencyFormatter.formatCompact(this, showSymbol: showSymbol);
  }

  /// Format as compact INR (legacy support)
  String toCompactINR({bool showSymbol = true}) {
    return CurrencyFormatter.formatCompact(
      this,
      showSymbol: showSymbol,
      currency: SupportedCurrency.inr,
    );
  }
  
  /// Format for UI display
  String toDisplayCurrency({bool showSymbol = true, bool compact = true}) {
    return CurrencyFormatter.formatDisplay(
      this,
      showSymbol: showSymbol,
      compact: compact,
    );
  }
  
  /// Format as percentage
  String toPercentage({int decimals = 2, bool showSign = true}) {
    final sign = showSign && this > 0 ? '+' : '';
    return '$sign${toStringAsFixed(decimals)}%';
  }
}

/// Date Formatter Extensions
extension DateFormatter on DateTime {
  /// Format as readable date
  String toReadable() {
    return DateFormat('d MMM yyyy').format(this);
  }
  
  /// Format as short date
  String toShort() {
    return DateFormat('d/M/yy').format(this);
  }
  
  /// Format with time
  String toDateTime() {
    return DateFormat('d MMM yyyy, h:mm a').format(this);
  }
  
  /// Format as relative time (Today, Yesterday, etc.)
  String toRelative() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(year, month, day);
    
    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (date.isAfter(today.subtract(const Duration(days: 7)))) {
      return DateFormat('EEEE').format(this);
    }
    return toReadable();
  }
  
  /// Format time only
  String toTime() {
    return DateFormat('h:mm a').format(this);
  }
}

/// String Extensions
extension StringX on String {
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
  
  /// Convert to title case
  String get titleCase {
    return split(' ').map((word) => word.capitalize).join(' ');
  }
  
  /// Mask string (for sensitive data)
  String mask({int visibleChars = 4, String maskChar = '*'}) {
    if (length <= visibleChars) return maskChar * length;
    return '${maskChar * (length - visibleChars)}${substring(length - visibleChars)}';
  }
  
  /// Format as masked account number
  String get maskedAccount {
    if (length < 4) return this;
    return 'XXXX ${substring(length - 4)}';
  }
  
  /// Format as masked UPI ID
  String get maskedUPI {
    final parts = split('@');
    if (parts.length != 2) return this;
    final username = parts[0];
    if (username.length <= 4) return this;
    return '${username.substring(0, 2)}****@${parts[1]}';
  }
  
  /// Check if valid email
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }
  
  /// Check if valid phone
  bool get isValidPhone {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(this);
  }
  
  /// Check if valid PAN
  bool get isValidPAN {
    return RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(toUpperCase());
  }
  
  /// Check if valid Aadhaar
  bool get isValidAadhaar {
    return RegExp(r'^\d{12}$').hasMatch(this);
  }
  
  /// Check if valid IFSC
  bool get isValidIFSC {
    return RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(toUpperCase());
  }
}

/// Widget Extensions
extension WidgetX on Widget {
  /// Add padding
  Widget padAll(double padding) {
    return Padding(padding: EdgeInsets.all(padding), child: this);
  }
  
  /// Add horizontal padding
  Widget padH(double padding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: this,
    );
  }
  
  /// Add vertical padding
  Widget padV(double padding) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding),
      child: this,
    );
  }
  
  /// Add padding only
  Widget padOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
      ),
      child: this,
    );
  }
  
  /// Center widget
  Widget get centered => Center(child: this);
  
  /// Expand in Row/Column
  Widget get expanded => Expanded(child: this);
  
  /// Add sliver adapter
  Widget get sliver => SliverToBoxAdapter(child: this);
}

/// Context Extensions
extension ContextX on BuildContext {
  /// Get theme
  ThemeData get theme => Theme.of(this);
  
  /// Get color scheme
  ColorScheme get colorScheme => theme.colorScheme;
  
  /// Get text theme
  TextTheme get textTheme => theme.textTheme;
  
  /// Get media query
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  
  /// Get screen size
  Size get screenSize => mediaQuery.size;
  
  /// Get screen width
  double get screenWidth => screenSize.width;
  
  /// Get screen height
  double get screenHeight => screenSize.height;
  
  /// Get safe area padding
  EdgeInsets get safeArea => mediaQuery.padding;
  
  /// Check if dark mode
  bool get isDarkMode => theme.brightness == Brightness.dark;
  
  /// Check if tablet
  bool get isTablet => screenWidth >= 600;
  
  /// Check if landscape
  bool get isLandscape => screenWidth > screenHeight;
  
  /// Show snackbar
  void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        backgroundColor: isError ? colorScheme.error : null,
      ),
    );
  }
  
  /// Show loading dialog
  Future<void> showLoading({String? message}) {
    return showDialog(
      context: this,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 24),
            Text(message ?? 'Please wait...'),
          ],
        ),
      ),
    );
  }
}

/// List Extensions
extension ListX<T> on List<T> {
  /// Safe get at index
  T? safeGet(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
  
  /// Separate list with widget
  List<T> separatedBy(T separator) {
    if (isEmpty || length == 1) return this;
    final result = <T>[];
    for (var i = 0; i < length; i++) {
      result.add(this[i]);
      if (i < length - 1) result.add(separator);
    }
    return result;
  }
}

/// Duration Extensions
extension DurationX on Duration {
  /// Format as readable string
  String get readable {
    if (inDays > 0) return '${inDays}d ${inHours.remainder(24)}h';
    if (inHours > 0) return '${inHours}h ${inMinutes.remainder(60)}m';
    if (inMinutes > 0) return '${inMinutes}m ${inSeconds.remainder(60)}s';
    return '${inSeconds}s';
  }
}

/// Color Extensions
extension ColorX on Color {
  /// Darken color
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final darkened = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }
  
  /// Lighten color
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightened = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return lightened.toColor();
  }
}

/// Result type for async operations
sealed class Result<T> {
  const Result();
  
  bool get isSuccess => this is Success<T>;
  bool get isError => this is Error<T>;
  
  T? get data => isSuccess ? (this as Success<T>).data : null;
  AppException? get error => isError ? (this as Error<T>).exception : null;
  
  R when<R>({
    required R Function(T data) success,
    required R Function(AppException exception) error,
  }) {
    return switch (this) {
      Success(:final data) => success(data),
      Error(:final exception) => error(exception),
    };
  }
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Error<T> extends Result<T> {
  final AppException exception;
  const Error(this.exception);
}

/// App Exception
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;
  
  const AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });
  
  @override
  String toString() => 'AppException: $message (code: $code)';
  
  /// Predefined exceptions
  static const networkError = AppException(
    message: 'Network error. Please check your connection.',
    code: 'NETWORK_ERROR',
  );
  
  static const serverError = AppException(
    message: 'Server error. Please try again later.',
    code: 'SERVER_ERROR',
  );
  
  static const unauthorized = AppException(
    message: 'Session expired. Please login again.',
    code: 'UNAUTHORIZED',
  );
  
  static const badRequest = AppException(
    message: 'Invalid request. Please check your input.',
    code: 'BAD_REQUEST',
  );
  
  static const notFound = AppException(
    message: 'Resource not found.',
    code: 'NOT_FOUND',
  );
  
  static const timeout = AppException(
    message: 'Request timed out. Please try again.',
    code: 'TIMEOUT',
  );
  
  static const unknown = AppException(
    message: 'Something went wrong. Please try again.',
    code: 'UNKNOWN',
  );
}



