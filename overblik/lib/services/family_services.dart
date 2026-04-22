import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class FamilyRecord {
  final String id;
  final String familyName;
  final String familyCode;
  final String? createdBy;

  FamilyRecord({
    required this.id,
    required this.familyName,
    required this.familyCode,
    required this.createdBy,
  });

  factory FamilyRecord.fromMap(Map<String, dynamic> map) {
    return FamilyRecord(
      id: map['id'] as String,
      familyName: map['family_name'] as String,
      familyCode: map['family_code'] as String,
      createdBy: map['created_by'] as String?,
    );
  }
}

class FamilyBootstrapResult {
  final FamilyRecord family;
  final Map<String, dynamic> parentProfile;

  FamilyBootstrapResult({
    required this.family,
    required this.parentProfile,
  });
}

class FamilyService {
  FamilyService._();
  static final FamilyService instance = FamilyService._();

  final SupabaseClient _client = Supabase.instance.client;
  final Random _random = Random.secure();

  static const String _familyCodeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String _generateLocalFamilyCode({int length = 6}) {
    return List.generate(
      length,
      (_) => _familyCodeChars[_random.nextInt(_familyCodeChars.length)],
    ).join();
  }

  Future<String> generateUniqueFamilyCode() async {
    while (true) {
      final code = _generateLocalFamilyCode();
      final existing = await _client
          .from('families')
          .select('id')
          .eq('family_code', code)
          .maybeSingle();

      if (existing == null) return code;
    }
  }

  Future<FamilyRecord> createFamily({
    required String familyName,
    required String createdBy,
  }) async {
    final familyCode = await generateUniqueFamilyCode();

    final inserted = await _client
        .from('families')
        .insert({
          'family_name': familyName.trim(),
          'family_code': familyCode,
          'created_by': createdBy,
        })
        .select()
        .single();

    return FamilyRecord.fromMap(inserted);
  }

  Future<FamilyBootstrapResult> createFamilyAndParentProfile({
    required String familyName,
    required String authUserId,
    required String parentName,
    String emoji = '🙂',
  }) async {
    final family = await createFamily(
      familyName: familyName,
      createdBy: authUserId,
    );

    final parentProfile = await _client
        .from('profiles')
        .insert({
          'family_id': family.id,
          'auth_user_id': authUserId,
          'name': parentName.trim(),
          'display_name': parentName.trim(),
          'emoji': emoji,
          'role': 'parent',
        })
        .select()
        .single();

    return FamilyBootstrapResult(
      family: family,
      parentProfile: parentProfile,
    );
  }

  Future<FamilyRecord?> getFamilyById(String familyId) async {
    final result = await _client
        .from('families')
        .select()
        .eq('id', familyId)
        .maybeSingle();

    if (result == null) return null;
    return FamilyRecord.fromMap(result);
  }
}