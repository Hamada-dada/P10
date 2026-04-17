import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../screens/daily_calendar_screen.dart';
import '../services/activity_service.dart';
import '../widgets/calendar_navigation_bar.dart';
import '../widgets/view_switcher.dart';
import 'create_activity_screen.dart';
import '../widgets/profile_avatar.dart';

class WeeklyCalendarScreen extends StatefulWidget {
  const WeeklyCalendarScreen({super.key});

  @override
  State<WeeklyCalendarScreen> createState() => _WeeklyCalendarScreenState();
}

class _WeeklyCalendarScreenState extends State<WeeklyCalendarScreen> {
  DateTime _focusedDate = DateTime.now();
  final ActivityService _activityService = ActivityService();
  final List<Activity> _createdActivities = [];

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

  Future<void> _openCreateActivityScreen() async {
    final createdActivity = await Navigator.push<Activity>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateActivityScreen(initialDate: _focusedDate),
      ),
    );

    if (createdActivity != null) {
      setState(() {
        _createdActivities.add(createdActivity);
      });
    }
  }

  List<Activity> _activitiesForDate(DateTime date) {
    final serviceActivities = _activityService.getActivitiesForDate(date);

    final createdActivitiesForDate = _createdActivities.where((activity) {
      return activity.startTime.year == date.year &&
          activity.startTime.month == date.month &&
          activity.startTime.day == date.day;
    }).toList();

    final allActivities = [
      ...serviceActivities,
      ...createdActivitiesForDate,
    ];

    allActivities.sort((a, b) => a.startTime.compareTo(b.startTime));
    return allActivities;
  }

  Activity? _getWeeklyHighlight(List<Activity> activities) {
    if (activities.isEmpty) return null;

    final importantActivities =
        activities.where((activity) => activity.isImportant).toList();
    if (importantActivities.isNotEmpty) {
      importantActivities.sort((a, b) => b.duration.compareTo(a.duration));
      return importantActivities.first;
    }

    final favoriteActivities =
        activities.where((activity) => activity.isFavorite).toList();
    if (favoriteActivities.isNotEmpty) {
      favoriteActivities.sort((a, b) => b.duration.compareTo(a.duration));
      return favoriteActivities.first;
    }

    activities.sort((a, b) => b.duration.compareTo(a.duration));
    return activities.first;
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = _activityService.getWeekDates(_focusedDate);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final horizontalPadding = isLandscape ? 12.0 : 16.0;
    final verticalPadding = isLandscape ? 6.0 : 10.0;
    final titleFontSize = isLandscape ? 22.0 : 28.0;
    final smallGap = isLandscape ? 4.0 : 6.0;
    final mediumGap = isLandscape ? 8.0 : 10.0;
    final largeGap = isLandscape ? 10.0 : 12.0;

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
                SizedBox(height: smallGap),
                _ScreenTitle(fontSize: titleFontSize),
                SizedBox(height: mediumGap),
                const ViewSwitcher(selectedView: CalendarScreenType.week),
                SizedBox(height: largeGap),
                CalendarNavigationBar(
                  focusedDate: _focusedDate,
                  viewType: CalendarViewType.week,
                  onPrevious: _goToPreviousWeek,
                  onNext: _goToNextWeek,
                  onToday: _goToToday,
                  onFilterTap: () {},
                ),
                SizedBox(height: mediumGap),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                  decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  ),
                 clipBehavior: Clip.antiAlias,
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
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: weekDays.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final day = weekDays[index];
                          final activities = _activitiesForDate(day);
                          final highlight =
                              _getWeeklyHighlight(List<Activity>.from(activities));

                          return _WeekDayCard(
                            date: day,
                            activities: activities,
                            highlightActivity: highlight,
                            onTap: () => _openDay(day),
                          );
                        },
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
        'Ugekalender',
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

class _WeekDayCard extends StatelessWidget {
  final DateTime date;
  final List<Activity> activities;
  final Activity? highlightActivity;
  final VoidCallback onTap;

  const _WeekDayCard({
    required this.date,
    required this.activities,
    required this.highlightActivity,
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
    final hasActivities = activities.isNotEmpty;
    final visibleActivities = activities.take(3).toList();
    final extraCount = activities.length - visibleActivities.length;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 92,
              child: Text(
                '${_weekdayName(date.weekday)}\n${date.day}/${date.month}',
                style: const TextStyle(
                  fontFamily: 'Italiana',
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: !hasActivities
                  ? const Text(
                      'Ingen aktiviteter',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
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
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (highlightActivity != null) ...[
                          Text(
                            '${_formatTime(highlightActivity!.startTime)} - ${_formatTime(highlightActivity!.endTime)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${highlightActivity!.title} ${highlightActivity!.emoji}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: highlightActivity!.isImportant
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: highlightActivity!.isImportant
                                  ? Colors.red
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ],
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