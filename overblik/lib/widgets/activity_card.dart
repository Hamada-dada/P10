import 'package:flutter/material.dart';

class ActivityCard extends StatelessWidget {
  final String startTime;
  final String endTime;
  final String title;
  final String emoji;
  final bool isChanged;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.title,
    required this.emoji,
    this.isChanged = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isChanged ? Colors.red : const Color(0xFFA2E5AD),
            width: 2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 64,
              child: Text(
                '$startTime\n$endTime',
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
                '$title $emoji',
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
    );
  }
}