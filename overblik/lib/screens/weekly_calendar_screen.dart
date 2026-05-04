import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/activity_filter.dart';
import '../models/activity.dart';
import '../models/profile.dart';
import '../repositories/supabase_activity_repository.dart';
import '../services/activity_service.dart';
import '../services/profile_service.dart';
import '../widgets/activity_indicators.dart';
import '../widgets/calendar_navigation_bar.dart';
import '../widgets/filter_panel.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/view_switcher.dart';
import 'create_activity_screen.dart';
import 'daily_calendar_screen.dart';
import 'monthly_calendar_screen.dart';

class WeeklyCalendarScreen extends StatefulWidget {
  final DateTime? initialDate;

  final Set<String>? initialSelectedFilterProfileIds;
  final bool? initialShowFamilyActivities;

  // Legacy child session fields.
  // Keep these temporarily until the old fake child-session flow is removed.
  final String? childFamilyId;
  final String? childProfileId;
  final String? childDisplayName;
  final String? childRole;
  final String? childLoginCode;

  const WeeklyCalendarScreen({
    super.key,
    this.initialDate,
    this.initialSelectedFilterProfileIds,
    this.initialShowFamilyActivities,
    this.childFamilyId,
    this.childProfileId,
    this.childDisplayName,
    this.childRole,
    this.childLoginCode,
  });

  bool get isChildSession {
    return childFamilyId != null &&
        childProfileId != null &&
        childRole != null &&
        childLoginCode != null;
  }

  bool get isChildLimited {
    return childRole == 'child_limited';
  }

  bool get isChildExtended {
    return childRole == 'child_extended';
  }

  @override
  State<WeeklyCalendarScreen> createState() => _WeeklyCalendarScreenState();
}

class _WeeklyCalendarScreenState extends State<WeeklyCalendarScreen> {
  late final ActivityService _activityService;
  final ProfileService _profileService = ProfileService();

  late DateTime _focusedDate;

  Profile? _currentProfile;

  Map<String, List<Activity>> _activitiesByDate = {};
  List<Profile> _filterProfiles = [];
  Set<String> _selectedFilterProfileIds = {};
  bool _showFamilyActivities = false;

  bool _isLoading = true;

  bool get _isChildSession => widget.isChildSession;

  bool get _hasAuthUser {
    return Supabase.instance.client.auth.currentUser != null;
  }

  bool get _hasInitialFilterState {
    return widget.initialSelectedFilterProfileIds != null ||
        widget.initialShowFamilyActivities != null;
  }

  bool get _canUseScreen {
    return _hasAuthUser || _isChildSession;
  }

  bool get _canCreateActivity {
    if (_isChildSession) {
      return widget.isChildExtended;
    }

    if (!_hasAuthUser) return false;

    final profile = _currentProfile;
    if (profile == null) return false;

    return profile.isParent || profile.isChildExtended;
  }

  String? get _headerDisplayName {
    if (_isChildSession) {
      return widget.childDisplayName;
    }

    if (_currentProfile?.isChild == true) {
      return _currentProfile?.displayName;
    }

    return null;
  }

