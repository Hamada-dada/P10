import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'controllers/locale_controller.dart';
import 'controllers/theme_controller.dart';
import 'core/supabase_config.dart';
import 'l10n/app_localizations.dart';
import 'screens/auth_gate.dart';
import 'services/notification_service.dart';

final themeController = ThemeController();
final localeController = LocaleController();

Future<void> main() async {
  runZonedGuarded(
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

      await NotificationService().initialize();

      await themeController.loadTheme();
      await localeController.loadLocale();

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
      animation: Listenable.merge([themeController, localeController]),
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Familiekalender',
          locale: localeController.locale,
          supportedLocales: const [Locale('da'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: themeController.lightTheme,
          darkTheme: themeController.darkTheme,
          themeMode: themeController.themeMode,
          home: const AuthGate(),
        );
      },
    );
  }
}
