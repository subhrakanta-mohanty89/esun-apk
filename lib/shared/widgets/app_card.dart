// Part of eSun Flutter App — design system
/// Flat card with subtle border — 16px radius, 16px padding, no heavy shadow.
library;


import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isDark ? ESUNColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? ESUNColors.darkDivider.withOpacity(0.3)
              : const Color(0xFFF1F5F9),
        ),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(ESUNSpacing.lg),
        child: child,
      ),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: card,
        ),
      );
    }

    return card;
  }
}
