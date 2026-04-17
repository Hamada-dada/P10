import 'package:flutter/material.dart';

import 'screens/daily_calendar_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Familiekalender',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA2E5AD),
        ),
        useMaterial3: true,
      ),
      home: const DailyCalendarScreen(),
    );
  }
}