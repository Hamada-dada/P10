import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
import 'screens/daily_calendar_screen.dart';
import 'screens/monthly_calendar_screen.dart';
import 'screens/weekly_calendar_screen.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
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

    final client = Supabase.instance.client;

    if (client.auth.currentSession == null) {
      final response = await client.auth.signInAnonymously();
      debugPrint('Anonymous user id: ${response.user?.id}');
    } else {
      debugPrint(
        'Existing session user id: ${client.auth.currentUser?.id}',
      );
    }

    runApp(const MyApp());
  }, (error, stack) {
    debugPrint('runZonedGuarded error: $error');
    debugPrintStack(stackTrace: stack);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Familiekalender',
      initialRoute: '/',
      routes: {
        '/': (_) => const DailyCalendarScreen(),
        '/weekly': (_) => const WeeklyCalendarScreen(),
        '/monthly': (_) => const MonthlyCalendarScreen(),
      },
    );
  }
}