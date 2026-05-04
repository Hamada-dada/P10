import '../models/activity.dart';

abstract class ActivityRepository {
  Future<List<Activity>> getActivitiesForDate(DateTime date);

  Future<List<Activity>> getActivitiesForWeek(DateTime focusedDate);

  Future<Activity?> getActivityById(String id);

  Future<void> addActivity(Activity activity);

  Future<void> updateActivity(Activity activity);

  Future<void> deleteActivity(String activityId);

  Future<void> setActivityCompleted({
    required String activityId,
    required bool isCompleted,
  });

  Future<void> setChecklistItemChecked({
    required String checklistItemId,
    required bool isChecked,
  });
}