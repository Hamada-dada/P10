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

  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  bool _isImportant = false;
  bool _isFavorite = false;

  late List<String> _selectedParticipants;
  late List<TextEditingController> _checklistControllers;

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

    _titleController = TextEditingController(text: activity?.title ?? '');
    _emojiController = TextEditingController(text: activity?.emoji ?? '');
    _descriptionController =
        TextEditingController(text: activity?.description ?? '');

    _selectedDate = activity?.startTime ?? baseDate;
    _startTime = TimeOfDay.fromDateTime(
      activity?.startTime ??
          DateTime(baseDate.year, baseDate.month, baseDate.day, 8, 0),
    );
    _endTime = TimeOfDay.fromDateTime(
      activity?.endTime ??
          DateTime(baseDate.year, baseDate.month, baseDate.day, 9, 0),
    );

    _isImportant = activity?.isImportant ?? false;
    _isFavorite = activity?.isFavorite ?? false;

    _selectedParticipants = List<String>.from(activity?.participants ?? ['Mig']);

    final initialChecklist = activity?.checklistItems ?? [];
    _checklistControllers = initialChecklist.isNotEmpty
        ? initialChecklist
            .map((item) => TextEditingController(text: item))
            .toList()
        : [TextEditingController()];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _emojiController.dispose();
    _descriptionController.dispose();

    for (final controller in _checklistControllers) {
      controller.dispose();
    }

    super.dispose();
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
      _checklistControllers.add(TextEditingController());
    });
  }

  void _removeChecklistItem(int index) {
    if (_checklistControllers.length == 1) {
      _checklistControllers[index].clear();
      return;
    }

    setState(() {
      _checklistControllers[index].dispose();
      _checklistControllers.removeAt(index);
    });
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

    final checklistItems = _checklistControllers
        .map((controller) => controller.text.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final activity = Activity(
      id: widget.existingActivity?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      emoji: _emojiController.text.trim(),
      startTime: startDateTime,
      endTime: endDateTime,
      owner: _mapParticipantsToOwner(_selectedParticipants),
      isImportant: _isImportant,
      isFavorite: _isFavorite,
      description: _descriptionController.text.trim(),
      participants: _selectedParticipants,
      checklistItems: checklistItems,
      isCompleted: widget.existingActivity?.isCompleted ?? false,
    );

    Navigator.pop(context, activity);
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? 'Rediger aktivitet' : 'Ny aktivitet';

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
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Tilføj deltager',
                            border: OutlineInputBorder(),
                          ),
                          items: _participantOptions
                              .where((option) => !_selectedParticipants.contains(option))
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
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Beskrivelse',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Checkliste',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                        const SizedBox(height: 12),
                        SwitchListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tileColor: const Color(0xFFF8F8F8),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          title: const Text('Vigtig aktivitet'),
                          subtitle: const Text(
                            'Bruges til aktiviteter der kræver særlig opmærksomhed eller ikke må glemmes.',
                          ),
                          value: _isImportant,
                          onChanged: (value) {
                            setState(() {
                              _isImportant = value;
                            });
                          },
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
                          title: const Text('Favoritaktivitet'),
                          subtitle: const Text(
                            'Bruges til aktiviteter man glæder sig til, eller som virker motiverende.',
                          ),
                          value: _isFavorite,
                          onChanged: (value) {
                            setState(() {
                              _isFavorite = value;
                            });
                          },
                        ),
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