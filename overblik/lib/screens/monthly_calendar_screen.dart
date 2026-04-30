import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/activity.dart';
import '../repositories/supabase_activity_repository.dart';
import '../services/activity_service.dart';
import '../widgets/calendar_navigation_bar.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/view_switcher.dart';
import 'create_activity_screen.dart';
import 'daily_calendar_screen.dart';
import 'weekly_calendar_screen.dart';
import '../models/profile.dart';
import '../services/profile_service.dart';
import '../widgets/filter_panel.dart';

class MonthlyCalendarScreen extends StatefulWidget {
  final DateTime? initialDate;

  final String? childFamilyId;
  final String? childProfileId;
  final String? childDisplayName;
  final String? childRole;

  const MonthlyCalendarScreen({
    super.key,
    this.initialDate,
    this.childFamilyId,
    this.childProfileId,
    this.childDisplayName,
    this.childRole,
  });

  bool get isChildSession {
    return childFamilyId != null &&
        childProfileId != null &&
        childRole != null;
  }

  bool get isChildLimited {
    return childRole == 'child_limited';
  }

  bool get isChildExtended {
    return childRole == 'child_extended';
  }

  @override
  State<MonthlyCalendarScreen> createState() => _MonthlyCalendarScreenState();
}

class _MonthlyCalendarScreenState extends State<MonthlyCalendarScreen> {
  late final ActivityService _activityService;

  late DateTime _focusedDate;

  Map<String, List<Activity>> _activitiesByDate = {};
bool _isLoading = true;

final ProfileService _profileService = ProfileService();

List<Profile> _filterProfiles = [];
Set<String> _selectedFilterProfileIds = {};
bool _showFamilyActivities = false;

  bool get _isChildSession => widget.isChildSession;

  bool get _hasAuthUser {
    return Supabase.instance.client.auth.currentUser != null;
  }

  bool get _canCreateActivity {
    // Parent creation works.
    // Child creation is intentionally disabled until child_create_activity RPC is implemented.
    return _hasAuthUser && !_isChildSession;
  }

  @override
  void initState() {
    super.initState();

    _focusedDate = widget.initialDate ?? DateTime.now();

    _activityService = ActivityService(
      SupabaseActivityRepository(
        Supabase.instance.client,
        childFamilyId: widget.childFamilyId,
        childProfileId: widget.childProfileId,
        childRole: widget.childRole,
      ),
    );

    debugPrint('MonthlyCalendarScreen: init');
    debugPrint('MonthlyCalendarScreen: hasAuthUser=$_hasAuthUser');
    debugPrint('MonthlyCalendarScreen: isChildSession=$_isChildSession');
    debugPrint('MonthlyCalendarScreen: childFamilyId=${widget.childFamilyId}');
    debugPrint('MonthlyCalendarScreen: childProfileId=${widget.childProfileId}');
    debugPrint('MonthlyCalendarScreen: childRole=${widget.childRole}');

    _loadMonthActivities();
    _loadFilterProfiles();
  }

  Future<void> _loadMonthActivities() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final gridDates = _buildMonthGrid(_focusedDate);

      if (gridDates.isEmpty) {
        if (!mounted) return;

        setState(() {
          _activitiesByDate = {};
          _isLoading = false;
        });

        return;
      }

      final allActivities = <Activity>[];

      DateTime cursor = gridDates.first;
      final end = gridDates.last;

      while (!cursor.isAfter(end)) {
        final weekActivities =
            await _activityService.getActivitiesForWeek(cursor);

        // Do NOT deduplicate only by id here.
        // Recurring activities may share the same database id,
        // but each occurrence has a different start time.
        allActivities.addAll(weekActivities);

        cursor = cursor.add(const Duration(days: 7));
      }

      final grouped = <String, List<Activity>>{};

      for (final activity in allActivities) {
        final key = _dateKey(activity.startTime);

        grouped.putIfAbsent(key, () => []);

        final alreadyAddedForSameDay = grouped[key]!.any((existing) {
          return existing.id == activity.id &&
              existing.startTime.year == activity.startTime.year &&
              existing.startTime.month == activity.startTime.month &&
              existing.startTime.day == activity.startTime.day &&
              existing.startTime.hour == activity.startTime.hour &&
              existing.startTime.minute == activity.startTime.minute;
        });

        if (!alreadyAddedForSameDay) {
          grouped[key]!.add(activity);
        }
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
      debugPrint('MonthlyCalendarScreen _loadMonthActivities failed: $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;

      setState(() {
        _activitiesByDate = {};
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke hente månedsaktiviteter: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
  Future<void> _loadFilterProfiles() async {
  try {
    if (_isChildSession) {
      if (widget.childProfileId == null) return;

      setState(() {
        _selectedFilterProfileIds = {widget.childProfileId!};
        _showFamilyActivities = false;
      });

      return;
    }

    final currentParent = await _profileService.getMyParentProfile();

    if (currentParent == null) return;

    final profiles = await _profileService.getFamilyProfiles(
      currentParent.familyId,
    );

    if (!mounted) return;

    setState(() {
      _filterProfiles = profiles;
      _selectedFilterProfileIds = {currentParent.id};
      _showFamilyActivities = false;
    });
  } catch (e, st) {
    debugPrint('MonthlyCalendarScreen _loadFilterProfiles failed: $e');
    debugPrintStack(stackTrace: st);
  }
}

  Future<void> _goToPreviousMonth() async {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
    });

    await _loadMonthActivities();
  }

  Future<void> _goToNextMonth() async {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
    });

    await _loadMonthActivities();
  }