  bool get _showChildHeaderName {
    return _isChildSession || _currentProfile?.isChild == true;
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
        childLoginCode: widget.childLoginCode,
      ),
    );

    debugPrint('WeeklyCalendarScreen: init');
    debugPrint('WeeklyCalendarScreen: hasAuthUser=$_hasAuthUser');
    debugPrint('WeeklyCalendarScreen: isChildSession=$_isChildSession');
    debugPrint('WeeklyCalendarScreen: childFamilyId=${widget.childFamilyId}');
    debugPrint('WeeklyCalendarScreen: childProfileId=${widget.childProfileId}');
    debugPrint('WeeklyCalendarScreen: childRole=${widget.childRole}');
    debugPrint('WeeklyCalendarScreen: childLoginCode=${widget.childLoginCode}');
    debugPrint(
      'WeeklyCalendarScreen: initialSelectedFilterProfileIds=${widget.initialSelectedFilterProfileIds}',
    );
    debugPrint(
      'WeeklyCalendarScreen: initialShowFamilyActivities=${widget.initialShowFamilyActivities}',
    );

    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    if (!_canUseScreen) {
      debugPrint(
        'WeeklyCalendarScreen: no auth user and no child session, skipping activity load',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      return;
    }

    if (_hasAuthUser) {
      final currentProfile = await _profileService
          .getCurrentAuthenticatedProfile();

      if (!mounted) return;

      setState(() {
        _currentProfile = currentProfile;
      });

      debugPrint(
        'WeeklyCalendarScreen: current profile id=${currentProfile?.id} role=${currentProfile?.role}',
      );
    }

    await _loadWeekActivities();
    await _loadFilterProfiles();
  }

  Future<void> _loadWeekActivities() async {
    if (!_canUseScreen) {
      if (!mounted) return;

      setState(() {
        _activitiesByDate = {};
        _isLoading = false;
      });

      return;
    }

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final activities = await _activityService.getActivitiesForWeek(
        _focusedDate,
      );

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke hente ugeaktiviteter: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _loadFilterProfiles() async {
    try {
      if (_isChildSession) {
        if (widget.childProfileId == null) return;

        if (!mounted) return;

        setState(() {
          _filterProfiles = [];

          if (_hasInitialFilterState) {
            _selectedFilterProfileIds = Set<String>.from(
              widget.initialSelectedFilterProfileIds ?? const {},
            );
            _showFamilyActivities = widget.initialShowFamilyActivities ?? false;
            return;
          }

          _selectedFilterProfileIds = {widget.childProfileId!};
          _showFamilyActivities = true;
        });

        return;
      }

      final currentProfile =
          _currentProfile ??
          await _profileService.getCurrentAuthenticatedProfile();

      if (currentProfile == null) {
        debugPrint(
          'WeeklyCalendarScreen: no current profile for filter loading',
        );
        return;
      }

      final profiles = currentProfile.isParent
          ? await _profileService.getFamilyProfiles(currentProfile.familyId)
          : currentProfile.isChild
          ? <Profile>[currentProfile]
          : await _profileService.getFamilyProfilesForCurrentUser();

      if (!mounted) return;

      setState(() {
        _currentProfile = currentProfile;
        _filterProfiles = profiles;

        if (_hasInitialFilterState) {
          _selectedFilterProfileIds = Set<String>.from(
            widget.initialSelectedFilterProfileIds ?? const {},
          );
          _showFamilyActivities = widget.initialShowFamilyActivities ?? false;
          return;
        }

        if (currentProfile.isParent) {
          _selectedFilterProfileIds = profiles
              .map((profile) => profile.id)
              .toSet();
          _showFamilyActivities = true;
        } else {
          _selectedFilterProfileIds = {currentProfile.id};
          _showFamilyActivities = true;
        }
      });
    } catch (e, st) {
      debugPrint('WeeklyCalendarScreen _loadFilterProfiles failed: $e');
      debugPrintStack(stackTrace: st);
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
        builder: (_) => DailyCalendarScreen(
          initialDate: selectedDate,
          initialSelectedFilterProfileIds: Set<String>.from(
            _selectedFilterProfileIds,
          ),
          initialShowFamilyActivities: _showFamilyActivities,
          childFamilyId: widget.childFamilyId,
          childProfileId: widget.childProfileId,
          childDisplayName: widget.childDisplayName,
          childRole: widget.childRole,
          childLoginCode: widget.childLoginCode,
        ),
      ),
    );

    await _loadWeekActivities();
  }

  void _openDayView() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DailyCalendarScreen(
          initialDate: _focusedDate,
          initialSelectedFilterProfileIds: Set<String>.from(
            _selectedFilterProfileIds,
          ),
          initialShowFamilyActivities: _showFamilyActivities,
          childFamilyId: widget.childFamilyId,
          childProfileId: widget.childProfileId,
          childDisplayName: widget.childDisplayName,
          childRole: widget.childRole,
          childLoginCode: widget.childLoginCode,
        ),
      ),
    );
  }

  void _openMonthView() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MonthlyCalendarScreen(
          initialDate: _focusedDate,
          initialSelectedFilterProfileIds: Set<String>.from(
            _selectedFilterProfileIds,
          ),
          initialShowFamilyActivities: _showFamilyActivities,
          childFamilyId: widget.childFamilyId,
          childProfileId: widget.childProfileId,
          childDisplayName: widget.childDisplayName,
          childRole: widget.childRole,
          childLoginCode: widget.childLoginCode,
        ),
      ),
    );
  }

  Future<void> _openFilterPanel() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (sheetContext) {
        return FilterPanel(
          profiles: _filterProfiles,
          selectedProfileIds: _selectedFilterProfileIds,
          showFamilyActivities: _showFamilyActivities,
          isChildView: _isChildSession || _currentProfile?.isChild == true,
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
          content: Text('Du har ikke adgang til at oprette aktiviteter.'),
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

      if (createdActivity == null) {
        return;
      }

      await _activityService.addActivity(createdActivity);
      await _loadWeekActivities();
    } catch (e, st) {
      debugPrint('WeeklyCalendarScreen _openCreateActivityScreen failed: $e');
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

  List<Activity> _filterActivities(List<Activity> activities) {
    return filterActivities(
      activities: activities,
      selectedProfileIds: _selectedFilterProfileIds,
      showFamilyActivities: _showFamilyActivities,
    );
  }

  List<Activity> _activitiesForDate(DateTime date) {
    final activities = _activitiesByDate[_dateKey(date)] ?? const [];
    return _filterActivities(activities);
  }

  Activity? _getWeeklyHighlight(List<Activity> activities) {
    if (activities.isEmpty) return null;

    final importantActivities = activities
        .where((activity) => activity.isImportant)
        .toList();

    if (importantActivities.isNotEmpty) {
      importantActivities.sort((a, b) => b.duration.compareTo(a.duration));
      return importantActivities.first;
    }

    final favoriteActivities = activities
        .where((activity) => activity.isFavorite)
        .toList();

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
    return _activitiesByDate.values.any(
      (activities) => _filterActivities(activities).isNotEmpty,
    );
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

    debugPrint(
      'WeeklyCalendarScreen: days=${_activitiesByDate.length}, profiles=${_filterProfiles.length}, selected=$_selectedFilterProfileIds, showFamily=$_showFamilyActivities',
    );

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
                showChildHeaderName: _showChildHeaderName,
                displayName: _headerDisplayName,
              ),
              SizedBox(height: smallGap),
              _ScreenTitle(fontSize: titleFontSize),
              SizedBox(height: mediumGap),
              ViewSwitcher(
                selectedView: CalendarScreenType.week,
                onDayTap: _openDayView,
                onMonthTap: _openMonthView,
              ),
              SizedBox(height: largeGap),
              CalendarNavigationBar(
                focusedDate: _focusedDate,
                viewType: CalendarViewType.week,
                onPrevious: _goToPreviousWeek,
                onNext: _goToNextWeek,
                onToday: _goToToday,
                onFilterTap: _openFilterPanel,
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
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : !_hasAnyActivities
                            ? const _EmptyWeekView()
                            : ListView.separated(
                                itemCount: weekDays.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final day = weekDays[index];
                                  final activities = _activitiesForDate(day);
                                  final highlight = _getWeeklyHighlight(
                                    activities,
                                  );

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
  final bool showChildHeaderName;
  final String? displayName;

  const _TopHeader({required this.showChildHeaderName, this.displayName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back, size: 30, color: Colors.black),
        ),
        const Spacer(),
        if (showChildHeaderName)
          Text(
            displayName ?? 'Barn',
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

  const _ScreenTitle({required this.fontSize});

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

    if (activity.visibility == ActivityVisibility.family) {
      return Colors.purple;
    }

    if (activity.ownerProfileId != null) {
      return Colors.blue;
    }

    return Colors.grey;
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
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
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
                        style: TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ActivityIndicators(
                          activities: activities,
                          activityColorBuilder: _activityColor,
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
              child: Icon(Icons.chevron_right, color: Colors.black),
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
          Icon(Icons.view_week_outlined, size: 40, color: Colors.black45),
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
