import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/activity_filter.dart';
import '../models/activity.dart';
import '../models/profile.dart';
import '../repositories/supabase_activity_repository.dart';
import '../services/activity_service.dart';
import '../services/profile_service.dart';
import '../widgets/activity_card.dart';
import '../widgets/activity_indicators.dart';
import '../widgets/calendar_navigation_bar.dart';
import '../widgets/filter_panel.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/view_switcher.dart';
import 'activity_detail_screen.dart';
import 'create_activity_screen.dart';
import 'login_screen.dart';
import 'monthly_calendar_screen.dart';
import 'weekly_calendar_screen.dart';

class DailyCalendarScreen extends StatefulWidget {
  final DateTime? initialDate;

  final Set<String>? initialSelectedFilterProfileIds;
  final bool? initialShowFamilyActivities;

  final String? childFamilyId;
  final String? childProfileId;
  final String? childDisplayName;
  final String? childRole;
  final String? childLoginCode;

  const DailyCalendarScreen({
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
    return childFamilyId != null && childProfileId != null && childRole != null;
  }

  bool get isChildLimited {
    return childRole == 'child_limited';
  }

  bool get isChildExtended {
    return childRole == 'child_extended';
  }

  @override
  State<DailyCalendarScreen> createState() => _DailyCalendarScreenState();
}

class _DailyCalendarScreenState extends State<DailyCalendarScreen>
    with WidgetsBindingObserver {
  late final ActivityService _activityService = ActivityService(
    SupabaseActivityRepository(
      Supabase.instance.client,
      childFamilyId: widget.childFamilyId,
      childProfileId: widget.childProfileId,
      childRole: widget.childRole,
      childLoginCode: widget.childLoginCode,
    ),
  );

  final ProfileService _profileService = ProfileService();

  late DateTime _focusedDate;

  Profile? _currentProfile;

  List<Activity> _activities = [];
  List<Profile> _filterProfiles = [];
  Set<String> _selectedFilterProfileIds = {};
  bool _showFamilyActivities = false;

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isLoggingOut = false;

  SupabaseClient get _supabase => Supabase.instance.client;

  bool get _hasAuthUser => _supabase.auth.currentUser != null;

  bool get _isChildSession => widget.isChildSession;

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

  bool get _canOpenActivityDetail {
    return _hasAuthUser || _isChildSession;
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

    WidgetsBinding.instance.addObserver(this);

    _focusedDate = widget.initialDate ?? DateTime.now();

    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    if (!_canUseScreen) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      return;
    }

    if (_hasAuthUser) {
      final currentProfile =
      await _profileService.getCurrentAuthenticatedProfile();

      if (!mounted) return;

      setState(() {
        _currentProfile = currentProfile;
      });
    }

    await _loadActivities(showFullLoader: true);
    await _loadFilterProfiles();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_isLoggingOut) return;
    if (!_canUseScreen) return;

