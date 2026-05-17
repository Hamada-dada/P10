import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/reward.dart';
import 'reward_type_chip.dart';

class RewardCard extends StatelessWidget {
  final Reward reward;
  final String? assignedProfileName;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const RewardCard({
    super.key,
    required this.reward,
    this.assignedProfileName,
    this.onDelete,
    this.onTap,
  });

  String _emojiLabel() {
    final emoji = reward.emoji.trim();
    if (emoji.isEmpty) return '🎁';
    return emoji;
  }

  @override
  Widget build(BuildContext context) {
    final hasDescription = reward.description.trim().isNotEmpty;
    final l = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileName = assignedProfileName?.trim() ?? '';

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
                ? colorScheme.primary.withValues(alpha: 0.45)
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
                      ? colorScheme.primary.withValues(alpha: 0.16)
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
                        profileName.isEmpty
                            ? l.noProfileSelectedLabel
                            : l.belongsToProfile(profileName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    tooltip: l.deleteRewardTooltip,
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline,
                      color: colorScheme.onSurface.withValues(alpha: 0.85),
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
                  color: colorScheme.onSurface.withValues(alpha: 0.78),
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
                  RewardTypeChip(
                    icon: Icons.flash_on_outlined,
                    label: l.directRewardLabel,
                  ),
                if (reward.isStreakReward)
                  RewardTypeChip(
                    icon: Icons.trending_up_outlined,
                    label: l.streakRewardLabel,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}