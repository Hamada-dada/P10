import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../screens/profile_screen.dart';
import '../services/profile_service.dart';

class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({super.key});

  @override
  Widget build(BuildContext context) {
    final profileService = ProfileService();

    return FutureBuilder<Profile?>(
      future: profileService.getCurrentAuthenticatedProfile(),
      builder: (context, snapshot) {
        final currentProfile = snapshot.data;

        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: currentProfile == null || currentProfile.isChild
              ? null
              : () async {
                  final familyProfiles = await profileService.getFamilyProfiles(
                    currentProfile.familyId,
                  );

                  if (!context.mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(
                        profile: currentProfile,
                        familyMembers: familyProfiles
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
      },
    );
  }
}