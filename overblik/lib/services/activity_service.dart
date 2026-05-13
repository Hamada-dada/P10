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

  Future<List<Activity>> getActivitiesForMonth(DateTime focusedDate) async {
    final activities = await repository.getActivitiesForMonth(focusedDate);
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
    await repository.addActivity(_validateActivity(activity));
  }

  Future<void> updateActivity(Activity updatedActivity) async {
    await repository.updateActivity(_validateActivity(updatedActivity));
  }

  Future<void> deleteActivity(String activityId) {
    return repository.deleteActivity(activityId);
  }

  Future<void> setActivityCompleted({
    required String activityId,
    required bool isCompleted,
  }) async {
    if (activityId.trim().isEmpty) {
      throw ArgumentError('Activity id cannot be empty.');
    }

    await repository.setActivityCompleted(
      activityId: activityId,
      isCompleted: isCompleted,
    );
  }

  Future<void> setChecklistItemChecked({
    required String checklistItemId,
    required bool isChecked,
  }) async {
    if (checklistItemId.trim().isEmpty) {
      throw ArgumentError('Checklist item id cannot be empty.');
    }

    await repository.setChecklistItemChecked(
      checklistItemId: checklistItemId,
      isChecked: isChecked,
    );
  }

  Activity _validateActivity(Activity activity) {
    if (activity.title.trim().isEmpty) {
      throw ArgumentError('Activity title cannot be empty.');
    }

    if (!activity.endTime.isAfter(activity.startTime)) {
      throw ArgumentError('Activity end time must be after start time.');
    }

    if (activity.recurrenceInterval < 1) {
      throw ArgumentError('Recurrence interval must be at least 1.');
    }

    final cleanedChecklist = activity.checklistItems
        .where((item) => item.title.trim().isNotEmpty)
        .toList();

    final normalizedChecklist = List<ActivityChecklistItem>.generate(
      cleanedChecklist.length,
      (index) {
        final item = cleanedChecklist[index];
        return ActivityChecklistItem(
          id: item.id,
          title: item.title.trim(),
          isChecked: item.isChecked,
          position: index,
        );
      },
    );

    return activity.copyWith(
      title: activity.title.trim(),
      emoji: activity.emoji.trim(),
      description: activity.description.trim(),
      imagePath: activity.imagePath.trim(),
      checklistItems: normalizedChecklist,
    );
  }

  DateTime _startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }
}