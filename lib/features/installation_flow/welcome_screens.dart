/// ESUN Welcome Screens
///
/// Swipeable onboarding screens introducing app features to new users.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';

/// Welcome page data model
class WelcomePage {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;
  final List<String> highlights;

  const WelcomePage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    this.highlights = const [],
  });
}

class WelcomeScreens extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const WelcomeScreens({
    super.key,
    required this.onComplete,
  });

  @override
  ConsumerState<WelcomeScreens> createState() => _WelcomeScreensState();
}

class _WelcomeScreensState extends ConsumerState<WelcomeScreens>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<WelcomePage> _pages = [
    // Page 1: App Introduction
    WelcomePage(
      icon: Icons.account_balance_rounded,
      title: 'Welcome to ESUN',
      description:
          'Your complete financial companion. Track, invest, and grow your wealth — all in one place.',
      gradient: [Color(0xFF1E40AF), Color(0xFF06B6D4)],
      highlights: [
        'Track all your bank accounts',
        'Smart expense categorization',
        'Investment portfolio tracking',
        'AI-powered financial advice',
      ],
    ),
    // Page 2: AI Financial Coach
    WelcomePage(
      icon: Icons.psychology_rounded,
      title: 'Meet KANTA\nYour Financial Coach',
      description:
          'Get personalized financial Insights in your language. Ask questions, get guidance, and achieve your money goals.',
      gradient: [Color(0xFF0D9488), Color(0xFF2E4A9A)],
      highlights: [
        'Chat in 6 Indian languages',
        'Voice-enabled coaching',
        'Personalized action plans',
        '24/7 financial guidance',
      ],
    ),
    // Page 3: Data Linking Intro
    WelcomePage(
      icon: Icons.link_rounded,
      title: 'Connect Your\nFinancial Data',
      description:
          'Securely link your bank accounts and credit bureau data for personalized insights.',
      gradient: [Color(0xFF4776E6), Color(0xFF8E54E9)],
      highlights: [
        'RBI-regulated Account Aggregator',
        'Bank-grade encryption',
        'Your data stays yours',
        'Revoke access anytime',
      ],
    ),
    // Page 4: Security & Privacy
    WelcomePage(
      icon: Icons.security_rounded,
      title: 'Bank-Grade\nSecurity',
      description:
          'Your data is protected with the highest level of encryption.',
      gradient: [Color(0xFF1A237E), Color(0xFF5C6BC0)],
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
      widget.onComplete();
    }
  }

  void _skipToEnd() {
    widget.onComplete();
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
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: page.gradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with skip button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ESUNSpacing.md,
                  vertical: ESUNSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Page indicator text
                    Text(
                      '${_currentPage + 1}/${_pages.length}',
                      style: ESUNTypography.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    // Skip button
                    if (!isLastPage)
                      TextButton(
                        onPressed: _skipToEnd,
                        child: Text(
                          'Skip',
                          style: ESUNTypography.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 60),
                  ],
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    return _WelcomePageView(page: _pages[index]);
                  },
                ),
              ),

              // Bottom section with indicators and button
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ESUNSpacing.xl,
                  ESUNSpacing.md,
                  ESUNSpacing.xl,
                  ESUNSpacing.xl,
                ),
                child: Column(
                  children: [
                    // Page indicators
                    Row(
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
                    const SizedBox(height: ESUNSpacing.xl),

                    // Next/Get Started button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: page.gradient[0],
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

/// Individual welcome page view
class _WelcomePageView extends StatelessWidget {
  final WelcomePage page;

  const _WelcomePageView({required this.page});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: ESUNSpacing.lg,
        vertical: isSmallScreen ? ESUNSpacing.sm : ESUNSpacing.lg,
      ),
      child: Column(
        children: [
          // Icon
          Container(
            width: isSmallScreen ? 100 : 140,
            height: isSmallScreen ? 100 : 140,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: isSmallScreen ? 50 : 70,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isSmallScreen ? ESUNSpacing.lg : ESUNSpacing.xl),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: (isSmallScreen
                    ? ESUNTypography.headlineMedium
                    : ESUNTypography.displaySmall)
                .copyWith(
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
            style: ESUNTypography.bodyLarge.copyWith(
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
          SizedBox(height: isSmallScreen ? ESUNSpacing.lg : ESUNSpacing.xl),

          // Highlights
          if (page.highlights.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(ESUNSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: page.highlights.map((highlight) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: ESUNSpacing.md),
                        Expanded(
                          child: Text(
                            highlight,
                            style: ESUNTypography.bodyMedium.copyWith(
                              color: Colors.white,
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
    );
  }
}
