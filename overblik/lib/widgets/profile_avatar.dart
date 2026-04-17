import 'package:flutter/material.dart';

import '../screens/profile_screen.dart';
import '../services/profile_service.dart';

class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({super.key});

  @override
  Widget build(BuildContext context) {
    final profileService = ProfileService();
    final currentProfile = profileService.getProfileById('profile-me');

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        if (currentProfile == null) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(
              profile: currentProfile,
              familyMembers: profileService
                  .getAllProfiles()
                  .map((profile) => profile.name)
                  .toList(),
            ),
          ),
        );
      },
      child: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.white,
        child: currentProfile != null
            ? Text(
                currentProfile.emoji,
                style: const TextStyle(fontSize: 20),
              )
            : Icon(
                Icons.person,
                color: Colors.grey.shade700,
              ),
      ),
    );
  }
}