import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/activity.dart';
import '../repositories/supabase_activity_repository.dart';
import '../services/activity_service.dart';
import '../widgets/activity_indicators.dart';
import '../widgets/calendar_navigation_bar.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/view_switcher.dart';
import 'create_activity_screen.dart';
import 'daily_calendar_screen.dart';

class WeeklyCalendarScreen extends StatefulWidget {
  const WeeklyCalendarScreen({super.key});

  @override
  State<WeeklyCalendarScreen> createState() => _WeeklyCalendarScreenState();
}

class _WeeklyCalendarScreenState extends State<WeeklyCalendarScreen> {
  late final ActivityService _activityService = ActivityService(
    SupabaseActivityRepository(Supabase.instance.client),
  );

  DateTime _focusedDate = DateTime.now();
  Map<String, List<Activity>> _activitiesByDate = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeekActivities();
  }

  Future<void> _loadWeekActivities() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final activities = await _activityService.getActivitiesForWeek(_focusedDate);
      final grouped = <String, List<Activity>>{};

      for (final activity in activities) {
        final key = _dateKey(activity.startTime);
        grouped.putIfAbsent(key, () => []);
        grouped[key]!.add(activity);
      }

      for (final entry in grouped.entries) {
        entry.value.sort((a, b) => a.startTime.compareTo(b.startTime));
      }

      if (!mounted) return;

      setState(() {
        _activitiesByDate = grouped;
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('WeeklyCalendarScreen _loadWeekActivities failed: $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;

      setState(() {
        _activitiesByDate = {};
        _isLoading = false;
      });
    }
  }

  Future<void> _goToPreviousWeek() async {
    setState(() {
      _focusedDate = _focusedDate.subtract(const Duration(days: 7));
    });
    await _loadWeekActivities();
  }

  Future<void> _goToNextWeek() async {
    setState(() {
      _focusedDate = _focusedDate.add(const Duration(days: 7));
    });
    await _loadWeekActivities();
  }

  Future<void> _goToToday() async {
    setState(() {
      _focusedDate = DateTime.now();
    });
    await _loadWeekActivities();
  }

  Future<void> _openDay(DateTime selectedDate) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DailyCalendarScreen(initialDate: selectedDate),
      ),
    );

    await _loadWeekActivities();
  }

  Future<void> _openCreateActivityScreen() async {
    try {
      final createdActivity = await Navigator.push<Activity>(
        context,
        MaterialPageRoute(
          builder: (_) => CreateActivityScreen(initialDate: _focusedDate),
        ),
      );

      if (createdActivity != null) {
        await _activityService.addActivity(createdActivity);
        await _loadWeekActivities();
      }
    } catch (e, st) {
      debugPrint('WeeklyCalendarScreen _openCreateActivityScreen failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  List<Activity> _activitiesForDate(DateTime date) {
    return _activitiesByDate[_dateKey(date)] ?? const [];
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

    final sorted = List<Activity>.from(activities)
      ..sort((a, b) => b.duration.compareTo(a.duration));
    return sorted.first;
  }

  String _dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return '${normalized.year}-${normalized.month}-${normalized.day}';
  }

  bool get _hasAnyActivities {
    return _activitiesByDate.values.any((activities) => activities.isNotEmpty);
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
              Expanded(
                child: Container(
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
                      Expanded(
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : !_hasAnyActivities
                                ? const _EmptyWeekView()
                                : ListView.separated(
                                    itemCount: weekDays.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final day = weekDays[index];
                                      final activities = _activitiesForDate(day);
                                      final highlight =
                                          _getWeeklyHighlight(activities);

                                      return _WeekDayCard(
                                        date: day,
                                        activities: activities,
                                        highlightActivity: highlight,
                                        onTap: () => _openDay(day),
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
              width: 84,
              child: Text(
                '${_weekdayName(date.weekday)}\n${date.day}/${date.month}',
                style: const TextStyle(
                  fontFamily: 'Italiana',
                  fontSize: 19,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: !hasActivities
                  ? const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Ingen aktiviteter',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ActivityIndicators(
                          activities: activities,
                          ownerColorBuilder: _ownerColor,
                          maxDots: 3,
                          maxStars: 3,
                          dotSize: 8,
                          starSize: 13,
                          countFontSize: 11,
                          itemSpacing: 4,
                          sectionSpacing: 10,
                        ),
                        if (highlightActivity != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${_formatTime(highlightActivity!.startTime)} - ${_formatTime(highlightActivity!.endTime)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                              height: 1.2,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(width: 6),
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.chevron_right,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyWeekView extends StatelessWidget {
  const _EmptyWeekView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.view_week_outlined,
            size: 40,
            color: Colors.black45,
          ),
          SizedBox(height: 10),
          Text(
            'Ingen aktiviteter i denne uge',
            style: TextStyle(
              fontFamily: 'Italiana',
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}