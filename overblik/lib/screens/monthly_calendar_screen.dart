import 'package:flutter/material.dart';
import '../widgets/calendar_navigation_bar.dart';
import '../widgets/view_switcher.dart';

class MonthlyCalendarScreen extends StatefulWidget {
  const MonthlyCalendarScreen({super.key});

  @override
  State<MonthlyCalendarScreen> createState() => _MonthlyCalendarScreenState();
}

class _MonthlyCalendarScreenState extends State<MonthlyCalendarScreen> {
  DateTime _focusedDate = DateTime.now();

  void _goToPreviousMonth() {
    setState(() {
      _focusedDate = DateTime(
        _focusedDate.year,
        _focusedDate.month - 1,
        _focusedDate.day,
      );
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedDate = DateTime(
        _focusedDate.year,
        _focusedDate.month + 1,
        _focusedDate.day,
      );
    });
  }

  void _goToToday() {
    setState(() {
      _focusedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA2E5AD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _TopHeader(),
              const SizedBox(height: 12),
              Container(
                height: 6,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              const _ScreenTitle(),
              const SizedBox(height: 16),
              const ViewSwitcher(selectedView: CalendarScreenType.month),
              const SizedBox(height: 24),
              CalendarNavigationBar(
                focusedDate: _focusedDate,
                viewType: CalendarViewType.month,
                onPrevious: _goToPreviousMonth,
                onNext: _goToNextMonth,
                onToday: _goToToday,
                onFilterTap: () {},
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: const Text(
                    'Monthly calendar coming next',
                    style: TextStyle(
                      fontFamily: 'Italiana',
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          icon: const Icon(
            Icons.arrow_back,
            size: 32,
            color: Colors.black,
          ),
        ),
        const Spacer(),
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white,
          child: Icon(
            Icons.person,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

class _ScreenTitle extends StatelessWidget {
  const _ScreenTitle();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Månedlige Kalender',
        style: TextStyle(
          fontFamily: 'Italiana',
          fontSize: 42,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
      ),
    );
  }
}