  Future<void> _goToToday() async {
    setState(() {
      _focusedDate = DateTime.now();
    });

    await _loadMonthActivities();
  }

  Future<void> _openDay(DateTime selectedDate) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DailyCalendarScreen(
          initialDate: selectedDate,
          childFamilyId: widget.childFamilyId,
          childProfileId: widget.childProfileId,
          childDisplayName: widget.childDisplayName,
          childRole: widget.childRole,
        ),
      ),
    );

    await _loadMonthActivities();
  }
  Future<void> _openFilterPanel() async {
  final result = await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    builder: (sheetContext) {
      return FilterPanel(
        profiles: _filterProfiles,
        selectedProfileIds: _selectedFilterProfileIds,
        showFamilyActivities: _showFamilyActivities,
      );
    },
  );

  if (result == null || !mounted) return;

  setState(() {
    _selectedFilterProfileIds = result['profileIds'] as Set<String>;
    _showFamilyActivities = result['showFamily'] as bool;
  });
}
  Future<void> _openCreateActivityScreen() async {
    if (!_canCreateActivity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Oprettelse fra børnelogin kræver næste backend-trin.',
          ),
        ),
      );
      return;
    }

    try {
      final createdActivity = await Navigator.push<Activity>(
        context,
        MaterialPageRoute(
          builder: (_) => CreateActivityScreen(initialDate: _focusedDate),
        ),
      );

      if (createdActivity != null) {
        await _activityService.addActivity(createdActivity);
        await _loadMonthActivities();
      }
    } catch (e, st) {
      debugPrint('MonthlyCalendarScreen _openCreateActivityScreen failed: $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke oprette aktivitet: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _openDayView() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DailyCalendarScreen(
          initialDate: _focusedDate,
          childFamilyId: widget.childFamilyId,
          childProfileId: widget.childProfileId,
          childDisplayName: widget.childDisplayName,
          childRole: widget.childRole,
        ),
      ),
    );
  }

  void _openWeekView() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WeeklyCalendarScreen(
          initialDate: _focusedDate,
          childFamilyId: widget.childFamilyId,
          childProfileId: widget.childProfileId,
          childDisplayName: widget.childDisplayName,
          childRole: widget.childRole,
        ),
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

  List<List<DateTime>> _buildWeekRows(DateTime monthDate) {
    final dates = List<DateTime>.from(_buildMonthGrid(monthDate));

    if (dates.isEmpty) {
      return [];
    }

    while (dates.length % 7 != 0) {
      dates.add(dates.last.add(const Duration(days: 1)));
    }

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

  Color _activityColor(Activity activity) {
    if (activity.isCompleted) {
      return Colors.green;
    }

    if (activity.isImportant) {
      return Colors.red;
    }

    if (activity.isFavorite) {
      return Colors.amber;
    }

    if (activity.ownerProfileId != null) {
      return Colors.blue;
    }

    return Colors.purple;
  }

  String _dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return '${normalized.year}-${normalized.month}-${normalized.day}';
  }

  List<Activity> _filterActivities(List<Activity> activities) {
  if (_selectedFilterProfileIds.isEmpty && !_showFamilyActivities) {
    return activities;
  }

  return activities.where((activity) {
    final matchesProfile = activity.participants.any((participant) {
      return participant.profileId != null &&
          _selectedFilterProfileIds.contains(participant.profileId);
    });

    final matchesFamily = _showFamilyActivities &&
        activity.participants.any(
          (participant) => participant.externalName == 'Familie',
        );

    return matchesProfile || matchesFamily;
  }).toList();
}

