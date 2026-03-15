/// ESUN Profile Screen
/// 
/// User profile and account management.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/widgets.dart';
import '../../state/app_state.dart';
import '../../core/network/api_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(context, profile),
            
            // Account Stats
            _buildAccountStats(context),
            
            // Menu Items
            _buildMenuSection(context, ref),
            
            // Logout
            _buildLogoutButton(context, ref),
            
            const SizedBox(height: ESUNSpacing.xxl),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfileHeader(BuildContext context, Map<String, dynamic>? profile) {
    final fullName = profile?['full_name'] ?? profile?['email'] ?? profile?['phone_number'] ?? 'User';
    final phone = profile?['phone_number'];
    final email = profile?['email'];
    final initials = _initials(fullName);
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.xl),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: ESUNColors.primary.withOpacity(0.1),
                child: Text(
                  initials,
                  style: ESUNTypography.headlineLarge.copyWith(
                    color: ESUNColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ESUNColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.lg),
          Text(
            fullName,
            style: ESUNTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            phone ?? email ?? '',
            style: ESUNTypography.bodyMedium.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: ESUNRadius.fullRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Gold Member',
                  style: ESUNTypography.labelMedium.copyWith(
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAccountStats(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: FPCard(
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem('Member Since', 'Jan 2023', Icons.calendar_today),
            ),
            Container(width: 1, height: 50, color: ESUNColors.border),
            Expanded(
              child: _buildStatItem('Transactions', '1,234', Icons.receipt_long),
            ),
            Container(width: 1, height: 50, color: ESUNColors.border),
            Expanded(
              child: _buildStatItem('Rewards', '2,450', Icons.stars),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: ESUNColors.primary, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: ESUNTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: ESUNTypography.labelSmall.copyWith(
            color: ESUNColors.textSecondary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMenuSection(BuildContext context, WidgetRef ref) {
    final menuItems = [
      _MenuItem('Personal Info', Icons.person_outline, () => _showEditProfileDialog(context, ref)),
      _MenuItem('Bank Accounts', Icons.account_balance_outlined, () {}),
      _MenuItem('Linked Cards', Icons.credit_card_outlined, () {}),
      _MenuItem('Data Connections', Icons.link_outlined, () => context.push(AppRoutes.dataConnections)),
      _MenuItem('KYC Status', Icons.verified_user_outlined, () {}),
      _MenuItem('Security', Icons.security_outlined, () {}),
      _MenuItem('Notifications', Icons.notifications_outlined, () => context.push(AppRoutes.alerts)),
      _MenuItem('Goals', Icons.flag_outlined, () => context.push(AppRoutes.goals)),
      _MenuItem('Budgets', Icons.pie_chart_outline, () => context.push(AppRoutes.budgets)),
      _MenuItem('Reports', Icons.bar_chart_outlined, () => context.push(AppRoutes.reports)),
      _MenuItem('Help & Support', Icons.help_outline, () {}),
      _MenuItem('About', Icons.info_outline, () {}),
    ];
    
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        children: menuItems.map((item) => _buildMenuItem(item)).toList(),
      ),
    );
  }
  
  Widget _buildMenuItem(_MenuItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: ESUNRadius.mdRadius,
          child: Container(
            padding: const EdgeInsets.all(ESUNSpacing.md),
            decoration: BoxDecoration(
              color: ESUNColors.surfaceVariant.withOpacity(0.5),
              borderRadius: ESUNRadius.mdRadius,
            ),
            child: Row(
              children: [
                Icon(item.icon, color: ESUNColors.textSecondary),
                const SizedBox(width: ESUNSpacing.md),
                Expanded(
                  child: Text(
                    item.label,
                    style: ESUNTypography.bodyLarge,
                  ),
                ),
                const Icon(Icons.chevron_right, color: ESUNColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(authStateProvider.notifier).logout();
                      context.go(AppRoutes.login);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ESUNColors.error,
                    ),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.logout, color: ESUNColors.error),
          label: Text(
            'Logout',
            style: ESUNTypography.bodyLarge.copyWith(
              color: ESUNColors.error,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: ESUNColors.error),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}

/// Profile provider fetching /users/me
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final api = ref.read(apiServiceProvider);
  final result = await api.get<Map<String, dynamic>>('${ApiConfig.apiPrefix}/users/me');
  if (result.isError) return null;
  final body = result.data as Map<String, dynamic>?;
  if (body == null || body['success'] != true) return null;
  return body['data'] as Map<String, dynamic>?;
});

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return 'U';
  if (parts.length == 1) return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : 'U';
  return (parts[0].isNotEmpty ? parts[0][0] : '') + (parts[1].isNotEmpty ? parts[1][0] : '');
}

void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
  final profile = ref.read(userProfileProvider).valueOrNull;
  final nameController = TextEditingController(text: profile?['full_name'] ?? '');
  
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Edit Profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter your full name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final newName = nameController.text.trim();
            if (newName.isEmpty) return;
            
            final api = ref.read(apiServiceProvider);
            final result = await api.patch<Map<String, dynamic>>(
              '${ApiConfig.apiPrefix}/users/me',
              data: {'full_name': newName},
            );
            
            if (result.isError || result.data?['success'] != true) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to update profile')),
                );
              }
            } else {
              // Refresh the profile provider
              ref.invalidate(userProfileProvider);
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully')),
                );
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

class _MenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  
  _MenuItem(this.label, this.icon, this.onTap);
}



