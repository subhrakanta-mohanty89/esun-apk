/// ESUN AA (Account Aggregator) Onboarding Flow
///
/// Multi-step flow for connecting user's financial accounts via
/// RBI's Account Aggregator framework.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_service.dart';
import '../../routes/app_routes.dart';
import '../../theme/theme.dart';
import '../../shared/widgets/widgets.dart';
import '../../shared/widgets/smart_network_image.dart';
import '../../state/app_state.dart';

// ============================================================================
// State Providers
// ============================================================================

/// AA onboarding state
class AAOnboardingState {
  final int currentStep;
  final bool isLoading;
  final String? error;
  final String? verificationId;
  final String? maskedMobile;
  final String? aaSessionId;
  final String? panNumber;
  final String? dateOfBirth;
  final String? consentId;
  final List<Map<String, dynamic>> selectedFips;
  final List<Map<String, dynamic>> discoveredAccounts;
  final List<String> selectedAccountIds;

  const AAOnboardingState({
    this.currentStep = 0,
    this.isLoading = false,
    this.error,
    this.verificationId,
    this.maskedMobile,
    this.aaSessionId,
    this.panNumber,
    this.dateOfBirth,
    this.consentId,
    this.selectedFips = const [],
    this.discoveredAccounts = const [],
    this.selectedAccountIds = const [],
  });

  AAOnboardingState copyWith({
    int? currentStep,
    bool? isLoading,
    String? error,
    String? verificationId,
    String? maskedMobile,
    String? aaSessionId,
    String? panNumber,
    String? dateOfBirth,
    String? consentId,
    List<Map<String, dynamic>>? selectedFips,
    List<Map<String, dynamic>>? discoveredAccounts,
    List<String>? selectedAccountIds,
  }) {
    return AAOnboardingState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      verificationId: verificationId ?? this.verificationId,
      maskedMobile: maskedMobile ?? this.maskedMobile,
      aaSessionId: aaSessionId ?? this.aaSessionId,
      panNumber: panNumber ?? this.panNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      consentId: consentId ?? this.consentId,
      selectedFips: selectedFips ?? this.selectedFips,
      discoveredAccounts: discoveredAccounts ?? this.discoveredAccounts,
      selectedAccountIds: selectedAccountIds ?? this.selectedAccountIds,
    );
  }
}

final aaOnboardingProvider =
    StateNotifierProvider<AAOnboardingNotifier, AAOnboardingState>((ref) {
  return AAOnboardingNotifier(ref);
});

class AAOnboardingNotifier extends StateNotifier<AAOnboardingState> {
  final Ref _ref;

  AAOnboardingNotifier(this._ref) : super(const AAOnboardingState());

  void reset() {
    state = const AAOnboardingState();
  }

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void setError(String? error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void toggleFip(Map<String, dynamic> fip) {
    final fipId = fip['id'] as String;
    final current = List<Map<String, dynamic>>.from(state.selectedFips);
    final exists = current.any((f) => f['id'] == fipId);
    if (exists) {
      current.removeWhere((f) => f['id'] == fipId);
    } else {
      current.add(fip);
    }
    state = state.copyWith(selectedFips: current);
  }

  void toggleAccount(String accountId) {
    final current = List<String>.from(state.selectedAccountIds);
    if (current.contains(accountId)) {
      current.remove(accountId);
    } else {
      current.add(accountId);
    }
    state = state.copyWith(selectedAccountIds: current);
  }

  void selectAllAccounts() {
    final allIds =
        state.discoveredAccounts.map((a) => a['account_id'] as String).toList();
    state = state.copyWith(selectedAccountIds: allIds);
  }

  Future<bool> verifyPan(String panNumber, String dob) async {
    state = state.copyWith(isLoading: true, error: null);

    final api = _ref.read(apiServiceProvider);
    final result = await api.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/aa/verify-pan',
      data: {'pan_number': panNumber, 'date_of_birth': dob},
    );

    if (result.isError || result.data?['success'] != true) {
      final msg =
          result.data?['error']?['message'] ?? 'PAN verification failed';
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }

    final data = result.data!['data'] as Map<String, dynamic>;
    state = state.copyWith(
      isLoading: false,
      verificationId: data['verification_id'],
      maskedMobile: data['masked_mobile'],
      panNumber: panNumber,
      dateOfBirth: dob,
    );
    return true;
  }

  Future<bool> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true, error: null);

    final api = _ref.read(apiServiceProvider);
    final result = await api.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/aa/verify-pan-otp',
      data: {
        'verification_id': state.verificationId,
        'otp': otp,
        // POC: Pass PAN details since we skip Redis
        'pan_number': state.panNumber,
        'date_of_birth': state.dateOfBirth,
      },
    );

    if (result.isError || result.data?['success'] != true) {
      final msg = result.data?['error']?['message'] ?? 'Invalid OTP';
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }

    final data = result.data!['data'] as Map<String, dynamic>;
    
    // Update auth state to reflect aa_connected status from backend
    // Backend sets aa_connected = true after OTP verification
    _ref.read(authStateProvider.notifier).state =
        _ref.read(authStateProvider).copyWith(
              aaConnected: true,
              isOnboarded: true,
            );
    
    state = state.copyWith(
      isLoading: false,
      aaSessionId: data['aa_session_id'],
    );
    return true;
  }

  Future<bool> discoverAccounts() async {
    state = state.copyWith(isLoading: true, error: null);

    final api = _ref.read(apiServiceProvider);
    final selectedFipIds = state.selectedFips.map((f) => f['id']).toList();

    final result = await api.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/aa/discover-accounts',
      data: {
        'aa_session_id': state.aaSessionId,
        'selected_fip_ids': selectedFipIds,
      },
    );

    if (result.isError || result.data?['success'] != true) {
      final msg =
          result.data?['error']?['message'] ?? 'Account discovery failed';
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }

    final data = result.data!['data'] as Map<String, dynamic>;
    final accounts = List<Map<String, dynamic>>.from(data['accounts'] ?? []);

    // Auto-select all discovered accounts
    final allIds = accounts.map((a) => a['account_id'] as String).toList();

    state = state.copyWith(
      isLoading: false,
      discoveredAccounts: accounts,
      selectedAccountIds: allIds,
    );
    return true;
  }

  Future<bool> submitConsent() async {
    state = state.copyWith(isLoading: true, error: null);

    final api = _ref.read(apiServiceProvider);
    final result = await api.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/aa/submit-consent',
      data: {
        'aa_session_id': state.aaSessionId,
        'account_ids': state.selectedAccountIds,
        'consent_accepted': true,
      },
    );

    if (result.isError || result.data?['success'] != true) {
      final msg =
          result.data?['error']?['message'] ?? 'Consent submission failed';
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }

    final data = result.data!['data'] as Map<String, dynamic>;
    state = state.copyWith(
      isLoading: false,
      consentId: data['consent_id'],
    );
    return true;
  }

  Future<bool> connectAccounts() async {
    state = state.copyWith(isLoading: true, error: null);

    final api = _ref.read(apiServiceProvider);
    final result = await api.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/aa/connect',
      data: {'consent_id': state.consentId},
    );

    if (result.isError || result.data?['success'] != true) {
      final msg =
          result.data?['error']?['message'] ?? 'Account connection failed';
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }

    // Update auth state to reflect onboarded status
    _ref.read(authStateProvider.notifier).state =
        _ref.read(authStateProvider).copyWith(
              isOnboarded: true,
              aaConnected: true,
            );

    state = state.copyWith(isLoading: false);
    return true;
  }

  // Selected finance tracker categories
  List<String> _selectedCategories = [];
  
  void toggleCategory(String categoryId) {
    final current = List<String>.from(_selectedCategories);
    if (current.contains(categoryId)) {
      current.remove(categoryId);
    } else {
      current.add(categoryId);
    }
    _selectedCategories = current;
    state = state.copyWith(); // Trigger rebuild
  }
  
  void selectAllCategories(List<String> categoryIds) {
    _selectedCategories = List.from(categoryIds);
    state = state.copyWith();
  }
  
  bool isCategorySelected(String categoryId) {
    return _selectedCategories.contains(categoryId);
  }
  
  List<String> get selectedCategories => _selectedCategories;
}

// ============================================================================
// Step Indicator Widget (FinFactor Style)
// ============================================================================

class AAStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const AAStepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg, vertical: ESUNSpacing.md),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final stepNumber = index + 1;
          final isCompleted = stepNumber < currentStep;
          final isCurrent = stepNumber == currentStep;
          return Expanded(
            child: Row(
              children: [
                // Step circle
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? ESUNColors.success 
                        : isCurrent 
                            ? ESUNColors.primary 
                            : ESUNColors.border,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(
                            '$stepNumber',
                            style: ESUNTypography.labelMedium.copyWith(
                              color: isCurrent ? Colors.white : ESUNColors.textTertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                // Connector line (except for last step)
                if (index < totalSteps - 1)
                  Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isCompleted ? ESUNColors.success : ESUNColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ============================================================================
// Step 1: Verify PAN Screen (FinFactor Style)
// ============================================================================

class AAVerifyPanScreen extends ConsumerStatefulWidget {
  const AAVerifyPanScreen({super.key});

  @override
  ConsumerState<AAVerifyPanScreen> createState() => _AAVerifyPanScreenState();
}

class _AAVerifyPanScreenState extends ConsumerState<AAVerifyPanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _panController = TextEditingController();

  @override
  void dispose() {
    _panController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    // For prototype, use a default DOB
    final notifier = ref.read(aaOnboardingProvider.notifier);
    final success = await notifier.verifyPan(
      _panController.text.trim().toUpperCase(),
      '01-01-1990', // Default DOB for prototype
    );

    if (success && mounted) {
      // Show OTP bottom sheet
      _showOtpBottomSheet();
    }
  }

  void _showOtpBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _OtpBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aaOnboardingProvider);
    final isPanValid = _panController.text.length == 10 &&
        RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(_panController.text.toUpperCase());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ESUNColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'Aa/अ',
              style: ESUNTypography.labelMedium.copyWith(color: ESUNColors.textSecondary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Indicator
            const AAStepIndicator(currentStep: 1, totalSteps: 4),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(ESUNSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Illustration Card
                      Container(
                        padding: const EdgeInsets.all(ESUNSpacing.xl),
                        decoration: BoxDecoration(
                          color: ESUNColors.surface,
                          borderRadius: ESUNRadius.lgRadius,
                          border: Border.all(color: ESUNColors.border),
                        ),
                        child: Column(
                          children: [
                            // Illustration placeholder
                            SizedBox(
                              height: 120,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Phone illustration
                                  Container(
                                    width: 80,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: ESUNColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: ESUNColors.primary.withOpacity(0.2)),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.person_outline, color: ESUNColors.primary, size: 24),
                                        const SizedBox(height: ESUNSpacing.sm),
                                        Container(
                                          width: 50,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: ESUNColors.primary.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: ESUNColors.primary.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Person illustration
                                  const Positioned(
                                    right: 60,
                                    bottom: 0,
                                    child: Icon(
                                      Icons.person,
                                      color: ESUNColors.secondary,
                                      size: 60,
                                    ),
                                  ),
                                  // Arrow indicators
                                  const Positioned(
                                    left: 60,
                                    top: 20,
                                    child: Icon(
                                      Icons.arrow_forward,
                                      color: ESUNColors.info,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: ESUNSpacing.lg),
                            
                            // Title
                            Text(
                              'Please enter your PAN',
                              style: ESUNTypography.headlineSmall.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: ESUNSpacing.sm),
                            Text(
                              'We will search for investments linked to your PAN so you can see them all in one place',
                              textAlign: TextAlign.center,
                              style: ESUNTypography.bodyMedium.copyWith(
                                color: ESUNColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: ESUNSpacing.xl),
                            
                            // PAN Input Field
                            TextFormField(
                              controller: _panController,
                              textCapitalization: TextCapitalization.characters,
                              onChanged: (_) => setState(() {}),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                                LengthLimitingTextInputFormatter(10),
                                UpperCaseTextFormatter(),
                              ],
                              decoration: InputDecoration(
                                labelText: 'PAN',
                                hintText: 'ABCDE1234F',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: ESUNColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: ESUNColors.primary, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              style: ESUNTypography.bodyLarge,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter your PAN number';
                                }
                                final pan = value.trim().toUpperCase();
                                if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(pan)) {
                                  return 'Invalid PAN format';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      // Error message
                      if (state.error != null) ...[
                        const SizedBox(height: ESUNSpacing.lg),
                        Container(
                          padding: const EdgeInsets.all(ESUNSpacing.md),
                          decoration: BoxDecoration(
                            color: ESUNColors.error.withOpacity(0.1),
                            borderRadius: ESUNRadius.mdRadius,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: ESUNColors.error),
                              const SizedBox(width: ESUNSpacing.sm),
                              Expanded(
                                child: Text(
                                  state.error!,
                                  style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            
            // Next Button
            Padding(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isPanValid && !state.isLoading ? _continue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ESUNColors.primary,
                    disabledBackgroundColor: ESUNColors.border,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Next',
                          style: ESUNTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// OTP Bottom Sheet (FinFactor Style)
// ============================================================================

class _OtpBottomSheet extends ConsumerStatefulWidget {
  const _OtpBottomSheet();

  @override
  ConsumerState<_OtpBottomSheet> createState() => _OtpBottomSheetState();
}

class _OtpBottomSheetState extends ConsumerState<_OtpBottomSheet> {
  String _otp = '';
  int _countdown = 179; // 02:59
  bool _isLoading = false;
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Listen to focus changes to update cursor indicator
    _otpFocusNode.addListener(_onFocusChange);
    // Auto-focus the OTP input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpFocusNode.requestFocus();
    });
  }

  void _onFocusChange() {
    setState(() {}); // Rebuild to show/hide cursor indicator
  }

  @override
  void dispose() {
    _otpFocusNode.removeListener(_onFocusChange);
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_countdown > 0) {
        setState(() => _countdown--);
        return true;
      }
      return false;
    });
  }

  String get _formattedTime {
    final minutes = _countdown ~/ 60;
    final seconds = _countdown % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _submitOtp() async {
    if (_otp.length != 6) return;

    setState(() => _isLoading = true);
    
    final notifier = ref.read(aaOnboardingProvider.notifier);
    final success = await notifier.verifyOtp(_otp);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop(); // Close bottom sheet
      context.push(AppRoutes.aaActivateTracker);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aaOnboardingProvider);
    final isOtpComplete = _otp.length == 6;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Close button
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(ESUNSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Please verify your mobile number',
                  style: ESUNTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: ESUNSpacing.xs),
                Text(
                  'You will receive OTP from Finvu (RBI regulated entity)',
                  style: ESUNTypography.bodyMedium.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
                const SizedBox(height: ESUNSpacing.xl),
                
                // OTP Card
                Container(
                  padding: const EdgeInsets.all(ESUNSpacing.lg),
                  decoration: BoxDecoration(
                    color: ESUNColors.surface,
                    borderRadius: ESUNRadius.lgRadius,
                    border: Border.all(color: ESUNColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Please enter OTP',
                        style: ESUNTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: ESUNSpacing.xs),
                      Row(
                        children: [
                          Text(
                            'OTP sent to ',
                            style: ESUNTypography.bodySmall.copyWith(
                              color: ESUNColors.textSecondary,
                            ),
                          ),
                          Text(
                            state.maskedMobile ?? '+91 XXXXX XXXXX',
                            style: ESUNTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.edit_outlined, size: 18, color: ESUNColors.textSecondary),
                        ],
                      ),
                      const SizedBox(height: ESUNSpacing.lg),
                      
                      // OTP Input boxes with hidden TextField
                      GestureDetector(
                        onTap: () {
                          _otpFocusNode.requestFocus();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          height: 56,
                          child: Stack(
                            children: [
                              // Hidden TextField for keyboard input - positioned to fill
                              Positioned.fill(
                                child: TextField(
                                  controller: _otpController,
                                  focusNode: _otpFocusNode,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  autofocus: true,
                                  style: const TextStyle(
                                    color: Colors.transparent,
                                    height: 0.01,
                                    fontSize: 1,
                                  ),
                                  showCursor: false,
                                  onChanged: (value) {
                                    setState(() {
                                      _otp = value.replaceAll(RegExp(r'[^0-9]'), '');
                                      if (_otp.length > 6) _otp = _otp.substring(0, 6);
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    counterText: '',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              // Visual OTP boxes on top
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(6, (index) {
                                  final hasDigit = index < _otp.length;
                                  final isCurrentBox = index == _otp.length && _otpFocusNode.hasFocus;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 48,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isCurrentBox 
                                            ? ESUNColors.primary 
                                            : (hasDigit ? ESUNColors.primary : ESUNColors.border),
                                        width: isCurrentBox ? 2 : (hasDigit ? 2 : 1),
                                      ),
                                      boxShadow: isCurrentBox ? [
                                        BoxShadow(
                                          color: ESUNColors.primary.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ] : null,
                                    ),
                                    child: Center(
                                      child: hasDigit
                                          ? Text(
                                              _otp[index],
                                              style: ESUNTypography.headlineSmall.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: ESUNColors.textPrimary,
                                              ),
                                            )
                                          : (isCurrentBox
                                              ? Container(
                                                  width: 2,
                                                  height: 24,
                                                  color: ESUNColors.primary,
                                                )
                                              : Text(
                                                  '',
                                                  style: ESUNTypography.headlineSmall.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: ESUNColors.textSecondary,
                                                  ),
                                                )),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Quick fill for prototype
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _otp = '123456';
                                _otpController.text = '123456';
                              });
                            },
                            icon: const Icon(Icons.auto_fix_high, size: 16),
                            label: const Text('Auto-fill: 123456'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              foregroundColor: ESUNColors.info,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: ESUNSpacing.md),
                      
                      // Timer and Resend
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 18, color: ESUNColors.primary),
                          const SizedBox(width: ESUNSpacing.xs),
                          Text(
                            _formattedTime,
                            style: ESUNTypography.bodyMedium.copyWith(
                              color: ESUNColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _countdown == 0 ? () {
                              setState(() => _countdown = 179);
                              _startCountdown();
                            } : null,
                            child: Text(
                              'Resend OTP',
                              style: ESUNTypography.bodyMedium.copyWith(
                                color: _countdown == 0 ? ESUNColors.primary : ESUNColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: ESUNSpacing.lg),
                
                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isOtpComplete && !_isLoading ? _submitOtp : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ESUNColors.primary,
                      disabledBackgroundColor: ESUNColors.border,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Submit OTP',
                            style: ESUNTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: ESUNSpacing.lg),
                
                // Terms
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
                      children: [
                        const TextSpan(text: 'By clicking continue you are agreeing to\n'),
                        TextSpan(
                          text: "Finvu's Terms and Conditions",
                          style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: ESUNSpacing.lg),
                
                // Footer
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.md),
                  decoration: const BoxDecoration(
                    color: ESUNColors.primary,
                    borderRadius: ESUNRadius.mdRadius,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Powered by RBI-Regulated AA',
                        style: ESUNTypography.bodySmall.copyWith(color: Colors.white),
                      ),
                      const SizedBox(width: ESUNSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'FINVU',
                          style: ESUNTypography.labelSmall.copyWith(
                            color: ESUNColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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

// ============================================================================
// Step 1.5: Portfolio Value Received Screen (FinFactor Style)
// ============================================================================

class AAActivateTrackerScreen extends ConsumerWidget {
  const AAActivateTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ESUNColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_outlined, color: ESUNColors.textSecondary),
            onPressed: () {},
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              'Aa/अ',
              style: ESUNTypography.labelMedium.copyWith(color: ESUNColors.textSecondary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Indicator
            const AAStepIndicator(currentStep: 2, totalSteps: 4),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(ESUNSpacing.lg),
                child: Column(
                  children: [
                    // Portfolio Value Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(ESUNSpacing.xl),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.teal.shade400,
                            Colors.teal.shade600,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: ESUNRadius.lgRadius,
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Received your Mutual Fund\nPortfolio Value',
                            textAlign: TextAlign.center,
                            style: ESUNTypography.titleMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: ESUNSpacing.md),
                          Text(
                            '₹6,04,247',
                            style: ESUNTypography.displaySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: ESUNSpacing.xs),
                          Text(
                            'across 12 Mutual Funds',
                            style: ESUNTypography.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: ESUNSpacing.xl),
                    
                    // Illustration
                    SizedBox(
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Document/Form illustration
                          Container(
                            width: 100,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 60,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 50,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.teal,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Next',
                                    style: TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Person illustration
                          Positioned(
                            right: 80,
                            bottom: 0,
                            child: Icon(
                              Icons.person,
                              color: Colors.blue.shade700,
                              size: 80,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: ESUNSpacing.xl),
                    
                    // Next Step text
                    Text(
                      'Next Step',
                      style: ESUNTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: ESUNSpacing.sm),
                    Text(
                      'Auto track your Mutual Funds and Equities\ndata to activate personal wealth advisor.',
                      textAlign: TextAlign.center,
                      style: ESUNTypography.bodyMedium.copyWith(
                        color: ESUNColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: ESUNSpacing.lg),
                    Text(
                      '3 Step away from activating auto\ntracking for personal wealth advisor!',
                      textAlign: TextAlign.center,
                      style: ESUNTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: ESUNSpacing.xl),
                    
                    // Trust indicators
                    Row(
                      children: [
                        const Text('🇮🇳', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: ESUNSpacing.sm),
                        Expanded(
                          child: Text(
                            'Used by 1 million customers across India',
                            style: ESUNTypography.bodySmall.copyWith(
                              color: ESUNColors.textSecondary,
                            ),
                          ),
                        ),
                        const Icon(Icons.open_in_new, size: 18, color: ESUNColors.textSecondary),
                      ],
                    ),
                    
                    const SizedBox(height: ESUNSpacing.md),
                    
                    // Secure sharing badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(ESUNSpacing.xs),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check, color: Colors.green.shade700, size: 16),
                        ),
                        const SizedBox(width: ESUNSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Secure & Quick Sharing',
                                style: ESUNTypography.bodySmall.copyWith(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'via RBI-authorised Account Aggregator Services',
                                style: ESUNTypography.bodySmall.copyWith(
                                  color: ESUNColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Continue button
            Padding(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.push(AppRoutes.aaSelectBanks),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ESUNColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue',
                    style: ESUNTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Step 2: Verify OTP Screen
// ============================================================================

class AAVerifyOtpScreen extends ConsumerStatefulWidget {
  const AAVerifyOtpScreen({super.key});

  @override
  ConsumerState<AAVerifyOtpScreen> createState() => _AAVerifyOtpScreenState();
}

class _AAVerifyOtpScreenState extends ConsumerState<AAVerifyOtpScreen> {
  String _otp = '';
  bool _autofilled = false;

  @override
  void initState() {
    super.initState();
    // Auto-fill OTP for prototype after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_autofilled) {
        setState(() {
          _otp = '123456';
          _autofilled = true;
        });
      }
    });
  }

  Future<void> _verify() async {
    if (_otp.length != 6) return;

    final notifier = ref.read(aaOnboardingProvider.notifier);
    final success = await notifier.verifyOtp(_otp);

    if (success && mounted) {
      context.push(AppRoutes.aaActivateTracker);
    }
  }

  Future<void> _resendOtp() async {
    // Re-verify PAN to resend OTP
    final state = ref.read(aaOnboardingProvider);
    if (state.panNumber != null) {
      // Show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP resent successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aaOnboardingProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ESUNColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Indicator
            const AAStepIndicator(currentStep: 2, totalSteps: 4),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(ESUNSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verify OTP',
                      style: ESUNTypography.headlineLarge
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: ESUNSpacing.sm),
                    Text(
                      'Enter the 6-digit code sent to ${state.maskedMobile ?? "your mobile"}',
                      style: ESUNTypography.bodyMedium
                          .copyWith(color: ESUNColors.textSecondary),
                    ),
                    const SizedBox(height: ESUNSpacing.lg),

                    // Prototype hint banner
                    Container(
                      padding: const EdgeInsets.all(ESUNSpacing.md),
                      decoration: BoxDecoration(
                        color: ESUNColors.info.withOpacity(0.1),
                        borderRadius: ESUNRadius.mdRadius,
                        border: Border.all(color: ESUNColors.info.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: ESUNColors.info, size: 20),
                          const SizedBox(width: ESUNSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Prototype Mode',
                                  style: ESUNTypography.labelMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: ESUNColors.info,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Use OTP: 123456',
                                  style: ESUNTypography.bodySmall.copyWith(
                                    color: ESUNColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Quick fill button
                          TextButton(
                            onPressed: () => setState(() => _otp = '123456'),
                            style: TextButton.styleFrom(
                              padding: ESUNSpacing.chipInsets,
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Auto-fill'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: ESUNSpacing.lg),

                    // OTP Field
                    Center(
                      child: FPOtpField(
                        length: 6,
                        onChanged: (value) => setState(() => _otp = value),
                        onCompleted: (value) {
                          setState(() => _otp = value);
                          _verify();
                        },
                      ),
                    ),

                    const SizedBox(height: ESUNSpacing.lg),

                    // Resend OTP
                    Center(
                      child: TextButton(
                        onPressed: _resendOtp,
                        child: Text(
                          "Didn't receive code? Resend",
                          style: ESUNTypography.bodyMedium
                              .copyWith(color: ESUNColors.primary),
                        ),
                      ),
                    ),

                    if (state.error != null) ...[
                      const SizedBox(height: ESUNSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(ESUNSpacing.md),
                        decoration: BoxDecoration(
                          color: ESUNColors.error.withOpacity(0.1),
                          borderRadius: ESUNRadius.mdRadius,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: ESUNColors.error),
                            const SizedBox(width: ESUNSpacing.sm),
                            Expanded(
                              child: Text(
                                state.error!,
                                style: ESUNTypography.bodySmall
                                    .copyWith(color: ESUNColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _otp.length == 6 && !state.isLoading ? _verify : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ESUNColors.primary,
                          disabledBackgroundColor: ESUNColors.border,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                          elevation: 0,
                        ),
                        child: state.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Verify',
                                style: ESUNTypography.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Step 3: Share Accounts Screen (FinFactor Style with Tabs)
// ============================================================================

final fipListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final result =
      await api.get<Map<String, dynamic>>('${ApiConfig.apiPrefix}/aa/fips');

  if (result.isError || result.data?['success'] != true) {
    throw Exception('Failed to load banks');
  }

  return List<Map<String, dynamic>>.from(result.data!['data'] ?? []);
});

// Tab categories for share accounts
enum ShareAccountTab {
  investments,
  bankAccounts,
  deposits,
  insurance,
}

// Mock data for discovered accounts
class DiscoveredAccount {
  final String id;
  final String provider;
  final String providerType;
  final String maskedNumber;
  final String? fundName;
  bool isLinked;
  bool isSelected;

  DiscoveredAccount({
    required this.id,
    required this.provider,
    required this.providerType,
    required this.maskedNumber,
    this.fundName,
    this.isLinked = false,
    this.isSelected = false,
  });
}

class AASelectBanksScreen extends ConsumerStatefulWidget {
  const AASelectBanksScreen({super.key});

  @override
  ConsumerState<AASelectBanksScreen> createState() => _AASelectBanksScreenState();
}

class _AASelectBanksScreenState extends ConsumerState<AASelectBanksScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _insuranceSearchController = TextEditingController();
  
  // Mock discovered accounts for Investments tab
  final List<DiscoveredAccount> _investmentAccounts = [
    DiscoveredAccount(id: '1', provider: 'CDSL', providerType: 'Demat Account', maskedNumber: '••••••••••987', isLinked: true, isSelected: true),
    DiscoveredAccount(id: '2', provider: 'CDSL', providerType: 'Demat Account', maskedNumber: '••••••••••552', isLinked: true, isSelected: true),
    DiscoveredAccount(id: '3', provider: 'CDSL', providerType: 'Demat Account', maskedNumber: '••••••••••160'),
    DiscoveredAccount(id: '4', provider: 'NSDL', providerType: 'Demat Account', maskedNumber: '••••••••••624', isLinked: true, isSelected: true),
    DiscoveredAccount(id: '5', provider: 'NSDL', providerType: 'Demat Account', maskedNumber: '••••••••••906'),
    DiscoveredAccount(id: '6', provider: 'CAMS', providerType: 'Mutual Fund', maskedNumber: '0245', fundName: 'ICICI Prudential'),
    DiscoveredAccount(id: '7', provider: 'CAMS', providerType: 'Mutual Fund', maskedNumber: '0245', fundName: 'Quant'),
    DiscoveredAccount(id: '8', provider: 'KFIN', providerType: 'Mutual Fund', maskedNumber: '0245', fundName: 'Parag Parekh'),
    DiscoveredAccount(id: '9', provider: 'KFIN', providerType: 'Mutual Fund', maskedNumber: '0245', fundName: 'HDFC Mutual Fund'),
  ];

  // Mock discovered bank accounts
  final List<DiscoveredAccount> _bankAccounts = [
    DiscoveredAccount(id: 'b1', provider: 'Axis Bank', providerType: 'Bank', maskedNumber: '0245', fundName: 'Savings Account', isLinked: true),
    DiscoveredAccount(id: 'b2', provider: 'Axis Bank', providerType: 'Bank', maskedNumber: '1207', fundName: 'Savings Account', isLinked: true, isSelected: true),
    DiscoveredAccount(id: 'b3', provider: 'HDFC Bank', providerType: 'Bank', maskedNumber: '2785', fundName: 'Savings Account', isLinked: true, isSelected: true),
  ];

  // Mock discovered deposits (FD/RD)
  final List<DiscoveredAccount> _depositAccounts = [
    DiscoveredAccount(id: 'd1', provider: 'Axis Bank', providerType: 'Deposit', maskedNumber: '0245', fundName: 'Recurring Deposit', isLinked: true),
    DiscoveredAccount(id: 'd2', provider: 'Axis Bank', providerType: 'Deposit', maskedNumber: '1207', fundName: 'Fixed Deposit', isLinked: true, isSelected: true),
    DiscoveredAccount(id: 'd3', provider: 'HDFC Bank', providerType: 'Deposit', maskedNumber: '2785', fundName: 'Fixed Deposit', isLinked: true, isSelected: true),
  ];

  // Mock discovered insurance policies
  final List<DiscoveredAccount> _insurancePolicies = [
    DiscoveredAccount(id: 'i1', provider: 'HDFC Life Insurance', providerType: 'Insurance', maskedNumber: 'XX1503', fundName: 'Policy number', isLinked: true),
    DiscoveredAccount(id: 'i2', provider: 'HDFC Life Insurance', providerType: 'Insurance', maskedNumber: 'XX1870', fundName: 'Policy number', isLinked: true, isSelected: true),
    DiscoveredAccount(id: 'i3', provider: 'HDFC Ergo', providerType: 'Insurance', maskedNumber: 'XX1352', fundName: 'Policy number', isLinked: true, isSelected: true),
  ];

  // Insurance providers list with logo URLs
  final List<Map<String, dynamic>> _insuranceProviders = [
    {'name': 'HDFC Life Insurance', 'icon': Icons.shield, 'color': const Color(0xFF004C8F), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://hdfclife.com&size=128'},
    {'name': 'HDFC Ergo', 'icon': Icons.shield, 'color': const Color(0xFFED1C24), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://hdfcergo.com&size=128'},
    {'name': 'TATA AIA Life Insurance', 'icon': Icons.shield, 'color': const Color(0xFF001F5C), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://tataaia.com&size=128'},
    {'name': 'ACKO Life Insurance Limited', 'icon': Icons.shield, 'color': const Color(0xFF6B46C1), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://acko.com&size=128'},
    {'name': 'LIC of India', 'icon': Icons.shield, 'color': const Color(0xFF003399), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://licindia.in&size=128'},
    {'name': 'ICICI Prudential', 'icon': Icons.shield, 'color': const Color(0xFFB02A30), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://iciciprulife.com&size=128'},
    {'name': 'SBI Life Insurance', 'icon': Icons.shield, 'color': const Color(0xFF22409A), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://sbilife.co.in&size=128'},
    {'name': 'Max Life Insurance', 'icon': Icons.shield, 'color': const Color(0xFF0066CC), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://maxlifeinsurance.com&size=128'},
    {'name': 'National Insurance Company', 'icon': Icons.shield, 'color': const Color(0xFFED1C24), 'comingSoon': true},
  ];
  final Set<String> _selectedInsuranceProviders = {};

  // State flags
  bool _isSearchingDeposits = true;
  bool _isSearchingInsurance = false;
  bool _depositsSearchComplete = false;
  bool _insuranceSearchComplete = false;

  // Comprehensive Indian Banks list with logo URLs
  final List<Map<String, dynamic>> _banks = [
    // Public Sector Banks
    {'name': 'State Bank of India', 'color': const Color(0xFF22409A), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://onlinesbi.sbi&size=128'},
    {'name': 'Punjab National Bank', 'color': const Color(0xFFED1C24), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://pnbindia.in&size=128'},
    {'name': 'Bank of Baroda', 'color': const Color(0xFFF15A22), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://bankofbaroda.in&size=128'},
    {'name': 'Canara Bank', 'color': const Color(0xFF0066B3), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://canarabank.com&size=128'},
    {'name': 'Union Bank of India', 'color': const Color(0xFFED1C24), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://unionbankofindia.co.in&size=128'},
    {'name': 'Bank of India', 'color': const Color(0xFFFF6600), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://bankofindia.co.in&size=128'},
    {'name': 'Indian Bank', 'color': const Color(0xFF1B3A6D), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://indianbank.in&size=128'},
    {'name': 'Central Bank of India', 'color': const Color(0xFF0055A5), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://centralbank.net.in&size=128'},
    {'name': 'Indian Overseas Bank', 'color': const Color(0xFF003399), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://iob.in&size=128'},
    {'name': 'UCO Bank', 'color': const Color(0xFF000066), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://ucobank.com&size=128'},
    {'name': 'Bank of Maharashtra', 'color': const Color(0xFF003D7C), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://bankofmaharashtra.in&size=128'},
    {'name': 'Punjab & Sind Bank', 'color': const Color(0xFF1E4D8C), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://psbindia.com&size=128'},
    
    // Private Sector Banks
    {'name': 'HDFC Bank', 'color': const Color(0xFF004C8F), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://hdfcbank.com&size=128'},
    {'name': 'ICICI Bank', 'color': const Color(0xFFB02A30), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://icicibank.com&size=128'},
    {'name': 'Axis Bank', 'color': const Color(0xFF97144D), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://axisbank.com&size=128'},
    {'name': 'Kotak Mahindra Bank', 'color': const Color(0xFFED1C24), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://kotak.com&size=128'},
    {'name': 'IndusInd Bank', 'color': const Color(0xFF6D1F7A), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://indusind.com&size=128'},
    {'name': 'Yes Bank', 'color': const Color(0xFF0033A0), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://yesbank.co.in&size=128'},
    {'name': 'IDFC First Bank', 'color': const Color(0xFFE31837), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://idfcfirstbank.com&size=128'},
    {'name': 'Federal Bank', 'color': const Color(0xFFED1C24), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://federalbank.co.in&size=128'},
    {'name': 'South Indian Bank', 'color': const Color(0xFF0072BC), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://southindianbank.com&size=128'},
    {'name': 'Karnataka Bank', 'color': const Color(0xFFE31837), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://karnatakabank.com&size=128'},
    {'name': 'Karur Vysya Bank', 'color': const Color(0xFF003399), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://kvb.in&size=128'},
    {'name': 'Bandhan Bank', 'color': const Color(0xFFE84E0F), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://bandhanbank.com&size=128'},
    {'name': 'RBL Bank', 'color': const Color(0xFF0066B3), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://rblbank.com&size=128'},
    {'name': 'City Union Bank', 'color': const Color(0xFF0072BC), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://cityunionbank.com&size=128'},
    {'name': 'Tamilnad Mercantile Bank', 'color': const Color(0xFF0052A5), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://tmb.in&size=128'},
    {'name': 'DCB Bank', 'color': const Color(0xFF6B1F7A), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://dcbbank.com&size=128'},
    {'name': 'Dhanlaxmi Bank', 'color': const Color(0xFFE31837), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://dhanlaxmibank.com&size=128'},
    
    // Small Finance Banks
    {'name': 'AU Small Finance Bank', 'color': const Color(0xFFE84E0F), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://aubank.in&size=128'},
    {'name': 'Equitas Small Finance Bank', 'color': const Color(0xFF003399), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://equitasbank.com&size=128'},
    {'name': 'Ujjivan Small Finance Bank', 'color': const Color(0xFF009639), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://ujjivansfb.in&size=128'},
    
    // Payments Banks
    {'name': 'Paytm Payments Bank', 'color': const Color(0xFF00B9F5), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://paytm.com&size=128'},
    {'name': 'Airtel Payments Bank', 'color': const Color(0xFFED1C24), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://airtel.in&size=128'},
    {'name': 'India Post Payments Bank', 'color': const Color(0xFFED1C24), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://ippbonline.com&size=128'},
    {'name': 'Fino Payments Bank', 'color': const Color(0xFF1E3A5F), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://finobank.com&size=128'},
    {'name': 'Jio Payments Bank', 'color': const Color(0xFF0A3D92), 'logoUrl': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://jio.com&size=128'},
  ];
  final Set<String> _selectedBanks = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Simulate deposits search completing after 2 seconds
    _simulateDepositsSearch();
  }

  void _onTabChanged() {
    // Rebuild to update button text (Next vs Proceed)
    setState(() {});
    
    if (_tabController.index == 2 && !_depositsSearchComplete && !_isSearchingDeposits) {
      setState(() => _isSearchingDeposits = true);
      _simulateDepositsSearch();
    }
  }

  void _simulateDepositsSearch() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isSearchingDeposits = false;
          _depositsSearchComplete = true;
        });
      }
    });
  }

  void _simulateInsuranceSearch() {
    setState(() {
      _isSearchingInsurance = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isSearchingInsurance = false;
          _insuranceSearchComplete = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _insuranceSearchController.dispose();
    super.dispose();
  }

  String _getTabTitle(ShareAccountTab tab) {
    switch (tab) {
      case ShareAccountTab.investments:
        return 'Investments';
      case ShareAccountTab.bankAccounts:
        return 'Bank Accounts';
      case ShareAccountTab.deposits:
        return 'Deposits (FD & RD)';
      case ShareAccountTab.insurance:
        return 'Insurance';
    }
  }

  IconData _getTabIcon(ShareAccountTab tab) {
    switch (tab) {
      case ShareAccountTab.investments:
        return Icons.trending_up;
      case ShareAccountTab.bankAccounts:
        return Icons.account_balance;
      case ShareAccountTab.deposits:
        return Icons.savings;
      case ShareAccountTab.insurance:
        return Icons.shield_outlined;
    }
  }

  void _showLinkOtpBottomSheet(String providerName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LinkAccountOtpBottomSheet(
        providerName: providerName,
        onSuccess: () {
          setState(() {
            for (final acc in _investmentAccounts.where((a) => a.provider == providerName)) {
              if (acc.isSelected) {
                acc.isLinked = true;
              }
            }
          });
        },
      ),
    );
  }

  void _showBankOtpBottomSheet(String bankName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BankOtpBottomSheet(
        bankName: bankName,
        onSuccess: () {
          setState(() {
            for (final acc in _bankAccounts.where((a) => a.provider == bankName)) {
              acc.isLinked = true;
            }
          });
        },
      ),
    );
  }

  bool get _hasSelectedAccounts {
    return _investmentAccounts.any((a) => a.isSelected) || 
           _bankAccounts.any((a) => a.isSelected) ||
           _depositAccounts.any((a) => a.isSelected) ||
           _insurancePolicies.any((a) => a.isSelected) ||
           _selectedBanks.isNotEmpty;
  }

  void _showAddMoreBottomSheet({required ShareAccountTab forTab}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMoreProvidersSheet(
        tabType: forTab,
        banks: _banks,
        insuranceProviders: _insuranceProviders,
        onBankSelected: (bankName) {
          setState(() {
            _selectedBanks.add(bankName);
            // Add mock discovered accounts for the new bank
            if (forTab == ShareAccountTab.bankAccounts) {
              _bankAccounts.add(DiscoveredAccount(
                id: 'b${DateTime.now().millisecondsSinceEpoch}',
                provider: bankName,
                providerType: 'Bank',
                maskedNumber: '••••${(1000 + _bankAccounts.length).toString().substring(1)}',
                fundName: 'Savings Account',
                isLinked: false,
              ));
            } else if (forTab == ShareAccountTab.deposits) {
              _depositAccounts.add(DiscoveredAccount(
                id: 'd${DateTime.now().millisecondsSinceEpoch}',
                provider: bankName,
                providerType: 'Deposit',
                maskedNumber: '••••${(1000 + _depositAccounts.length).toString().substring(1)}',
                fundName: 'Fixed Deposit',
                isLinked: false,
              ));
            }
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$bankName added. Searching for accounts...')),
          );
        },
        onInsuranceProviderSelected: (providerName) {
          setState(() {
            _selectedInsuranceProviders.add(providerName);
            _insurancePolicies.add(DiscoveredAccount(
              id: 'i${DateTime.now().millisecondsSinceEpoch}',
              provider: providerName,
              providerType: 'Insurance',
              maskedNumber: 'XX${(1000 + _insurancePolicies.length).toString().substring(1)}',
              fundName: 'Policy number',
              isLinked: false,
            ));
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$providerName added. Searching for policies...')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ESUNColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Share Accounts',
          style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_outlined, color: ESUNColors.textSecondary),
            onPressed: () {},
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              'Aa/अ',
              style: ESUNTypography.labelMedium.copyWith(color: ESUNColors.textSecondary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Step Indicator
          const AAStepIndicator(currentStep: 3, totalSteps: 4),
          
          // Tab Bar
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: ESUNColors.border)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: ESUNColors.primary,
              unselectedLabelColor: ESUNColors.textSecondary,
              labelStyle: ESUNTypography.labelSmall.copyWith(fontWeight: FontWeight.w600),
              unselectedLabelStyle: ESUNTypography.labelSmall,
              indicatorColor: ESUNColors.primary,
              indicatorWeight: 3,
              labelPadding: EdgeInsets.zero,
              tabs: ShareAccountTab.values.map((tab) {
                return Tab(
                  height: 56,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_getTabIcon(tab), size: 18),
                      const SizedBox(height: 2),
                      Text(
                        _getTabTitle(tab),
                        style: const TextStyle(fontSize: 9),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInvestmentsTab(),
                _buildBankAccountsTab(),
                _buildDepositsTab(),
                _buildInsuranceTab(),
              ],
            ),
          ),
          
          // Next/Proceed Button
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  // If not on last tab, go to next tab
                  if (_tabController.index < 3) {
                    _tabController.animateTo(_tabController.index + 1);
                  } else {
                    // On last tab (Insurance), proceed to final consent
                    if (_hasSelectedAccounts) {
                      context.push(AppRoutes.aaFinalStepConsent);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ESUNColors.primary,
                  disabledBackgroundColor: ESUNColors.border,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _tabController.index < 3 ? 'Next' : 'Proceed',
                  style: ESUNTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          
          // Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.sm),
            color: ESUNColors.primary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Powered by RBI-Regulated AA',
                  style: ESUNTypography.bodySmall.copyWith(color: Colors.white),
                ),
                const SizedBox(width: ESUNSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'FINVU',
                    style: ESUNTypography.labelSmall.copyWith(
                      color: ESUNColors.primary,
                      fontWeight: FontWeight.bold,
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

  Widget _buildInvestmentsTab() {
    // Group accounts by provider
    final grouped = <String, List<DiscoveredAccount>>{};
    for (final acc in _investmentAccounts) {
      grouped.putIfAbsent(acc.provider, () => []).add(acc);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Select accounts to link',
            style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: ESUNSpacing.xs),
          Text(
            'We have discovered the following accounts linked to you.\nPlease select the ones you want to continue with',
            style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          
          // "See what you will share" dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: ESUNColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Text('See what you will share', style: ESUNTypography.bodyMedium),
                Spacer(),
                Icon(Icons.keyboard_arrow_down, color: ESUNColors.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          
          // Account groups
          ...grouped.entries.map((entry) {
            final provider = entry.key;
            final accounts = entry.value;
            final providerType = accounts.first.providerType;
            final hasUnlinked = accounts.any((a) => !a.isLinked && a.isSelected);
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Provider header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider,
                            style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            providerType,
                            style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (hasUnlinked || accounts.any((a) => a.isSelected && a.isLinked))
                      ElevatedButton(
                        onPressed: () => _showLinkOtpBottomSheet(provider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ESUNColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: Text('Link Now', style: ESUNTypography.labelMedium.copyWith(color: Colors.white)),
                      ),
                  ],
                ),
                const SizedBox(height: ESUNSpacing.sm),
                
                // Accounts list
                ...accounts.map((account) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        account.isSelected = !account.isSelected;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account.fundName != null 
                                      ? '${account.fundName} • ${account.maskedNumber}'
                                      : account.maskedNumber,
                                  style: ESUNTypography.bodyMedium,
                                ),
                                if (account.isLinked)
                                  Text(
                                    'Linked',
                                    style: ESUNTypography.bodySmall.copyWith(
                                      color: Colors.green.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: account.isSelected ? ESUNColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: account.isSelected ? ESUNColors.primary : ESUNColors.border,
                                width: 2,
                              ),
                            ),
                            child: account.isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                
                const Divider(height: 24),
              ],
            );
          }),
          
          // Tip banner
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.md),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: ESUNRadius.mdRadius,
            ),
            child: Row(
              children: [
                Icon(Icons.bolt, color: Colors.amber.shade800, size: 24),
                const SizedBox(width: ESUNSpacing.sm),
                Expanded(
                  child: Text(
                    'Select All for regular updates and optimize your mutual fund portfolio with your goals',
                    style: ESUNTypography.bodySmall.copyWith(color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountsTab() {
    // Group bank accounts by bank
    final accountsByBank = <String, List<DiscoveredAccount>>{};
    for (final account in _bankAccounts) {
      accountsByBank.putIfAbsent(account.provider, () => []).add(account);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Select accounts to share',
            style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          
          // Summary Card
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            decoration: BoxDecoration(
              color: ESUNColors.surface,
              borderRadius: ESUNRadius.lgRadius,
              border: Border.all(color: ESUNColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bank Accounts header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.account_balance, size: 20, color: ESUNColors.textSecondary),
                    ),
                    const SizedBox(width: ESUNSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bank Accounts', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                        Text('${_bankAccounts.length} accounts discovered', style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: ESUNSpacing.md),
                
                // Dropdown hint
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.md, vertical: ESUNSpacing.sm),
                  decoration: BoxDecoration(
                    border: Border.all(color: ESUNColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('See what you will share', style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textSecondary)),
                      const Icon(Icons.keyboard_arrow_down, color: ESUNColors.textSecondary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          
          // Select instruction
          Text(
            'Select at least 1 account to share from',
            style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textSecondary),
          ),
          const SizedBox(height: ESUNSpacing.md),
          
          // Accounts grouped by bank
          ...accountsByBank.entries.map((entry) {
            final bankName = entry.key;
            final accounts = entry.value;
            final bankData = _banks.firstWhere(
              (b) => b['name'] == bankName,
              orElse: () => {'color': ESUNColors.primary, 'logoUrl': null},
            );
            final hasUnlinkedAccounts = accounts.any((a) => !a.isLinked);
            final hasLogo = bankData['logoUrl'] != null;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bank header
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: (bankData['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: hasLogo
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: SmartNetworkImage(
                                imageUrl: bankData['logoUrl'] as String,
                                width: 22,
                                height: 22,
                                fit: BoxFit.contain,
                                placeholderIcon: Icons.account_balance,
                                placeholderColor: bankData['color'] as Color,
                                errorBuilder: (_, __, ___) => Icon(Icons.account_balance, size: 14, color: bankData['color'] as Color),
                              ),
                            )
                          : Icon(Icons.account_balance, size: 14, color: bankData['color'] as Color),
                    ),
                    const SizedBox(width: ESUNSpacing.sm),
                    Expanded(
                      child: Text(bankName, style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    if (hasUnlinkedAccounts)
                      ElevatedButton(
                        onPressed: () => _showBankOtpBottomSheet(bankName),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ESUNColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: Text('Link Now', style: ESUNTypography.labelMedium.copyWith(color: Colors.white)),
                      ),
                  ],
                ),
                const SizedBox(height: ESUNSpacing.sm),
                
                // Account list
                ...accounts.map((account) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        account.isSelected = !account.isSelected;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${account.fundName} • ${account.maskedNumber}',
                                  style: ESUNTypography.bodyMedium,
                                ),
                                if (account.isLinked)
                                  Text(
                                    'Linked',
                                    style: ESUNTypography.bodySmall.copyWith(
                                      color: Colors.green.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: account.isSelected ? ESUNColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: account.isSelected ? ESUNColors.primary : ESUNColors.border,
                                width: 2,
                              ),
                            ),
                            child: account.isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                
                const Divider(height: 24),
              ],
            );
          }),
          
          // Missing accounts link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Missing any accounts?', style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textSecondary)),
              TextButton.icon(
                onPressed: () => _showAddMoreBottomSheet(forTab: ShareAccountTab.bankAccounts),
                icon: const Icon(Icons.add_circle_outline, size: 18, color: ESUNColors.primary),
                label: Text('Add More', style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDepositsTab() {
    // Show searching state
    if (_isSearchingDeposits) {
      return _buildSearchingState(
        icon: Icons.savings,
        title: 'Deposits (FD & RD)',
        message: 'Searching for accounts in your selected banks',
        subMessage: 'Give us a few minutes as we use your phone number to discover these accounts',
      );
    }

    // Group deposit accounts by bank
    final accountsByBank = <String, List<DiscoveredAccount>>{};
    for (final account in _depositAccounts) {
      accountsByBank.putIfAbsent(account.provider, () => []).add(account);
    }
    
    // Count FDs and RDs
    final fdCount = _depositAccounts.where((a) => a.fundName?.contains('Fixed') ?? false).length;
    final rdCount = _depositAccounts.where((a) => a.fundName?.contains('Recurring') ?? false).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Select accounts to share',
            style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          
          // Summary Card
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            decoration: BoxDecoration(
              color: ESUNColors.surface,
              borderRadius: ESUNRadius.lgRadius,
              border: Border.all(color: ESUNColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.savings, size: 20, color: ESUNColors.textSecondary),
                    ),
                    const SizedBox(width: ESUNSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bank Accounts', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                        Text('$fdCount FDs & $rdCount RD found', style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: ESUNSpacing.md),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.md, vertical: ESUNSpacing.sm),
                  decoration: BoxDecoration(
                    border: Border.all(color: ESUNColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('See what you will share', style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textSecondary)),
                      const Icon(Icons.keyboard_arrow_down, color: ESUNColors.textSecondary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          
          Text(
            'Select at least 1 account to share from',
            style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textSecondary),
          ),
          const SizedBox(height: ESUNSpacing.md),
          
          // Accounts grouped by bank
          ...accountsByBank.entries.map((entry) {
            final bankName = entry.key;
            final accounts = entry.value;
            final bankData = _banks.firstWhere(
              (b) => b['name'] == bankName,
              orElse: () => {'color': ESUNColors.primary, 'logoUrl': null},
            );
            final hasLogo = bankData['logoUrl'] != null;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bank header
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: (bankData['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: hasLogo
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: SmartNetworkImage(
                                imageUrl: bankData['logoUrl'] as String,
                                width: 22,
                                height: 22,
                                fit: BoxFit.contain,
                                placeholderIcon: Icons.account_balance,
                                placeholderColor: bankData['color'] as Color,
                                errorBuilder: (_, __, ___) => Icon(Icons.account_balance, size: 14, color: bankData['color'] as Color),
                              ),
                            )
                          : Icon(Icons.account_balance, size: 14, color: bankData['color'] as Color),
                    ),
                    const SizedBox(width: ESUNSpacing.sm),
                    Text(bankName, style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: ESUNSpacing.sm),
                
                ...accounts.map((account) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        account.isSelected = !account.isSelected;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${account.fundName} • ${account.maskedNumber}',
                                  style: ESUNTypography.bodyMedium,
                                ),
                                if (account.isLinked)
                                  Text(
                                    'Linked',
                                    style: ESUNTypography.bodySmall.copyWith(
                                      color: Colors.green.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: account.isSelected ? ESUNColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: account.isSelected ? ESUNColors.primary : ESUNColors.border,
                                width: 2,
                              ),
                            ),
                            child: account.isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                
                const Divider(height: 24),
              ],
            );
          }),
          
          // Missing accounts link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Missing any accounts?', style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textSecondary)),
              TextButton.icon(
                onPressed: () => _showAddMoreBottomSheet(forTab: ShareAccountTab.deposits),
                icon: const Icon(Icons.add_circle_outline, size: 18, color: ESUNColors.primary),
                label: Text('Add More', style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsuranceTab() {
    // Show searching state
    if (_isSearchingInsurance) {
      return _buildSearchingState(
        icon: Icons.shield_outlined,
        title: 'Insurance',
        message: 'Searching for Insurance schemes',
        subMessage: 'Give us a few seconds as we search',
      );
    }

    // If insurance search is complete, show discovered policies
    if (_insuranceSearchComplete) {
      return _buildInsurancePoliciesList();
    }

    // Show provider selection
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Select in which your Insurance schemes are present',
            style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          
          // Card
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            decoration: BoxDecoration(
              color: ESUNColors.surface,
              borderRadius: ESUNRadius.lgRadius,
              border: Border.all(color: ESUNColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pick at least one to proceed',
                  style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: ESUNSpacing.md),
                
                // Search field
                TextField(
                  controller: _insuranceSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search Here',
                    prefixIcon: const Icon(Icons.search, color: ESUNColors.textSecondary),
                    suffixIcon: const Icon(Icons.mic, color: ESUNColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: ESUNColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: ESUNColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: ESUNSpacing.md),
                
                // Insurance providers list
                ..._insuranceProviders.where((p) => p['comingSoon'] != true).map((provider) {
                  final isSelected = _selectedInsuranceProviders.contains(provider['name']);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedInsuranceProviders.remove(provider['name']);
                        } else {
                          _selectedInsuranceProviders.add(provider['name'] as String);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.md),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: (provider['color'] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(Icons.shield, size: 18, color: provider['color'] as Color),
                          ),
                          const SizedBox(width: ESUNSpacing.md),
                          Expanded(
                            child: Text(provider['name'] as String, style: ESUNTypography.bodyMedium),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected ? ESUNColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected ? ESUNColors.primary : ESUNColors.border,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                
                const SizedBox(height: ESUNSpacing.md),
                Text(
                  'More insurance companies coming soon...',
                  style: ESUNTypography.bodySmall.copyWith(
                    color: ESUNColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: ESUNSpacing.sm),
                
                // Coming soon provider with Notify Me
                ..._insuranceProviders.where((p) => p['comingSoon'] == true).map((provider) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.sm),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: (provider['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(Icons.shield, size: 18, color: provider['color'] as Color),
                        ),
                        const SizedBox(width: ESUNSpacing.md),
                        Expanded(
                          child: Text(
                            provider['name'] as String,
                            style: ESUNTypography.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.notifications_outlined, size: 16, color: ESUNColors.primary),
                          label: Text('Notify Me', style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.primary)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          
          // Search button if providers selected
          if (_selectedInsuranceProviders.isNotEmpty) ...[
            const SizedBox(height: ESUNSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _simulateInsuranceSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ESUNColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text('Search Policies', style: ESUNTypography.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchingState({
    required IconData icon,
    required String title,
    required String message,
    required String subMessage,
  }) {
    return Column(
      children: [
        const SizedBox(height: ESUNSpacing.xl),
        // Green header banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
          padding: const EdgeInsets.all(ESUNSpacing.lg),
          decoration: const BoxDecoration(
            color: Color(0xFF1B5E20),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: ESUNSpacing.sm),
              Text(
                title,
                style: ESUNTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        
        // Searching content
        Container(
          margin: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
          padding: const EdgeInsets.all(ESUNSpacing.xl),
          decoration: BoxDecoration(
            color: ESUNColors.surface,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            border: Border.all(color: ESUNColors.border),
          ),
          child: Column(
            children: [
              Text(
                'Searching...',
                style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textSecondary),
              ),
              const SizedBox(height: ESUNSpacing.lg),
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(ESUNColors.textSecondary),
                ),
              ),
              const SizedBox(height: ESUNSpacing.lg),
              Text(
                message,
                style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ESUNSpacing.sm),
              Text(
                subMessage,
                style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsurancePoliciesList() {
    // Group policies by provider
    final policiesByProvider = <String, List<DiscoveredAccount>>{};
    for (final policy in _insurancePolicies) {
      policiesByProvider.putIfAbsent(policy.provider, () => []).add(policy);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Select policies to share',
            style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          
          // Summary Card
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            decoration: BoxDecoration(
              color: ESUNColors.surface,
              borderRadius: ESUNRadius.lgRadius,
              border: Border.all(color: ESUNColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shield_outlined, size: 20, color: ESUNColors.textSecondary),
                    ),
                    const SizedBox(width: ESUNSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Insurance', style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                        Text('${_insurancePolicies.length} policies found!', style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: ESUNSpacing.md),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.md, vertical: ESUNSpacing.sm),
                  decoration: BoxDecoration(
                    border: Border.all(color: ESUNColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('See what you will share', style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textSecondary)),
                      const Icon(Icons.keyboard_arrow_down, color: ESUNColors.textSecondary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          
          Text(
            'Select at least 1 policy to share from',
            style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textSecondary),
          ),
          const SizedBox(height: ESUNSpacing.md),
          
          // Policies grouped by provider
          ...policiesByProvider.entries.map((entry) {
            final providerName = entry.key;
            final policies = entry.value;
            final providerData = _insuranceProviders.firstWhere(
              (p) => p['name'] == providerName,
              orElse: () => {'color': ESUNColors.primary, 'icon': Icons.shield},
            );
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Provider header
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: (providerData['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.shield, size: 14, color: providerData['color'] as Color),
                    ),
                    const SizedBox(width: ESUNSpacing.sm),
                    Text(providerName, style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: ESUNSpacing.sm),
                
                ...policies.map((policy) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        policy.isSelected = !policy.isSelected;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${policy.fundName} ${policy.maskedNumber}',
                                  style: ESUNTypography.bodyMedium,
                                ),
                                if (policy.isLinked)
                                  Text(
                                    'Linked',
                                    style: ESUNTypography.bodySmall.copyWith(
                                      color: Colors.green.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: policy.isSelected ? ESUNColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: policy.isSelected ? ESUNColors.primary : ESUNColors.border,
                                width: 2,
                              ),
                            ),
                            child: policy.isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                
                const Divider(height: 24),
              ],
            );
          }),
          
          // Missing accounts link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Missing any accounts?', style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textSecondary)),
              TextButton.icon(
                onPressed: () => _showAddMoreBottomSheet(forTab: ShareAccountTab.insurance),
                icon: const Icon(Icons.add_circle_outline, size: 18, color: ESUNColors.primary),
                label: Text('Add More', style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Add More Providers Bottom Sheet
class _AddMoreProvidersSheet extends StatefulWidget {
  final ShareAccountTab tabType;
  final List<Map<String, dynamic>> banks;
  final List<Map<String, dynamic>> insuranceProviders;
  final Function(String) onBankSelected;
  final Function(String) onInsuranceProviderSelected;

  const _AddMoreProvidersSheet({
    required this.tabType,
    required this.banks,
    required this.insuranceProviders,
    required this.onBankSelected,
    required this.onInsuranceProviderSelected,
  });

  @override
  State<_AddMoreProvidersSheet> createState() => _AddMoreProvidersSheetState();
}

class _AddMoreProvidersSheetState extends State<_AddMoreProvidersSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredProviders {
    final providers = widget.tabType == ShareAccountTab.insurance
        ? widget.insuranceProviders
        : widget.banks;
    
    if (_searchQuery.isEmpty) return providers;
    return providers.where((p) => 
      (p['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isInsurance = widget.tabType == ShareAccountTab.insurance;
    final title = isInsurance ? 'Add Insurance Provider' : 'Add Bank';
    final subtitle = isInsurance 
        ? 'Select an insurance provider to discover policies'
        : 'Select a bank to discover accounts';

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ESUNColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(subtitle, style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textSecondary)),
              ],
            ),
          ),
          
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search ${isInsurance ? "providers" : "banks"}...',
                prefixIcon: const Icon(Icons.search, color: ESUNColors.textSecondary),
                filled: true,
                fillColor: ESUNColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: ESUNSpacing.md),
          
          // Providers list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
              itemCount: _filteredProviders.length,
              itemBuilder: (context, index) {
                final provider = _filteredProviders[index];
                final isComingSoon = provider['comingSoon'] == true;
                final hasLogo = provider['logoUrl'] != null;
                
                return ListTile(
                  onTap: isComingSoon ? null : () {
                    if (isInsurance) {
                      widget.onInsuranceProviderSelected(provider['name'] as String);
                    } else {
                      widget.onBankSelected(provider['name'] as String);
                    }
                  },
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (provider['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: hasLogo
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SmartNetworkImage(
                              imageUrl: provider['logoUrl'] as String,
                              width: 32,
                              height: 32,
                              fit: BoxFit.contain,
                              placeholderIcon: Icons.account_balance,
                              placeholderColor: provider['color'] as Color,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.account_balance,
                                color: provider['color'] as Color,
                                size: 20,
                              ),
                            ),
                          )
                        : Icon(
                            provider['icon'] as IconData? ?? Icons.account_balance,
                            color: provider['color'] as Color,
                            size: 20,
                          ),
                  ),
                  title: Text(
                    provider['name'] as String,
                    style: ESUNTypography.bodyMedium.copyWith(
                      color: isComingSoon ? ESUNColors.textSecondary : ESUNColors.textPrimary,
                    ),
                  ),
                  trailing: isComingSoon
                      ? Container(
                          padding: ESUNSpacing.badgeInsets,
                          decoration: BoxDecoration(
                            color: ESUNColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Coming Soon',
                            style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.textSecondary),
                          ),
                        )
                      : const Icon(Icons.arrow_forward_ios, size: 16, color: ESUNColors.textSecondary),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Link Account OTP Bottom Sheet
class _LinkAccountOtpBottomSheet extends StatefulWidget {
  final String providerName;
  final VoidCallback onSuccess;

  const _LinkAccountOtpBottomSheet({
    required this.providerName,
    required this.onSuccess,
  });

  @override
  State<_LinkAccountOtpBottomSheet> createState() => _LinkAccountOtpBottomSheetState();
}

class _LinkAccountOtpBottomSheetState extends State<_LinkAccountOtpBottomSheet> {
  String _otp = '';
  int _countdown = 179;
  bool _isLoading = false;
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Listen to focus changes to update cursor indicator
    _otpFocusNode.addListener(_onFocusChange);
    // Auto-focus the OTP input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpFocusNode.requestFocus();
    });
  }

  void _onFocusChange() {
    setState(() {}); // Rebuild to show/hide cursor indicator
  }

  @override
  void dispose() {
    _otpFocusNode.removeListener(_onFocusChange);
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_countdown > 0) {
        setState(() => _countdown--);
        return true;
      }
      return false;
    });
  }

  String get _formattedTime {
    final minutes = _countdown ~/ 60;
    final seconds = _countdown % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get _providerFullName {
    switch (widget.providerName) {
      case 'CDSL':
        return 'Central Depository Services (India)';
      case 'NSDL':
        return 'National Depository Services (India)';
      default:
        return widget.providerName;
    }
  }

  Future<void> _submitOtp() async {
    if (_otp.length != 6) return;

    setState(() => _isLoading = true);
    
    // Simulate OTP verification
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.of(context).pop();
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.providerName} accounts linked successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOtpComplete = _otp.length == 6;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Close button
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(ESUNSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Please verify OTP',
                  style: ESUNTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: ESUNSpacing.xs),
                Text(
                  'You will receive OTP from $_providerFullName',
                  style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textSecondary),
                ),
                const SizedBox(height: ESUNSpacing.xl),
                
                // OTP Card
                Container(
                  padding: const EdgeInsets.all(ESUNSpacing.lg),
                  decoration: BoxDecoration(
                    color: ESUNColors.surface,
                    borderRadius: ESUNRadius.lgRadius,
                    border: Border.all(color: ESUNColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('OTP sent to ', style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
                          Text('+91 80361 73887', style: ESUNTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          const Icon(Icons.edit_outlined, size: 18, color: ESUNColors.textSecondary),
                        ],
                      ),
                      const SizedBox(height: ESUNSpacing.lg),
                      
                      // OTP Input boxes with hidden TextField
                      GestureDetector(
                        onTap: () {
                          _otpFocusNode.requestFocus();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          height: 56,
                          child: Stack(
                            children: [
                              // Hidden TextField for keyboard input
                              Positioned.fill(
                                child: TextField(
                                  controller: _otpController,
                                  focusNode: _otpFocusNode,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  autofocus: true,
                                  style: const TextStyle(
                                    color: Colors.transparent,
                                    height: 0.01,
                                    fontSize: 1,
                                  ),
                                  showCursor: false,
                                  onChanged: (value) {
                                    setState(() {
                                      _otp = value.replaceAll(RegExp(r'[^0-9]'), '');
                                      if (_otp.length > 6) _otp = _otp.substring(0, 6);
                                    });
                                    // Auto-submit when 6 digits entered
                                    if (_otp.length == 6) {
                                      _submitOtp();
                                    }
                                  },
                                  decoration: const InputDecoration(
                                    counterText: '',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              // Visual OTP boxes
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(6, (index) {
                                  final hasDigit = index < _otp.length;
                                  final isCurrentBox = index == _otp.length && _otpFocusNode.hasFocus;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 46,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isCurrentBox 
                                            ? ESUNColors.primary 
                                            : (hasDigit ? ESUNColors.primary : ESUNColors.border),
                                        width: isCurrentBox ? 2 : (hasDigit ? 2 : 1),
                                      ),
                                      boxShadow: isCurrentBox ? [
                                        BoxShadow(
                                          color: ESUNColors.primary.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ] : null,
                                    ),
                                    child: Center(
                                      child: hasDigit
                                          ? Text(
                                              _otp[index],
                                              style: ESUNTypography.headlineSmall.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: ESUNColors.textPrimary,
                                              ),
                                            )
                                          : (isCurrentBox
                                              ? Container(
                                                  width: 2,
                                                  height: 24,
                                                  color: ESUNColors.primary,
                                                )
                                              : const SizedBox()),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Quick fill for prototype
                      const SizedBox(height: ESUNSpacing.sm),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _otp = '123456';
                            _otpController.text = '123456';
                          });
                        },
                        icon: const Icon(Icons.auto_fix_high, size: 16),
                        label: const Text('Auto-fill: 123456'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: ESUNColors.info,
                        ),
                      ),
                      
                      const SizedBox(height: ESUNSpacing.md),
                      
                      // Timer and Resend
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 18, color: ESUNColors.primary),
                          const SizedBox(width: ESUNSpacing.xs),
                          Text(_formattedTime, style: ESUNTypography.bodyMedium),
                          const Spacer(),
                          TextButton(
                            onPressed: _countdown == 0 ? () {
                              setState(() => _countdown = 179);
                              _startCountdown();
                            } : null,
                            child: Text(
                              'Resend OTP',
                              style: ESUNTypography.bodyMedium.copyWith(
                                color: _countdown == 0 ? ESUNColors.primary : ESUNColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: ESUNSpacing.lg),
                
                // Authorise button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isOtpComplete && !_isLoading ? _submitOtp : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ESUNColors.primary,
                      disabledBackgroundColor: ESUNColors.border,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Authorise',
                            style: ESUNTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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

// Bank OTP Bottom Sheet (for Axis Bank, HDFC Bank, etc.)
class _BankOtpBottomSheet extends StatefulWidget {
  final String bankName;
  final VoidCallback onSuccess;

  const _BankOtpBottomSheet({
    required this.bankName,
    required this.onSuccess,
  });

  @override
  State<_BankOtpBottomSheet> createState() => _BankOtpBottomSheetState();
}

class _BankOtpBottomSheetState extends State<_BankOtpBottomSheet> {
  String _otp = '';
  int _countdown = 179;
  bool _isLoading = false;
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Listen to focus changes to update cursor indicator
    _otpFocusNode.addListener(_onFocusChange);
    // Auto-focus the OTP input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpFocusNode.requestFocus();
    });
  }

  void _onFocusChange() {
    setState(() {}); // Rebuild to show/hide cursor indicator
  }

  @override
  void dispose() {
    _otpFocusNode.removeListener(_onFocusChange);
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_countdown > 0) {
        setState(() => _countdown--);
        return true;
      }
      return false;
    });
  }

  String get _formattedTime {
    final minutes = _countdown ~/ 60;
    final seconds = _countdown % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color get _bankColor {
    final bankColors = {
      'State Bank of India': const Color(0xFF22409A),
      'Punjab National Bank': const Color(0xFFED1C24),
      'Bank of Baroda': const Color(0xFFF15A22),
      'Canara Bank': const Color(0xFF0066B3),
      'Union Bank of India': const Color(0xFFED1C24),
      'Bank of India': const Color(0xFFFF6600),
      'Indian Bank': const Color(0xFF1B3A6D),
      'HDFC Bank': const Color(0xFF004C8F),
      'ICICI Bank': const Color(0xFFB02A30),
      'Axis Bank': const Color(0xFF97144D),
      'Kotak Mahindra Bank': const Color(0xFFED1C24),
      'IndusInd Bank': const Color(0xFF6D1F7A),
      'Yes Bank': const Color(0xFF0033A0),
      'IDFC First Bank': const Color(0xFFE31837),
      'Federal Bank': const Color(0xFFED1C24),
      'AU Small Finance Bank': const Color(0xFFE84E0F),
      'Bandhan Bank': const Color(0xFFE84E0F),
      'RBL Bank': const Color(0xFF0066B3),
    };
    return bankColors[widget.bankName] ?? ESUNColors.primary;
  }

  String? get _bankLogoUrl {
    final bankLogos = {
      'State Bank of India': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://onlinesbi.sbi&size=128',
      'Punjab National Bank': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://pnbindia.in&size=128',
      'Bank of Baroda': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://bankofbaroda.in&size=128',
      'Canara Bank': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://canarabank.com&size=128',
      'Union Bank of India': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://unionbankofindia.co.in&size=128',
      'Bank of India': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://bankofindia.co.in&size=128',
      'Indian Bank': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://indianbank.in&size=128',
      'HDFC Bank': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://hdfcbank.com&size=128',
      'ICICI Bank': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://icicibank.com&size=128',
      'Axis Bank': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://axisbank.com&size=128',
      'Kotak Mahindra Bank': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://kotak.com&size=128',
      'IndusInd Bank': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://indusind.com&size=128',
      'Yes Bank': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://yesbank.co.in&size=128',
      'IDFC First Bank': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://idfcfirstbank.com&size=128',
      'Federal Bank': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://federalbank.co.in&size=128',
      'AU Small Finance Bank': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://aubank.in&size=128',
      'Bandhan Bank': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://bandhanbank.com&size=128',
      'RBL Bank': 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://rblbank.com&size=128',
    };
    return bankLogos[widget.bankName];
  }

  Future<void> _submitOtp() async {
    if (_otp.length != 6) return;

    setState(() => _isLoading = true);
    
    // Simulate OTP verification
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.of(context).pop();
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.bankName} accounts linked successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOtpComplete = _otp.length == 6;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Close button
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(ESUNSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title
                Text(
                  'Securely authorize each selected account',
                  style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: ESUNSpacing.lg),
                
                // Bank logo and name
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _bankColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _bankLogoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SmartNetworkImage(
                                imageUrl: _bankLogoUrl!,
                                width: 28,
                                height: 28,
                                fit: BoxFit.contain,
                                placeholderIcon: Icons.account_balance,
                                placeholderColor: _bankColor,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.account_balance, size: 16, color: _bankColor),
                              ),
                            )
                          : Icon(Icons.account_balance, size: 16, color: _bankColor),
                    ),
                    const SizedBox(width: ESUNSpacing.sm),
                    Text(
                      widget.bankName,
                      style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: ESUNSpacing.xl),
                
                // OTP Card
                Container(
                  padding: const EdgeInsets.all(ESUNSpacing.lg),
                  decoration: BoxDecoration(
                    color: ESUNColors.surface,
                    borderRadius: ESUNRadius.lgRadius,
                    border: Border.all(color: ESUNColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Please enter OTP',
                        style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: ESUNSpacing.xs),
                      Row(
                        children: [
                          Text('OTP sent to ', style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
                          Text('+91 80361 73887', style: ESUNTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          const Icon(Icons.edit_outlined, size: 18, color: ESUNColors.textSecondary),
                        ],
                      ),
                      const SizedBox(height: ESUNSpacing.lg),
                      
                      // OTP Input boxes with hidden TextField
                      GestureDetector(
                        onTap: () {
                          _otpFocusNode.requestFocus();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          height: 56,
                          child: Stack(
                            children: [
                              // Hidden TextField for keyboard input
                              Positioned.fill(
                                child: TextField(
                                  controller: _otpController,
                                  focusNode: _otpFocusNode,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  autofocus: true,
                                  style: const TextStyle(
                                    color: Colors.transparent,
                                    height: 0.01,
                                    fontSize: 1,
                                  ),
                                  showCursor: false,
                                  onChanged: (value) {
                                    setState(() {
                                      _otp = value.replaceAll(RegExp(r'[^0-9]'), '');
                                      if (_otp.length > 6) _otp = _otp.substring(0, 6);
                                    });
                                    // Auto-submit when 6 digits entered
                                    if (_otp.length == 6) {
                                      _submitOtp();
                                    }
                                  },
                                  decoration: const InputDecoration(
                                    counterText: '',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              // Visual OTP boxes
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(6, (index) {
                                  final hasDigit = index < _otp.length;
                                  final isCurrentBox = index == _otp.length && _otpFocusNode.hasFocus;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 44,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isCurrentBox 
                                            ? ESUNColors.primary 
                                            : (hasDigit ? ESUNColors.primary : ESUNColors.border),
                                        width: isCurrentBox ? 2 : (hasDigit ? 2 : 1),
                                      ),
                                      boxShadow: isCurrentBox ? [
                                        BoxShadow(
                                          color: ESUNColors.primary.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ] : null,
                                    ),
                                    child: Center(
                                      child: hasDigit
                                          ? Text(
                                              _otp[index],
                                              style: ESUNTypography.titleLarge.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: ESUNColors.textPrimary,
                                              ),
                                            )
                                          : (isCurrentBox
                                              ? Container(
                                                  width: 2,
                                                  height: 24,
                                                  color: ESUNColors.primary,
                                                )
                                              : const SizedBox()),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Quick fill for prototype
                      const SizedBox(height: ESUNSpacing.sm),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _otp = '123456';
                            _otpController.text = '123456';
                          });
                        },
                        icon: const Icon(Icons.auto_fix_high, size: 16),
                        label: const Text('Auto-fill: 123456'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: ESUNColors.info,
                        ),
                      ),
                      
                      const SizedBox(height: ESUNSpacing.md),
                      
                      // Timer and Resend
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 18, color: ESUNColors.primary),
                          const SizedBox(width: ESUNSpacing.xs),
                          Text(_formattedTime, style: ESUNTypography.bodyMedium),
                          const Spacer(),
                          TextButton(
                            onPressed: _countdown == 0 ? () {
                              setState(() => _countdown = 179);
                              _startCountdown();
                            } : null,
                            child: Text(
                              'Resend OTP',
                              style: ESUNTypography.bodyMedium.copyWith(
                                color: _countdown == 0 ? ESUNColors.primary : ESUNColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: ESUNSpacing.lg),
                
                // Submit OTP button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isOtpComplete && !_isLoading ? _submitOtp : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ESUNColors.primary,
                      disabledBackgroundColor: ESUNColors.border,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Submit OTP',
                            style: ESUNTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          
          // Footer
          Padding(
            padding: const EdgeInsets.only(bottom: ESUNSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Powered by RBI-Regulated AA',
                  style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
                ),
                const SizedBox(width: ESUNSpacing.sm),
                Image.asset(
                  'assets/images/finvu_logo.png',
                  height: 16,
                  errorBuilder: (_, __, ___) => Text(
                    'FINVU',
                    style: ESUNTypography.labelSmall.copyWith(
                      color: ESUNColors.primary,
                      fontWeight: FontWeight.bold,
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

// ============================================================================
// Step 4: Discovered Accounts Screen
// ============================================================================

class AADiscoverAccountsScreen extends ConsumerWidget {
  const AADiscoverAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aaOnboardingProvider);
    final notifier = ref.read(aaOnboardingProvider.notifier);

    // Group accounts by FIP
    final accountsByFip = <String, List<Map<String, dynamic>>>{};
    for (final account in state.discoveredAccounts) {
      final fipName = account['fip_name'] as String;
      accountsByFip.putIfAbsent(fipName, () => []).add(account);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Connect Accounts'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: ESUNSpacing.md),
            child: Center(
              child: Text(
                'Step 2 of 4',
                style: ESUNTypography.bodySmall
                    .copyWith(color: ESUNColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const _AAProgressBar(currentStep: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discovered Accounts',
                    style: ESUNTypography.titleMedium
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: ESUNSpacing.xs),
                  Text(
                    'We found these accounts linked to your PAN',
                    style: ESUNTypography.bodySmall
                        .copyWith(color: ESUNColors.textSecondary),
                  ),
                  const SizedBox(height: ESUNSpacing.lg),
                  if (state.discoveredAccounts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(ESUNSpacing.xl),
                      decoration: BoxDecoration(
                        color: ESUNColors.surface,
                        borderRadius: ESUNRadius.lgRadius,
                        border: Border.all(color: ESUNColors.border),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.account_balance_outlined,
                            size: 48,
                            color: ESUNColors.textTertiary,
                          ),
                          const SizedBox(height: ESUNSpacing.md),
                          Text(
                            'No accounts found',
                            style: ESUNTypography.bodyMedium
                                .copyWith(color: ESUNColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  else
                    ...accountsByFip.entries.map((entry) {
                      return Container(
                        margin:
                            const EdgeInsets.only(bottom: ESUNSpacing.lg),
                        decoration: BoxDecoration(
                          color: ESUNColors.surface,
                          borderRadius: ESUNRadius.lgRadius,
                          border: Border.all(color: ESUNColors.border),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: ESUNColors.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: ESUNRadius.smRadius,
                                ),
                                child: const Icon(Icons.account_balance,
                                    color: ESUNColors.primary),
                              ),
                              title: Text(
                                entry.key,
                                style: ESUNTypography.titleSmall
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const FPDivider.subtle(),
                            ...entry.value.map((account) {
                              final accountId = account['account_id'] as String;
                              final isSelected =
                                  state.selectedAccountIds.contains(accountId);
                              return ListTile(
                                onTap: () => notifier.toggleAccount(accountId),
                                leading: Checkbox(
                                  value: isSelected,
                                  onChanged: (_) =>
                                      notifier.toggleAccount(accountId),
                                ),
                                title: Text(
                                  account['account_type'] ?? 'Account',
                                  style: ESUNTypography.bodyMedium
                                      .copyWith(color: ESUNColors.primary),
                                ),
                                trailing: Text(
                                  account['masked_account_number'] ?? '',
                                  style: ESUNTypography.bodyMedium
                                      .copyWith(
                                          color: ESUNColors.textSecondary),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          _AABottomBar(
            buttonLabel: 'Continue',
            showBack: true,
            isLoading: state.isLoading,
            enabled: state.selectedAccountIds.isNotEmpty,
            onPressed: () => context.push(AppRoutes.aaReviewConsent),
            onBack: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Step 5: Review Consent Screen
// ============================================================================

class AAReviewConsentScreen extends ConsumerStatefulWidget {
  const AAReviewConsentScreen({super.key});

  @override
  ConsumerState<AAReviewConsentScreen> createState() =>
      _AAReviewConsentScreenState();
}

class _AAReviewConsentScreenState extends ConsumerState<AAReviewConsentScreen> {
  bool _consentChecked = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aaOnboardingProvider);
    final notifier = ref.read(aaOnboardingProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Connect Accounts'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: ESUNSpacing.md),
            child: Center(
              child: Text(
                'Step 3 of 4',
                style: ESUNTypography.bodySmall
                    .copyWith(color: ESUNColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const _AAProgressBar(currentStep: 2),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review Consent',
                    style: ESUNTypography.titleMedium
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: ESUNSpacing.xs),
                  Text(
                    'Please review what data will be accessed',
                    style: ESUNTypography.bodySmall
                        .copyWith(color: ESUNColors.textSecondary),
                  ),
                  const SizedBox(height: ESUNSpacing.lg),

                  // AA Framework badge
                  Container(
                    padding: const EdgeInsets.all(ESUNSpacing.md),
                    decoration: BoxDecoration(
                      color: ESUNColors.primary.withValues(alpha: 0.1),
                      borderRadius: ESUNRadius.lgRadius,
                      border: Border.all(
                          color: ESUNColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: ESUNColors.primary, width: 2),
                          ),
                          child: const Icon(Icons.verified_outlined,
                              color: ESUNColors.primary, size: 20),
                        ),
                        const SizedBox(width: ESUNSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AA Consent-Based Access',
                                style: ESUNTypography.titleSmall
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Following RBI Account Aggregator framework',
                                style: ESUNTypography.bodySmall.copyWith(
                                    color: ESUNColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ESUNSpacing.lg),

                  // Consent details
                  const _ConsentDetailTile(
                      title: 'Purpose',
                      value: 'Financial wellness education + affordability insights'),
                  const _ConsentDetailTile(
                      title: 'Data Types', value: 'Balances + Transactions'),
                  const _ConsentDetailTile(
                      title: 'Time Range', value: 'Last 12 months'),
                  const _ConsentDetailTile(
                      title: 'Frequency',
                      value: 'One-time with periodic refresh'),
                  const _ConsentDetailTile(
                      title: 'Duration', value: '90 days (renewable)'),
                  const _ConsentDetailTile(
                      title: 'Revocation', value: 'Anytime from Settings'),

                  const SizedBox(height: ESUNSpacing.xl),

                  // Consent checkbox
                  Container(
                    padding: const EdgeInsets.all(ESUNSpacing.md),
                    decoration: BoxDecoration(
                      color: ESUNColors.surface,
                      borderRadius: ESUNRadius.mdRadius,
                      border: Border.all(color: ESUNColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _consentChecked,
                          onChanged: (v) =>
                              setState(() => _consentChecked = v ?? false),
                        ),
                        const SizedBox(width: ESUNSpacing.sm),
                        const Expanded(
                          child: Text(
                            'I consent to share this data for the stated purpose. I understand I can revoke this consent anytime.',
                            style: ESUNTypography.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: ESUNSpacing.lg),

                  // Regulatory Protection Statement
                  const _RegulatoryProtectionBadge(),
                ],
              ),
            ),
          ),
          _AABottomBar(
            buttonLabel: 'Submit Consent',
            showBack: true,
            isLoading: state.isLoading,
            enabled: _consentChecked,
            onPressed: () async {
              final success = await notifier.submitConsent();
              if (success && context.mounted) {
                context.push(AppRoutes.aaConnecting);
              }
            },
            onBack: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Step 6: Connecting Screen (Loading)
// ============================================================================

class AAConnectingScreen extends ConsumerStatefulWidget {
  const AAConnectingScreen({super.key});

  @override
  ConsumerState<AAConnectingScreen> createState() => _AAConnectingScreenState();
}

class _AAConnectingScreenState extends ConsumerState<AAConnectingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _connectAccounts();
  }

  Future<void> _connectAccounts() async {
    // Add a small delay for visual effect
    await Future.delayed(const Duration(seconds: 2));

    final notifier = ref.read(aaOnboardingProvider.notifier);
    final success = await notifier.connectAccounts();

    if (mounted) {
      if (success) {
        context.go(AppRoutes.aaSuccess);
      } else {
        // Show error and go back to consent
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(ref.read(aaOnboardingProvider).error ?? 'Connection failed')),
        );
        context.pop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aaOnboardingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Accounts'),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: ESUNSpacing.md),
            child: Center(
              child: Text(
                'Step 4 of 4',
                style: ESUNTypography.bodySmall
                    .copyWith(color: ESUNColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const _AAProgressBar(currentStep: 3),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              ESUNColors.primary,
                              ESUNColors.primary.withValues(alpha: 0.1),
                              ESUNColors.primary,
                            ],
                            transform:
                                GradientRotation(_controller.value * 2 * 3.14159),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(ESUNSpacing.xs),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).scaffoldBackgroundColor,
                          ),
                          child: const Icon(
                            Icons.account_balance,
                            size: 40,
                            color: ESUNColors.primary,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: ESUNSpacing.xl),
                  Text(
                    'Connecting to your accounts...',
                    style: ESUNTypography.titleMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: ESUNSpacing.sm),
                  Text(
                    'This may take a moment',
                    style: ESUNTypography.bodyMedium
                        .copyWith(color: ESUNColors.textSecondary),
                  ),
                  const SizedBox(height: ESUNSpacing.xxl),
                  Text(
                    '${state.selectedAccountIds.length} accounts',
                    style: ESUNTypography.bodySmall
                        .copyWith(color: ESUNColors.textTertiary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Step 7: Success Screen
// ============================================================================

class AASuccessScreen extends ConsumerWidget {
  const AASuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aaOnboardingProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ESUNSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Success animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ESUNColors.success.withValues(alpha: 0.1),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 80,
                        color: ESUNColors.success,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: ESUNSpacing.xl),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Column(
                      children: [
                        Text(
                          'All Set!',
                          style: ESUNTypography.headlineLarge
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: ESUNSpacing.md),
                        Text(
                          '${state.selectedAccountIds.length} accounts connected successfully',
                          style: ESUNTypography.bodyLarge.copyWith(
                            color: ESUNColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: ESUNSpacing.sm),
                        Text(
                          'Your financial data is now securely synced',
                          style: ESUNTypography.bodyMedium.copyWith(
                            color: ESUNColors.textTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FPButton(
                  label: 'Go to Dashboard',
                  onPressed: () async {
                    // Update auth state to reflect successful AA connection
                    ref.read(authStateProvider.notifier).updateLinkingStatus(
                      aaConnected: true,
                    );
                    // Refresh user profile from server to ensure status is synced
                    await ref.read(authStateProvider.notifier).refreshUserProfile();
                    // Reset onboarding state
                    ref.read(aaOnboardingProvider.notifier).reset();
                    // Navigate to payments
                    context.go(AppRoutes.payments);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Final Step Consent Screen (Finvu Style)
// ============================================================================

class AAFinalStepConsentScreen extends ConsumerStatefulWidget {
  const AAFinalStepConsentScreen({super.key});

  @override
  ConsumerState<AAFinalStepConsentScreen> createState() =>
      _AAFinalStepConsentScreenState();
}

class _AAFinalStepConsentScreenState
    extends ConsumerState<AAFinalStepConsentScreen> {
  bool _showAccountDetails = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Share Accounts',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_outlined, color: Colors.black54),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Aa/अ',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          _buildFinvuProgressBar(currentStep: 3),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(ESUNSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Final step',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      children: [
                        TextSpan(text: 'Consent to share your ('),
                        TextSpan(
                          text: 'yourphone@Finvu',
                          style: TextStyle(
                            color: Color(0xFF009688),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(text: ') accounts with <FIU name>'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Accounts Shared Section
                  _buildConsentSection(
                    icon: Icons.person_outline,
                    title: 'Accounts Shared',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('2 Bank accounts', style: TextStyle(fontSize: 14, color: Colors.black87)),
                        const Text('3 Deposits', style: TextStyle(fontSize: 14, color: Colors.black87)),
                        const Text('2 CDSL', style: TextStyle(fontSize: 14, color: Colors.black87)),
                        const Text('1 NSDL', style: TextStyle(fontSize: 14, color: Colors.black87)),
                        const Text('2 CAMS', style: TextStyle(fontSize: 14, color: Colors.black87)),
                        const Text('5 KFIN', style: TextStyle(fontSize: 14, color: Colors.black87)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() => _showAccountDetails = !_showAccountDetails);
                          },
                          child: Row(
                            children: [
                              const Text(
                                'View Details',
                                style: TextStyle(
                                  color: Color(0xFF009688),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              Icon(
                                _showAccountDetails
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: const Color(0xFF009688),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Permission Validity Section
                  _buildConsentSection(
                    icon: Icons.calendar_today_outlined,
                    title: 'Permission Validity',
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                        children: [
                          TextSpan(text: 'From '),
                          TextSpan(
                            text: '17 April 2023',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: ' to '),
                          TextSpan(
                            text: '17 April 2024',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Frequency of Access Section
                  _buildConsentSection(
                    icon: Icons.hourglass_empty,
                    title: 'Frequency of Access',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                            children: [
                              TextSpan(text: 'Finvu can access your information '),
                              TextSpan(
                                text: 'once a day',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showMoreDetailsBottomSheet(),
                          child: const Text(
                            'View more details',
                            style: TextStyle(
                              color: Color(0xFF009688),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(ESUNSpacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFFF9A825),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You can pause or cancel sharing anytime via your Finvu App',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade800,
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
          
          // Bottom buttons
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.xl),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => context.push(AppRoutes.aaAnalyzing),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Allow Permission',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.aaDeclined),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        color: Color(0xFFD32F2F),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Footer
          _buildFinvuFooter(),
        ],
      ),
    );
  }

  Widget _buildConsentSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.grey.shade600, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              child,
            ],
          ),
        ),
      ],
    );
  }

  void _showMoreDetailsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(ESUNSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: ESUNSpacing.lg),
            const Text(
              'Consent Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: ESUNSpacing.lg),
            _buildDetailRow('Data Fetch Type', 'One-time & Periodic'),
            _buildDetailRow('Frequency', 'Once a day'),
            _buildDetailRow('Data Life', '1 Year'),
            _buildDetailRow('Data Storage', 'Encrypted & Secure'),
            _buildDetailRow('Purpose', 'Financial Health Analysis'),
            const SizedBox(height: ESUNSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
                  side: const BorderSide(color: Color(0xFF009688)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Color(0xFF009688),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Analyzing Screen (Animated Messages)
// ============================================================================

class AAAnalyzingScreen extends ConsumerStatefulWidget {
  const AAAnalyzingScreen({super.key});

  @override
  ConsumerState<AAAnalyzingScreen> createState() => _AAAnalyzingScreenState();
}

class _AAAnalyzingScreenState extends ConsumerState<AAAnalyzingScreen>
    with SingleTickerProviderStateMixin {
  int _currentMessageIndex = 0;
  late AnimationController _rotationController;

  final List<String> _analyzingMessages = [
    'Assessing Current Asset Value',
    'Looking for Emergency Fund Coverage',
    'Checking on the insurance',
    'Generating the Financial Health',
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startMessageRotation();
  }

  void _startMessageRotation() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _currentMessageIndex++;
          if (_currentMessageIndex < _analyzingMessages.length) {
            _startMessageRotation();
          } else {
            // Navigate to dashboard after all messages
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                context.go(AppRoutes.aaFinancialHealthDashboard);
              }
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentMessage = _currentMessageIndex < _analyzingMessages.length
        ? _analyzingMessages[_currentMessageIndex]
        : _analyzingMessages.last;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Aa/अ',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          _buildFinvuProgressBar(currentStep: 3),
          
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(ESUNSpacing.xxl),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Searching...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Animated loader
                      AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(60, 60),
                            painter: _CircularLoaderPainter(
                              progress: _rotationController.value,
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Animated message
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          currentMessage,
                          key: ValueKey(currentMessage),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Footer
          _buildFinvuFooter(),
        ],
      ),
    );
  }
}

class _CircularLoaderPainter extends CustomPainter {
  final double progress;

  _CircularLoaderPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final startAngle = -1.5708 + (progress * 6.2832);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      1.5708,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularLoaderPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ============================================================================
// Financial Health Dashboard Screen
// ============================================================================

class AAFinancialHealthDashboardScreen extends ConsumerWidget {
  const AAFinancialHealthDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Consolidated Bank Balance Header
              _buildConsolidatedHeader(),
              
              Padding(
                padding: const EdgeInsets.all(ESUNSpacing.lg),
                child: Column(
                  children: [
                    // Investment Tip Card
                    _buildInvestmentTipCard(),
                    const SizedBox(height: 16),
                    
                    // Recurring Bills Card
                    _buildRecurringBillsCard(),
                    const SizedBox(height: 16),
                    
                    // Expense Mode Split
                    _buildExpenseModeSplitCard(),
                    const SizedBox(height: 16),
                    
                    // Expense Categories
                    _buildExpenseCategoriesCard(),
                    const SizedBox(height: 16),
                    
                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(aaOnboardingProvider.notifier).reset();
                          context.go(AppRoutes.payments);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ESUNColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsolidatedHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ESUNSpacing.xl),
      decoration: const BoxDecoration(
        color: Color(0xFF009688),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Consolidated Bank Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '₹2,83,610.53',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'As of 05/08/2024',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          
          // Bank accounts
          _buildBankAccountCard(
            bankName: 'Axis Bank',
            accountType: 'Savings Account',
            last4: '1207',
            balance: '₹1,12,370.53',
            date: 'on 5 Aug',
            color: const Color(0xFF97144D),
          ),
          const SizedBox(height: 8),
          _buildBankAccountCard(
            bankName: 'HDFC',
            accountType: 'Savings Account',
            last4: '1207',
            balance: '₹1,12,370.53',
            date: 'on 5 Aug',
            color: const Color(0xFF004C8F),
          ),
        ],
      ),
    );
  }

  static Widget _buildBankAccountCard({
    required String bankName,
    required String accountType,
    required String last4,
    required String balance,
    required String date,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                bankName[0],
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bankName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$accountType • $last4',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            balance,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentTipCard() {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(ESUNSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFF009688).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Color(0xFF009688),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Time to top-up your investments!',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'We Noticed a hike in your salary, congratulations! This might be the perfect time to top up your investments.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Text(
                'Top up now',
                style: TextStyle(
                  color: ESUNColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: ESUNColors.primary,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.people,
                  color: Color(0xFF2E7D32),
                  size: 14,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '20,000+ users have topped up their investments after a salary hike in the past 3 months.',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 11,
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

  Widget _buildRecurringBillsCard() {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(ESUNSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Color(0xFF1976D2),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recurring Bills Coming Up!',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Make sure you maintain a balance of at least ₹19,789 in your account for these recurring payments.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Text(
                'View Details',
                style: TextStyle(
                  color: ESUNColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: ESUNColors.primary,
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseModeSplitCard() {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(ESUNSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.pie_chart,
                  color: Colors.grey.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Expense mode split',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildExpenseModeRow('ATM', '₹', '3%'),
          const Divider(height: 1),
          _buildExpenseModeRow('Card', '💳', '12%'),
          const Divider(height: 1),
          _buildExpenseModeRow('UPI', '📱', '66%'),
          const Divider(height: 1),
          _buildExpenseModeRow('FT', '↔️', '9%'),
          const Divider(height: 1),
          _buildExpenseModeRow('Others', '📋', '10%'),
        ],
      ),
    );
  }

  Widget _buildExpenseModeRow(String label, String icon, String percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          const Spacer(),
          Text(
            percentage,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right,
            color: Colors.grey.shade400,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCategoriesCard() {
    final categories = [
      {'name': 'Payments', 'count': '34 transactions', 'amount': '₹2,23,192', 'percent': '52.35%', 'color': const Color(0xFF7C4DFF)},
      {'name': 'Credit Card Bill', 'count': '1 transaction', 'amount': '₹65,574', 'percent': '15.26%', 'color': const Color(0xFF7C4DFF)},
      {'name': 'Investments', 'count': '4 transactions', 'amount': '₹33,157', 'percent': '7.77%', 'color': const Color(0xFF7C4DFF)},
      {'name': 'Others', 'count': '119 transactions', 'amount': '₹27,684', 'percent': '6.49%', 'color': const Color(0xFF7C4DFF)},
      {'name': 'Travel', 'count': '25 transactions', 'amount': '₹10,847', 'percent': '2.54%', 'color': const Color(0xFF7C4DFF)},
      {'name': 'Shopping', 'count': '8 transactions', 'amount': '₹9,009', 'percent': '2.11%', 'color': const Color(0xFF7C4DFF)},
      {'name': 'Food & Beverage', 'count': '12 transactions', 'amount': '₹8,515', 'percent': '2.01%', 'color': const Color(0xFF7C4DFF)},
    ];

    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(ESUNSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.grid_view,
                  color: Color(0xFF7B1FA2),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expense Categories',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '83.51% of your spends were in 4 categories',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '₹4,26,702.28',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '11 Categories',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Set Budgets button
          Center(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Set Budgets'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Category list
          ...categories.map((cat) => _buildCategoryRow(
            name: cat['name'] as String,
            count: cat['count'] as String,
            amount: cat['amount'] as String,
            percent: cat['percent'] as String,
            color: cat['color'] as Color,
          )),
          
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View all categories',
                    style: TextStyle(
                      color: ESUNColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: ESUNColors.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow({
    required String name,
    required String count,
    required String amount,
    required String percent,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.category,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  count,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                percent,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Finvu Helper Widgets
// ============================================================================

Widget _buildFinvuProgressBar({required int currentStep}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    child: Row(
      children: List.generate(4, (index) {
        final stepNumber = index + 1;
        final isCompleted = stepNumber < currentStep;
        final isCurrent = stepNumber == currentStep;
        final isLast = index == 3;

        return Expanded(
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? const Color(0xFF009688)
                      : isCurrent
                          ? const Color(0xFF009688)
                          : Colors.grey.shade300,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : Text(
                          '$stepNumber',
                          style: TextStyle(
                            color: isCurrent ? Colors.white : Colors.grey.shade500,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 3,
                    color: isCompleted
                        ? const Color(0xFF009688)
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }),
    ),
  );
}

Widget _buildFinvuFooter() {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Powered by RBI-Regulated AA',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: ESUNSpacing.badgeInsets,
          decoration: BoxDecoration(
            color: const Color(0xFF009688),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'FINVU',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

// ============================================================================
// Helper Widgets
// ============================================================================

class _AAProgressBar extends StatelessWidget {
  final int currentStep;

  const _AAProgressBar({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: ESUNSpacing.lg, vertical: ESUNSpacing.md),
      child: Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: index <= currentStep
                    ? ESUNColors.primary
                    : ESUNColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _AABottomBar extends StatelessWidget {
  final String buttonLabel;
  final bool showBack;
  final bool isLoading;
  final bool enabled;
  final VoidCallback? onPressed;
  final VoidCallback? onBack;

  const _AABottomBar({
    required this.buttonLabel,
    this.showBack = false,
    this.isLoading = false,
    this.enabled = true,
    this.onPressed,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FPButton(
                label: buttonLabel,
                onPressed: enabled && !isLoading ? onPressed : null,
                isLoading: isLoading,
              ),
            ),
            if (showBack) ...[
              const SizedBox(height: ESUNSpacing.sm),
              TextButton(
                onPressed: onBack,
                child: const Text('Back'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _FipListTile extends StatelessWidget {
  final Map<String, dynamic> fip;
  final bool isSelected;
  final VoidCallback onTap;

  const _FipListTile({
    required this.fip,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _fallbackIcon {
    switch (fip['type']) {
      case 'bank':
        return Icons.account_balance;
      case 'investment':
        return Icons.trending_up;
      case 'retirement':
        return Icons.savings;
      default:
        return Icons.account_balance_wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final logoUrl = fip['logo'] as String?;
    
    return Container(
      margin: const EdgeInsets.only(bottom: ESUNSpacing.sm),
      decoration: BoxDecoration(
        color: ESUNColors.surface,
        borderRadius: ESUNRadius.mdRadius,
        border: Border.all(
          color: isSelected ? ESUNColors.primary : ESUNColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ESUNColors.primary.withValues(alpha: 0.1),
            borderRadius: ESUNRadius.smRadius,
          ),
          child: ClipRRect(
            borderRadius: ESUNRadius.smRadius,
            child: logoUrl != null && logoUrl.isNotEmpty
                ? SmartNetworkImage(
                    imageUrl: logoUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    placeholderIcon: _fallbackIcon,
                    placeholderColor: ESUNColors.primary,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(_fallbackIcon, color: ESUNColors.primary, size: 20);
                    },
                  )
                : Icon(_fallbackIcon, color: ESUNColors.primary, size: 20),
          ),
        ),
        title: Text(
          fip['name'] ?? '',
          style: ESUNTypography.titleSmall,
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: ESUNColors.primary)
            : const Icon(Icons.circle_outlined, color: ESUNColors.border),
      ),
    );
  }
}

class _ConsentDetailTile extends StatelessWidget {
  final String title;
  final String value;

  const _ConsentDetailTile({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ESUNSpacing.sm),
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: ESUNColors.surface,
        borderRadius: ESUNRadius.mdRadius,
        border: Border.all(color: ESUNColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: ESUNTypography.titleSmall
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: ESUNSpacing.xs),
          Text(
            value,
            style: ESUNTypography.bodySmall
                .copyWith(color: ESUNColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Regulatory Protection Statement Badge
class _RegulatoryProtectionBadge extends StatelessWidget {
  const _RegulatoryProtectionBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.md),
      decoration: BoxDecoration(
        color: ESUNColors.success.withOpacity(0.08),
        borderRadius: ESUNRadius.mdRadius,
        border: Border.all(color: ESUNColors.success.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.sm),
            decoration: BoxDecoration(
              color: ESUNColors.success.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: ESUNColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: ESUNSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Regulated & Protected',
                  style: ESUNTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ESUNColors.success,
                  ),
                ),
                const SizedBox(height: ESUNSpacing.xs),
                Text(
                  'Your data is protected and regulated by RBI, SEBI, IRDAI, and PFRDA.',
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

// ============================================================================
// Text Formatter for uppercase PAN
// ============================================================================

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

// ============================================================================
// My Consents Screen (FinFactor Style)
// ============================================================================

class ConsentData {
  final String id;
  final String title;
  final String description;
  final String dateRange;
  final List<Map<String, dynamic>> accounts;
  final String issuedVia;
  final int expiresInDays;
  bool isSelected;
  bool isPaused;

  ConsentData({
    required this.id,
    required this.title,
    required this.description,
    required this.dateRange,
    required this.accounts,
    required this.issuedVia,
    required this.expiresInDays,
    this.isSelected = false,
    this.isPaused = false,
  });
}

class AAMyConsentsScreen extends ConsumerStatefulWidget {
  const AAMyConsentsScreen({super.key});

  @override
  ConsumerState<AAMyConsentsScreen> createState() => _AAMyConsentsScreenState();
}

class _AAMyConsentsScreenState extends ConsumerState<AAMyConsentsScreen> {
  String _selectedTab = 'All';
  
  // Mock consent data
  final List<ConsentData> _consents = [
    ConsentData(
      id: '1',
      title: 'To generate insights based on your financial data',
      description: 'Access your data once a day',
      dateRange: '29 Aug 2024 to 30 Sep 2025',
      accounts: [
        {'name': 'HDFC Bank', 'number': '2785', 'color': const Color(0xFF004C8F)},
        {'name': 'Axis Bank', 'number': '0245', 'color': const Color(0xFF97144D)},
      ],
      issuedVia: 'FINVU',
      expiresInDays: 2,
      isSelected: true,
    ),
    ConsentData(
      id: '2',
      title: 'To generate insights based on your financial data',
      description: 'Access your data once a day',
      dateRange: '29 Aug 2024 to 30 Sep 2025',
      accounts: [
        {'name': 'HDFC Bank', 'number': '2785', 'color': const Color(0xFF004C8F)},
        {'name': 'Axis Bank', 'number': '0245', 'color': const Color(0xFF97144D)},
      ],
      issuedVia: 'anumati',
      expiresInDays: 2,
      isPaused: true,
    ),
  ];

  List<ConsentData> get _filteredConsents {
    if (_selectedTab == 'All') {
      return _consents.where((c) => !c.isPaused).toList();
    } else {
      return _consents.where((c) => c.isPaused).toList();
    }
  }

  bool get _hasSelectedConsents => _consents.any((c) => c.isSelected);

  void _showRevokeConfirmation() {
    final selectedConsents = _consents.where((c) => c.isSelected).toList();
    if (selectedConsents.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RevokeConsentBottomSheet(
        consents: selectedConsents,
        onSuccess: () {
          setState(() {
            for (final consent in selectedConsents) {
              _consents.remove(consent);
            }
          });
          _showRevokeSuccess();
        },
      ),
    );
  }

  void _showRevokeSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _RevokeSuccessDialog(
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ESUNColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'My Consents',
          style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_outlined, color: ESUNColors.textSecondary),
            onPressed: () {},
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              'Aa/अ',
              style: ESUNTypography.labelMedium.copyWith(color: ESUNColors.textSecondary),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
            child: Text(
              'Manage all your existing data sharing consents. You can revoke the consent in case it is not required anymore.',
              style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textSecondary),
            ),
          ),
          const SizedBox(height: ESUNSpacing.md),
          
          // Account Aggregators info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
            child: InkWell(
              onTap: () => _showAccountAggregatorsInfo(),
              child: Row(
                children: [
                  Text(
                    'Account Aggregators',
                    style: ESUNTypography.labelMedium.copyWith(
                      color: ESUNColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.info_outline, size: 16, color: ESUNColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          
          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
            child: Row(
              children: ['All', 'Paused'].map((tab) {
                final isActive = _selectedTab == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: ESUNSpacing.sm),
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = tab),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? ESUNColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive ? ESUNColors.primary : ESUNColors.border,
                        ),
                      ),
                      child: Text(
                        tab,
                        style: ESUNTypography.labelMedium.copyWith(
                          color: isActive ? Colors.white : ESUNColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          
          // Consent Cards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
              itemCount: _filteredConsents.length,
              itemBuilder: (context, index) {
                final consent = _filteredConsents[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: ESUNSpacing.md),
                  child: _ConsentCard(
                    consent: consent,
                    onSelectionChanged: (selected) {
                      setState(() {
                        consent.isSelected = selected;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          
          // Revoke Button
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _hasSelectedConsents ? _showRevokeConfirmation : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ESUNColors.primary,
                  disabledBackgroundColor: ESUNColors.border,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Revoke Consents',
                  style: ESUNTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.only(bottom: ESUNSpacing.lg),
            child: Center(
              child: Text(
                'Consent will re-appear automatically once it is re-established',
                style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAccountAggregatorsInfo() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(ESUNSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              
              Text(
                'Want to know more about Account Aggregators?',
                style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ESUNSpacing.md),
              
              Text(
                'AA helps us bring your all financial data at one place in an electronic format.',
                style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ESUNSpacing.lg),
              
              // Logos
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Powered by: ', style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
                  const SizedBox(width: 8),
                  // Mock logos
                  Container(
                    padding: ESUNSpacing.badgeInsets,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Setu', style: ESUNTypography.labelSmall.copyWith(color: Colors.blue)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: ESUNSpacing.badgeInsets,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('FINVU', style: ESUNTypography.labelSmall.copyWith(color: Colors.green)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: ESUNSpacing.badgeInsets,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Anumati', style: ESUNTypography.labelSmall.copyWith(color: Colors.orange)),
                  ),
                ],
              ),
              const SizedBox(height: ESUNSpacing.xl),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ESUNColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Understood'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Consent Card Widget
class _ConsentCard extends StatelessWidget {
  final ConsentData consent;
  final Function(bool) onSelectionChanged;

  const _ConsentCard({
    required this.consent,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: ESUNRadius.lgRadius,
        border: Border.all(color: ESUNColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with checkbox and Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              InkWell(
                onTap: () => onSelectionChanged(!consent.isSelected),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: consent.isSelected ? ESUNColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: consent.isSelected ? ESUNColors.primary : ESUNColors.border,
                      width: 2,
                    ),
                  ),
                  child: consent.isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Details',
                  style: ESUNTypography.labelMedium.copyWith(
                    color: ESUNColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.sm),
          
          // Title
          Text(
            consent.title,
            style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: ESUNSpacing.xs),
          
          // Description with date range
          Text(
            '${consent.description}, from ${consent.dateRange}',
            style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
          ),
          const SizedBox(height: ESUNSpacing.lg),
          
          // Accounts section
          Row(
            children: [
              Text(
                'Accounts',
                style: ESUNTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Manage',
                  style: ESUNTypography.labelMedium.copyWith(
                    color: ESUNColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          // Account icons
          Row(
            children: [
              ...consent.accounts.take(2).map((account) {
                return Padding(
                  padding: const EdgeInsets.only(right: ESUNSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: (account['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(Icons.account_balance, size: 12, color: account['color'] as Color),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '• ${account['number']}',
                        style: ESUNTypography.bodySmall.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }),
              if (consent.accounts.length > 2)
                Text(
                  '+ ${consent.accounts.length - 2} more',
                  style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: ESUNSpacing.lg),
          
          // Footer
          Row(
            children: [
              // Expiry warning
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.red.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Expires in ${consent.expiresInDays} days',
                    style: ESUNTypography.bodySmall.copyWith(color: Colors.red.shade600),
                  ),
                ],
              ),
              const Spacer(),
              // Issued via
              Text(
                'Issued via: ',
                style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
              ),
              Text(
                consent.issuedVia,
                style: ESUNTypography.labelSmall.copyWith(
                  color: ESUNColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Revoke Consent Bottom Sheet
class _RevokeConsentBottomSheet extends StatefulWidget {
  final List<ConsentData> consents;
  final VoidCallback onSuccess;

  const _RevokeConsentBottomSheet({
    required this.consents,
    required this.onSuccess,
  });

  @override
  State<_RevokeConsentBottomSheet> createState() => _RevokeConsentBottomSheetState();
}

class _RevokeConsentBottomSheetState extends State<_RevokeConsentBottomSheet> {
  String _otp = '';
  int _countdown = 179;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_countdown > 0) {
        setState(() => _countdown--);
        return true;
      }
      return false;
    });
  }

  String get _formattedTime {
    final minutes = _countdown ~/ 60;
    final seconds = _countdown % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _submitOtp() async {
    if (_otp.length != 6) return;

    setState(() => _isLoading = true);
    
    // Simulate OTP verification
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.of(context).pop();
      widget.onSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOtpComplete = _otp.length == 6;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Close button
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(ESUNSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Please verify your mobile number',
                  style: ESUNTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: ESUNSpacing.xs),
                Text(
                  'You need to enter the OTP sent to this mobile no. to revoke this consent',
                  style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
                ),
                const SizedBox(height: ESUNSpacing.lg),
                
                // Warning banner
                Container(
                  padding: const EdgeInsets.all(ESUNSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: ESUNSpacing.sm),
                      Expanded(
                        child: Text(
                          'Revoking this consent may affect your experience in generating insights',
                          style: ESUNTypography.bodySmall.copyWith(color: Colors.orange.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ESUNSpacing.lg),
                
                // OTP Card
                Container(
                  padding: const EdgeInsets.all(ESUNSpacing.lg),
                  decoration: BoxDecoration(
                    color: ESUNColors.surface,
                    borderRadius: ESUNRadius.lgRadius,
                    border: Border.all(color: ESUNColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Please enter OTP',
                        style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: ESUNSpacing.xs),
                      Row(
                        children: [
                          Text('OTP sent to ', style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary)),
                          Text('+91 80361 73887', style: ESUNTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          const Icon(Icons.edit_outlined, size: 18, color: ESUNColors.textSecondary),
                        ],
                      ),
                      const SizedBox(height: ESUNSpacing.lg),
                      
                      // OTP Input boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          final hasDigit = index < _otp.length;
                          return Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: hasDigit ? ESUNColors.primary : ESUNColors.border,
                                width: hasDigit ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                hasDigit ? _otp[index] : '',
                                style: ESUNTypography.titleLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: ESUNColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      
                      // Quick fill for prototype
                      const SizedBox(height: ESUNSpacing.sm),
                      TextButton.icon(
                        onPressed: () => setState(() => _otp = '123456'),
                        icon: const Icon(Icons.auto_fix_high, size: 16),
                        label: const Text('Auto-fill: 123456'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: ESUNColors.info,
                        ),
                      ),
                      
                      const SizedBox(height: ESUNSpacing.md),
                      
                      // Timer and Resend
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 18, color: ESUNColors.primary),
                          const SizedBox(width: ESUNSpacing.xs),
                          Text(_formattedTime, style: ESUNTypography.bodyMedium),
                          const Spacer(),
                          TextButton(
                            onPressed: _countdown == 0 ? () {
                              setState(() => _countdown = 179);
                              _startCountdown();
                            } : null,
                            child: Text(
                              'Resend OTP',
                              style: ESUNTypography.bodyMedium.copyWith(
                                color: _countdown == 0 ? ESUNColors.primary : ESUNColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: ESUNSpacing.lg),
                
                // Submit OTP button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isOtpComplete && !_isLoading ? _submitOtp : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ESUNColors.primary,
                      disabledBackgroundColor: ESUNColors.border,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Submit OTP',
                            style: ESUNTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: ESUNSpacing.lg),
                
                // Disclaimer
                Text(
                  'By clicking on the button above, you agree to the revoking of data, withdrawal from your AA',
                  style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Footer
          Padding(
            padding: const EdgeInsets.only(bottom: ESUNSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'For any queries contact us at ',
                  style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
                ),
                Text(
                  'hello@finvu.in',
                  style: ESUNTypography.bodySmall.copyWith(
                    color: ESUNColors.primary,
                    fontWeight: FontWeight.w600,
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

// Revoke Success Dialog
class _RevokeSuccessDialog extends StatelessWidget {
  final VoidCallback onClose;

  const _RevokeSuccessDialog({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1B5E20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(ESUNSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: onClose,
              ),
            ),
            
            // Success icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 48),
            ),
            const SizedBox(height: ESUNSpacing.lg),
            
            Text(
              'You have successfully revoked the selected consent(s)',
              style: ESUNTypography.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ESUNSpacing.lg),
            
            TextButton(
              onPressed: onClose,
              child: Text(
                'Yes, I need the Revoke',
                style: ESUNTypography.labelMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// AA Profile Screen
// ============================================================================

class AAProfileScreen extends ConsumerWidget {
  const AAProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: Row(
                children: [
                  Text(
                    'Profile',
                    style: ESUNTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: ESUNColors.textSecondary),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: ESUNColors.textSecondary),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            
            // User Info Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ESUNColors.primary, ESUNColors.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: ESUNRadius.lgRadius,
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: ESUNSpacing.md),
                  
                  // Name
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sahu Boi',
                        style: ESUNTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Edit Profile',
                          style: ESUNTypography.labelSmall.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: ESUNSpacing.xl),
            
            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
                children: [
                  _ProfileMenuItem(
                    icon: Icons.subscriptions_outlined,
                    title: 'Subscriptions',
                    onTap: () {},
                  ),
                  _ProfileMenuItem(
                    icon: Icons.handshake_outlined,
                    title: 'My Consents',
                    onTap: () => context.push(AppRoutes.aaMyConsents),
                  ),
                  _ProfileMenuItem(
                    icon: Icons.language,
                    title: 'Language',
                    onTap: () {},
                  ),
                  _ProfileMenuItem(
                    icon: Icons.support_agent_outlined,
                    title: 'Support',
                    onTap: () {},
                  ),
                  const Divider(height: 32),
                  _ProfileMenuItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    isDestructive: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            
            // Footer
            Padding(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ESUN ',
                    style: ESUNTypography.labelMedium.copyWith(
                      color: ESUNColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'v2.0.32',
                    style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
                  ),
                ],
              ),
            ),
            
            // Bottom icons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () {},
                  color: ESUNColors.textSecondary,
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_outline),
                  onPressed: () {},
                  color: ESUNColors.textSecondary,
                ),
                IconButton(
                  icon: const Icon(Icons.star_outline),
                  onPressed: () {},
                  color: ESUNColors.textSecondary,
                ),
                IconButton(
                  icon: const Icon(Icons.feedback_outlined),
                  onPressed: () {},
                  color: ESUNColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: ESUNSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : ESUNColors.textPrimary;
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: ESUNTypography.bodyMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: ESUNColors.textSecondary),
      onTap: onTap,
    );
  }
}

// ============================================================================
// Revoke Consents Flow Screen (Full Page)
// ============================================================================

class AARevokeConsentsScreen extends ConsumerStatefulWidget {
  const AARevokeConsentsScreen({super.key});

  @override
  ConsumerState<AARevokeConsentsScreen> createState() => _AARevokeConsentsScreenState();
}

class _AARevokeConsentsScreenState extends ConsumerState<AARevokeConsentsScreen> {
  final List<Map<String, dynamic>> _consents = [
    {
      'id': '1',
      'provider': 'Lenskart Banss Pvt.Ltd.',
      'purpose': 'To offer you suitable loan options, you are sharing your banking data with Banking Solutions Pvt. Ltd.',
      'frequency': 'Access once, every month for 1 year (ending 12 Aug 2025)',
      'accounts': [
        {'bank': 'Axis Bank', 'number': '6576', 'color': const Color(0xFF97144D)},
        {'bank': 'HDFC Bank', 'number': '0245', 'color': const Color(0xFF004C8F)},
      ],
      'isSelected': true,
    },
    {
      'id': '2',
      'provider': 'Growwing Technologies Pvt.Ltd.',
      'purpose': 'Profile your portfolio on your account and help you wealth creation',
      'frequency': 'Access once, every month for 1 year (ending 12 Aug 2025)',
      'accounts': [
        {'bank': 'CDSL', 'number': '4566', 'color': const Color(0xFF1B5E20)},
        {'bank': 'NSDL', 'number': '0896', 'color': const Color(0xFFFF6F00)},
      ],
    },
  ];

  void _showDetailsFor(Map<String, dynamic> consent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ConsentDetailsBottomSheet(consent: consent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _consents.where((c) => c['isSelected'] == true).length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ESUNColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Revoke Consents',
          style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_outlined, color: ESUNColors.textSecondary),
            onPressed: () {},
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              'Aa/अ',
              style: ESUNTypography.labelMedium.copyWith(color: ESUNColors.textSecondary),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider info
          Padding(
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(ESUNSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle, color: ESUNColors.success, size: 24),
                ),
                const SizedBox(width: ESUNSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lenskart Banss Pvt.Ltd.',
                        style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'You are revoking data to be shared with this provider',
                        style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('Revoke', style: ESUNTypography.labelMedium.copyWith(color: ESUNColors.primary)),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: ESUNSpacing.md),
          
          // Consent list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
              itemCount: _consents.length,
              itemBuilder: (context, index) {
                final consent = _consents[index];
                final isSelected = consent['isSelected'] == true;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: ESUNSpacing.md),
                  padding: const EdgeInsets.all(ESUNSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: ESUNRadius.lgRadius,
                    border: Border.all(color: isSelected ? ESUNColors.primary : ESUNColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                consent['isSelected'] = !isSelected;
                              });
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSelected ? ESUNColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isSelected ? ESUNColors.primary : ESUNColors.border,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: ESUNSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  consent['provider'] as String,
                                  style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  consent['purpose'] as String,
                                  style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showDetailsFor(consent),
                            child: Text(
                              'Details',
                              style: ESUNTypography.labelMedium.copyWith(color: ESUNColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: ESUNSpacing.md),
                      
                      // Accounts
                      Text(
                        'Accounts',
                        style: ESUNTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: ESUNSpacing.sm),
                      
                      Wrap(
                        spacing: ESUNSpacing.md,
                        runSpacing: ESUNSpacing.sm,
                        children: (consent['accounts'] as List<Map<String, dynamic>>).map((account) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: (account['color'] as Color).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(Icons.account_balance, size: 12, color: account['color'] as Color),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${account['bank']} • ${account['number']}',
                                style: ESUNTypography.bodySmall,
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: ESUNSpacing.sm),
                      
                      // Add more link
                      Row(
                        children: [
                          Text(
                            'Missing any accounts?',
                            style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              context.push('/aa/select-banks');
                            },
                            icon: const Icon(Icons.add_circle_outline, size: 16, color: ESUNColors.primary),
                            label: Text('Add More', style: ESUNTypography.labelSmall.copyWith(color: ESUNColors.primary)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Revoke button
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: selectedCount > 0 ? () {} : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ESUNColors.primary,
                  disabledBackgroundColor: ESUNColors.border,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: Text(
                  'Revoke Consents',
                  style: ESUNTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          
          // Footer
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: ESUNSpacing.lg),
              child: Text(
                'Consent will re-appear automatically once it is re-established',
                style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Consent Details Bottom Sheet
class _ConsentDetailsBottomSheet extends StatelessWidget {
  final Map<String, dynamic> consent;

  const _ConsentDetailsBottomSheet({required this.consent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(ESUNSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consent Details',
                  style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: ESUNSpacing.lg),
                
                _DetailRow(title: 'Provider', value: consent['provider'] as String),
                _DetailRow(title: 'Purpose', value: consent['purpose'] as String),
                _DetailRow(title: 'Frequency', value: consent['frequency'] as String),
                
                const SizedBox(height: ESUNSpacing.lg),
                
                Text(
                  'Accounts',
                  style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: ESUNSpacing.sm),
                
                ...(consent['accounts'] as List<Map<String, dynamic>>).map((account) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: ESUNSpacing.sm),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: (account['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(Icons.account_balance, size: 14, color: account['color'] as Color),
                        ),
                        const SizedBox(width: ESUNSpacing.sm),
                        Text(
                          '${account['bank']} • ••••${account['number']}',
                          style: ESUNTypography.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }),
                
                const SizedBox(height: ESUNSpacing.lg),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: ESUNColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text('Close'),
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

class _DetailRow extends StatelessWidget {
  final String title;
  final String value;

  const _DetailRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESUNSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: ESUNTypography.labelMedium.copyWith(
              color: ESUNColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: ESUNTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// AA Declined Screen
// ============================================================================

class AADeclinedScreen extends ConsumerStatefulWidget {
  const AADeclinedScreen({super.key});

  @override
  ConsumerState<AADeclinedScreen> createState() => _AADeclinedScreenState();
}

class _AADeclinedScreenState extends ConsumerState<AADeclinedScreen> {
  String? _selectedReason;
  final List<String> _reasons = [
    "Didn't receive OTP for verification",
    "Not interested in linking",
    "Not sure about data security",
    "Other",
  ];
  int _countdown = 5;
  bool _showConfirmation = false;
  
  void _confirmDecline() {
    setState(() {
      _showConfirmation = true;
    });
    
    // Start countdown for redirect
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _countdown = 4);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() => _countdown = 3);
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                setState(() => _countdown = 2);
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    setState(() => _countdown = 1);
                    Future.delayed(const Duration(seconds: 1), () {
                      if (mounted) {
                        ref.read(aaOnboardingProvider.notifier).reset();
                        context.go(AppRoutes.payments);
                      }
                    });
                  }
                });
              }
            });
          }
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_showConfirmation) {
      return _buildConfirmationScreen();
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Dark overlay at top for modal effect
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 150,
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Close button
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(ESUNSpacing.lg),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Warning icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFCC80),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFF9800),
                    size: 48,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  'Are you sure?',
                  style: ESUNTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Warning message box
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(ESUNSpacing.lg),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEF9A9A)),
                  ),
                  child: Text(
                    "You won't be able to see personal wealth advisor and insights on ESUN",
                    style: ESUNTypography.bodyMedium.copyWith(
                      color: const Color(0xFFB71C1C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Reason selection
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Tell us why you don't want to track",
                        style: ESUNTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._reasons.map((reason) => _buildReasonOption(reason)),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Buttons
                Padding(
                  padding: const EdgeInsets.all(ESUNSpacing.xxl),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Go Back',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _confirmDecline,
                        child: const Text(
                          'Yes, I want to decline',
                          style: TextStyle(
                            color: Color(0xFFD32F2F),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Footer
                _buildFinvuFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReasonOption(String reason) {
    final isSelected = _selectedReason == reason;
    return GestureDetector(
      onTap: () => setState(() => _selectedReason = reason),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1A237E) : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? const Color(0xFF1A237E) : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reason,
                style: ESUNTypography.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConfirmationScreen() {
    return Scaffold(
      body: Stack(
        children: [
          // Red gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(ESUNSpacing.lg),
                    child: GestureDetector(
                      onTap: () {
                        ref.read(aaOnboardingProvider.notifier).reset();
                        context.go(AppRoutes.payments);
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // X icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Text(
                  'You have declined the account\nsharing request with',
                  style: ESUNTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'ESUN',
                  style: ESUNTypography.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  'You can always share these accounts again\nthrough your ESUN app',
                  style: ESUNTypography.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Info box
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(ESUNSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.white.withOpacity(0.8),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your selected accounts are saved by Finvu in your Account Aggregator profile.',
                              style: ESUNTypography.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          // Restart the journey
                          ref.read(aaOnboardingProvider.notifier).reset();
                          context.go(AppRoutes.aaVerifyPan);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Restart the journey anytime with lesser steps!',
                            style: TextStyle(
                              color: Color(0xFF1A237E),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                Text(
                  'Redirecting to ESUN in $_countdown seconds...',
                  style: ESUNTypography.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Footer
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Powered by RBI-Regulated AA',
                        style: ESUNTypography.labelSmall.copyWith(
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'FINVU',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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

// ============================================================================
// AA Failure Screen
// ============================================================================

class AAFailureScreen extends ConsumerWidget {
  const AAFailureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ESUNSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Failure animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ESUNColors.error.withOpacity(0.1),
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        size: 80,
                        color: ESUNColors.error,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: ESUNSpacing.xl),
              
              Text(
                'Something went wrong',
                style: ESUNTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: ESUNSpacing.md),
              
              Text(
                'We couldn\'t complete the account linking process. This might be due to a temporary issue.',
                style: ESUNTypography.bodyLarge.copyWith(
                  color: ESUNColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: ESUNSpacing.lg),
              
              // Error details card
              Container(
                padding: const EdgeInsets.all(ESUNSpacing.lg),
                decoration: BoxDecoration(
                  color: ESUNColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ESUNColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: ESUNColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Common reasons for failure:',
                            style: ESUNTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildReasonItem('Bank server temporarily unavailable'),
                    _buildReasonItem('Session expired - please try again'),
                    _buildReasonItem('Network connectivity issues'),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Retry button
              SizedBox(
                width: double.infinity,
                child: FPButton(
                  label: 'Try Again',
                  onPressed: () {
                    ref.read(aaOnboardingProvider.notifier).reset();
                    context.go(AppRoutes.aaVerifyPan);
                  },
                ),
              ),
              
              const SizedBox(height: ESUNSpacing.md),
              
              // Home button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(aaOnboardingProvider.notifier).reset();
                    context.go(AppRoutes.payments);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Go to Pay'),
                ),
              ),
              
              const SizedBox(height: ESUNSpacing.lg),
              
              // Contact support
              TextButton.icon(
                onPressed: () {
                  // Open support
                },
                icon: const Icon(Icons.support_agent, size: 20),
                label: const Text('Contact Support'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildReasonItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: ESUNTypography.bodySmall.copyWith(
                color: ESUNColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// AA Renew Consents Screen
// ============================================================================

class AARenewConsentsScreen extends ConsumerStatefulWidget {
  const AARenewConsentsScreen({super.key});

  @override
  ConsumerState<AARenewConsentsScreen> createState() => _AARenewConsentsScreenState();
}

class _AARenewConsentsScreenState extends ConsumerState<AARenewConsentsScreen> {
  final Set<int> _selectedConsents = {};
  
  final List<Map<String, dynamic>> _consents = [
    {
      'id': 1,
      'title': 'Consent Purpose (1/3)',
      'description': 'To verify your savings/current account details for your credit card application',
      'dataFetched': 'Once a month',
      'consentValid': '2 Years',
      'dataStored': '1 Month',
    },
    {
      'id': 2,
      'title': 'Consent Purpose (2/3)',
      'description': 'To provide financial insights and relevant recommendations when needed',
      'dataFetched': 'Once a month',
      'consentValid': '2 Years',
      'dataStored': '1 Month',
    },
    {
      'id': 3,
      'title': 'Consent Purpose (3/3)',
      'description': 'To verify income for the insurer chosen by the customer during life insurance underwriting',
      'dataFetched': 'Once a month',
      'consentValid': '2 Years',
      'dataStored': '1 Month',
    },
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Renew Consents',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: ESUNSpacing.badgeInsets,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volume_up, size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'AA',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(ESUNSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Give Permission',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        'To share your accounts with ',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: ESUNSpacing.tagInsets,
                        decoration: BoxDecoration(
                          color: const Color(0xFF004C8F).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SmartNetworkImage(
                              imageUrl: 'https://t1.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=https://hdfcbank.com&size=128',
                              width: 16,
                              height: 16,
                              placeholderIcon: Icons.account_balance,
                              placeholderColor: const Color(0xFF004C8F),
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.account_balance,
                                size: 16,
                                color: Color(0xFF004C8F),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'HDFC Bank',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Accounts Shared section
                  Container(
                    padding: const EdgeInsets.all(ESUNSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(ESUNSpacing.sm),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.people_outline,
                                color: Colors.grey.shade600,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Accounts Shared',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '2 Savings Accounts',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildAccountTag('• 2785', Colors.red),
                            const SizedBox(width: 8),
                            _buildAccountTag('• 0245', Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              '+ 2 more',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                              ),
                              child: const Text(
                                'View',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Consent purposes
                  ..._consents.map((consent) => _buildConsentCard(consent)),
                  
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(ESUNSpacing.md),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFFF9A825),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You can pause or cancel sharing anytime via your Finvu App',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade800,
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
          
          // Bottom buttons
          Container(
            padding: const EdgeInsets.all(ESUNSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        // Grant permissions and navigate to success
                        context.go(AppRoutes.aaSuccess);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Give permission (${_selectedConsents.length}/${_consents.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.aaDeclined),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        color: Color(0xFFD32F2F),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          _buildFinvuFooter(),
        ],
      ),
    );
  }
  
  Widget _buildAccountTag(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.person_outline,
            size: 12,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildConsentCard(Map<String, dynamic> consent) {
    final isSelected = _selectedConsents.contains(consent['id']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(ESUNSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF1A237E) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  consent['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedConsents.remove(consent['id']);
                    } else {
                      _selectedConsents.add(consent['id']);
                    }
                  });
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1A237E) : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF1A237E) : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            consent['description'],
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip('Data fetched', consent['dataFetched']),
              const SizedBox(width: 16),
              _buildInfoChip('Consent Valid', consent['consentValid']),
              const SizedBox(width: 16),
              _buildInfoChip('Data stored', consent['dataStored']),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
            ),
            child: const Text(
              'View more details',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
