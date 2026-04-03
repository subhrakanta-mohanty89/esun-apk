import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../theme/theme.dart';

/// Shows a bottom sheet with a QR preview for receiving money.
Future<void> showQrBottomSheet(
  BuildContext context, {
  required String name,
  required String upiId,
  String bankLabel = 'Linked account',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final colorScheme = theme.colorScheme;

      return Padding(
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ESUNSpacing.lg,
            vertical: ESUNSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? ESUNColors.darkSurface
                : Colors.white,
            borderRadius: ESUNRadius.xlRadius,
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: ESUNColors.divider,
                    borderRadius: ESUNRadius.fullRadius,
                  ),
                ),
                const SizedBox(height: ESUNSpacing.lg),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: colorScheme.primary.withOpacity(0.15),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: ESUNTypography.titleMedium.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: ESUNSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: ESUNTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            upiId,
                            style: ESUNTypography.bodyMedium.copyWith(
                              color: ESUNColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_outlined),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('UPI ID copied')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: ESUNSpacing.xl),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(ESUNSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withOpacity(0.08),
                        colorScheme.secondary.withOpacity(0.12),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: ESUNRadius.lgRadius,
                    border: Border.all(color: ESUNColors.border),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(ESUNSpacing.lg),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: ESUNRadius.mdRadius,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.qr_code_2_rounded,
                          size: 180,
                          color: ESUNColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: ESUNSpacing.md),
                      Text(
                        bankLabel,
                        style: ESUNTypography.labelMedium.copyWith(
                          color: ESUNColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ESUNSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final text = 'Pay $name via UPI ID: $upiId';
                          Share.share(text, subject: 'Scan or pay $name');
                        },
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Share'),
                      ),
                    ),
                    const SizedBox(width: ESUNSpacing.md),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}



