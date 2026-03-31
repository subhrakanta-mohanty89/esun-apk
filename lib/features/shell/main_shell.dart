/// ESUN Main Shell
/// 
/// Bottom navigation shell that wraps the main screens.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../routes/app_routes.dart';
import '../../state/app_state.dart';
import '../../core/storage/secure_storage.dart';

/// Current navigation index provider
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Main Shell with Bottom Navigation
class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  
  const MainShell({
    super.key,
    required this.child,
  });
  
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with WidgetsBindingObserver {
  DateTime? _pausedAt;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed && _pausedAt != null) {
      final elapsed = DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
      // If app was in background for more than 30 seconds, require biometric
      if (elapsed.inSeconds > 30) {
        _checkBiometricLock();
      }
    }
  }
  
  Future<void> _checkBiometricLock() async {
    final secureStorage = ref.read(secureStorageProvider);
    final biometricEnabled = await secureStorage.isBiometricEnabled();
    final appSettings = ref.read(appSettingsProvider);
    
    if (biometricEnabled && appSettings.biometricPromptEnabled && mounted) {
      context.go(AppRoutes.biometricUnlock);
    }
  }
  
  static const List<_NavItem> _navItems = [
    _NavItem(
      path: AppRoutes.home,
      label: 'Overview',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
    ),
    _NavItem(
      path: AppRoutes.invest,
      label: 'Wealth',
      icon: Icons.trending_up_outlined,
      activeIcon: Icons.trending_up,
    ),
    _NavItem(
      path: AppRoutes.payments,
      label: 'Pay',
      icon: Icons.qr_code_scanner_outlined,
      activeIcon: Icons.qr_code_scanner,
      isCenter: true,
    ),
    _NavItem(
      path: AppRoutes.discover,
      label: 'Discover',
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
    ),
    _NavItem(
      path: AppRoutes.advisor,
      label: 'Kantha',
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome,
    ),
  ];
  
  int _getSelectedIndex(String location) {
    // Check non-home routes first since home is '/' which matches everything
    for (int i = 1; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].path)) {
        return i;
      }
    }
    // Default to home
    return 0;
  }
  
  // Modules that require AA/Credit Bureau linking
  // Index 0: Home - always accessible
  // Index 1: Wealth Manager - requires linking
  // Index 2: Pay - always accessible (center)
  // Index 3: Discover - requires linking  
  // Index 4: Advisor - requires linking
  static const Set<int> _restrictedModules = {1, 3, 4};
  
  void _onItemTapped(int index) {
    // Check if this module requires linking
    if (_restrictedModules.contains(index)) {
      final authState = ref.read(authStateProvider);
      final isLinked = authState.aaConnected || authState.creditBureauConnected;
      
      if (!isLinked) {
        _showLinkRequiredDialog();
        return;
      }
    }
    
    context.go(_navItems[index].path);
  }
  
  void _showLinkRequiredDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: ESUNRadius.lgRadius,
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(ESUNSpacing.sm),
              decoration: BoxDecoration(
                color: ESUNColors.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.link_off_rounded,
                color: ESUNColors.warning,
              ),
            ),
            const SizedBox(width: ESUNSpacing.md),
            const Expanded(
              child: Text('Link Required'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To access this feature, please link your Account Aggregator or Credit Bureau first.',
              style: ESUNTypography.bodyMedium.copyWith(
                color: ESUNColors.textSecondary,
              ),
            ),
            const SizedBox(height: ESUNSpacing.md),
            Text(
              'This helps us provide personalized insights and recommendations.',
              style: ESUNTypography.bodySmall.copyWith(
                color: ESUNColors.textTertiary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: ESUNColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.push(AppRoutes.aaVerifyPan);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ESUNColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: ESUNRadius.smRadius,
              ),
            ),
            child: const Text('Link Now'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _getSelectedIndex(location);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? ESUNColors.darkBackground : ESUNColors.background,
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? ESUNColors.darkSurface : Colors.white,
          border: Border(
            top: BorderSide(
              color: const Color(0xFFF1F5F9),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: ESUNSpacing.sm,
              right: ESUNSpacing.sm,
              top: ESUNSpacing.sm,
              bottom: ESUNSpacing.sm + 8, // extra 8px bottom padding
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (index) {
                final item = _navItems[index];
                final isSelected = index == selectedIndex;
                
                return _NavBarItem(
                  icon: isSelected ? item.activeIcon : item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  isCenter: item.isCenter,
                  onTap: () => _onItemTapped(index),
                  selectedColor: colorScheme.primary,
                  unselectedColor: isDark 
                      ? ESUNColors.darkTextTertiary 
                      : ESUNColors.textTertiary,
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isCenter;
  
  const _NavItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.isCenter = false,
  });
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isCenter;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color unselectedColor;
  
  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.isCenter = false,
    required this.onTap,
    required this.selectedColor,
    required this.unselectedColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final color = isSelected ? selectedColor : unselectedColor;
    
    // Center item (Pay) has special elevated styling
    if (isCenter) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Transform.translate(
            offset: const Offset(0, -4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        selectedColor,
                        selectedColor.withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: selectedColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: ESUNTypography.labelSmall.copyWith(
                    color: isSelected ? selectedColor : unselectedColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: ESUNRadius.smRadius,
        child: AnimatedContainer(
          duration: ESUNAnimations.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: ESUNSpacing.sm,
            vertical: ESUNSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: ESUNAnimations.fast,
                width: 48,
                padding: const EdgeInsets.symmetric(
                  vertical: ESUNSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFEEF2FF)
                      : Colors.transparent,
                  borderRadius: ESUNRadius.fullRadius,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: ESUNIconSize.md,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: ESUNSpacing.xs),
              Text(
                label,
                style: ESUNTypography.labelSmall.copyWith(
                  color: isSelected ? selectedColor : unselectedColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



