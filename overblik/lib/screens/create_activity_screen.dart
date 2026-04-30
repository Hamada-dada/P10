import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/activity.dart';
import '../models/profile.dart';
import '../models/reward.dart';
import '../screens/rewards_screen.dart';
import '../services/profile_service.dart';
import '../services/reward_service.dart';

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
  int _participantDropdownResetKey = 0;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  final RewardService _rewardService = RewardService();
  final ProfileService _profileService = ProfileService();
  final Uuid _uuid = const Uuid();

  List<Profile> _availableProfiles = [];
  List<String> _participantOptions = [];

  bool _isLoadingProfiles = true;
  String? _profilesError;

  Profile? _currentParentProfile;
  String? _currentFamilyId;

  late final TextEditingController _titleController;
  late final TextEditingController _emojiController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _recurrenceIntervalController;
  late final TextEditingController _streakTargetController;

  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  DateTime? _recurrenceEndDate;

  bool _isFavorite = false;
  bool _showRewardFields = false;
  bool _showChecklist = false;
  bool _showMoreSettings = false;

  bool _enableDirectReward = false;
  bool _enableStreakReward = false;

  String? _selectedDirectRewardId;
  String? _selectedStreakRewardId;

  late List<String> _selectedParticipants;
  late List<TextEditingController> _checklistControllers;
  late ActivityRecurrence _selectedRecurrence;
  late ActivityRecurrence _selectedCustomRecurrence;

  String _imagePath = '';

  bool get _isEditing => widget.existingActivity != null;

  @override
  void initState() {
    super.initState();

    final activity = widget.existingActivity;
    final baseDate = widget.initialDate ?? DateTime.now();
    final roundedNow = _roundToNextQuarter(baseDate);

    _titleController = TextEditingController(text: activity?.title ?? '');
    _emojiController = TextEditingController(text: activity?.emoji ?? '');
    _descriptionController = TextEditingController(
      text: activity?.description ?? '',
    );
    _recurrenceIntervalController = TextEditingController(
      text: (activity?.recurrenceInterval ?? 1).toString(),
    );
    _streakTargetController = TextEditingController(
      text: (activity?.streakTarget ?? 5).toString(),
    );

    _imagePath = activity?.imagePath ?? '';
    _recurrenceEndDate = activity?.recurrenceEndDate;

    _selectedDate = activity?.startTime ?? baseDate;
    _startTime = TimeOfDay.fromDateTime(activity?.startTime ?? roundedNow);
    _endTime = TimeOfDay.fromDateTime(
      activity?.endTime ?? roundedNow.add(const Duration(hours: 1)),
    );

    _isFavorite = activity?.isFavorite ?? false;
    _showChecklist = activity?.checklistItems.isNotEmpty ?? false;

    _enableDirectReward = activity?.directRewardId != null;
    _enableStreakReward = activity?.streakRewardId != null;
    _showRewardFields = _enableDirectReward || _enableStreakReward;

    _selectedDirectRewardId = activity?.directRewardId;
    _selectedStreakRewardId = activity?.streakRewardId;

    _selectedParticipants = <String>[];

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
              .map((item) => TextEditingController(text: item.title))
              .toList()
        : [];

    _revalidateSelectedRewards();
    _loadProfiles();
  }

  List<String> _uniqueStrings(List<String> values) {
    final result = <String>[];

    for (final value in values) {
      final cleanValue = value.trim();

      if (cleanValue.isEmpty) continue;

      if (!result.contains(cleanValue)) {
        result.add(cleanValue);
      }
    }

    return result;
  }

  Future<void> _loadProfiles() async {
    debugPrint(
      'CreateActivityScreen current auth user = ${Supabase.instance.client.auth.currentUser?.id}',
    );

    try {
      final currentParent = await _profileService.getMyParentProfile();

      if (currentParent == null) {
        if (!mounted) return;

        setState(() {
          _availableProfiles = [];
          _currentParentProfile = null;
          _currentFamilyId = null;
          _participantOptions = [];
          _selectedParticipants = [];
          _isLoadingProfiles = false;
          _profilesError =
              'Kunne ikke finde din forælderprofil. Din bruger er sandsynligvis ikke koblet til en profil i databasen.';
        });

        return;
      }

      final profiles = await _profileService.getFamilyProfiles(
        currentParent.familyId,
      );

      final selectedParticipants = <String>[];
      final externalParticipantOptions = <String>[];

      if (_isEditing && widget.existingActivity != null) {
        for (final participant in widget.existingActivity!.participants) {
          final externalName = participant.externalName?.trim();

          if (externalName != null && externalName.isNotEmpty) {
            selectedParticipants.add(externalName);

            if (!externalParticipantOptions.contains(externalName)) {
              externalParticipantOptions.add(externalName);
            }

            continue;
          }

          if (participant.profileId != null) {
            final matchingProfile = profiles.cast<Profile?>().firstWhere(
              (profile) => profile?.id == participant.profileId,
              orElse: () => null,
            );

            if (matchingProfile != null) {
              selectedParticipants.add(matchingProfile.name);
            }
          }
        }
      }

      if (selectedParticipants.isEmpty) {
        selectedParticipants.add(currentParent.name);
      }

      final participantOptions = _uniqueStrings([
        ...profiles.map((profile) => profile.name),
        ...externalParticipantOptions,
        'Familie',
      ]);

      final uniqueSelectedParticipants = _uniqueStrings(selectedParticipants)
          .where((participant) => participantOptions.contains(participant))
          .toList();

      if (uniqueSelectedParticipants.isEmpty) {
        uniqueSelectedParticipants.add(currentParent.name);
      }

      if (!mounted) return;

      setState(() {
        _availableProfiles = profiles;
        _currentParentProfile = currentParent;
        _currentFamilyId = currentParent.familyId;
        _participantOptions = participantOptions;
        _selectedParticipants = uniqueSelectedParticipants;
        _isLoadingProfiles = false;
        _profilesError = null;
      });
    } catch (e, st) {
      debugPrint('CreateActivityScreen _loadProfiles failed: $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;

      setState(() {
        _availableProfiles = [];
        _currentParentProfile = null;
        _currentFamilyId = null;
        _participantOptions = [];
        _selectedParticipants = [];
        _isLoadingProfiles = false;
        _profilesError = 'Kunne ikke hente profiler: $e';
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _emojiController.dispose();
    _descriptionController.dispose();
    _recurrenceIntervalController.dispose();
    _streakTargetController.dispose();

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
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
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

  List<Reward> _availableRewards() {
    final rewards = _rewardService.getAllRewards();
    rewards.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return rewards;
  }

  List<Reward> _directRewards() {
    return _availableRewards()
        .where((reward) => reward.types.contains(RewardType.direct))
        .toList();
  }

  List<Reward> _streakRewards() {
    return _availableRewards()
        .where((reward) => reward.types.contains(RewardType.streak))
        .toList();
  }

  void _revalidateSelectedRewards() {
    final updatedDirectRewards = _directRewards();
    final updatedStreakRewards = _streakRewards();

    if (_selectedDirectRewardId != null &&
        !updatedDirectRewards.any((r) => r.id == _selectedDirectRewardId)) {
      _selectedDirectRewardId = null;
    }

    if (_selectedStreakRewardId != null &&
        !updatedStreakRewards.any((r) => r.id == _selectedStreakRewardId)) {
      _selectedStreakRewardId = null;
    }
  }

  String _rewardTitleById(String? rewardId) {
    if (rewardId == null) return 'Ingen valgt';
    return _rewardService.getRewardById(rewardId)?.title ?? 'Ukendt belønning';
  }

  String _rewardDropdownLabel(Reward reward) {
    final emoji = reward.emoji.trim().isEmpty ? '🎁' : reward.emoji;
    return '$emoji ${reward.title}';
  }

  String? _resolveOwnerProfileId() {
    return _currentParentProfile?.id;
  }

  List<ActivityParticipant> _buildParticipants() {
    final participants = <ActivityParticipant>[];

    for (final selected in _selectedParticipants) {
      final cleanSelected = selected.trim();
      if (cleanSelected.isEmpty) continue;

      if (cleanSelected == 'Familie') {
        participants.add(const ActivityParticipant(externalName: 'Familie'));
        continue;
      }

      final matchingProfile = _availableProfiles.cast<Profile?>().firstWhere(
        (profile) => profile?.name == cleanSelected,
        orElse: () => null,
      );

      if (matchingProfile != null) {
        participants.add(ActivityParticipant(profileId: matchingProfile.id));
      } else {
        participants.add(ActivityParticipant(externalName: cleanSelected));
      }
    }

    return participants;
  }

  List<ActivityChecklistItem> _buildChecklistItems() {
    if (!_showChecklist) return const [];

    final previousChecklist =
        widget.existingActivity?.checklistItems ?? const [];

    final rawItems = _checklistControllers
        .map((controller) => controller.text.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return List<ActivityChecklistItem>.generate(
      rawItems.length,
      (index) => ActivityChecklistItem(
        id: index < previousChecklist.length
            ? previousChecklist[index].id
            : null,
        title: rawItems[index],
        isChecked: index < previousChecklist.length
            ? previousChecklist[index].isChecked
            : false,
        position: index,
      ),
    );
  }

  Future<void> _pickRecurrenceEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recurrenceEndDate ?? _selectedDate,
      firstDate: _selectedDate,
      lastDate: DateTime(2030),
    );

    if (picked == null) return;

    setState(() {
      _recurrenceEndDate = picked;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
    });
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

    if (picked == null) return;

    setState(() {
      _startTime = picked;
    });
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

    if (picked == null) return;

    setState(() {
      _endTime = picked;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _imagePath = pickedFile.path;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kunne ikke vælge billede: $e')));
    }
  }

  void _removeImage() {
    setState(() {
      _imagePath = '';
    });
  }

  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Vælg fra billeder'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Tag billede med kamera'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _pickImage(ImageSource.camera);
                  },
                ),
                if (_imagePath.trim().isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Slet billede'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _removeImage();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddExternalParticipantDialog() async {
    final controller = TextEditingController();

    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tilføj anden deltager'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Navn',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuller'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return;

                Navigator.pop(dialogContext, text);
              },
              child: const Text('Tilføj'),
            ),
          ],
        );
      },
    );

    //controller.dispose();

    if (!mounted || value == null || value.trim().isEmpty) return;

    final participant = value.trim();

    setState(() {
      final nextOptions = _uniqueStrings([..._participantOptions, participant]);

      final nextSelected = _uniqueStrings([
        ..._selectedParticipants,
        participant,
      ]);

      _participantOptions = nextOptions;
      _selectedParticipants = nextSelected;
      _participantDropdownResetKey++;
      _revalidateSelectedRewards();
    });
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
      _checklistControllers.removeAt(index);

      if (_checklistControllers.isEmpty) {
        _showChecklist = false;
      }
    });
  }

  void _toggleChecklist() {
    setState(() {
      if (_showChecklist) {
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
        _enableDirectReward = false;
        _enableStreakReward = false;
        _selectedDirectRewardId = null;
        _selectedStreakRewardId = null;
        _streakTargetController.text = '5';
      }
    });
  }

  Future<void> _openRewardsScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RewardsScreen()),
    );

    if (!mounted) return;

    setState(() {
      _revalidateSelectedRewards();
    });
  }

  Widget _buildImagePreview() {
    if (_imagePath.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    if (kIsWeb) {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 140, minHeight: 90),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Billede valgt, men forhåndsvisning understøttes ikke i webversionen endnu.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 140, minHeight: 90),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(_imagePath),
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox(
              height: 90,
              child: Center(child: Text('Kunne ikke vise billedet')),
            );
          },
        ),
      ),
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
        const SnackBar(content: Text('Sluttid skal være efter starttid.')),
      );
      return;
    }

    if (_currentFamilyId == null || _currentParentProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunne ikke finde familie eller profil.')),
      );
      return;
    }

    if (_selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vælg mindst én deltager.')));
      return;
    }

    final participants = _buildParticipants();

    if (participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vælg mindst én gyldig deltager.')),
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

    if (_enableStreakReward) {
      final streakTarget = int.tryParse(_streakTargetController.text.trim());

      if (streakTarget == null || streakTarget < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Angiv et gyldigt mål for langsigtet belønning.'),
          ),
        );
        return;
      }
    }

    final checklistItems = _buildChecklistItems();

    final activity = Activity(
      id: widget.existingActivity?.id ?? _uuid.v4(),
      familyId: _currentFamilyId!,
      title: _titleController.text.trim(),
      emoji: _emojiController.text.trim(),
      description: _descriptionController.text.trim(),
      startTime: startDateTime,
      endTime: endDateTime,
      createdBy: _currentParentProfile!.authUserId,
      ownerProfileId: _resolveOwnerProfileId(),
      isCompleted: widget.existingActivity?.isCompleted ?? false,
      isImportant: widget.existingActivity?.isImportant ?? false,
      isFavorite: _isFavorite,
      imagePath: _imagePath.trim(),
      directRewardId: _enableDirectReward ? _selectedDirectRewardId : null,
      streakRewardId: _enableStreakReward ? _selectedStreakRewardId : null,
      streakTarget: _enableStreakReward
          ? int.tryParse(_streakTargetController.text.trim()) ?? 5
          : null,
      recurrence: _selectedRecurrence == ActivityRecurrence.custom
          ? _selectedCustomRecurrence
          : _selectedRecurrence,
      recurrenceInterval: _selectedRecurrence == ActivityRecurrence.none
          ? 1
          : parsedInterval,
      recurrenceEndDate: _selectedRecurrence == ActivityRecurrence.none
          ? null
          : _recurrenceEndDate,
      createdAt: widget.existingActivity?.createdAt,
      updatedAt: widget.existingActivity?.updatedAt,
      participants: participants,
      checklistItems: checklistItems,
    );

    Navigator.pop(context, activity);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfiles) {
      return const Scaffold(
        backgroundColor: Color(0xFFA2E5AD),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profilesError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFA2E5AD),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 34,
                    color: Colors.black54,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _profilesError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoadingProfiles = true;
                        _profilesError = null;
                      });

                      _loadProfiles();
                    },
                    child: const Text('Prøv igen'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tilbage'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final title = _isEditing ? 'Rediger aktivitet' : 'Ny aktivitet';
    final directRewards = _directRewards();
    final streakRewards = _streakRewards();

    final availableParticipantOptions = _participantOptions
        .where((option) => !_selectedParticipants.contains(option))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFA2E5AD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(title: title, onBack: () => Navigator.pop(context)),
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
                        ExpansionTile(
                          leading: const Icon(Icons.tune),
                          title: Text(
                            _showMoreSettings
                                ? 'Færre indstillinger'
                                : 'Flere indstillinger',
                          ),
                          onExpansionChanged: (expanded) {
                            setState(() {
                              _showMoreSettings = expanded;
                            });
                          },
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                12,
                                12,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  DropdownButtonFormField<ActivityRecurrence>(
                                    initialValue: _selectedRecurrence,
                                    decoration: const InputDecoration(
                                      labelText: 'Gentag aktivitet',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: ActivityRecurrence.values.map((
                                      recurrence,
                                    ) {
                                      return DropdownMenuItem<
                                        ActivityRecurrence
                                      >(
                                        value: recurrence,
                                        child: Text(
                                          _recurrenceLabel(recurrence),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value == null) return;

                                      setState(() {
                                        _selectedRecurrence = value;
                                      });
                                    },
                                  ),
                                  if (_selectedRecurrence !=
                                      ActivityRecurrence.none) ...[
                                    const SizedBox(height: 12),
                                    if (_selectedRecurrence ==
                                        ActivityRecurrence.custom) ...[
                                      DropdownButtonFormField<
                                        ActivityRecurrence
                                      >(
                                        initialValue: _selectedCustomRecurrence,
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
                                        labelText:
                                            _selectedRecurrence ==
                                                ActivityRecurrence.custom
                                            ? 'Hver X ${_intervalSuffix(_selectedCustomRecurrence)}'
                                            : 'Hver X ${_intervalSuffix(_selectedRecurrence)}',
                                        border: const OutlineInputBorder(),
                                        hintText: 'f.eks. 2',
                                      ),
                                      validator: (value) {
                                        if (_selectedRecurrence ==
                                            ActivityRecurrence.none) {
                                          return null;
                                        }

                                        final number = int.tryParse(
                                          (value ?? '').trim(),
                                        );

                                        if (number == null || number < 1) {
                                          return 'Skriv et tal på mindst 1';
                                        }

                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 12),
                                    _PickerTile(
                                      label: 'Gentag indtil',
                                      value: _recurrenceEndDate == null
                                          ? 'Ingen slutdato'
                                          : _formatDate(_recurrenceEndDate!),
                                      icon: Icons.event_available_outlined,
                                      onTap: _pickRecurrenceEndDate,
                                    ),
                                    if (_recurrenceEndDate != null)
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _recurrenceEndDate = null;
                                          });
                                        },
                                        child: const Text('Fjern slutdato'),
                                      ),
                                  ],
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    key: ValueKey(_participantDropdownResetKey),
                                    initialValue: null,
                                    decoration: const InputDecoration(
                                      labelText: 'Tilføj deltagere',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: availableParticipantOptions.map((
                                      participant,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: participant,
                                        child: Text(participant),
                                      );
                                    }).toList(),
                                    onChanged:
                                        availableParticipantOptions.isEmpty
                                        ? null
                                        : (value) {
                                            if (value == null) return;

                                            setState(() {
                                              _selectedParticipants =
                                                  _uniqueStrings([
                                                    ..._selectedParticipants,
                                                    value,
                                                  ]);
                                              _participantDropdownResetKey++;
                                              _revalidateSelectedRewards();
                                            });
                                          },
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed:
                                          _showAddExternalParticipantDialog,
                                      icon: const Icon(Icons.person_add_alt_1),
                                      label: const Text(
                                        'Tilføj andre deltagere',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (_selectedParticipants.isEmpty)
                                    const Text(
                                      'Ingen deltagere valgt',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 14,
                                      ),
                                    )
                                  else
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _selectedParticipants.map((
                                        participant,
                                      ) {
                                        return Chip(
                                          label: Text(participant),
                                          onDeleted: () {
                                            setState(() {
                                              _selectedParticipants.remove(
                                                participant,
                                              );
                                              _participantDropdownResetKey++;
                                              _revalidateSelectedRewards();
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  const SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFFBDBDBD),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 220,
                                          child: SingleChildScrollView(
                                            padding: const EdgeInsets.fromLTRB(
                                              12,
                                              12,
                                              12,
                                              12,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                TextField(
                                                  controller:
                                                      _descriptionController,
                                                  keyboardType:
                                                      TextInputType.multiline,
                                                  textInputAction:
                                                      TextInputAction.newline,
                                                  minLines: 4,
                                                  maxLines: null,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText:
                                                            'Beskrivelse',
                                                        alignLabelWithHint:
                                                            true,
                                                        border:
                                                            InputBorder.none,
                                                        isCollapsed: true,
                                                      ),
                                                ),
                                                if (_imagePath
                                                    .trim()
                                                    .isNotEmpty) ...[
                                                  const SizedBox(height: 12),
                                                  Stack(
                                                    children: [
                                                      _buildImagePreview(),
                                                      Positioned(
                                                        top: 6,
                                                        right: 6,
                                                        child: Material(
                                                          color: Colors.white,
                                                          shape:
                                                              const CircleBorder(),
                                                          elevation: 2,
                                                          child: IconButton(
                                                            tooltip:
                                                                'Slet billede',
                                                            onPressed:
                                                                _removeImage,
                                                            icon: const Icon(
                                                              Icons.close,
                                                              size: 18,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
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
                                                      : Icons
                                                            .card_giftcard_outlined,
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
                                                      : Icons
                                                            .checklist_outlined,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: 'Tilføj billede',
                                                onPressed:
                                                    _showImageSourceDialog,
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
                                  if (_showChecklist) ...[
                                    const SizedBox(height: 12),
                                    ...List.generate(_checklistControllers.length, (
                                      index,
                                    ) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
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
                                                controller:
                                                    _checklistControllers[index],
                                                decoration: InputDecoration(
                                                  hintText:
                                                      'Punkt ${index + 1}',
                                                  border:
                                                      const OutlineInputBorder(),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              onPressed: () =>
                                                  _removeChecklistItem(index),
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
                                    SwitchListTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      tileColor: const Color(0xFFF8F8F8),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                      title: const Text('Direkte belønning'),
                                      subtitle: const Text(
                                        'Belønning efter én aktivitet.',
                                      ),
                                      value: _enableDirectReward,
                                      onChanged: (value) {
                                        setState(() {
                                          _enableDirectReward = value;
                                          if (!value) {
                                            _selectedDirectRewardId = null;
                                          }
                                        });
                                      },
                                    ),
                                    if (_enableDirectReward) ...[
                                      const SizedBox(height: 10),
                                      DropdownButtonFormField<String>(
                                        initialValue:
                                            directRewards.any(
                                              (r) =>
                                                  r.id ==
                                                  _selectedDirectRewardId,
                                            )
                                            ? _selectedDirectRewardId
                                            : null,
                                        decoration: const InputDecoration(
                                          labelText: 'Vælg direkte belønning',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: directRewards
                                            .map(
                                              (reward) =>
                                                  DropdownMenuItem<String>(
                                                    value: reward.id,
                                                    child: Text(
                                                      _rewardDropdownLabel(
                                                        reward,
                                                      ),
                                                    ),
                                                  ),
                                            )
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedDirectRewardId = value;
                                          });
                                        },
                                      ),
                                      if (directRewards.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: TextButton.icon(
                                            onPressed: _openRewardsScreen,
                                            icon: const Icon(Icons.add),
                                            label: const Text(
                                              'Ingen direkte belønninger fundet – opret en',
                                            ),
                                          ),
                                        ),
                                    ],
                                    const SizedBox(height: 12),
                                    SwitchListTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      tileColor: const Color(0xFFF8F8F8),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                      title: const Text('Langsigtet belønning'),
                                      subtitle: const Text(
                                        'Belønning efter flere gennemførelser.',
                                      ),
                                      value: _enableStreakReward,
                                      onChanged: (value) {
                                        setState(() {
                                          _enableStreakReward = value;
                                          if (!value) {
                                            _selectedStreakRewardId = null;
                                            _streakTargetController.text = '5';
                                          }
                                        });
                                      },
                                    ),
                                    if (_enableStreakReward) ...[
                                      const SizedBox(height: 10),
                                      DropdownButtonFormField<String>(
                                        initialValue:
                                            streakRewards.any(
                                              (r) =>
                                                  r.id ==
                                                  _selectedStreakRewardId,
                                            )
                                            ? _selectedStreakRewardId
                                            : null,
                                        decoration: const InputDecoration(
                                          labelText:
                                              'Vælg langsigtet belønning',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: streakRewards
                                            .map(
                                              (reward) =>
                                                  DropdownMenuItem<String>(
                                                    value: reward.id,
                                                    child: Text(
                                                      _rewardDropdownLabel(
                                                        reward,
                                                      ),
                                                    ),
                                                  ),
                                            )
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedStreakRewardId = value;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      TextFormField(
                                        controller: _streakTargetController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Opnås efter X gange',
                                          border: OutlineInputBorder(),
                                          hintText: 'f.eks. 5',
                                        ),
                                        validator: (value) {
                                          if (!_enableStreakReward) return null;

                                          final number = int.tryParse(
                                            (value ?? '').trim(),
                                          );

                                          if (number == null || number < 1) {
                                            return 'Skriv et tal på mindst 1';
                                          }

                                          return null;
                                        },
                                      ),
                                      if (streakRewards.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: TextButton.icon(
                                            onPressed: _openRewardsScreen,
                                            icon: const Icon(Icons.add),
                                            label: const Text(
                                              'Ingen langsigtede belønninger fundet – opret en',
                                            ),
                                          ),
                                        ),
                                    ],
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8F8F8),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Valgt nu: direkte = ${_rewardTitleById(_selectedDirectRewardId)}, langsigtet = ${_rewardTitleById(_selectedStreakRewardId)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
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

  const _TopBar({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, size: 30, color: Colors.black),
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
                style: const TextStyle(fontSize: 15, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
