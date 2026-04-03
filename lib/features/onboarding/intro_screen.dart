// Part of eSun Flutter App — onboarding
/// Three-page onboarding intro shown on first install.
/// Writes 'onboarding_complete' to Hive, then navigates to /onboarding/details.
library;


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../state/app_state.dart';
import '../../routes/app_routes.dart';

class OnboardingIntroScreen extends ConsumerStatefulWidget {
  const OnboardingIntroScreen({super.key});

  @override
  ConsumerState<OnboardingIntroScreen> createState() =>
      _OnboardingIntroScreenState();
}

class _OnboardingIntroScreenState extends ConsumerState<OnboardingIntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = <_IntroPageData>[
    _IntroPageData(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Smart Finance',
      subtitle:
          'All your bank accounts, investments and expenses in one place. Track, plan and grow your wealth effortlessly.',
      color: Color(0xFF2E4A9A), // Royal Blue
      accentColor: Color(0xFF4A62B8),
    ),
    _IntroPageData(
      icon: Icons.auto_awesome_rounded,
      title: 'AI-Powered Insights',
      subtitle:
          'Meet KANTA, your personal AI financial advisor. Get tailored recommendations and real-time spending analysis.',
      color: Color(0xFF0891B2), // Cyan
      accentColor: Color(0xFF06B6D4),
    ),
    _IntroPageData(
      icon: Icons.shield_rounded,
      title: 'Secure & Private',
      subtitle:
          'Bank-grade encryption protects your data. Biometric login and device binding keep your finances safe.',
      color: Color(0xFF059669), // Emerald
      accentColor: Color(0xFF10B981),
    ),
  ];

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    ref.read(appSettingsProvider.notifier).completeOnboarding();
    context.go(AppRoutes.onboarding); // → registration screen
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          // Pages with parallax background
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double parallaxOffset = 0;
                  if (_pageController.position.haveDimensions) {
                    final page = _pageController.page ?? 0;
                    parallaxOffset = (page - index) * size.width * 0.3;
                  }
                  return _IntroPage(
                    data: _pages[index],
                    parallaxOffset: parallaxOffset,
                  );
                },
              );
            },
          ),

          // Skip button (top-right, hidden on last page)
          if (!isLastPage)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 20,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  'Skip',
                  style: ESUNTypography.labelLarge.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Page indicator dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                // Next / Get Started button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _pages[_currentPage].color,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: ESUNTypography.labelLarge.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(isLastPage ? 'Get Started' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Data model for a single intro page.
class _IntroPageData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color accentColor;

  const _IntroPageData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.accentColor,
  });
}

/// Single intro page with parallax-shifted background circle.
class _IntroPage extends StatelessWidget {
  final _IntroPageData data;
  final double parallaxOffset;

  const _IntroPage({required this.data, this.parallaxOffset = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [data.color, data.accentColor],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Animated icon with background circle (parallax)
              Transform.translate(
                offset: Offset(parallaxOffset, 0),
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                  ),
                  child: Center(
                    child: Icon(
                      data.icon,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: ESUNTypography.headlineLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                data.subtitle,
                textAlign: TextAlign.center,
                style: ESUNTypography.bodyLarge.copyWith(
                  color: Colors.white.withOpacity(0.85),
                  height: 1.6,
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
