import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../models/activity.dart';
import '../models/profile.dart';
import '../repositories/supabase_activity_repository.dart';
import '../services/activity_service.dart';
import '../services/profile_service.dart';
import '../widgets/activity_indicators.dart';
import '../widgets/calendar_navigation_bar.dart';
import '../widgets/content_action_row.dart';
import '../widgets/filter_panel.dart';
import '../main.dart' show themeController;
import '../widgets/profile_avatar.dart';
import '../widgets/view_switcher.dart';
import 'create_activity_screen.dart';
import 'daily_calendar_screen.dart';
import 'login_screen.dart';
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
  bool _isLoggingOut = false;

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

  String? get _headerChildEmoji {
    if (_currentProfile?.isChild == true) {
      return _currentProfile?.emoji;
    }
    return null;
  }

  bool get _showChildHeaderName => _isChildSession;

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

    await _loadFilterProfiles();
    await _loadWeekActivities();
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

        final alreadyAddedForSameTime = grouped[key]!.any((existing) {
          return existing.id == activity.id &&
              existing.startTime.year == activity.startTime.year &&
              existing.startTime.month == activity.startTime.month &&
              existing.startTime.day == activity.startTime.day &&
              existing.startTime.hour == activity.startTime.hour &&
              existing.startTime.minute == activity.startTime.minute;
        });

        if (!alreadyAddedForSameTime) {
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
      debugPrint('WeeklyCalendarScreen _loadWeekActivities failed: $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;

      setState(() {
        _activitiesByDate = {};
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).errorLoadWeekActivities(e)),
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
          _showFamilyActivities = false;
        });

        return;
      }

      final currentProfile =
          _currentProfile ??
          await _profileService.getCurrentAuthenticatedProfile();

      if (currentProfile == null) {
        debugPrint('CalendarScreen: no current profile for filter loading');
        return;
      }

      final profiles = await _profileService.getFamilyProfiles(
        currentProfile.familyId,
      );

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

        // Required default:
        // Parent = own + family/others.
        // Child = own only.
        _selectedFilterProfileIds = {currentProfile.id};
        _showFamilyActivities = currentProfile.isParent;
      });
    } catch (e, st) {
      debugPrint('CalendarScreen _loadFilterProfiles failed: $e');
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

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      await Supabase.instance.client.auth.signOut();
      await themeController.setThemeMode(ThemeMode.light);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (_) {
      if (mounted) setState(() => _isLoggingOut = false);
    }
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
      isScrollControlled: true,
      builder: (sheetContext) {
        return FilterPanel(
          profiles: _filterProfiles,
          selectedProfileIds: _selectedFilterProfileIds,
          showFamilyActivities: _showFamilyActivities,
          isChildView: _isChildSession || _currentProfile?.isChild == true,
          currentProfileId: _currentProfile?.id,
        );
      },
    );

    if (result == null || !mounted) return;

    final rawProfileIds = result['profileIds'];

    setState(() {
      _selectedFilterProfileIds = rawProfileIds is Iterable
          ? Set<String>.from(rawProfileIds)
          : <String>{};

      _showFamilyActivities = result['showFamily'] == true;
    });
  }

  Future<void> _openCreateActivityScreen() async {
    if (!_canCreateActivity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).errorNoAccessCreate),
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
          content: Text(AppLocalizations.of(context).errorSaveActivity(e)),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  List<Activity> _filterActivities(List<Activity> activities) {
    if (_selectedFilterProfileIds.isEmpty && !_showFamilyActivities) {
      return [];
    }

    return activities.where((activity) {
      final matchesParticipant = activity.participants.any((participant) {
        return participant.profileId != null &&
            _selectedFilterProfileIds.contains(participant.profileId);
      });

      final matchesOwner =
          activity.ownerProfileId != null &&
          _selectedFilterProfileIds.contains(activity.ownerProfileId);

      final matchesFamily =
          _showFamilyActivities &&
          (activity.visibility == ActivityVisibility.family ||
              activity.participants.any(
                (participant) => participant.externalName == 'Familie',
              ));

      return matchesParticipant || matchesOwner || matchesFamily;
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    final weekDays = _activityService.getWeekDates(_focusedDate);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      backgroundColor: isDark
          ? const Color(0xFF050706)
          : colorScheme.primaryContainer,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < -300) _goToNextWeek();
          if (details.primaryVelocity! > 300) _goToPreviousWeek();
        },
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopHeader(
                onLogout: _logout,
                isLoggingOut: _isLoggingOut,
                showChildHeaderName: _showChildHeaderName,
                displayName: _headerDisplayName,
                childEmoji: _headerChildEmoji,
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
                    color: isDark
                        ? const Color(0xFF101312)
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2A2D2C)
                          : Colors.transparent,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ContentActionRow(
                        canCreate: _canCreateActivity,
                        onNew: _openCreateActivityScreen,
                        onToday: _goToToday,
                        onFilter: _openFilterPanel,
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
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
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final VoidCallback onLogout;
  final bool isLoggingOut;
  final bool showChildHeaderName;
  final String? displayName;
  final String? childEmoji;

  const _TopHeader({
    required this.onLogout,
    required this.isLoggingOut,
    required this.showChildHeaderName,
    this.displayName,
    this.childEmoji,
  });

  void _showChildSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark ? const Color(0xFF101312) : Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 36,
                backgroundColor: isDark
                    ? colorScheme.primary.withValues(alpha: 0.16)
                    : colorScheme.primaryContainer,
                child: Text(childEmoji ?? '🙂', style: const TextStyle(fontSize: 32)),
              ),
              const SizedBox(height: 12),
              Text(
                displayName ?? AppLocalizations.of(context).child,
                style: TextStyle(
                  fontFamily: 'Italiana',
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    onLogout();
                  },
                  icon: const Icon(Icons.logout, size: 20),
                  label: Text(AppLocalizations.of(context).logout),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(sheetContext).colorScheme.error,
                    side: BorderSide(color: Theme.of(sheetContext).colorScheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (showChildHeaderName)
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: isLoggingOut ? null : () => _showChildSheet(context),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2A2D2C)
                      : colorScheme.primary.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: isDark
                    ? const Color(0xFF171A19)
                    : Colors.white,
                child: isLoggingOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        childEmoji ?? '🙂',
                        style: const TextStyle(fontSize: 20),
                      ),
              ),
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
        AppLocalizations.of(context).weeklyCalendarTitle,
        style: TextStyle(
          fontFamily: 'Italiana',
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
          color: Theme.of(context).colorScheme.onSurface,
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF171A19)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2D2C) : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              child: Text(
                '${AppLocalizations.of(context).weekdayNames[date.weekday - 1]}\n${date.day}/${date.month}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: !hasActivities
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        AppLocalizations.of(context).noActivities,
                        style: TextStyle(
                          fontSize: 15,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
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
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
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
                                  : colorScheme.onSurface,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.chevron_right, color: colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

