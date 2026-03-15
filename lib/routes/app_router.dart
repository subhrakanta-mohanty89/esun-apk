/// ESUN Router Configuration
/// 
/// GoRouter setup with nested navigation and guards.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/app_state.dart';
import '../features/shell/main_shell.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/onboarding_identity.dart';
import '../features/onboarding/onboarding_verify.dart';
import '../features/onboarding/feature_intro_screen.dart';
import '../features/auth/auth_screens.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/home/home_screen.dart';
import '../features/payments/payments_screen.dart';
import '../features/payments/qr_scanner_screen.dart';
import '../features/payments/payment_history_screen.dart';
import '../features/invest/invest_screen.dart';
import '../features/discover/discover_screen.dart';
import '../features/advisor/advisor_screen.dart';
import '../features/experts/experts_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/alerts/alerts_screen.dart';
import '../features/search/search_screen.dart';
import '../features/borrow/borrow_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/data_connections_screen.dart';
import '../features/goals/goals_screen.dart';
import '../features/budgets/budgets_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/advisor/cfo_advisor_screen.dart';
import '../features/aa_onboarding/aa_onboarding_screens.dart';
import '../features/installation_flow/installation_flow_screen.dart';
import '../features/installation_flow/permissions_screen.dart';
import '../features/installation_flow/data_linking_screen.dart';
import '../features/rewards/rewards_screen.dart';
import '../features/calculators/calculators_screen.dart';
import '../features/net_worth/net_worth_screen.dart';
import '../shared/widgets/remind_me_later_dialog.dart';
import '../services/reminder_service.dart';

import 'app_routes.dart';

