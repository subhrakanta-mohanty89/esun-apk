/// ESUN Settings Screen
/// 
/// App settings and preferences.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../state/app_state.dart';
import '../../shared/widgets/widgets.dart';
import '../../routes/app_routes.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final settings = ref.watch(appSettingsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        children: [
          // Appearance
          _buildSectionHeader('Appearance'),
          FPCard(
            child: Column(
              children: [
                _buildSwitchTile(
                  'Dark Mode',
                  'Switch to dark theme',
                  Icons.dark_mode_outlined,
                  themeMode == ThemeMode.dark,
                  (value) {
                    ref.read(themeModeProvider.notifier).toggleTheme();
                  },
                ),
                const FPDivider.subtle(),
                _buildNavigationTile(
                  'App Icon',
                  'Change app icon',
                  Icons.app_shortcut_outlined,
                  () => _showNotImplemented(context, 'App Icon'),
                ),
              ],
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          
          // Security
          _buildSectionHeader('Security'),
          FPCard(
            child: Column(
              children: [
                _buildSwitchTile(
                  'Biometric Login',
                  'Use fingerprint or face to login',
                  Icons.fingerprint,
                  settings.biometricEnabled,
                  (value) {
                    ref.read(appSettingsProvider.notifier).toggleBiometric();
                  },
                ),
                const FPDivider.subtle(),
                _buildNavigationTile(
                  'Change PIN',
                  'Update your app PIN',
                  Icons.lock_outline,
                  () => _showNotImplemented(context, 'Change PIN'),
                ),
                const FPDivider.subtle(),
                _buildNavigationTile(
                  'Privacy',
                  'Manage your data',
                  Icons.privacy_tip_outlined,
                  () => _showNotImplemented(context, 'Privacy'),
                ),
              ],
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          
          // Data Connections
          _buildSectionHeader('Data Connections'),
          FPCard(
            child: Column(
              children: [
                _buildNavigationTile(
                  'Data Connections',
                  'Manage Account Aggregator & Credit Bureau',
                  Icons.link_outlined,
                  () => context.push(AppRoutes.dataConnections),
                ),
              ],
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          
          // Notifications
          _buildSectionHeader('Notifications'),
          FPCard(
            child: Column(
              children: [
                _buildSwitchTile(
                  'Push Notifications',
                  'Receive alerts and updates',
                  Icons.notifications_outlined,
                  settings.notificationsEnabled,
                  (value) {
                    ref.read(appSettingsProvider.notifier).toggleNotifications();
                  },
                ),
                const FPDivider.subtle(),
                _buildSwitchTile(
                  'Transaction Alerts',
                  'Get notified for every transaction',
                  Icons.receipt_long_outlined,
                  true,
                  (value) => _showNotImplemented(context, 'Transaction Alerts'),
                ),
                const FPDivider.subtle(),
                _buildSwitchTile(
                  'Bill Reminders',
                  'Remind me before due dates',
                  Icons.alarm_outlined,
                  true,
                  (value) => _showNotImplemented(context, 'Bill Reminders'),
                ),
              ],
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          
          // Payments
          _buildSectionHeader('Payments'),
          FPCard(
            child: Column(
              children: [
                _buildNavigationTile(
                  'Default Payment Method',
                  'HDFC Bank ****4521',
                  Icons.account_balance_outlined,
                  () => _showNotImplemented(context, 'Default Payment Method'),
                ),
                const FPDivider.subtle(),
                _buildNavigationTile(
                  'UPI Settings',
                  'Manage UPI IDs',
                  Icons.qr_code_outlined,
                  () => _showNotImplemented(context, 'UPI Settings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          
          // About
          _buildSectionHeader('About'),
          FPCard(
            child: Column(
              children: [
                _buildNavigationTile(
                  'Terms of Service',
                  '',
                  Icons.description_outlined,
                  () => _showNotImplemented(context, 'Terms of Service'),
                ),
                const FPDivider.subtle(),
                _buildNavigationTile(
                  'Privacy Policy',
                  '',
                  Icons.privacy_tip_outlined,
                  () => _showNotImplemented(context, 'Privacy Policy'),
                ),
                const FPDivider.subtle(),
                _buildNavigationTile(
                  'App Version',
                  '1.0.0 (Build 100)',
                  Icons.info_outline,
                  () => _showNotImplemented(context, 'App Version'),
                  showChevron: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: ESUNSpacing.xxl),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: ESUNSpacing.xs,
        bottom: ESUNSpacing.sm,
      ),
      child: Text(
        title,
        style: ESUNTypography.titleSmall.copyWith(
          color: ESUNColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ESUNSpacing.md,
          vertical: ESUNSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, color: ESUNColors.textSecondary),
            const SizedBox(width: ESUNSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ESUNTypography.bodyLarge,
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: ESUNTypography.bodySmall.copyWith(
                        color: ESUNColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNavigationTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool showChevron = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(ESUNSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: ESUNColors.textSecondary),
            const SizedBox(width: ESUNSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ESUNTypography.bodyLarge,
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: ESUNTypography.bodySmall.copyWith(
                        color: ESUNColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (showChevron)
              const Icon(Icons.chevron_right, color: ESUNColors.textTertiary),
          ],
        ),
      ),
    );
  }

  void _showNotImplemented(BuildContext context, String label) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label coming soon')),
    );
  }
}



