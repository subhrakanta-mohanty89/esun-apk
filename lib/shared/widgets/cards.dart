/// ESUN Cards
/// 
/// Reusable card components following the design system.

import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import 'smart_network_image.dart';

/// Base Card
class FPCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final FPCardVariant variant;
  final BorderRadiusGeometry? borderRadius;
  final Color? backgroundColor;
  final List<BoxShadow>? shadow;
  
  const FPCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.variant = FPCardVariant.outlined,
    this.borderRadius,
    this.backgroundColor,
    this.shadow,
  });
  
  const FPCard.elevated({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.backgroundColor,
    this.shadow,
  }) : variant = FPCardVariant.elevated;
  
  const FPCard.filled({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.backgroundColor,
    this.shadow,
  }) : variant = FPCardVariant.filled;
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final effectiveBorderRadius = borderRadius ?? ESUNRadius.cardRadius;
    final effectivePadding = padding ?? ESUNSpacing.cardInsets;
    
    Color bgColor;
    BoxBorder? border;
    List<BoxShadow> effectiveShadow;
    
    switch (variant) {
      case FPCardVariant.outlined:
        bgColor = backgroundColor ?? (isDark ? ESUNColors.darkSurface : ESUNColors.surface);
        border = Border.all(
          color: isDark ? ESUNColors.darkDivider.withOpacity(0.3) : ESUNColors.cardBorder,
          width: 1,
        );
        effectiveShadow = shadow ?? ESUNShadows.none;
        break;
      case FPCardVariant.elevated:
        bgColor = backgroundColor ?? (isDark ? ESUNColors.darkSurface : ESUNColors.surface);
        border = null;
        effectiveShadow = shadow ?? ESUNShadows.mid;
        break;
      case FPCardVariant.filled:
        bgColor = backgroundColor ?? (isDark ? ESUNColors.darkSurfaceVariant : ESUNColors.surfaceVariant);
        border = null;
        effectiveShadow = shadow ?? ESUNShadows.none;
        break;
    }
    
    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: effectiveBorderRadius,
        border: border,
        boxShadow: effectiveShadow,
      ),
      child: Padding(
        padding: effectivePadding,
        child: child,
      ),
    );
    
    if (onTap != null || onLongPress != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: effectiveBorderRadius as BorderRadius,
          child: card,
        ),
      );
    }
    
    return card;
  }
}

enum FPCardVariant {
  outlined,
  elevated,
  filled,
}

/// Info Card with icon
class FPInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  
  const FPInfoCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.iconBackgroundColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return FPCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBackgroundColor ?? colorScheme.primaryContainer,
              borderRadius: ESUNRadius.mdRadius,
            ),
            child: Icon(
              icon,
              color: iconColor ?? colorScheme.primary,
              size: ESUNIconSize.md,
            ),
          ),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: ESUNTypography.titleSmall,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: ESUNSpacing.xs),
                  Text(
                    subtitle!,
                    style: ESUNTypography.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Gradient Card - Modern glassmorphism style
class FPGradientCard extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BorderRadiusGeometry? borderRadius;
  final bool withGlassEffect;
  
  const FPGradientCard({
    super.key,
    required this.child,
    required this.gradient,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
    this.withGlassEffect = true,
  });
  
  const FPGradientCard.primary({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
    this.withGlassEffect = true,
  }) : gradient = ESUNColors.primaryGradient;
  
  const FPGradientCard.premium({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
    this.withGlassEffect = true,
  }) : gradient = ESUNColors.premiumGradient;
  
  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? ESUNRadius.cardRadius;
    final effectivePadding = padding ?? ESUNSpacing.cardInsets;
    
    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: effectiveBorderRadius,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E4A9A).withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
          const BoxShadow(
            color: Color(0x30000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Glassmorphism overlay patterns
          if (withGlassEffect) ...[
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
          ],
          // Content
          Padding(
            padding: effectivePadding,
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white),
              child: IconTheme(
                data: const IconThemeData(color: Colors.white),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
    
    // Clip the overflow from decorative circles
    card = ClipRRect(
      borderRadius: effectiveBorderRadius as BorderRadius,
      child: card,
    );
    
    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveBorderRadius,
          child: card,
        ),
      );
    }
    
    return card;
  }
}

