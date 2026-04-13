import 'package:flutter/material.dart';

class MonthlyCalendarScreen extends StatelessWidget {
  const MonthlyCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Calendar')),
      body: const Center(
        child: Text('Monthly Calendar Screen'),
      ),
    );
  }
}