/// ESUN State Widgets
/// 
/// Empty states, error states, and placeholder components.
library;

import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import 'buttons.dart';

/// Empty State
class FPEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  
  const FPEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  });
  
  // Common empty states
  const FPEmptyState.noData({
    super.key,
    this.title = 'No Data',
    this.description = 'There\'s nothing here yet.',
    this.actionLabel,
    this.onAction,
  }) : icon = Icons.inbox_outlined;
  
  const FPEmptyState.noTransactions({
    super.key,
    this.title = 'No Transactions',
    this.description = 'Your transactions will appear here.',
    this.actionLabel,
    this.onAction,
  }) : icon = Icons.receipt_long_outlined;
  
  const FPEmptyState.noResults({
    super.key,
    this.title = 'No Results',
    this.description = 'Try adjusting your search or filters.',
    this.actionLabel,
    this.onAction,
  }) : icon = Icons.search_off_outlined;
  
  const FPEmptyState.noConnection({
    super.key,
    this.title = 'No Connection',
    this.description = 'Check your internet connection and try again.',
    this.actionLabel = 'Retry',
    this.onAction,
  }) : icon = Icons.wifi_off_outlined;
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: ESUNIconSize.huge,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          Text(
            title,
            style: ESUNTypography.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (description != null) ...[
            const SizedBox(height: ESUNSpacing.sm),
            Text(
              description!,
              style: ESUNTypography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: ESUNSpacing.lg),
            FPButton.primary(
              label: actionLabel!,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

/// Error State
class FPErrorState extends StatelessWidget {
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onRetry;
  final IconData? icon;
  
  const FPErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.description,
    this.actionLabel = 'Try Again',
    this.onRetry,
    this.icon,
  });
  
  const FPErrorState.network({
    super.key,
    this.title = 'Connection Error',
    this.description = 'Please check your internet connection and try again.',
    this.actionLabel = 'Retry',
    this.onRetry,
  }) : icon = Icons.wifi_off_outlined;
  
  const FPErrorState.server({
    super.key,
    this.title = 'Server Error',
    this.description = 'We\'re having trouble connecting. Please try again later.',
    this.actionLabel = 'Retry',
    this.onRetry,
  }) : icon = Icons.cloud_off_outlined;
  
  const FPErrorState.notFound({
    super.key,
    this.title = 'Not Found',
    this.description = 'The content you\'re looking for doesn\'t exist.',
    this.actionLabel = 'Go Back',
    this.onRetry,
  }) : icon = Icons.error_outline;
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: ESUNColors.errorSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon ?? Icons.error_outline,
              size: ESUNIconSize.huge,
              color: ESUNColors.error,
            ),
          ),
          const SizedBox(height: ESUNSpacing.xxl),
          Text(
            title,
            style: ESUNTypography.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (description != null) ...[
            const SizedBox(height: ESUNSpacing.sm),
            Text(
              description!,
              style: ESUNTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onRetry != null) ...[
            const SizedBox(height: ESUNSpacing.xxl),
            FPButton.primary(
              label: actionLabel!,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

/// Success State
class FPSuccessState extends StatelessWidget {
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  
  const FPSuccessState({
    super.key,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: ESUNColors.successSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: ESUNIconSize.huge,
              color: ESUNColors.success,
            ),
          ),
          const SizedBox(height: ESUNSpacing.xxl),
          Text(
            title,
            style: ESUNTypography.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (description != null) ...[
            const SizedBox(height: ESUNSpacing.sm),
            Text(
              description!,
              style: ESUNTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: ESUNSpacing.xxl),
            FPButton.primary(
              label: actionLabel!,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

/// Permission Required State
class FPPermissionState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onRequest;
  
  const FPPermissionState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel = 'Grant Permission',
    required this.onRequest,
  });
  
  const FPPermissionState.camera({
    super.key,
    this.title = 'Camera Access Required',
    this.description = 'ESUN needs camera access to scan QR codes and documents.',
    this.actionLabel = 'Enable Camera',
    required this.onRequest,
  }) : icon = Icons.camera_alt_outlined;
  
  const FPPermissionState.contacts({
    super.key,
    this.title = 'Contacts Access Required',
    this.description = 'Allow access to your contacts to send money easily.',
    this.actionLabel = 'Enable Contacts',
    required this.onRequest,
  }) : icon = Icons.contacts_outlined;
  
  const FPPermissionState.notifications({
    super.key,
    this.title = 'Enable Notifications',
    this.description = 'Stay updated with payment alerts and important updates.',
    this.actionLabel = 'Enable Notifications',
    required this.onRequest,
  }) : icon = Icons.notifications_outlined;
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: ESUNIconSize.huge,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          Text(
            title,
            style: ESUNTypography.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ESUNSpacing.sm),
          Text(
            description,
            style: ESUNTypography.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ESUNSpacing.lg),
          FPButton.primary(
            label: actionLabel,
            onPressed: onRequest,
            icon: icon,
          ),
        ],
      ),
    );
  }
}

/// Maintenance State
class FPMaintenanceState extends StatelessWidget {
  final String? message;
  final String? estimatedTime;
  
  const FPMaintenanceState({
    super.key,
    this.message,
    this.estimatedTime,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: ESUNColors.warningSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.construction_outlined,
              size: ESUNIconSize.huge,
              color: ESUNColors.warning,
            ),
          ),
          const SizedBox(height: ESUNSpacing.xxl),
          const Text(
            'Under Maintenance',
            style: ESUNTypography.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ESUNSpacing.sm),
          Text(
            message ?? 'We\'re making some improvements. Please check back soon.',
            style: ESUNTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (estimatedTime != null) ...[
            const SizedBox(height: ESUNSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ESUNSpacing.lg,
                vertical: ESUNSpacing.sm,
              ),
              decoration: const BoxDecoration(
                color: ESUNColors.warningSurface,
                borderRadius: ESUNRadius.smRadius,
              ),
              child: Text(
                'Estimated time: $estimatedTime',
                style: ESUNTypography.labelMedium.copyWith(
                  color: ESUNColors.warning,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Coming Soon State
class FPComingSoonState extends StatelessWidget {
  final String feature;
  final String? description;
  
  const FPComingSoonState({
    super.key,
    required this.feature,
    this.description,
  });
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.rocket_launch_outlined,
              size: ESUNIconSize.huge,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: ESUNSpacing.xxl),
          Text(
            feature,
            style: ESUNTypography.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ESUNSpacing.sm),
          Text(
            description ?? 'This feature is coming soon. Stay tuned!',
            style: ESUNTypography.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ESUNSpacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ESUNSpacing.lg,
              vertical: ESUNSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: ESUNRadius.fullRadius,
            ),
            child: Text(
              'Coming Soon',
              style: ESUNTypography.labelMedium.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



