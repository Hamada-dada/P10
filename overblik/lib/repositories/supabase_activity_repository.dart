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

  final String? childFamilyId;
  final String? childProfileId;
  final String? childRole;
  final String? childLoginCode;

  static const String _legacyCachedFamilyIdKey =
      'cached_current_family_id_v1';
  static const String _cachedFamilyIdPrefix =
      'cached_current_family_id_v2';

  SupabaseActivityRepository(
    this._client, {
    this.childFamilyId,
    this.childProfileId,
    this.childRole,
    this.childLoginCode,
  });

  bool get _isChildSession {
    return childFamilyId != null &&
        childProfileId != null &&
        childRole != null &&
        childLoginCode != null;
  }

  String _cachedFamilyIdKeyForUser(String authUserId) {
    return '${_cachedFamilyIdPrefix}_$authUserId';
  }

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

  Future<void> _cacheCurrentFamilyIdForUser({
    required String authUserId,
    required String familyId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _cachedFamilyIdKeyForUser(authUserId),
      familyId,
    );
  }

  Future<String?> _getCachedFamilyIdForUser(String authUserId) async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(
      _cachedFamilyIdKeyForUser(authUserId),
    );
  }

  Future<void> _clearCachedFamilyIdForUser(String authUserId) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_cachedFamilyIdKeyForUser(authUserId));

    // Remove old global cache because it can leak family context
    // between different authenticated users.
    await prefs.remove(_legacyCachedFamilyIdKey);
  }

  Future<String?> _getCurrentFamilyId() async {
    if (_isChildSession) {
      debugPrint(
        'SupabaseActivityRepository: using child session '
        'familyId=$childFamilyId profileId=$childProfileId role=$childRole',
      );

      return childFamilyId;
    }

    final user = _client.auth.currentUser;

    debugPrint(
      'SupabaseActivityRepository: current auth user = ${user?.id}',
    );

    if (user == null) {
      debugPrint(
        'SupabaseActivityRepository: no auth user, returning null family id',
      );

      return null;
    }

    try {
      final profile = await _client
          .from('profiles')
          .select('family_id')
          .eq('auth_user_id', user.id)
          .eq('role', 'parent')
          .eq('is_active', true)
          .maybeSingle();

      debugPrint(
        'SupabaseActivityRepository: parent profile lookup = $profile',
      );

      if (profile == null) {
        debugPrint(
          'SupabaseActivityRepository: authenticated user has no active '
          'parent profile, clearing cache and returning null family id',
        );

        await _clearCachedFamilyIdForUser(user.id);

        return null;
      }

      final familyId = profile['family_id'] as String?;

      if (familyId == null || familyId.trim().isEmpty) {
        debugPrint(
          'SupabaseActivityRepository: parent profile has no family id, '
          'clearing cache and returning null family id',
        );

        await _clearCachedFamilyIdForUser(user.id);

        return null;
      }

      await _cacheCurrentFamilyIdForUser(
        authUserId: user.id,
        familyId: familyId,
      );

      return familyId;
    } catch (e, st) {
      debugPrint('SupabaseActivityRepository: family lookup failed: $e');
      debugPrintStack(stackTrace: st);

      if (_isNetworkException(e)) {
        final cachedFamilyId = await _getCachedFamilyIdForUser(user.id);

        debugPrint(
          'SupabaseActivityRepository: network error, using user-scoped '
          'cached family id = $cachedFamilyId',
        );

        return cachedFamilyId;
      }

      rethrow;
    }
  }

  bool _activityVisibleToCurrentChild(Activity activity) {
    if (!_isChildSession || childProfileId == null) {
      return true;
    }

    if (activity.familyId != childFamilyId) {
      return false;
    }

    if (activity.visibility == ActivityVisibility.family) {
      return true;
    }

    if (activity.ownerProfileId == childProfileId) {
      return true;
    }

    return activity.participants.any(
      (participant) => participant.profileId == childProfileId,
    );
  }

  bool _activitySafeForCurrentSession({
    required Activity activity,
    required String? currentFamilyId,
  }) {
    if (_isChildSession) {
      return _activityVisibleToCurrentChild(activity);
    }

    if (currentFamilyId == null || currentFamilyId.trim().isEmpty) {
      return false;
    }

    return activity.familyId == currentFamilyId;
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
      'SupabaseActivityRepository: loading date activities '
      'familyId=$familyId start=$start end=$end',
    );

    try {
      await _trySyncPendingActivities(familyId: familyId);

      final activities = await _getActivitiesForRangeOnline(
        familyId: familyId,
        rangeStart: start,
        rangeEnd: end,
      );

      await _localCache.upsertCachedActivities(activities);

      debugPrint(
        'SupabaseActivityRepository: returning ${activities.length} '
        'expanded activities for date',
      );

      return activities;
    } catch (e, st) {
      debugPrint(
        'SupabaseActivityRepository: date online load failed, using local '
        'cache only if network error: $e',
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
        'SupabaseActivityRepository: returning ${localActivities.length} '
        'local activities for date',
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
      'SupabaseActivityRepository: loading week activities '
      'familyId=$familyId start=$startOfWeek end=$endOfWeek',
    );

    try {
      await _trySyncPendingActivities(familyId: familyId);

      final activities = await _getActivitiesForRangeOnline(
        familyId: familyId,
        rangeStart: startOfWeek,
        rangeEnd: endOfWeek,
      );

      await _localCache.upsertCachedActivities(activities);

      debugPrint(
        'SupabaseActivityRepository: returning ${activities.length} '
        'expanded activities for week',
      );

      return activities;
    } catch (e, st) {
      debugPrint(
        'SupabaseActivityRepository: week online load failed, using local '
        'cache only if network error: $e',
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
        'SupabaseActivityRepository: returning ${localActivities.length} '
        'local activities for week',
      );

      return localActivities;
    }
  }

  Future<List<Activity>> _getActivitiesForRangeOnline({
    required String familyId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    if (_isChildSession) {
      return _getActivitiesForRangeOnlineAsChild(
        familyId: familyId,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );
    }

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
      'SupabaseActivityRepository: loaded ${activityRows.length} '
      'base activity rows for range',
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

  Future<List<Activity>> _getActivitiesForRangeOnlineAsChild({
    required String familyId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    if (!_isChildSession || childProfileId == null || childLoginCode == null) {
      debugPrint(
        'SupabaseActivityRepository: incomplete child session, '
        'cannot load child activities',
      );
      return [];
    }

    final rangeStartIso = rangeStart.toIso8601String();
    final rangeEndIso = rangeEnd.toIso8601String();

    debugPrint(
      'SupabaseActivityRepository: child loading activities '
      'profileId=$childProfileId familyId=$familyId '
      'start=$rangeStartIso end=$rangeEndIso',
    );

    final result = await _client.rpc(
      'child_get_activities_for_range_v2',
      params: {
        'input_profile_id': childProfileId,
        'input_child_code': childLoginCode,
        'input_range_start': rangeStartIso,
        'input_range_end': rangeEndIso,
      },
    );

    final rows = List<Map<String, dynamic>>.from(result as List);

    debugPrint(
      'SupabaseActivityRepository: child v2 RPC returned '
      '${rows.length} activity rows',
    );

    final baseActivities = _buildActivitiesFromRpcRows(rows);

    final expandedActivities = _expandRecurringActivitiesForRange(
      activities: baseActivities,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    ).where(_activityVisibleToCurrentChild).toList();

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
        .where(_activityVisibleToCurrentChild)
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

    final currentFamilyId = await _getCurrentFamilyId();

    if (currentFamilyId == null) {
      debugPrint(
        'SupabaseActivityRepository: no current family id, refusing '
        'getActivityById local/online load',
      );
      return null;
    }

    final localActivity = await _getActivityByIdFromLocal(id);

    if (localActivity != null) {
      debugPrint(
        'SupabaseActivityRepository: found activity locally id=$id',
      );
    }

    try {
      await _trySyncPendingActivities(familyId: currentFamilyId);

      if (_isChildSession) {
        if (localActivity != null &&
            _activitySafeForCurrentSession(
              activity: localActivity,
              currentFamilyId: currentFamilyId,
            )) {
          return localActivity;
        }

        return null;
      }

      final rows = await _client
          .from('activities')
          .select()
          .eq('id', id)
          .eq('family_id', currentFamilyId)
          .limit(1);

      if (rows.isEmpty) {
        debugPrint(
          'SupabaseActivityRepository: no online activity found id=$id',
        );

        if (localActivity != null &&
            _activitySafeForCurrentSession(
              activity: localActivity,
              currentFamilyId: currentFamilyId,
            )) {
          return localActivity;
        }

        return null;
      }

      final activities = await _buildActivitiesFromRows(
        List<Map<String, dynamic>>.from(rows),
      );

      if (activities.isEmpty) {
        debugPrint(
          'SupabaseActivityRepository: online activity build returned empty '
          'id=$id',
        );

        if (localActivity != null &&
            _activitySafeForCurrentSession(
              activity: localActivity,
              currentFamilyId: currentFamilyId,
            )) {
          return localActivity;
        }

        return null;
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
        if (localActivity != null &&
            _activitySafeForCurrentSession(
              activity: localActivity,
              currentFamilyId: currentFamilyId,
            )) {
          debugPrint(
            'SupabaseActivityRepository: returning safe local activity id=$id',
          );
          return localActivity;
        }

        debugPrint(
          'SupabaseActivityRepository: no safe local fallback found id=$id',
        );

        return null;
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
      'SupabaseActivityRepository: visibility='
      '${activityVisibilityToDatabase(activity.visibility)}',
    );
    debugPrint(
      'SupabaseActivityRepository: participants=${activity.participants.length}',
    );
    debugPrint(
      'SupabaseActivityRepository: checklistItems=${activity.checklistItems.length}',
    );

    if (_isChildSession) {
      throw Exception(
        'Child activity creation is not implemented yet. '
        'Next step is child_create_activity RPC.',
      );
    }

    final currentFamilyId = await _getCurrentFamilyId();

    if (currentFamilyId == null || activity.familyId != currentFamilyId) {
      throw Exception(
        'Cannot add activity because the activity family does not match the '
        'current active parent family.',
      );
    }

    try {
      await _insertActivityOnline(activity);

      await _localCache.upsertCachedActivities([activity]);
      await _localCache.removePendingActivity(activity.id);

      debugPrint('SupabaseActivityRepository: addActivity completed online');
    } on PostgrestException catch (e, st) {
      debugPrint(
        'SupabaseActivityRepository addActivity PostgrestException: '
        '${e.message}',
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
      'SupabaseActivityRepository: activity inserted '
      'id=${insertedActivity['id']}',
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

  Future<void> _trySyncPendingActivities({
    required String familyId,
  }) async {
    if (_isChildSession) {
      debugPrint(
        'SupabaseActivityRepository: child session, skipping pending '
        'activity sync',
      );
      return;
    }

    final pendingActivities = await _localCache.getPendingActivities();

    final safePendingActivities = pendingActivities
        .where((activity) => activity.familyId == familyId)
        .toList();

    if (safePendingActivities.isEmpty) {
      return;
    }

    debugPrint(
      'SupabaseActivityRepository: trying to sync '
      '${safePendingActivities.length} pending activities for family=$familyId',
    );

    for (final activity in safePendingActivities) {
      try {
        await _insertActivityOnline(activity);
        await _localCache.removePendingActivity(activity.id);
        await _localCache.upsertCachedActivities([activity]);

        debugPrint(
          'SupabaseActivityRepository: synced pending activity '
          'id=${activity.id}',
        );
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          await _localCache.removePendingActivity(activity.id);
          await _localCache.upsertCachedActivities([activity]);

          debugPrint(
            'SupabaseActivityRepository: pending activity already exists '
            'online id=${activity.id}',
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
    if (_isChildSession) {
      throw Exception(
        'Child activity update is not implemented yet. '
        'This needs a controlled RPC.',
      );
    }

    final currentFamilyId = await _getCurrentFamilyId();

    if (currentFamilyId == null || activity.familyId != currentFamilyId) {
      throw Exception(
        'Cannot update activity because the activity family does not match '
        'the current active parent family.',
      );
    }

    debugPrint(
      'SupabaseActivityRepository: updating activity id=${activity.id}',
    );

    try {
      await _client
          .from('activities')
          .update(activity.toActivityRow())
          .eq('id', activity.id)
          .eq('family_id', currentFamilyId);

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
        'SupabaseActivityRepository updateActivity PostgrestException: '
        '${e.message}',
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
          'SupabaseActivityRepository: updated activity saved locally as '
          'pending',
        );

        return;
      }

      rethrow;
    }
  }

  @override
  Future<void> deleteActivity(String activityId) async {
    if (_isChildSession) {
      throw Exception(
        'Child activity deletion is not allowed from child session.',
      );
    }

    final currentFamilyId = await _getCurrentFamilyId();

    if (currentFamilyId == null) {
      throw Exception(
        'Cannot delete activity because no active parent family was found.',
      );
    }

    debugPrint('SupabaseActivityRepository: deleting activity id=$activityId');

    try {
      await _client
          .from('activities')
          .delete()
          .eq('id', activityId)
          .eq('family_id', currentFamilyId);

      await _localCache.removeCachedActivity(activityId);
      await _localCache.removePendingActivity(activityId);

      debugPrint('SupabaseActivityRepository: deleteActivity completed');
    } on PostgrestException catch (e, st) {
      debugPrint(
        'SupabaseActivityRepository deleteActivity PostgrestException: '
        '${e.message}',
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
          'SupabaseActivityRepository: deleted activity locally only while '
          'offline',
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
      'SupabaseActivityRepository: loaded '
      '${participantRows.length} participant rows',
    );

    debugPrint(
      'SupabaseActivityRepository: loaded '
      '${checklistRows.length} checklist rows',
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

  List<Activity> _buildActivitiesFromRpcRows(
    List<Map<String, dynamic>> rows,
  ) {
    if (rows.isEmpty) {
      return [];
    }

    return rows.map((row) {
      final activityRow = Map<String, dynamic>.from(
        row['activity'] as Map,
      );

      final participantRows = List<Map<String, dynamic>>.from(
        row['participants'] as List? ?? const [],
      );

      final checklistRows = List<Map<String, dynamic>>.from(
        row['checklist_items'] as List? ?? const [],
      );

      final participants = participantRows
          .map(ActivityParticipant.fromDatabaseRow)
          .toList();

      final checklistItems = checklistRows
          .map(ActivityChecklistItem.fromDatabaseRow)
          .toList();

      return Activity.fromDatabase(
        activityRow: activityRow,
        participants: participants,
        checklistItems: checklistItems,
      );
    }).toList();
  }
}