/// ESUN Home Screen
/// 
/// Main dashboard showing account overview, quick actions, and insights.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/widgets.dart';
import '../../core/utils/utils.dart';
import '../../shared/widgets/qr_sheet.dart';
import '../profile/profile_screen.dart';
import '../../state/app_state.dart';
import '../../state/aa_data_state.dart';
import '../../state/transaction_state.dart';
import '../../core/analytics/analytics_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // User data loaded from provider
  String get _userName {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    return profile?['full_name'] ?? 'User';
  }
  
  String get _userPhone {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    return profile?['phone_number'] ?? '';
  }
  
  String get _userUpiId {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final name = (profile?['full_name'] ?? 'user').toString().toLowerCase().replaceAll(' ', '.');
    return '$name@ESUN';
  }
  
  String get _userBankLabel {
    final banks = ref.watch(aaDataProvider).bankAccounts;
    if (banks.isNotEmpty) {
      final b = banks.first;
      final last4 = b.accountNumber.length >= 4
          ? b.accountNumber.substring(b.accountNumber.length - 4)
          : b.accountNumber;
      return '${b.bankName} • $last4';
    }
    return 'Link Bank Account';
  }
  final ScrollController _scrollController = ScrollController();
  final PageController _cardPageController = PageController();
  bool _isHeaderCollapsed = false;
  bool _isBalanceHidden = false;
  bool _isNetWorthHidden = false;
  int _currentCardIndex = 0;
  bool _hasShownOnboardingPopup = false;
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Check data linking status after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDataLinkingStatus();
      _refreshAADataIfNeeded();
    });
  }
  
  /// Refresh AA data from server if user has AA connected
  void _refreshAADataIfNeeded() {
    final authState = ref.read(authStateProvider);
    
    // Fetch real data from server if AA is connected
    if (authState.status == AuthStatus.authenticated && authState.aaConnected) {
      ref.read(aaDataProvider.notifier).fetchAllData();
    }
    // Mock data is already loaded by provider initialization
  }
  
  void _checkDataLinkingStatus() {
    if (_hasShownOnboardingPopup) return;
    
    final authState = ref.read(authStateProvider);
    
    // Show popup only if user has NOT onboarded (not linked AA or Credit Bureau)
    // Once onboarded (either AA or CB connected), don't show popup again
    final needsLinking = !authState.isOnboarded;
    final notDismissed = !authState.linkDataPopupDismissed;
    
    if (needsLinking && notDismissed && authState.status == AuthStatus.authenticated) {
      _hasShownOnboardingPopup = true;
      _showLinkDataPopup(authState);
    }
  }
  
  void _showLinkDataPopup(AuthState authState) {
    // Log popup shown
    ref.read(analyticsServiceProvider).logLinkDataPopupShown(
      aaConnected: authState.aaConnected,
      creditBureauConnected: authState.creditBureauConnected,
    );
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: ESUNRadius.lgRadius,
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ESUNColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.link_rounded,
                color: ESUNColors.primary,
              ),
            ),
            const SizedBox(width: ESUNSpacing.md),
            const Expanded(
              child: Text('Link Your Data'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connect your financial data to unlock personalized insights and better recommendations.',
              style: ESUNTypography.bodyMedium.copyWith(
                color: ESUNColors.textSecondary,
              ),
            ),
            const SizedBox(height: ESUNSpacing.xl),
            
            // Account Aggregator Button
            if (!authState.aaConnected)
              _buildLinkOptionCard(
                icon: Icons.account_balance_outlined,
                title: 'Link Account Aggregator',
                subtitle: 'Connect your bank accounts securely',
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  ref.read(analyticsServiceProvider).logLinkDataAction(
                    AnalyticsEvents.linkAccountAggregatorClicked,
                  );
                  context.push(AppRoutes.aaVerifyPan);
                },
              ),
            
            if (!authState.aaConnected && !authState.creditBureauConnected)
              const SizedBox(height: ESUNSpacing.md),
            
            // Credit Bureau Button
            if (!authState.creditBureauConnected)
              _buildLinkOptionCard(
                icon: Icons.credit_score_outlined,
                title: 'Link Credit Bureau',
                subtitle: 'Get your credit score and report',
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  ref.read(analyticsServiceProvider).logLinkDataAction(
                    AnalyticsEvents.linkCreditBureauClicked,
                  );
                  // Navigate to credit bureau flow (uses data linking screen)
                  context.push(AppRoutes.installationDataLinking);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(analyticsServiceProvider).logLinkDataAction(
                AnalyticsEvents.remindMeLaterClicked,
              );
              ref.read(authStateProvider.notifier).dismissLinkDataPopup();
            },
            child: Text(
              'Remind me later',
              style: TextStyle(color: ESUNColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLinkOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: ESUNRadius.mdRadius,
      child: Container(
        padding: const EdgeInsets.all(ESUNSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: ESUNColors.border),
          borderRadius: ESUNRadius.mdRadius,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ESUNColors.primary.withValues(alpha: 0.1),
                borderRadius: ESUNRadius.smRadius,
              ),
              child: Icon(icon, color: ESUNColors.primary, size: 24),
            ),
            const SizedBox(width: ESUNSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ESUNTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: ESUNTypography.bodySmall.copyWith(
                      color: ESUNColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: ESUNColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
  
  void _onScroll() {
    final isCollapsed = _scrollController.offset > 120;
    if (isCollapsed != _isHeaderCollapsed) {
      setState(() => _isHeaderCollapsed = isCollapsed);
    }
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _cardPageController.dispose();
    super.dispose();
  }
  
  String _getGreeting() {
    final hour = DateTime.now().hour;
    final firstName = _userName.split(' ').first;
    String greeting;
    if (hour >= 5 && hour < 12) {
      greeting = 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      greeting = 'Good Evening';
    } else {
      greeting = 'Good Night';
    }
    return '$greeting, $firstName!';
  }
  
  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : 'U';
    return (parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '') + 
           (parts[1].isNotEmpty ? parts[1][0].toUpperCase() : '');
  }
  
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return '${(difference.inDays / 7).floor()} week${(difference.inDays / 7).floor() > 1 ? 's' : ''} ago';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? ESUNColors.darkBackground : ESUNColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar
          _buildAppBar(context, isDark),
          
          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance Card
                _buildBalanceCard(context),
                
                // Quick Actions
                _buildQuickActions(context),
                
                // Rewards Banner
                _buildRewardsBanner(context),
                
                // AI Insights Banner
                _buildAIInsightsBanner(context),
                
                // Coach Kantha - Financial Tools
                _buildCoachModules(context),
                
                // Financial Health Score
                _buildHealthScore(context),
                
                // Linking Status Badge (shows when data not linked or has errors)
                const LinkingStatusBadge(),
                
                // Data Connections Status Card
                _buildDataConnectionsCard(context),
                
                // Recent Transactions
                _buildRecentTransactions(context),
                
                // Spending Categories Breakdown
                _buildSpendingCategories(context),
                
                // Monthly Overview
                _buildMonthlyOverview(context),
                
                // Goals Progress
                _buildGoalsProgress(context),
                
                // Promotions
                _buildPromotions(context),
                
                const SizedBox(height: 72),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppBar(BuildContext context, bool isDark) {
    // Get AA data for dynamic balance in collapsed header
    final aaData = ref.watch(aaDataProvider);
    final assets = aaData.assetBreakdown ?? AssetBreakdown.mock;
    final bankBalance = assets.bankBalance > 0
        ? assets.bankBalance
        : aaData.bankAccounts.fold<double>(0, (sum, a) => sum + a.balance);
    
    return SliverAppBar(
      expandedHeight: 80,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: _showProfileSheet,
          child: CircleAvatar(
            backgroundColor: ESUNColors.primary.withOpacity(0.1),
            child: Text(_getInitials(_userName), style: const TextStyle(color: ESUNColors.primary)),
          ),
        ),
      ),
      title: AnimatedOpacity(
        opacity: _isHeaderCollapsed ? 1.0 : 0.0,
        duration: ESUNAnimations.fast,
        child: Text(
          _isBalanceHidden ? '₹••••••' : bankBalance.toINR(),
          style: ESUNTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      actions: [
        // Expert Support Button - Prominent placement
        _buildSupportButton(context),
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () => context.push(AppRoutes.search),
        ),
        IconButton(
          icon: Badge(
            smallSize: 8,
            child: const Icon(Icons.notifications_outlined),
          ),
          onPressed: () => context.push(AppRoutes.alerts),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: ESUNTypography.bodyMedium.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildBalanceCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg, vertical: ESUNSpacing.sm),
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: PageView(
              controller: _cardPageController,
              onPageChanged: (index) {
                setState(() => _currentCardIndex = index);
              },
              children: [
                _buildTotalBalanceCard(),
                _buildNetWorthCard(),
              ],
            ),
          ),
          const SizedBox(height: ESUNSpacing.sm),
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPageIndicator(0),
              const SizedBox(width: 8),
              _buildPageIndicator(1),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPageIndicator(int index) {
    final isActive = _currentCardIndex == index;
    return GestureDetector(
      onTap: () {
        _cardPageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isActive ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: isActive ? ESUNColors.primary : ESUNColors.primary.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
  
  Widget _buildTotalBalanceCard() {
    // Get AA data for bank balance display
    final aaData = ref.watch(aaDataProvider);
    final assets = aaData.assetBreakdown ?? AssetBreakdown.mock;
    final bankBalance = assets.bankBalance > 0
        ? assets.bankBalance
        : aaData.bankAccounts.fold<double>(0, (sum, a) => sum + a.balance);
    
    // Get transaction state for spending data
    final monthSpending = ref.watch(monthSpendingProvider);
    
    // Calculate monthly income (credits) vs expenses
    final monthIncome = 120000.0; // From salary etc.
    
    // Format amounts for display
    String formatAmount(double amount) {
      if (amount >= 100000) {
        return '₹${(amount / 100000).toStringAsFixed(1)}L';
      } else if (amount >= 1000) {
        return '₹${(amount / 1000).toStringAsFixed(1)}K';
      }
      return '₹${amount.toStringAsFixed(0)}';
    }
    
    return FPGradientCard(
      gradient: ESUNColors.heroCardGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: ESUNRadius.smRadius,
                    ),
                    child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Total Balance',
                    style: ESUNTypography.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => setState(() => _isBalanceHidden = !_isBalanceHidden),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: ESUNRadius.fullRadius,
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isBalanceHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isBalanceHidden ? 'Show' : 'Hide',
                        style: ESUNTypography.labelSmall.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          Text(
            _isBalanceHidden ? '₹••••••' : bankBalance.toINR(),
            style: ESUNTypography.amountLarge.copyWith(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ESUNColors.success.withOpacity(0.3),
                  borderRadius: ESUNRadius.fullRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '+12.5% this month',
                      style: ESUNTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          // Income / Expense Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: ESUNRadius.mdRadius,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Expanded(child: _buildBalanceChip(Icons.arrow_upward_rounded, 'Income', _isBalanceHidden ? '₹••••' : formatAmount(monthIncome), const Color(0xFF4ADE80))),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.white.withOpacity(0.2),
                ),
                Expanded(child: _buildBalanceChip(Icons.arrow_downward_rounded, 'Spent', _isBalanceHidden ? '₹••••' : formatAmount(monthSpending), const Color(0xFFFB7185))),
              ],
            ),
          ),
          const Spacer(),
          // Account Indicators
          Row(
            children: [
              _buildAccountDot('HDFC', const Color(0xFF60A5FA)),
              const SizedBox(width: 8),
              _buildAccountDot('ICICI', const Color(0xFFFBBF24)),
              const SizedBox(width: 8),
              _buildAccountDot('SBI', const Color(0xFF34D399)),
              const Spacer(),
              GestureDetector(
                onTap: () => _showAccountsSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: ESUNRadius.fullRadius,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '3 Accounts',
                        style: ESUNTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildNetWorthCard() {
    // Get AA data for net worth display
    final aaData = ref.watch(aaDataProvider);
    final snapshot = aaData.snapshot ?? FinancialSnapshot.mock;
    final assets = aaData.assetBreakdown ?? AssetBreakdown.mock;
    
    // Format the net worth value
    String formatAmount(double amount) {
      if (amount >= 10000000) {
        return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
      } else if (amount >= 100000) {
        return '₹${(amount / 100000).toStringAsFixed(2)} L';
      } else if (amount >= 1000) {
        return '₹${(amount / 1000).toStringAsFixed(1)} K';
      }
      return '₹${amount.toStringAsFixed(0)}';
    }
    
    // Calculate asset percentages
    final totalAssets = assets.total;
    final mfPerc = totalAssets > 0 ? ((assets.mutualFunds / totalAssets) * 100).toStringAsFixed(0) : '0';
    final stocksPerc = totalAssets > 0 ? ((assets.stocks / totalAssets) * 100).toStringAsFixed(0) : '0';
    final bankPerc = totalAssets > 0 ? ((assets.bankBalance / totalAssets) * 100).toStringAsFixed(0) : '0';
    final othersPerc = totalAssets > 0 ? (((assets.etfs + assets.fixedDeposits + assets.gold) / totalAssets) * 100).toStringAsFixed(0) : '0';
    
    return GestureDetector(
      onTap: () => context.push(AppRoutes.invest),
      child: AnimatedOpacity(
        duration: ESUNAnimations.fast,
        opacity: _isNetWorthHidden ? 0.55 : 1,
        child: FPGradientCard(
          gradient: ESUNColors.heroCardGradient,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: ESUNRadius.smRadius,
                        ),
                        child: const Icon(Icons.pie_chart_outline, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Net Worth',
                        style: ESUNTypography.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.3),
                          borderRadius: ESUNRadius.fullRadius,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.trending_up, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              '+18.2%',
                              style: ESUNTypography.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _isNetWorthHidden = !_isNetWorthHidden),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: ESUNRadius.fullRadius,
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isNetWorthHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isNetWorthHidden ? 'Show' : 'Hide',
                                style: ESUNTypography.labelSmall.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: ESUNSpacing.md),
              Text(
                _isNetWorthHidden ? '₹••••••' : formatAmount(snapshot.netWorth),
                style: ESUNTypography.amountLarge.copyWith(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.update,
                    color: Colors.white.withOpacity(0.7),
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    aaData.lastUpdated != null 
                        ? 'Updated ${_getTimeAgo(aaData.lastUpdated!)}'
                        : 'Updated an hour ago',
                    style: ESUNTypography.labelSmall.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ESUNSpacing.md),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: ESUNRadius.mdRadius,
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildBalanceChip(
                        Icons.trending_up_rounded, 
                        'Assets', 
                        _isNetWorthHidden ? '₹••••' : formatAmount(snapshot.totalAssets), 
                        const Color(0xFF4ADE80),
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    Expanded(
                      child: _buildBalanceChip(
                        Icons.trending_down_rounded, 
                        'Liabilities', 
                        _isNetWorthHidden ? '₹••••' : formatAmount(snapshot.totalLiabilities), 
                        const Color(0xFFFB7185),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  _buildAssetDot('MF', const Color(0xFF60A5FA), '$mfPerc%'),
                  const SizedBox(width: 8),
                  _buildAssetDot('Stocks', const Color(0xFFFBBF24), '$stocksPerc%'),
                  const SizedBox(width: 8),
                  _buildAssetDot('Bank', const Color(0xFF34D399), '$bankPerc%'),
                  const SizedBox(width: 8),
                  _buildAssetDot('Others', const Color(0xFFA78BFA), '$othersPerc%'),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.invest),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: ESUNRadius.fullRadius,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Details',
                            style: ESUNTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }
  
  Widget _buildAssetDot(String label, Color color, String percent) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label $percent',
          style: ESUNTypography.labelSmall.copyWith(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
  
  // AA Assets Overview - Beautiful cards showing synced data
  // ignore: unused_element
  Widget _buildAAAssetsOverview(BuildContext context) {
    final aaData = ref.watch(aaDataProvider);
    final snapshot = aaData.snapshot ?? FinancialSnapshot.mock;
    final investments = aaData.investments;
    final bankAccounts = aaData.bankAccounts;
    final fds = aaData.fixedDeposits;
    final insurances = aaData.insurances;
    
    // Calculate investment breakdown
    final equityValue = investments.where((i) => i.type.toLowerCase() == 'stock').fold(0.0, (sum, i) => sum + i.currentValue);
    final mfValue = investments.where((i) => i.type.toLowerCase() == 'mutual_fund').fold(0.0, (sum, i) => sum + i.currentValue);
    final insuranceInvestments = insurances.fold(0.0, (sum, i) => sum + (i.premiumAmount * 12)); // Estimated annual value
    
    final totalInvestmentValue = equityValue + mfValue + insuranceInvestments;
    final totalBankBalance = bankAccounts.fold(0.0, (sum, acc) => sum + acc.balance);
    final totalFDValue = fds.fold(0.0, (sum, fd) => sum + fd.principalAmount);
    final lifeInsuranceValue = insurances.where((i) => i.type.toLowerCase() == 'life' || i.type.toLowerCase() == 'term').fold(0.0, (sum, i) => sum + i.sumAssured);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Assets Hero Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE0E7FF), Color(0xFFC7D2FE), Color(0xFFEDE9FE)],
              ),
              borderRadius: ESUNRadius.lgRadius,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E4A9A).withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Your accounts have synced!',
                      style: ESUNTypography.bodyMedium.copyWith(
                        color: const Color(0xFF374151),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ESUNSpacing.md),
                Text(
                  'Total Assets',
                  style: ESUNTypography.titleMedium.copyWith(
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: ESUNSpacing.xs),
                Text(
                  _formatIndianCurrency(snapshot.totalAssets),
                  style: ESUNTypography.displaySmall.copyWith(
                    color: const Color(0xFF1E3A8A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: ESUNSpacing.lg),
          
          // Asset Cards Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column - Investments
              Expanded(
                child: _buildInvestmentCard(
                  totalValue: totalInvestmentValue,
                  equityValue: equityValue,
                  mfValue: mfValue,
                  insuranceValue: insuranceInvestments,
                ),
              ),
              const SizedBox(width: ESUNSpacing.md),
              // Right Column - Bank Accounts & Deposits
              Expanded(
                child: Column(
                  children: [
                    _buildAssetCard(
                      icon: Icons.account_balance,
                      title: '${bankAccounts.length} Bank accounts',
                      value: totalBankBalance,
                      color: const Color(0xFF4A62B8),
                      bgColor: const Color(0xFFEDE9FE),
                    ),
                    const SizedBox(height: ESUNSpacing.md),
                    _buildAssetCard(
                      icon: Icons.savings,
                      title: 'Deposits (FD&RD)',
                      value: totalFDValue,
                      color: const Color(0xFF2E4A9A),
                      bgColor: const Color(0xFFE0E7FF),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: ESUNSpacing.md),
          
          // Life Insurance Card
          _buildAssetCard(
            icon: Icons.account_balance,
            title: 'Life Insurance',
            value: lifeInsuranceValue,
            color: const Color(0xFF2E4A9A),
            bgColor: const Color(0xFFE0E7FF),
            isFullWidth: true,
          ),
          
          const SizedBox(height: ESUNSpacing.lg),
          
          // Next Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push(AppRoutes.netWorth),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Next',
                style: ESUNTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: ESUNSpacing.lg),
        ],
      ),
    );
  }
  
  Widget _buildInvestmentCard({
    required double totalValue,
    required double equityValue,
    required double mfValue,
    required double insuranceValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: ESUNRadius.lgRadius,
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: ESUNRadius.smRadius,
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: Color(0xFF16A34A),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Investments',
                style: ESUNTypography.bodyMedium.copyWith(
                  color: const Color(0xFF374151),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.sm),
          Text(
            _formatIndianCurrency(totalValue),
            style: ESUNTypography.titleLarge.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          const Divider(height: 1, color: Color(0xFFBBF7D0)),
          const SizedBox(height: ESUNSpacing.sm),
          _buildInvestmentRow('Equity', equityValue),
          const SizedBox(height: 6),
          _buildInvestmentRow('MF', mfValue),
          const SizedBox(height: 6),
          _buildInvestmentRow('Insurance', insuranceValue),
        ],
      ),
    );
  }
  
  Widget _buildInvestmentRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: ESUNTypography.bodySmall.copyWith(
            color: const Color(0xFF6B7280),
          ),
        ),
        Text(
          _formatIndianCurrency(value),
          style: ESUNTypography.bodySmall.copyWith(
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildAssetCard({
    required IconData icon,
    required String title,
    required double value,
    required Color color,
    required Color bgColor,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: ESUNRadius.lgRadius,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: ESUNRadius.smRadius,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: ESUNTypography.bodySmall.copyWith(
                    color: const Color(0xFF374151),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.sm),
          Text(
            _formatIndianCurrency(value),
            style: ESUNTypography.titleMedium.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatIndianCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} L';
    } else {
      // Format with Indian style commas
      final intPart = amount.toInt();
      final formatted = intPart.toString().replaceAllMapped(
        RegExp(r'(\d{1,2})(?=(\d{2})+(\d{1})(?!\d))'),
        (m) => '${m[1]},',
      );
      return '₹$formatted';
    }
  }

  void _showAccountsSheet(BuildContext context) {
    final aaData = ref.read(aaDataProvider);
    final accounts = aaData.bankAccounts;
    final totalBalance = accounts.fold<double>(0, (sum, a) => sum + a.balance);
    
    final accountColors = [
      const Color(0xFF60A5FA),
      const Color(0xFFFBBF24),
      const Color(0xFF34D399),
      const Color(0xFFA78BFA),
      const Color(0xFFFB7185),
    ];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: ESUNSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Linked Accounts',
                  style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  _isBalanceHidden ? '₹••••••' : totalBalance.toINR(),
                  style: ESUNTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ESUNColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ESUNSpacing.lg),
            ...List.generate(accounts.length, (index) {
              final account = accounts[index];
              final color = accountColors[index % accountColors.length];
              return Padding(
                padding: EdgeInsets.only(bottom: index < accounts.length - 1 ? ESUNSpacing.md : 0),
                child: _buildAccountItem(
                  account.bankName,
                  '${account.accountType} A/c •••• ${account.accountNumber.length >= 4 ? account.accountNumber.substring(account.accountNumber.length - 4) : account.accountNumber}',
                  _isBalanceHidden ? '₹••••••' : account.balance.toINR(),
                  color,
                  logoUrl: account.effectiveLogoUrl,
                ),
              );
            }),
            const SizedBox(height: ESUNSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Bank Account'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: ESUNRadius.mdRadius,
                  ),
                ),
              ),
            ),
            const SizedBox(height: ESUNSpacing.lg),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAccountItem(String name, String accountNo, String balance, Color color, {String? logoUrl}) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: ESUNRadius.mdRadius,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: ESUNRadius.smRadius,
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: ClipRRect(
              borderRadius: ESUNRadius.smRadius,
              child: logoUrl != null
                  ? Image.network(
                      logoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.account_balance,
                        color: color,
                        size: 24,
                      ),
                    )
                  : Icon(Icons.account_balance, color: color, size: 24),
            ),
          ),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  accountNo,
                  style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            _isBalanceHidden ? '₹••••••' : balance,
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showScanSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: ESUNSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Scan & Pay',
              style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: ESUNSpacing.xl),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: ESUNColors.surfaceVariant,
                borderRadius: ESUNRadius.lgRadius,
                border: Border.all(color: ESUNColors.primary, width: 3),
              ),
              child: const Center(
                child: Icon(Icons.qr_code_scanner_rounded, size: 80, color: ESUNColors.primary),
              ),
            ),
            const SizedBox(height: ESUNSpacing.lg),
            Text(
              'Point your camera at a QR code',
              style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textSecondary),
            ),
            const SizedBox(height: ESUNSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: ESUNSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.flashlight_on_outlined),
                    label: const Text('Flash'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ESUNSpacing.lg),
          ],
        ),
      ),
    );
  }
  
  void _showBillsSheet(BuildContext context) {
    final bills = [
      ('Electricity', 'BESCOM', '₹1,250', Icons.electric_bolt_rounded, const Color(0xFFF59E0B)),
      ('Water', 'BWSSB', '₹450', Icons.water_drop_rounded, const Color(0xFF06B6D4)),
      ('Gas', 'Indane Gas', '₹980', Icons.local_fire_department_rounded, const Color(0xFFEF4444)),
      ('Internet', 'Airtel Fiber', '₹999', Icons.wifi_rounded, const Color(0xFF4A62B8)),
      ('DTH', 'Tata Play', '₹350', Icons.tv_rounded, const Color(0xFF10B981)),
      ('Insurance', 'LIC Premium', '₹5,000', Icons.shield_rounded, const Color(0xFF2E4A9A)),
    ];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: ESUNSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Bill Payments',
              style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: ESUNSpacing.lg),
            Expanded(
              child: ListView.separated(
                itemCount: bills.length,
                separatorBuilder: (_, __) => const SizedBox(height: ESUNSpacing.sm),
                itemBuilder: (context, index) {
                  final bill = bills[index];
                  return _buildBillItem(bill.$1, bill.$2, bill.$3, bill.$4, bill.$5);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBillItem(String type, String provider, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: ESUNRadius.mdRadius,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: ESUNRadius.smRadius,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                Text(provider, style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.bold, color: color)),
              Text('Due', style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textTertiary)),
            ],
          ),
          const SizedBox(width: ESUNSpacing.sm),
          Icon(Icons.chevron_right, color: color),
        ],
      ),
    );
  }
  
  void _showRechargeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: ESUNSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Recharge & Pay',
              style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: ESUNSpacing.lg),
            Row(
              children: [
                _buildRechargeOption(Icons.phone_android_rounded, 'Mobile', const Color(0xFF10B981)),
                const SizedBox(width: ESUNSpacing.md),
                _buildRechargeOption(Icons.wifi_rounded, 'Broadband', const Color(0xFF2E4A9A)),
                const SizedBox(width: ESUNSpacing.md),
                _buildRechargeOption(Icons.tv_rounded, 'DTH', const Color(0xFFF59E0B)),
                const SizedBox(width: ESUNSpacing.md),
                _buildRechargeOption(Icons.local_gas_station_rounded, 'FASTag', const Color(0xFFEC4899)),
              ],
            ),
            const SizedBox(height: ESUNSpacing.xl),
            Text('Recent Recharges', style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: ESUNSpacing.md),
            _buildRecentRecharge('+91 98765 43210', 'Jio Prepaid', '₹299'),
            const SizedBox(height: ESUNSpacing.sm),
            _buildRecentRecharge('+91 87654 32109', 'Airtel Prepaid', '₹199'),
            const SizedBox(height: ESUNSpacing.lg),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRechargeOption(IconData icon, String label, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.md),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: ESUNRadius.mdRadius,
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: ESUNSpacing.xs),
              Text(label, style: ESUNTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRecentRecharge(String number, String operator, String amount) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: ESUNColors.surfaceVariant,
        borderRadius: ESUNRadius.mdRadius,
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: ESUNColors.primary,
            radius: 18,
            child: Icon(Icons.phone, color: Colors.white, size: 18),
          ),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(number, style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w500)),
                Text(operator, style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: ESUNTypography.labelSmall,
            ),
            child: Text(amount),
          ),
        ],
      ),
    );
  }
  
  void _showCardsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: ESUNSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'My Cards',
              style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: ESUNSpacing.lg),
            _buildCreditCard('HDFC Credit Card', '•••• •••• •••• 4532', '₹85,000', const Color(0xFF2E4A9A)),
            const SizedBox(height: ESUNSpacing.md),
            _buildCreditCard('ICICI Amazon Pay', '•••• •••• •••• 7891', '₹1,20,000', const Color(0xFFEC4899)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.add),
                label: const Text('Add New Card'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: ESUNSpacing.lg),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCreditCard(String name, String number, String limit, Color color) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
        borderRadius: ESUNRadius.lgRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: ESUNTypography.titleSmall.copyWith(color: Colors.white)),
              const Icon(Icons.credit_card, color: Colors.white),
            ],
          ),
          const SizedBox(height: ESUNSpacing.lg),
          Text(number, style: ESUNTypography.titleLarge.copyWith(color: Colors.white, letterSpacing: 2)),
          const SizedBox(height: ESUNSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Credit Limit', style: ESUNTypography.labelSmall.copyWith(color: Colors.white70)),
              Text(_isBalanceHidden ? '₹••••' : limit, style: ESUNTypography.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
  
  // ignore: unused_element
  void _showMoreSheet(BuildContext context) {
    final moreOptions = [
      ('Budgets', Icons.pie_chart_rounded, AppRoutes.budgets, const Color(0xFF2E4A9A)),
      ('Reports', Icons.analytics_rounded, AppRoutes.reports, const Color(0xFF4A62B8)),
      ('Goals', Icons.flag_rounded, AppRoutes.goals, const Color(0xFF10B981)),
      ('Borrow', Icons.account_balance_rounded, AppRoutes.borrow, const Color(0xFFF59E0B)),
      ('Settings', Icons.settings_rounded, AppRoutes.settings, const Color(0xFF64748B)),
      ('Help', Icons.help_outline_rounded, AppRoutes.experts, const Color(0xFF06B6D4)),
    ];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(ESUNSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: ESUNSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'More Options',
              style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: ESUNSpacing.lg),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: moreOptions.length,
              itemBuilder: (context, index) {
                final opt = moreOptions[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    context.push(opt.$3);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: opt.$4.withOpacity(0.1),
                      borderRadius: ESUNRadius.mdRadius,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(opt.$2, color: opt.$4, size: 28),
                        const SizedBox(height: ESUNSpacing.xs),
                        Text(opt.$1, style: ESUNTypography.labelMedium.copyWith(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: ESUNSpacing.lg),
          ],
        ),
      ),
    );
  }
  
  void _showAllTransactionsSheet(BuildContext context) {
    final transactions = [
      ('Amazon', 'Shopping', '-₹2,499', '2h ago', Icons.shopping_bag, Colors.orange, false),
      ('Salary Credit', 'Income', '+₹75,000', 'Yesterday', Icons.account_balance, const Color(0xFF10B981), true),
      ('HP Petrol', 'Transport', '-₹1,850', 'Yesterday', Icons.local_gas_station, Colors.blue, false),
      ('Swiggy', 'Food & Dining', '-₹456', '2 days ago', Icons.restaurant, Colors.deepOrange, false),
      ('Netflix', 'Entertainment', '-₹649', '3 days ago', Icons.smart_display, Colors.red, false),
      ('Electricity Bill', 'Utilities', '-₹1,250', '5 days ago', Icons.electric_bolt, const Color(0xFFF59E0B), false),
      ('Freelance Payment', 'Income', '+₹25,000', '1 week ago', Icons.work, const Color(0xFF10B981), true),
      ('Uber', 'Transport', '-₹320', '1 week ago', Icons.local_taxi, Colors.black, false),
      ('Gym Membership', 'Health', '-₹2,000', '1 week ago', Icons.fitness_center, Colors.purple, false),
      ('Mobile Recharge', 'Utilities', '-₹299', '2 weeks ago', Icons.phone_android, const Color(0xFF10B981), false),
    ];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(ESUNSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: ESUNSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Transactions',
                    style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ESUNColors.surfaceVariant,
                      borderRadius: ESUNRadius.fullRadius,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_list, size: 16),
                        const SizedBox(width: 4),
                        Text('Filter', style: ESUNTypography.labelMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ESUNSpacing.md),
              // Summary row
              Container(
                padding: const EdgeInsets.all(ESUNSpacing.md),
                decoration: BoxDecoration(
                  color: ESUNColors.primary.withOpacity(0.08),
                  borderRadius: ESUNRadius.mdRadius,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTxnSummary('Income', '+₹1,00,000', const Color(0xFF10B981)),
                    Container(width: 1, height: 30, color: ESUNColors.border),
                    _buildTxnSummary('Expense', '-₹9,324', Colors.red),
                    Container(width: 1, height: 30, color: ESUNColors.border),
                    _buildTxnSummary('Count', '10', ESUNColors.primary),
                  ],
                ),
              ),
              const SizedBox(height: ESUNSpacing.lg),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final txn = transactions[index];
                    return _buildTransactionItem(
                      txn.$1, txn.$2, txn.$3, txn.$4, txn.$5, txn.$6, txn.$7,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTxnSummary(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
  
  Widget _buildTransactionItem(String name, String category, String amount, String time, IconData icon, Color color, bool isIncome) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: ESUNRadius.smRadius,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    Text(category, style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
                    const SizedBox(width: 6),
                    Text('•', style: TextStyle(color: ESUNColors.textTertiary)),
                    const SizedBox(width: 6),
                    Text(time, style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textTertiary)),
                  ],
                ),
              ],
            ),
          ),
          Text(
            _isBalanceHidden ? '₹••••' : amount,
            style: ESUNTypography.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: isIncome ? const Color(0xFF10B981) : ESUNColors.error,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBalanceChip(IconData icon, String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: ESUNTypography.labelSmall.copyWith(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: ESUNTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildAccountDot(String label, Color color) {
    return Tooltip(
      message: label,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
  
  Widget _buildSupportButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.experts),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          borderRadius: ESUNRadius.fullRadius,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              'Expert',
              style: ESUNTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(Icons.send_rounded, 'Send', () => context.push('${AppRoutes.payments}/send'), const Color(0xFF2E4A9A)),
      _QuickAction(Icons.qr_code_scanner_rounded, 'Scan', () => _showScanSheet(context), const Color(0xFF06B6D4)),
      _QuickAction(Icons.account_balance_rounded, 'Bank', () => _showAccountsSheet(context), const Color(0xFF4A62B8)),
      _QuickAction(Icons.receipt_long_rounded, 'Bills', () => _showBillsSheet(context), const Color(0xFFF59E0B)),
      _QuickAction(Icons.phone_android_rounded, 'Recharge', () => _showRechargeSheet(context), const Color(0xFF10B981)),
      _QuickAction(Icons.credit_card_rounded, 'Cards', () => _showCardsSheet(context), const Color(0xFFEC4899)),
      _QuickAction(Icons.savings_rounded, 'Goals', () => context.push(AppRoutes.goals), const Color(0xFF14B8A6)),
      _QuickAction(Icons.card_giftcard_rounded, 'Rewards', () => context.push(AppRoutes.rewards), const Color(0xFF2E4A9A)),
    ];
    
    return Padding(
      padding: const EdgeInsets.only(left: ESUNSpacing.lg, right: ESUNSpacing.lg, top: ESUNSpacing.xs, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: actions.sublist(0, 4).map((action) {
              return Expanded(
                child: FPQuickActionButton(
                  icon: action.icon,
                  label: action.label,
                  onPressed: action.onTap,
                  iconColor: action.color,
                ),
              );
            }).toList(),
          ),
          Row(
            children: actions.sublist(4).map((action) {
              return Expanded(
                child: FPQuickActionButton(
                  icon: action.icon,
                  label: action.label,
                  onPressed: action.onTap,
                  iconColor: action.color,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRewardsBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg, vertical: ESUNSpacing.xs),
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.rewards),
        child: Container(
          padding: const EdgeInsets.all(ESUNSpacing.md),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E4A9A), Color(0xFF223474)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: ESUNRadius.lgRadius,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E4A9A).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: ESUNRadius.mdRadius,
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: ESUNSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rewards & Cashback',
                      style: ESUNTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Spin to win, gift cards & more',
                      style: ESUNTypography.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: ESUNRadius.fullRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '19,546',
                      style: ESUNTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
  
  Widget _buildAIInsightsBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg, vertical: ESUNSpacing.xs),
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.advisor),
        child: Container(
          padding: const EdgeInsets.all(ESUNSpacing.md),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E4A9A), Color(0xFF4A62B8)],
            ),
            borderRadius: ESUNRadius.lgRadius,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology, color: Colors.white, size: 24),
              ),
              const SizedBox(width: ESUNSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Insight',
                      style: ESUNTypography.labelSmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      'You can save ₹5,000 this month by reducing dining out',
                      style: ESUNTypography.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Coach Kantha Financial Tools Section
  Widget _buildCoachModules(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg, vertical: ESUNSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.school_outlined,
                        color: ESUNColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Coach Kantha',
                        style: ESUNTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your personal financial coach',
                    style: ESUNTypography.bodySmall.copyWith(
                      color: ESUNColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          
          // Coach Modules Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: ESUNSpacing.sm,
            crossAxisSpacing: ESUNSpacing.sm,
            childAspectRatio: 1.5,
            children: [
              _buildCoachModuleCard(
                icon: Icons.calculate_outlined,
                title: 'Calculators',
                subtitle: 'EMI, SIP & more',
                color: const Color(0xFF2E4A9A),
                onTap: () => context.push(AppRoutes.calculators),
              ),
              _buildCoachModuleCard(
                icon: Icons.menu_book_outlined,
                title: 'Learn',
                subtitle: 'Financial basics',
                color: const Color(0xFF059669),
                onTap: () {
                  // TODO: Navigate to educational modules
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Educational modules coming soon!')),
                  );
                },
                comingSoon: true,
              ),
              _buildCoachModuleCard(
                icon: Icons.flag_outlined,
                title: 'Goal Planner',
                subtitle: 'Set & track goals',
                color: const Color(0xFFF59E0B),
                onTap: () => context.push(AppRoutes.goals),
              ),
              _buildCoachModuleCard(
                icon: Icons.storefront_outlined,
                title: 'Products',
                subtitle: 'Curated for you',
                color: const Color(0xFFEC4899),
                onTap: () => context.push(AppRoutes.discover),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCoachModuleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool comingSoon = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(ESUNSpacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: ESUNRadius.mdRadius,
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                if (comingSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: ESUNRadius.fullRadius,
                    ),
                    child: Text(
                      'SOON',
                      style: ESUNTypography.labelSmall.copyWith(
                        color: color,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: ESUNTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: ESUNTypography.labelSmall.copyWith(
                color: ESUNColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHealthScore(BuildContext context) {
    final aaData = ref.watch(aaDataProvider);
    final score = aaData.healthScore;
    final label = aaData.healthLabel;
    final scoreNorm = (score / 100).clamp(0.0, 1.0);
    final scoreColor = score >= 65
        ? ESUNColors.success
        : score >= 50
            ? ESUNColors.warning
            : Colors.red;

    final savingsVal = aaData.savingsFactor;
    final spendingVal = aaData.spendingFactor;
    final investVal = aaData.investmentFactor;
    final debtVal = aaData.debtFactor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg, vertical: ESUNSpacing.xs),
      child: FPCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Financial Health',
                  style: ESUNTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    borderRadius: ESUNRadius.fullRadius,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, color: scoreColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$score / 100',
                        style: ESUNTypography.labelMedium.copyWith(
                          color: scoreColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: ESUNSpacing.lg),
            Row(
              children: [
                // Score Circle
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: scoreNorm,
                          strokeWidth: 10,
                          backgroundColor: ESUNColors.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation(scoreColor),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$score',
                            style: ESUNTypography.headlineMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: scoreColor,
                            ),
                          ),
                          Text(
                            label,
                            style: ESUNTypography.labelSmall.copyWith(
                              color: ESUNColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: ESUNSpacing.xl),
                // Factor breakdown
                Expanded(
                  child: Column(
                    children: [
                      _buildHealthFactor('Savings', savingsVal, ESUNColors.success),
                      const SizedBox(height: 8),
                      _buildHealthFactor('Spending', spendingVal, spendingVal >= 0.5 ? ESUNColors.success : ESUNColors.warning),
                      const SizedBox(height: 8),
                      _buildHealthFactor('Investments', investVal, ESUNColors.primary),
                      const SizedBox(height: 8),
                      _buildHealthFactor('Debt', debtVal, debtVal >= 0.6 ? ESUNColors.success : Colors.red),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHealthFactor(String label, double value, Color color) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: ESUNTypography.labelSmall.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: ESUNRadius.fullRadius,
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: ESUNColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDataConnectionsCard(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final aaConnected = authState.aaConnected;
    final cbConnected = authState.creditBureauConnected;
    
    // Don't show if both are connected
    if (aaConnected && cbConnected) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: ESUNSpacing.lg),
          GestureDetector(
            onTap: () => context.push(AppRoutes.dataConnections),
            child: Container(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ESUNColors.primary.withOpacity(0.08),
                    ESUNColors.secondary.withOpacity(0.04),
                  ],
                ),
                borderRadius: ESUNRadius.lgRadius,
                border: Border.all(color: ESUNColors.primary.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ESUNColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.link_rounded,
                      color: ESUNColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: ESUNSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connect Your Data',
                          style: ESUNTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildConnectionStatusDot(aaConnected),
                            const SizedBox(width: 4),
                            Text(
                              'AA',
                              style: ESUNTypography.labelSmall.copyWith(
                                color: aaConnected ? ESUNColors.success : ESUNColors.textTertiary,
                              ),
                            ),
                            const SizedBox(width: ESUNSpacing.md),
                            _buildConnectionStatusDot(cbConnected),
                            const SizedBox(width: 4),
                            Text(
                              'Credit Bureau',
                              style: ESUNTypography.labelSmall.copyWith(
                                color: cbConnected ? ESUNColors.success : ESUNColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ESUNColors.primary,
                      borderRadius: ESUNRadius.fullRadius,
                    ),
                    child: Text(
                      'Link',
                      style: ESUNTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildConnectionStatusDot(bool connected) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: connected ? ESUNColors.success : ESUNColors.textTertiary.withOpacity(0.5),
      ),
    );
  }
  
  Widget _buildRecentTransactions(BuildContext context) {
    // Get latest transactions from transaction state
    final recentTransactions = ref.watch(recentTransactionsProvider);
    
    // Helper to get time ago string
    String getTimeAgo(DateTime dateTime) {
      final now = DateTime.now();
      final diff = now.difference(dateTime);
      
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${(diff.inDays / 7).floor()}w ago';
    }
    
    // Helper to get icon for transaction type
    IconData getIcon(TransactionType type) {
      switch (type) {
        case TransactionType.billPayment:
          return Icons.receipt_long_rounded;
        case TransactionType.upiTransfer:
          return Icons.send_rounded;
        case TransactionType.bankTransfer:
          return Icons.account_balance_rounded;
        case TransactionType.recharge:
          return Icons.smartphone_rounded;
        case TransactionType.income:
          return Icons.account_balance_rounded;
        case TransactionType.refund:
          return Icons.replay_rounded;
      }
    }
    
    // Helper to get icon color
    Color getIconColor(TransactionType type, bool isDebit) {
      if (!isDebit) return ESUNColors.success;
      switch (type) {
        case TransactionType.billPayment:
          return Colors.purple;
        case TransactionType.upiTransfer:
          return Colors.blue;
        case TransactionType.bankTransfer:
          return ESUNColors.primary;
        case TransactionType.recharge:
          return Colors.orange;
        case TransactionType.income:
          return ESUNColors.success;
        case TransactionType.refund:
          return ESUNColors.success;
      }
    }
    
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: ESUNTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => _showAllTransactionsSheet(context),
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.sm),
          // Dynamic transaction list
          if (recentTransactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(ESUNSpacing.xl),
              decoration: BoxDecoration(
                color: ESUNColors.surface,
                borderRadius: ESUNRadius.lgRadius,
                border: Border.all(color: ESUNColors.border),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 48, color: ESUNColors.textTertiary),
                    const SizedBox(height: ESUNSpacing.sm),
                    Text(
                      'No transactions yet',
                      style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            ...recentTransactions.take(5).map((tx) {
              final iconColor = getIconColor(tx.type, tx.isDebit);
              final amountText = tx.isDebit ? '-₹${tx.amount.toStringAsFixed(0)}' : '+₹${tx.amount.toStringAsFixed(0)}';
              final category = tx.category ?? (tx.isDebit ? 'Payment' : 'Income');
              
              return FPTransactionCard(
                icon: getIcon(tx.type),
                iconBackgroundColor: iconColor.withOpacity(0.1),
                iconColor: iconColor,
                title: tx.title,
                subtitle: '$category • ${getTimeAgo(tx.timestamp)}',
                amount: amountText,
                amountColor: tx.isDebit ? ESUNColors.error : ESUNColors.success,
              );
            }),
        ],
      ),
    );
  }
  
  Widget _buildSpendingCategories(BuildContext context) {
    // Category data with colors
    final categories = [
      _SpendingCategory('Payments', 223000, 52.35, Icons.credit_card_rounded, const Color(0xFFEF4444)),
      _SpendingCategory('Credit Card Bill', 65574, 15.26, Icons.receipt_long_rounded, const Color(0xFF8B5CF6)),
      _SpendingCategory('Investments', 33157, 7.77, Icons.trending_up_rounded, const Color(0xFF3B82F6)),
      _SpendingCategory('Others', 27684, 6.49, Icons.more_horiz_rounded, const Color(0xFF6B7280)),
      _SpendingCategory('Travel', 10847, 2.54, Icons.flight_takeoff_rounded, const Color(0xFF2E4A9A)),
      _SpendingCategory('Shopping', 9009, 2.17, Icons.shopping_bag_rounded, const Color(0xFFF59E0B)),
      _SpendingCategory('Food & Beverage', 8515, 2.01, Icons.restaurant_rounded, const Color(0xFFEC4899)),
    ];
    
    final totalSpending = categories.fold(0.0, (sum, cat) => sum + cat.amount);
    
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF2E4A9A), const Color(0xFF3B82F6)],
                      ),
                      borderRadius: ESUNRadius.smRadius,
                    ),
                    child: const Icon(Icons.pie_chart_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: ESUNSpacing.sm),
                  Text(
                    'Spending Analysis',
                    style: ESUNTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View all categories'),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.md),
          
          // Colorful Bar Chart
          Container(
            height: 24,
            decoration: BoxDecoration(
              borderRadius: ESUNRadius.smRadius,
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: categories.map((cat) {
                return Expanded(
                  flex: (cat.percentage * 10).round(),
                  child: Container(
                    color: cat.color,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          
          // Category List
          ...categories.map((cat) => _buildCategoryRow(cat, totalSpending)),
        ],
      ),
    );
  }
  
  Widget _buildCategoryRow(_SpendingCategory category, double total) {
    final percentage = (category.amount / total * 100);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.md),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.15),
              borderRadius: ESUNRadius.smRadius,
            ),
            child: Icon(category.icon, color: category.color, size: 20),
          ),
          const SizedBox(width: ESUNSpacing.md),
          
          // Category details with progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category.name,
                      style: ESUNTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '₹${_formatCategoryAmount(category.amount)}',
                      style: ESUNTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: category.color.withOpacity(0.15),
                              borderRadius: ESUNRadius.fullRadius,
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: percentage / 100,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    category.color,
                                    category.color.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: ESUNRadius.fullRadius,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: ESUNSpacing.sm),
                    Text(
                      '${percentage.toStringAsFixed(2)}%',
                      style: ESUNTypography.labelSmall.copyWith(
                        color: category.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatCategoryAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)},${(amount % 1000).toStringAsFixed(0).padLeft(3, '0')}';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildMonthlyOverview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
      child: FPCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Month',
              style: ESUNTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: ESUNSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    'Income',
                    '₹1,20,000',
                    Icons.arrow_upward,
                    ESUNColors.success,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: ESUNColors.border,
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Expenses',
                    '₹45,800',
                    Icons.arrow_downward,
                    ESUNColors.error,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: ESUNColors.border,
                ),
                Expanded(
                  child: _buildStatColumn(
                    'Saved',
                    '₹74,200',
                    Icons.savings,
                    ESUNColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: ESUNTypography.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: ESUNTypography.labelSmall.copyWith(
            color: ESUNColors.textSecondary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildGoalsProgress(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Goals',
                style: ESUNTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.goals),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.sm),
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildGoalCard(
                  'Emergency Fund',
                  '₹3,00,000',
                  '₹1,80,000',
                  0.6,
                  Icons.shield_outlined,
                  Colors.blue,
                ),
                _buildGoalCard(
                  'New Car',
                  '₹8,00,000',
                  '₹2,40,000',
                  0.3,
                  Icons.directions_car,
                  Colors.orange,
                ),
                _buildGoalCard(
                  'Vacation',
                  '₹1,50,000',
                  '₹90,000',
                  0.6,
                  Icons.flight,
                  Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGoalCard(
    String name,
    String target,
    String saved,
    double progress,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: ESUNSpacing.md),
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: ESUNRadius.lgRadius,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toInt()}%',
                style: ESUNTypography.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            name,
            style: ESUNTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$saved / $target',
            style: ESUNTypography.labelSmall.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: ESUNRadius.fullRadius,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPromotions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg, vertical: ESUNSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'For You',
            style: ESUNTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [ESUNColors.primary200, ESUNColors.secondaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: ESUNRadius.lgRadius,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Borrow Hub',
                        style: ESUNTypography.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Personal, home, and secured loans\nfrom trusted partners',
                        style: ESUNTypography.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () => context.push(AppRoutes.borrow),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: ESUNColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Apply Now',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? ESUNColors.darkSurface : Colors.white;

    showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Profile',
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, _, __) {
        final screenHeight = MediaQuery.of(dialogContext).size.height;
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            height: screenHeight,
            width: screenWidth,
            child: Material(
              color: sheetColor,
              borderRadius: BorderRadius.zero,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(ESUNSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: ESUNColors.primary.withOpacity(0.12),
                            child: Text(
                              _getInitials(_userName),
                              style: const TextStyle(color: ESUNColors.primary),
                            ),
                          ),
                          const SizedBox(width: ESUNSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userName,
                                  style: ESUNTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _userPhone,
                                  style: ESUNTypography.bodyMedium.copyWith(
                                    color: ESUNColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: ESUNSpacing.lg),
                      _SideItem(
                        icon: Icons.person_outline,
                        label: 'Profile',
                        subtitle: 'Privacy, notifications',
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          context.push(AppRoutes.profile);
                        },
                      ),
                      _SideItem(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        subtitle: 'Theme, security, alerts',
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          context.push(AppRoutes.settings);
                        },
                      ),
                      _SideItem(
                        icon: Icons.account_balance_outlined,
                        label: 'Bank & UPI',
                        subtitle: _userBankLabel,
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          context.push(AppRoutes.payments);
                        },
                      ),
                      _SideItem(
                        icon: Icons.card_giftcard_outlined,
                        label: 'Rewards & Cashback',
                        subtitle: 'View offers and referrals',
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          context.push(AppRoutes.discover);
                        },
                      ),
                      _SideItem(
                        icon: Icons.qr_code_2_rounded,
                        label: 'View QR',
                        subtitle: _userUpiId,
                        onTap: () async {
                          Navigator.of(dialogContext).pop();
                          await showQrBottomSheet(
                            context,
                            name: _userName,
                            upiId: _userUpiId,
                            bankLabel: _userBankLabel,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final slide = Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return SlideTransition(
          position: slide,
          child: FadeTransition(
            opacity: fade,
            child: child,
          ),
        );
      },
    );
  }
}

class _SideItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _SideItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: ESUNRadius.mdRadius,
          child: Container(
            padding: const EdgeInsets.all(ESUNSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? ESUNColors.darkSurfaceVariant.withOpacity(0.4)
                  : ESUNColors.surfaceVariant,
              borderRadius: ESUNRadius.mdRadius,
            ),
            child: Row(
              children: [
                Icon(icon, color: ESUNColors.textSecondary),
                const SizedBox(width: ESUNSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: ESUNTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: ESUNTypography.labelSmall.copyWith(
                          color: ESUNColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: ESUNColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  
  _QuickAction(this.icon, this.label, this.onTap, this.color);
}

class _SpendingCategory {
  final String name;
  final double amount;
  final double percentage;
  final IconData icon;
  final Color color;
  
  _SpendingCategory(this.name, this.amount, this.percentage, this.icon, this.color);
}