    _loadActivities(showFullLoader: false);
  }

  Future<void> _loadActivities({bool showFullLoader = true}) async {
    if (_isRefreshing) return;

    if (!_canUseScreen) {
      if (!mounted) return;

      setState(() {
        _activities = [];
        _isLoading = false;
      });

      return;
    }

    try {
      _isRefreshing = true;

      if (showFullLoader && mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final activities = await _activityService.getActivitiesForDate(
        _focusedDate,
      );

      if (!mounted) return;

      setState(() {
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke hente aktiviteter: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      _isRefreshing = false;
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
          _currentProfile ?? await _profileService.getCurrentAuthenticatedProfile();

      if (currentProfile == null) return;

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

        _selectedFilterProfileIds = {currentProfile.id};
        _showFamilyActivities = currentProfile.isParent;
      });
    } catch (_) {}
  }

  List<Activity> get _filteredActivities {
    return filterActivities(
      activities: _activities,
      selectedProfileIds: _selectedFilterProfileIds,
      showFamilyActivities: _showFamilyActivities,
    );
  }

  Future<void> _goToPreviousDay() async {
    setState(() {
      _focusedDate = _focusedDate.subtract(const Duration(days: 1));
    });

    await _loadActivities();
  }

  Future<void> _goToNextDay() async {
    setState(() {
      _focusedDate = _focusedDate.add(const Duration(days: 1));
    });

    await _loadActivities();
  }

  Future<void> _goToToday() async {
    setState(() {
      _focusedDate = DateTime.now();
    });

    await _loadActivities();
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

      if (createdActivity == null) return;

      await _activityService.addActivity(createdActivity);
      await _loadActivities(showFullLoader: false);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Aktivitet gemt')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke gemme aktivitet: $e'),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Future<void> _openActivityDetail(Activity activity) async {
    if (!_canOpenActivityDetail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Du er ikke logget ind. Log ind igen.')),
      );
      return;
    }

    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityDetailScreen(
          activity: activity,
          childFamilyId: widget.childFamilyId,
          childProfileId: widget.childProfileId,
          childDisplayName: widget.childDisplayName,
          childRole: widget.childRole,
          childLoginCode: widget.childLoginCode,
        ),
      ),
    );

    if (result == true) {
      await _loadActivities(showFullLoader: false);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Aktivitet opdateret')));
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log ud'),
          content: const Text('Er du sikker på, at du vil logge ud?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuller'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Log ud'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    try {
      setState(() {
        _isLoggingOut = true;
      });

      if (_hasAuthUser) {
        await _supabase.auth.signOut();
      }

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke logge ud: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _openWeekView() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WeeklyCalendarScreen(
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

  @override
  Widget build(BuildContext context) {
    final activities = _filteredActivities;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF050706) : colorScheme.primaryContainer,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopHeader(
                onLogout: _logout,
                isLoggingOut: _isLoggingOut,
                displayName: _headerDisplayName,
                showChildHeaderName: _showChildHeaderName,
              ),
              const SizedBox(height: 8),
              const _ScreenTitle(),
              const SizedBox(height: 12),
              ViewSwitcher(
                selectedView: CalendarScreenType.day,
                onWeekTap: _openWeekView,
                onMonthTap: _openMonthView,
              ),
              const SizedBox(height: 12),
              CalendarNavigationBar(
                focusedDate: _focusedDate,
                viewType: CalendarViewType.day,
                onPrevious: _goToPreviousDay,
                onNext: _goToNextDay,
                onToday: _goToToday,
                onFilterTap: _openFilterPanel,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF101312) : colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2A2D2C) : Colors.transparent,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      if (_canCreateActivity)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                            _isLoggingOut ? null : _openCreateActivityScreen,
                            icon: const Icon(Icons.add),
                            label: const Text('Ny aktivitet'),
                          ),
                        ),
                      if (_canCreateActivity) const SizedBox(height: 12),
                      _DailySummaryCard(activities: activities),
                      const SizedBox(height: 12),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () =>
                              _loadActivities(showFullLoader: false),
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : activities.isEmpty
                              ? _EmptyActivitiesView(
                            isChildSession: _isChildSession,
                          )
                              : ListView.separated(
                            physics:
                            const AlwaysScrollableScrollPhysics(),
                            itemCount: activities.length,
                            separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final activity = activities[index];

                              return ActivityCard(
                                activity: activity,
                                profiles: _filterProfiles,
                                onTap: () =>
                                    _openActivityDetail(activity),
                                onCompletedChanged:
                                    (isCompleted) async {
                                  final scaffoldMessenger =
                                  ScaffoldMessenger.of(context);
                                  final updatedActivity =
                                  activity.copyWith(
                                    isCompleted: isCompleted,
                                  );

                                  setState(() {
                                    _activities = _activities.map(
                                          (existing) {
                                        if (existing.id !=
                                            activity.id) {
                                          return existing;
                                        }

                                        return updatedActivity;
                                      },
                                    ).toList();
                                  });

                                  try {
                                    await _activityService
                                        .setActivityCompleted(
                                      activityId: activity.id,
                                      isCompleted: isCompleted,
                                    );
                                  } catch (_) {
                                    if (!mounted) return;

                                    setState(() {
                                      _activities = _activities.map(
                                            (existing) {
                                          if (existing.id !=
                                              activity.id) {
                                            return existing;
                                          }

                                          return activity;
                                        },
                                      ).toList();
                                    });

                                    scaffoldMessenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Kunne ikke opdatere aktiviteten.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
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
  final VoidCallback onLogout;
  final bool isLoggingOut;
  final bool showChildHeaderName;
  final String? displayName;

  const _TopHeader({
    required this.onLogout,
    required this.isLoggingOut,
    required this.showChildHeaderName,
    this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        IconButton(
          tooltip: 'Log ud',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: isLoggingOut ? null : onLogout,
          icon: isLoggingOut
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Icon(Icons.logout, size: 28, color: colorScheme.onSurface),
        ),
        const Spacer(),
        if (showChildHeaderName)
          Text(
            displayName ?? 'Barn',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.85),
            ),
          )
        else
          const ProfileAvatarButton(),
      ],
    );
  }
}

class _ScreenTitle extends StatelessWidget {
  const _ScreenTitle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Daglig kalender',
        style: TextStyle(
          fontFamily: 'Italiana',
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  final List<Activity> activities;

  const _DailySummaryCard({required this.activities});

  Color _activityColor(Activity activity) {
    if (activity.isCompleted) return Colors.green;
    if (activity.isImportant) return Colors.red;
    if (activity.isFavorite) return Colors.amber;
    if (activity.visibility == ActivityVisibility.family) return Colors.purple;
    if (activity.ownerProfileId != null) return Colors.blue;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
        isDark ? const Color(0xFF171A19) : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2D2C) : const Color(0xFFE0E0E0),
        ),
      ),
      child: activities.isEmpty
          ? Text(
        'Ingen aktiviteter planlagt for denne dag',
        style: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dagens overblik',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          ActivityIndicators(
            activities: activities,
            activityColorBuilder: _activityColor,
            maxDots: 5,
            maxStars: 3,
            dotSize: 8,
            starSize: 13,
            countFontSize: 11,
            itemSpacing: 4,
            sectionSpacing: 10,
          ),
        ],
      ),
    );
  }
}

class _EmptyActivitiesView extends StatelessWidget {
  final bool isChildSession;

  const _EmptyActivitiesView({required this.isChildSession});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 38,
              color: colorScheme.onSurface.withOpacity(0.45),
            ),
            const SizedBox(height: 10),
            Text(
              'Ingen aktiviteter',
              style: TextStyle(
                fontFamily: 'Italiana',
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}