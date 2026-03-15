/// ESUN Data Linking Screen
///
/// Explains the purpose of data linking (AA & Credit Bureau) with consent screens.
/// Provides clear CTAs: "Link Data Now" and "Do it later — go to Dashboard".

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme.dart';

/// Data source type
enum DataSourceType {
  accountAggregator,
  creditBureau,
}

/// Data linking step
enum DataLinkingStep {
  intro,
  accountAggregatorConsent,
  creditBureauConsent,
  summary,
}

class DataLinkingScreen extends ConsumerStatefulWidget {
  final VoidCallback onLinkNow;
  final VoidCallback onDoItLater;

  const DataLinkingScreen({
    super.key,
    required this.onLinkNow,
    required this.onDoItLater,
  });

  @override
  ConsumerState<DataLinkingScreen> createState() => _DataLinkingScreenState();
}

class _DataLinkingScreenState extends ConsumerState<DataLinkingScreen> {
  DataLinkingStep _currentStep = DataLinkingStep.intro;
  bool _aaConsentGiven = false;
  bool _creditBureauConsentGiven = false;

  void _nextStep() {
    setState(() {
      switch (_currentStep) {
        case DataLinkingStep.intro:
          _currentStep = DataLinkingStep.accountAggregatorConsent;
          break;
        case DataLinkingStep.accountAggregatorConsent:
          _currentStep = DataLinkingStep.creditBureauConsent;
          break;
        case DataLinkingStep.creditBureauConsent:
          _currentStep = DataLinkingStep.summary;
          break;
        case DataLinkingStep.summary:
          widget.onLinkNow();
          break;
      }
    });
  }

