/// ESUN Feature Introduction Screen
///
/// Shows app features to new users after registration with swipeable pages.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../routes/app_routes.dart';
import '../../state/app_state.dart';

/// Feature intro page data
class _FeaturePage {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradientColors;
  final List<String> highlights;

  const _FeaturePage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradientColors,
    required this.highlights,
  });
}

class FeatureIntroScreen extends ConsumerStatefulWidget {
  const FeatureIntroScreen({super.key});

  @override
  ConsumerState<FeatureIntroScreen> createState() => _FeatureIntroScreenState();
}

class _FeatureIntroScreenState extends ConsumerState<FeatureIntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_FeaturePage> _pages = [
    _FeaturePage(
      icon: Icons.account_balance_rounded,
      title: 'All Your Finances\nIn One Place',
      description: 'Connect all your bank accounts and track every rupee with ease.',
      gradientColors: [Color(0xFF1E40AF), Color(0xFF06B6D4)],
      highlights: [
        'Link multiple bank accounts',
        'Track expenses automatically',
        'Real-time balance updates',
        'Smart spending insights',
      ],
    ),
    _FeaturePage(
      icon: Icons.psychology_rounded,
      title: 'Meet KANTA\nYour Financial Coach',
      description: 'Get personalized financial Insights in Hindi, Telugu, Tamil & more.',
      gradientColors: [Color(0xFF0D9488), Color(0xFF2E4A9A)],
      highlights: [
        'Chat in 6 Indian languages',
        'Voice-enabled coaching',
        'Personalized action plans',
        '24/7 financial guidance',
      ],
    ),
    _FeaturePage(
      icon: Icons.trending_up_rounded,
      title: 'Invest & Grow\nYour Wealth',
      description: 'Explore stocks, mutual funds, FDs and build your portfolio.',
      gradientColors: [Color(0xFFFC466B), Color(0xFF3F5EFB)],
      highlights: [
        'Track your investments',
        'Live stock prices',
        'IPO alerts & updates',
        'Portfolio analytics',
      ],
    ),
    _FeaturePage(
      icon: Icons.currency_rupee_rounded,
      title: 'Quick & Secure\nPayments',
      description: 'Send money, pay bills, and manage all payments effortlessly.',
      gradientColors: [Color(0xFF059669), Color(0xFF34D399)],
      highlights: [
        'UPI & bank transfers',
        'Bill reminders',
        'Split expenses',
        'Payment history',
      ],
    ),
    _FeaturePage(
      icon: Icons.security_rounded,
      title: 'Bank-Grade\nSecurity',
      description: 'Your data is protected with the highest level of encryption.',
      gradientColors: [Color(0xFF1A237E), Color(0xFF5C6BC0)],
      highlights: [
        'Biometric authentication',
        'End-to-end encryption',
        'RBI regulated Account Aggregator',
        'CERT-IN compliant security',
      ],
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeIntro();
    }
  }

  void _skipIntro() {
    _completeIntro();
  }

  Future<void> _completeIntro() async {
    // Mark onboarding as complete so it won't show again
    await ref.read(appSettingsProvider.notifier).completeOnboarding();
    if (mounted) {
      // Navigate to login - user needs to login or register
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;
    final page = _pages[_currentPage];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: page.gradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Padding(
                padding: const EdgeInsets.all(ESUNSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isLastPage)
                      TextButton(
                        onPressed: _skipIntro,
                        child: Text(
                          'Skip',
                          style: ESUNTypography.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),

              // Page Indicators
              Padding(
                padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 28 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    );
                  }),
                ),
              ),

              // Next/Get Started Button
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ESUNSpacing.xl,
                  ESUNSpacing.sm,
                  ESUNSpacing.xl,
                  ESUNSpacing.xl,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: page.gradientColors[0],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLastPage ? 'Get Started' : 'Next',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isLastPage
                              ? Icons.arrow_forward_rounded
                              : Icons.arrow_forward_ios_rounded,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_FeaturePage page) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final iconSize = isSmallScreen ? 80.0 : 120.0;
    final iconInnerSize = isSmallScreen ? 44.0 : 64.0;
    
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ESUNSpacing.lg,
          vertical: isSmallScreen ? ESUNSpacing.md : ESUNSpacing.xl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                page.icon,
                size: iconInnerSize,
                color: Colors.white,
              ),
            ),
            SizedBox(height: isSmallScreen ? ESUNSpacing.md : ESUNSpacing.xl),

            // Title
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: (isSmallScreen ? ESUNTypography.titleLarge : ESUNTypography.displaySmall).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            SizedBox(height: isSmallScreen ? ESUNSpacing.sm : ESUNSpacing.md),

            // Description
            Text(
              page.description,
              textAlign: TextAlign.center,
              style: ESUNTypography.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
            ),
            SizedBox(height: isSmallScreen ? ESUNSpacing.md : ESUNSpacing.xl),

            // Highlights
            Container(
              padding: EdgeInsets.all(isSmallScreen ? ESUNSpacing.md : ESUNSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: page.highlights.map((highlight) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 6),
                    child: Row(
                      children: [
                        Container(
                          width: isSmallScreen ? 20 : 24,
                          height: isSmallScreen ? 20 : 24,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: isSmallScreen ? 14 : 16,
                          ),
                        ),
                        const SizedBox(width: ESUNSpacing.sm),
                        Expanded(
                          child: Text(
                            highlight,
                            style: ESUNTypography.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



