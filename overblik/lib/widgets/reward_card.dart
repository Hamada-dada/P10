import 'package:flutter/material.dart';

import '../models/reward.dart';
import 'reward_type_chip.dart';

class RewardCard extends StatelessWidget {
  final Reward reward;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const RewardCard({
    super.key,
    required this.reward,
    this.onDelete,
    this.onTap,
  });

  String _profileLabel() {
    final profile = reward.assignedProfile.trim();
    if (profile.isEmpty) {
      return 'Ingen profil valgt';
    }
    return profile;
  }

  String _emojiLabel() {
    final emoji = reward.emoji.trim();
    if (emoji.isEmpty) {
      return '🎁';
    }
    return emoji;
  }

  @override
  Widget build(BuildContext context) {
    final hasDescription = reward.description.trim().isNotEmpty;

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF101312) : colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? colorScheme.primary.withOpacity(0.45)
                : const Color(0xFFE0E0E0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isDark
                      ? colorScheme.primary.withOpacity(0.16)
                      : Colors.white,
                  child: Text(
                    _emojiLabel(),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tilhører: ${_profileLabel()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withOpacity(0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Slet belønning',
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline,
                      color: colorScheme.onSurface.withOpacity(0.85),
                    ),
                  ),
              ],
            ),
            if (hasDescription) ...[
              const SizedBox(height: 10),
              Text(
                reward.description,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.78),
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (reward.isDirectReward)
                  const RewardTypeChip(
                    icon: Icons.flash_on_outlined,
                    label: 'Direkte',
                  ),
                if (reward.isStreakReward)
                  const RewardTypeChip(
                    icon: Icons.trending_up_outlined,
                    label: 'Langsigtet',
                  ),
                if (!reward.isDirectReward && !reward.isStreakReward)
                  const RewardTypeChip(
                    icon: Icons.remove_circle_outline,
                    label: 'Ingen type valgt',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}