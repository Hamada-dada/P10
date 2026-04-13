import 'package:flutter/material.dart';

class WeeklyCalendarScreen extends StatelessWidget {
  const WeeklyCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Calendar')),
      body: const Center(
        child: Text('Weekly Calendar Screen'),
      ),
    );
  }
}