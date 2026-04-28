import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/activity.dart';
import '../repositories/supabase_activity_repository.dart';
import '../services/activity_service.dart';
import '../widgets/activity_card.dart';
import '../widgets/activity_indicators.dart';
import '../widgets/calendar_navigation_bar.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/view_switcher.dart';
import 'activity_detail_screen.dart';
import 'create_activity_screen.dart';

class DailyCalendarScreen extends StatefulWidget {
  final DateTime? initialDate;

  const DailyCalendarScreen({
    super.key,
    this.initialDate,
  });

  @override
  State<DailyCalendarScreen> createState() => _DailyCalendarScreenState();
}

class _DailyCalendarScreenState extends State<DailyCalendarScreen>
    with WidgetsBindingObserver {
  late final ActivityService _activityService = ActivityService(
    SupabaseActivityRepository(Supabase.instance.client),
  );

  late DateTime _focusedDate;

  List<Activity> _activities = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _focusedDate = widget.initialDate ?? DateTime.now();
    _loadActivities();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('DailyCalendarScreen: app resumed, reloading activities');
      _loadActivities(showFullLoader: false);
    }
  }

  Future<void> _loadActivities({bool showFullLoader = true}) async {
    if (_isRefreshing) return;

    try {
      _isRefreshing = true;

      if (showFullLoader && mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final activities =
          await _activityService.getActivitiesForDate(_focusedDate);

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
    } finally {
      _isRefreshing = false;
    }
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

  Future<void> _openCreateActivityScreen() async {
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
      debugPrint(
        'DailyCalendarScreen: familyId=${createdActivity.familyId}',
      );
      debugPrint(
        'DailyCalendarScreen: createdBy=${createdActivity.createdBy}',
      );
      debugPrint(
        'DailyCalendarScreen: ownerProfileId=${createdActivity.ownerProfileId}',
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aktivitet gemt'),
        ),
      );
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
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityDetailScreen(activity: activity),
      ),
    );

    if (result == true) {
  await _loadActivities(showFullLoader: false);

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Aktivitet opdateret'),
    ),
  );
}
  }

  @override
  Widget build(BuildContext context) {
    final activities = _activities;

    return Scaffold(
      backgroundColor: const Color(0xFFA2E5AD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _TopHeader(),
              const SizedBox(height: 8),
              const _ScreenTitle(),
              const SizedBox(height: 12),
              const ViewSwitcher(selectedView: CalendarScreenType.day),
              const SizedBox(height: 12),
              CalendarNavigationBar(
                focusedDate: _focusedDate,
                viewType: CalendarViewType.day,
                onPrevious: _goToPreviousDay,
                onNext: _goToNextDay,
                onToday: _goToToday,
                onFilterTap: () {},
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
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openCreateActivityScreen,
                          icon: const Icon(Icons.add),
                          label: const Text('Ny aktivitet'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DailySummaryCard(activities: activities),
                      const SizedBox(height: 12),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () =>
                              _loadActivities(showFullLoader: false),
                          child: _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : activities.isEmpty
                                  ? const _EmptyActivitiesView()
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
                                          onTap: () =>
                                              _openActivityDetail(activity),
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

  const _DailySummaryCard({
    required this.activities,
  });

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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
        ),
      ),
      child: activities.isEmpty
          ? const Text(
              'Ingen aktiviteter planlagt for denne dag',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
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
  const _EmptyActivitiesView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 38,
              color: Colors.black45,
            ),
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