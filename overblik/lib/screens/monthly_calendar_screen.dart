import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../screens/daily_calendar_screen.dart';
import '../services/activity_service.dart';
import '../widgets/calendar_navigation_bar.dart';
import '../widgets/view_switcher.dart';

class MonthlyCalendarScreen extends StatefulWidget {
  const MonthlyCalendarScreen({super.key});

  @override
  State<MonthlyCalendarScreen> createState() => _MonthlyCalendarScreenState();
}

class _MonthlyCalendarScreenState extends State<MonthlyCalendarScreen> {
  DateTime _focusedDate = DateTime.now();
  final ActivityService _activityService = ActivityService();

  void _goToPreviousMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
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

  List<DateTime> _buildMonthGrid(DateTime monthDate) {
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final lastDayOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);

    final startOffset = firstDayOfMonth.weekday - 1;
    final gridStartDate = firstDayOfMonth.subtract(Duration(days: startOffset));

    final endOffset = 7 - lastDayOfMonth.weekday;
    final gridEndDate = lastDayOfMonth.add(Duration(days: endOffset));

    final totalDays = gridEndDate.difference(gridStartDate).inDays + 1;

    return List.generate(
      totalDays,
      (index) => gridStartDate.add(Duration(days: index)),
    );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final monthGridDates = _buildMonthGrid(_focusedDate);
    final today = DateTime.now();

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
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const _WeekdayHeaderRow(),
                      const SizedBox(height: 8),
                      Expanded(
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: monthGridDates.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.82,
                          ),
                          itemBuilder: (context, index) {
                            final date = monthGridDates[index];
                            final activities =
                                _activityService.getActivitiesForDate(date);
                            final isCurrentMonth =
                                date.month == _focusedDate.month;
                            final isToday = _isSameDate(date, today);

                            return _MonthDayCell(
                              date: date,
                              activities: activities,
                              isCurrentMonth: isCurrentMonth,
                              isToday: isToday,
                              onTap: () => _openDay(date),
                            );
                          },
                        ),
                      ),
                    ],
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
        'Månedlig Kalender',
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

class _WeekdayHeaderRow extends StatelessWidget {
  const _WeekdayHeaderRow();

  @override
  Widget build(BuildContext context) {
    const labels = ['Man', 'Tir', 'Ons', 'Tor', 'Fre', 'Lør', 'Søn'];

    return Row(
      children: labels
          .map(
            (label) => Expanded(
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  final DateTime date;
  final List<Activity> activities;
  final bool isCurrentMonth;
  final bool isToday;
  final VoidCallback onTap;

  const _MonthDayCell({
    required this.date,
    required this.activities,
    required this.isCurrentMonth,
    required this.isToday,
    required this.onTap,
  });

  Color _ownerColor(ActivityOwner owner) {
    switch (owner) {
      case ActivityOwner.me:
        return Colors.blue;
      case ActivityOwner.mother:
        return Colors.pink;
      case ActivityOwner.father:
        return Colors.orange;
      case ActivityOwner.family:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isCurrentMonth ? Colors.black : Colors.black38;
    final borderColor = isToday ? Colors.black : const Color(0xFFA2E5AD);

    final visibleActivities = activities.take(3).toList();
    final extraCount = activities.length - visibleActivities.length;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: borderColor,
            width: isToday ? 2.5 : 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontFamily: 'Italiana',
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            if (visibleActivities.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  ...visibleActivities.map(
                    (activity) => Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _ownerColor(activity.owner),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  if (extraCount > 0)
                    Text(
                      '+$extraCount',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isCurrentMonth ? Colors.black87 : Colors.black38,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}