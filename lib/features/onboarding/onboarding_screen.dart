/// ESUN Onboarding Screen
/// 
/// Introduces app features to new users.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../routes/app_routes.dart';

/// Onboarding state provider
final onboardingIndexProvider = StateProvider<int>((ref) => 0);

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  
  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.account_balance_rounded,
      title: 'All Your Finances\nIn One Place',
      description: 'Track spending, manage investments, and stay on top of your bills effortlessly.',
      gradient: [Color(0xFF1E40AF), Color(0xFF06B6D4)],
    ),
    _OnboardingPage(
      icon: Icons.psychology_rounded,
      title: 'Smart AI\nAssistant',
      description: 'Meet KANTA - your personal finance advisor powered by AI to help you make better decisions',
      gradient: [Color(0xFF0D9488), Color(0xFF2E4A9A)],
    ),
    _OnboardingPage(
      icon: Icons.trending_up_rounded,
      title: 'Invest & Grow\nYour Wealth',
      description: 'Explore stocks, mutual funds, and fixed deposits. Start building your wealth today.',
      gradient: [ESUNColors.success, Color(0xFF059669)],
    ),
    _OnboardingPage(
      icon: Icons.security_rounded,
      title: 'Bank-Grade\nSecurity',
      description: 'RBI-regulated & CERT-IN compliant. End-to-end encryption with biometric authentication.',
      gradient: [Color(0xFF1A237E), Color(0xFF5C6BC0)],
    ),
  ];
  
  void _nextPage() {
    final currentIndex = ref.read(onboardingIndexProvider);
    if (currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: ESUNAnimations.medium,
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }
  
  void _skipOnboarding() {
    _completeOnboarding();
  }
  
  void _completeOnboarding() {
    context.go(AppRoutes.onboardingDetails);
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(onboardingIndexProvider);
    final isLastPage = currentIndex == _pages.length - 1;
    
    return Scaffold(
      body: Stack(
        children: [
          // Page View
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
              ref.read(onboardingIndexProvider.notifier).state = index;
            },
            itemBuilder: (context, index) {
              return _OnboardingPageView(page: _pages[index]);
            },
          ),
          
          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + ESUNSpacing.md,
            right: ESUNSpacing.lg,
            child: AnimatedOpacity(
              opacity: isLastPage ? 0.0 : 1.0,
              duration: ESUNAnimations.fast,
              child: TextButton(
                onPressed: isLastPage ? null : _skipOnboarding,
                child: Text(
                  'Skip',
                  style: ESUNTypography.labelLarge.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ),
          
          // Bottom controls
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + ESUNSpacing.md,
            left: ESUNSpacing.xl,
            right: ESUNSpacing.xl,
            child: Column(
              children: [
                // Page indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) {
                    return AnimatedContainer(
                      duration: ESUNAnimations.fast,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: currentIndex == index ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currentIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                        borderRadius: ESUNRadius.fullRadius,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: ESUNSpacing.xl),
                // Next/Get Started button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _pages[currentIndex].gradient[0],
                      padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
                      shape: const RoundedRectangleBorder(
                        borderRadius: ESUNRadius.lgRadius,
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isLastPage ? 'Get Started' : 'Next',
                      style: ESUNTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _pages[currentIndex].gradient[0],
                      ),
                    ),
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

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;
  
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingPage page;
  
  const _OnboardingPageView({required this.page});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: page.gradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.xl),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Icon container
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      page.icon,
                      size: 50,
                      color: page.gradient[0],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Title
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: ESUNTypography.displaySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  shadows: [
                    Shadow(
                      color: page.gradient[1].withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                    Shadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ESUNSpacing.lg),
              // Description
              Text(
                page.description,
                textAlign: TextAlign.center,
                style: ESUNTypography.bodyLarge.copyWith(
                  color: Colors.white,
                  height: 1.5,
                  shadows: [
                    Shadow(
                      color: page.gradient[1].withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                    Shadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
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



