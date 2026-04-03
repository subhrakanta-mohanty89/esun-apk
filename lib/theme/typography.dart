/// ESUN Typography System
/// 
/// Type scale based on Material Design 3 with custom refinements
/// for optimal readability in financial applications.
library;

import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Typography Scale
abstract class ESUNTypography {
  static const String fontFamily = 'Inter';
  
  // Display Styles - Hero sections, large numbers
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
    color: ESUNColors.textPrimary,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
    color: ESUNColors.textPrimary,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
    color: ESUNColors.textPrimary,
  );
  
  // Headline Styles - Page titles, section headers
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.25,
    color: ESUNColors.textPrimary,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.29,
    color: ESUNColors.textPrimary,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
    color: ESUNColors.textPrimary,
  );
  
  // Title Styles - Card titles, list headers
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.27,
    color: ESUNColors.textPrimary,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.5,
    color: ESUNColors.textPrimary,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
    color: ESUNColors.textPrimary,
  );
  
  // Body Styles - Primary content
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
    color: ESUNColors.textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
    color: ESUNColors.textPrimary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: ESUNColors.textSecondary,
  );
  
  // Label Styles - Buttons, chips, form labels
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
    color: ESUNColors.textPrimary,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.33,
    color: ESUNColors.textPrimary,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.45,
    color: ESUNColors.textSecondary,
  );
  
  // Caption Style
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: ESUNColors.textTertiary,
  );
  
  // Overline Style
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    height: 1.6,
    color: ESUNColors.textSecondary,
  );
  
  // Button Style
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.43,
  );
  
  // Financial Number Styles - For amounts, percentages
  static const TextStyle amountLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
    color: ESUNColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  
  static const TextStyle amountMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.25,
    color: ESUNColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  
  static const TextStyle amountSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
    color: ESUNColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  
  static const TextStyle percentage = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

/// Text Theme for Material Theme
TextTheme createTextTheme({bool isDark = false}) {
  final Color textColor = isDark 
      ? ESUNColors.darkTextPrimary 
      : ESUNColors.textPrimary;
  final Color secondaryTextColor = isDark 
      ? ESUNColors.darkTextSecondary 
      : ESUNColors.textSecondary;
  
  return TextTheme(
    displayLarge: ESUNTypography.displayLarge.copyWith(color: textColor),
    displayMedium: ESUNTypography.displayMedium.copyWith(color: textColor),
    displaySmall: ESUNTypography.displaySmall.copyWith(color: textColor),
    headlineLarge: ESUNTypography.headlineLarge.copyWith(color: textColor),
    headlineMedium: ESUNTypography.headlineMedium.copyWith(color: textColor),
    headlineSmall: ESUNTypography.headlineSmall.copyWith(color: textColor),
    titleLarge: ESUNTypography.titleLarge.copyWith(color: textColor),
    titleMedium: ESUNTypography.titleMedium.copyWith(color: textColor),
    titleSmall: ESUNTypography.titleSmall.copyWith(color: textColor),
    bodyLarge: ESUNTypography.bodyLarge.copyWith(color: textColor),
    bodyMedium: ESUNTypography.bodyMedium.copyWith(color: textColor),
    bodySmall: ESUNTypography.bodySmall.copyWith(color: secondaryTextColor),
    labelLarge: ESUNTypography.labelLarge.copyWith(color: textColor),
    labelMedium: ESUNTypography.labelMedium.copyWith(color: textColor),
    labelSmall: ESUNTypography.labelSmall.copyWith(color: secondaryTextColor),
  );
}



