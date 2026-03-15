/// ESUN Cards
/// 
/// Reusable card components following the design system.

import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Base Card
class FPCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
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
    
    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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
    'swiggy': 'https://upload.wikimedia.org/wikipedia/en/thumb/1/12/Swiggy_logo.svg/200px-Swiggy_logo.svg.png',
    'zomato': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/75/Zomato_logo.png/200px-Zomato_logo.png',
    'dominos': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Domino%27s_pizza_logo.svg/200px-Domino%27s_pizza_logo.svg.png',
    'mcdonalds': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/McDonald%27s_Golden_Arches.svg/200px-McDonald%27s_Golden_Arches.svg.png',
    'starbucks': 'https://upload.wikimedia.org/wikipedia/en/thumb/d/d3/Starbucks_Corporation_Logo_2011.svg/200px-Starbucks_Corporation_Logo_2011.svg.png',
    
    // Transport
    'ola': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Ola_Cabs_logo.svg/200px-Ola_Cabs_logo.svg.png',
    'uber': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/58/Uber_logo_2018.svg/200px-Uber_logo_2018.svg.png',
    'rapido': 'https://play-lh.googleusercontent.com/P0Ofljgq8j7bkb3BOwpg6JT7Xv4K4XKkVxwk5B4fWYQDp5hRD7nh1hTyQMG6oD7aeJBY',
    
    // Shopping
    'amazon': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a9/Amazon_logo.svg/200px-Amazon_logo.svg.png',
    'flipkart': 'https://upload.wikimedia.org/wikipedia/en/thumb/7/7e/Flipkart_logo.svg/200px-Flipkart_logo.svg.png',
    'myntra': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a9/Myntra_logo.png/200px-Myntra_logo.png',
    'boat': 'https://upload.wikimedia.org/wikipedia/commons/1/1a/BoAt_Logo.svg',
    'nykaa': 'https://companieslogo.com/img/orig/NYKAA.NS-4e6d3f9c.png',
    
    // Entertainment
    'netflix': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/08/Netflix_2015_logo.svg/200px-Netflix_2015_logo.svg.png',
    'prime': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/11/Amazon_Prime_Video_logo.svg/200px-Amazon_Prime_Video_logo.svg.png',
    'hotstar': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/Disney%2B_Hotstar_2024_Logo.svg/200px-Disney%2B_Hotstar_2024_Logo.svg.png',
    'spotify': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/19/Spotify_logo_without_text.svg/200px-Spotify_logo_without_text.svg.png',
    
    // Utilities & Payments
    'paytm': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/42/Paytm_logo.png/200px-Paytm_logo.png',
    'phonepe': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/71/PhonePe_Logo.svg/200px-PhonePe_Logo.svg.png',
    'gpay': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f2/Google_Pay_Logo.svg/200px-Google_Pay_Logo.svg.png',
    'google pay': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f2/Google_Pay_Logo.svg/200px-Google_Pay_Logo.svg.png',
    
    // Grocery
    'bigbasket': 'https://upload.wikimedia.org/wikipedia/en/thumb/9/9f/BigBasket_Logo.svg/200px-BigBasket_Logo.svg.png',
    'blinkit': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2b/Blinkit-yellow-logo.svg/200px-Blinkit-yellow-logo.svg.png',
    'zepto': 'https://zepto.co.in/images/zepto-logo.png',
    'instamart': 'https://upload.wikimedia.org/wikipedia/en/thumb/1/12/Swiggy_logo.svg/200px-Swiggy_logo.svg.png',
    
    // Fuel
    'hp petrol': 'https://upload.wikimedia.org/wikipedia/en/thumb/7/7d/Hindustan_Petroleum_Logo.svg/200px-Hindustan_Petroleum_Logo.svg.png',
    'indian oil': 'https://upload.wikimedia.org/wikipedia/en/thumb/6/62/Indian_Oil_Logo.svg/200px-Indian_Oil_Logo.svg.png',
    'bharat petroleum': 'https://upload.wikimedia.org/wikipedia/en/thumb/3/3c/BPCL_logo.svg/200px-BPCL_logo.svg.png',
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
                    child: Image.network(
                      effectiveLogoUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        effectiveIcon,
                        color: effectiveIconColor,
                        size: ESUNIconSize.sm,
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Icon(
                          effectiveIcon,
                          color: effectiveIconColor.withOpacity(0.5),
                          size: ESUNIconSize.sm,
                        );
                      },
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



