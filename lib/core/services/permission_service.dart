/// ESUN Permission Service
///
/// Handles app permissions for contacts, camera, microphone, and media.
/// Auto-requests essential permissions on app startup.

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Permission status provider
final permissionStatusProvider = StateNotifierProvider<PermissionStatusNotifier, PermissionStatusState>((ref) {
  return PermissionStatusNotifier();
});

/// Permission status state
class PermissionStatusState {
  final bool contacts;
  final bool camera;
  final bool microphone;
  final bool photos;
  final bool storage;
  final bool isInitialized;

  const PermissionStatusState({
    this.contacts = false,
    this.camera = false,
    this.microphone = false,
    this.photos = false,
    this.storage = false,
    this.isInitialized = false,
  });

  PermissionStatusState copyWith({
    bool? contacts,
    bool? camera,
    bool? microphone,
    bool? photos,
    bool? storage,
    bool? isInitialized,
  }) {
    return PermissionStatusState(
      contacts: contacts ?? this.contacts,
      camera: camera ?? this.camera,
      microphone: microphone ?? this.microphone,
      photos: photos ?? this.photos,
      storage: storage ?? this.storage,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  bool get allGranted => contacts && camera && microphone && (photos || storage);
}

/// Permission status notifier
class PermissionStatusNotifier extends StateNotifier<PermissionStatusState> {
  PermissionStatusNotifier() : super(const PermissionStatusState());

  /// Initialize and check all permissions
  Future<void> initialize() async {
    final contacts = await Permission.contacts.status;
    final camera = await Permission.camera.status;
    final microphone = await Permission.microphone.status;
    final photos = await Permission.photos.status;
    final storage = await Permission.storage.status;

    state = state.copyWith(
      contacts: contacts.isGranted,
      camera: camera.isGranted,
      microphone: microphone.isGranted,
      photos: photos.isGranted,
      storage: storage.isGranted,
      isInitialized: true,
    );
  }

  /// Request all essential permissions
  Future<bool> requestAllPermissions() async {
    final results = await [
      Permission.contacts,
      Permission.camera,
      Permission.microphone,
      Permission.photos,
      Permission.storage,
    ].request();

    state = state.copyWith(
      contacts: results[Permission.contacts]?.isGranted ?? false,
      camera: results[Permission.camera]?.isGranted ?? false,
      microphone: results[Permission.microphone]?.isGranted ?? false,
      photos: results[Permission.photos]?.isGranted ?? false,
      storage: results[Permission.storage]?.isGranted ?? false,
    );

    return state.allGranted;
  }

  /// Request specific permission
  Future<bool> requestPermission(Permission permission) async {
    final status = await permission.request();
    
    switch (permission) {
      case Permission.contacts:
        state = state.copyWith(contacts: status.isGranted);
        break;
      case Permission.camera:
        state = state.copyWith(camera: status.isGranted);
        break;
      case Permission.microphone:
        state = state.copyWith(microphone: status.isGranted);
        break;
      case Permission.photos:
        state = state.copyWith(photos: status.isGranted);
        break;
      case Permission.storage:
        state = state.copyWith(storage: status.isGranted);
        break;
      default:
        break;
    }

    return status.isGranted;
  }

  /// Check if contacts permission is granted
  Future<bool> hasContactsPermission() async {
    final status = await Permission.contacts.status;
    state = state.copyWith(contacts: status.isGranted);
    return status.isGranted;
  }

  /// Request contacts permission
  Future<bool> requestContactsPermission() async {
    final status = await Permission.contacts.request();
    state = state.copyWith(contacts: status.isGranted);
    return status.isGranted;
  }

  /// Check if camera permission is granted
  Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    state = state.copyWith(camera: status.isGranted);
    return status.isGranted;
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    state = state.copyWith(camera: status.isGranted);
    return status.isGranted;
  }

  /// Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    state = state.copyWith(microphone: status.isGranted);
    return status.isGranted;
  }

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    state = state.copyWith(microphone: status.isGranted);
    return status.isGranted;
  }
}

/// Permission service singleton for direct access
class PermissionService {
  PermissionService._();
  static final instance = PermissionService._();

  /// Request all essential permissions on app startup
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    return await [
      Permission.contacts,
      Permission.camera,
      Permission.microphone,
      Permission.photos,
      Permission.storage,
    ].request();
  }

  /// Check and request contacts permission
  Future<bool> ensureContactsPermission(BuildContext context) async {
    var status = await Permission.contacts.status;
    
    if (status.isDenied) {
      status = await Permission.contacts.request();
    }

    if (status.isPermanentlyDenied && context.mounted) {
      final shouldOpen = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Contacts Permission Required'),
          content: const Text(
            'To send money to your contacts, please enable contacts permission in settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      if (shouldOpen == true) {
        await openAppSettings();
        // Re-check after returning from settings
        status = await Permission.contacts.status;
      }
    }

    return status.isGranted;
  }

  /// Check and request camera permission
  Future<bool> ensureCameraPermission(BuildContext context) async {
    var status = await Permission.camera.status;
    
    if (status.isDenied) {
      status = await Permission.camera.request();
    }

    if (status.isPermanentlyDenied && context.mounted) {
      final shouldOpen = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Camera Permission Required'),
          content: const Text(
            'To scan QR codes and take photos, please enable camera permission in settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      if (shouldOpen == true) {
        await openAppSettings();
        status = await Permission.camera.status;
      }
    }

    return status.isGranted;
  }

  /// Check and request microphone permission
  Future<bool> ensureMicrophonePermission(BuildContext context) async {
    var status = await Permission.microphone.status;
    
    if (status.isDenied) {
      status = await Permission.microphone.request();
    }

    if (status.isPermanentlyDenied && context.mounted) {
      final shouldOpen = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Microphone Permission Required'),
          content: const Text(
            'To use voice commands and AI assistant, please enable microphone permission in settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      if (shouldOpen == true) {
        await openAppSettings();
        status = await Permission.microphone.status;
      }
    }

    return status.isGranted;
  }
}
