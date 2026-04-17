import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../screens/daily_calendar_screen.dart';
import '../services/activity_service.dart';
import '../widgets/calendar_navigation_bar.dart';
import '../widgets/view_switcher.dart';
import 'create_activity_screen.dart';
import '../widgets/profile_avatar.dart';

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

  Future<void> _openDay(DateTime selectedDate) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DailyCalendarScreen(initialDate: selectedDate),
      ),
    );

    setState(() {});
  }

  Future<void> _openCreateActivityScreen() async {
    final createdActivity = await Navigator.push<Activity>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateActivityScreen(initialDate: _focusedDate),
      ),
    );

    if (createdActivity != null) {
      _activityService.addActivity(createdActivity);
      setState(() {});
    }
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

  List<List<DateTime>> _buildWeekRows(DateTime monthDate) {
    final dates = _buildMonthGrid(monthDate);
    final rows = <List<DateTime>>[];

    for (int i = 0; i < dates.length; i += 7) {
      rows.add(dates.sublist(i, i + 7));
    }

    return rows;
  }

  int _getWeekNumber(DateTime date) {
    final thursday =
        date.add(Duration(days: 4 - (date.weekday == 7 ? 7 : date.weekday)));
    final firstJanuary = DateTime(thursday.year, 1, 1);
    final days = thursday.difference(firstJanuary).inDays;
    return ((days + firstJanuary.weekday - 1) / 7).floor() + 1;
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

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
    final weekRows = _buildWeekRows(_focusedDate);
    final today = DateTime.now();
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final horizontalPadding = isLandscape ? 12.0 : 16.0;
    final verticalPadding = isLandscape ? 6.0 : 10.0;
    final titleFontSize = isLandscape ? 22.0 : 28.0;
    final mediumGap = isLandscape ? 8.0 : 10.0;
    final largeGap = isLandscape ? 10.0 : 12.0;
    final weekNumberWidth = isLandscape ? 34.0 : 38.0;
    final cellHeight = isLandscape ? 58.0 : 72.0;

    return Scaffold(
      backgroundColor: const Color(0xFFA2E5AD),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _TopHeader(),
                SizedBox(height: mediumGap),
                _ScreenTitle(fontSize: titleFontSize),
                SizedBox(height: mediumGap),
                const ViewSwitcher(selectedView: CalendarScreenType.month),
                SizedBox(height: largeGap),
                CalendarNavigationBar(
                  focusedDate: _focusedDate,
                  viewType: CalendarViewType.month,
                  onPrevious: _goToPreviousMonth,
                  onNext: _goToNextMonth,
                  onToday: _goToToday,
                  onFilterTap: () {},
                ),
                SizedBox(height: mediumGap),
                Container(
                  clipBehavior: Clip.antiAlias,
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openCreateActivityScreen,
                          icon: const Icon(Icons.add),
                          label: const Text('Ny aktivitet'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _WeekdayHeaderRow(weekNumberWidth: weekNumberWidth),
                      const SizedBox(height: 8),
                      ...weekRows.map(
                        (week) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _MonthWeekRow(
                            week: week,
                            focusedMonth: _focusedDate.month,
                            today: today,
                            weekNumber: _getWeekNumber(week[0]),
                            weekNumberWidth: weekNumberWidth,
                            cellHeight: cellHeight,
                            getActivitiesForDate:
                                _activityService.getActivitiesForDate,
                            ownerColorBuilder: _ownerColor,
                            isSameDate: _isSameDate,
                            onTapDay: _openDay,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(
            Icons.arrow_back,
            size: 30,
            color: Colors.black,
          ),
        ),
        const Spacer(),
        const ProfileAvatarButton(),
      ],
    );
  }
}

class _ScreenTitle extends StatelessWidget {
  final double fontSize;

  const _ScreenTitle({
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Månedskalender',
        style: TextStyle(
          fontFamily: 'Italiana',
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _WeekdayHeaderRow extends StatelessWidget {
  final double weekNumberWidth;

  const _WeekdayHeaderRow({
    required this.weekNumberWidth,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['Man', 'Tir', 'Ons', 'Tor', 'Fre', 'Lør', 'Søn'];

    return Row(
      children: [
        SizedBox(width: weekNumberWidth),
        ...labels.map(
          (label) => Expanded(
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthWeekRow extends StatelessWidget {
  final List<DateTime> week;
  final int focusedMonth;
  final DateTime today;
  final int weekNumber;
  final double weekNumberWidth;
  final double cellHeight;
  final List<Activity> Function(DateTime) getActivitiesForDate;
  final Color Function(ActivityOwner) ownerColorBuilder;
  final bool Function(DateTime, DateTime) isSameDate;
  final ValueChanged<DateTime> onTapDay;

  const _MonthWeekRow({
    required this.week,
    required this.focusedMonth,
    required this.today,
    required this.weekNumber,
    required this.weekNumberWidth,
    required this.cellHeight,
    required this.getActivitiesForDate,
    required this.ownerColorBuilder,
    required this.isSameDate,
    required this.onTapDay,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: weekNumberWidth,
          child: Center(
            child: Text(
              '$weekNumber',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
        ),
        ...week.map(
          (date) {
            final activities = getActivitiesForDate(date);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _MonthDayCell(
                  date: date,
                  activities: activities,
                  isCurrentMonth: date.month == focusedMonth,
                  isToday: isSameDate(date, today),
                  cellHeight: cellHeight,
                  ownerColorBuilder: ownerColorBuilder,
                  onTap: () => onTapDay(date),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  final DateTime date;
  final List<Activity> activities;
  final bool isCurrentMonth;
  final bool isToday;
  final double cellHeight;
  final Color Function(ActivityOwner) ownerColorBuilder;
  final VoidCallback onTap;

  const _MonthDayCell({
    required this.date,
    required this.activities,
    required this.isCurrentMonth,
    required this.isToday,
    required this.cellHeight,
    required this.ownerColorBuilder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isCurrentMonth ? Colors.black : Colors.black38;
    final backgroundColor =
        isCurrentMonth ? const Color(0xFFF8F8F8) : const Color(0xFFF1F1F1);
    final borderColor = isToday ? Colors.black : const Color(0xFFE0E0E0);

    final hasActivities = activities.isNotEmpty;
    final firstActivity = hasActivities ? activities.first : null;
    final extraCount = hasActivities ? activities.length - 1 : 0;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: cellHeight,
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isToday ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontFamily: 'Italiana',
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: textColor,
              ),
            ),
            const Spacer(),
            if (firstActivity != null)
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: ownerColorBuilder(firstActivity.owner),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (extraCount > 0) ...[
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '+$extraCount',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isCurrentMonth
                              ? Colors.black87
                              : Colors.black38,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}