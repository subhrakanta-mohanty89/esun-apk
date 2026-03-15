/// ESUN Theme System
/// 
/// Complete Material 3 theme implementation with light and dark modes.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'design_tokens.dart';
import 'typography.dart';

/// Main Theme Provider
class ESUNTheme {
  const ESUNTheme._();
  
  /// Light Theme
  static ThemeData get light {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: ESUNColors.primary,
      onPrimary: ESUNColors.onPrimary,
      primaryContainer: ESUNColors.primary100,
      onPrimaryContainer: ESUNColors.primary900,
      secondary: ESUNColors.secondary,
      onSecondary: ESUNColors.onSecondary,
      secondaryContainer: ESUNColors.secondaryLight.withOpacity(0.3),
      onSecondaryContainer: ESUNColors.secondaryDark,
      tertiary: ESUNColors.accent,
      onTertiary: ESUNColors.onAccent,
      tertiaryContainer: ESUNColors.accentLight.withOpacity(0.3),
      onTertiaryContainer: ESUNColors.accentDark,
      error: ESUNColors.error,
      onError: ESUNColors.onError,
      errorContainer: ESUNColors.errorSurface,
      onErrorContainer: ESUNColors.error,
      surface: ESUNColors.surface,
      onSurface: ESUNColors.onSurface,
      surfaceContainerHighest: ESUNColors.surfaceVariant,
      onSurfaceVariant: ESUNColors.onSurfaceVariant,
      outline: ESUNColors.border,
      outlineVariant: ESUNColors.divider,
      shadow: Colors.black,
      scrim: ESUNColors.scrim,
      inverseSurface: ESUNColors.darkSurface,
      onInverseSurface: ESUNColors.darkTextPrimary,
      inversePrimary: ESUNColors.primary200,
    );
    
