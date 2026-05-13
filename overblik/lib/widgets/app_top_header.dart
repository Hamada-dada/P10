import 'package:flutter/material.dart';

import 'profile_avatar.dart';

class AppTopHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const AppTopHeader({
    super.key,
    required this.title,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: onBack ?? () => Navigator.maybePop(context),
          icon: Icon(
            Icons.arrow_back,
            size: 30,
            color: colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Italiana',
            fontSize: 26,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        const ProfileAvatarButton(),
      ],
    );
  }
}