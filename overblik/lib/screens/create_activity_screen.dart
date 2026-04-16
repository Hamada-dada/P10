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
  late final TextEditingController _participantsController;

  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late ActivityOwner _selectedOwner;
  bool _isImportant = false;
  bool _isFavorite = false;

  bool get _isEditing => widget.existingActivity != null;

  @override
  void initState() {
    super.initState();

    final activity = widget.existingActivity;
    final baseDate = widget.initialDate ?? DateTime.now();

    _titleController = TextEditingController(text: activity?.title ?? '');
    _emojiController = TextEditingController(text: activity?.emoji ?? '');
    _descriptionController =
        TextEditingController(text: activity?.description ?? '');
    _participantsController = TextEditingController(
      text: activity?.participants.join(', ') ?? '',
    );

    _selectedDate = activity?.startTime ?? baseDate;
    _startTime = TimeOfDay.fromDateTime(
      activity?.startTime ??
          DateTime(baseDate.year, baseDate.month, baseDate.day, 8, 0),
    );
    _endTime = TimeOfDay.fromDateTime(
      activity?.endTime ??
          DateTime(baseDate.year, baseDate.month, baseDate.day, 9, 0),
    );

    _selectedOwner = activity?.owner ?? ActivityOwner.me;
    _isImportant = activity?.isImportant ?? false;
    _isFavorite = activity?.isFavorite ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _emojiController.dispose();
    _descriptionController.dispose();
    _participantsController.dispose();
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

  String _ownerLabel(ActivityOwner owner) {
    switch (owner) {
      case ActivityOwner.me:
        return 'Mig';
      case ActivityOwner.mother:
        return 'Mor';
      case ActivityOwner.father:
        return 'Far';
      case ActivityOwner.family:
        return 'Familie';
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
    );

    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
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

    final participants = _participantsController.text
        .split(',')
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    final activity = Activity(
      id: widget.existingActivity?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      emoji: _emojiController.text.trim(),
      startTime: startDateTime,
      endTime: endDateTime,
      owner: _selectedOwner,
      isImportant: _isImportant,
      isFavorite: _isFavorite,
      description: _descriptionController.text.trim(),
      participants: participants,
      isCompleted: widget.existingActivity?.isCompleted ?? false,
    );

    Navigator.pop(context, activity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA2E5AD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFA2E5AD),
        elevation: 0,
        title: Text(_isEditing ? 'Rediger aktivitet' : 'Ny aktivitet'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          hintText: 'f.eks. 📘',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<ActivityOwner>(
                        value: _selectedOwner,
                        decoration: const InputDecoration(
                          labelText: 'Ejer',
                          border: OutlineInputBorder(),
                        ),
                        items: ActivityOwner.values.map((owner) {
                          return DropdownMenuItem<ActivityOwner>(
                            value: owner,
                            child: Text(_ownerLabel(owner)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedOwner = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _pickDate,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                child: Text('Dato: ${_formatDate(_selectedDate)}'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _pickStartTime,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                child:
                                    Text('Start: ${_formatTime(_startTime)}'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _pickEndTime,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                child: Text('Slut: ${_formatTime(_endTime)}'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _participantsController,
                        decoration: const InputDecoration(
                          labelText: 'Deltagere',
                          border: OutlineInputBorder(),
                          hintText: 'Mig, Mor, Far',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Beskrivelse',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Vigtig aktivitet'),
                        value: _isImportant,
                        onChanged: (value) {
                          setState(() {
                            _isImportant = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Favoritaktivitet'),
                        value: _isFavorite,
                        onChanged: (value) {
                          setState(() {
                            _isFavorite = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _saveActivity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            _isEditing ? 'Gem ændringer' : 'Opret aktivitet',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}