import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../screens/profile_screen.dart';
import '../services/profile_service.dart';

class ProfileAvatarButton extends StatefulWidget {
  const ProfileAvatarButton({super.key});

  @override
  State<ProfileAvatarButton> createState() => _ProfileAvatarButtonState();
}

class _ProfileAvatarButtonState extends State<ProfileAvatarButton> {
  late final Future<Profile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = ProfileService().getCurrentAuthenticatedProfile();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<Profile?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final currentProfile = snapshot.data;

        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: currentProfile == null
              ? null
              : currentProfile.isChild
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profilsiden er ikke tilgængelig for børn.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              : () async {
                  final familyProfiles = await ProfileService()
                      .getFamilyProfiles(currentProfile.familyId);

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
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2A2D2C)
                    : colorScheme.primary.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: isDark
                  ? const Color(0xFF171A19)
                  : Colors.white,
              child: currentProfile != null
                  ? Text(
                      currentProfile.emoji,
                      style: const TextStyle(fontSize: 20),
                    )
                  : Icon(
                      Icons.person,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
            ),
          ),
        );
      },
    );
  }
}
