import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/activity.dart';
import 'activity_repository.dart';

class SupabaseActivityRepository implements ActivityRepository {
  final SupabaseClient _client;

  SupabaseActivityRepository(this._client);

  Future<String?> _getCurrentFamilyId() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final profile = await _client
        .from('profiles')
        .select('family_id')
        .eq('auth_user_id', user.id)
        .eq('role', 'parent')
        .maybeSingle();

    if (profile == null) return null;
    return profile['family_id'] as String?;
  }

  @override
  Future<List<Activity>> getActivitiesForDate(DateTime date) async {
    final familyId = await _getCurrentFamilyId();
    if (familyId == null) return [];

    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final activityRows = await _client
        .from('activities')
        .select()
        .eq('family_id', familyId)
        .gte('start_time', start.toIso8601String())
        .lt('start_time', end.toIso8601String())
        .order('start_time');

    return _buildActivitiesFromRows(
      List<Map<String, dynamic>>.from(activityRows),
    );
  }

  @override
  Future<List<Activity>> getActivitiesForWeek(DateTime focusedDate) async {
    final familyId = await _getCurrentFamilyId();
    if (familyId == null) return [];

    final startOfWeek = DateTime(
      focusedDate.year,
      focusedDate.month,
      focusedDate.day,
    ).subtract(Duration(days: focusedDate.weekday - 1));

    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final activityRows = await _client
        .from('activities')
        .select()
        .eq('family_id', familyId)
        .gte('start_time', startOfWeek.toIso8601String())
        .lt('start_time', endOfWeek.toIso8601String())
        .order('start_time');

    return _buildActivitiesFromRows(
      List<Map<String, dynamic>>.from(activityRows),
    );
  }

  @override
  Future<Activity?> getActivityById(String id) async {
    final rows = await _client
        .from('activities')
        .select()
        .eq('id', id)
        .limit(1);

    if (rows.isEmpty) {
      return null;
    }

    final activities = await _buildActivitiesFromRows(
      List<Map<String, dynamic>>.from(rows),
    );

    if (activities.isEmpty) {
      return null;
    }

    return activities.first;
  }

  @override
  Future<void> addActivity(Activity activity) async {
    await _client.from('activities').insert(activity.toActivityRow());

    if (activity.participants.isNotEmpty) {
      await _client.from('activity_participants').insert(
        activity.participants
            .map((participant) => participant.toDatabaseRow(activity.id))
            .toList(),
      );
    }

    if (activity.checklistItems.isNotEmpty) {
      await _client.from('checklist_items').insert(
        activity.checklistItems
            .map((item) => item.toDatabaseRow(activity.id))
            .toList(),
      );
    }
  }

  @override
  Future<void> updateActivity(Activity activity) async {
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
      await _client.from('checklist_items').insert(
        activity.checklistItems
            .map((item) => item.toDatabaseRow(activity.id))
            .toList(),
      );
    }
  }

  @override
  Future<void> deleteActivity(String activityId) async {
    await _client.from('activities').delete().eq('id', activityId);
  }

  Future<List<Activity>> _buildActivitiesFromRows(
    List<Map<String, dynamic>> activityRows,
  ) async {
    if (activityRows.isEmpty) {
      return [];
    }

    final activityIds = activityRows.map((row) => row['id'] as String).toList();

    final participantRows = await _client
        .from('activity_participants')
        .select()
        .inFilter('activity_id', activityIds);

    final checklistRows = await _client
        .from('checklist_items')
        .select()
        .inFilter('activity_id', activityIds)
        .order('position');

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