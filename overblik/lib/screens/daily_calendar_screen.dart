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

  // Legacy child session fields.
  // Keep these temporarily until the old fake child-session flow is fully removed.
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

    debugPrint('DailyCalendarScreen: init');
    debugPrint('DailyCalendarScreen: hasAuthUser=$_hasAuthUser');
    debugPrint('DailyCalendarScreen: isChildSession=$_isChildSession');
    debugPrint('DailyCalendarScreen: childFamilyId=${widget.childFamilyId}');
    debugPrint('DailyCalendarScreen: childProfileId=${widget.childProfileId}');
    debugPrint('DailyCalendarScreen: childRole=${widget.childRole}');
    debugPrint('DailyCalendarScreen: childLoginCode=${widget.childLoginCode}');
    debugPrint(
      'DailyCalendarScreen: initialSelectedFilterProfileIds=${widget.initialSelectedFilterProfileIds}',
    );
    debugPrint(
      'DailyCalendarScreen: initialShowFamilyActivities=${widget.initialShowFamilyActivities}',
    );

    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    if (!_canUseScreen) {
      debugPrint(
        'DailyCalendarScreen: no auth user and no child session, skipping activity load',
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
        'DailyCalendarScreen: current profile id=${currentProfile?.id} role=${currentProfile?.role}',
      );
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

    if (!_canUseScreen) {
      debugPrint(
        'DailyCalendarScreen: app resumed but no valid session, skipping reload',
      );
      return;
    }

    debugPrint('DailyCalendarScreen: app resumed, reloading activities');
    _loadActivities(showFullLoader: false);
  }

  Future<void> _loadActivities({bool showFullLoader = true}) async {
    if (_isRefreshing) return;

    if (!_canUseScreen) {
      debugPrint(
        'DailyCalendarScreen: no auth user or child session, skipping activity load',
      );

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
    } catch (e, st) {
      debugPrint('DailyCalendarScreen _loadActivities failed: $e');
      debugPrintStack(stackTrace: st);

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
          _showFamilyActivities = true;
        });

        return;
      }

      final currentProfile =
          _currentProfile ??
          await _profileService.getCurrentAuthenticatedProfile();

      if (currentProfile == null) {
        debugPrint(
          'DailyCalendarScreen: no current profile for filter loading',
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
        _filterProfiles = profiles;

        if (_hasInitialFilterState) {
          _selectedFilterProfileIds = Set<String>.from(
            widget.initialSelectedFilterProfileIds ?? const {},
          );
          _showFamilyActivities = widget.initialShowFamilyActivities ?? false;
          return;
        }

        if (currentProfile.isParent) {
          // Parent default filter = all children/profiles + family activities.
          _selectedFilterProfileIds = profiles
              .map((profile) => profile.id)
              .toSet();
          _showFamilyActivities = true;
        } else {
          // Child default filter = own profile + family activities.
          _selectedFilterProfileIds = {currentProfile.id};
          _showFamilyActivities = true;
        }
      });
    } catch (e, st) {
      debugPrint('DailyCalendarScreen _loadFilterProfiles failed: $e');
      debugPrintStack(stackTrace: st);
    }
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
        debugPrint('DailyCalendarScreen: create activity cancelled');
        return;
      }

      debugPrint(
        'DailyCalendarScreen: saving activity id=${createdActivity.id}',
      );
      debugPrint('DailyCalendarScreen: familyId=${createdActivity.familyId}');
      debugPrint('DailyCalendarScreen: createdBy=${createdActivity.createdBy}');
      debugPrint(
        'DailyCalendarScreen: ownerProfileId=${createdActivity.ownerProfileId}',
      );
      debugPrint(
        'DailyCalendarScreen: visibility=${activityVisibilityToDatabase(createdActivity.visibility)}',
      );
      debugPrint(
        'DailyCalendarScreen: participants=${createdActivity.participants.length}',
      );
      debugPrint(
        'DailyCalendarScreen: checklistItems=${createdActivity.checklistItems.length}',
      );

      await _activityService.addActivity(createdActivity);

      debugPrint('DailyCalendarScreen: activity saved successfully');

      await _loadActivities(showFullLoader: false);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Aktivitet gemt')));
    } catch (e, st) {
      debugPrint('DailyCalendarScreen _openCreateActivityScreen failed: $e');
      debugPrintStack(stackTrace: st);

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
    } catch (e, st) {
      debugPrint('DailyCalendarScreen _logout failed: $e');
      debugPrintStack(stackTrace: st);

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

    debugPrint(
      'DailyCalendarScreen: raw=${_activities.length}, filtered=${activities.length}, profiles=${_filterProfiles.length}, selected=$_selectedFilterProfileIds, showFamily=$_showFamilyActivities',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFA2E5AD),
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
                            onPressed: _isLoggingOut
                                ? null
                                : _openCreateActivityScreen,
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
                                      onCompletedChanged: (isCompleted) async {
                                        final scaffoldMessenger =
                                            ScaffoldMessenger.of(context);
                                        final updatedActivity = activity
                                            .copyWith(isCompleted: isCompleted);

                                        setState(() {
                                          _activities = _activities.map((
                                            existing,
                                          ) {
                                            if (existing.id != activity.id) {
                                              return existing;
                                            }

                                            return updatedActivity;
                                          }).toList();
                                        });

                                        try {
                                          await _activityService.updateActivity(
                                            updatedActivity,
                                          );
                                        } catch (e, st) {
                                          debugPrint(
                                            'DailyCalendarScreen onCompletedChanged failed: $e',
                                          );
                                          debugPrintStack(stackTrace: st);

                                          if (!mounted) return;

                                          setState(() {
                                            _activities = _activities.map((
                                              existing,
                                            ) {
                                              if (existing.id != activity.id) {
                                                return existing;
                                              }

                                              return activity;
                                            }).toList();
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
              : const Icon(Icons.logout, size: 28, color: Colors.black),
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
  const _ScreenTitle();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Daglig kalender',
        style: TextStyle(
          fontFamily: 'Italiana',
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  final List<Activity> activities;

  const _DailySummaryCard({required this.activities});

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: activities.isEmpty
          ? const Text(
              'Ingen aktiviteter planlagt for denne dag',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dagens overblik',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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
    return const Center(
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note_outlined, size: 38, color: Colors.black45),
            SizedBox(height: 10),
            Text(
              'Ingen aktiviteter',
              style: TextStyle(
                fontFamily: 'Italiana',
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
