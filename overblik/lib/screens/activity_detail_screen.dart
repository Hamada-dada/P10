import 'package:flutter/material.dart';
import '../models/activity.dart';

class ActivityDetailScreen extends StatelessWidget {
  final Activity activity;

  const ActivityDetailScreen({
    super.key,
    required this.activity,
  });

  String _formatDate(DateTime dateTime) {
    const weekdays = [
      'Mandag',
      'Tirsdag',
      'Onsdag',
      'Torsdag',
      'Fredag',
      'Lørdag',
      'Søndag',
    ];

    final weekday = weekdays[dateTime.weekday - 1];
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = (dateTime.year % 100).toString().padLeft(2, '0');

    return '$weekday $day/$month/$year';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _buildParticipantsText() {
    if (activity.participants.isEmpty) {
      return 'Ingen deltagere';
    }

    return activity.participants.join(', ');
  }

  String _buildDescriptionText() {
    if (activity.description.trim().isEmpty) {
      return 'Ingen beskrivelse';
    }

    return activity.description;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA2E5AD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _TopBar(),
              const SizedBox(height: 20),

              Center(
                child: Text(
                  '${activity.title} ${activity.emoji}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Italiana',
                    fontSize: 36,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TimeInfoCard(
                    dateText: _formatDate(activity.startTime),
                    timeText: _formatTime(activity.startTime),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 28,
                      color: Colors.black,
                    ),
                  ),
                  _TimeInfoCard(
                    dateText: _formatDate(activity.endTime),
                    timeText: _formatTime(activity.endTime),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _InfoSection(
                icon: Icons.edit_note,
                child: Text(
                  _buildDescriptionText(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF1D1B20),
                    height: 1.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _InfoSection(
                icon: Icons.group_outlined,
                child: Text(
                  _buildParticipantsText(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                    height: 1.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const Spacer(),

              Align(
                alignment: Alignment.bottomRight,
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.camera_alt_outlined,
                    size: 28,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 24,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.edit,
            color: Colors.black,
            size: 28,
          ),
        ),
      ],
    );
  }
}

class _TimeInfoCard extends StatelessWidget {
  final String dateText;
  final String timeText;

  const _TimeInfoCard({
    required this.dateText,
    required this.timeText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Column(
        children: [
          Text(
            dateText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
              height: 1.5,
              letterSpacing: 0.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            timeText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const _InfoSection({
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          child: Icon(
            icon,
            size: 30,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFD9D9D9),
            child: child,
          ),
        ),
      ],
    );
  }
}