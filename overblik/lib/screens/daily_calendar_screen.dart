import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../widgets/activity_card.dart';
import '../widgets/calendar_navigation_bar.dart';

class DailyCalendarScreen extends StatefulWidget {
  const DailyCalendarScreen({super.key});

  @override
  State<DailyCalendarScreen> createState() => _DailyCalendarScreenState();
}

class _DailyCalendarScreenState extends State<DailyCalendarScreen> {
  DateTime _focusedDate = DateTime.now();

  late final List<Activity> _activities = [
    Activity(
      id: '1',
      title: 'Morgenmad',
      emoji: '🍳',
      startTime: DateTime(
        _focusedDate.year,
        _focusedDate.month,
        _focusedDate.day,
        7,
        0,
      ),
      endTime: DateTime(
        _focusedDate.year,
        _focusedDate.month,
        _focusedDate.day,
        7,
        15,
      ),
    ),
    Activity(
      id: '2',
      title: 'Skole',
      emoji: '🏫',
      startTime: DateTime(
        _focusedDate.year,
        _focusedDate.month,
        _focusedDate.day,
        8,
        0,
      ),
      endTime: DateTime(
        _focusedDate.year,
        _focusedDate.month,
        _focusedDate.day,
        15,
        30,
      ),
    ),
    Activity(
      id: '3',
      title: 'Aftale med Peter',
      emoji: '🎮',
      startTime: DateTime(
        _focusedDate.year,
        _focusedDate.month,
        _focusedDate.day,
        16,
        0,
      ),
      endTime: DateTime(
        _focusedDate.year,
        _focusedDate.month,
        _focusedDate.day,
        17,
        30,
      ),
      isImportant: true,
    ),
    Activity(
      id: '4',
      title: 'Takeout',
      emoji: '😋',
      startTime: DateTime(
        _focusedDate.year,
        _focusedDate.month,
        _focusedDate.day,
        18,
        0,
      ),
      endTime: DateTime(
        _focusedDate.year,
        _focusedDate.month,
        _focusedDate.day,
        18,
        45,
      ),
    ),
    Activity(
      id: '5',
      title: 'Lektier',
      emoji: '📘',
      startTime: DateTime(
        _focusedDate.year,
        _focusedDate.month,
        _focusedDate.day,
        20,
        0,
      ),
      endTime: DateTime(
        _focusedDate.year,
        _focusedDate.month,
        _focusedDate.day,
        21,
        0,
      ),
    ),
  ];

  List<Activity> get _activitiesForFocusedDate {
    return _activities.where((activity) {
      return activity.startTime.year == _focusedDate.year &&
          activity.startTime.month == _focusedDate.month &&
          activity.startTime.day == _focusedDate.day;
    }).toList();
  }

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

  void _goToToday() {
    setState(() {
      _focusedDate = DateTime.now();
    });
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final activities = _activitiesForFocusedDate;

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
                onToday: _goToToday,
                onFilterTap: () {},
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: activities.isEmpty
                      ? const Center(
                          child: Text(
                            'Ingen aktiviteter',
                            style: TextStyle(
                              fontFamily: 'Italiana',
                              fontSize: 24,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: activities.length,
                          itemBuilder: (context, index) {
                            final activity = activities[index];

                            return ActivityCard(
                              activity: activity,
                              onTap: () {},
                            );
                          },
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