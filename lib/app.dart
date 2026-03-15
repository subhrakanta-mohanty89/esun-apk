/// ESUN App Root Widget
/// 
/// Configures theme, routing, and app-level providers.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/theme.dart';
import 'routes/app_router.dart';
import 'state/app_state.dart';

class ESUNApp extends ConsumerWidget {
  const ESUNApp({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'ESUN',
      debugShowCheckedModeBanner: false,
      
      // Theme configuration
      theme: ESUNTheme.light,
      darkTheme: ESUNTheme.dark,
      themeMode: themeMode,
      
      // Router configuration
      routerConfig: router,
      
      // Builder for global overlays
      builder: (context, child) {
        return MediaQuery(
          // Prevent text scaling from breaking UI
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}



