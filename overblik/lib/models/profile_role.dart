enum ProfileRole {
  parent,
  childExtended,
  childLimited,
}

extension ProfileRoleParser on ProfileRole {
  static ProfileRole fromString(String value) {
    switch (value) {
      case 'parent':
        return ProfileRole.parent;
      case 'child_extended':
        return ProfileRole.childExtended;
      case 'child_limited':
        return ProfileRole.childLimited;
      default:
        throw Exception('Unknown profile role: $value');
    }
  }

  String get dbValue {
    switch (this) {
      case ProfileRole.parent:
        return 'parent';
      case ProfileRole.childExtended:
        return 'child_extended';
      case ProfileRole.childLimited:
        return 'child_limited';
    }
  }
}