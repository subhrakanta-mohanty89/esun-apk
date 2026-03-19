/// ESUN Splash Screen
/// 
/// Initial loading screen with branding and auth check.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../state/app_state.dart';
import '../../routes/app_routes.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
    
    _controller.forward();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    // Minimum splash display time for branding
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) return;
    
    // Wait for auth state to finish loading
    AuthState authState = ref.read(authStateProvider);
    
    // Poll until auth state is fully determined (max 10 seconds)
    // This ensures we don't navigate until authentication is resolved
    int attempts = 0;
    const maxAttempts = 30; // 3 seconds max
    while ((authState.isLoading || authState.status == AuthStatus.initial) && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      authState = ref.read(authStateProvider);
      attempts++;
    }
    
    if (!mounted) return;
    
    // Safety check: if still loading after timeout, default to unauthenticated
    if (authState.isLoading || authState.status == AuthStatus.initial) {
      authState = const AuthState(status: AuthStatus.unauthenticated, isLoading: false);
    }
    
    // Get app settings to check onboarding status
    final appSettings = ref.read(appSettingsProvider);
    
    switch (authState.status) {
      case AuthStatus.authenticated:
        // Go directly to main app - data linking prompt shown on home screen
        context.go(AppRoutes.payments);
        break;
      case AuthStatus.unauthenticated:
      case AuthStatus.initial:
      case AuthStatus.sessionExpired:
        // Check if user has completed onboarding (seen feature intro screens)
        if (!appSettings.hasCompletedOnboarding) {
          // First time user - show feature intro screens
          context.go(AppRoutes.featureIntro);
        } else {
          // Returning user - go to login screen
          context.go(AppRoutes.login);
        }
        break;
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ESUNColors.primary600,
              ESUNColors.primary400,
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  // Logo
                  Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: ESUNRadius.xlRadius,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 60,
                            color: ESUNColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: ESUNSpacing.xl),
                  // App Name
                  Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        children: [
                          Text(
                            'ESUN',
                            style: ESUNTypography.displayMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: ESUNSpacing.xs),
                          Text(
                            'Your Financial Companion',
                            style: ESUNTypography.bodyLarge.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  // Loading indicator
                  Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: ESUNSpacing.md),
                        Text(
                          'Setting things up...',
                          style: ESUNTypography.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ESUNSpacing.xxl),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}



