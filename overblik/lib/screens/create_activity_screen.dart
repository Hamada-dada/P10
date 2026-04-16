import 'package:flutter/material.dart';
import '../models/activity.dart';

class CreateActivityScreen extends StatefulWidget {
  final DateTime? initialDate;
  final Activity? existingActivity;

  const CreateActivityScreen({
    super.key,
    this.initialDate,
    this.existingActivity,
  });

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _emojiController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _rewardController;
  late final TextEditingController _imagePathController;
  late final TextEditingController _recurrenceIntervalController;

  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  bool _isFavorite = false;
  bool _showRewardFields = false;
  bool _isRewardRecurring = false;
  bool _showChecklist = false;

  late List<String> _selectedParticipants;
  late List<TextEditingController> _checklistControllers;
  late ActivityRecurrence _selectedRecurrence;
  late ActivityRecurrence _selectedCustomRecurrence;

  bool get _isEditing => widget.existingActivity != null;

  static const List<String> _participantOptions = [
    'Mig',
    'Mor',
    'Far',
    'Peter',
    'Familie',
  ];

  @override
  void initState() {
    super.initState();

    final activity = widget.existingActivity;
    final baseDate = widget.initialDate ?? DateTime.now();
    final roundedNow = _roundToNextQuarter(baseDate);

    _titleController = TextEditingController(text: activity?.title ?? '');
    _emojiController = TextEditingController(text: activity?.emoji ?? '');
    _descriptionController =
        TextEditingController(text: activity?.description ?? '');
    _rewardController = TextEditingController(text: activity?.reward ?? '');
    _imagePathController =
        TextEditingController(text: activity?.imagePath ?? '');
    _recurrenceIntervalController = TextEditingController(
      text: (activity?.recurrenceInterval ?? 1).toString(),
    );

    _selectedDate = activity?.startTime ?? baseDate;
    _startTime = TimeOfDay.fromDateTime(activity?.startTime ?? roundedNow);
    _endTime = TimeOfDay.fromDateTime(
      activity?.endTime ?? roundedNow.add(const Duration(hours: 1)),
    );

    _isFavorite = activity?.isFavorite ?? false;
    _showRewardFields = (activity?.reward.trim().isNotEmpty ?? false);
    _isRewardRecurring = activity?.isRewardRecurring ?? false;
    _showChecklist = (activity?.checklistItems.isNotEmpty ?? false);

    _selectedParticipants = List<String>.from(activity?.participants ?? ['Mig']);
    _selectedRecurrence = activity?.recurrence ?? ActivityRecurrence.none;

    _selectedCustomRecurrence =
        activity?.recurrence == ActivityRecurrence.daily ||
                activity?.recurrence == ActivityRecurrence.weekly ||
                activity?.recurrence == ActivityRecurrence.monthly
            ? activity!.recurrence
            : ActivityRecurrence.daily;

    final initialChecklist = activity?.checklistItems ?? [];
    _checklistControllers = initialChecklist.isNotEmpty
        ? initialChecklist
            .map((item) => TextEditingController(text: item))
            .toList()
        : [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _emojiController.dispose();
    _descriptionController.dispose();
    _rewardController.dispose();
    _imagePathController.dispose();
    _recurrenceIntervalController.dispose();

    for (final controller in _checklistControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  DateTime _roundToNextQuarter(DateTime dateTime) {
    final remainder = dateTime.minute % 15;
    final minutesToAdd = remainder == 0 ? 0 : 15 - remainder;
    final rounded = dateTime.add(Duration(minutes: minutesToAdd));

    return DateTime(
      rounded.year,
      rounded.month,
      rounded.day,
      rounded.hour,
      rounded.minute,
    );
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _looksLikeSingleEmoji(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return true;
    return trimmed.runes.length <= 8;
  }

  ActivityOwner _mapParticipantsToOwner(List<String> participants) {
    if (participants.contains('Familie')) {
      return ActivityOwner.family;
    }
    if (participants.length > 1) {
      return ActivityOwner.family;
    }
    if (participants.contains('Mor')) {
      return ActivityOwner.mother;
    }
    if (participants.contains('Far')) {
      return ActivityOwner.father;
    }
    return ActivityOwner.me;
  }

  String _recurrenceLabel(ActivityRecurrence recurrence) {
    switch (recurrence) {
      case ActivityRecurrence.none:
        return 'Ingen gentagelse';
      case ActivityRecurrence.daily:
        return 'Dagligt';
      case ActivityRecurrence.weekly:
        return 'Ugentligt';
      case ActivityRecurrence.monthly:
        return 'Månedligt';
      case ActivityRecurrence.custom:
        return 'Brugerdefineret';
    }
  }

  String _intervalSuffix(ActivityRecurrence recurrence) {
    switch (recurrence) {
      case ActivityRecurrence.none:
        return '';
      case ActivityRecurrence.daily:
        return 'dag(e)';
      case ActivityRecurrence.weekly:
        return 'uge(r)';
      case ActivityRecurrence.monthly:
        return 'måned(er)';
      case ActivityRecurrence.custom:
        return _intervalSuffix(_selectedCustomRecurrence);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  void _addChecklistItem() {
    setState(() {
      if (!_showChecklist) {
        _showChecklist = true;
      }
      _checklistControllers.add(TextEditingController());
    });
  }

  void _removeChecklistItem(int index) {
    setState(() {
      _checklistControllers[index].dispose();
      _checklistControllers.removeAt(index);

      if (_checklistControllers.isEmpty) {
        _showChecklist = false;
      }
    });
  }

  void _toggleChecklist() {
    setState(() {
      if (_showChecklist) {
        for (final controller in _checklistControllers) {
          controller.dispose();
        }
        _checklistControllers = [];
        _showChecklist = false;
      } else {
        _showChecklist = true;
        _checklistControllers = [TextEditingController()];
      }
    });
  }

  void _toggleRewardFields() {
    setState(() {
      _showRewardFields = !_showRewardFields;
      if (!_showRewardFields) {
        _rewardController.clear();
        _isRewardRecurring = false;
      }
    });
  }

  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Vælg fra billeder'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Galleri-integration mangler endnu. UI er klar til image_picker.',
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Tag billede med kamera'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Kamera-integration mangler endnu. UI er klar til image_picker.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _saveActivity() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final startDateTime = _combineDateAndTime(_selectedDate, _startTime);
    final endDateTime = _combineDateAndTime(_selectedDate, _endTime);

    if (!endDateTime.isAfter(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sluttid skal være efter starttid.'),
        ),
      );
      return;
    }

    if (_selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vælg mindst én deltager.'),
        ),
      );
      return;
    }

    final parsedInterval =
        int.tryParse(_recurrenceIntervalController.text.trim()) ?? 1;

    if (_selectedRecurrence != ActivityRecurrence.none && parsedInterval < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gentagelsesinterval skal være mindst 1.'),
        ),
      );
      return;
    }

    final checklistItems = _showChecklist
        ? _checklistControllers
            .map((controller) => controller.text.trim())
            .where((item) => item.isNotEmpty)
            .toList()
        : <String>[];

    final rewardText = _showRewardFields ? _rewardController.text.trim() : '';

    final activity = Activity(
      id: widget.existingActivity?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      emoji: _emojiController.text.trim(),
      startTime: startDateTime,
      endTime: endDateTime,
      owner: _mapParticipantsToOwner(_selectedParticipants),
      isImportant: widget.existingActivity?.isImportant ?? false,
      isFavorite: _isFavorite,
      description: _descriptionController.text.trim(),
      participants: _selectedParticipants,
      checklistItems: checklistItems,
      reward: rewardText,
      isRewardRecurring: _showRewardFields ? _isRewardRecurring : false,
      imagePath: _imagePathController.text.trim(),
      recurrence: _selectedRecurrence == ActivityRecurrence.custom
          ? _selectedCustomRecurrence
          : _selectedRecurrence,
      recurrenceInterval:
          _selectedRecurrence == ActivityRecurrence.none ? 1 : parsedInterval,
      isCompleted: widget.existingActivity?.isCompleted ?? false,
    );

    Navigator.pop(context, activity);
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? 'Ny aktivitet' : 'Ny aktivitet';

    return Scaffold(
      backgroundColor: const Color(0xFFA2E5AD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(
                title: title,
                onBack: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Titel',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Skriv en titel';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emojiController,
                          decoration: const InputDecoration(
                            labelText: 'Emoji',
                            border: OutlineInputBorder(),
                            hintText: 'f.eks. 🎮',
                          ),
                          validator: (value) {
                            if (value == null) return null;
                            if (!_looksLikeSingleEmoji(value)) {
                              return 'Brug kun én emoji';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _PickerTile(
                          label: 'Dato',
                          value: _formatDate(_selectedDate),
                          icon: Icons.calendar_today_outlined,
                          onTap: _pickDate,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _PickerTile(
                                label: 'Start',
                                value: _formatTime(_startTime),
                                icon: Icons.schedule,
                                onTap: _pickStartTime,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _PickerTile(
                                label: 'Slut',
                                value: _formatTime(_endTime),
                                icon: Icons.schedule_outlined,
                                onTap: _pickEndTime,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ActivityRecurrence>(
                          value: _selectedRecurrence,
                          decoration: const InputDecoration(
                            labelText: 'Gentagelse',
                            border: OutlineInputBorder(),
                          ),
                          items: ActivityRecurrence.values.map((recurrence) {
                            return DropdownMenuItem<ActivityRecurrence>(
                              value: recurrence,
                              child: Text(_recurrenceLabel(recurrence)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedRecurrence = value;
                            });
                          },
                        ),
                        if (_selectedRecurrence != ActivityRecurrence.none) ...[
                          const SizedBox(height: 12),
                          if (_selectedRecurrence == ActivityRecurrence.custom) ...[
                            DropdownButtonFormField<ActivityRecurrence>(
                              value: _selectedCustomRecurrence,
                              decoration: const InputDecoration(
                                labelText: 'Gentag hver',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: ActivityRecurrence.daily,
                                  child: Text('Dag'),
                                ),
                                DropdownMenuItem(
                                  value: ActivityRecurrence.weekly,
                                  child: Text('Uge'),
                                ),
                                DropdownMenuItem(
                                  value: ActivityRecurrence.monthly,
                                  child: Text('Måned'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _selectedCustomRecurrence = value;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _recurrenceIntervalController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: _selectedRecurrence ==
                                      ActivityRecurrence.custom
                                  ? 'Hver X ${_intervalSuffix(_selectedCustomRecurrence)}'
                                  : 'Hver X ${_intervalSuffix(_selectedRecurrence)}',
                              border: const OutlineInputBorder(),
                              hintText: 'f.eks. 2',
                            ),
                            validator: (value) {
                              if (_selectedRecurrence == ActivityRecurrence.none) {
                                return null;
                              }
                              final number = int.tryParse((value ?? '').trim());
                              if (number == null || number < 1) {
                                return 'Skriv et tal på mindst 1';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Tilføj deltager',
                            border: OutlineInputBorder(),
                          ),
                          items: _participantOptions
                              .where((option) =>
                                  !_selectedParticipants.contains(option))
                              .map((participant) {
                            return DropdownMenuItem<String>(
                              value: participant,
                              child: Text(participant),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedParticipants.add(value);
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedParticipants.map((participant) {
                            return Chip(
                              label: Text(participant),
                              onDeleted: () {
                                setState(() {
                                  _selectedParticipants.remove(participant);
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFBDBDBD)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _descriptionController,
                                maxLines: 5,
                                decoration: const InputDecoration(
                                  labelText: 'Beskrivelse',
                                  alignLabelWithHint: true,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.fromLTRB(
                                    12,
                                    12,
                                    12,
                                    12,
                                  ),
                                ),
                              ),
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'Favorit',
                                      onPressed: () {
                                        setState(() {
                                          _isFavorite = !_isFavorite;
                                        });
                                      },
                                      icon: Icon(
                                        _isFavorite
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: _isFavorite
                                            ? Colors.amber
                                            : Colors.black87,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Belønning',
                                      onPressed: _toggleRewardFields,
                                      icon: Icon(
                                        _showRewardFields
                                            ? Icons.card_giftcard
                                            : Icons.card_giftcard_outlined,
                                        color: _showRewardFields
                                            ? Colors.deepPurple
                                            : Colors.black87,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      tooltip: 'Tjekliste',
                                      onPressed: _toggleChecklist,
                                      icon: Icon(
                                        _showChecklist
                                            ? Icons.checklist_rtl
                                            : Icons.checklist_outlined,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Tilføj billede',
                                      onPressed: _showImageSourceDialog,
                                      icon: const Icon(
                                        Icons.camera_alt_outlined,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_imagePathController.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _imagePathController,
                            decoration: const InputDecoration(
                              labelText: 'Billedereference',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                        if (_showChecklist) ...[
                          const SizedBox(height: 12),
                          ...List.generate(_checklistControllers.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_box_outline_blank,
                                    size: 22,
                                    color: Colors.black54,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _checklistControllers[index],
                                      decoration: InputDecoration(
                                        hintText: 'Punkt ${index + 1}',
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => _removeChecklistItem(index),
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                              ),
                            );
                          }),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _addChecklistItem,
                              icon: const Icon(Icons.add),
                              label: const Text('Tilføj punkt'),
                            ),
                          ),
                        ],
                        if (_showRewardFields) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _rewardController,
                            decoration: const InputDecoration(
                              labelText: 'Belønning',
                              border: OutlineInputBorder(),
                              hintText:
                                  'f.eks. 30 min. Switch eller is efter aftensmad',
                            ),
                          ),
                          const SizedBox(height: 10),
                          SwitchListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            tileColor: const Color(0xFFF8F8F8),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            title: const Text('Gentagende belønning'),
                            subtitle: const Text(
                              'Belønningen kan bruges igen næste gang aktiviteten gennemføres.',
                            ),
                            value: _isRewardRecurring,
                            onChanged: (value) {
                              setState(() {
                                _isRewardRecurring = value;
                              });
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveActivity,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Text(
                                _isEditing
                                    ? 'Gem ændringer'
                                    : 'Opret aktivitet',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
  final String title;
  final VoidCallback onBack;

  const _TopBar({
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: onBack,
          icon: const Icon(
            Icons.arrow_back,
            size: 30,
            color: Colors.black,
          ),
        ),
        const Spacer(),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Italiana',
            fontSize: 26,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 30),
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _PickerTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.black87),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$label: $value',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}