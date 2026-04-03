// Part of eSun Flutter App — splash
/// Enhanced splash screen with elastic logo animation and tagline fade-in.
library;


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../state/app_state.dart';
import '../../routes/app_routes.dart';
import '../../core/storage/secure_storage.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _taglineFade;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Logo scales from 0.5 → 1.0 with elastic curve
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    // Tagline fades in at ~800ms (0.32 of 2500ms)
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.32, 0.6, curve: Curves.easeOut),
      ),
    );

    // Shimmer effect cycles
    _shimmer = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Minimum 2.5s splash display for branding
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    // Check onboarding status from Hive
    final cache = ref.read(cacheStorageProvider);
    final hasCompletedOnboarding =
        cache.getPref<bool>(PrefKeys.onboardingComplete) ?? false;

    if (!hasCompletedOnboarding) {
      // First install → onboarding intro
      if (mounted) context.go(AppRoutes.onboardingIntro);
      return;
    }

    // Has seen onboarding — check for tokens
    final storage = ref.read(secureStorageProvider);
    final hasTokens = await storage.isLoggedIn();

    if (!hasTokens) {
      if (mounted) context.go(AppRoutes.login);
      return;
    }

    // Has tokens → wait for _restoreSession to finish
    AuthState authState = ref.read(authStateProvider);
    int attempts = 0;
    while ((authState.isLoading || authState.status == AuthStatus.initial) &&
        attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      authState = ref.read(authStateProvider);
      attempts++;
    }

    if (!mounted) return;

    if (authState.status == AuthStatus.authenticated) {
      context.go(AppRoutes.payments);
    } else {
      context.go(AppRoutes.login);
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
                  // Logo with scale + shimmer
                  Transform.scale(
                    scale: _logoScale.value,
                    child: Opacity(
                      opacity: _logoFade.value,
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
                  // App name
                  Opacity(
                    opacity: _logoFade.value,
                    child: Text(
                      'ESUN',
                      style: ESUNTypography.displayMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: ESUNSpacing.xs),
                  // Tagline fades in at 800ms
                  Opacity(
                    opacity: _taglineFade.value,
                    child: Text(
                      'Your Financial Companion',
                      style: ESUNTypography.bodyLarge.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  // Loading indicator
                  Opacity(
                    opacity: _taglineFade.value,
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



