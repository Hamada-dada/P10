import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity.dart';

class LocalActivityCache {
  static const String _cachedActivitiesKey = 'cached_activities_v1';
  static const String _pendingActivitiesKey = 'pending_activities_v1';

  Future<List<Activity>> getCachedActivities() async {
    return _readActivityList(_cachedActivitiesKey);
  }

  Future<List<Activity>> getPendingActivities() async {
    return _readActivityList(_pendingActivitiesKey);
  }

  Future<List<Activity>> getAllLocalActivities() async {
    final cached = await getCachedActivities();
    final pending = await getPendingActivities();

    final mergedById = <String, Activity>{};

    for (final activity in cached) {
      mergedById[activity.id] = activity;
    }

    for (final activity in pending) {
      mergedById[activity.id] = activity;
    }

    final merged = mergedById.values.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return merged;
  }

  Future<void> upsertCachedActivities(List<Activity> activities) async {
    if (activities.isEmpty) return;

    final existing = await getCachedActivities();
    final byId = <String, Activity>{};

    for (final activity in existing) {
      byId[activity.id] = activity;
    }

    for (final activity in activities) {
      byId[activity.id] = activity;
    }

    final updated = byId.values.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    await _writeActivityList(_cachedActivitiesKey, updated);
  }

  Future<void> upsertPendingActivity(Activity activity) async {
    final existing = await getPendingActivities();
    final byId = <String, Activity>{};

    for (final existingActivity in existing) {
      byId[existingActivity.id] = existingActivity;
    }

    byId[activity.id] = activity;

    final updated = byId.values.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    await _writeActivityList(_pendingActivitiesKey, updated);
  }

  Future<void> removePendingActivity(String activityId) async {
    final existing = await getPendingActivities();

    final updated = existing
        .where((activity) => activity.id != activityId)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    await _writeActivityList(_pendingActivitiesKey, updated);
  }

  Future<void> removeCachedActivity(String activityId) async {
    final existing = await getCachedActivities();

    final updated = existing
        .where((activity) => activity.id != activityId)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    await _writeActivityList(_cachedActivitiesKey, updated);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedActivitiesKey);
    await prefs.remove(_pendingActivitiesKey);
  }

  Future<List<Activity>> _readActivityList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);

    if (raw == null || raw.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map((item) => _activityFromJson(Map<String, dynamic>.from(item)))
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeActivityList(String key, List<Activity> activities) async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      activities.map(_activityToJson).toList(),
    );

    await prefs.setString(key, encoded);
  }

  Map<String, dynamic> _activityToJson(Activity activity) {
    return {
      'activity': {
        ...activity.toActivityRow(),
        'created_at': activity.createdAt?.toIso8601String(),
        'updated_at': activity.updatedAt?.toIso8601String(),
      },
      'participants': activity.participants.map((participant) {
        return {
          'profile_id': participant.profileId,
          'external_name': participant.externalName,
        };
      }).toList(),
      'checklist_items': activity.checklistItems.map((item) {
        return {
          'id': item.id,
          'title': item.title,
          'is_checked': item.isChecked,
          'position': item.position,
        };
      }).toList(),
    };
  }

  Activity _activityFromJson(Map<String, dynamic> json) {
    final activityRow = Map<String, dynamic>.from(
      json['activity'] as Map,
    );

    final rawParticipants = json['participants'];
    final rawChecklistItems = json['checklist_items'];

    final participants = rawParticipants is List
        ? rawParticipants
            .whereType<Map>()
            .map(
              (row) => ActivityParticipant.fromDatabaseRow(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList()
        : <ActivityParticipant>[];

    final checklistItems = rawChecklistItems is List
        ? rawChecklistItems
            .whereType<Map>()
            .map(
              (row) => ActivityChecklistItem.fromDatabaseRow(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList()
        : <ActivityChecklistItem>[];

    return Activity.fromDatabase(
      activityRow: activityRow,
      participants: participants,
      checklistItems: checklistItems,
    );
  }
}