enum ProfileRole {
  child,
  parent,
}

class Profile {
  final String id;
  final String name;
  final String emoji;
  final ProfileRole role;

  const Profile({
    required this.id,
    required this.name,
    required this.emoji,
    required this.role,
  });

  Profile copyWith({
    String? id,
    String? name,
    String? emoji,
    ProfileRole? role,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'role': role.name,
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      name: map['name'] as String,
      emoji: map['emoji'] as String? ?? '🙂',
      role: ProfileRole.values.firstWhere(
        (role) => role.name == map['role'],
        orElse: () => ProfileRole.child,
      ),
    );
  }
}