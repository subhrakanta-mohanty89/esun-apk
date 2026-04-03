/// ESUN Forgot Password Screen
///
/// Allows users to request password reset via OTP.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_service.dart';
import '../../theme/theme.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _identifierController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  bool _isEmail(String value) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final id = _identifierController.text.trim();
    final isDigits = RegExp(r'^\d{10,}$').hasMatch(id);
    final payload = isDigits
        ? {'phone': id.startsWith('+') ? id : '+91$id'}
        : {'email': id};

    final api = ref.read(apiServiceProvider);
    final result = await api.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/auth/forgot-password',
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
          msg = 'No account found with this email/phone';
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

    // Navigate to reset password screen with identifier
    context.push(
      AppRoutes.resetPassword,
      extra: payload[isDigits ? 'phone' : 'email'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ESUNSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: ESUNSpacing.xl),
                // Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: ESUNColors.primary100,
                    borderRadius: ESUNRadius.lgRadius,
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    size: 36,
                    color: ESUNColors.primary,
                  ),
                ),
                const SizedBox(height: ESUNSpacing.xl),
                Text(
                  'Reset Your Password',
                  style: ESUNTypography.headlineLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: ESUNSpacing.sm),
                Text(
                  'Enter your email or mobile number and we\'ll send you an OTP to reset your password.',
                  style: ESUNTypography.bodyLarge.copyWith(
                    color: ESUNColors.textSecondary,
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
                const SizedBox(height: ESUNSpacing.xl),
                // Send OTP Button
                SizedBox(
                  width: double.infinity,
                  child: FPButton(
                    label: 'Send OTP',
                    onPressed: _sendOtp,
                    isLoading: _isLoading,
                  ),
                ),
                const SizedBox(height: ESUNSpacing.lg),
                // Back to Login
                Center(
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: Text(
                      'Back to Login',
                      style: ESUNTypography.labelLarge.copyWith(
                        color: ESUNColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
