import '../models/profile.dart';

class ProfileService {
  ProfileService._internal();

  static final ProfileService _instance = ProfileService._internal();

  factory ProfileService() => _instance;

  final List<Profile> _profiles = [
    const Profile(
      id: 'profile-me',
      name: 'Mig',
      emoji: '🙂',
      role: ProfileRole.child,
    ),
    const Profile(
      id: 'profile-mor',
      name: 'Mor',
      emoji: '👩',
      role: ProfileRole.parent,
    ),
    const Profile(
      id: 'profile-far',
      name: 'Far',
      emoji: '👨',
      role: ProfileRole.parent,
    ),
    const Profile(
      id: 'profile-peter',
      name: 'Peter',
      emoji: '🧒',
      role: ProfileRole.child,
    ),
  ];

  List<Profile> getAllProfiles() {
    return List<Profile>.from(_profiles);
  }

  List<Profile> getChildProfiles() {
    return _profiles
        .where((profile) => profile.role == ProfileRole.child)
        .toList();
  }

  List<Profile> getParentProfiles() {
    return _profiles
        .where((profile) => profile.role == ProfileRole.parent)
        .toList();
  }

  Profile? getProfileById(String id) {
    try {
      return _profiles.firstWhere((profile) => profile.id == id);
    } catch (_) {
      return null;
    }
  }

  Profile? getProfileByName(String name) {
    try {
      return _profiles.firstWhere((profile) => profile.name == name);
    } catch (_) {
      return null;
    }
  }

  void addProfile(Profile profile) {
    _profiles.add(profile);
  }

  void updateProfile(Profile updatedProfile) {
    final index = _profiles.indexWhere((profile) => profile.id == updatedProfile.id);

    if (index == -1) {
      return;
    }

    _profiles[index] = updatedProfile;
  }

  void deleteProfile(String profileId) {
    _profiles.removeWhere((profile) => profile.id == profileId);
  }
}