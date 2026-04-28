import '../models/profile.dart';

class Permissions {
  static bool canViewOwnActivities(ProfileRole role) {
    return true;
  }

  static bool canViewFamilyActivities(ProfileRole role) {
    return true;
  }

  static bool canCreateActivity(ProfileRole role) {
    return role == ProfileRole.parent ||
        role == ProfileRole.childExtended;
  }

  static bool canEditActivity({
    required ProfileRole role,
    required bool ownsActivity,
  }) {
    if (role == ProfileRole.parent) return true;

    if (role == ProfileRole.childExtended && ownsActivity) {
      return true;
    }

    return false;
  }

  static bool canDeleteActivity({
    required ProfileRole role,
    required bool ownsActivity,
  }) {
    if (role == ProfileRole.parent) return true;

    if (role == ProfileRole.childExtended && ownsActivity) {
      return true;
    }

    return false;
  }

  static bool canEditChildActivity(ProfileRole role) {
    return role == ProfileRole.parent;
  }

  static bool canMarkActivityCompleted(ProfileRole role) {
    return true;
  }

  static bool canEditChecklistStructure({
    required ProfileRole role,
    required bool ownsActivity,
  }) {
    if (role == ProfileRole.parent) return true;

    if (role == ProfileRole.childExtended && ownsActivity) {
      return true;
    }

    return false;
  }

  static bool canCheckOrUncheckChecklistItem(ProfileRole role) {
    return true;
  }

  static bool canManageProfiles(ProfileRole role) {
    return role == ProfileRole.parent;
  }

  static bool canManageRewards(ProfileRole role) {
    return role == ProfileRole.parent;
  }

  static bool canChangeFamilySettings(ProfileRole role) {
    return role == ProfileRole.parent;
  }
}