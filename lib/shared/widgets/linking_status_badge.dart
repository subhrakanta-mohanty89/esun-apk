/// ESUN Linking Status Badge
///
/// Dashboard badge widget that shows linking status and prompts
/// users to complete data linking or re-link on errors.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../services/reminder_service.dart';
import '../../routes/app_routes.dart';
import '../../core/analytics/analytics_service.dart';

/// Linking status badge for dashboard
class LinkingStatusBadge extends ConsumerWidget {
  const LinkingStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(linkingStatusProvider);

    return statusAsync.when(
      data: (status) {
        if (status == null || (!status.needsAttention && !status.hasErrors)) {
          return const SizedBox.shrink();
        }
        return _buildBadge(context, ref, status);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBadge(BuildContext context, WidgetRef ref, LinkingStatus status) {
    final badge = status.badge;
    if (badge == null) return const SizedBox.shrink();

    final isError = badge.type == 'error';
    final backgroundColor = isError
        ? ESUNColors.error.withOpacity(0.1)
        : ESUNColors.warning.withOpacity(0.1);
    final borderColor = isError ? ESUNColors.error : ESUNColors.warning;
    final iconColor = isError ? ESUNColors.error : ESUNColors.warning;
    final icon = isError ? Icons.error_outline : Icons.info_outline;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ESUNSpacing.lg,
        vertical: ESUNSpacing.sm,
      ),
      child: InkWell(
        onTap: () => _handleTap(context, ref, status),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(ESUNSpacing.md),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: ESUNSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badge.message,
                      style: ESUNTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ESUNColors.textPrimary,
                      ),
                    ),
                    if (status.hasErrors) ...[
                      const SizedBox(height: 2),
                      Text(
                        _getErrorDescription(status),
                        style: ESUNTypography.caption.copyWith(
                          color: ESUNColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getErrorDescription(LinkingStatus status) {
    if (status.accountAggregator.hasError) {
      return status.accountAggregator.errorMessage ?? 'Account Aggregator needs attention';
    }
    if (status.creditBureau.hasError) {
      return status.creditBureau.errorMessage ?? 'Credit Bureau needs attention';
    }
    return 'Complete setup for full features';
  }

  void _handleTap(BuildContext context, WidgetRef ref, LinkingStatus status) {
    ref.read(analyticsServiceProvider).logEvent(
      name: 'linking_badge_tapped',
      parameters: {
        'has_errors': status.hasErrors,
        'needs_attention': status.needsAttention,
      },
    );

    context.push(AppRoutes.dataConnections);
  }
}

/// Compact linking status indicator for use in cards
class LinkingStatusIndicator extends ConsumerWidget {
  final String connectionType; // 'aa' or 'credit_bureau'

  const LinkingStatusIndicator({
    super.key,
    required this.connectionType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(linkingStatusProvider);

    return statusAsync.when(
      data: (status) {
        if (status == null) return const SizedBox.shrink();
        
        final connection = connectionType == 'aa'
            ? status.accountAggregator
            : status.creditBureau;

        return _buildIndicator(context, ref, connection);
      },
      loading: () => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildIndicator(
    BuildContext context,
    WidgetRef ref,
    ConnectionInfo connection,
  ) {
    final (color, icon, tooltip) = _getStatusVisuals(connection);

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ESUNSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              connection.ctaText ?? _getStatusLabel(connection.status),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, IconData, String) _getStatusVisuals(ConnectionInfo connection) {
    switch (connection.status) {
      case 'linked':
        return (ESUNColors.success, Icons.check_circle, 'Connected successfully');
      case 'pending':
        return (ESUNColors.warning, Icons.hourglass_empty, 'Connection pending');
      case 'error':
      case 'expired':
        return (ESUNColors.error, Icons.error_outline, connection.errorMessage ?? 'Error - tap to re-link');
      default:
        return (ESUNColors.textSecondary, Icons.link_off, 'Not linked');
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'linked':
        return 'Linked';
      case 'pending':
        return 'Pending';
      case 'error':
        return 'Error';
      case 'expired':
        return 'Expired';
      default:
        return 'Link';
    }
  }
}

/// Error banner for expired/failed connections
class ConnectionErrorBanner extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRelink;
  final VoidCallback? onDismiss;

  const ConnectionErrorBanner({
    super.key,
    required this.title,
    required this.message,
    required this.onRelink,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(ESUNSpacing.lg),
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: ESUNColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ESUNColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(ESUNSpacing.sm),
                decoration: BoxDecoration(
                  color: ESUNColors.error.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: ESUNColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: ESUNSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: ESUNTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ESUNColors.error,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: ESUNTypography.caption.copyWith(
                        color: ESUNColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onDismiss,
                  color: ESUNColors.textTertiary,
                ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRelink,
              style: ElevatedButton.styleFrom(
                backgroundColor: ESUNColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Re-link Now',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
