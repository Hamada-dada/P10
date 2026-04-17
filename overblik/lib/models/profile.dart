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
}