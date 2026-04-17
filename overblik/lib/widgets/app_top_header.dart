import 'package:flutter/material.dart';

import 'profile_avatar.dart';

class AppTopHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final String profileName;
  final String roleLabel;
  final String emoji;
  final List<String> familyMembers;
  final bool useEmoji;

  const AppTopHeader({
    super.key,
    required this.title,
    this.onBack,
    this.profileName = 'Mig',
    this.roleLabel = 'Barn',
    this.emoji = '🙂',
    this.familyMembers = const ['Mig', 'Mor', 'Far'],
    this.useEmoji = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: onBack ?? () => Navigator.maybePop(context),
          icon: const Icon(
            Icons.arrow_back,
            size: 30,
            color: Colors.black,
          ),
        ),
        const Spacer(),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Italiana',
            fontSize: 26,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        const Spacer(),
        ProfileAvatarButton(
          name: profileName,
          roleLabel: roleLabel,
          emoji: emoji,
          familyMembers: familyMembers,
          useEmoji: useEmoji,
        ),
      ],
    );
  }
}