List<Activity> _getActivitiesForDate(DateTime date) {
  final activities = _activitiesByDate[_dateKey(date)] ?? const [];
  return _filterActivities(activities);
}

  bool get _hasAnyActivities {
  return _activitiesByDate.values.any(
    (activities) => _filterActivities(activities).isNotEmpty,
  );
}

  @override
  Widget build(BuildContext context) {
    final weekRows = _buildWeekRows(_focusedDate);
    final today = DateTime.now();

    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    final horizontalPadding = isLandscape ? 12.0 : 16.0;
    final verticalPadding = isLandscape ? 6.0 : 10.0;
    final titleFontSize = isLandscape ? 22.0 : 28.0;
    final mediumGap = isLandscape ? 8.0 : 10.0;
    final largeGap = isLandscape ? 10.0 : 12.0;
    final weekNumberWidth = screenWidth < 380 ? 30.0 : 36.0;

    final cellHeight = isLandscape
        ? 58.0
        : screenHeight < 700
            ? 70.0
            : screenHeight < 780
                ? 76.0
                : 82.0;

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
              _TopHeader(
                isChildSession: _isChildSession,
                childDisplayName: widget.childDisplayName,
              ),
              SizedBox(height: mediumGap),
              _ScreenTitle(fontSize: titleFontSize),
              SizedBox(height: mediumGap),
              ViewSwitcher(
                selectedView: CalendarScreenType.month,
                onDayTap: _openDayView,
                onWeekTap: _openWeekView,
              ),
              SizedBox(height: largeGap),
              CalendarNavigationBar(
                focusedDate: _focusedDate,
                viewType: CalendarViewType.month,
                onPrevious: _goToPreviousMonth,
                onNext: _goToNextMonth,
                onToday: _goToToday,
                onFilterTap: _openFilterPanel,
              ),
              SizedBox(height: mediumGap),
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      if (_canCreateActivity)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _openCreateActivityScreen,
                            icon: const Icon(Icons.add),
                            label: const Text('Ny aktivitet'),
                          ),
                        ),
                      if (_canCreateActivity) const SizedBox(height: 12),
                      _WeekdayHeaderRow(weekNumberWidth: weekNumberWidth),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : !_hasAnyActivities
                                ? const _EmptyMonthView()
                                : SingleChildScrollView(
                                    child: Column(
                                      children: weekRows
                                          .map(
                                            (week) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              child: _MonthWeekRow(
                                                week: week,
                                                focusedMonth:
                                                    _focusedDate.month,
                                                today: today,
                                                weekNumber:
                                                    _getWeekNumber(week[0]),
                                                weekNumberWidth:
                                                    weekNumberWidth,
                                                cellHeight: cellHeight,
                                                getActivitiesForDate:
                                                    _getActivitiesForDate,
                                                activityColorBuilder:
                                                    _activityColor,
                                                isSameDate: _isSameDate,
                                                onTapDay: _openDay,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
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
  final bool isChildSession;
  final String? childDisplayName;

  const _TopHeader({
    required this.isChildSession,
    this.childDisplayName,
  });

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
        if (isChildSession)
          Text(
            childDisplayName ?? 'Barn',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          )
        else
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
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: const TextStyle(
                  fontSize: 11,
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
  final Color Function(Activity activity) activityColorBuilder;
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
    required this.activityColorBuilder,
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
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: const TextStyle(
                fontSize: 10,
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
                  activityColorBuilder: activityColorBuilder,
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
  final Color Function(Activity activity) activityColorBuilder;
  final VoidCallback onTap;

  const _MonthDayCell({
    required this.date,
    required this.activities,
    required this.isCurrentMonth,
    required this.isToday,
    required this.cellHeight,
    required this.activityColorBuilder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isCurrentMonth ? Colors.black : Colors.black38;
    final backgroundColor =
        isCurrentMonth ? const Color(0xFFF8F8F8) : const Color(0xFFF1F1F1);
    final borderColor = isToday ? Colors.black : const Color(0xFFE0E0E0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isVerySmallCell = constraints.maxWidth < 44;

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            height: cellHeight,
            padding: EdgeInsets.fromLTRB(
              isVerySmallCell ? 4 : 6,
              6,
              isVerySmallCell ? 4 : 6,
              4,
            ),
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
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontFamily: 'Italiana',
                    fontSize: isVerySmallCell ? 16 : 18,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                if (activities.isNotEmpty)
                  _CompactMonthActivityIndicator(
                    activities: activities,
                    activityColorBuilder: activityColorBuilder,
                    isVerySmallCell: isVerySmallCell,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CompactMonthActivityIndicator extends StatelessWidget {
  final List<Activity> activities;
  final Color Function(Activity activity) activityColorBuilder;
  final bool isVerySmallCell;

  const _CompactMonthActivityIndicator({
    required this.activities,
    required this.activityColorBuilder,
    required this.isVerySmallCell,
  });

  @override
  Widget build(BuildContext context) {
    final visibleActivities = activities.take(isVerySmallCell ? 2 : 3).toList();
    final remainingCount = activities.length - visibleActivities.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...visibleActivities.map(
          (activity) => Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Container(
              width: isVerySmallCell ? 5 : 6,
              height: isVerySmallCell ? 5 : 6,
              decoration: BoxDecoration(
                color: activityColorBuilder(activity),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        if (remainingCount > 0)
          Flexible(
            child: Text(
              '+$remainingCount',
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontSize: isVerySmallCell ? 8 : 9,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyMonthView extends StatelessWidget {
  const _EmptyMonthView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 40,
            color: Colors.black45,
          ),
          SizedBox(height: 10),
          Text(
            'Ingen aktiviteter i denne måned',
            textAlign: TextAlign.center,
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