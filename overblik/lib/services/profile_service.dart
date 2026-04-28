import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static const String _cachedParentProfilePrefix = 'cached_parent_profile_';
  static const String _cachedFamilyProfilesPrefix = 'cached_family_profiles_';

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

  String? _currentUserId() {
    return _client.auth.currentUser?.id;
  }

  Future<void> _cacheParentProfile(String authUserId, Profile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_cachedParentProfilePrefix$authUserId';

      await prefs.setString(
        key,
        jsonEncode(profile.toMap()),
      );

      debugPrint('ProfileService: cached parent profile for user=$authUserId');
    } catch (e, st) {
      debugPrint('ProfileService: failed to cache parent profile: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<Profile?> _getCachedParentProfile(String authUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_cachedParentProfilePrefix$authUserId';
      final raw = prefs.getString(key);

      if (raw == null || raw.trim().isEmpty) {
        debugPrint('ProfileService: no cached parent profile found');
        return null;
      }

      final decoded = jsonDecode(raw);
      final profile = Profile.fromMap(
        _asMap(decoded, errorContext: '_getCachedParentProfile'),
      );

      debugPrint('ProfileService: loaded cached parent profile');
      return profile;
    } catch (e, st) {
      debugPrint('ProfileService: failed to read cached parent profile: $e');
      debugPrintStack(stackTrace: st);
      return null;
    }
  }

  Future<void> _cacheFamilyProfiles(
    String familyId,
    List<Profile> profiles,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_cachedFamilyProfilesPrefix$familyId';

      await prefs.setString(
        key,
        jsonEncode(
          profiles.map((profile) => profile.toMap()).toList(),
        ),
      );

      debugPrint(
        'ProfileService: cached ${profiles.length} family profiles for family=$familyId',
      );
    } catch (e, st) {
      debugPrint('ProfileService: failed to cache family profiles: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<List<Profile>> _getCachedFamilyProfiles(String familyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_cachedFamilyProfilesPrefix$familyId';
      final raw = prefs.getString(key);

      if (raw == null || raw.trim().isEmpty) {
        debugPrint('ProfileService: no cached family profiles found');
        return [];
      }

      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        debugPrint('ProfileService: cached family profiles had wrong shape');
        return [];
      }

      final profiles = decoded
          .map(
            (row) => Profile.fromMap(
              _asMap(row, errorContext: '_getCachedFamilyProfiles'),
            ),
          )
          .toList();

      debugPrint(
        'ProfileService: loaded ${profiles.length} cached family profiles',
      );

      return profiles;
    } catch (e, st) {
      debugPrint('ProfileService: failed to read cached family profiles: $e');
      debugPrintStack(stackTrace: st);
      return [];
    }
  }

  Future<Profile?> getMyParentProfile() async {
    final userId = _currentUserId();

    if (userId == null) {
      debugPrint('ProfileService: no current user for getMyParentProfile');
      return null;
    }

    try {
      final result = await _client
          .from('profiles')
          .select()
          .eq('auth_user_id', userId)
          .eq('role', profileRoleToString(ProfileRole.parent))
          .maybeSingle();

      if (result == null) {
        debugPrint('ProfileService: no parent profile found online');
        return await _getCachedParentProfile(userId);
      }

      final profile = Profile.fromMap(
        _asMap(result, errorContext: 'getMyParentProfile'),
      );

      await _cacheParentProfile(userId, profile);

      return profile;
    } catch (e, st) {
      debugPrint('ProfileService: getMyParentProfile online failed: $e');
      debugPrintStack(stackTrace: st);

      return await _getCachedParentProfile(userId);
    }
  }

  Future<List<Profile>> getFamilyProfiles(String familyId) async {
    try {
      final result = await _client
          .from('profiles')
          .select()
          .eq('family_id', familyId)
          .order('created_at', ascending: true);

      final profiles = (result as List)
          .map(
            (row) => Profile.fromMap(
              _asMap(row, errorContext: 'getFamilyProfiles'),
            ),
          )
          .toList();

      await _cacheFamilyProfiles(familyId, profiles);

      return profiles;
    } catch (e, st) {
      debugPrint('ProfileService: getFamilyProfiles online failed: $e');
      debugPrintStack(stackTrace: st);

      return await _getCachedFamilyProfiles(familyId);
    }
  }

  Future<List<Profile>> getMyFamilyProfiles() async {
    final currentProfile = await getMyParentProfile();

    if (currentProfile == null) {
      debugPrint('ProfileService: no parent profile for getMyFamilyProfiles');
      return [];
    }

    return await getFamilyProfiles(currentProfile.familyId);
  }

  Future<List<String>> getMyFamilyMemberNames() async {
    final profiles = await getMyFamilyProfiles();
    return profiles.map((profile) => profile.name).toList();
  }

  Future<List<Profile>> getChildProfiles(String familyId) async {
    final profiles = await getFamilyProfiles(familyId);

    return profiles.where((profile) => profile.isChild).toList();
  }

  Future<List<Profile>> getParentProfiles(String familyId) async {
    final profiles = await getFamilyProfiles(familyId);

    return profiles
        .where((profile) => profile.role == ProfileRole.parent)
        .toList();
  }

  Future<Profile?> getProfileById(String profileId) async {
    try {
      final result = await _client
          .from('profiles')
          .select()
          .eq('id', profileId)
          .maybeSingle();

      if (result == null) {
        final familyProfiles = await getMyFamilyProfiles();

        for (final profile in familyProfiles) {
          if (profile.id == profileId) {
            return profile;
          }
        }

        return null;
      }

      return Profile.fromMap(
        _asMap(result, errorContext: 'getProfileById'),
      );
    } catch (e, st) {
      debugPrint('ProfileService: getProfileById online failed: $e');
      debugPrintStack(stackTrace: st);

      final familyProfiles = await getMyFamilyProfiles();

      for (final profile in familyProfiles) {
        if (profile.id == profileId) {
          return profile;
        }
      }

      return null;
    }
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
          'role': profileRoleToString(ProfileRole.parent),
        })
        .select()
        .single();

    final profile = Profile.fromMap(
      _asMap(result, errorContext: 'createParentProfile'),
    );

    await _cacheParentProfile(authUserId, profile);

    final cachedFamilyProfiles = await _getCachedFamilyProfiles(familyId);
    final updatedProfiles = [
      ...cachedFamilyProfiles.where((p) => p.id != profile.id),
      profile,
    ];

    await _cacheFamilyProfiles(familyId, updatedProfiles);

    return profile;
  }

  Future<Profile> createChildProfile({
    required String familyId,
    required String name,
    String? displayName,
    String emoji = '🧒',
    ProfileRole role = ProfileRole.childLimited,
  }) async {
    if (role == ProfileRole.parent) {
      throw ArgumentError('createChildProfile cannot create a parent profile.');
    }

    final result = await _client.rpc(
      'create_child_profile',
      params: {
        'p_family_id': familyId,
        'p_name': name.trim(),
        'p_display_name': (displayName == null || displayName.trim().isEmpty)
            ? null
            : displayName.trim(),
        'p_emoji': emoji,
        'p_role': profileRoleToString(role),
      },
    );

    final Profile profile;

    if (result is List && result.isNotEmpty) {
      profile = Profile.fromMap(
        _asMap(result.first, errorContext: 'createChildProfile'),
      );
    } else {
      profile = Profile.fromMap(
        _asMap(result, errorContext: 'createChildProfile'),
      );
    }

    final cachedFamilyProfiles = await _getCachedFamilyProfiles(familyId);
    final updatedProfiles = [
      ...cachedFamilyProfiles.where((p) => p.id != profile.id),
      profile,
    ];

    await _cacheFamilyProfiles(familyId, updatedProfiles);

    return profile;
  }

  Future<Profile> updateProfile({
    required String profileId,
    String? name,
    String? displayName,
    String? emoji,
    ProfileRole? role,
    bool? isActive,
  }) async {
    if (role == ProfileRole.parent) {
      throw ArgumentError(
        'updateProfile should not promote a child profile to parent.',
      );
    }

    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name.trim();
    if (displayName != null) updates['display_name'] = displayName.trim();
    if (emoji != null) updates['emoji'] = emoji;
    if (role != null) updates['role'] = profileRoleToString(role);
    if (isActive != null) updates['is_active'] = isActive;

    if (updates.isEmpty) {
      final existingProfile = await getProfileById(profileId);
      if (existingProfile == null) {
        throw Exception('Profile not found: $profileId');
      }
      return existingProfile;
    }

    final result = await _client
        .from('profiles')
        .update(updates)
        .eq('id', profileId)
        .select()
        .single();

    final profile = Profile.fromMap(
      _asMap(result, errorContext: 'updateProfile'),
    );

    final cachedFamilyProfiles =
        await _getCachedFamilyProfiles(profile.familyId);
    final updatedProfiles = [
      ...cachedFamilyProfiles.where((p) => p.id != profile.id),
      profile,
    ];

    await _cacheFamilyProfiles(profile.familyId, updatedProfiles);

    final userId = _currentUserId();
    if (userId != null && profile.authUserId == userId) {
      await _cacheParentProfile(userId, profile);
    }

    return profile;
  }

  Future<void> deleteProfile(String profileId) async {
    await _client.from('profiles').delete().eq('id', profileId);

    final profiles = await getMyFamilyProfiles();

    if (profiles.isEmpty) return;

    final familyId = profiles.first.familyId;
    final updatedProfiles =
        profiles.where((profile) => profile.id != profileId).toList();

    await _cacheFamilyProfiles(familyId, updatedProfiles);
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