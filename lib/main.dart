/// ESUN Mobile - Main Entry Point
/// 
/// A production-grade personal finance ecosystem.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/storage/secure_storage.dart';
import 'core/services/permission_service.dart';
import 'core/cache/cache_first_provider.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Open Hive boxes
  await Hive.openBox(HiveBoxes.cache);
  await Hive.openBox(HiveBoxes.preferences);
  await Hive.openBox(HiveBoxes.offlineQueue);
  
  // Initialize cache-first data layer
  await HiveCache.init();
  
  // Request essential permissions (non-blocking)
  _requestPermissions();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Run the app wrapped in ProviderScope for Riverpod
  runApp(
    const ProviderScope(
      child: ESUNApp(),
    ),
  );
}

/// Request essential permissions in background
Future<void> _requestPermissions() async {
  try {
    await PermissionService.instance.requestAllPermissions();
  } catch (e) {
    // Silently fail - permissions will be requested when features are used
    debugPrint('Permission request failed: $e');
  }
}



