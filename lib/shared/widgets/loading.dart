/// ESUN Loading States
/// 
/// Skeleton loaders, shimmer effects, and loading indicators.

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/theme.dart';

/// Shimmer Loading Effect
class FPShimmer extends StatelessWidget {
  final Widget child;
  final bool enabled;
  
  const FPShimmer({
    super.key,
    required this.child,
    this.enabled = true,
  });
  
  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? ESUNColors.darkSurfaceVariant : ESUNColors.surfaceVariant,
      highlightColor: isDark 
          ? ESUNColors.darkSurface 
          : Colors.white,
      child: child,
    );
  }
}

/// Skeleton Box
class FPSkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  
  const FPSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? ESUNColors.darkSurfaceVariant : ESUNColors.surfaceVariant,
        borderRadius: borderRadius ?? ESUNRadius.smRadius,
      ),
    );
  }
}

/// Skeleton Line (for text)
class FPSkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  
  const FPSkeletonLine({
    super.key,
    this.width = double.infinity,
    this.height = 16,
  });
  
  @override
  Widget build(BuildContext context) {
    return FPSkeletonBox(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(height / 2),
    );
  }
}

/// Skeleton Circle
class FPSkeletonCircle extends StatelessWidget {
  final double size;
  
  const FPSkeletonCircle({
    super.key,
    required this.size,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? ESUNColors.darkSurfaceVariant : ESUNColors.surfaceVariant,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Card Skeleton
class FPCardSkeleton extends StatelessWidget {
  final double height;
  
  const FPCardSkeleton({
    super.key,
    this.height = 120,
  });
  
  @override
  Widget build(BuildContext context) {
    return FPShimmer(
      child: FPSkeletonBox(
        height: height,
        borderRadius: ESUNRadius.cardRadius,
      ),
    );
  }
}

/// List Item Skeleton
class FPListItemSkeleton extends StatelessWidget {
  final bool showAvatar;
  final int lines;
  
  const FPListItemSkeleton({
    super.key,
    this.showAvatar = true,
    this.lines = 2,
  });
  
  @override
  Widget build(BuildContext context) {
    return FPShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ESUNSpacing.lg,
          vertical: ESUNSpacing.md,
        ),
        child: Row(
          children: [
            if (showAvatar) ...[
              const FPSkeletonCircle(size: 48),
              const SizedBox(width: ESUNSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FPSkeletonLine(width: 150, height: 14),
                  if (lines > 1) ...[
                    const SizedBox(height: ESUNSpacing.sm),
                    FPSkeletonLine(
                      width: lines > 2 ? double.infinity : 100,
                      height: 12,
                    ),
                  ],
                  if (lines > 2) ...[
                    const SizedBox(height: ESUNSpacing.sm),
                    const FPSkeletonLine(width: 80, height: 12),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Transaction Skeleton
class FPTransactionSkeleton extends StatelessWidget {
  const FPTransactionSkeleton({super.key});
  
  @override
  Widget build(BuildContext context) {
    return FPShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ESUNSpacing.lg,
          vertical: ESUNSpacing.md,
        ),
        child: Row(
          children: [
            FPSkeletonBox(
              width: 44,
              height: 44,
              borderRadius: ESUNRadius.smRadius,
            ),
            const SizedBox(width: ESUNSpacing.md),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FPSkeletonLine(width: 120, height: 14),
                  SizedBox(height: ESUNSpacing.xs),
                  FPSkeletonLine(width: 80, height: 12),
                ],
              ),
            ),
            const SizedBox(width: ESUNSpacing.md),
            const FPSkeletonLine(width: 70, height: 16),
          ],
        ),
      ),
    );
  }
}

/// Balance Card Skeleton
class FPBalanceCardSkeleton extends StatelessWidget {
  const FPBalanceCardSkeleton({super.key});
  
  @override
  Widget build(BuildContext context) {
    return FPShimmer(
      child: Container(
        padding: const EdgeInsets.all(ESUNSpacing.xl),
        decoration: BoxDecoration(
          color: ESUNColors.surfaceVariant,
          borderRadius: ESUNRadius.cardRadius,
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FPSkeletonLine(width: 100, height: 14),
            SizedBox(height: ESUNSpacing.md),
            FPSkeletonLine(width: 180, height: 32),
            SizedBox(height: ESUNSpacing.sm),
            FPSkeletonLine(width: 120, height: 12),
          ],
        ),
      ),
    );
  }
}

/// Stats Row Skeleton
class FPStatsRowSkeleton extends StatelessWidget {
  final int count;
  
  const FPStatsRowSkeleton({
    super.key,
    this.count = 3,
  });
  
  @override
  Widget build(BuildContext context) {
    return FPShimmer(
      child: Row(
        children: List.generate(count, (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: index < count - 1 ? ESUNSpacing.md : 0,
              ),
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              decoration: BoxDecoration(
                color: ESUNColors.surfaceVariant,
                borderRadius: ESUNRadius.cardRadius,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FPSkeletonLine(width: 60, height: 12),
                  SizedBox(height: ESUNSpacing.sm),
                  FPSkeletonLine(width: 80, height: 20),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Chart Skeleton
class FPChartSkeleton extends StatelessWidget {
  final double height;
  
  const FPChartSkeleton({
    super.key,
    this.height = 200,
  });
  
  @override
  Widget build(BuildContext context) {
    return FPShimmer(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: ESUNColors.surfaceVariant,
          borderRadius: ESUNRadius.cardRadius,
        ),
      ),
    );
  }
}

/// Loading Overlay
class FPLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  
  const FPLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black38,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(ESUNSpacing.xxl),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: ESUNRadius.lgRadius,
                    boxShadow: ESUNShadows.modal,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (message != null) ...[
                        const SizedBox(height: ESUNSpacing.lg),
                        Text(
                          message!,
                          style: ESUNTypography.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Pull to Refresh Indicator
class FPRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  
  const FPRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });
  
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: child,
    );
  }
}

/// Loading Indicator
class FPLoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;
  
  const FPLoadingIndicator({
    super.key,
    this.size = 24,
    this.strokeWidth = 2.5,
    this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation(
          color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Full Page Loading
class FPPageLoading extends StatelessWidget {
  final String? message;
  
  const FPPageLoading({
    super.key,
    this.message,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FPLoadingIndicator(size: 48, strokeWidth: 3),
          if (message != null) ...[
            const SizedBox(height: ESUNSpacing.lg),
            Text(
              message!,
              style: ESUNTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}



