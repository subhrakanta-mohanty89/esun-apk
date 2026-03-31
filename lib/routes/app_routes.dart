/// ESUN Navigation Routes
/// 
/// Route definitions and path constants.

abstract class AppRoutes {
  // Root
  static const String splash = '/splash';
  static const String onboarding = '/onboarding/details';  // Go directly to registration
  static const String onboardingIntro = '/onboarding';  // First-install intro screens
  static const String onboardingDetails = '/onboarding/details';
  static const String onboardingVerify = '/onboarding/verify';
  static const String featureIntro = '/feature-intro';
  
  // Installation Flow (New User Journey)
  static const String installationFlow = '/install';
  static const String installationWelcome = '/install/welcome';
  static const String installationPermissions = '/install/permissions';
  static const String installationDataLinking = '/install/data-linking';
  
  // Auth
  static const String login = '/login';
  static const String otp = '/otp';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String biometricUnlock = '/biometric-unlock';
  static const String pinSetup = '/pin-setup';
  static const String pinUnlock = '/pin-unlock';
  
  // Main Shell
  static const String home = '/';
  static const String payments = '/payments';
  static const String invest = '/invest';
  static const String discover = '/discover';
  static const String advisor = '/advisor';
  static const String experts = '/experts';
  
  // Home Sub-routes
  static const String financialHealth = '/financial-health';
  static const String cashflow = '/cashflow';
  static const String insights = '/insights';
  
  // Profile & Settings
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String dataConnections = '/settings/data-connections';
  static const String security = '/settings/security';
  static const String privacy = '/settings/privacy';
  static const String notifications = '/notifications';
  static const String alerts = '/alerts';
  
  // Payments Sub-routes
  static const String sendMoney = '/payments/send';
  static const String requestMoney = '/payments/request';
  static const String scanQr = '/payments/scan';
  static const String myQr = '/payments/my-qr';
  static const String bankAccounts = '/payments/accounts';
  static const String addAccount = '/payments/accounts/add';
  static const String contacts = '/payments/contacts';
  static const String transactionHistory = '/payments/history';
  static const String transactionDetails = '/payments/transaction/:id';
  static const String creditCardPayment = '/payments/credit-card';
  static const String billPayments = '/payments/bills';
  
  // Invest Sub-routes
  static const String portfolio = '/invest/portfolio';
  static const String assetAllocation = '/invest/allocation';
  static const String sipManager = '/invest/sip';
  static const String sipDetails = '/invest/sip/:id';
  static const String createSip = '/invest/sip/create';
  static const String mutualFunds = '/invest/mutual-funds';
  static const String fundDetails = '/invest/mutual-funds/:id';
  static const String stocks = '/invest/stocks';
  static const String stockDetails = '/invest/stocks/:id';
  static const String digitalGold = '/invest/gold';
  static const String fixedDeposits = '/invest/fd';
  static const String watchlist = '/invest/watchlist';
  
  // Borrow
  static const String borrow = '/borrow';
  static const String loanEligibility = '/borrow/eligibility';
  static const String emiCalculator = '/borrow/emi-calculator';
  static const String creditScore = '/borrow/credit-score';
  static const String activeLoans = '/borrow/active';
  static const String loanDetails = '/borrow/loan/:id';
  
  // Discover Sub-routes
  static const String discoverCategory = '/discover/:category';
  static const String productDetails = '/discover/product/:id';
  static const String compare = '/discover/compare';
  
  // Advisor (KANTA)
  static const String advisorChat = '/advisor/chat';
  static const String advisorVoice = '/advisor/voice';
  static const String weeklyReport = '/advisor/report';
  
  // Experts Sub-routes
  static const String expertProfile = '/experts/:id';
  static const String bookSession = '/experts/:id/book';
  static const String upcomingSessions = '/experts/sessions';
  static const String sessionDetails = '/experts/session/:id';
  
  // Search
  static const String search = '/search';
  
  // Reports
  static const String reports = '/reports';
  static const String taxSummary = '/reports/tax';
  static const String spendingReport = '/reports/spending';
  static const String investmentReport = '/reports/investment';
  
  // Goals & Budgets
  static const String goals = '/goals';
  static const String goalDetails = '/goals/:id';
  static const String createGoal = '/goals/create';
  static const String budgets = '/budgets';
  static const String budgetDetails = '/budgets/:id';
  static const String createBudget = '/budgets/create';
  
  // AA Onboarding (Account Aggregator)
  static const String aaOnboarding = '/aa-onboarding';
  static const String aaVerifyPan = '/aa-onboarding/verify-pan';
  static const String aaActivateTracker = '/aa-onboarding/activate-tracker';
  static const String aaVerifyOtp = '/aa-onboarding/verify-otp';
  static const String aaSelectBanks = '/aa-onboarding/select-banks';
  static const String aaDiscoverAccounts = '/aa-onboarding/discover-accounts';
  static const String aaReviewConsent = '/aa-onboarding/review-consent';
  static const String aaFinalStepConsent = '/aa-onboarding/final-step-consent';
  static const String aaAnalyzing = '/aa-onboarding/analyzing';
  static const String aaFinancialHealthDashboard = '/aa-onboarding/financial-health-dashboard';
  static const String aaConnecting = '/aa-onboarding/connecting';
  static const String aaSuccess = '/aa-onboarding/success';
  static const String aaDeclined = '/aa-onboarding/declined';
  static const String aaFailure = '/aa-onboarding/failure';
  static const String aaMyConsents = '/aa/my-consents';
  static const String aaProfile = '/aa/profile';
  static const String aaRenewConsents = '/aa/renew-consents';
  
  // Net Worth
  static const String netWorth = '/net-worth';
  static const String netWorthDetails = '/net-worth/details';
  
  // Rewards
  static const String rewards = '/rewards';
  static const String spinWheel = '/rewards/spin';
  static const String giftCards = '/rewards/gift-cards';
  static const String credStore = '/rewards/store';
  static const String dailyRewards = '/rewards/daily';
  
  // Coach (Kantha Financial Tools)
  static const String calculators = '/coach/calculators';
  static const String educationalModules = '/coach/learn';
  static const String goalPlanner = '/coach/goal-planner';
  static const String productMarketplace = '/coach/marketplace';
  
  // Helper methods
  static String transactionDetailsPath(String id) => '/payments/transaction/$id';
  static String fundDetailsPath(String id) => '/invest/mutual-funds/$id';
  static String stockDetailsPath(String id) => '/invest/stocks/$id';
  static String sipDetailsPath(String id) => '/invest/sip/$id';
  static String loanDetailsPath(String id) => '/borrow/loan/$id';
  static String expertProfilePath(String id) => '/experts/$id';
  static String bookSessionPath(String id) => '/experts/$id/book';
  static String sessionDetailsPath(String id) => '/experts/session/$id';
  static String goalDetailsPath(String id) => '/goals/$id';
  static String budgetDetailsPath(String id) => '/budgets/$id';
  static String discoverCategoryPath(String category) => '/discover/$category';
  static String productDetailsPath(String id) => '/discover/product/$id';
}



