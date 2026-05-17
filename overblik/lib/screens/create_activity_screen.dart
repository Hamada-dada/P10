import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../models/activity.dart';
import '../models/profile.dart';
import '../models/reward.dart';
import '../services/notification_preferences.dart';
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
  List<Reward> _rewards = [];

  bool _isLoadingProfiles = true;
  String? _profilesError;

  Profile? _currentProfile;
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

  bool _notificationsEnabled = true;
  int _reminderMinutesBefore = 10;
  bool _isCustomReminder = false;
  late TextEditingController _customAmountController;
  String _customReminderUnit = 'minutter';
  String _notificationStyle = 'tydelig';

  bool _recurrenceEnabled = false;

  bool _enableDirectReward = false;
  bool _enableStreakReward = false;

  String? _selectedDirectRewardId;
  String? _selectedStreakRewardId;

  late List<String> _selectedParticipants;
  late List<TextEditingController> _checklistControllers;
  late ActivityRecurrence _selectedRecurrence;

  String _imagePath = '';
  bool _isUploadingImage = false;
  String? _pendingLocalImagePath;

  bool get _isEditing => widget.existingActivity != null;

  String? get _currentAuthUserId {
    return Supabase.instance.client.auth.currentUser?.id;
  }

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
    _notificationsEnabled = activity?.notificationsEnabled ?? true;
    _reminderMinutesBefore = activity?.reminderMinutesBefore ?? 10;
    _isCustomReminder = !NotificationPreferencesService.isFixedOption(
      _reminderMinutesBefore,
    );
    final customInit = _minutesToAmountUnit(_reminderMinutesBefore);
    _customAmountController = TextEditingController(
      text: _isCustomReminder ? customInit.amount.toString() : '',
    );
    _customReminderUnit = _isCustomReminder ? customInit.unit : 'minutter';
    _notificationStyle = activity?.notificationStyle ?? 'tydelig';

    if (!_isEditing) {
      _loadNotificationDefaults();
    }
    _showChecklist = activity?.checklistItems.isNotEmpty ?? false;

    _enableDirectReward = activity?.directRewardId != null;
    _enableStreakReward = activity?.streakRewardId != null;
    _showRewardFields = _enableDirectReward || _enableStreakReward;

    _selectedDirectRewardId = activity?.directRewardId;
    _selectedStreakRewardId = activity?.streakRewardId;

    _selectedParticipants = <String>[];

    _selectedRecurrence = activity?.recurrence ?? ActivityRecurrence.none;
    _recurrenceEnabled = _selectedRecurrence != ActivityRecurrence.none;

    final initialChecklist = activity?.checklistItems ?? [];
    _checklistControllers = initialChecklist.isNotEmpty
        ? initialChecklist
        .map((item) => TextEditingController(text: item.title))
        .toList()
        : [];

    _revalidateSelectedRewards();
    _loadProfiles();
    _loadRewards();
  }

  List<Profile> get _childProfiles {
    return _availableProfiles.where((profile) => profile.isChild).toList();
  }

  @override
  void dispose() {

  _titleController.dispose();

  _emojiController.dispose();

  _descriptionController.dispose();

  _recurrenceIntervalController.dispose();

  _streakTargetController.dispose();

  _customAmountController.dispose();

  for

  (

  final controller in _checklistControllers) {
  controller.dispose();
  }

  super

      .

  dispose

  (

  );
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

Future<void> _loadNotificationDefaults() async {
  final svc = NotificationPreferencesService();
  final enabled = await svc.loadDefaultEnabled();
  final minutes = await svc.loadDefaultReminderMinutes();
  final style = await svc.loadDefaultNotificationStyle();
  if (!mounted) return;
  final isCustom = !NotificationPreferencesService.isFixedOption(minutes);
  setState(() {
    _notificationsEnabled = enabled;
    _reminderMinutesBefore = minutes;
    _isCustomReminder = isCustom;
    _notificationStyle = style;
    if (isCustom) {
      final init = _minutesToAmountUnit(minutes);
      _customAmountController.text = init.amount.toString();
      _customReminderUnit = init.unit;
    }
  });
}

Future<void> _loadProfiles() async {
  try {
    final currentProfile =
    await _profileService.getCurrentAuthenticatedProfile();

    if (currentProfile == null) {
      if (!mounted) return;

      final l = AppLocalizations.of(context);
      setState(() {
        _availableProfiles = [];
        _currentProfile = null;
        _currentFamilyId = null;
        _participantOptions = [];
        _selectedParticipants = [];
        _isLoadingProfiles = false;
        _profilesError = l.errorProfileNotFound;
      });

      return;
    }

    if (currentProfile.isChildLimited) {
      if (!mounted) return;

      final l = AppLocalizations.of(context);
      setState(() {
        _availableProfiles = [];
        _currentProfile = currentProfile;
        _currentFamilyId = currentProfile.familyId;
        _participantOptions = [];
        _selectedParticipants = [];
        _isLoadingProfiles = false;
        _profilesError = l.errorChildLimitedNoCreate;
      });

      return;
    }

    final profiles = currentProfile.isParent
        ? await _profileService.getFamilyProfiles(currentProfile.familyId)
        : await _profileService.getFamilyProfilesForCurrentUser();

    final selectedParticipants = <String>[];
    final externalParticipantOptions = <String>[];

    if (_isEditing && widget.existingActivity != null) {
      final existingActivity = widget.existingActivity!;

      if (existingActivity.visibility == ActivityVisibility.family) {
        selectedParticipants.add('Familie');
      }

      for (final participant in existingActivity.participants) {
        final externalName = participant.externalName?.trim();

        if (externalName != null && externalName.isNotEmpty) {
          if (externalName == 'Familie') {
            selectedParticipants.add('Familie');
            continue;
          }

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
      selectedParticipants.add(currentProfile.name);
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
      uniqueSelectedParticipants.add(currentProfile.name);
    }

    if (!mounted) return;

    setState(() {
      _availableProfiles = profiles;
      _currentProfile = currentProfile;
      _currentFamilyId = currentProfile.familyId;
      _participantOptions = participantOptions;
      _selectedParticipants = uniqueSelectedParticipants;
      _isLoadingProfiles = false;
      _profilesError = null;
    });
  } catch (e, st) {
    debugPrint('CreateActivityScreen _loadProfiles failed: $e');
    debugPrintStack(stackTrace: st);

    if (!mounted) return;

    final l = AppLocalizations.of(context);
    setState(() {
      _availableProfiles = [];
      _currentProfile = null;
      _currentFamilyId = null;
      _participantOptions = [];
      _selectedParticipants = [];
      _isLoadingProfiles = false;
      _profilesError = l.errorLoadProfiles(e);
    });
  }
}

Future<void> _loadRewards() async {
  try {
    final rewards = await _rewardService.getAllRewards();

    if (!mounted) return;

    setState(() {
      _rewards = rewards;
    });
  } catch (e) {
    debugPrint('CreateActivityScreen _loadRewards failed: $e');
  }
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

({int amount, String unit}) _minutesToAmountUnit(int minutes) {
  if (minutes > 0 && minutes % 10080 == 0) {
    return (amount: minutes ~/ 10080, unit: 'uger');
  }
  if (minutes > 0 && minutes % 1440 == 0) {
    return (amount: minutes ~/ 1440, unit: 'dage');
  }
  if (minutes > 0 && minutes % 60 == 0) {
    return (amount: minutes ~/ 60, unit: 'timer');
  }
  return (amount: minutes, unit: 'minutter');
}

int _amountUnitToMinutes(int amount, String unit) {
  switch (unit) {
    case 'uger':
      return amount * 10080;
    case 'dage':
      return amount * 1440;
    case 'timer':
      return amount * 60;
    default:
      return amount;
  }
}


List<Reward> _availableRewards() {
  final rewards = List<Reward>.from(_rewards);

  rewards.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
  );

  return rewards;
}

List<Reward> _directRewards() {
  return _availableRewards()
      .where((reward) => reward.type == RewardType.direct)
      .toList();
}

List<Reward> _streakRewards() {
  return _availableRewards()
      .where((reward) => reward.type == RewardType.streak)
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

String _rewardTitleById(String? rewardId, AppLocalizations l) {
  if (rewardId == null) return l.noneSelected;

  try {
    return _rewards.firstWhere((reward) => reward.id == rewardId).title;
  } catch (_) {
    return l.unknownReward;
  }
}

String _rewardDropdownLabel(Reward reward) {
  final emoji = reward.emoji
      .trim()
      .isEmpty ? '🎁' : reward.emoji;
  return '$emoji ${reward.title}';
}

String? _resolveOwnerProfileId() {
  return _currentProfile?.id;
}

ActivityVisibility _resolveVisibility() {
  if (_selectedParticipants.contains('Familie')) {
    return ActivityVisibility.family;
  }

  return ActivityVisibility.participants;
}

List<ActivityParticipant> _buildParticipants() {
  final participants = <ActivityParticipant>[];

  for (final selected in _selectedParticipants) {
    final cleanSelected = selected.trim();

    if (cleanSelected.isEmpty) continue;

    if (cleanSelected == 'Familie') {
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
        (index) =>
        ActivityChecklistItem(
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
    final startMinutes = picked.hour * 60 + picked.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (endMinutes <= startMinutes) {
      final newEnd = startMinutes + 60;
      _endTime = TimeOfDay(hour: (newEnd ~/ 60) % 24, minute: newEnd % 60);
    }
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
      _pendingLocalImagePath = pickedFile.path;
      _isUploadingImage = true;
    });

    final familyId = _currentFamilyId;
    if (familyId == null) throw Exception('Familienøgle mangler');

    final ext = pickedFile.path
        .split('.')
        .last
        .toLowerCase();
    final storagePath = '$familyId/${_uuid.v4()}.$ext';
    final bytes = await pickedFile.readAsBytes();

    await Supabase.instance.client.storage
        .from('activity-images')
        .uploadBinary(storagePath, bytes);

    final publicUrl = Supabase.instance.client.storage
        .from('activity-images')
        .getPublicUrl(storagePath);

    setState(() {
      _imagePath = publicUrl;
      _pendingLocalImagePath = null;
      _isUploadingImage = false;
    });
  } catch (e) {
    setState(() {
      _imagePath = '';
      _pendingLocalImagePath = null;
      _isUploadingImage = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).errorUploadImage(e))),
    );
  }
}

void _removeImage() {
  setState(() {
    _imagePath = '';
    _pendingLocalImagePath = null;
  });
}

Future<void> _showImageSourceDialog() async {
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final l = AppLocalizations.of(sheetContext);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l.chooseFromGallery),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(l.takePhoto),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _pickImage(ImageSource.camera);
                },
              ),
              if (_imagePath
                  .trim()
                  .isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: Text(l.deleteImageLabel),
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
  final l = AppLocalizations.of(context);
  final value = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      final controller = TextEditingController();
      return StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: Text(l.addExternalParticipantDialog),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Navn',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(dialogContext, text);
              },
              child: Text(l.add),
            ),
          ],
        ),
      );
    },
  );

  if (!mounted || value == null || value.trim().isEmpty) {
    return;
  }

  final participant = value.trim();

  if (participant == 'Familie') {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.familyNameReserved)),
    );
    return;
  }

  if (_participantOptions.any((o) => o.toLowerCase() == participant.toLowerCase())) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.participantAlreadyExists(participant))),
    );
    return;
  }

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
    final controller = _checklistControllers.removeAt(index);
    controller.dispose();

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
      _enableDirectReward = false;
      _enableStreakReward = false;
      _selectedDirectRewardId = null;
      _selectedStreakRewardId = null;
      _streakTargetController.text = '5';
    }
  });
}

