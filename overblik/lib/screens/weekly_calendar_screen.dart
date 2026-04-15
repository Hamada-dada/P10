import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../screens/daily_calendar_screen.dart';
import '../services/activity_service.dart';
import '../widgets/calendar_navigation_bar.dart';
import '../widgets/view_switcher.dart';

class WeeklyCalendarScreen extends StatefulWidget {
  const WeeklyCalendarScreen({super.key});

  @override
  State<WeeklyCalendarScreen> createState() => _WeeklyCalendarScreenState();
}

class _WeeklyCalendarScreenState extends State<WeeklyCalendarScreen> {
  DateTime _focusedDate = DateTime.now();
  final ActivityService _activityService = ActivityService();

  void _goToPreviousWeek() {
    setState(() {
      _focusedDate = _focusedDate.subtract(const Duration(days: 7));
    });
  }

  void _goToNextWeek() {
    setState(() {
      _focusedDate = _focusedDate.add(const Duration(days: 7));
    });
  }

  void _goToToday() {
    setState(() {
      _focusedDate = DateTime.now();
    });
  }

  void _openDay(DateTime selectedDate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DailyCalendarScreen(initialDate: selectedDate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = _activityService.getWeekDates(_focusedDate);
    final longestActivities =
        _activityService.getLongestActivitiesForWeek(_focusedDate);

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
              const ViewSwitcher(selectedView: CalendarScreenType.week),
              const SizedBox(height: 24),
              CalendarNavigationBar(
                focusedDate: _focusedDate,
                viewType: CalendarViewType.week,
                onPrevious: _goToPreviousWeek,
                onNext: _goToNextWeek,
                onToday: _goToToday,
                onFilterTap: () {},
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: ListView.separated(
                    itemCount: weekDays.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final day = weekDays[index];
                      final activity = longestActivities[index];

                      return _WeekDayCard(
                        date: day,
                        activity: activity,
                        onTap: () => _openDay(day),
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
        IconButton(
          onPressed: () => Navigator.maybePop(context),
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
        'Ugentlig Kalender',
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

class _WeekDayCard extends StatelessWidget {
  final DateTime date;
  final Activity? activity;
  final VoidCallback onTap;

  const _WeekDayCard({
    required this.date,
    required this.activity,
    required this.onTap,
  });

  String _weekdayName(int weekday) {
    const weekdays = [
      'Mandag',
      'Tirsdag',
      'Onsdag',
      'Torsdag',
      'Fredag',
      'Lørdag',
      'Søndag',
    ];
    return weekdays[weekday - 1];
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final hasActivity = activity != null;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasActivity && activity!.isImportant
                ? Colors.red
                : const Color(0xFFA2E5AD),
            width: 2,
          ),
          color: Colors.white,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 95,
              child: Text(
                '${_weekdayName(date.weekday)}\n${date.day}/${date.month}',
                style: const TextStyle(
                  fontFamily: 'Italiana',
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: hasActivity
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_formatTime(activity!.startTime)} - ${_formatTime(activity!.endTime)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${activity!.title} ${activity!.emoji}',
                          style: TextStyle(
                            fontSize: 18,
                            color: activity!.isImportant ? Colors.red : Colors.black,
                            fontWeight: activity!.isImportant
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Ingen aktiviteter',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}