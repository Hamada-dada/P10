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

      // fallback if profile not found
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: activity.isImportant
                  ? Colors.red
                  : const Color(0xFFE0E0E0),
              width: activity.isImportant ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
  tooltip: activity.isCompleted ? 'Marker som ikke færdig' : 'Marker som færdig',
  onPressed: onCompletedChanged == null
      ? null
      : () => onCompletedChanged!(!activity.isCompleted),
  icon: Icon(
    activity.isCompleted
        ? Icons.check_box
        : Icons.check_box_outline_blank,
    color: activity.isCompleted ? Colors.green : Colors.black54,
  ),
),
const SizedBox(width: 4),
              SizedBox(
                width: 72,
                child: Text(
                  '${_formatTime(activity.startTime)}\n${_formatTime(activity.endTime)}',
                  style: const TextStyle(
                    fontFamily: 'Italiana',
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${activity.title} ${activity.emoji}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Italiana',
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Builder(
                builder: (context) {
                  final visibleParticipants = activity.participants
                      .take(2)
                      .toList();
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
                          padding: const EdgeInsets.only(right: 4),
                          child: CircleAvatar(
                            radius: 13,
                            backgroundColor: const Color(0xFFA2E5AD),
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        );
                      }),
                      if (hiddenCount > 0)
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: const Color(0xFFE0E0E0),
                          child: Text(
                            '+$hiddenCount',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const Icon(Icons.chevron_right, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }
}
