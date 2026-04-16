import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../services/activity_service.dart';
import 'create_activity_screen.dart';

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

  String _buildRewardText() {
    if (activity.reward.trim().isEmpty) {
      return 'Ingen belønning valgt';
    }

    return activity.reward;
  }

  Future<void> _editActivity(BuildContext context) async {
    final activityService = ActivityService();

    final updatedActivity = await Navigator.push<Activity>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateActivityScreen(
          existingActivity: activity,
          initialDate: activity.startTime,
        ),
      ),
    );

    if (updatedActivity != null) {
      activityService.updateActivity(updatedActivity);

      if (!context.mounted) return;
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteActivity(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Slet aktivitet'),
          content: Text('Vil du slette "${activity.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuller'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Slet'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    final activityService = ActivityService();
    activityService.deleteActivity(activity.id);

    if (!context.mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA2E5AD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Center(
            child: Container(
              width: 420,
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(
                    onBack: () => Navigator.pop(context),
                    onEdit: () => _editActivity(context),
                    onDelete: () => _deleteActivity(context),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      '${activity.title} ${activity.emoji}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Italiana',
                        fontSize: 32,
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
                          size: 24,
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
                  if (activity.checklistItems.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _InfoSection(
                      icon: Icons.check_box_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: activity.checklistItems.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.check_box_outline_blank,
                                    size: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF1D1B20),
                                      height: 1.5,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  if (activity.isFavorite || activity.reward.trim().isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _InfoSection(
                      icon: Icons.card_giftcard_outlined,
                      child: Text(
                        _buildRewardText(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                          height: 1.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _BottomActionButton(
                        icon: Icons.delete_outline,
                        label: 'Slet',
                        onTap: () => _deleteActivity(context),
                      ),
                      _BottomActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Rediger',
                        onTap: () => _editActivity(context),
                      ),
                      _BottomActionButton(
                        icon: Icons.camera_alt_outlined,
                        label: 'Foto',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TopBar({
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 24,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.black,
            size: 26,
          ),
        ),
        IconButton(
          onPressed: onEdit,
          icon: const Icon(
            Icons.edit,
            color: Colors.black,
            size: 26,
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
      width: 115,
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
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: Colors.black,
        size: 22,
      ),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}