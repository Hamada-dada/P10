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

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tilhører: ${_profileLabel()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Slet belønning',
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.black87,
                    ),
                  ),
              ],
            ),
            if (hasDescription) ...[
              const SizedBox(height: 10),
              Text(
                reward.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
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