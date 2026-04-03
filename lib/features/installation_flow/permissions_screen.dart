/// ESUN Permissions Screen
///
/// Requests necessary app permissions from the user with clear explanations.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';

/// Permission item model
class PermissionItem {
  final IconData icon;
  final String title;
  final String description;
  final bool isRequired;
  final bool isGranted;

  const PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    this.isRequired = false,
    this.isGranted = false,
  });

  PermissionItem copyWith({bool? isGranted}) {
    return PermissionItem(
      icon: icon,
      title: title,
      description: description,
      isRequired: isRequired,
      isGranted: isGranted ?? this.isGranted,
    );
  }
}

class PermissionsScreen extends ConsumerStatefulWidget {
  final Function(bool granted) onComplete;

  const PermissionsScreen({
    super.key,
    required this.onComplete,
  });

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  bool _isProcessing = false;
  List<PermissionItem> _permissions = [
    const PermissionItem(
      icon: Icons.notifications_rounded,
      title: 'Notifications',
      description:
          'Get alerts for payments, bill reminders, and important updates about your finances.',
      isRequired: false,
    ),
    const PermissionItem(
      icon: Icons.camera_alt_rounded,
      title: 'Camera',
      description:
          'Scan QR codes for quick payments and document scanning for KYC verification.',
      isRequired: false,
    ),
    const PermissionItem(
      icon: Icons.contacts_rounded,
      title: 'Contacts',
      description:
          'Send money easily to your contacts. We never share your contact data.',
      isRequired: false,
    ),
    const PermissionItem(
      icon: Icons.fingerprint_rounded,
      title: 'Biometric',
      description:
          'Use fingerprint or face unlock for quick and secure app access.',
      isRequired: false,
    ),
    const PermissionItem(
      icon: Icons.location_on_rounded,
      title: 'Location',
      description:
          'Find nearby ATMs, bank branches, and enable location-based security.',
      isRequired: false,
    ),
  ];

  Future<void> _requestAllPermissions() async {
    setState(() => _isProcessing = true);

    // Simulate permission requests
    // In production, use permission_handler package
    await Future.delayed(const Duration(milliseconds: 500));

    // For demo, mark all as granted
    setState(() {
      _permissions = _permissions
          .map((p) => p.copyWith(isGranted: true))
          .toList();
      _isProcessing = false;
    });

    // Proceed after granting
    await Future.delayed(const Duration(milliseconds: 300));
    widget.onComplete(true);
  }

  Future<void> _skipPermissions() async {
    widget.onComplete(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ESUNColors.primary50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(ESUNSpacing.xl),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: ESUNColors.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.security_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: ESUNSpacing.lg),
                    Text(
                      'App Permissions',
                      style: ESUNTypography.headlineMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ESUNColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: ESUNSpacing.sm),
                    Text(
                      'These permissions help us provide you with a better experience. You can change these later in Settings.',
                      textAlign: TextAlign.center,
                      style: ESUNTypography.bodyMedium.copyWith(
                        color: ESUNColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Permissions list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
                  itemCount: _permissions.length,
                  itemBuilder: (context, index) {
                    final permission = _permissions[index];
                    return _PermissionTile(
                      permission: permission,
                      onToggle: () {
                        setState(() {
                          _permissions[index] = permission.copyWith(
                            isGranted: !permission.isGranted,
                          );
                        });
                      },
                    );
                  },
                ),
              ),

              // Bottom buttons
              Padding(
                padding: const EdgeInsets.all(ESUNSpacing.xl),
                child: Column(
                  children: [
                    // Allow All button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _requestAllPermissions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ESUNColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded),
                                  SizedBox(width: 8),
                                  Text(
                                    'Allow All Permissions',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: ESUNSpacing.md),

                    // Skip button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _isProcessing ? null : _skipPermissions,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ESUNColors.textSecondary,
                          side: const BorderSide(color: ESUNColors.neutral300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Skip for Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: ESUNSpacing.md),
                    Text(
                      'You can manage permissions anytime in Settings',
                      style: ESUNTypography.bodySmall.copyWith(
                        color: ESUNColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Permission tile widget
class _PermissionTile extends StatelessWidget {
  final PermissionItem permission;
  final VoidCallback onToggle;

  const _PermissionTile({
    required this.permission,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ESUNSpacing.md),
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: permission.isGranted
              ? ESUNColors.success.withOpacity(0.3)
              : ESUNColors.neutral200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: permission.isGranted
                  ? ESUNColors.success.withOpacity(0.1)
                  : ESUNColors.primary50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              permission.icon,
              color: permission.isGranted
                  ? ESUNColors.success
                  : ESUNColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: ESUNSpacing.md),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      permission.title,
                      style: ESUNTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ESUNColors.textPrimary,
                      ),
                    ),
                    if (permission.isRequired) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ESUNColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Required',
                          style: ESUNTypography.labelSmall.copyWith(
                            color: ESUNColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  permission.description,
                  style: ESUNTypography.bodySmall.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: ESUNSpacing.sm),

          // Toggle
          Switch.adaptive(
            value: permission.isGranted,
            onChanged: (_) => onToggle(),
            activeColor: ESUNColors.success,
          ),
        ],
      ),
    );
  }
}
