import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../services/activity_service.dart';
import '../widgets/activity_card.dart';
import '../widgets/calendar_navigation_bar.dart';
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
  final List<Activity> _createdActivities = [];
  late DateTime _focusedDate;

  @override
  void initState() {
    super.initState();
    _focusedDate = widget.initialDate ?? DateTime.now();
  }

  List<Activity> get _activitiesForFocusedDate {
    final serviceActivities = _activityService.getActivitiesForDate(_focusedDate);

    final createdActivitiesForDate = _createdActivities.where((activity) {
      return activity.startTime.year == _focusedDate.year &&
          activity.startTime.month == _focusedDate.month &&
          activity.startTime.day == _focusedDate.day;
    }).toList();

    final allActivities = [
      ...serviceActivities,
      ...createdActivitiesForDate,
    ];

    allActivities.sort((a, b) => a.startTime.compareTo(b.startTime));
    return allActivities;
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

  void _openActivityDetail(Activity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityDetailScreen(activity: activity),
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
                      Expanded(
                        child: activities.isEmpty
                            ? const _EmptyActivitiesView()
                            : ListView.separated(
                                itemCount: activities.length,
                                separatorBuilder: (_, __) =>
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
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white,
          child: Icon(
            Icons.person,
            color: Colors.grey.shade700,
          ),
        ),
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
        'Daglig Kalender',
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

class _EmptyActivitiesView extends StatelessWidget {
  const _EmptyActivitiesView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Ingen aktiviteter',
        style: TextStyle(
          fontFamily: 'Italiana',
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
      ),
    );
  }
}