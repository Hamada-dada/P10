import 'package:flutter/material.dart';

import '../models/activity.dart';
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

class _DailyCalendarScreenState extends State<DailyCalendarScreen> {
  final ActivityService _activityService = ActivityService();
  late DateTime _focusedDate;

  @override
  void initState() {
    super.initState();
    _focusedDate = widget.initialDate ?? DateTime.now();
  }

  List<Activity> get _activitiesForFocusedDate {
    final activities = _activityService.getActivitiesForDate(_focusedDate);
    activities.sort((a, b) => a.startTime.compareTo(b.startTime));
    return activities;
  }

  void _goToPreviousDay() {
    setState(() {
      _focusedDate = _focusedDate.subtract(const Duration(days: 1));
    });
  }

  void _goToNextDay() {
    setState(() {
      _focusedDate = _focusedDate.add(const Duration(days: 1));
    });
  }

  void _goToToday() {
    setState(() {
      _focusedDate = DateTime.now();
    });
  }

  Future<void> _openActivityDetail(Activity activity) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityDetailScreen(activity: activity),
      ),
    );

    if (result == true) {
      setState(() {});
    }
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

  @override
  Widget build(BuildContext context) {
    final activities = _activitiesForFocusedDate;
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
              const ViewSwitcher(selectedView: CalendarScreenType.day),
              SizedBox(height: largeGap),
              CalendarNavigationBar(
                focusedDate: _focusedDate,
                viewType: CalendarViewType.day,
                onPrevious: _goToPreviousDay,
                onNext: _goToNextDay,
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
                      _DailySummaryCard(activities: activities),
                      const SizedBox(height: 12),
                      Expanded(
                        child: activities.isEmpty
                            ? const _EmptyActivitiesView()
                            : ListView.separated(
                                itemCount: activities.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final activity = activities[index];

                                  return ActivityCard(
                                    activity: activity,
                                    onTap: () => _openActivityDetail(activity),
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
        'Daglig kalender',
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

class _DailySummaryCard extends StatelessWidget {
  final List<Activity> activities;

  const _DailySummaryCard({
    required this.activities,
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
                  ownerColorBuilder: _ownerColor,
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
    );
  }
}