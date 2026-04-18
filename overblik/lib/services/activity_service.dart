import '../models/activity.dart';
import '../repositories/activity_repository.dart';

class ActivityService {
  final ActivityRepository repository;

  ActivityService(this.repository);

  Future<List<Activity>> getActivitiesForDate(DateTime date) async {
    final activities = await repository.getActivitiesForDate(date);
    activities.sort((a, b) => a.startTime.compareTo(b.startTime));
    return activities;
  }

  Future<List<Activity>> getActivitiesForWeek(DateTime focusedDate) async {
    final activities = await repository.getActivitiesForWeek(focusedDate);
    activities.sort((a, b) => a.startTime.compareTo(b.startTime));
    return activities;
  }

  Future<Activity?> getLongestActivityForDate(DateTime date) async {
    final activities = await getActivitiesForDate(date);

    if (activities.isEmpty) {
      return null;
    }

    Activity longestActivity = activities.first;

    for (final activity in activities) {
      if (activity.duration > longestActivity.duration) {
        longestActivity = activity;
      }
    }

    return longestActivity;
  }

  Future<List<Activity?>> getLongestActivitiesForWeek(DateTime focusedDate) async {
    final startOfWeek = _startOfWeek(focusedDate);
    final List<Activity?> longestActivities = [];

    for (int i = 0; i < 7; i++) {
      final currentDate = startOfWeek.add(Duration(days: i));
      longestActivities.add(await getLongestActivityForDate(currentDate));
    }

    return longestActivities;
  }

  List<DateTime> getWeekDates(DateTime focusedDate) {
    final startOfWeek = _startOfWeek(focusedDate);

    return List.generate(
      7,
      (index) => startOfWeek.add(Duration(days: index)),
    );
  }

  DateTime startOfWeek(DateTime date) {
    return _startOfWeek(date);
  }

  Future<Activity?> getActivityById(String id) {
    return repository.getActivityById(id);
  }

  Future<void> addActivity(Activity activity) async {
    await repository.addActivity(_normalizeActivity(activity));
  }

  Future<void> updateActivity(Activity updatedActivity) async {
    await repository.updateActivity(_normalizeActivity(updatedActivity));
  }

  Future<void> deleteActivity(String activityId) {
    return repository.deleteActivity(activityId);
  }

  Activity _normalizeActivity(Activity activity) {
    final normalizedChecked = List<bool>.generate(
      activity.checklistItems.length,
      (index) => index < activity.checklistChecked.length
          ? activity.checklistChecked[index]
          : false,
    );

    return activity.copyWith(
      checklistChecked: normalizedChecked,
    );
  }

  DateTime _startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }
}