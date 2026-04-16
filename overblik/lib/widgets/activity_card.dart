import 'package:flutter/material.dart';
import '../models/activity.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.activity,
    this.onTap,
  });

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
          color: activity.isImportant ? Colors.red : const Color(0xFFE0E0E0),
          width: activity.isImportant ? 2 : 1,
        ),
      ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 72,
              child: Text(
                '${_formatTime(activity.startTime)}\n${_formatTime(activity.endTime)}',
                style: const TextStyle(
                  fontFamily: 'Italiana',
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                '${activity.title} ${activity.emoji}',
                style: const TextStyle(
                  fontFamily: 'Italiana',
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}