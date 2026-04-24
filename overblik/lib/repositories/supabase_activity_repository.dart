import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/activity.dart';
import 'activity_repository.dart';
import 'local_activity_cache.dart';

class SupabaseActivityRepository implements ActivityRepository {
  final SupabaseClient _client;
  final LocalActivityCache _localCache = LocalActivityCache();

  static const String _cachedFamilyIdKey = 'cached_current_family_id_v1';

  SupabaseActivityRepository(this._client);

  bool _isNetworkException(Object error) {
    if (error is SocketException) return true;
    if (error is http.ClientException) return true;

    final text = error.toString().toLowerCase();

    return text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('no address associated with hostname') ||
        text.contains('network is unreachable') ||
        text.contains('connection refused') ||
        text.contains('connection failed');
  }

  Future<void> _cacheCurrentFamilyId(String familyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedFamilyIdKey, familyId);
  }

  Future<String?> _getCachedFamilyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cachedFamilyIdKey);
  }

  Future<String?> _getCurrentFamilyId() async {
    final user = _client.auth.currentUser;

    debugPrint(
      'SupabaseActivityRepository: current auth user = ${user?.id}',
    );

    if (user == null) {
      return _getCachedFamilyId();
    }

    try {
      final profile = await _client
          .from('profiles')
          .select('family_id')
          .eq('auth_user_id', user.id)
          .eq('role', 'parent')
          .maybeSingle();

      debugPrint(
        'SupabaseActivityRepository: parent profile lookup = $profile',
      );

      if (profile == null) {
        return _getCachedFamilyId();
      }

      final familyId = profile['family_id'] as String?;

      if (familyId != null && familyId.trim().isNotEmpty) {
        await _cacheCurrentFamilyId(familyId);
      }

      return familyId;
    } catch (e, st) {
      debugPrint('SupabaseActivityRepository: family lookup failed: $e');
      debugPrintStack(stackTrace: st);

      if (_isNetworkException(e)) {
        final cachedFamilyId = await _getCachedFamilyId();

        debugPrint(
          'SupabaseActivityRepository: using cached family id = $cachedFamilyId',
        );

        return cachedFamilyId;
      }

      rethrow;
    }
  }

  @override
  Future<List<Activity>> getActivitiesForDate(DateTime date) async {
    final familyId = await _getCurrentFamilyId();

    if (familyId == null) {
      debugPrint(
        'SupabaseActivityRepository: no family id found for date query',
      );
      return [];
    }

    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    debugPrint(
      'SupabaseActivityRepository: loading date activities familyId=$familyId start=$start end=$end',
    );

    try {
      await _trySyncPendingActivities();

      final activities = await _getActivitiesForRangeOnline(
        familyId: familyId,
        rangeStart: start,
        rangeEnd: end,
      );

      await _localCache.upsertCachedActivities(activities);

      debugPrint(
        'SupabaseActivityRepository: returning ${activities.length} expanded activities for date',
      );

      return activities;
    } catch (e, st) {
      debugPrint(
        'SupabaseActivityRepository: date online load failed, using local cache: $e',
      );
      debugPrintStack(stackTrace: st);

      if (!_isNetworkException(e)) {
        rethrow;
      }

      final localActivities = await _getActivitiesForRangeFromLocalCache(
        familyId: familyId,
        rangeStart: start,
        rangeEnd: end,
      );

      debugPrint(
        'SupabaseActivityRepository: returning ${localActivities.length} local activities for date',
      );

      return localActivities;
    }
  }

  @override
  Future<List<Activity>> getActivitiesForWeek(DateTime focusedDate) async {
    final familyId = await _getCurrentFamilyId();

    if (familyId == null) {
      debugPrint(
        'SupabaseActivityRepository: no family id found for week query',
      );
      return [];
    }

    final startOfWeek = DateTime(
      focusedDate.year,
      focusedDate.month,
      focusedDate.day,
    ).subtract(Duration(days: focusedDate.weekday - 1));

    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    debugPrint(
      'SupabaseActivityRepository: loading week activities familyId=$familyId start=$startOfWeek end=$endOfWeek',
    );

    try {
      await _trySyncPendingActivities();

      final activities = await _getActivitiesForRangeOnline(
        familyId: familyId,
        rangeStart: startOfWeek,
        rangeEnd: endOfWeek,
      );

      await _localCache.upsertCachedActivities(activities);

      debugPrint(
        'SupabaseActivityRepository: returning ${activities.length} expanded activities for week',
      );

      return activities;
    } catch (e, st) {
      debugPrint(
        'SupabaseActivityRepository: week online load failed, using local cache: $e',
      );
      debugPrintStack(stackTrace: st);

      if (!_isNetworkException(e)) {
        rethrow;
      }

      final localActivities = await _getActivitiesForRangeFromLocalCache(
        familyId: familyId,
        rangeStart: startOfWeek,
        rangeEnd: endOfWeek,
      );

      debugPrint(
        'SupabaseActivityRepository: returning ${localActivities.length} local activities for week',
      );

      return localActivities;
    }
  }

  Future<List<Activity>> _getActivitiesForRangeOnline({
    required String familyId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    final rangeStartIso = rangeStart.toIso8601String();
    final rangeEndIso = rangeEnd.toIso8601String();

    final activityRows = await _client
        .from('activities')
        .select()
        .eq('family_id', familyId)
        .lt('start_time', rangeEndIso)
        .or('start_time.gte.$rangeStartIso,recurrence.neq.none')
        .order('start_time');

    debugPrint(
      'SupabaseActivityRepository: loaded ${activityRows.length} base activity rows for range',
    );

    final baseActivities = await _buildActivitiesFromRows(
      List<Map<String, dynamic>>.from(activityRows),
    );

    final expandedActivities = _expandRecurringActivitiesForRange(
      activities: baseActivities,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );

    expandedActivities.sort((a, b) => a.startTime.compareTo(b.startTime));

    return expandedActivities;
  }

  Future<List<Activity>> _getActivitiesForRangeFromLocalCache({
    required String familyId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    final allLocalActivities = await _localCache.getAllLocalActivities();
    final pendingActivities = await _localCache.getPendingActivities();

    final mergedById = <String, Activity>{};

    for (final activity in allLocalActivities) {
      mergedById[activity.id] = activity;
    }

    for (final activity in pendingActivities) {
      mergedById[activity.id] = activity;
    }

    final familyActivities = mergedById.values
        .where((activity) => activity.familyId == familyId)
        .toList();

    final expandedActivities = _expandRecurringActivitiesForRange(
      activities: familyActivities,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );

    expandedActivities.sort((a, b) => a.startTime.compareTo(b.startTime));

    return expandedActivities;
  }

  List<Activity> _expandRecurringActivitiesForRange({
    required List<Activity> activities,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final expanded = <Activity>[];

    for (final activity in activities) {
      if (activity.recurrence == ActivityRecurrence.none) {
        if (_startsInsideRange(activity.startTime, rangeStart, rangeEnd)) {
          expanded.add(activity);
        }
        continue;
      }

      expanded.addAll(
        _generateOccurrencesForRange(
          activity: activity,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        ),
      );
    }

    return expanded;
  }

  bool _startsInsideRange(
    DateTime startTime,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    return !startTime.isBefore(rangeStart) && startTime.isBefore(rangeEnd);
  }

  List<Activity> _generateOccurrencesForRange({
    required Activity activity,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    switch (activity.recurrence) {
      case ActivityRecurrence.daily:
        return _generateDailyOccurrences(
          activity: activity,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );

      case ActivityRecurrence.weekly:
        return _generateWeeklyOccurrences(
          activity: activity,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );

      case ActivityRecurrence.monthly:
        return _generateMonthlyOccurrences(
          activity: activity,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );

      case ActivityRecurrence.custom:
        if (_startsInsideRange(activity.startTime, rangeStart, rangeEnd)) {
          return [activity];
        }
        return [];

      case ActivityRecurrence.none:
        if (_startsInsideRange(activity.startTime, rangeStart, rangeEnd)) {
          return [activity];
        }
        return [];
    }
  }

  List<Activity> _generateDailyOccurrences({
    required Activity activity,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final interval =
        activity.recurrenceInterval < 1 ? 1 : activity.recurrenceInterval;

    final occurrenceDuration = activity.endTime.difference(activity.startTime);
    final originalStart = activity.startTime;

    final originalDay = DateTime(
      originalStart.year,
      originalStart.month,
      originalStart.day,
    );

    final rangeStartDay = DateTime(
      rangeStart.year,
      rangeStart.month,
      rangeStart.day,
    );

    final daysFromOriginal = rangeStartDay.difference(originalDay).inDays;

    final firstStep = daysFromOriginal <= 0
        ? 0
        : ((daysFromOriginal + interval - 1) ~/ interval);

    var occurrenceStart = originalStart.add(
      Duration(days: firstStep * interval),
    );

    final occurrences = <Activity>[];

    while (occurrenceStart.isBefore(rangeEnd)) {
      if (!occurrenceStart.isBefore(rangeStart)) {
        occurrences.add(
          _copyActivityForOccurrence(
            activity: activity,
            occurrenceStart: occurrenceStart,
            occurrenceDuration: occurrenceDuration,
          ),
        );
      }

      occurrenceStart = occurrenceStart.add(Duration(days: interval));
    }

    return occurrences;
  }

  List<Activity> _generateWeeklyOccurrences({
    required Activity activity,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final interval =
        activity.recurrenceInterval < 1 ? 1 : activity.recurrenceInterval;

    final periodDays = interval * 7;
    final occurrenceDuration = activity.endTime.difference(activity.startTime);
    final originalStart = activity.startTime;

    final originalDay = DateTime(
      originalStart.year,
      originalStart.month,
      originalStart.day,
    );

    final rangeStartDay = DateTime(
      rangeStart.year,
      rangeStart.month,
      rangeStart.day,
    );

    final daysFromOriginal = rangeStartDay.difference(originalDay).inDays;

    final firstStep = daysFromOriginal <= 0
        ? 0
        : ((daysFromOriginal + periodDays - 1) ~/ periodDays);

    var occurrenceStart = originalStart.add(
      Duration(days: firstStep * periodDays),
    );

    final occurrences = <Activity>[];

    while (occurrenceStart.isBefore(rangeEnd)) {
      if (!occurrenceStart.isBefore(rangeStart)) {
        occurrences.add(
          _copyActivityForOccurrence(
            activity: activity,
            occurrenceStart: occurrenceStart,
            occurrenceDuration: occurrenceDuration,
          ),
        );
      }

      occurrenceStart = occurrenceStart.add(Duration(days: periodDays));
    }

    return occurrences;
  }

  List<Activity> _generateMonthlyOccurrences({
    required Activity activity,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final interval =
        activity.recurrenceInterval < 1 ? 1 : activity.recurrenceInterval;

    final occurrenceDuration = activity.endTime.difference(activity.startTime);
    final originalStart = activity.startTime;

    final occurrences = <Activity>[];

    var monthStep = 0;
    var occurrenceStart = originalStart;
    var safetyCounter = 0;

    while (occurrenceStart.isBefore(rangeEnd) && safetyCounter < 600) {
      if (!occurrenceStart.isBefore(rangeStart)) {
        occurrences.add(
          _copyActivityForOccurrence(
            activity: activity,
            occurrenceStart: occurrenceStart,
            occurrenceDuration: occurrenceDuration,
          ),
        );
      }

      monthStep += interval;
      occurrenceStart = _addMonthsClamped(originalStart, monthStep);
      safetyCounter++;
    }

    return occurrences;
  }

  DateTime _addMonthsClamped(DateTime original, int monthsToAdd) {
    final targetMonthIndex = original.month + monthsToAdd;
    final targetYear = original.year + ((targetMonthIndex - 1) ~/ 12);
    final targetMonth = ((targetMonthIndex - 1) % 12) + 1;

    final lastDayInTargetMonth = DateTime(
      targetYear,
      targetMonth + 1,
      0,
    ).day;

    final targetDay = original.day > lastDayInTargetMonth
        ? lastDayInTargetMonth
        : original.day;

    return DateTime(
      targetYear,
      targetMonth,
      targetDay,
      original.hour,
      original.minute,
      original.second,
      original.millisecond,
      original.microsecond,
    );
  }

  Activity _copyActivityForOccurrence({
    required Activity activity,
    required DateTime occurrenceStart,
    required Duration occurrenceDuration,
  }) {
    return activity.copyWith(
      startTime: occurrenceStart,
      endTime: occurrenceStart.add(occurrenceDuration),
    );
  }

  @override
  Future<Activity?> getActivityById(String id) async {
    debugPrint('SupabaseActivityRepository: loading activity id=$id');

    final localActivity = await _getActivityByIdFromLocal(id);

    if (localActivity != null) {
      debugPrint(
        'SupabaseActivityRepository: found activity locally id=$id',
      );
    }

    try {
      await _trySyncPendingActivities();

      final rows = await _client
          .from('activities')
          .select()
          .eq('id', id)
          .limit(1);

      if (rows.isEmpty) {
        debugPrint(
          'SupabaseActivityRepository: no online activity found id=$id',
        );

        return localActivity;
      }

      final activities = await _buildActivitiesFromRows(
        List<Map<String, dynamic>>.from(rows),
      );

      if (activities.isEmpty) {
        debugPrint(
          'SupabaseActivityRepository: online activity build returned empty id=$id',
        );

        return localActivity;
      }

      await _localCache.upsertCachedActivities(activities);

      debugPrint(
        'SupabaseActivityRepository: returning online activity id=$id',
      );

      return activities.first;
    } catch (e, st) {
      debugPrint(
        'SupabaseActivityRepository: getActivityById online failed: $e',
      );
      debugPrintStack(stackTrace: st);

      if (_isNetworkException(e)) {
        if (localActivity != null) {
          debugPrint(
            'SupabaseActivityRepository: returning local activity id=$id',
          );
        } else {
          debugPrint(
            'SupabaseActivityRepository: no local fallback found id=$id',
          );
        }

        return localActivity;
      }

      rethrow;
    }
  }

  Future<Activity?> _getActivityByIdFromLocal(String id) async {
    final localActivities = await _localCache.getAllLocalActivities();

    for (final activity in localActivities) {
      if (activity.id == id) {
        return activity;
      }
    }

    final pendingActivities = await _localCache.getPendingActivities();

    for (final activity in pendingActivities) {
      if (activity.id == id) {
        return activity;
      }
    }

    return null;
  }

  @override
  Future<void> addActivity(Activity activity) async {
    debugPrint('SupabaseActivityRepository: inserting activity');
    debugPrint('SupabaseActivityRepository: id=${activity.id}');
    debugPrint('SupabaseActivityRepository: familyId=${activity.familyId}');
    debugPrint('SupabaseActivityRepository: createdBy=${activity.createdBy}');
    debugPrint(
      'SupabaseActivityRepository: ownerProfileId=${activity.ownerProfileId}',
    );
    debugPrint(
      'SupabaseActivityRepository: participants=${activity.participants.length}',
    );
    debugPrint(
      'SupabaseActivityRepository: checklistItems=${activity.checklistItems.length}',
    );

    try {
      await _insertActivityOnline(activity);

      await _localCache.upsertCachedActivities([activity]);
      await _localCache.removePendingActivity(activity.id);

      debugPrint('SupabaseActivityRepository: addActivity completed online');
    } on PostgrestException catch (e, st) {
      debugPrint(
        'SupabaseActivityRepository addActivity PostgrestException: ${e.message}',
      );
      debugPrint('SupabaseActivityRepository details: ${e.details}');
      debugPrint('SupabaseActivityRepository hint: ${e.hint}');
      debugPrint('SupabaseActivityRepository code: ${e.code}');
      debugPrintStack(stackTrace: st);
      rethrow;
    } catch (e, st) {
      debugPrint('SupabaseActivityRepository addActivity failed: $e');
      debugPrintStack(stackTrace: st);

      if (_isNetworkException(e)) {
        await _localCache.upsertPendingActivity(activity);
        await _localCache.upsertCachedActivities([activity]);

        debugPrint(
          'SupabaseActivityRepository: activity saved locally as pending',
        );

        return;
      }

      rethrow;
    }
  }

  Future<void> _insertActivityOnline(Activity activity) async {
    final activityRow = activity.toActivityRow();

    debugPrint(
      'SupabaseActivityRepository: activity row = $activityRow',
    );

    final insertedActivity = await _client
        .from('activities')
        .insert(activityRow)
        .select('id')
        .single();

    debugPrint(
      'SupabaseActivityRepository: activity inserted id=${insertedActivity['id']}',
    );

    if (activity.participants.isNotEmpty) {
      final participantRows = activity.participants
          .map((participant) => participant.toDatabaseRow(activity.id))
          .toList();

      debugPrint(
        'SupabaseActivityRepository: participant rows = $participantRows',
      );

      await _client.from('activity_participants').insert(participantRows);

      debugPrint('SupabaseActivityRepository: participants inserted');
    }

    if (activity.checklistItems.isNotEmpty) {
      final checklistRows = activity.checklistItems.map((item) {
        final row = Map<String, dynamic>.from(
          item.toDatabaseRow(activity.id),
        );

        if (row['id'] == null) {
          row.remove('id');
        }

        return row;
      }).toList();

      debugPrint(
        'SupabaseActivityRepository: checklist rows = $checklistRows',
      );

      await _client.from('checklist_items').insert(checklistRows);

      debugPrint('SupabaseActivityRepository: checklist inserted');
    }
  }

  Future<void> _trySyncPendingActivities() async {
    final pendingActivities = await _localCache.getPendingActivities();

    if (pendingActivities.isEmpty) {
      return;
    }

    debugPrint(
      'SupabaseActivityRepository: trying to sync ${pendingActivities.length} pending activities',
    );

    for (final activity in pendingActivities) {
      try {
        await _insertActivityOnline(activity);
        await _localCache.removePendingActivity(activity.id);
        await _localCache.upsertCachedActivities([activity]);

        debugPrint(
          'SupabaseActivityRepository: synced pending activity id=${activity.id}',
        );
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          await _localCache.removePendingActivity(activity.id);
          await _localCache.upsertCachedActivities([activity]);

          debugPrint(
            'SupabaseActivityRepository: pending activity already exists online id=${activity.id}',
          );

          continue;
        }

        rethrow;
      } catch (e) {
        if (_isNetworkException(e)) {
          debugPrint(
            'SupabaseActivityRepository: still offline, pending sync stopped',
          );
          return;
        }

        rethrow;
      }
    }
  }

  @override
  Future<void> updateActivity(Activity activity) async {
    debugPrint('SupabaseActivityRepository: updating activity id=${activity.id}');

    try {
      await _client
          .from('activities')
          .update(activity.toActivityRow())
          .eq('id', activity.id);

      await _client
          .from('activity_participants')
          .delete()
          .eq('activity_id', activity.id);

      if (activity.participants.isNotEmpty) {
        await _client.from('activity_participants').insert(
              activity.participants
                  .map((participant) => participant.toDatabaseRow(activity.id))
                  .toList(),
            );
      }

      await _client
          .from('checklist_items')
          .delete()
          .eq('activity_id', activity.id);

      if (activity.checklistItems.isNotEmpty) {
        final checklistRows = activity.checklistItems.map((item) {
          final row = Map<String, dynamic>.from(
            item.toDatabaseRow(activity.id),
          );

          if (row['id'] == null) {
            row.remove('id');
          }

          return row;
        }).toList();

        await _client.from('checklist_items').insert(checklistRows);
      }

      await _localCache.upsertCachedActivities([activity]);

      debugPrint('SupabaseActivityRepository: updateActivity completed');
    } on PostgrestException catch (e, st) {
      debugPrint(
        'SupabaseActivityRepository updateActivity PostgrestException: ${e.message}',
      );
      debugPrint('SupabaseActivityRepository details: ${e.details}');
      debugPrint('SupabaseActivityRepository hint: ${e.hint}');
      debugPrint('SupabaseActivityRepository code: ${e.code}');
      debugPrintStack(stackTrace: st);
      rethrow;
    } catch (e, st) {
      debugPrint('SupabaseActivityRepository updateActivity failed: $e');
      debugPrintStack(stackTrace: st);

      if (_isNetworkException(e)) {
        await _localCache.upsertPendingActivity(activity);
        await _localCache.upsertCachedActivities([activity]);

        debugPrint(
          'SupabaseActivityRepository: updated activity saved locally as pending',
        );

        return;
      }

      rethrow;
    }
  }

  @override
  Future<void> deleteActivity(String activityId) async {
    debugPrint('SupabaseActivityRepository: deleting activity id=$activityId');

    try {
      await _client.from('activities').delete().eq('id', activityId);

      await _localCache.removeCachedActivity(activityId);
      await _localCache.removePendingActivity(activityId);

      debugPrint('SupabaseActivityRepository: deleteActivity completed');
    } on PostgrestException catch (e, st) {
      debugPrint(
        'SupabaseActivityRepository deleteActivity PostgrestException: ${e.message}',
      );
      debugPrint('SupabaseActivityRepository details: ${e.details}');
      debugPrint('SupabaseActivityRepository hint: ${e.hint}');
      debugPrint('SupabaseActivityRepository code: ${e.code}');
      debugPrintStack(stackTrace: st);
      rethrow;
    } catch (e, st) {
      debugPrint('SupabaseActivityRepository deleteActivity failed: $e');
      debugPrintStack(stackTrace: st);

      if (_isNetworkException(e)) {
        await _localCache.removeCachedActivity(activityId);
        await _localCache.removePendingActivity(activityId);

        debugPrint(
          'SupabaseActivityRepository: deleted activity locally only while offline',
        );

        return;
      }

      rethrow;
    }
  }

  Future<List<Activity>> _buildActivitiesFromRows(
    List<Map<String, dynamic>> activityRows,
  ) async {
    if (activityRows.isEmpty) {
      return [];
    }

    final activityIds = activityRows.map((row) => row['id'] as String).toList();

    debugPrint(
      'SupabaseActivityRepository: building activities for ids=$activityIds',
    );

    final participantRows = await _client
        .from('activity_participants')
        .select()
        .inFilter('activity_id', activityIds);

    final checklistRows = await _client
        .from('checklist_items')
        .select()
        .inFilter('activity_id', activityIds)
        .order('position');

    debugPrint(
      'SupabaseActivityRepository: loaded ${participantRows.length} participant rows',
    );

    debugPrint(
      'SupabaseActivityRepository: loaded ${checklistRows.length} checklist rows',
    );

    final participantsByActivity = <String, List<ActivityParticipant>>{};

    for (final row in participantRows) {
      final map = Map<String, dynamic>.from(row);
      final activityId = map['activity_id'] as String;

      participantsByActivity.putIfAbsent(activityId, () => []);
      participantsByActivity[activityId]!.add(
        ActivityParticipant.fromDatabaseRow(map),
      );
    }

    final checklistByActivity = <String, List<ActivityChecklistItem>>{};

    for (final row in checklistRows) {
      final map = Map<String, dynamic>.from(row);
      final activityId = map['activity_id'] as String;

      checklistByActivity.putIfAbsent(activityId, () => []);
      checklistByActivity[activityId]!.add(
        ActivityChecklistItem.fromDatabaseRow(map),
      );
    }

    return activityRows.map((row) {
      final id = row['id'] as String;

      return Activity.fromDatabase(
        activityRow: row,
        participants: participantsByActivity[id] ?? const [],
        checklistItems: checklistByActivity[id] ?? const [],
      );
    }).toList();
  }
}