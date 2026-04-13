import 'package:flutter/material.dart';

class CalendarHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final VoidCallback? onAvatarPressed;

  const CalendarHeader({
    super.key,
    required this.title,
    this.onBackPressed,
    this.onAvatarPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBackPressed,
              icon: const Icon(
                Icons.arrow_back,
                size: 32,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onAvatarPressed,
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Italiana',
            fontSize: 48,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 6,
          width: double.infinity,
          color: Colors.white,
        ),
      ],
    );
  }
}