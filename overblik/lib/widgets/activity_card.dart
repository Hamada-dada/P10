import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../models/profile.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final List<Profile> profiles;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onCompletedChanged;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.profiles,
    this.onTap,
    this.onCompletedChanged,
  });

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _participantLabel(ActivityParticipant participant) {
    if (participant.externalName != null) {
      return participant.externalName!.trim();
    }

    if (participant.profileId != null) {
      for (final profile in profiles) {
        if (profile.id == participant.profileId) {
          return profile.name.trim();
        }
      }

      return participant.profileId!.substring(0, 2).toUpperCase();
    }

    return '';
  }

  String _initialsFromLabel(String label) {
    final cleanLabel = label.trim();

    if (cleanLabel.isEmpty) return '';

    return cleanLabel.length <= 2
        ? cleanLabel.toUpperCase()
        : cleanLabel.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF171A19) : colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: activity.isImportant
                  ? colorScheme.error
                  : (isDark ? const Color(0xFF2A2D2C) : const Color(0xFFE0E0E0)),
              width: activity.isImportant ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                tooltip: activity.isCompleted
                    ? 'Marker som ikke færdig'
                    : 'Marker som færdig',
                onPressed: onCompletedChanged == null
                    ? null
                    : () => onCompletedChanged!(!activity.isCompleted),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  activity.isCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: activity.isCompleted
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 26,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: Text(
                  '${_formatTime(activity.startTime)}\n${_formatTime(activity.endTime)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${activity.title} ${activity.emoji}',
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Italiana',
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Builder(
                builder: (context) {
                  final visibleParticipants =
                      activity.participants.take(1).toList();
                  final hiddenCount =
                      activity.participants.length - visibleParticipants.length;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...visibleParticipants.map((participant) {
                        final label = _participantLabel(participant);
                        final initials = _initialsFromLabel(label);

                        if (initials.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(right: 3),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              initials,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        );
                      }),
                      if (hiddenCount > 0)
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: isDark
                              ? const Color(0xFF2A2D2C)
                              : const Color(0xFFE0E0E0),
                          child: Text(
                            '+$hiddenCount',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
