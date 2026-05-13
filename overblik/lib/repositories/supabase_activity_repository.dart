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
  late final LocalActivityCache _localCache;

  final String? childFamilyId;
  final String? childProfileId;
  final String? childRole;
  final String? childLoginCode;

  // CS-2: in-memory family id cache to avoid repeated profile lookups
  String? _familyIdCache;

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
  }) {
    // O-3: scope cache to the current user so sessions never bleed into each other
    _localCache = LocalActivityCache(
      userId: childProfileId ?? _client.auth.currentUser?.id,
    );
  }

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
    _familyIdCache = null;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_cachedFamilyIdKeyForUser(authUserId));

    // Remove old global cache because it can leak family context
    // between different authenticated users.
    await prefs.remove(_legacyCachedFamilyIdKey);
  }

  Future<String?> _getCurrentFamilyId() async {
    if (_isChildSession) {
      debugPrint(
        'SupabaseActivityRepository: using legacy child session '
        'familyId=$childFamilyId profileId=$childProfileId role=$childRole',
      );

      return childFamilyId;
    }

    // CS-2: return in-memory cache hit without a network or disk round-trip
    if (_familyIdCache != null) {
      return _familyIdCache;
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
          .select('family_id, role')
          .eq('auth_user_id', user.id)
          .eq('is_active', true)
          .maybeSingle();

      debugPrint(
        'SupabaseActivityRepository: current profile lookup = $profile',
      );

      if (profile == null) {
        debugPrint(
          'SupabaseActivityRepository: authenticated user has no active '
          'profile, clearing cache and returning null family id',
        );

        await _clearCachedFamilyIdForUser(user.id);

        return null;
      }

      final familyId = profile['family_id'] as String?;

      if (familyId == null || familyId.trim().isEmpty) {
        debugPrint(
          'SupabaseActivityRepository: current profile has no family id, '
          'clearing cache and returning null family id',
        );

        await _clearCachedFamilyIdForUser(user.id);

        return null;
      }

      _familyIdCache = familyId;

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

  @override
  Future<List<Activity>> getActivitiesForMonth(DateTime focusedDate) async {
    final familyId = await _getCurrentFamilyId();

    if (familyId == null) {
      debugPrint(
        'SupabaseActivityRepository: no family id found for month query',
      );
      return [];
    }

    // Compute the full calendar grid range (same logic as _buildMonthGrid in
    // monthly_calendar_screen): Mon-padded start to Sun-padded end.
    final firstDayOfMonth = DateTime(focusedDate.year, focusedDate.month, 1);
    final lastDayOfMonth = DateTime(focusedDate.year, focusedDate.month + 1, 0);

    final gridStart = firstDayOfMonth.subtract(
      Duration(days: firstDayOfMonth.weekday - 1),
    );
    final gridEnd = lastDayOfMonth.add(
      Duration(days: 7 - lastDayOfMonth.weekday + 1),
    );

    debugPrint(
      'SupabaseActivityRepository: loading month activities '
      'familyId=$familyId gridStart=$gridStart gridEnd=$gridEnd',
    );

    try {
      await _trySyncPendingActivities(familyId: familyId);

      final activities = await _getActivitiesForRangeOnline(
        familyId: familyId,
        rangeStart: gridStart,
        rangeEnd: gridEnd,
      );

      await _localCache.upsertCachedActivities(activities);

      debugPrint(
        'SupabaseActivityRepository: returning ${activities.length} '
        'expanded activities for month',
      );

      return activities;
    } catch (e, st) {
      debugPrint(
        'SupabaseActivityRepository: month online load failed, using local '
        'cache only if network error: $e',
      );
      debugPrintStack(stackTrace: st);

      if (!_isNetworkException(e)) {
        rethrow;
      }

      final localActivities = await _getActivitiesForRangeFromLocalCache(
        familyId: familyId,
        rangeStart: gridStart,
        rangeEnd: gridEnd,
      );

      debugPrint(
        'SupabaseActivityRepository: returning ${localActivities.length} '
        'local activities for month',
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
      return _getActivitiesForRangeOnlineAsLegacyChild(
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

  Future<List<Activity>> _getActivitiesForRangeOnlineAsLegacyChild({
    required String familyId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    if (!_isChildSession || childProfileId == null || childLoginCode == null) {
      debugPrint(
        'SupabaseActivityRepository: incomplete legacy child session, '
        'cannot load child activities',
      );
      return [];
    }

    final rangeStartIso = rangeStart.toIso8601String();
    final rangeEndIso = rangeEnd.toIso8601String();

    debugPrint(
      'SupabaseActivityRepository: legacy child loading activities '
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
    // getAllLocalActivities already merges cached + pending creates — no need
    // to call getPendingActivities separately (O-4).
    final allLocalActivities = await _localCache.getAllLocalActivities();

    final familyActivities = allLocalActivities
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

    // Clamp range end to recurrenceEndDate (inclusive day).
    final effectiveRangeEnd = activity.recurrenceEndDate != null &&
            activity.recurrenceEndDate!.add(const Duration(days: 1)).isBefore(rangeEnd)
        ? activity.recurrenceEndDate!.add(const Duration(days: 1))
        : rangeEnd;

    if (!effectiveRangeEnd.isAfter(rangeStart)) return [];

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

    while (occurrenceStart.isBefore(effectiveRangeEnd)) {
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

    final effectiveRangeEnd = activity.recurrenceEndDate != null &&
            activity.recurrenceEndDate!.add(const Duration(days: 1)).isBefore(rangeEnd)
        ? activity.recurrenceEndDate!.add(const Duration(days: 1))
        : rangeEnd;

    if (!effectiveRangeEnd.isAfter(rangeStart)) return [];

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

    while (occurrenceStart.isBefore(effectiveRangeEnd)) {
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

    final effectiveRangeEnd = activity.recurrenceEndDate != null &&
            activity.recurrenceEndDate!.add(const Duration(days: 1)).isBefore(rangeEnd)
        ? activity.recurrenceEndDate!.add(const Duration(days: 1))
        : rangeEnd;

    if (!effectiveRangeEnd.isAfter(rangeStart)) return [];

    final occurrenceDuration = activity.endTime.difference(activity.startTime);
    final originalStart = activity.startTime;

    final occurrences = <Activity>[];

    var monthStep = 0;
    var occurrenceStart = originalStart;
    var safetyCounter = 0;

    while (occurrenceStart.isBefore(effectiveRangeEnd) && safetyCounter < 600) {
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
  Future<void> setActivityCompleted({
    required String activityId,
    required bool isCompleted,
  }) async {
    final currentFamilyId = await _getCurrentFamilyId();

    if (currentFamilyId == null) {
      throw Exception(
        'Cannot update activity completion because no active family was found.',
      );
    }

    debugPrint(
      'SupabaseActivityRepository: setActivityCompleted '
      'activityId=$activityId isCompleted=$isCompleted',
    );

    // O-2: update local cache immediately so the UI stays responsive offline
    final localActivity = await _getActivityByIdFromLocal(activityId);

    if (localActivity != null &&
        _activitySafeForCurrentSession(
          activity: localActivity,
          currentFamilyId: currentFamilyId,
        )) {
      await _localCache.upsertCachedActivities([
        localActivity.copyWith(isCompleted: isCompleted),
      ]);
    }

    try {
      await _client.rpc(
        'set_activity_completed',
        params: {
          'input_activity_id': activityId,
          'input_is_completed': isCompleted,
        },
      );

      await _localCache.removePendingCompletion(activityId);

      debugPrint(
        'SupabaseActivityRepository: setActivityCompleted completed',
      );
    } on PostgrestException catch (e, st) {
      debugPrint(
        'SupabaseActivityRepository setActivityCompleted PostgrestException: '
        '${e.message}',
      );
      debugPrint('SupabaseActivityRepository details: ${e.details}');
      debugPrint('SupabaseActivityRepository hint: ${e.hint}');
      debugPrint('SupabaseActivityRepository code: ${e.code}');
      debugPrintStack(stackTrace: st);
      rethrow;
    } catch (e, st) {
      debugPrint('SupabaseActivityRepository setActivityCompleted failed: $e');
      debugPrintStack(stackTrace: st);

      if (_isNetworkException(e)) {
        await _localCache.setPendingCompletion(activityId, isCompleted);
        debugPrint(
          'SupabaseActivityRepository: queued completion offline activityId=$activityId',
        );
        return;
      }

      rethrow;
    }
  }

  @override
  Future<void> setChecklistItemChecked({
    required String checklistItemId,
    required bool isChecked,
  }) async {
    final currentFamilyId = await _getCurrentFamilyId();

    if (currentFamilyId == null) {
      throw Exception(
        'Cannot update checklist item because no active family was found.',
      );
    }

    debugPrint(
      'SupabaseActivityRepository: setChecklistItemChecked '
      'checklistItemId=$checklistItemId isChecked=$isChecked',
    );

    // O-2: update local cache immediately so the UI stays responsive offline
    final localActivity = await _getActivityContainingChecklistItemFromLocal(
      checklistItemId,
    );

    if (localActivity != null &&
        _activitySafeForCurrentSession(
          activity: localActivity,
          currentFamilyId: currentFamilyId,
        )) {
      final updatedChecklistItems = localActivity.checklistItems.map((item) {
        if (item.id != checklistItemId) return item;

        return ActivityChecklistItem(
          id: item.id,
          title: item.title,
          isChecked: isChecked,
          position: item.position,
        );
      }).toList();

      await _localCache.upsertCachedActivities([
        localActivity.copyWith(checklistItems: updatedChecklistItems),
      ]);
    }

    try {
      await _client.rpc(
        'set_checklist_item_checked',
        params: {
          'input_checklist_item_id': checklistItemId,
          'input_is_checked': isChecked,
        },
      );

      await _localCache.removePendingChecklistCheck(checklistItemId);

      debugPrint(
        'SupabaseActivityRepository: setChecklistItemChecked completed',
      );
    } on PostgrestException catch (e, st) {
      debugPrint(
        'SupabaseActivityRepository setChecklistItemChecked PostgrestException: '
        '${e.message}',
      );
      debugPrint('SupabaseActivityRepository details: ${e.details}');
      debugPrint('SupabaseActivityRepository hint: ${e.hint}');
      debugPrint('SupabaseActivityRepository code: ${e.code}');
      debugPrintStack(stackTrace: st);
      rethrow;
    } catch (e, st) {
      debugPrint('SupabaseActivityRepository setChecklistItemChecked failed: $e');
      debugPrintStack(stackTrace: st);

      if (_isNetworkException(e)) {
        await _localCache.setPendingChecklistCheck(checklistItemId, isChecked);
        debugPrint(
          'SupabaseActivityRepository: queued checklist check offline '
          'checklistItemId=$checklistItemId',
        );
        return;
      }

      rethrow;
    }
  }

  Future<Activity?> _getActivityContainingChecklistItemFromLocal(
    String checklistItemId,
  ) async {
    final localActivities = await _localCache.getAllLocalActivities();

    for (final activity in localActivities) {
      final containsItem = activity.checklistItems.any(
        (item) => item.id == checklistItemId,
      );

      if (containsItem) {
        return activity;
      }
    }

    final pendingActivities = await _localCache.getPendingActivities();

    for (final activity in pendingActivities) {
      final containsItem = activity.checklistItems.any(
        (item) => item.id == checklistItemId,
      );

      if (containsItem) {
        return activity;
      }
    }

    return null;
  }

  
  @override
  Future<void> addActivity(Activity activity) async {
    debugPrint('SupabaseActivityRepository: creating activity with relations');
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
        'Legacy child activity creation is not implemented. '
        'Use authenticated child login instead.',
      );
    }

    final currentFamilyId = await _getCurrentFamilyId();

    if (currentFamilyId == null || activity.familyId != currentFamilyId) {
      throw Exception(
        'Cannot add activity because the activity family does not match the '
        'current active profile family.',
      );
    }

    try {
      await _insertActivityOnline(activity);

      await _localCache.upsertCachedActivities([activity]);
      await _localCache.removePendingActivity(activity.id);

      debugPrint(
        'SupabaseActivityRepository: addActivity completed online via RPC',
      );
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

    final participantRows = activity.participants
        .map((participant) => participant.toDatabaseRow(activity.id))
        .toList();

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
      'SupabaseActivityRepository: activity RPC row = $activityRow',
    );
    debugPrint(
      'SupabaseActivityRepository: participant RPC rows = $participantRows',
    );
    debugPrint(
      'SupabaseActivityRepository: checklist RPC rows = $checklistRows',
    );

    final createdActivityId = await _client.rpc(
      'create_activity_with_relations',
      params: {
        'p_activity': activityRow,
        'p_participants': participantRows,
        'p_checklist_items': checklistRows,
      },
    );

    debugPrint(
      'SupabaseActivityRepository: create_activity_with_relations completed '
      'id=$createdActivityId',
    );
  }

  Future<void> _updateActivityOnline(Activity activity) async {
    final activityRow = activity.toActivityRow();

    final participantRows = activity.participants
        .map((p) => p.toDatabaseRow(activity.id))
        .toList();

    final checklistRows = activity.checklistItems.map((item) {
      final row = Map<String, dynamic>.from(item.toDatabaseRow(activity.id));
      row.remove('id');
      return row;
    }).toList();

    await _client.rpc(
      'update_activity_with_relations',
      params: {
        'p_activity': activityRow,
        'p_participants': participantRows,
        'p_checklist_items': checklistRows,
      },
    );
  }

  Future<void> _trySyncPendingActivities({
    required String familyId,
  }) async {
    if (_isChildSession) {
      debugPrint(
        'SupabaseActivityRepository: legacy child session, skipping pending '
        'activity sync',
      );
      return;
    }

    await _syncPendingCreates(familyId: familyId);
    await _syncPendingUpdates(familyId: familyId);
    await _syncPendingDeletes(familyId: familyId);
    await _syncPendingCompletions();
    await _syncPendingChecklistChecks();
  }

  Future<void> _syncPendingDeletes({required String familyId}) async {
    final pendingDeletes = await _localCache.getPendingDeletes();

    if (pendingDeletes.isEmpty) return;

    debugPrint(
      'SupabaseActivityRepository: syncing ${pendingDeletes.length} pending '
      'deletes for family=$familyId',
    );

    for (final activityId in List<String>.from(pendingDeletes)) {
      try {
        await _client
            .from('activities')
            .delete()
            .eq('id', activityId)
            .eq('family_id', familyId);

        await _localCache.removePendingDelete(activityId);

        debugPrint(
          'SupabaseActivityRepository: synced pending delete id=$activityId',
        );
      } catch (e) {
        if (_isNetworkException(e)) {
          debugPrint(
            'SupabaseActivityRepository: still offline, pending delete sync stopped',
          );
          return;
        }
        // Ignore other errors (activity may already be gone) and clear the entry.
        await _localCache.removePendingDelete(activityId);
      }
    }
  }

  Future<void> _syncPendingCompletions() async {
    final pendingCompletions = await _localCache.getPendingCompletions();

    if (pendingCompletions.isEmpty) return;

    debugPrint(
      'SupabaseActivityRepository: syncing ${pendingCompletions.length} '
      'pending completions',
    );

    for (final entry in Map<String, bool>.from(pendingCompletions).entries) {
      try {
        await _client.rpc(
          'set_activity_completed',
          params: {
            'input_activity_id': entry.key,
            'input_is_completed': entry.value,
          },
        );

        await _localCache.removePendingCompletion(entry.key);

        debugPrint(
          'SupabaseActivityRepository: synced pending completion id=${entry.key}',
        );
      } catch (e) {
        if (_isNetworkException(e)) {
          debugPrint(
            'SupabaseActivityRepository: still offline, completion sync stopped',
          );
          return;
        }
        await _localCache.removePendingCompletion(entry.key);
      }
    }
  }

  Future<void> _syncPendingChecklistChecks() async {
    final pendingChecks = await _localCache.getPendingChecklistChecks();

    if (pendingChecks.isEmpty) return;

    debugPrint(
      'SupabaseActivityRepository: syncing ${pendingChecks.length} '
      'pending checklist checks',
    );

    for (final entry in Map<String, bool>.from(pendingChecks).entries) {
      try {
        await _client.rpc(
          'set_checklist_item_checked',
          params: {
            'input_checklist_item_id': entry.key,
            'input_is_checked': entry.value,
          },
        );

        await _localCache.removePendingChecklistCheck(entry.key);

        debugPrint(
          'SupabaseActivityRepository: synced pending checklist check '
          'id=${entry.key}',
        );
      } catch (e) {
        if (_isNetworkException(e)) {
          debugPrint(
            'SupabaseActivityRepository: still offline, checklist check sync stopped',
          );
          return;
        }
        await _localCache.removePendingChecklistCheck(entry.key);
      }
    }
  }

  Future<void> _syncPendingCreates({required String familyId}) async {
    final pendingActivities = await _localCache.getPendingActivities();

    final safe = pendingActivities
        .where((activity) => activity.familyId == familyId)
        .toList();

    if (safe.isEmpty) return;

    debugPrint(
      'SupabaseActivityRepository: syncing ${safe.length} pending creates '
      'for family=$familyId',
    );

    for (final activity in safe) {
      try {
        await _insertActivityOnline(activity);
        await _localCache.removePendingActivity(activity.id);
        await _localCache.upsertCachedActivities([activity]);

        debugPrint(
          'SupabaseActivityRepository: synced pending create id=${activity.id}',
        );
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          // Already exists online — treat as synced.
          await _localCache.removePendingActivity(activity.id);
          await _localCache.upsertCachedActivities([activity]);
          continue;
        }
        rethrow;
      } catch (e) {
        if (_isNetworkException(e)) {
          debugPrint(
            'SupabaseActivityRepository: still offline, pending create sync stopped',
          );
          return;
        }
        rethrow;
      }
    }
  }

  Future<void> _syncPendingUpdates({required String familyId}) async {
    final pendingUpdates = await _localCache.getPendingUpdateActivities();

    final safe = pendingUpdates
        .where((activity) => activity.familyId == familyId)
        .toList();

    if (safe.isEmpty) return;

    debugPrint(
      'SupabaseActivityRepository: syncing ${safe.length} pending updates '
      'for family=$familyId',
    );

    for (final activity in safe) {
      try {
        await _updateActivityOnline(activity);

        await _localCache.removePendingUpdateActivity(activity.id);
        await _localCache.upsertCachedActivities([activity]);

        debugPrint(
          'SupabaseActivityRepository: synced pending update id=${activity.id}',
        );
      } catch (e) {
        if (_isNetworkException(e)) {
          debugPrint(
            'SupabaseActivityRepository: still offline, pending update sync stopped',
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
        'Legacy child activity update is not implemented. '
        'Use authenticated child login instead.',
      );
    }

    final currentFamilyId = await _getCurrentFamilyId();

    if (currentFamilyId == null || activity.familyId != currentFamilyId) {
      throw Exception(
        'Cannot update activity because the activity family does not match '
        'the current active profile family.',
      );
    }

    debugPrint(
      'SupabaseActivityRepository: updating activity id=${activity.id}',
    );

    try {
      await _updateActivityOnline(activity);

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
        await _localCache.upsertPendingUpdateActivity(activity);
        await _localCache.upsertCachedActivities([activity]);

        debugPrint(
          'SupabaseActivityRepository: updated activity saved locally as '
          'pending update',
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
        'Legacy child activity deletion is not allowed from child session.',
      );
    }

    final currentFamilyId = await _getCurrentFamilyId();

    if (currentFamilyId == null) {
      throw Exception(
        'Cannot delete activity because no active profile family was found.',
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
        await _localCache.addPendingDelete(activityId);

        debugPrint(
          'SupabaseActivityRepository: queued delete offline activityId=$activityId',
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

    // CS-3: fetch participants and checklist items in parallel
    final results = await Future.wait([
      _client
          .from('activity_participants')
          .select()
          .inFilter('activity_id', activityIds),
      _client
          .from('checklist_items')
          .select()
          .inFilter('activity_id', activityIds)
          .order('position'),
    ]);

    final participantRows = results[0];
    final checklistRows = results[1];

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