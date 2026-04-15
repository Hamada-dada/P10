import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../services/activity_service.dart';
import '../widgets/activity_card.dart';
import '../widgets/calendar_navigation_bar.dart';
import '../widgets/view_switcher.dart';
import 'activity_detail_screen.dart';

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
    return _activityService.getActivitiesForDate(_focusedDate);
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

  @override
  Widget build(BuildContext context) {
    final activities = _activitiesForFocusedDate;

    return Scaffold(
      backgroundColor: const Color(0xFFA2E5AD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _TopHeader(),
              const SizedBox(height: 12),
              Container(
                height: 6,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              const _ScreenTitle(),
              const SizedBox(height: 16),
              const ViewSwitcher(selectedView: CalendarScreenType.day),
              const SizedBox(height: 24),
              CalendarNavigationBar(
                focusedDate: _focusedDate,
                viewType: CalendarViewType.day,
                onPrevious: _goToPreviousDay,
                onNext: _goToNextDay,
                onToday: _goToToday,
                onFilterTap: () {},
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: activities.isEmpty
                      ? const _EmptyActivitiesView()
                      : ListView.builder(
                          itemCount: activities.length,
                          itemBuilder: (context, index) {
                            final activity = activities[index];

                            return ActivityCard(
                              activity: activity,
                              onTap: () => _openActivityDetail(activity),
                            );
                          },
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
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(
            Icons.arrow_back,
            size: 32,
            color: Colors.black,
          ),
        ),
        const Spacer(),
        CircleAvatar(
          radius: 24,
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
  const _ScreenTitle();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Daglig Kalender',
        style: TextStyle(
          fontFamily: 'Italiana',
          fontSize: 42,
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