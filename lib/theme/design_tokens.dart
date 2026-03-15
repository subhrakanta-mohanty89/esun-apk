/// ESUN Design Tokens
/// 
/// This file contains all design tokens for the ESUN application.
/// Modern fintech-inspired design with vibrant gradients and glassmorphism.

library ESUN_design_tokens;

import 'package:flutter/material.dart';

/// Primary Royal Blue Palette - Corporate Fintech Style
/// Clean, professional blue theme
abstract class ESUNColors {
  // Primary Royal Blue Scale
  static const Color primary50 = Color(0xFFE8EBF5);
  static const Color primary100 = Color(0xFFC5CCE8);
  static const Color primary200 = Color(0xFF9EAADA);
  static const Color primary300 = Color(0xFF7788CC);
  static const Color primary400 = Color(0xFF4A62B8);
  static const Color primary500 = Color(0xFF2E4A9A);
  static const Color primary600 = Color(0xFF283F87);
  static const Color primary700 = Color(0xFF223474);
  static const Color primary800 = Color(0xFF1C2961);
  static const Color primary900 = Color(0xFF131D4D);
  
  // Primary Main Colors - Royal Blue
  static const Color primary = Color(0xFF2E4A9A);
  static const Color primaryLight = Color(0xFF4A62B8);
  static const Color primaryDark = Color(0xFF223474);
  static const Color onPrimary = Color(0xFFFFFFFF);
  
  // Secondary - Electric Cyan for highlights
  static const Color secondary = Color(0xFF06B6D4);
  static const Color secondaryLight = Color(0xFF22D3EE);
  static const Color secondaryDark = Color(0xFF0891B2);
  static const Color onSecondary = Color(0xFFFFFFFF);
  
  // Accent - Vibrant Emerald for positive actions
  static const Color accent = Color(0xFF10B981);
  static const Color accentLight = Color(0xFF34D399);
  static const Color accentDark = Color(0xFF059669);
  static const Color onAccent = Color(0xFFFFFFFF);
  
  // Surface Colors - Clean whites with subtle blue tints
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F7FA);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF0F172A);
  static const Color onSurfaceVariant = Color(0xFF475569);
  
  // Background Colors - ESUN Blue theme
  static const Color background = Color(0xFFF5F7FB);
  static const Color backgroundElevated = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF0F172A);
  
  // Semantic Colors - Success (Emerald)
  static const Color success = Color(0xFF10B981);
  static const Color success100 = Color(0xFFD1FAE5);
  static const Color successLight = Color(0xFF6EE7B7);
  static const Color successSurface = Color(0xFFD1FAE5);
  static const Color onSuccess = Color(0xFFFFFFFF);
  
  // Semantic Colors - Warning (Amber)
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFCD34D);
  static const Color warningSurface = Color(0xFFFEF3C7);
  static const Color onWarning = Color(0xFF000000);
  
  // Semantic Colors - Error (Rose)
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFCA5A5);
  static const Color errorSurface = Color(0xFFFEE2E2);
  static const Color onError = Color(0xFFFFFFFF);
  
  // Semantic Colors - Info (Sky Blue)
  static const Color info = Color(0xFF0EA5E9);
  static const Color infoLight = Color(0xFF7DD3FC);
  static const Color infoSurface = Color(0xFFE0F2FE);
  static const Color onInfo = Color(0xFFFFFFFF);
  
  // Neutral Colors - Gray scale for UI elements
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral300 = Color(0xFFD4D4D4);
  static const Color neutral400 = Color(0xFFA3A3A3);
  static const Color neutral500 = Color(0xFF737373);
  static const Color neutral600 = Color(0xFF525252);
  static const Color neutral700 = Color(0xFF404040);
  static const Color neutral800 = Color(0xFF262626);
  static const Color neutral900 = Color(0xFF171717);
  
  // Dividers and Borders - Subtle separators
  static const Color divider = Color(0xFFE2E8F0);
  static const Color dividerDark = Color(0xFF3D4A5C);
  static const Color dividerSubtle = Color(0xFFF0F4F8);
  static const Color border = Color(0xFFCBD5E1);
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color disabled = Color(0xFF94A3B8);
  static const Color disabledSurface = Color(0xFFF1F5F9);
  
  // Icon Colors - Professional blue for better visibility
  static const Color iconPrimary = Color(0xFF2E4A9A);
  static const Color iconSecondary = Color(0xFF4A62B8);
  static const Color iconAccent = Color(0xFF06B6D4);
  static const Color iconSuccess = Color(0xFF10B981);
  static const Color iconWarning = Color(0xFFF59E0B);
  static const Color iconError = Color(0xFFEF4444);
  static const Color iconMuted = Color(0xFF64748B);
  static const Color iconOnDark = Color(0xFFFFFFFF);
  
  // Text Colors - High contrast
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFFCBD5E1);
  static const Color textInverse = Color(0xFFFFFFFF);
  
  // Chart Colors - Modern blue-based palette
  static const Color chart1 = Color(0xFF2E4A9A); // Royal Blue
  static const Color chart2 = Color(0xFF06B6D4); // Cyan
  static const Color chart3 = Color(0xFFF59E0B); // Amber
  static const Color chart4 = Color(0xFFEC4899); // Pink
  static const Color chart5 = Color(0xFF10B981); // Emerald
  static const Color chart6 = Color(0xFF4A62B8); // Light Blue
  
  // Modern Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E4A9A), Color(0xFF4A62B8)],
  );
  
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E4A9A), Color(0xFF223474), Color(0xFF4A62B8)],
  );
  
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );
  
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFCD34D), Color(0xFFF59E0B)],
  );
  
  // Glassmorphism gradients
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x40FFFFFF), Color(0x10FFFFFF)],
  );
  
  static const LinearGradient darkGlassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x20FFFFFF), Color(0x05FFFFFF)],
  );
  
  // Hero card gradients
  static const LinearGradient heroCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E4A9A), Color(0xFF4A62B8)],
  );
  
  static const LinearGradient neonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00D9F5), Color(0xFF2E4A9A)],
  );
  
  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B6B), Color(0xFFFFA07A)],
  );
  
  // Scrim & Overlay
  static const Color scrim = Color(0x52000000);
  static const Color overlay = Color(0x0A000000);
  static const Color overlayDark = Color(0x1A000000);
  static const Color glassOverlay = Color(0x30FFFFFF);
  
  // Card Colors - Modern elevated feel
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color cardShadow = Color(0x1A2E4A9A);
  
  // Dark Theme Colors - Rich dark mode
  static const Color darkBackground = Color(0xFF0F1423);
  static const Color darkSurface = Color(0xFF1A1F2E);
  static const Color darkSurfaceVariant = Color(0xFF252A3A);
  static const Color darkDivider = Color(0xFF3D4A5C);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFA1ABC7);
  static const Color darkTextTertiary = Color(0xFF6B758D);
}

