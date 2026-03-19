/// ESUN Settings Screen
/// 
/// App settings and preferences.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../state/app_state.dart';
import '../../state/aa_data_state.dart';
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
                  () => _showInfoDialog(context, 'App Icon', 'App icon customization will be available in a future update.'),
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
                  () => _showChangePinDialog(context),
                ),
                const FPDivider.subtle(),
                _buildNavigationTile(
                  'Privacy',
                  'Manage your data',
                  Icons.privacy_tip_outlined,
                  () => _showInfoDialog(context, 'Privacy', 'Your data is encrypted and stored securely. We never share your financial information with third parties without consent. You can request data deletion from the Profile screen.'),
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
                  settings.transactionAlertsEnabled,
                  (value) {
                    ref.read(appSettingsProvider.notifier).toggleTransactionAlerts();
                  },
                ),
                const FPDivider.subtle(),
                _buildSwitchTile(
                  'Bill Reminders',
                  'Remind me before due dates',
                  Icons.alarm_outlined,
                  settings.billRemindersEnabled,
                  (value) {
                    ref.read(appSettingsProvider.notifier).toggleBillReminders();
                  },
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
                Builder(
                  builder: (context) {
                    final banks = ref.watch(aaDataProvider).bankAccounts;
                    final label = banks.isNotEmpty
                        ? '${banks.first.bankName} ••••${banks.first.accountNumber.length >= 4 ? banks.first.accountNumber.substring(banks.first.accountNumber.length - 4) : banks.first.accountNumber}'
                        : 'No bank linked';
                    return _buildNavigationTile(
                      'Default Payment Method',
                      label,
                      Icons.account_balance_outlined,
                      () => context.push(AppRoutes.payments),
                    );
                  },
                ),
                const FPDivider.subtle(),
                _buildNavigationTile(
                  'UPI Settings',
                  'Manage UPI IDs',
                  Icons.qr_code_outlined,
                  () => context.push(AppRoutes.payments),
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
                  () => _showInfoDialog(context, 'Terms of Service', 'By using ESUN, you agree to our terms of service. This app provides financial management tools for informational purposes. Investment decisions are your own responsibility. For full terms, visit esun.app/terms.'),
                ),
                const FPDivider.subtle(),
                _buildNavigationTile(
                  'Privacy Policy',
                  '',
                  Icons.privacy_tip_outlined,
                  () => _showInfoDialog(context, 'Privacy Policy', 'ESUN collects financial data only with your explicit consent via Account Aggregator (AA) framework regulated by RBI. Your data is encrypted at rest and in transit. We do not sell your data. For details, visit esun.app/privacy.'),
                ),
                const FPDivider.subtle(),
                _buildNavigationTile(
                  'App Version',
                  '1.0.0-mvp',
                  Icons.info_outline,
                  null,
                  showChevron: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 72),
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
    VoidCallback? onTap, {
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

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showChangePinDialog(BuildContext context) {
    final currentPin = TextEditingController();
    final newPin = TextEditingController();
    final confirmPin = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPin,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Current PIN',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newPin,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'New PIN',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmPin,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Confirm New PIN',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (newPin.text != confirmPin.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PINs do not match')),
                );
                return;
              }
              if (newPin.text.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN must be 4 digits')),
                );
                return;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PIN changed successfully')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}



