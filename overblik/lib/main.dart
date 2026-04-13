import 'package:flutter/material.dart';
import 'package:overblik/screens/daily_calendar_screen.dart';
import 'core/theme/app_theme.dart';
import 'screens/create_activity_screen.dart';
import 'screens/family_screen.dart';
import 'screens/monthly_calendar_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/rewards_screen.dart';
import 'screens/weekly_calendar_screen.dart';

void main() {
  runApp(const OverblikApp());
}

class OverblikApp extends StatelessWidget {
  const OverblikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Overblik',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const DailyCalendarScreen(),
        '/family': (context) => const FamilyScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/weekly': (context) => const WeeklyCalendarScreen(),
        '/monthly': (context) => const MonthlyCalendarScreen(),
        '/rewards': (context) => const RewardsScreen(),
        '/create-activity': (context) => const CreateActivityScreen(),
      },
    );
  }
}