/// Global navigation key - exposed for session expiry handling
final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final settings = ref.watch(appSettingsProvider);
  
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: _RouterRefreshNotifier(ref),
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final currentPath = state.uri.path;
      
      // Don't redirect during loading
      if (isLoading) return null;
      
      // Splash screen handles initial routing
      if (currentPath == AppRoutes.splash) return null;
      
      // Auth routes - login, registration, OTP verification, password reset
      final isAuthRoute = currentPath == AppRoutes.login ||
          currentPath == AppRoutes.otp ||
          currentPath == AppRoutes.forgotPassword ||
          currentPath == AppRoutes.resetPassword ||
          currentPath == '/onboarding/details';
      
      // Feature intro and verify are allowed for unauthenticated users
      final isFeatureIntro = currentPath == AppRoutes.featureIntro;
      final isVerifyScreen = currentPath == AppRoutes.onboardingVerify;
      
      // Redirect to login if not authenticated and not on auth route, feature intro, or verify screen
      if (!isAuthenticated && !isAuthRoute && !isFeatureIntro && !isVerifyScreen) {
        return AppRoutes.login;
      }
      
      // Redirect to payments if authenticated and trying to access auth routes
      // But NOT if on feature intro or verify screen (they handle their own navigation)
      if (isAuthenticated && isAuthRoute && !isFeatureIntro && !isVerifyScreen) {
        return AppRoutes.payments;
      }
      
      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Installation Flow (New User Journey)
      GoRoute(
        path: AppRoutes.installationFlow,
        builder: (context, state) {
          final startStep = state.uri.queryParameters['step'];
          return InstallationFlowScreen(startStep: startStep);
        },
      ),
      GoRoute(
        path: AppRoutes.installationPermissions,
        builder: (context, state) => PermissionsScreen(
          onComplete: (granted) {
            context.go(AppRoutes.installationDataLinking);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.installationDataLinking,
        builder: (context, state) => DataLinkingScreen(
          onLinkNow: () => context.go(AppRoutes.aaVerifyPan),
          onDoItLater: () async {
            // Show remind me later dialog
            final result = await showRemindMeLaterDialog(
              context,
              reminderType: ReminderType.accountAggregator,
            );
            // Navigate to home regardless of result
            if (context.mounted) {
              context.go(AppRoutes.payments);
            }
          },
        ),
      ),
      
      // Onboarding / Registration - go directly to registration form
      GoRoute(
        path: '/onboarding/details',
        builder: (context, state) => const OnboardingIdentityScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingVerify,
        builder: (context, state) {
          final data = state.extra as OnboardingUserData?;
          return OnboardingVerifyScreen(data: data);
        },
      ),
      GoRoute(
        path: AppRoutes.featureIntro,
        builder: (context, state) => const FeatureIntroScreen(),
      ),
      
      // Auth Routes
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) {
          final identifier = state.extra as String? ?? '';
          return OtpScreen(identifier: identifier);
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) {
          final identifier = state.extra as String? ?? '';
          return ResetPasswordScreen(identifier: identifier);
        },
      ),
      GoRoute(
        path: AppRoutes.biometricUnlock,
        builder: (context, state) => const BiometricUnlockScreen(),
      ),
      
      // AA Onboarding Routes (Account Aggregator)
      GoRoute(
        path: AppRoutes.aaVerifyPan,
        builder: (context, state) => const AAVerifyPanScreen(),
      ),
      GoRoute(
        path: AppRoutes.aaActivateTracker,
        builder: (context, state) => const AAActivateTrackerScreen(),
      ),
      GoRoute(
        path: AppRoutes.aaVerifyOtp,
        builder: (context, state) => const AAVerifyOtpScreen(),
      ),
      GoRoute(
        path: AppRoutes.aaSelectBanks,
        builder: (context, state) => const AASelectBanksScreen(),
      ),
      GoRoute(
        path: AppRoutes.aaDiscoverAccounts,
        builder: (context, state) => const AADiscoverAccountsScreen(),
      ),
      GoRoute(
        path: AppRoutes.aaReviewConsent,
        builder: (context, state) => const AAReviewConsentScreen(),
      ),
      GoRoute(
        path: AppRoutes.aaFinalStepConsent,
        builder: (context, state) => const AAFinalStepConsentScreen(),
      ),
      GoRoute(
        path: AppRoutes.aaAnalyzing,
        builder: (context, state) => const AAAnalyzingScreen(),
      ),
      GoRoute(
        path: AppRoutes.aaFinancialHealthDashboard,
        builder: (context, state) => const AAFinancialHealthDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.aaConnecting,
        builder: (context, state) => const AAConnectingScreen(),
      ),
      GoRoute(
        path: AppRoutes.aaSuccess,
        builder: (context, state) => const AASuccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.aaDeclined,
        builder: (context, state) => const AADeclinedScreen(),
      ),
      GoRoute(
        path: AppRoutes.aaFailure,
        builder: (context, state) => const AAFailureScreen(),
      ),
      GoRoute(
        path: AppRoutes.aaRenewConsents,
        builder: (context, state) => const AARenewConsentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.aaMyConsents,
        builder: (context, state) => const AAMyConsentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.aaProfile,
        builder: (context, state) => const AAProfileScreen(),
      ),
      
      // Main Shell with Bottom Navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          // Home
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
            routes: [
              GoRoute(
                path: 'financial-health',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Financial Health Details')),
                ),
              ),
              GoRoute(
                path: 'cashflow',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Cashflow Analysis')),
                ),
              ),
              GoRoute(
                path: 'insights',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Insights')),
                ),
              ),
            ],
          ),
          
          // Payments
          GoRoute(
            path: AppRoutes.payments,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PaymentsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'send',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Send Money')),
                ),
              ),
              GoRoute(
                path: 'request',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Request Money')),
                ),
              ),
              GoRoute(
                path: 'scan',
                builder: (context, state) => const QRScannerScreen(),
              ),
              GoRoute(
                path: 'history',
                builder: (context, state) => const PaymentHistoryScreen(),
              ),
              GoRoute(
                path: 'transaction/:id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return Scaffold(
                    body: Center(child: Text('Transaction: $id')),
                  );
                },
              ),
            ],
          ),
          
          // Invest
          GoRoute(
            path: AppRoutes.invest,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: InvestScreen(),
            ),
            routes: [
              GoRoute(
                path: 'portfolio',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Portfolio')),
                ),
              ),
              GoRoute(
                path: 'sip',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('SIP Manager')),
                ),
              ),
              GoRoute(
                path: 'mutual-funds',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Mutual Funds')),
                ),
              ),
              GoRoute(
                path: 'mutual-funds/:id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return Scaffold(
                    body: Center(child: Text('Fund: $id')),
                  );
                },
              ),
              GoRoute(
                path: 'stocks',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Stocks')),
                ),
              ),
              GoRoute(
                path: 'gold',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Digital Gold')),
                ),
              ),
            ],
          ),
          
          // Discover
          GoRoute(
            path: AppRoutes.discover,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DiscoverScreen(),
            ),
            routes: [
              GoRoute(
                path: ':category',
                builder: (context, state) {
                  final category = state.pathParameters['category']!;
                  return Scaffold(
                    body: Center(child: Text('Category: $category')),
                  );
                },
              ),
              GoRoute(
                path: 'product/:id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return Scaffold(
                    body: Center(child: Text('Product: $id')),
                  );
                },
              ),
            ],
          ),
          
          // Advisor (CFO AI)
          GoRoute(
            path: AppRoutes.advisor,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CFOAdvisorScreen(),
            ),
            routes: [
              GoRoute(
                path: 'chat',
                builder: (context, state) => const CFOAdvisorScreen(),
              ),
              GoRoute(
                path: 'voice',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Voice Assistant')),
                ),
              ),
              GoRoute(
                path: 'report',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Weekly Report')),
                ),
              ),
            ],
          ),
          
          // Experts
          GoRoute(
            path: AppRoutes.experts,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ExpertsScreen(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return Scaffold(
                    body: Center(child: Text('Expert: $id')),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'book',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return Scaffold(
                        body: Center(child: Text('Book Expert: $id')),
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'sessions',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Upcoming Sessions')),
                ),
              ),
            ],
          ),
        ],
      ),
      
      // Full-screen routes (outside shell)
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.dataConnections,
        builder: (context, state) => const DataConnectionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.alerts,
        builder: (context, state) => const AlertsScreen(),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.borrow,
        builder: (context, state) => const BorrowScreen(),
        routes: [
          GoRoute(
            path: 'eligibility',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Loan Eligibility')),
            ),
          ),
          GoRoute(
            path: 'emi-calculator',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('EMI Calculator')),
            ),
          ),
          GoRoute(
            path: 'credit-score',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Credit Score')),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.goals,
        builder: (context, state) => const GoalsScreen(),
      ),
      GoRoute(
        path: AppRoutes.budgets,
        builder: (context, state) => const BudgetsScreen(),
      ),
      GoRoute(
        path: AppRoutes.netWorth,
        builder: (context, state) => const NetWorthScreen(),
      ),
      GoRoute(
        path: AppRoutes.netWorthDetails,
        builder: (context, state) => const NetWorthDetailsScreen(),
      ),
      // Rewards
      GoRoute(
        path: AppRoutes.rewards,
        builder: (context, state) => const RewardsScreen(),
      ),
      // Coach / Financial Tools
      GoRoute(
        path: AppRoutes.calculators,
        builder: (context, state) => const CalculatorsScreen(),
      ),
      GoRoute(
        path: AppRoutes.reports,
        builder: (context, state) => const ReportsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri.path}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.payments),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Refresh notifier for router
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(appSettingsProvider, (_, __) => notifyListeners());
  }
  
  final Ref _ref;
}

/// Navigation Extensions
extension NavigationX on BuildContext {
  void goHome() => go(AppRoutes.home);
  void goPayments() => go(AppRoutes.payments);
  void goInvest() => go(AppRoutes.invest);
  void goDiscover() => go(AppRoutes.discover);
  void goAdvisor() => go(AppRoutes.advisor);
  void goExperts() => go(AppRoutes.experts);
  void goProfile() => push(AppRoutes.profile);
  void goAlerts() => push(AppRoutes.alerts);
  void goSearch() => push(AppRoutes.search);
  void goSettings() => push(AppRoutes.settings);
  void goBorrow() => push(AppRoutes.borrow);
  
  void goTransaction(String id) => push(AppRoutes.transactionDetailsPath(id));
  void goFund(String id) => push(AppRoutes.fundDetailsPath(id));
  void goStock(String id) => push(AppRoutes.stockDetailsPath(id));
  void goExpert(String id) => push(AppRoutes.expertProfilePath(id));
  void goGoal(String id) => push(AppRoutes.goalDetailsPath(id));
  void goBudget(String id) => push(AppRoutes.budgetDetailsPath(id));
}



