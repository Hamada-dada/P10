import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'controllers/theme_controller.dart';
import 'core/supabase_config.dart';
import 'screens/auth_gate.dart';

final themeController = ThemeController();

Future<void> main() async {
  await runZonedGuarded(
        () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('FlutterError: ${details.exception}');
        debugPrintStack(stackTrace: details.stack);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('PlatformDispatcher error: $error');
        debugPrintStack(stackTrace: stack);
        return true;
      };

      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );

      await themeController.loadTheme();

      debugPrint(
        'main.dart: current session user id = '
            '${Supabase.instance.client.auth.currentUser?.id}',
      );

      runApp(const MyApp());
    },
        (error, stack) {
      debugPrint('runZonedGuarded error: $error');
      debugPrintStack(stackTrace: stack);
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Familiekalender',
          theme: themeController.lightTheme,
          darkTheme: themeController.darkTheme,
          themeMode: themeController.themeMode,
          home: const AuthGate(),
        );
      },
    );
  }
}