  void _previousStep() {
    setState(() {
      switch (_currentStep) {
        case DataLinkingStep.intro:
          // Can't go back from intro
          break;
        case DataLinkingStep.accountAggregatorConsent:
          _currentStep = DataLinkingStep.intro;
          break;
        case DataLinkingStep.creditBureauConsent:
          _currentStep = DataLinkingStep.accountAggregatorConsent;
          break;
        case DataLinkingStep.summary:
          _currentStep = DataLinkingStep.creditBureauConsent;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ESUNColors.primary.withOpacity(0.05),
              Colors.white,
              ESUNColors.success.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              _buildProgressIndicator(),

              // Content
              Expanded(
                child: _buildCurrentStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final steps = DataLinkingStep.values;
    final currentIndex = steps.indexOf(_currentStep);

    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Row(
        children: [
          if (_currentStep != DataLinkingStep.intro)
            IconButton(
              onPressed: _previousStep,
              icon: const Icon(Icons.arrow_back_rounded),
              color: ESUNColors.textSecondary,
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(steps.length, (index) {
                final isActive = index <= currentIndex;
                final isCompleted = index < currentIndex;
                return Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isActive
                            ? ESUNColors.primary
                            : ESUNColors.neutral200,
                        shape: BoxShape.circle,
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            )
                          : Center(
                              child: Text(
                                '${index + 1}',
                                style: ESUNTypography.labelSmall.copyWith(
                                  color: isActive
                                      ? Colors.white
                                      : ESUNColors.textTertiary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                    if (index < steps.length - 1)
                      Container(
                        width: 24,
                        height: 2,
                        color: index < currentIndex
                            ? ESUNColors.primary
                            : ESUNColors.neutral200,
                      ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case DataLinkingStep.intro:
        return _IntroStep(
          onLinkNow: _nextStep,
          onDoItLater: widget.onDoItLater,
        );
      case DataLinkingStep.accountAggregatorConsent:
        return _AAConsentStep(
          isConsented: _aaConsentGiven,
          onConsentChanged: (value) {
            setState(() => _aaConsentGiven = value);
          },
          onContinue: _aaConsentGiven ? _nextStep : null,
          onSkip: widget.onDoItLater,
        );
      case DataLinkingStep.creditBureauConsent:
        return _CreditBureauConsentStep(
          isConsented: _creditBureauConsentGiven,
          onConsentChanged: (value) {
            setState(() => _creditBureauConsentGiven = value);
          },
          onContinue: _creditBureauConsentGiven ? _nextStep : null,
          onSkip: _nextStep, // Can skip credit bureau consent
        );
      case DataLinkingStep.summary:
        return _SummaryStep(
          aaConsented: _aaConsentGiven,
          creditBureauConsented: _creditBureauConsentGiven,
          onLinkNow: widget.onLinkNow,
          onDoItLater: widget.onDoItLater,
        );
    }
  }
}

/// Intro step explaining why data linking matters
class _IntroStep extends StatelessWidget {
  final VoidCallback onLinkNow;
  final VoidCallback onDoItLater;

  const _IntroStep({
    required this.onLinkNow,
    required this.onDoItLater,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESUNSpacing.xl),
      child: Column(
        children: [
          // Hero image/icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [ESUNColors.primary, ESUNColors.primary700],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: ESUNColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.link_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: ESUNSpacing.xl),

          Text(
            'Connect Your\nFinancial Accounts',
            textAlign: TextAlign.center,
            style: ESUNTypography.headlineLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: ESUNColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),

          Text(
            'Get personalized financial insights by securely linking your bank accounts and credit information.',
            textAlign: TextAlign.center,
            style: ESUNTypography.bodyLarge.copyWith(
              color: ESUNColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: ESUNSpacing.xxl),

          // Benefits
          _BenefitCard(
            icon: Icons.psychology_rounded,
            title: 'AI-Powered Insights',
            description:
                'KANTA analyzes your spending patterns and gives personalized advice.',
            gradient: [const Color(0xFF4A62B8), const Color(0xFF2E4A9A)],
          ),
          const SizedBox(height: ESUNSpacing.md),
          _BenefitCard(
            icon: Icons.account_balance_rounded,
            title: 'All Accounts in One Place',
            description:
                'View balances from all your banks in a single dashboard.',
            gradient: [const Color(0xFF11998E), const Color(0xFF38EF7D)],
          ),
          const SizedBox(height: ESUNSpacing.md),
          _BenefitCard(
            icon: Icons.trending_up_rounded,
            title: 'Credit Score Monitoring',
            description:
                'Track your credit score and get tips to improve it.',
            gradient: [const Color(0xFFFC466B), const Color(0xFF3F5EFB)],
          ),
          const SizedBox(height: ESUNSpacing.xxl),

          // CTAs
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onLinkNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: ESUNColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.link_rounded),
                  SizedBox(width: 8),
                  Text(
                    'Link Data Now',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: TextButton(
              onPressed: onDoItLater,
              style: TextButton.styleFrom(
                foregroundColor: ESUNColors.textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Do it later — go to Dashboard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Benefit card widget
class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;

  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ESUNColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ESUNTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ESUNColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: ESUNTypography.bodySmall.copyWith(
                    color: ESUNColors.textSecondary,
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

/// Account Aggregator consent step
class _AAConsentStep extends StatelessWidget {
  final bool isConsented;
  final Function(bool) onConsentChanged;
  final VoidCallback? onContinue;
  final VoidCallback onSkip;

  const _AAConsentStep({
    required this.isConsented,
    required this.onConsentChanged,
    required this.onContinue,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESUNSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: ESUNColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: ESUNColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: ESUNSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Aggregator',
                      style: ESUNTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ESUNColors.textPrimary,
                      ),
                    ),
                    Text(
                      'RBI Regulated Framework',
                      style: ESUNTypography.bodySmall.copyWith(
                        color: ESUNColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.xl),

          Text(
            'What is Account Aggregator?',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: ESUNColors.textPrimary,
            ),
          ),
          const SizedBox(height: ESUNSpacing.sm),
          Text(
            'Account Aggregator (AA) is an RBI-regulated framework that lets you securely share your financial data with ESUN. Your data is encrypted and you remain in full control.',
            style: ESUNTypography.bodyMedium.copyWith(
              color: ESUNColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),

          // What we access
          _ConsentSection(
            title: 'What data will be accessed',
            items: const [
              'Bank account statements (last 12 months)',
              'Account balances and transaction history',
              'Deposit and investment account details',
            ],
            icon: Icons.visibility_rounded,
            color: ESUNColors.primary,
          ),
          const SizedBox(height: ESUNSpacing.md),

          // Security
          _ConsentSection(
            title: 'How your data is protected',
            items: const [
              'End-to-end encryption',
              'No data stored without your consent',
              'Revoke access anytime from settings',
              'Data deleted when consent expires',
            ],
            icon: Icons.shield_rounded,
            color: ESUNColors.success,
          ),
          const SizedBox(height: ESUNSpacing.xl),

          // Consent checkbox
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.md),
            decoration: BoxDecoration(
              color: isConsented
                  ? ESUNColors.success.withOpacity(0.05)
                  : ESUNColors.neutral100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isConsented
                    ? ESUNColors.success.withOpacity(0.3)
                    : ESUNColors.neutral300,
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: isConsented,
                  onChanged: (value) => onConsentChanged(value ?? false),
                  activeColor: ESUNColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Expanded(
                  child: Text(
                    'I consent to share my bank account data via Account Aggregator for personalized financial insights.',
                    style: ESUNTypography.bodyMedium.copyWith(
                      color: ESUNColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ESUNSpacing.xl),

          // Continue button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: ESUNColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: ESUNColors.neutral300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),

          // Skip option
          Center(
            child: TextButton(
              onPressed: onSkip,
              child: Text(
                'Do it later — go to Dashboard',
                style: ESUNTypography.bodyMedium.copyWith(
                  color: ESUNColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Credit Bureau consent step
class _CreditBureauConsentStep extends StatelessWidget {
  final bool isConsented;
  final Function(bool) onConsentChanged;
  final VoidCallback? onContinue;
  final VoidCallback onSkip;

  const _CreditBureauConsentStep({
    required this.isConsented,
    required this.onConsentChanged,
    required this.onContinue,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESUNSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: ESUNColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.credit_score_rounded,
                  color: ESUNColors.warning,
                  size: 28,
                ),
              ),
              const SizedBox(width: ESUNSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Credit Bureau',
                      style: ESUNTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ESUNColors.textPrimary,
                      ),
                    ),
                    Text(
                      'CIBIL / Experian',
                      style: ESUNTypography.bodySmall.copyWith(
                        color: ESUNColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.xl),

          Text(
            'Why check your credit score?',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: ESUNColors.textPrimary,
            ),
          ),
          const SizedBox(height: ESUNSpacing.sm),
          Text(
            'Your credit score affects loan eligibility and interest rates. Monitoring it helps you improve your financial health and get better deals.',
            style: ESUNTypography.bodyMedium.copyWith(
              color: ESUNColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),

          // What we access
          _ConsentSection(
            title: 'What data will be accessed',
            items: const [
              'Your credit score and history',
              'Active loans and credit cards',
              'Payment history and defaults',
              'Credit enquiries',
            ],
            icon: Icons.visibility_rounded,
            color: ESUNColors.warning,
          ),
          const SizedBox(height: ESUNSpacing.md),

          // Benefits
          _ConsentSection(
            title: 'Benefits',
            items: const [
              'Free monthly credit score updates',
              'Personalized loan recommendations',
              'Tips to improve your score',
              'Alert on credit score changes',
            ],
            icon: Icons.star_rounded,
            color: ESUNColors.success,
          ),
          const SizedBox(height: ESUNSpacing.xl),

          // Optional badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ESUNSpacing.md,
              vertical: ESUNSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: ESUNColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: ESUNColors.info,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This step is optional. You can skip and enable it later.',
                    style: ESUNTypography.bodySmall.copyWith(
                      color: ESUNColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),

          // Consent checkbox
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.md),
            decoration: BoxDecoration(
              color: isConsented
                  ? ESUNColors.success.withOpacity(0.05)
                  : ESUNColors.neutral100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isConsented
                    ? ESUNColors.success.withOpacity(0.3)
                    : ESUNColors.neutral300,
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: isConsented,
                  onChanged: (value) => onConsentChanged(value ?? false),
                  activeColor: ESUNColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Expanded(
                  child: Text(
                    'I consent to fetch my credit report from CIBIL/Experian for credit score monitoring.',
                    style: ESUNTypography.bodyMedium.copyWith(
                      color: ESUNColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ESUNSpacing.xl),

          // Continue button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onContinue ?? onSkip,
              style: ElevatedButton.styleFrom(
                backgroundColor: ESUNColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                isConsented ? 'Continue' : 'Skip for Now',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Consent section widget
class _ConsentSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;

  const _ConsentSection({
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: ESUNTypography.labelLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.sm),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: color.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: ESUNTypography.bodySmall.copyWith(
                          color: ESUNColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

/// Summary step before linking
class _SummaryStep extends StatelessWidget {
  final bool aaConsented;
  final bool creditBureauConsented;
  final VoidCallback onLinkNow;
  final VoidCallback onDoItLater;

  const _SummaryStep({
    required this.aaConsented,
    required this.creditBureauConsented,
    required this.onLinkNow,
    required this.onDoItLater,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESUNSpacing.xl),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: ESUNColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 60,
              color: ESUNColors.success,
            ),
          ),
          const SizedBox(height: ESUNSpacing.xl),

          Text(
            'Ready to Link!',
            style: ESUNTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: ESUNColors.textPrimary,
            ),
          ),
          const SizedBox(height: ESUNSpacing.sm),
          Text(
            'Here\'s a summary of what you\'re linking:',
            style: ESUNTypography.bodyMedium.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
          const SizedBox(height: ESUNSpacing.xl),

          // Summary cards
          _SummaryCard(
            icon: Icons.account_balance_rounded,
            title: 'Bank Accounts via AA',
            isEnabled: aaConsented,
            description: aaConsented
                ? 'Will fetch your bank statements'
                : 'Not enabled',
          ),
          const SizedBox(height: ESUNSpacing.md),
          _SummaryCard(
            icon: Icons.credit_score_rounded,
            title: 'Credit Bureau',
            isEnabled: creditBureauConsented,
            description: creditBureauConsented
                ? 'Will fetch your credit score'
                : 'Not enabled',
          ),
          const SizedBox(height: ESUNSpacing.xxl),

          // CTAs
          if (aaConsented) ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onLinkNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ESUNColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.link_rounded),
                    SizedBox(width: 8),
                    Text(
                      'Link Data Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: ESUNSpacing.md),
          ],

          SizedBox(
            width: double.infinity,
            height: 56,
            child: aaConsented
                ? TextButton(
                    onPressed: onDoItLater,
                    style: TextButton.styleFrom(
                      foregroundColor: ESUNColors.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Do it later — go to Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  )
                : ElevatedButton(
                    onPressed: onDoItLater,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ESUNColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Go to Dashboard',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Summary card widget
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isEnabled;
  final String description;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.isEnabled,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled
              ? ESUNColors.success.withOpacity(0.3)
              : ESUNColors.neutral300,
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isEnabled
                  ? ESUNColors.success.withOpacity(0.1)
                  : ESUNColors.neutral100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isEnabled ? ESUNColors.success : ESUNColors.textTertiary,
              size: 24,
            ),
          ),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ESUNTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ESUNColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: ESUNTypography.bodySmall.copyWith(
                    color: isEnabled
                        ? ESUNColors.success
                        : ESUNColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (isEnabled)
            const Icon(
              Icons.check_circle_rounded,
              color: ESUNColors.success,
              size: 24,
            )
          else
            Icon(
              Icons.remove_circle_outline_rounded,
              color: ESUNColors.textTertiary,
              size: 24,
            ),
        ],
      ),
    );
  }
}
