import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class ChildLoginResult {
  final String profileId;
  final String familyId;
  final String name;
  final String displayName;
  final String emoji;
  final ProfileRole role;

  const ChildLoginResult({
    required this.profileId,
    required this.familyId,
    required this.name,
    required this.displayName,
    required this.emoji,
    required this.role,
  });

  factory ChildLoginResult.fromMap(Map<String, dynamic> map) {
    return ChildLoginResult(
      profileId: map['profile_id'] as String,
      familyId: map['family_id'] as String,
      name: map['name'] as String,
      displayName: map['display_name'] as String,
      emoji: (map['emoji'] as String?) ?? '🙂',
      role: profileRoleFromString(map['role'] as String),
    );
  }
}

class ProfileService {
  ProfileService._internal();

  static final ProfileService _instance = ProfileService._internal();

  factory ProfileService() => _instance;

  final SupabaseClient _client = Supabase.instance.client;

  Map<String, dynamic> _asMap(dynamic value, {String? errorContext}) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    throw Exception(
      errorContext == null
          ? 'Unexpected response shape'
          : 'Unexpected response shape in $errorContext',
    );
  }

  Future<Profile?> getMyParentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final result = await _client
        .from('profiles')
        .select()
        .eq('auth_user_id', user.id)
        .eq('role', 'parent')
        .maybeSingle();

    if (result == null) return null;

    return Profile.fromMap(
      _asMap(result, errorContext: 'getMyParentProfile'),
    );
  }

  Future<List<Profile>> getFamilyProfiles(String familyId) async {
    final result = await _client
        .from('profiles')
        .select()
        .eq('family_id', familyId)
        .order('created_at', ascending: true);

    return (result as List)
        .map(
          (row) => Profile.fromMap(
            _asMap(row, errorContext: 'getFamilyProfiles'),
          ),
        )
        .toList();
  }

  Future<List<Profile>> getMyFamilyProfiles() async {
    final currentProfile = await getMyParentProfile();
    if (currentProfile == null) return [];

    return await getFamilyProfiles(currentProfile.familyId);
  }

  Future<List<String>> getMyFamilyMemberNames() async {
    final profiles = await getMyFamilyProfiles();
    return profiles.map((profile) => profile.name).toList();
  }

  Future<List<Profile>> getChildProfiles(String familyId) async {
    final result = await _client
        .from('profiles')
        .select()
        .eq('family_id', familyId)
        .eq('role', 'child')
        .order('created_at', ascending: true);

    return (result as List)
        .map(
          (row) => Profile.fromMap(
            _asMap(row, errorContext: 'getChildProfiles'),
          ),
        )
        .toList();
  }

  Future<List<Profile>> getParentProfiles(String familyId) async {
    final result = await _client
        .from('profiles')
        .select()
        .eq('family_id', familyId)
        .eq('role', 'parent')
        .order('created_at', ascending: true);

    return (result as List)
        .map(
          (row) => Profile.fromMap(
            _asMap(row, errorContext: 'getParentProfiles'),
          ),
        )
        .toList();
  }

  Future<Profile?> getProfileById(String profileId) async {
    final result = await _client
        .from('profiles')
        .select()
        .eq('id', profileId)
        .maybeSingle();

    if (result == null) return null;

    return Profile.fromMap(
      _asMap(result, errorContext: 'getProfileById'),
    );
  }

  Future<Profile> createParentProfile({
    required String familyId,
    required String authUserId,
    required String name,
    String? displayName,
    String emoji = '🙂',
  }) async {
    final result = await _client
        .from('profiles')
        .insert({
          'family_id': familyId,
          'auth_user_id': authUserId,
          'name': name.trim(),
          'display_name': (displayName == null || displayName.trim().isEmpty)
              ? name.trim()
              : displayName.trim(),
          'emoji': emoji,
          'role': 'parent',
        })
        .select()
        .single();

    return Profile.fromMap(
      _asMap(result, errorContext: 'createParentProfile'),
    );
  }

  Future<Profile> createChildProfile({
    required String familyId,
    required String name,
    String? displayName,
    String emoji = '🧒',
  }) async {
    final result = await _client.rpc(
      'create_child_profile',
      params: {
        'p_family_id': familyId,
        'p_name': name.trim(),
        'p_display_name': (displayName == null || displayName.trim().isEmpty)
            ? null
            : displayName.trim(),
        'p_emoji': emoji,
      },
    );

    if (result is List && result.isNotEmpty) {
      return Profile.fromMap(
        _asMap(result.first, errorContext: 'createChildProfile'),
      );
    }

    return Profile.fromMap(
      _asMap(result, errorContext: 'createChildProfile'),
    );
  }

  Future<Profile> updateProfile({
    required String profileId,
    String? name,
    String? displayName,
    String? emoji,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name.trim();
    if (displayName != null) updates['display_name'] = displayName.trim();
    if (emoji != null) updates['emoji'] = emoji;
    if (isActive != null) updates['is_active'] = isActive;

    final result = await _client
        .from('profiles')
        .update(updates)
        .eq('id', profileId)
        .select()
        .single();

    return Profile.fromMap(
      _asMap(result, errorContext: 'updateProfile'),
    );
  }

  Future<void> deleteProfile(String profileId) async {
    await _client.from('profiles').delete().eq('id', profileId);
  }

  Future<String> resetChildCode(String profileId) async {
    final result = await _client.rpc(
      'reset_child_login_code',
      params: {
        'p_profile_id': profileId,
      },
    );

    if (result is String) return result;

    throw Exception('Unexpected response from reset_child_login_code');
  }

  Future<ChildLoginResult?> loginChildWithCode({
    required String familyCode,
    required String childCode,
  }) async {
    final result = await _client.rpc(
      'get_child_by_family_and_code',
      params: {
        'p_family_code': familyCode.trim(),
        'p_child_code': childCode.trim(),
      },
    );

    if (result is List && result.isNotEmpty) {
      return ChildLoginResult.fromMap(
        _asMap(result.first, errorContext: 'loginChildWithCode'),
      );
    }

    return null;
  }
}