Future<void> _openCreateRewardDialog(RewardType rewardType) async {
  final childProfiles = _childProfiles;

  if (childProfiles.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).needChildFirst)),
    );
    return;
  }

  final titleController = TextEditingController();
  final emojiController = TextEditingController();
  final descriptionController = TextEditingController();
  final targetCountController = TextEditingController(
    text: rewardType == RewardType.direct ? '1' : _streakTargetController.text,
  );

  Profile selectedProfile = childProfiles.first;
  bool isSaving = false;
  final l = AppLocalizations.of(context);

  final createdReward = await showDialog<Reward>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(
              rewardType == RewardType.direct
                  ? l.createDirectRewardDialogTitle
                  : l.createStreakRewardDialogTitle,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: l.title,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emojiController,
                    decoration: InputDecoration(
                      labelText: 'Emoji',
                      hintText: l.emojiHintReward,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l.description,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedProfile.id,
                    decoration: InputDecoration(
                      labelText: l.belongsToChild,
                      border: const OutlineInputBorder(),
                    ),
                    items: childProfiles.map((profile) {
                      return DropdownMenuItem<String>(
                        value: profile.id,
                        child: Text('${profile.emoji} ${profile.name}'),
                      );
                    }).toList(),
                    onChanged: isSaving
                        ? null
                        : (value) {
                      if (value == null) return;

                      final profile = childProfiles.firstWhere(
                            (profile) => profile.id == value,
                      );

                      setDialogState(() {
                        selectedProfile = profile;
                      });
                    },
                  ),
                  if (rewardType == RewardType.streak) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: targetCountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l.completionCountStreak,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: Text(l.cancel),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                  final title = titleController.text.trim();
                  final emoji = emojiController.text.trim();
                  final description = descriptionController.text.trim();
                  final targetCount =
                      int.tryParse(targetCountController.text.trim()) ?? 1;

                  if (title.isEmpty) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text(l.rewardTitleRequired)),
                    );
                    return;
                  }

                  if (targetCount < 1) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text(l.amountMin1)),
                    );
                    return;
                  }

                  setDialogState(() {
                    isSaving = true;
                  });

                  try {
                    final reward = Reward(
                      id: '',
                      familyId: selectedProfile.familyId,
                      profileId: selectedProfile.id,
                      title: title,
                      emoji: emoji.isEmpty ? '🎁' : emoji,
                      description: description,
                      type: rewardType,
                      targetCount:
                      rewardType == RewardType.direct ? 1 : targetCount,
                      currentCount: 0,
                      isTriggered: false,
                    );

                    await _rewardService.addReward(reward);
                    final rewards = await _rewardService.getAllRewards();

                    final savedReward = rewards.firstWhere(
                          (r) =>
                      r.title == reward.title &&
                          r.profileId == reward.profileId &&
                          r.type == reward.type,
                      orElse: () => reward,
                    );

                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext, savedReward);
                  } catch (e) {
                    if (!dialogContext.mounted) return;

                    setDialogState(() {
                      isSaving = false;
                    });

                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text(l.errorCreateReward(e))),
                    );
                  }
                },
                child: isSaving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(l.save),
              ),
            ],
          );
        },
      );
    },
  );

  if (createdReward == null) return;

  await _loadRewards();

  if (!mounted) return;

  setState(() {
    if (rewardType == RewardType.direct) {
      _enableDirectReward = true;
      _selectedDirectRewardId = createdReward.id;
    } else {
      _enableStreakReward = true;
      _selectedStreakRewardId = createdReward.id;
      _streakTargetController.text = createdReward.targetCount.toString();
    }
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context).rewardCreated)),
  );
}

