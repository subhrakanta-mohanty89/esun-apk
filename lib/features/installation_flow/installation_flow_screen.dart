/// ESUN Installation Flow Screen
///
/// Main installation flow controller that manages the onboarding journey:
/// Onboarding → Registration → Permissions → Data Linking.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';
import 'welcome_screens.dart';
import 'permissions_screen.dart';
import 'data_linking_screen.dart';

/// Installation flow step enum
enum InstallationStep {
  welcome,
  registration,
  permissions,
  dataLinking,
}

/// Installation flow state
class InstallationFlowState {
  final InstallationStep currentStep;
  final int welcomePageIndex;
  final bool permissionsGranted;
  final bool dataLinkingComplete;
  final bool skippedDataLinking;

  const InstallationFlowState({
    this.currentStep = InstallationStep.welcome,
    this.welcomePageIndex = 0,
    this.permissionsGranted = false,
    this.dataLinkingComplete = false,
    this.skippedDataLinking = false,
  });

  InstallationFlowState copyWith({
    InstallationStep? currentStep,
    int? welcomePageIndex,
    bool? permissionsGranted,
    bool? dataLinkingComplete,
    bool? skippedDataLinking,
  }) {
    return InstallationFlowState(
      currentStep: currentStep ?? this.currentStep,
      welcomePageIndex: welcomePageIndex ?? this.welcomePageIndex,
      permissionsGranted: permissionsGranted ?? this.permissionsGranted,
      dataLinkingComplete: dataLinkingComplete ?? this.dataLinkingComplete,
      skippedDataLinking: skippedDataLinking ?? this.skippedDataLinking,
    );
  }
}

/// Installation flow notifier
class InstallationFlowNotifier extends StateNotifier<InstallationFlowState> {
  InstallationFlowNotifier() : super(const InstallationFlowState());

  void setStep(InstallationStep step) {
    state = state.copyWith(currentStep: step);
  }

  void setWelcomePageIndex(int index) {
    state = state.copyWith(welcomePageIndex: index);
  }

  void completeWelcome() {
    state = state.copyWith(currentStep: InstallationStep.registration);
  }

  void completeRegistration() {
    state = state.copyWith(currentStep: InstallationStep.permissions);
  }

  void completePermissions(bool granted) {
    state = state.copyWith(
      permissionsGranted: granted,
      currentStep: InstallationStep.dataLinking,
    );
  }

  void completeDataLinking(bool completed) {
    state = state.copyWith(
      dataLinkingComplete: completed,
      skippedDataLinking: !completed,
    );
  }

  void reset() {
    state = const InstallationFlowState();
  }
}

/// Provider for installation flow state
final installationFlowProvider =
    StateNotifierProvider<InstallationFlowNotifier, InstallationFlowState>(
        (ref) => InstallationFlowNotifier());

/// Main Installation Flow Screen
class InstallationFlowScreen extends ConsumerStatefulWidget {
  /// Optional start step (for deep linking)
  final String? startStep;

  const InstallationFlowScreen({super.key, this.startStep});

  @override
  ConsumerState<InstallationFlowScreen> createState() =>
      _InstallationFlowScreenState();
}

class _InstallationFlowScreenState extends ConsumerState<InstallationFlowScreen> {
  @override
  void initState() {
    super.initState();
    _handleDeepLinkStep();
  }

  void _handleDeepLinkStep() {
    final step = widget.startStep;
    if (step != null) {
      final notifier = ref.read(installationFlowProvider.notifier);
      switch (step) {
        case 'permissions':
          notifier.setStep(InstallationStep.permissions);
          break;
        case 'data-linking':
          notifier.setStep(InstallationStep.dataLinking);
          break;
        case 'aa-onboarding':
          // Navigate directly to AA onboarding
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go(AppRoutes.aaVerifyPan);
          });
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(installationFlowProvider);

    return PopScope(
      canPop: flowState.currentStep == InstallationStep.welcome &&
          flowState.welcomePageIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Handle back navigation within flow
          final notifier = ref.read(installationFlowProvider.notifier);
          switch (flowState.currentStep) {
            case InstallationStep.welcome:
              if (flowState.welcomePageIndex > 0) {
                notifier.setWelcomePageIndex(flowState.welcomePageIndex - 1);
              }
              break;
            case InstallationStep.registration:
              notifier.setStep(InstallationStep.welcome);
              break;
            case InstallationStep.permissions:
              // Can't go back from permissions after registration
              break;
            case InstallationStep.dataLinking:
              // Can't go back from data linking
              break;
          }
        }
      },
      child: _buildCurrentStep(flowState.currentStep),
    );
  }

  Widget _buildCurrentStep(InstallationStep step) {
    switch (step) {
      case InstallationStep.welcome:
        return WelcomeScreens(
          onComplete: () {
            ref.read(installationFlowProvider.notifier).completeWelcome();
            context.go(AppRoutes.onboardingDetails);
          },
        );
      case InstallationStep.registration:
        // Registration is handled by existing OnboardingIdentityScreen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go(AppRoutes.onboardingDetails);
        });
        return const SizedBox.shrink();
      case InstallationStep.permissions:
        return PermissionsScreen(
          onComplete: (granted) {
            ref.read(installationFlowProvider.notifier).completePermissions(granted);
          },
        );
      case InstallationStep.dataLinking:
        return DataLinkingScreen(
          onLinkNow: () {
            ref.read(installationFlowProvider.notifier).completeDataLinking(true);
            context.go(AppRoutes.aaVerifyPan);
          },
          onDoItLater: () {
            ref.read(installationFlowProvider.notifier).completeDataLinking(false);
            context.go(AppRoutes.payments);
          },
        );
    }
  }
}
