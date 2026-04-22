enum ProfileRole { parent, child }

ProfileRole profileRoleFromString(String value) {
  switch (value) {
    case 'parent':
      return ProfileRole.parent;
    case 'child':
      return ProfileRole.child;
    default:
      throw ArgumentError('Unknown profile role: $value');
  }
}

String profileRoleToString(ProfileRole role) {
  switch (role) {
    case ProfileRole.parent:
      return 'parent';
    case ProfileRole.child:
      return 'child';
  }
}

class Profile {
  final String id;
  final String familyId;
  final String? authUserId;
  final String name;
  final String displayName;
  final String emoji;
  final ProfileRole role;
  final String? childLoginCode;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Profile({
    required this.id,
    required this.familyId,
    required this.authUserId,
    required this.name,
    required this.displayName,
    required this.emoji,
    required this.role,
    required this.childLoginCode,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      familyId: map['family_id'] as String,
      authUserId: map['auth_user_id'] as String?,
      name: map['name'] as String,
      displayName: map['display_name'] as String,
      emoji: (map['emoji'] as String?) ?? '🙂',
      role: profileRoleFromString(map['role'] as String),
      childLoginCode: map['child_login_code'] as String?,
      isActive: (map['is_active'] as bool?) ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'family_id': familyId,
      'auth_user_id': authUserId,
      'name': name,
      'display_name': displayName,
      'emoji': emoji,
      'role': profileRoleToString(role),
      'child_login_code': childLoginCode,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}