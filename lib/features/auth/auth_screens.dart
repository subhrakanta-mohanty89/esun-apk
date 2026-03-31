/// ESUN Auth Screens
/// 
/// Login, OTP verification, and biometric unlock screens.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_service.dart';
import '../../theme/theme.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/widgets.dart';
import '../../state/app_state.dart';

/// Login Screen
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

enum LoginMode { otp, password }

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  LoginMode _loginMode = LoginMode.otp;
  
  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  bool _isEmail(String value) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  
  bool _isPhoneNumber(String value) {
    // Match 10 digits, or +91 followed by 10 digits, or 91 followed by 10 digits
    return RegExp(r'^(\+91|91)?\d{10}$').hasMatch(value);
  }
  
  String _normalizePhone(String phone) {
    // Remove all non-digit characters except leading +
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    // Extract just the digits
    final digits = cleaned.replaceAll('+', '');
    // If 10 digits, add +91 prefix
    if (digits.length == 10) {
      return '+91$digits';
    }
    // If 12 digits starting with 91, add + prefix
    if (digits.length == 12 && digits.startsWith('91')) {
      return '+$digits';
    }
    // Otherwise return with + prefix
    return '+$digits';
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final id = _identifierController.text.trim();
    final isPhone = _isPhoneNumber(id);
    final payload = isPhone
        ? {'phone': _normalizePhone(id)}
        : {'email': id};

    final api = ref.read(apiServiceProvider);
    final result = await api.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/auth/initiate',
      data: payload,
      skipAuth: true,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isError || result.data == null || result.data!['success'] != true) {
      String msg = 'Failed to send OTP';
      final errorData = result.data?['error'];
      if (errorData != null) {
        final code = errorData['code'];
        if (code == 'NOT_FOUND') {
          // User not found - redirect to registration
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No account found. Redirecting to registration...')),
          );
          if (mounted) context.go(AppRoutes.onboarding);
          return;
        } else if (code == 'RATE_LIMITED') {
          msg = 'Too many requests. Please try again later.';
        } else {
          msg = errorData['message'] ?? msg;
        }
      } else if (result.error != null) {
        msg = result.error!.message;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      return;
    }

    context.push(AppRoutes.otp, extra: payload[isPhone ? 'phone' : 'email']);
  }

  Future<void> _loginWithPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final id = _identifierController.text.trim();
    final password = _passwordController.text;
    final isPhone = _isPhoneNumber(id);
    final Map<String, dynamic> payload = {
      if (isPhone) 'phone': _normalizePhone(id),
      if (!isPhone) 'email': id,
      'password': password,
    };

    final api = ref.read(apiServiceProvider);
    final result = await api.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/auth/login',
      data: payload,
      skipAuth: true,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isError || result.data == null || result.data!['success'] != true) {
      String msg = 'Login failed';
      final errorData = result.data?['error'];
      if (errorData != null) {
        final code = errorData['code'];
        if (code == 'NOT_FOUND') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No account found. Redirecting to registration...')),
          );
          if (mounted) context.go(AppRoutes.onboarding);
          return;
        } else if (code == 'INVALID_CREDENTIALS') {
          msg = 'Invalid password. Please try again.';
        } else if (code == 'RATE_LIMITED') {
          msg = 'Too many attempts. Please try again later.';
        } else {
          msg = errorData['message'] ?? msg;
        }
      } else if (result.error != null) {
        msg = result.error!.message;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      return;
    }

    // Successful login - save tokens and navigate
    final data = result.data!['data'];
    final tokens = data['tokens'] as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>;
    final deviceId = data['device_id']?.toString();
    
    await ref.read(authStateProvider.notifier).loginWithTokens(
      accessToken: tokens['access_token'] as String,
      refreshToken: tokens['refresh_token'] as String,
      user: user,
      deviceId: deviceId,
    );
    // GoRouter redirect handles navigation when authState changes
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: ESUNSpacing.xxxl),
                // Logo & Welcome — gradient background
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: ESUNColors.primaryGradient,
                    borderRadius: ESUNRadius.lgRadius,
                    boxShadow: [
                      BoxShadow(
                        color: ESUNColors.primary.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: ESUNSpacing.xl),
                Text(
                  'Welcome to ESUN',
                  style: ESUNTypography.headlineLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: ESUNSpacing.xs),
                Text(
                  'Your personal finance companion',
                  style: ESUNTypography.bodyLarge.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
                const SizedBox(height: ESUNSpacing.xxl),
                // Login Mode Toggle — pill style
                Container(
                  decoration: BoxDecoration(
                    color: ESUNColors.surfaceVariant,
                    borderRadius: ESUNRadius.lgRadius,
                  ),
                  padding: const EdgeInsets.all(ESUNSpacing.xs),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _loginMode = LoginMode.otp),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _loginMode == LoginMode.otp ? Colors.white : Colors.transparent,
                              borderRadius: ESUNRadius.mdRadius,
                              boxShadow: _loginMode == LoginMode.otp
                                  ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Login with OTP',
                                style: ESUNTypography.labelMedium.copyWith(
                                  color: _loginMode == LoginMode.otp ? ESUNColors.primary : ESUNColors.textTertiary,
                                  fontWeight: _loginMode == LoginMode.otp ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _loginMode = LoginMode.password),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _loginMode == LoginMode.password ? Colors.white : Colors.transparent,
                              borderRadius: ESUNRadius.mdRadius,
                              boxShadow: _loginMode == LoginMode.password
                                  ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Login with Password',
                                style: ESUNTypography.labelMedium.copyWith(
                                  color: _loginMode == LoginMode.password ? ESUNColors.primary : ESUNColors.textTertiary,
                                  fontWeight: _loginMode == LoginMode.password ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ESUNSpacing.xxl),
                // Email or Phone Input
                FPTextField(
                  controller: _identifierController,
                  label: 'Email or Mobile',
                  hint: 'you@example.com or 9876543210',
                  keyboardType: TextInputType.emailAddress,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9@a-zA-Z._+-]')),
                    LengthLimitingTextInputFormatter(50),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter email or mobile number';
                    }
                    final trimmed = value.trim();
                    final isDigits = RegExp(r'^\d{10}$').hasMatch(trimmed);
                    if (isDigits || _isEmail(trimmed)) return null;
                    return 'Enter a valid email or 10-digit mobile number';
                  },
                ),
                const SizedBox(height: ESUNSpacing.md),
                // Password Field (shown only in password mode)
                if (_loginMode == LoginMode.password) ...[
                  FPTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Enter your password',
                    obscureText: _obscurePassword,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: ESUNColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: ESUNSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(AppRoutes.forgotPassword),
                      child: Text(
                        'Forgot Password?',
                        style: ESUNTypography.bodySmall.copyWith(
                          color: ESUNColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: ESUNSpacing.xxl),
                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FPButton(
                    label: _loginMode == LoginMode.otp ? 'Send OTP' : 'Login',
                    onPressed: _loginMode == LoginMode.otp ? _sendOtp : _loginWithPassword,
                    isLoading: _isLoading,
                  ),
                ),
                const SizedBox(height: ESUNSpacing.lg),
                // Divider with "or"
                Row(
                  children: [
                    Expanded(child: Divider(color: ESUNColors.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: ESUNSpacing.lg),
                      child: Text(
                        'or',
                        style: ESUNTypography.bodySmall.copyWith(
                          color: ESUNColors.textTertiary,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: ESUNColors.divider)),
                  ],
                ),
                const SizedBox(height: ESUNSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => context.go(AppRoutes.onboarding),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: ESUNColors.primary.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: ESUNRadius.mdRadius,
                      ),
                    ),
                    child: Text(
                      "Don't have an account? Create one",
                      style: ESUNTypography.labelMedium.copyWith(
                        color: ESUNColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: ESUNSpacing.xxl),
                // Terms
                Text.rich(
                  TextSpan(
                    text: 'By continuing, you agree to our ',
                    style: ESUNTypography.bodySmall.copyWith(
                      color: ESUNColors.textTertiary,
                    ),
                    children: [
                      TextSpan(
                        text: 'Terms of Service',
                        style: ESUNTypography.bodySmall.copyWith(
                          color: ESUNColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: ESUNTypography.bodySmall.copyWith(
                          color: ESUNColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: ESUNSpacing.xxl),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// OTP Verification Screen
class OtpScreen extends ConsumerStatefulWidget {
  final String identifier;
  
  const OtpScreen({
    super.key,
    required this.identifier,
  });
  
  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _otpControllers = 
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = 
      List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  int _resendTimer = 30;
  bool _canResend = false;
  
  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }
  
  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _canResend = true;
        }
      });
      return _resendTimer > 0;
    });
  }
  
  @override
  void dispose() {
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
  
  String get _otp => _otpControllers.map((c) => c.text).join();
  
  Future<void> _verifyOtp() async {
    if (_otp.length != 6) return;
    
    setState(() => _isLoading = true);
    final ok = await ref.read(authStateProvider.notifier).login(
          identifier: widget.identifier,
          otp: _otp,
        );
    if (!mounted) return;

    if (ok) {
      // Keep loading overlay; GoRouter redirect navigates automatically
      return;
    }
    setState(() => _isLoading = false);
    final err = ref.read(authStateProvider).error ?? 'Invalid code';
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    }
  }
  
  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_otp.length == 6) {
      _verifyOtp();
    }
  }
  
  void _onKeyPressed(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _otpControllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }
  
  void _resendOtp() {
    if (!_canResend) return;
    setState(() {
      _resendTimer = 30;
      _canResend = false;
    });
    _startResendTimer();
    final api = ref.read(apiServiceProvider);
    final isEmail = widget.identifier.contains('@');
    api.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/auth/resend-otp',
      data: isEmail ? {'email': widget.identifier} : {'phone': widget.identifier},
      skipAuth: true,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isEmail = widget.identifier.contains('@');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ESUNSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEmail ? 'Verify Email' : 'Verify Phone',
                style: ESUNTypography.headlineLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: ESUNSpacing.sm),
              Text.rich(
                TextSpan(
                  text: 'Enter the 6-digit code sent to ',
                  style: ESUNTypography.bodyLarge.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                  children: [
                    TextSpan(
                      text: widget.identifier,
                      style: ESUNTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ESUNColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ESUNSpacing.xxl),
              // OTP Input Fields
              LayoutBuilder(
                builder: (context, constraints) {
                  final boxWidth = (constraints.maxWidth - (5 * ESUNSpacing.sm)) / 6;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return Container(
                        width: boxWidth.clamp(52.0, 64.0),
                        height: 64,
                        margin: EdgeInsets.only(
                          right: index < 5 ? ESUNSpacing.sm : 0,
                        ),
                        child: RawKeyboardListener(
                          focusNode: FocusNode(),
                          onKey: (event) => _onKeyPressed(index, event),
                          child: TextField(
                            controller: _otpControllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: ESUNTypography.headlineLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: ESUNColors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                            cursorColor: ESUNColors.primary,
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: ESUNColors.surfaceVariant,
                              contentPadding: const EdgeInsets.symmetric(vertical: ESUNSpacing.lg),
                              border: OutlineInputBorder(
                                borderRadius: ESUNRadius.mdRadius,
                                borderSide: BorderSide(
                                  color: ESUNColors.textPrimary.withOpacity(0.35),
                                  width: 1.35,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: ESUNRadius.mdRadius,
                                borderSide: BorderSide(
                                  color: _otpControllers[index].text.isNotEmpty 
                                      ? ESUNColors.primary
                                      : ESUNColors.textPrimary.withOpacity(0.45),
                                  width: 1.85,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: ESUNRadius.mdRadius,
                                borderSide: const BorderSide(
                                  color: ESUNColors.primary,
                                  width: 2.2,
                                ),
                              ),
                              focusColor: ESUNColors.primary,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) {
                              setState(() {});
                              _onOtpChanged(index, value);
                            },
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: ESUNSpacing.xl),
              // Resend
              Center(
                child: _canResend
                    ? TextButton(
                        onPressed: _resendOtp,
                        child: const Text('Resend OTP'),
                      )
                    : Text(
                        'Resend in ${_resendTimer}s',
                        style: ESUNTypography.bodyMedium.copyWith(
                          color: ESUNColors.textTertiary,
                        ),
                      ),
              ),
              const Spacer(),
              // Verify Button
              SizedBox(
                width: double.infinity,
                child: FPButton(
                  label: 'Verify',
                  onPressed: _otp.length == 6 ? _verifyOtp : null,
                  isLoading: _isLoading,
                ),
              ),
              const SizedBox(height: ESUNSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

/// Biometric Unlock Screen
class BiometricUnlockScreen extends ConsumerStatefulWidget {
  const BiometricUnlockScreen({super.key});
  
  @override
  ConsumerState<BiometricUnlockScreen> createState() => _BiometricUnlockScreenState();
}

class _BiometricUnlockScreenState extends ConsumerState<BiometricUnlockScreen> {
  bool _isAuthenticating = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    // Trigger biometric prompt after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }
  
  Future<void> _authenticate() async {
    if (!mounted || _isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });
    
    await ref.read(authStateProvider.notifier).authenticateWithBiometrics();
    
    if (!mounted) return;
    
    final authState = ref.read(authStateProvider);
    if (authState.status == AuthStatus.authenticated) {
      context.go(AppRoutes.payments);
    } else {
      setState(() {
        _isAuthenticating = false;
        _errorMessage = authState.error ?? 'Authentication failed. Tap to retry.';
      });
    }
  }
  
  void _usePassword() {
    // Fall back to login screen for password entry
    context.go(AppRoutes.login);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ESUNSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Fingerprint Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ESUNColors.primary.withOpacity(0.1),
                      ESUNColors.primary.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ESUNColors.primary.withOpacity(0.15),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.fingerprint,
                  size: 64,
                  color: ESUNColors.primary,
                ),
              ),
              const SizedBox(height: ESUNSpacing.xl),
              Text(
                'Touch to Unlock',
                style: ESUNTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: ESUNSpacing.sm),
              Text(
                'Use your fingerprint to access ESUN',
                style: ESUNTypography.bodyLarge.copyWith(
                  color: ESUNColors.textSecondary,
                ),
              ),
              const Spacer(),
              // Retry Button
              TextButton.icon(
                onPressed: _isAuthenticating ? null : _authenticate,
                icon: const Icon(Icons.fingerprint),
                label: Text(_isAuthenticating ? 'Authenticating...' : 'Try Again'),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: ESUNSpacing.sm),
                Text(
                  _errorMessage!,
                  style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: ESUNSpacing.md),
              // Use Password
              TextButton(
                onPressed: _usePassword,
                child: const Text('Use Password Instead'),
              ),
              const SizedBox(height: ESUNSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}



