import 'dart:io';

import 'package:flutter/material.dart';

import '../models/activity.dart';
import '../services/activity_service.dart';
import 'create_activity_screen.dart';

class ActivityDetailScreen extends StatefulWidget {
  final Activity activity;

  const ActivityDetailScreen({
    super.key,
    required this.activity,
  });

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late Activity _activity;
  late List<bool> _checkedItems;

  @override
  void initState() {
    super.initState();

    _activity =
        ActivityService().getActivityById(widget.activity.id) ?? widget.activity;

    _checkedItems = List<bool>.from(_activity.normalizedChecklistChecked);
  }

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

    return '$weekday\n$day/$month/$year';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _buildParticipantsText() {
    if (_activity.participants.isEmpty) {
      return 'Ingen deltagere';
    }

    return _activity.participants.join(', ');
  }

  String _buildDescriptionText() {
    if (_activity.description.trim().isEmpty) {
      return 'Ingen beskrivelse';
    }

    return _activity.description;
  }

  String _buildRewardText() {
    if (_activity.reward.trim().isEmpty) {
      return 'Ingen belønning valgt';
    }

    if (_activity.isRewardRecurring) {
      return '${_activity.reward}\nGentagende belønning';
    }

    return _activity.reward;
  }

  String _buildRecurrenceText() {
    switch (_activity.recurrence) {
      case ActivityRecurrence.none:
        return 'Ingen gentagelse';
      case ActivityRecurrence.daily:
        if (_activity.recurrenceInterval == 1) {
          return 'Gentages hver dag';
        }
        return 'Gentages hver ${_activity.recurrenceInterval}. dag';
      case ActivityRecurrence.weekly:
        if (_activity.recurrenceInterval == 1) {
          return 'Gentages hver uge';
        }
        return 'Gentages hver ${_activity.recurrenceInterval}. uge';
      case ActivityRecurrence.monthly:
        if (_activity.recurrenceInterval == 1) {
          return 'Gentages hver måned';
        }
        return 'Gentages hver ${_activity.recurrenceInterval}. måned';
      case ActivityRecurrence.custom:
        return 'Brugerdefineret gentagelse';
    }
  }

  Future<void> _toggleChecklistItem(int index) async {
    final updatedCheckedItems = List<bool>.from(_checkedItems);
    updatedCheckedItems[index] = !updatedCheckedItems[index];

    final updatedActivity = _activity.copyWith(
      checklistChecked: updatedCheckedItems,
    );

    ActivityService().updateActivity(updatedActivity);

    setState(() {
      _checkedItems = updatedCheckedItems;
      _activity = updatedActivity;
    });
  }

  Future<void> _editActivity(BuildContext context) async {
    final updatedActivity = await Navigator.push<Activity>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateActivityScreen(
          existingActivity: _activity,
          initialDate: _activity.startTime,
        ),
      ),
    );

    if (updatedActivity != null) {
      ActivityService().updateActivity(updatedActivity);

      setState(() {
        _activity = updatedActivity;
        _checkedItems = List<bool>.from(_activity.normalizedChecklistChecked);
      });

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
          content: Text('Vil du slette "${_activity.title}"?'),
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

    ActivityService().deleteActivity(_activity.id);

    if (!context.mounted) return;
    Navigator.pop(context, true);
  }

  void _openImagePreview(BuildContext context) {
    if (_activity.imagePath.trim().isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    child: Image.file(
                      File(_activity.imagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _activity.imagePath.trim().isNotEmpty;
    final hasReward = _activity.reward.trim().isNotEmpty;
    final hasChecklist = _activity.checklistItems.isNotEmpty;
    final hasRecurrence = _activity.recurrence != ActivityRecurrence.none;

    return Scaffold(
      backgroundColor: const Color(0xFFA2E5AD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Center(
            child: Container(
              width: 420,
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: _TopBar(
                      onBack: () => Navigator.pop(context),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_activity.isFavorite)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 28,
                                    ),
                                  ),
                                Flexible(
                                  child: Text(
                                    '${_activity.title} ${_activity.emoji}',
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _TimeInfoCard(
                                dateText: _formatDate(_activity.startTime),
                                timeText: _formatTime(_activity.startTime),
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
                                dateText: _formatDate(_activity.endTime),
                                timeText: _formatTime(_activity.endTime),
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
                          if (hasImage) ...[
                            const SizedBox(height: 20),
                            _InfoSection(
                              icon: Icons.image_outlined,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _openImagePreview(context),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(_activity.imagePath),
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 90,
                                        alignment: Alignment.center,
                                        color: const Color(0xFFF1F1F1),
                                        child: const Text(
                                          'Kunne ikke vise billedet',
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (hasChecklist) ...[
                            const SizedBox(height: 20),
                            _InfoSection(
                              icon: Icons.check_box_outlined,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: List.generate(
                                  _activity.checklistItems.length,
                                  (index) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () => _toggleChecklistItem(index),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 2),
                                            child: Icon(
                                              _checkedItems[index]
                                                  ? Icons.check_box
                                                  : Icons
                                                      .check_box_outline_blank,
                                              size: 20,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _activity.checklistItems[index],
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w400,
                                                color: const Color(0xFF1D1B20),
                                                height: 1.5,
                                                letterSpacing: 0.5,
                                                decoration: _checkedItems[index]
                                                    ? TextDecoration.lineThrough
                                                    : TextDecoration.none,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (hasReward) ...[
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
                          if (hasRecurrence) ...[
                            const SizedBox(height: 20),
                            _InfoSection(
                              icon: Icons.repeat,
                              child: Text(
                                _buildRecurrenceText(),
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
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Row(
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
                      ],
                    ),
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

  const _TopBar({
    required this.onBack,
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