/// Stat Card
class FPStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? change;
  final bool isPositive;
  final IconData? icon;
  final VoidCallback? onTap;
  
  const FPStatCard({
    super.key,
    required this.label,
    required this.value,
    this.change,
    this.isPositive = true,
    this.icon,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return FPCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: ESUNIconSize.sm,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: ESUNSpacing.xs),
              ],
              Expanded(
                child: Text(
                  label,
                  style: ESUNTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.sm),
          Text(
            value,
            style: ESUNTypography.amountMedium,
          ),
          if (change != null) ...[
            const SizedBox(height: ESUNSpacing.xs),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: ESUNIconSize.xs,
                  color: isPositive ? ESUNColors.success : ESUNColors.error,
                ),
                const SizedBox(width: ESUNSpacing.xs),
                Text(
                  change!,
                  style: ESUNTypography.labelSmall.copyWith(
                    color: isPositive ? ESUNColors.success : ESUNColors.error,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Balance Card
class FPBalanceCard extends StatelessWidget {
  final String title;
  final String amount;
  final String? subtitle;
  final VoidCallback? onTap;
  final List<Widget>? actions;
  
  const FPBalanceCard({
    super.key,
    required this.title,
    required this.amount,
    this.subtitle,
    this.onTap,
    this.actions,
  });
  
  @override
  Widget build(BuildContext context) {
    return FPGradientCard.premium(
      onTap: onTap,
      padding: const EdgeInsets.all(ESUNSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: ESUNTypography.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: ESUNSpacing.sm),
          Text(
            amount,
            style: ESUNTypography.amountLarge.copyWith(
              color: Colors.white,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: ESUNSpacing.xs),
            Text(
              subtitle!,
              style: ESUNTypography.caption.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: ESUNSpacing.lg),
            Row(
              children: actions!
                  .map((action) => Expanded(child: action))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Transaction Card
class FPTransactionCard extends StatelessWidget {
  final IconData? categoryIcon;
  final IconData? icon;
  final String title;
  final String subtitle;
  final String amount;
  final bool isExpense;
  final VoidCallback? onTap;
  final Color? categoryColor;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Color? amountColor;
  final String? logoUrl;
  
  const FPTransactionCard({
    super.key,
    this.categoryIcon,
    this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.isExpense = true,
    this.onTap,
    this.categoryColor,
    this.iconColor,
    this.iconBackgroundColor,
    this.amountColor,
    this.logoUrl,
  });
  
  // Static logo mapping for common merchants/companies
  static String? getLogoUrl(String merchantName) {
    final normalized = merchantName.toLowerCase().trim();
    if (_merchantLogos.containsKey(normalized)) {
      return _merchantLogos[normalized];
    }
    final match = _merchantLogos.entries.firstWhere(
      (e) => normalized.contains(e.key) || e.key.contains(normalized),
      orElse: () => const MapEntry('', ''),
    );
    return match.value.isNotEmpty ? match.value : null;
  }
  
  static final Map<String, String> _merchantLogos = {
    // Food & Dining
    'swiggy': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://swiggy.com&size=128',
    'zomato': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://zomato.com&size=128',
    'dominos': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://dominos.co.in&size=128',
    'mcdonalds': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://mcdonalds.com&size=128',
    'starbucks': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://starbucks.in&size=128',
    
    // Transport
    'ola': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://uber.com&size=128',
    'uber': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://uber.com&size=128',
    'rapido': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://rapido.bike&size=128',
    
    // Shopping
    'amazon': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://amazon.in&size=128',
    'flipkart': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://flipkart.com&size=128',
    'myntra': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://myntra.com&size=128',
    'boat': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://boat-lifestyle.com&size=128',
    'nykaa': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://nykaa.com&size=128',
    
    // Entertainment
    'netflix': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://netflix.com&size=128',
    'prime': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://primevideo.com&size=128',
    'hotstar': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://hotstar.com&size=128',
    'spotify': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://spotify.com&size=128',
    
    // Utilities & Payments
    'paytm': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://paytm.com&size=128',
    'phonepe': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://phonepe.com&size=128',
    'gpay': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://pay.google.com&size=128',
    'google pay': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://pay.google.com&size=128',
    
    // Grocery
    'bigbasket': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://bigbasket.com&size=128',
    'blinkit': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://blinkit.com&size=128',
    'zepto': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://zeptonow.com&size=128',
    'instamart': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://swiggy.com&size=128',
    
    // Fuel
    'hp petrol': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://hindustanpetroleum.com&size=128',
    'indian oil': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://iocl.com&size=128',
    'bharat petroleum': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://bharatpetroleum.in&size=128',
  };
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveIcon = icon ?? categoryIcon ?? Icons.receipt;
    final effectiveIconColor = iconColor ?? categoryColor ?? colorScheme.primary;
    final effectiveIconBgColor = iconBackgroundColor ?? effectiveIconColor.withOpacity(0.1);
    final effectiveAmountColor = amountColor ?? (isExpense ? ESUNColors.error : ESUNColors.success);
    final effectiveLogoUrl = logoUrl ?? getLogoUrl(title);
    
    return FPCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: ESUNSpacing.lg,
        vertical: ESUNSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: effectiveIconBgColor,
              borderRadius: ESUNRadius.smRadius,
            ),
            child: effectiveLogoUrl != null
                ? ClipRRect(
                    borderRadius: ESUNRadius.smRadius,
                    child: SmartNetworkImage(
                      imageUrl: effectiveLogoUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                      placeholderIcon: effectiveIcon,
                      placeholderColor: effectiveIconColor,
                      errorBuilder: (_, __, ___) => Icon(
                        effectiveIcon,
                        color: effectiveIconColor,
                        size: ESUNIconSize.sm,
                      ),
                    ),
                  )
                : Icon(
                    effectiveIcon,
                    color: effectiveIconColor,
                    size: ESUNIconSize.sm,
                  ),
          ),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: ESUNTypography.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: ESUNSpacing.xs),
                Text(
                  subtitle,
                  style: ESUNTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: ESUNSpacing.md),
          Text(
            amount,
            style: ESUNTypography.amountSmall.copyWith(
              color: effectiveAmountColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Account Card
class FPAccountCard extends StatelessWidget {
  final String bankName;
  final String accountNumber;
  final String balance;
  final String? accountType;
  final Widget? logo;
  final VoidCallback? onTap;
  
  const FPAccountCard({
    super.key,
    required this.bankName,
    required this.accountNumber,
    required this.balance,
    this.accountType,
    this.logo,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return FPCard.elevated(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (logo != null) ...[
                SizedBox(
                  width: 40,
                  height: 40,
                  child: logo,
                ),
                const SizedBox(width: ESUNSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bankName,
                      style: ESUNTypography.titleSmall,
                    ),
                    if (accountType != null)
                      Text(
                        accountType!,
                        style: ESUNTypography.caption,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.lg),
          Text(
            accountNumber,
            style: ESUNTypography.bodyMedium.copyWith(
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: ESUNSpacing.sm),
          Text(
            balance,
            style: ESUNTypography.amountMedium,
          ),
        ],
      ),
    );
  }
}

/// Subtle Divider - Modern, minimal separator
/// 
/// Replaces the default intrusive Divider with a softer, design-compliant separator.
class FPDivider extends StatelessWidget {
  final double? height;
  final double? thickness;
  final double? indent;
  final double? endIndent;
  final Color? color;
  final FPDividerVariant variant;
  
  const FPDivider({
    super.key,
    this.height,
    this.thickness,
    this.indent,
    this.endIndent,
    this.color,
    this.variant = FPDividerVariant.subtle,
  });
  
  const FPDivider.subtle({
    super.key,
    this.height,
    this.thickness,
    this.indent,
    this.endIndent,
    this.color,
  }) : variant = FPDividerVariant.subtle;
  
  const FPDivider.spaced({
    super.key,
    this.height,
    this.thickness,
    this.indent,
    this.endIndent,
    this.color,
  }) : variant = FPDividerVariant.spaced;
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color effectiveColor;
    double effectiveThickness;
    double effectiveHeight;
    
    switch (variant) {
      case FPDividerVariant.subtle:
        effectiveColor = color ?? (isDark 
          ? ESUNColors.darkDivider.withOpacity(0.4) 
          : ESUNColors.dividerSubtle);
        effectiveThickness = thickness ?? 1.0;
        effectiveHeight = height ?? 1.0;
        break;
      case FPDividerVariant.standard:
        effectiveColor = color ?? (isDark 
          ? ESUNColors.darkDivider 
          : ESUNColors.divider);
        effectiveThickness = thickness ?? 1.0;
        effectiveHeight = height ?? 1.0;
        break;
      case FPDividerVariant.spaced:
        effectiveColor = color ?? (isDark 
          ? ESUNColors.darkDivider.withOpacity(0.3) 
          : ESUNColors.dividerSubtle);
        effectiveThickness = thickness ?? 1.0;
        effectiveHeight = height ?? 24.0;
        break;
    }
    
    return Container(
      height: effectiveHeight,
      margin: EdgeInsets.only(
        left: indent ?? 0,
        right: endIndent ?? 0,
      ),
      child: Center(
        child: Container(
          height: effectiveThickness,
          color: effectiveColor,
        ),
      ),
    );
  }
}

enum FPDividerVariant {
  subtle,
  standard,
  spaced,
}

/// Icon Container - Consistent icon display with background
class FPIconContainer extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final double? size;
  final double? iconSize;
  final FPIconContainerVariant variant;
  
  const FPIconContainer({
    super.key,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.size,
    this.iconSize,
    this.variant = FPIconContainerVariant.rounded,
  });
  
  const FPIconContainer.circle({
    super.key,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.size,
    this.iconSize,
  }) : variant = FPIconContainerVariant.circle;
  
  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? ESUNColors.iconPrimary;
    final effectiveBackgroundColor = backgroundColor ?? effectiveIconColor.withOpacity(0.1);
    final effectiveSize = size ?? 40.0;
    final effectiveIconSize = iconSize ?? ESUNIconSize.md;
    
    return Container(
      width: effectiveSize,
      height: effectiveSize,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: variant == FPIconContainerVariant.rounded 
          ? ESUNRadius.smRadius 
          : null,
        shape: variant == FPIconContainerVariant.circle 
          ? BoxShape.circle 
          : BoxShape.rectangle,
      ),
      child: Center(
        child: Icon(
          icon,
          color: effectiveIconColor,
          size: effectiveIconSize,
        ),
      ),
    );
  }
}

enum FPIconContainerVariant {
  rounded,
  circle,
}



