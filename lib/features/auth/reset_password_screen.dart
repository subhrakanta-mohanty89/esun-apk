/// ESUN Reset Password Screen
///
/// Allows users to enter OTP and new password to reset their password.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_service.dart';
import '../../theme/theme.dart';
import '../../routes/app_routes.dart';
import '../../shared/widgets/widgets.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String identifier;

  const ResetPasswordScreen({
    super.key,
    required this.identifier,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _otpVerified = false;
  int _resendTimer = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendTimer = 30;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendTimer--;
        if (_resendTimer <= 0) {
          _canResend = true;
        }
      });
      return _resendTimer > 0;
    });
  }

  String get _otp => _otpControllers.map((c) => c.text).join();

  bool get _isPhone => widget.identifier.startsWith('+') || 
      RegExp(r'^\d{10,}$').hasMatch(widget.identifier);

  Future<void> _verifyOtp() async {
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final api = ref.read(apiServiceProvider);
    final payload = _isPhone
        ? {'phone': widget.identifier, 'otp': _otp}
        : {'email': widget.identifier, 'otp': _otp};

    final result = await api.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/auth/forgot-password/verify',
      data: payload,
      skipAuth: true,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isError || result.data == null || result.data!['success'] != true) {
      String msg = 'Invalid OTP';
      final errorData = result.data?['error'];
      if (errorData != null) {
        msg = errorData['message'] ?? msg;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      return;
    }

    setState(() => _otpVerified = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP verified! Now set your new password.')),
    );
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final api = ref.read(apiServiceProvider);
    final payload = {
      if (_isPhone) 'phone': widget.identifier,
      if (!_isPhone) 'email': widget.identifier,
      'otp': _otp,
      'new_password': _passwordController.text,
    };

    final result = await api.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/auth/reset-password',
      data: payload,
      skipAuth: true,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isError || result.data == null || result.data!['success'] != true) {
      String msg = 'Failed to reset password';
      final errorData = result.data?['error'];
      if (errorData != null) {
        msg = errorData['message'] ?? msg;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      return;
    }

    // Success - show dialog and redirect to login
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: ESUNRadius.lgRadius,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: ESUNColors.success,
                size: 64,
              ),
              const SizedBox(height: ESUNSpacing.lg),
              Text(
                'Password Reset Successful!',
                style: ESUNTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ESUNSpacing.sm),
              Text(
                'You can now login with your new password.',
                style: ESUNTypography.bodyMedium.copyWith(
                  color: ESUNColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go(AppRoutes.login);
                },
                child: const Text('Go to Login'),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() => _isLoading = true);

    final api = ref.read(apiServiceProvider);
    final payload = _isPhone
        ? {'phone': widget.identifier}
        : {'email': widget.identifier};

    final result = await api.post<Map<String, dynamic>>(
      '${ApiConfig.apiPrefix}/auth/forgot-password',
      data: payload,
      skipAuth: true,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isError || result.data == null || result.data!['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to resend OTP')),
      );
      return;
    }

    // Clear OTP fields
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
    _startResendTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP sent successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ESUNSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: ESUNSpacing.lg),
                // Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _otpVerified ? ESUNColors.success100 : ESUNColors.primary100,
                    borderRadius: ESUNRadius.lgRadius,
                  ),
                  child: Icon(
                    _otpVerified ? Icons.check_rounded : Icons.sms_rounded,
                    size: 36,
                    color: _otpVerified ? ESUNColors.success : ESUNColors.primary,
                  ),
                ),
                const SizedBox(height: ESUNSpacing.xl),
                Text(
                  _otpVerified ? 'Create New Password' : 'Enter OTP',
                  style: ESUNTypography.headlineLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: ESUNSpacing.sm),
                Text(
                  _otpVerified
                      ? 'Enter your new password below.'
                      : 'We sent a 6-digit code to ${_maskIdentifier(widget.identifier)}',
                  style: ESUNTypography.bodyLarge.copyWith(
                    color: ESUNColors.textSecondary,
                  ),
                ),
                const SizedBox(height: ESUNSpacing.xxl),

                // OTP Input (shown when not verified)
                if (!_otpVerified) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 48,
                        height: 56,
                        child: TextFormField(
                          controller: _otpControllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: ESUNTypography.headlineMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: ESUNColors.neutral100,
                            border: OutlineInputBorder(
                              borderRadius: ESUNRadius.mdRadius,
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: ESUNRadius.mdRadius,
                              borderSide: const BorderSide(
                                color: ESUNColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            } else if (value.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                            // Auto-verify when all digits entered
                            if (_otp.length == 6) {
                              _verifyOtp();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: ESUNSpacing.lg),
                  // Resend OTP
                  Center(
                    child: _canResend
                        ? TextButton(
                            onPressed: _resendOtp,
                            child: Text(
                              'Resend OTP',
                              style: ESUNTypography.labelLarge.copyWith(
                                color: ESUNColors.primary,
                              ),
                            ),
                          )
                        : Text(
                            'Resend OTP in ${_resendTimer}s',
                            style: ESUNTypography.bodyMedium.copyWith(
                              color: ESUNColors.textSecondary,
                            ),
                          ),
                  ),
                  const SizedBox(height: ESUNSpacing.xl),
                  // Verify Button
                  SizedBox(
                    width: double.infinity,
                    child: FPButton(
                      label: 'Verify OTP',
                      onPressed: _verifyOtp,
                      isLoading: _isLoading,
                    ),
                  ),
                ],

                // Password fields (shown when OTP verified)
                if (_otpVerified) ...[
                  FPTextField(
                    controller: _passwordController,
                    label: 'New Password',
                    hint: 'Enter new password',
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
                        return 'Enter new password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      if (!RegExp(r'[A-Z]').hasMatch(value)) {
                        return 'Password must contain an uppercase letter';
                      }
                      if (!RegExp(r'[a-z]').hasMatch(value)) {
                        return 'Password must contain a lowercase letter';
                      }
                      if (!RegExp(r'\d').hasMatch(value)) {
                        return 'Password must contain a digit';
                      }
                      if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                        return 'Password must contain a special character';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: ESUNSpacing.lg),
                  FPTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hint: 'Re-enter new password',
                    obscureText: _obscureConfirmPassword,
                    suffix: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: ESUNColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: ESUNSpacing.sm),
                  // Password requirements
                  Container(
                    padding: const EdgeInsets.all(ESUNSpacing.md),
                    decoration: BoxDecoration(
                      color: ESUNColors.neutral100,
                      borderRadius: ESUNRadius.mdRadius,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password Requirements:',
                          style: ESUNTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: ESUNSpacing.xs),
                        _buildRequirement('At least 8 characters'),
                        _buildRequirement('One uppercase letter'),
                        _buildRequirement('One lowercase letter'),
                        _buildRequirement('One digit'),
                        _buildRequirement('One special character'),
                      ],
                    ),
                  ),
                  const SizedBox(height: ESUNSpacing.xl),
                  // Reset Button
                  SizedBox(
                    width: double.infinity,
                    child: FPButton(
                      label: 'Reset Password',
                      onPressed: _resetPassword,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 14,
            color: ESUNColors.textSecondary,
          ),
          const SizedBox(width: ESUNSpacing.xs),
          Text(
            text,
            style: ESUNTypography.bodySmall.copyWith(
              color: ESUNColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _maskIdentifier(String identifier) {
    if (identifier.contains('@')) {
      // Email
      final parts = identifier.split('@');
      final local = parts[0];
      final domain = parts[1];
      if (local.length > 2) {
        return '${local[0]}***${local[local.length - 1]}@$domain';
      }
      return '***@$domain';
    } else {
      // Phone
      if (identifier.length >= 10) {
        return '${identifier.substring(0, 3)}****${identifier.substring(identifier.length - 4)}';
      }
      return '****${identifier.substring(identifier.length - 4)}';
    }
  }
}
