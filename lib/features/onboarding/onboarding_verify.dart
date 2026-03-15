import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../routes/app_routes.dart';
import '../../theme/theme.dart';
import '../../shared/widgets/widgets.dart';
import '../../state/app_state.dart';
import 'onboarding_identity.dart';

class OnboardingVerifyScreen extends ConsumerStatefulWidget {
  final OnboardingUserData? data;

  const OnboardingVerifyScreen({super.key, this.data});

  @override
  ConsumerState<OnboardingVerifyScreen> createState() => _OnboardingVerifyScreenState();
}

class _OnboardingVerifyScreenState extends ConsumerState<OnboardingVerifyScreen> {
  String _phoneOtp = '';
  String _emailOtp = '';
  bool _isVerifying = false;
  bool _permissionsRequested = false;
  String? _errorMessage;

  Future<void> _verify() async {
    if (_phoneOtp.length != 6 || _emailOtp.length != 6) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });
    
    final ok = await ref.read(authStateProvider.notifier).login(
      identifier: widget.data?.phone ?? '',
      otp: _phoneOtp,
      fullName: widget.data?.fullName,
      email: widget.data?.email,
    );
    
    if (!mounted) return;

    if (ok) {
      if (!_permissionsRequested) {
        _permissionsRequested = true;
        await _requestAppPermissions();
      }
      if (!mounted) return;
      // Navigate to data linking screen for new users
      context.go(AppRoutes.installationDataLinking);
    } else {
      final err = ref.read(authStateProvider).error ?? 'Invalid OTP code';
      setState(() {
        _isVerifying = false;
        _errorMessage = err;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    }
  }

  Future<void> _requestAppPermissions() async {
    final permissions = <Permission>[
      Permission.locationWhenInUse,
      Permission.camera,
      Permission.microphone,
      Permission.contacts,
      Permission.photos,
      Permission.storage,
    ];

    final results = await permissions.request();
    final denied = results.entries
        .where((entry) => entry.value.isPermanentlyDenied || entry.value.isDenied)
        .map((e) => e.key)
        .toList();

    if (!mounted) return;
    if (denied.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Some permissions were denied. You can enable them in Settings for full experience.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify your contact details'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? ESUNSpacing.lg : ESUNSpacing.xl),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data != null) ...[
                          Text(
                            data.fullName,
                            style: ESUNTypography.titleLarge.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: ESUNSpacing.xs),
                          Text(
                            '${data.phone}  -  ${data.email}',
                            style: ESUNTypography.bodyMedium.copyWith(color: ESUNColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: isSmallScreen ? ESUNSpacing.lg : ESUNSpacing.xl),
                        ],

                        Text(
                          'Mobile verification',
                          style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: ESUNSpacing.sm),
                        FPOtpField(
                          length: 6,
                          onChanged: (value) => setState(() => _phoneOtp = value),
                          onCompleted: (value) => setState(() => _phoneOtp = value),
                        ),
                        const SizedBox(height: ESUNSpacing.sm),
                        Text(
                          'Code sent to your mobile number',
                          style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textTertiary),
                        ),

                        SizedBox(height: isSmallScreen ? ESUNSpacing.lg : ESUNSpacing.xl),

                        Text(
                          'Email verification',
                          style: ESUNTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: ESUNSpacing.sm),
                        FPOtpField(
                          length: 6,
                          onChanged: (value) => setState(() => _emailOtp = value),
                          onCompleted: (value) => setState(() => _emailOtp = value),
                        ),
                        const SizedBox(height: ESUNSpacing.sm),
                        Text(
                          'Code sent to your email address',
                          style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textTertiary),
                        ),

                        const Spacer(),
                        SizedBox(height: isSmallScreen ? ESUNSpacing.lg : ESUNSpacing.xl),

                        SizedBox(
                          width: double.infinity,
                          child: FPButton(
                            label: 'Verify & Continue',
                            onPressed: (_phoneOtp.length == 6 && _emailOtp.length == 6 && !_isVerifying)
                                ? _verify
                                : null,
                            isLoading: _isVerifying,
                          ),
                        ),
                        const SizedBox(height: ESUNSpacing.md),
                        Text(
                          "Did not get a code? Check spam or request again after a minute.",
                          style: ESUNTypography.bodySmall.copyWith(color: ESUNColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}