Widget _buildImagePreview() {
  final hasImage = _imagePath
      .trim()
      .isNotEmpty || _pendingLocalImagePath != null;
  if (!hasImage) return const SizedBox.shrink();

  final containerDecoration = BoxDecoration(
    color: const Color(0xFFF8F8F8),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: const Color(0xFFE0E0E0)),
  );

  if (_isUploadingImage) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: containerDecoration,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  if (_imagePath.startsWith('http')) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 140, minHeight: 90),
      decoration: containerDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          _imagePath,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return SizedBox(
              height: 90,
              child: Center(child: Text(AppLocalizations.of(context).couldNotLoadImage)),
            );
          },
        ),
      ),
    );
  }

  if (kIsWeb) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 140, minHeight: 90),
      decoration: containerDecoration,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            AppLocalizations.of(context).imagePreviewNotSupported,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  return Container(
    width: double.infinity,
    constraints: const BoxConstraints(maxHeight: 140, minHeight: 90),
    decoration: containerDecoration,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(
        File(_imagePath),
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return SizedBox(
            height: 90,
            child: Center(child: Text(AppLocalizations.of(context).couldNotLoadImage)),
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

  final authUserId = _currentAuthUserId;
  final currentProfile = _currentProfile;
  final currentFamilyId = _currentFamilyId;

  if (authUserId == null || authUserId
      .trim()
      .isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).errorNotLoggedIn)),
    );
    return;
  }

  if (currentProfile == null || currentFamilyId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).errorFamilyOrProfile)),
    );
    return;
  }

  if (currentProfile.isChildLimited) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).childCannotCreateActivities)),
    );
    return;
  }

  final startDateTime = _combineDateAndTime(_selectedDate, _startTime);
  final endDateTime = _combineDateAndTime(_selectedDate, _endTime);

  if (!endDateTime.isAfter(startDateTime)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).endAfterStart)),
    );
    return;
  }

  if (_selectedParticipants.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).selectAtLeastOneParticipant)),
    );
    return;
  }

  final visibility = _resolveVisibility();
  final participants = _buildParticipants();

  if (participants.isEmpty && visibility != ActivityVisibility.family) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).selectAtLeastOneValidParticipant)),
    );
    return;
  }

  final parsedInterval =
      int.tryParse(_recurrenceIntervalController.text.trim()) ?? 1;

  if (_recurrenceEnabled && parsedInterval < 1) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).recurrenceIntervalMin)),
    );
    return;
  }

  if (_enableStreakReward) {
    final streakTarget = int.tryParse(_streakTargetController.text.trim());

    if (streakTarget == null || streakTarget < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).streakTargetValid)),
      );
      return;
    }
  }

  final checklistItems = _buildChecklistItems();

  final activity = Activity(
    id: widget.existingActivity?.id ?? _uuid.v4(),
    familyId: currentFamilyId,
    title: _titleController.text.trim(),
    emoji: _emojiController.text.trim(),
    description: _descriptionController.text.trim(),
    startTime: startDateTime,
    endTime: endDateTime,
    createdBy: widget.existingActivity?.createdBy ?? authUserId,
    ownerProfileId: widget.existingActivity?.ownerProfileId ??
        _resolveOwnerProfileId(),
    visibility: visibility,
    isCompleted: widget.existingActivity?.isCompleted ?? false,
    isImportant: widget.existingActivity?.isImportant ?? false,
    isFavorite: _isFavorite,
    imagePath: _imagePath.trim(),
    directRewardId: _enableDirectReward ? _selectedDirectRewardId : null,
    streakRewardId: _enableStreakReward ? _selectedStreakRewardId : null,
    streakTarget: _enableStreakReward
        ? int.tryParse(_streakTargetController.text.trim()) ?? 5
        : null,
    recurrence: _recurrenceEnabled ? _selectedRecurrence : ActivityRecurrence
        .none,
    recurrenceInterval: _recurrenceEnabled ? parsedInterval : 1,
    recurrenceEndDate: _recurrenceEnabled ? _recurrenceEndDate : null,
    notificationsEnabled: _notificationsEnabled,
    reminderMinutesBefore: _notificationsEnabled && _isCustomReminder
        ? _amountUnitToMinutes(
      int.tryParse(_customAmountController.text.trim()) ?? 1,
      _customReminderUnit,
    )
        : _reminderMinutesBefore,
    notificationStyle: _notificationStyle,
    createdAt: widget.existingActivity?.createdAt,
    updatedAt: widget.existingActivity?.updatedAt,
    participants: participants,
    checklistItems: checklistItems,
  );

  Navigator.pop(context, activity);
}

