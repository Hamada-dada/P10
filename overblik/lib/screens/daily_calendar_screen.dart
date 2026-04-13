import 'package:flutter/material.dart';
import '../widgets/calendar_navigation_bar.dart';

class DailyCalendarScreen extends StatefulWidget {
  const DailyCalendarScreen({super.key});

  @override
  State<DailyCalendarScreen> createState() => _DailyCalendarScreenState();
}

class _DailyCalendarScreenState extends State<DailyCalendarScreen> {
  DateTime _focusedDate = DateTime.now();

  void _goToPreviousDay() {
    setState(() {
      _focusedDate = _focusedDate.subtract(const Duration(days: 1));
    });
  }

  void _goToNextDay() {
    setState(() {
      _focusedDate = _focusedDate.add(const Duration(days: 1));
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
              Container(height: 6, color: Colors.white),
              const SizedBox(height: 16),
              const _ScreenTitle(),
              const SizedBox(height: 16),
              const _ViewSwitcher(),
              const SizedBox(height: 24),
              CalendarNavigationBar(
                focusedDate: _focusedDate,
                viewType: CalendarViewType.day,
                onPrevious: _goToPreviousDay,
                onNext: _goToNextDay,
                onFilterTap: () {},
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  color: Colors.white,
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
        const Icon(Icons.arrow_back, size: 32, color: Colors.black),
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
        'Kalender',
        style: TextStyle(
          fontFamily: 'Italiana',
          fontSize: 48,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _ViewSwitcher extends StatelessWidget {
  const _ViewSwitcher();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(118, 118, 128, 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: const [
          _SegmentButton(label: 'Dag', selected: true),
          _SegmentButton(label: 'Uge'),
          _SegmentButton(label: 'Måned'),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;

  const _SegmentButton({
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: selected
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}