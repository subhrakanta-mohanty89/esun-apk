/// ESUN Buttons
/// 
/// Reusable button components following the design system.

import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Primary filled button
class FPButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;
  final FPButtonVariant variant;
  final FPButtonSize size;
  
  const FPButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = false,
    this.icon,
    this.variant = FPButtonVariant.primary,
    this.size = FPButtonSize.medium,
  });
  
  const FPButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = false,
    this.icon,
    this.size = FPButtonSize.medium,
  }) : variant = FPButtonVariant.primary;
  
  const FPButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = false,
    this.icon,
    this.size = FPButtonSize.medium,
  }) : variant = FPButtonVariant.secondary;
  
  const FPButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = false,
    this.icon,
    this.size = FPButtonSize.medium,
  }) : variant = FPButtonVariant.outline;
  
  const FPButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = false,
    this.icon,
    this.size = FPButtonSize.medium,
  }) : variant = FPButtonVariant.text;
  
  const FPButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = false,
    this.icon,
    this.size = FPButtonSize.medium,
  }) : variant = FPButtonVariant.danger;
  
  @override
  Widget build(BuildContext context) {
    final child = _buildChild(context);
    
    final button = switch (variant) {
      FPButtonVariant.primary => FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: _getStyle(context),
          child: child,
        ),
      FPButtonVariant.secondary => FilledButton.tonal(
          onPressed: isLoading ? null : onPressed,
          style: _getStyle(context),
          child: child,
        ),
      FPButtonVariant.outline => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: _getStyle(context),
          child: child,
        ),
      FPButtonVariant.text => TextButton(
          onPressed: isLoading ? null : onPressed,
          style: _getStyle(context),
          child: child,
        ),
      FPButtonVariant.danger => FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: _getDangerStyle(context),
          child: child,
        ),
    };
    
    if (isExpanded) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }
    
    return button;
  }
  
  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: _getLoaderSize(),
        height: _getLoaderSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(
            variant == FPButtonVariant.primary || variant == FPButtonVariant.danger
                ? Colors.white
                : Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _getIconSize()),
          const SizedBox(width: ESUNSpacing.sm),
          Text(label),
        ],
      );
    }
    
    return Text(label);
  }
  
  ButtonStyle _getStyle(BuildContext context) {
    return ButtonStyle(
      minimumSize: WidgetStatePropertyAll(_getMinSize()),
      padding: WidgetStatePropertyAll(_getPadding()),
      textStyle: WidgetStatePropertyAll(_getTextStyle()),
    );
  }
  
  ButtonStyle _getDangerStyle(BuildContext context) {
    return ButtonStyle(
      minimumSize: WidgetStatePropertyAll(_getMinSize()),
      padding: WidgetStatePropertyAll(_getPadding()),
      textStyle: WidgetStatePropertyAll(_getTextStyle()),
      backgroundColor: WidgetStatePropertyAll(ESUNColors.error),
      foregroundColor: WidgetStatePropertyAll(ESUNColors.onError),
    );
  }
  
  Size _getMinSize() {
    return switch (size) {
      FPButtonSize.small => const Size(64, 36),
      FPButtonSize.medium => const Size(88, 44),
      FPButtonSize.large => const Size(96, 52),
    };
  }
  
  EdgeInsets _getPadding() {
    return switch (size) {
      FPButtonSize.small => const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      FPButtonSize.medium => const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      FPButtonSize.large => const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    };
  }
  
  TextStyle _getTextStyle() {
    return switch (size) {
      FPButtonSize.small => ESUNTypography.labelMedium,
      FPButtonSize.medium => ESUNTypography.labelLarge,
      FPButtonSize.large => ESUNTypography.titleSmall,
    };
  }
  
  double _getIconSize() {
    return switch (size) {
      FPButtonSize.small => 16,
      FPButtonSize.medium => 20,
      FPButtonSize.large => 24,
    };
  }
  
  double _getLoaderSize() {
    return switch (size) {
      FPButtonSize.small => 16,
      FPButtonSize.medium => 20,
      FPButtonSize.large => 24,
    };
  }
}

enum FPButtonVariant {
  primary,
  secondary,
  outline,
  text,
  danger,
}

enum FPButtonSize {
  small,
  medium,
  large,
}

/// Icon Button
class FPIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final FPIconButtonVariant variant;
  final double size;
  final Color? color;
  final Color? backgroundColor;
  
  const FPIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.variant = FPIconButtonVariant.standard,
    this.size = 24,
    this.color,
    this.backgroundColor,
  });
  
  const FPIconButton.filled({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = 24,
    this.color,
    this.backgroundColor,
  }) : variant = FPIconButtonVariant.filled;
  
  const FPIconButton.outlined({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = 24,
    this.color,
    this.backgroundColor,
  }) : variant = FPIconButtonVariant.outlined;
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    Widget button = switch (variant) {
      FPIconButtonVariant.standard => IconButton(
          icon: Icon(icon, size: size),
          onPressed: onPressed,
          color: color ?? colorScheme.onSurface,
          tooltip: tooltip,
        ),
      FPIconButtonVariant.filled => IconButton.filled(
          icon: Icon(icon, size: size),
          onPressed: onPressed,
          color: color ?? colorScheme.onPrimary,
          style: IconButton.styleFrom(
            backgroundColor: backgroundColor ?? colorScheme.primary,
          ),
          tooltip: tooltip,
        ),
      FPIconButtonVariant.outlined => IconButton.outlined(
          icon: Icon(icon, size: size),
          onPressed: onPressed,
          color: color ?? colorScheme.primary,
          tooltip: tooltip,
        ),
      FPIconButtonVariant.tonal => IconButton.filledTonal(
          icon: Icon(icon, size: size),
          onPressed: onPressed,
          color: color ?? colorScheme.onSecondaryContainer,
          tooltip: tooltip,
        ),
    };
    
    return button;
  }
}

enum FPIconButtonVariant {
  standard,
  filled,
  outlined,
  tonal,
}

/// Quick Action Button (for dashboard) - Modern style
class FPQuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final Color? backgroundColor;
  final Gradient? gradient;
  
  const FPQuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.iconColor,
    this.backgroundColor,
    this.gradient,
  });
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: ESUNRadius.mdRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: gradient ?? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (backgroundColor ?? colorScheme.primary).withOpacity(0.1),
                      (backgroundColor ?? colorScheme.primary).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: ESUNRadius.lgRadius,
                  border: Border.all(
                    color: (iconColor ?? colorScheme.primary).withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (iconColor ?? colorScheme.primary).withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: ESUNIconSize.md,
                  color: iconColor ?? colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: ESUNTypography.labelSmall.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating Action Button
class FPFloatingButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final bool extended;
  
  const FPFloatingButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.label,
    this.extended = false,
  });
  
  @override
  Widget build(BuildContext context) {
    if (extended && label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label!),
      );
    }
    
    return FloatingActionButton(
      onPressed: onPressed,
      child: Icon(icon),
    );
  }
}



