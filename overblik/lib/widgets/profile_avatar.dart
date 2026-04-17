import 'package:flutter/material.dart';

import '../screens/profile_screen.dart';

class ProfileAvatarButton extends StatelessWidget {
  final double radius;
  final String name;
  final String roleLabel;
  final String emoji;
  final List<String> familyMembers;
  final Color backgroundColor;
  final Color iconColor;
  final bool useEmoji;
  final VoidCallback? onBeforeNavigate;

  const ProfileAvatarButton({
    super.key,
    this.radius = 22,
    this.name = 'Mig',
    this.roleLabel = 'Barn',
    this.emoji = '🙂',
    this.familyMembers = const ['Mig', 'Mor', 'Far'],
    this.backgroundColor = Colors.white,
    this.iconColor = Colors.black54,
    this.useEmoji = false,
    this.onBeforeNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius + 8),
        onTap: () {
          onBeforeNavigate?.call();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileScreen(
                name: name,
                roleLabel: roleLabel,
                emoji: emoji,
                familyMembers: familyMembers,
              ),
            ),
          );
        },
        child: CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor,
          child: useEmoji
              ? Text(
                  emoji,
                  style: TextStyle(fontSize: radius * 0.9),
                )
              : Icon(
                  Icons.person,
                  color: iconColor,
                ),
        ),
      ),
    );
  }
}