@override
Widget build(BuildContext context) {
  final l = AppLocalizations.of(context);
  final colorScheme = Theme
      .of(context)
      .colorScheme;
  final isDark = Theme
      .of(context)
      .brightness == Brightness.dark;
  if (_isLoadingProfiles) {
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF050706)
          : colorScheme.primaryContainer,
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  if (_profilesError != null) {
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF050706)
          : colorScheme.primaryContainer,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF171A19) : Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 34,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 12),
                Text(
                  _profilesError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: colorScheme.onSurface,
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
                  child: Text(l.retry),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.back),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  final title = _isEditing ? l.editActivityTitle : l.newActivityTitle;
  final directRewards = _directRewards();
  final streakRewards = _streakRewards();

  final availableParticipantOptions = _participantOptions
      .where((option) => !_selectedParticipants.contains(option))
      .toList();

  return Scaffold(
    backgroundColor: isDark
        ? const Color(0xFF050706)
        : colorScheme.primaryContainer,
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
                  color: isDark ? const Color(0xFF101312) : colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2A2D2C) : Colors
                        .transparent,
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: l.title,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value
                              .trim()
                              .isEmpty) {
                            return l.titleRequired;
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emojiController,
                        decoration: InputDecoration(
                          labelText: 'Emoji',
                          border: const OutlineInputBorder(),
                          hintText: l.emojiHint,
                        ),
                        validator: (value) {
                          if (value == null) return null;

                          if (!_looksLikeSingleEmoji(value)) {
                            return l.singleEmojiOnly;
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _PickerTile(
                        label: l.dateLabel,
                        value: _formatDate(_selectedDate),
                        icon: Icons.calendar_today_outlined,
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _PickerTile(
                              label: l.startLabel,
                              value: _formatTime(_startTime),
                              icon: Icons.schedule,
                              onTap: _pickStartTime,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PickerTile(
                              label: l.endLabel,
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
                              ? l.fewerSettings
                              : l.moreSettings,
                        ),
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _showMoreSettings = expanded;
                          });
                        },
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SwitchListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  tileColor: Theme
                                      .of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  contentPadding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  title: Text(l.notificationsLabel),
                                  subtitle: Text(l.remindAboutActivity),
                                  value: _notificationsEnabled,
                                  onChanged: (value) {
                                    setState(() {
                                      _notificationsEnabled = value;
                                    });
                                  },
                                ),
                                if (_notificationsEnabled) ...[
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<int?>(
                                    key: ValueKey(
                                      _isCustomReminder
                                          ? null
                                          : _reminderMinutesBefore,
                                    ),
                                    initialValue: _isCustomReminder
                                        ? null
                                        : _reminderMinutesBefore,
                                    decoration: InputDecoration(
                                      labelText: l.remindMeLabel,
                                      border: const OutlineInputBorder(),
                                    ),
                                    items: [
                                      ...NotificationPreferencesService
                                          .fixedReminderOptions
                                          .map(
                                            (m) =>
                                            DropdownMenuItem<int?>(
                                              value: m,
                                              child: Text(l.reminderLabel(m)),
                                            ),
                                      ),
                                      DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text(l.customOption),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        if (value != null) {
                                          _isCustomReminder = false;
                                          _reminderMinutesBefore = value;
                                        } else {
                                          _isCustomReminder = true;
                                          final init = _minutesToAmountUnit(
                                            _reminderMinutesBefore,
                                          );
                                          _customAmountController.text =
                                              init.amount.toString();
                                          _customReminderUnit = init.unit;
                                        }
                                      });
                                    },
                                  ),
                                  if (_isCustomReminder) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: TextFormField(
                                            controller: _customAmountController,
                                            keyboardType:
                                            TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: l.amountLabel,
                                              border: const OutlineInputBorder(),
                                            ),
                                            validator: (value) {
                                              if (!_notificationsEnabled ||
                                                  !_isCustomReminder) {
                                                return null;
                                              }
                                              final raw =
                                                  value?.trim() ?? '';
                                              if (raw.isEmpty) {
                                                return l.enterAmount;
                                              }
                                              final amount =
                                              int.tryParse(raw);
                                              if (amount == null ||
                                                  amount < 0) {
                                                return l.enterAmount;
                                              }
                                              final total =
                                              _amountUnitToMinutes(
                                                amount,
                                                _customReminderUnit,
                                              );
                                              if (total > 10080) {
                                                return l.reminderMaxDays;
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          flex: 3,
                                          child:
                                          DropdownButtonFormField<String>(
                                            key: ValueKey(_customReminderUnit),
                                            initialValue: _customReminderUnit,
                                            decoration: InputDecoration(
                                              labelText: l.unitLabel,
                                              border: const OutlineInputBorder(),
                                            ),
                                            items: [
                                              DropdownMenuItem(
                                                value: 'minutter',
                                                child: Text(l.unitMinutes),
                                              ),
                                              DropdownMenuItem(
                                                value: 'timer',
                                                child: Text(l.unitHours),
                                              ),
                                              DropdownMenuItem(
                                                value: 'dage',
                                                child: Text(l.unitDays),
                                              ),
                                              DropdownMenuItem(
                                                value: 'uger',
                                                child: Text(l.unitWeeks),
                                              ),
                                            ],
                                            onChanged: (unit) {
                                              if (unit == null) return;
                                              setState(() {
                                                _customReminderUnit = unit;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<String>(
                                    key: ValueKey(_notificationStyle),
                                    initialValue: _notificationStyle,
                                    decoration: InputDecoration(
                                      labelText: l.notifStyleLabel,
                                      border: const OutlineInputBorder(),
                                    ),
                                    items: NotificationPreferencesService
                                        .notificationStyleOptions
                                        .map(
                                          (s) =>
                                          DropdownMenuItem(
                                            value: s,
                                            child: Text(
                                              l.notificationStyleLabel(s),
                                            ),
                                          ),
                                    )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() {
                                        _notificationStyle = value;
                                      });
                                    },
                                  ),
                                ],
                                const SizedBox(height: 12),
                                SwitchListTile(
                                  value: _recurrenceEnabled,
                                  onChanged: (value) {
                                    setState(() {
                                      _recurrenceEnabled = value;
                                      if (value &&
                                          _selectedRecurrence ==
                                              ActivityRecurrence.none) {
                                        _selectedRecurrence =
                                            ActivityRecurrence.daily;
                                      }
                                    });
                                  },
                                  title: Text(l.repeatActivityLabel),
                                  contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  tileColor: colorScheme
                                      .surfaceContainerHighest,
                                ),
                                if (_recurrenceEnabled) ...[
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<ActivityRecurrence>(
                                    key: ValueKey(_recurrenceEnabled),
                                    initialValue: _selectedRecurrence ==
                                        ActivityRecurrence.none
                                        ? ActivityRecurrence.daily
                                        : _selectedRecurrence,
                                    decoration: InputDecoration(
                                      labelText: l.recurrenceLabel,
                                      border: const OutlineInputBorder(),
                                    ),
                                    items: ActivityRecurrence.values
                                        .where(
                                          (r) =>
                                      r != ActivityRecurrence.none &&
                                          r != ActivityRecurrence.custom,
                                    )
                                        .map(
                                          (r) =>
                                          DropdownMenuItem(
                                            value: r,
                                            child: Text(l.recurrenceEnumLabel(r)),
                                          ),
                                    )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(
                                            () => _selectedRecurrence = value,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _recurrenceIntervalController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText:
                                      '${l.everyXPrefix} ${l.intervalSuffix(_selectedRecurrence)}',
                                      border: const OutlineInputBorder(),
                                      hintText: l.intervalHint,
                                    ),
                                    validator: (value) {
                                      if (!_recurrenceEnabled) return null;
                                      final number = int.tryParse(
                                        (value ?? '').trim(),
                                      );
                                      if (number == null || number < 1) {
                                        return l.numberMin1;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _PickerTile(
                                    label: l.repeatUntilLabel,
                                    value: _recurrenceEndDate == null
                                        ? l.noEndDate
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
                                      child: Text(l.removeEndDate),
                                    ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        key: ValueKey(
                                            _participantDropdownResetKey),
                                        initialValue: null,
                                        decoration: InputDecoration(
                                          labelText: l.addParticipantsLabel,
                                          border: const OutlineInputBorder(),
                                        ),
                                        items: availableParticipantOptions
                                            .map((participant) {
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
                                    ),
                                    const SizedBox(width: 8),
                                    Tooltip(
                                      message: l.addOtherParticipants,
                                      child: IconButton(
                                        onPressed:
                                        _showAddExternalParticipantDialog,
                                        icon: const Icon(
                                            Icons.person_add_alt_1),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (_selectedParticipants.isEmpty)
                                  Text(
                                    l.noParticipantsSelected,
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withValues(
                                          alpha: 0.6),
                                      fontSize: 14,
                                    ),
                                  )
                                else
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _selectedParticipants.map(
                                          (participant) {
                                        return Chip(
                                          label: Text(participant),
                                          onDeleted: () {
                                            setState(() {
                                              _selectedParticipants
                                                  .remove(participant);
                                              _participantDropdownResetKey++;
                                              _revalidateSelectedRewards();
                                            });
                                          },
                                        );
                                      },
                                    ).toList(),
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
                                                InputDecoration(
                                                  labelText: l.description,
                                                  alignLabelWithHint: true,
                                                  border: InputBorder.none,
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
                                                        color: isDark
                                                            ? const Color(
                                                            0xFF171A19)
                                                            : Colors.white,
                                                        shape:
                                                        const CircleBorder(),
                                                        elevation: 2,
                                                        child: IconButton(
                                                          tooltip: l.deleteImageLabel,
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
                                              tooltip: l.favouriteTooltip,
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
                                                    : colorScheme.onSurface,
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: l.rewardTooltip,
                                              onPressed: _toggleRewardFields,
                                              icon: Icon(
                                                _showRewardFields
                                                    ? Icons.card_giftcard
                                                    : Icons
                                                    .card_giftcard_outlined,
                                                color: _showRewardFields
                                                    ? colorScheme.primary
                                                    : colorScheme.onSurface,
                                              ),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              tooltip: l.checklistTooltip,
                                              onPressed: _toggleChecklist,
                                              icon: Icon(
                                                _showChecklist
                                                    ? Icons.checklist_rtl
                                                    : Icons.checklist_outlined,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: l.addImageTooltip,
                                              onPressed:
                                              _showImageSourceDialog,
                                              icon: Icon(
                                                Icons.camera_alt_outlined,
                                                color: colorScheme.onSurface,
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
                                  ...List.generate(
                                    _checklistControllers.length,
                                        (index) {
                                      return Padding(
                                        padding:
                                        const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.check_box_outline_blank,
                                              size: 22,
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextField(
                                                controller:
                                                _checklistControllers[index],
                                                decoration: InputDecoration(
                                                  hintText: l.checklistItemHint(index + 1),
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
                                    },
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed: _addChecklistItem,
                                      icon: const Icon(Icons.add),
                                      label: Text(l.addChecklistItem),
                                    ),
                                  ),
                                ],
                                if (_showRewardFields) ...[
                                  const SizedBox(height: 12),
                                  SwitchListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    tileColor: colorScheme
                                        .surfaceContainerHighest,
                                    contentPadding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    title: Text(l.directRewardLabel),
                                    subtitle: Text(l.directRewardSubtitle),
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
                                      initialValue: directRewards.any(
                                            (r) => r.id == _selectedDirectRewardId,
                                      )
                                          ? _selectedDirectRewardId
                                          : null,
                                      decoration: InputDecoration(
                                        labelText: l.selectDirectReward,
                                        border: const OutlineInputBorder(),
                                      ),
                                      items: directRewards.map((reward) {
                                        return DropdownMenuItem<String>(
                                          value: reward.id,
                                          child: Text(_rewardDropdownLabel(reward)),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedDirectRewardId = value;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        onPressed: () => _openCreateRewardDialog(RewardType.direct),
                                        icon: const Icon(Icons.add),
                                        label: Text(l.createNewDirectReward),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  SwitchListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    tileColor: colorScheme
                                        .surfaceContainerHighest,
                                    contentPadding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    title: Text(l.streakRewardLabel),
                                    subtitle: Text(l.streakRewardSubtitle),
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
                                      initialValue: streakRewards.any(
                                            (r) => r.id == _selectedStreakRewardId,
                                      )
                                          ? _selectedStreakRewardId
                                          : null,
                                      decoration: InputDecoration(
                                        labelText: l.selectStreakReward,
                                        border: const OutlineInputBorder(),
                                      ),
                                      items: streakRewards.map((reward) {
                                        return DropdownMenuItem<String>(
                                          value: reward.id,
                                          child: Text(_rewardDropdownLabel(reward)),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedStreakRewardId = value;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        onPressed: () => _openCreateRewardDialog(RewardType.streak),
                                        icon: const Icon(Icons.add),
                                        label: Text(l.createNewStreakReward),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: _streakTargetController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: l.streakTargetLabel,
                                        border: const OutlineInputBorder(),
                                        hintText: l.streakTargetHint,
                                      ),
                                      validator: (value) {
                                        if (!_enableStreakReward) return null;

                                        final number = int.tryParse(
                                          (value ?? '').trim(),
                                        );

                                        if (number == null || number < 1) {
                                          return l.numberMin1;
                                        }

                                        return null;
                                      },
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF2A2D2C)
                                            : const Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    child: Text(
                                      l.selectedRewardsSummary(
                                        _rewardTitleById(_selectedDirectRewardId, l),
                                        _rewardTitleById(_selectedStreakRewardId, l),
                                      ),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colorScheme.onSurface,
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
                          onPressed: _isUploadingImage ? null : _saveActivity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              _isEditing ? l.saveChangesButton : l.saveActivityButton,
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
}}

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _TopBar({
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme
        .of(context)
        .colorScheme;

    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: onBack,
          icon: Icon(
            Icons.arrow_back,
            size: 30,
            color: colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Italiana',
            fontSize: 26,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurface,
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
    final colorScheme = Theme
        .of(context)
        .colorScheme;
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF171A19)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2D2C) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.onSurface),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$label: $value',
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}