/// Spacing Scale - Based on 4px grid
abstract class ESUNSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;
  static const double massive = 48.0;
  static const double gigantic = 64.0;
  
  // Page Padding
  static const double pagePadding = 16.0;
  static const double pageMargin = 24.0;
  
  // Component Spacing
  static const double sectionGap = 24.0;
  static const double cardPadding = 16.0;
  static const double listItemSpacing = 12.0;
  static const double iconTextGap = 8.0;
  
  // Insets
  static const EdgeInsets pageInsets = EdgeInsets.all(16.0);
  static const EdgeInsets cardInsets = EdgeInsets.all(16.0);
  static const EdgeInsets listInsets = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets buttonInsets = EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0);
}

/// Border Radius Scale
abstract class ESUNRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;
  
  // Pre-built BorderRadius
  static const BorderRadius xsRadius = BorderRadius.all(Radius.circular(4.0));
  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(8.0));
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(16.0));
  static const BorderRadius xlRadius = BorderRadius.all(Radius.circular(24.0));
  static const BorderRadius fullRadius = BorderRadius.all(Radius.circular(999.0));
  
  // Card Radius
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(16.0));
  static const BorderRadius chipRadius = BorderRadius.all(Radius.circular(8.0));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius inputRadius = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius sheetRadius = BorderRadius.vertical(top: Radius.circular(24.0));
}

/// Shadow Elevations - Modern colored shadows
abstract class ESUNShadows {
  static const List<BoxShadow> none = [];
  
  // Subtle shadow for cards
  static const List<BoxShadow> low = [
    BoxShadow(
      color: Color(0x086366F1),
      blurRadius: 8,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x05000000),
      blurRadius: 4,
      offset: Offset(0, 1),
      spreadRadius: 0,
    ),
  ];
  
  // Medium shadow for elevated components
  static const List<BoxShadow> mid = [
    BoxShadow(
      color: Color(0x146366F1),
      blurRadius: 16,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 6,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
  
  // High shadow for floating elements
  static const List<BoxShadow> high = [
    BoxShadow(
      color: Color(0x1A6366F1),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 12,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
  ];
  
  // Modal shadow
  static const List<BoxShadow> modal = [
    BoxShadow(
      color: Color(0x286366F1),
      blurRadius: 48,
      offset: Offset(0, 16),
      spreadRadius: -8,
    ),
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      offset: Offset(0, 8),
      spreadRadius: -4,
    ),
  ];
  
  // Colored shadows for elevated cards
  static List<BoxShadow> primaryShadow = [
    BoxShadow(
      color: ESUNColors.primary.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];
  
  static List<BoxShadow> successShadow = [
    BoxShadow(
      color: ESUNColors.success.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];
}

/// Animation Durations & Curves
abstract class ESUNAnimations {
  // Durations
  static const Duration instant = Duration(milliseconds: 50);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration slower = Duration(milliseconds: 500);
  
  // Standard curves
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeInOut = Curves.easeInOut;
  
  // Physics-based curves
  static const Curve spring = Curves.elasticOut;
  static const Curve bounce = Curves.bounceOut;
  static const Curve decelerate = Curves.decelerate;
  
  // Custom Material curves
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve standard = Cubic(0.2, 0.0, 0.0, 1.0);

  // Page transition
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Curve pageTransitionCurve = Curves.easeInOutCubic;
}

/// Icon Sizes
abstract class ESUNIconSize {
  static const double xs = 16.0;
  static const double sm = 20.0;
  static const double md = 24.0;
  static const double lg = 28.0;
  static const double xl = 32.0;
  static const double xxl = 40.0;
  static const double huge = 48.0;
  static const double illustration = 80.0;
}

/// Touch Targets - Accessibility compliant (minimum 44x44)
abstract class ESUNTouchTarget {
  static const double minimum = 44.0;
  static const double comfortable = 48.0;
  static const double large = 56.0;
}

/// Breakpoints for responsive design
abstract class ESUNBreakpoints {
  static const double mobile = 0;
  static const double tablet = 600;
  static const double desktop = 1024;
  static const double wide = 1440;
}



