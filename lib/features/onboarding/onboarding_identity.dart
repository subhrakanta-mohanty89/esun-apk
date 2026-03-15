import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';
import '../../theme/theme.dart';
import '../../shared/widgets/widgets.dart';
import '../../core/network/api_service.dart';

/// Simple model passed between onboarding steps.
class OnboardingUserData {
  final String fullName;
  final String phone;
  final String email;
  final String? password;

  const OnboardingUserData({
    required this.fullName,
    required this.phone,
    required this.email,
    this.password,
  });
}

class OnboardingIdentityScreen extends ConsumerStatefulWidget {
  const OnboardingIdentityScreen({super.key});

  @override
  ConsumerState<OnboardingIdentityScreen> createState() => _OnboardingIdentityScreenState();
}

class _OnboardingIdentityScreenState extends ConsumerState<OnboardingIdentityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validate password strength
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter a password';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Must contain at least one lowercase letter';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Must contain at least one digit';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Must contain at least one special character';
    }
    return null;
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final fullName = _nameController.text.trim();
    final password = _passwordController.text;
    final api = ref.read(apiServiceProvider);

    // Use register endpoint for new user registration (sends OTP)
    final registerPayload = {
      'phone': '+91$phone',
      'email': email,
      'full_name': fullName,
      'password': password,
    };

    final result = await api.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/auth/register',
      data: registerPayload,
      skipAuth: true,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.isError || result.data?['success'] != true) {
      String msg = 'Registration failed';
      final errorData = result.data?['error'];
      if (errorData != null) {
        final code = errorData['code'];
        if (code == 'ALREADY_EXISTS') {
          // User already exists - redirect to login
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account already exists. Redirecting to login...')),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) context.go(AppRoutes.login);
          return;
        } else if (code == 'RATE_LIMITED') {
          msg = 'Too many requests. Please try again later.';
        } else if (code == 'VALIDATION_ERROR') {
          // Show specific validation error from backend
          msg = errorData['message'] ?? msg;
        } else {
          msg = errorData['message'] ?? msg;
        }
      } else if (result.error != null) {
        msg = result.error!.message;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    final data = OnboardingUserData(
      fullName: fullName,
      phone: '+91$phone',
      email: email,
      password: password,
    );

    context.push(AppRoutes.onboardingVerify, extra: data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ESUNSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: ESUNSpacing.lg),
                // Header
                Text(
                  'Register account',
                  style: ESUNTypography.headlineLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: ESUNSpacing.sm),
                Text(
                  'Create your ESUN account to get started.',
                  style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textSecondary),
                ),
                const SizedBox(height: ESUNSpacing.xxl),

                FPTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'John Doe',
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Enter your full name';
                    if (value.trim().length < 3) return 'Name looks too short';
                    return null;
                  },
                ),
                const SizedBox(height: ESUNSpacing.lg),

                FPTextField(
                  controller: _phoneController,
                  label: 'Mobile Number',
                  hint: '9876543210',
                  prefixText: '+91 ',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter your mobile number';
                    if (value.length != 10) return 'Enter a valid 10-digit number';
                    return null;
                  },
                ),
                const SizedBox(height: ESUNSpacing.lg),

                FPTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter your email';
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: ESUNSpacing.lg),

                // Password field
                FPTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Create a strong password',
                  obscureText: _obscurePassword,
                  suffix: GestureDetector(
                    onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: ESUNColors.textTertiary,
                      size: 20,
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: ESUNSpacing.xs),
                Text(
                  'Must be 8+ chars with uppercase, lowercase, digit & special char',
                  style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textTertiary),
                ),
                const SizedBox(height: ESUNSpacing.lg),

                // Confirm Password field
                FPTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  obscureText: _obscureConfirmPassword,
                  suffix: GestureDetector(
                    onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    child: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: ESUNColors.textTertiary,
                      size: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Confirm your password';
                    if (value != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),

                const SizedBox(height: ESUNSpacing.xl),

                SizedBox(
                  width: double.infinity,
                  child: FPButton(
                    label: 'Send OTP',
                    onPressed: _continue,
                    isLoading: _isSubmitting,
                  ),
                ),

                const SizedBox(height: ESUNSpacing.lg),
                Text(
                  'We’ll send separate codes to verify your mobile number and email.',
                  style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textTertiary),
                ),                const SizedBox(height: ESUNSpacing.xl),
                Center(
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text('Already have an account? Login'),
                  ),
                ),              ],
            ),
          ),
        ),
      ),
    );
  }
}