    return _buildTheme(
      colorScheme: colorScheme,
      isDark: false,
    );
  }
  
  /// Dark Theme
  static ThemeData get dark {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: ESUNColors.primary300,
      onPrimary: ESUNColors.primary900,
      primaryContainer: ESUNColors.primary700,
      onPrimaryContainer: ESUNColors.primary100,
      secondary: ESUNColors.secondaryLight,
      onSecondary: ESUNColors.secondaryDark,
      secondaryContainer: ESUNColors.secondary.withOpacity(0.3),
      onSecondaryContainer: ESUNColors.secondaryLight,
      tertiary: ESUNColors.accentLight,
      onTertiary: ESUNColors.accentDark,
      tertiaryContainer: ESUNColors.accent.withOpacity(0.3),
      onTertiaryContainer: ESUNColors.accentLight,
      error: ESUNColors.errorLight,
      onError: Color(0xFF601410),
      errorContainer: Color(0xFF8C1D18),
      onErrorContainer: ESUNColors.errorLight,
      surface: ESUNColors.darkSurface,
      onSurface: ESUNColors.darkTextPrimary,
      surfaceContainerHighest: ESUNColors.darkSurfaceVariant,
      onSurfaceVariant: ESUNColors.darkTextSecondary,
      outline: ESUNColors.darkDivider,
      outlineVariant: ESUNColors.darkDivider.withOpacity(0.5),
      shadow: Colors.black,
      scrim: ESUNColors.scrim,
      inverseSurface: ESUNColors.surface,
      onInverseSurface: ESUNColors.textPrimary,
      inversePrimary: ESUNColors.primary700,
    );
    
    return _buildTheme(
      colorScheme: colorScheme,
      isDark: true,
    );
  }
  
  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    final textTheme = createTextTheme(isDark: isDark);
    final backgroundColor = isDark 
        ? ESUNColors.darkBackground 
        : ESUNColors.background;
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: backgroundColor,
      brightness: isDark ? Brightness.dark : Brightness.light,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        backgroundColor: isDark 
            ? ESUNColors.darkSurface 
            : ESUNColors.surface,
        foregroundColor: isDark 
            ? ESUNColors.darkTextPrimary 
            : ESUNColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge,
        toolbarHeight: 64,
        iconTheme: IconThemeData(
          color: isDark 
              ? ESUNColors.darkTextPrimary 
              : ESUNColors.textPrimary,
          size: ESUNIconSize.md,
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark 
            ? ESUNColors.darkSurface 
            : ESUNColors.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: isDark 
            ? ESUNColors.darkTextTertiary 
            : ESUNColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: ESUNTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: ESUNTypography.labelSmall,
      ),
      
      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: isDark 
            ? ESUNColors.darkSurface 
            : ESUNColors.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ESUNTypography.labelSmall.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return ESUNTypography.labelSmall.copyWith(
            color: isDark 
                ? ESUNColors.darkTextTertiary 
                : ESUNColors.textTertiary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: colorScheme.primary,
              size: ESUNIconSize.md,
            );
          }
          return IconThemeData(
            color: isDark 
                ? ESUNColors.darkTextTertiary 
                : ESUNColors.textTertiary,
            size: ESUNIconSize.md,
          );
        }),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: ESUNRadius.cardRadius,
          side: BorderSide(
            color: isDark 
                ? ESUNColors.darkDivider.withOpacity(0.2) 
                : ESUNColors.cardBorder,
            width: 1,
          ),
        ),
        color: isDark 
            ? ESUNColors.darkSurface 
            : ESUNColors.cardBackground,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: ESUNSpacing.buttonInsets,
          minimumSize: const Size(88, ESUNTouchTarget.minimum),
          shape: RoundedRectangleBorder(
            borderRadius: ESUNRadius.buttonRadius,
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: ESUNColors.disabledSurface,
          disabledForegroundColor: ESUNColors.disabled,
          textStyle: ESUNTypography.button,
        ),
      ),
      
      // Filled Button Theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: ESUNSpacing.buttonInsets,
          minimumSize: const Size(88, ESUNTouchTarget.minimum),
          shape: RoundedRectangleBorder(
            borderRadius: ESUNRadius.buttonRadius,
          ),
          textStyle: ESUNTypography.button,
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: ESUNSpacing.buttonInsets,
          minimumSize: const Size(88, ESUNTouchTarget.minimum),
          shape: RoundedRectangleBorder(
            borderRadius: ESUNRadius.buttonRadius,
          ),
          side: BorderSide(
            color: colorScheme.outline,
            width: 1,
          ),
          foregroundColor: colorScheme.primary,
          textStyle: ESUNTypography.button,
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: ESUNSpacing.buttonInsets,
          minimumSize: const Size(88, ESUNTouchTarget.minimum),
          shape: RoundedRectangleBorder(
            borderRadius: ESUNRadius.buttonRadius,
          ),
          foregroundColor: colorScheme.primary,
          textStyle: ESUNTypography.button,
        ),
      ),
      
      // Icon Button Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(
            ESUNTouchTarget.minimum,
            ESUNTouchTarget.minimum,
          ),
          padding: const EdgeInsets.all(ESUNSpacing.sm),
        ),
      ),
      
      // FAB Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: ESUNRadius.lgRadius,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark 
            ? ESUNColors.darkSurfaceVariant.withOpacity(0.5)
            : ESUNColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ESUNSpacing.lg,
          vertical: ESUNSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: ESUNRadius.inputRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: ESUNRadius.inputRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: ESUNRadius.inputRadius,
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: ESUNRadius.inputRadius,
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: ESUNRadius.inputRadius,
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2,
          ),
        ),
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: isDark 
              ? ESUNColors.darkTextTertiary 
              : ESUNColors.textTertiary,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.error,
        ),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: isDark 
            ? ESUNColors.darkSurfaceVariant 
            : ESUNColors.surfaceVariant,
        selectedColor: colorScheme.primaryContainer,
        disabledColor: ESUNColors.disabledSurface,
        labelStyle: ESUNTypography.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: ESUNSpacing.sm,
          vertical: ESUNSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: ESUNRadius.chipRadius,
        ),
        side: BorderSide.none,
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: isDark 
            ? ESUNColors.darkSurface 
            : ESUNColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: ESUNRadius.xlRadius,
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      
      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark 
            ? ESUNColors.darkSurface 
            : ESUNColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: ESUNRadius.sheetRadius,
        ),
        dragHandleColor: isDark 
            ? ESUNColors.darkDivider 
            : ESUNColors.divider,
        dragHandleSize: const Size(32, 4),
        showDragHandle: true,
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark 
            ? ESUNColors.darkTextPrimary 
            : ESUNColors.textPrimary,
        contentTextStyle: ESUNTypography.bodyMedium.copyWith(
          color: isDark 
              ? ESUNColors.textPrimary 
              : ESUNColors.textInverse,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: ESUNRadius.smRadius,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
      
      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: isDark 
            ? ESUNColors.darkTextTertiary 
            : ESUNColors.textTertiary,
        labelStyle: ESUNTypography.labelLarge,
        unselectedLabelStyle: ESUNTypography.labelLarge,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 3,
          ),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(3),
          ),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: isDark ? ESUNColors.darkDivider : ESUNColors.divider,
        thickness: 1,
        space: 1,
      ),
      
      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ESUNSpacing.lg,
          vertical: ESUNSpacing.xs,
        ),
        minVerticalPadding: ESUNSpacing.sm,
        shape: RoundedRectangleBorder(
          borderRadius: ESUNRadius.smRadius,
        ),
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodySmall,
        leadingAndTrailingTextStyle: textTheme.labelMedium,
        iconColor: isDark 
            ? ESUNColors.darkTextSecondary 
            : ESUNColors.textSecondary,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return isDark 
              ? ESUNColors.darkTextTertiary 
              : ESUNColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return isDark 
              ? ESUNColors.darkSurfaceVariant 
              : ESUNColors.surfaceVariant;
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: BorderSide(
          color: isDark 
              ? ESUNColors.darkDivider 
              : ESUNColors.border,
          width: 2,
        ),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return isDark 
              ? ESUNColors.darkDivider 
              : ESUNColors.border;
        }),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: isDark 
            ? ESUNColors.darkSurfaceVariant 
            : ESUNColors.surfaceVariant,
        circularTrackColor: isDark 
            ? ESUNColors.darkSurfaceVariant 
            : ESUNColors.surfaceVariant,
      ),
      
      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: isDark 
            ? ESUNColors.darkSurfaceVariant 
            : ESUNColors.surfaceVariant,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withOpacity(0.12),
        valueIndicatorColor: colorScheme.primary,
        valueIndicatorTextStyle: ESUNTypography.labelMedium.copyWith(
          color: colorScheme.onPrimary,
        ),
      ),
      
      // Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark 
              ? ESUNColors.darkTextPrimary 
              : ESUNColors.textPrimary,
          borderRadius: ESUNRadius.smRadius,
        ),
        textStyle: ESUNTypography.bodySmall.copyWith(
          color: isDark 
              ? ESUNColors.textPrimary 
              : ESUNColors.textInverse,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: ESUNSpacing.sm,
          vertical: ESUNSpacing.xs,
        ),
      ),
      
      // Page Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      
      // Visual Density
      visualDensity: VisualDensity.standard,
      
      // Splash/Ripple
      splashFactory: InkSparkle.splashFactory,
    );
  }
}



