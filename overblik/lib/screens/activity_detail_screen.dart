import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/activity.dart';
import '../models/profile.dart';
import '../repositories/supabase_activity_repository.dart';
import '../services/activity_service.dart';
import '../services/profile_service.dart';
import '../services/reward_service.dart';
import 'create_activity_screen.dart';

class ActivityDetailScreen extends StatefulWidget {
  final Activity activity;

  // Legacy fake child-session fields.
  // Keep temporarily until the old child RPC flow is fully removed.
  final String? childFamilyId;
  final String? childProfileId;
  final String? childDisplayName;
  final String? childRole;
  final String? childLoginCode;

  const ActivityDetailScreen({
    super.key,
    required this.activity,
    this.childFamilyId,
    this.childProfileId,
    this.childDisplayName,
    this.childRole,
    this.childLoginCode,
  });

  bool get isChildSession {
    return childFamilyId != null &&
        childProfileId != null &&
        childRole != null &&
        childLoginCode != null;
  }

  bool get isChildLimited {
    return childRole == 'child_limited';
  }

  bool get isChildExtended {
    return childRole == 'child_extended';
  }

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late Activity _activity;

  final RewardService _rewardService = RewardService();
  final ProfileService _profileService = ProfileService();

  late final ActivityService _activityService = ActivityService(
    SupabaseActivityRepository(
      Supabase.instance.client,
      childFamilyId: widget.childFamilyId,
      childProfileId: widget.childProfileId,
      childRole: widget.childRole,
      childLoginCode: widget.childLoginCode,
    ),
  );

  bool _isLoading = true;

  Profile? _currentProfile;
  Map<String, String> _profileNamesById = {};

  bool get _isChildSession => widget.isChildSession;

  bool get _hasAuthUser {
    return Supabase.instance.client.auth.currentUser != null;
  }

  bool get _isAuthenticatedParent {
    return _currentProfile?.isParent == true;
  }

  bool get _isAuthenticatedChild {
    return _currentProfile?.isChild == true;
  }

  bool get _isAuthenticatedChildExtended {
    return _currentProfile?.isChildExtended == true;
  }

  bool get _isOwnActivity {
    final currentProfile = _currentProfile;

    if (currentProfile == null) return false;

    return _activity.ownerProfileId == currentProfile.id;
  }

  bool get _canEditActivity {
    if (_isAuthenticatedParent) {
      return true;
    }

    if (_isAuthenticatedChildExtended && _isOwnActivity) {
      return true;
    }

    // Legacy fake child-session path does not have safe authenticated mutation.
    return false;
  }

  bool get _canDeleteActivity {
    if (_isAuthenticatedParent) {
      return true;
    }

    if (_isAuthenticatedChildExtended && _isOwnActivity) {
      return true;
    }

    // Legacy fake child-session path does not have safe authenticated mutation.
    return false;
  }

  bool get _canToggleChecklist {
    if (_isAuthenticatedParent) {
      return true;
    }

    if (_isAuthenticatedChild) {
      return true;
    }

    if (_isChildSession) {
      return true;
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _activity = widget.activity;

    debugPrint('ActivityDetailScreen: init');
    debugPrint('ActivityDetailScreen: hasAuthUser=$_hasAuthUser');
    debugPrint('ActivityDetailScreen: isChildSession=$_isChildSession');
    debugPrint('ActivityDetailScreen: childFamilyId=${widget.childFamilyId}');
    debugPrint('ActivityDetailScreen: childProfileId=${widget.childProfileId}');
    debugPrint('ActivityDetailScreen: childRole=${widget.childRole}');
    debugPrint('ActivityDetailScreen: childLoginCode=${widget.childLoginCode}');

    _loadActivity();
  }

  Future<Profile?> _loadCurrentProfileForSession() async {
    if (!_hasAuthUser) {
      return null;
    }

    try {
      final profile = await _profileService.getCurrentAuthenticatedProfile();

      debugPrint(
        'ActivityDetailScreen: current profile id=${profile?.id} role=${profile?.role}',
      );

      return profile;
    } catch (e, st) {
      debugPrint('ActivityDetailScreen: failed to load current profile: $e');
      debugPrintStack(stackTrace: st);
      return null;
    }
  }

  Future<Map<String, String>> _loadProfileNamesForSession({
    Profile? currentProfile,
  }) async {
    if (_isChildSession) {
      return _loadProfileNamesForLegacyChild();
    }

    final profile = currentProfile ??
        _currentProfile ??
        await _profileService.getCurrentAuthenticatedProfile();

    if (profile == null) {
      debugPrint(
        'ActivityDetailScreen: no current profile for profile-name loading',
      );
      return {};
    }

    final familyProfiles = profile.isParent
        ? await _profileService.getFamilyProfiles(profile.familyId)
        : await _profileService.getFamilyProfilesForCurrentUser();

    return {
      for (final familyProfile in familyProfiles)
        familyProfile.id: familyProfile.displayName.trim().isNotEmpty
            ? familyProfile.displayName
            : familyProfile.name,
    };
  }

  Future<Map<String, String>> _loadProfileNamesForLegacyChild() async {
    final childProfileId = widget.childProfileId;
    final childLoginCode = widget.childLoginCode;

    if (childProfileId == null || childLoginCode == null) {
      return {};
    }

    final result = await Supabase.instance.client.rpc(
      'child_get_family_profiles_v2',
      params: {
        'input_profile_id': childProfileId,
        'input_child_code': childLoginCode,
      },
    );

    final rows = List<Map<String, dynamic>>.from(result as List);

    final namesById = <String, String>{};

    for (final row in rows) {
      final id = row['id'] as String?;
      final name = row['name'] as String? ?? '';
      final displayName = row['display_name'] as String? ?? '';

      if (id == null || id.trim().isEmpty) {
        continue;
      }

      final preferredName = displayName.trim().isNotEmpty
          ? displayName.trim()
          : name.trim();

      namesById[id] = preferredName.isNotEmpty ? preferredName : 'Ukendt';
    }

    return namesById;
  }

  Future<void> _loadActivity() async {
    try {
      final currentProfile = await _loadCurrentProfileForSession();

      final freshActivity =
          await _activityService.getActivityById(widget.activity.id);

      final activityToShow = freshActivity ?? widget.activity;

      final profileNamesById = await _loadProfileNamesForSession(
        currentProfile: currentProfile,
      );

      if (!mounted) return;

      setState(() {
        _currentProfile = currentProfile;
        _activity = activityToShow;
        _profileNamesById = profileNamesById;
        _isLoading = false;
      });

      debugPrint(
        'ActivityDetailScreen: loaded activity id=${activityToShow.id} '
        'ownerProfileId=${activityToShow.ownerProfileId} '
        'currentProfileId=${currentProfile?.id} '
        'canEdit=$_canEditActivity canDelete=$_canDeleteActivity canChecklist=$_canToggleChecklist',
      );
    } catch (e, st) {
      debugPrint('ActivityDetailScreen _loadActivity failed: $e');
      debugPrintStack(stackTrace: st);

      try {
        final currentProfile = await _loadCurrentProfileForSession();

        final profileNamesById = await _loadProfileNamesForSession(
          currentProfile: currentProfile,
        );

        if (!mounted) return;

        setState(() {
          _currentProfile = currentProfile;
          _activity = widget.activity;
          _profileNamesById = profileNamesById;
          _isLoading = false;
        });
      } catch (profileError, profileSt) {
        debugPrint(
          'ActivityDetailScreen profile fallback failed: $profileError',
        );
        debugPrintStack(stackTrace: profileSt);

        if (!mounted) return;

        setState(() {
          _currentProfile = null;
          _activity = widget.activity;
          _profileNamesById = {};
          _isLoading = false;
        });
      }
    }
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

  String _participantDisplayText(ActivityParticipant participant) {
    if (participant.externalName != null &&
        participant.externalName!.trim().isNotEmpty) {
      return participant.externalName!;
    }

    if (participant.profileId != null) {
      final profileName = _profileNamesById[participant.profileId!];

      if (profileName != null && profileName.trim().isNotEmpty) {
        return profileName;
      }
    }

    return 'Ukendt deltager';
  }

  String _buildParticipantsText() {
    if (_activity.visibility == ActivityVisibility.family) {
      if (_activity.participants.isEmpty) {
        return 'Familieaktivitet (ingen specifikke deltagere)';
      }

      return 'Hele familien';
    }

    if (_activity.participants.isEmpty) {
      return 'Ingen specifikke deltagere';
    }

    return _activity.participants.map(_participantDisplayText).join(', ');
  }

  String _buildDescriptionText() {
    if (_activity.description.trim().isEmpty) {
      return 'Ingen beskrivelse';
    }

    return _activity.description;
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
    if (!_canToggleChecklist) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Du har ikke adgang til at ændre tjeklisten.'),
        ),
      );
      return;
    }

    final previousActivity = _activity;

    try {
      final updatedChecklist = List<ActivityChecklistItem>.from(
        _activity.checklistItems,
      );

      final currentItem = updatedChecklist[index];
      final checklistItemId = currentItem.id;

      if (checklistItemId == null || checklistItemId.trim().isEmpty) {
        throw ArgumentError(
          'Cannot update checklist item because the checklist item id is missing.',
        );
      }

      final newCheckedValue = !currentItem.isChecked;

      updatedChecklist[index] = ActivityChecklistItem(
        id: checklistItemId,
        title: currentItem.title,
        isChecked: newCheckedValue,
        position: currentItem.position,
      );

      final updatedActivity = _activity.copyWith(
        checklistItems: updatedChecklist,
      );

      setState(() {
        _activity = updatedActivity;
      });

      await _activityService.setChecklistItemChecked(
        checklistItemId: checklistItemId,
        isChecked: newCheckedValue,
      );
    } catch (e, st) {
      debugPrint('ActivityDetailScreen _toggleChecklistItem failed: $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;

      setState(() {
        _activity = previousActivity;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kunne ikke opdatere tjeklisten.'),
        ),
      );
    }
  }

  Future<void> _editActivity() async {
    if (!_canEditActivity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Du har ikke adgang til at redigere denne aktivitet.'),
        ),
      );
      return;
    }

    try {
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
        await _activityService.updateActivity(updatedActivity);

        if (!mounted) return;

        setState(() {
          _activity = updatedActivity;
        });

        Navigator.pop(context, true);
      }
    } catch (e, st) {
      debugPrint('ActivityDetailScreen _editActivity failed: $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kunne ikke gemme ændringerne.'),
        ),
      );
    }
  }

  Future<void> _deleteActivity() async {
    if (!_canDeleteActivity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Du har ikke adgang til at slette denne aktivitet.'),
        ),
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Slet aktivitet'),
          content: Text('Vil du slette "${_activity.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuller'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Slet'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await _activityService.deleteActivity(_activity.id);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e, st) {
      debugPrint('ActivityDetailScreen _deleteActivity failed: $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kunne ikke slette aktiviteten.'),
        ),
      );
    }
  }

  void _openImagePreview(BuildContext context) {
    if (_activity.imagePath.trim().isEmpty) return;

    final isRemoteUrl = _activity.imagePath.startsWith('http');

    if (kIsWeb && !isRemoteUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Billedvisning understøttes ikke i webversionen endnu.',
          ),
        ),
      );
      return;
    }

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
                    child: isRemoteUrl
                        ? Image.network(
                            _activity.imagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Text(
                              'Kunne ikke vise billedet',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : Image.file(
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

  Widget _buildDetailImagePreview() {
    if (_activity.imagePath.trim().isEmpty) return const SizedBox.shrink();

    final isRemoteUrl = _activity.imagePath.startsWith('http');

    if (isRemoteUrl) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _activity.imagePath,
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 90,
              alignment: Alignment.center,
              color: const Color(0xFFF1F1F1),
              child: const Text('Kunne ikke vise billedet'),
            );
          },
        ),
      );
    }

    if (kIsWeb) {
      return Container(
        height: 120,
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Billede gemt, men forhåndsvisning understøttes ikke i webversionen endnu.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
      );
    }

    return ClipRRect(
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
            child: const Text('Kunne ikke vise billedet'),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFA2E5AD),
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final hasImage = _activity.imagePath.trim().isNotEmpty;
    final hasReward =
        _activity.directRewardId != null || _activity.streakRewardId != null;
    final hasChecklist = _activity.checklistItems.isNotEmpty;
    final hasRecurrence = _activity.recurrence != ActivityRecurrence.none;
    final showBottomActions = _canEditActivity || _canDeleteActivity;

    final directReward = _activity.directRewardId != null
        ? _rewardService.getRewardById(_activity.directRewardId!)
        : null;

    final streakReward = _activity.streakRewardId != null
        ? _rewardService.getRewardById(_activity.streakRewardId!)
        : null;

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
                      padding: EdgeInsets.fromLTRB(
                        16,
                        4,
                        16,
                        showBottomActions ? 16 : 24,
                      ),
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
                          const SizedBox(height: 20),
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
                                child: _buildDetailImagePreview(),
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
                                  (index) {
                                    final checklistItem =
                                        _activity.checklistItems[index];

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () =>
                                            _toggleChecklistItem(index),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 2,
                                              ),
                                              child: Icon(
                                                checklistItem.isChecked
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
                                                checklistItem.title,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w400,
                                                  color: const Color(
                                                    0xFF1D1B20,
                                                  ),
                                                  height: 1.5,
                                                  letterSpacing: 0.5,
                                                  decoration:
                                                      checklistItem.isChecked
                                                          ? TextDecoration
                                                              .lineThrough
                                                          : TextDecoration.none,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                          if (hasReward) ...[
                            const SizedBox(height: 20),
                            _InfoSection(
                              icon: Icons.card_giftcard_outlined,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (directReward != null ||
                                      _activity.directRewardId != null)
                                    _RewardCard(
                                      title: 'Direkte belønning',
                                      emoji: directReward?.emoji ?? '🎁',
                                      rewardTitle: directReward?.title ??
                                          'Ukendt belønning',
                                      subtitle:
                                          'Kan opnås efter denne aktivitet',
                                      icon: Icons.flash_on_outlined,
                                    ),
                                  if ((directReward != null ||
                                          _activity.directRewardId != null) &&
                                      (streakReward != null ||
                                          _activity.streakRewardId != null))
                                    const SizedBox(height: 10),
                                  if (streakReward != null ||
                                      _activity.streakRewardId != null)
                                    _RewardCard(
                                      title: 'Langsigtet belønning',
                                      emoji: streakReward?.emoji ?? '🏆',
                                      rewardTitle: streakReward?.title ??
                                          'Ukendt belønning',
                                      subtitle: _activity.streakTarget != null
                                          ? 'Opnås efter ${_activity.streakTarget} gange'
                                          : 'Langsigtet belønning',
                                      icon: Icons.trending_up_outlined,
                                    ),
                                ],
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
                        ],
                      ),
                    ),
                  ),
                  if (showBottomActions)
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_canDeleteActivity)
                            _BottomActionButton(
                              icon: Icons.delete_outline,
                              label: 'Slet',
                              onTap: _deleteActivity,
                            )
                          else
                            const SizedBox(width: 80),
                          if (_canEditActivity)
                            _BottomActionButton(
                              icon: Icons.edit_outlined,
                              label: 'Rediger',
                              onTap: _editActivity,
                            )
                          else
                            const SizedBox(width: 80),
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

class _RewardCard extends StatelessWidget {
  final String title;
  final String emoji;
  final String rewardTitle;
  final String subtitle;
  final IconData icon;

  const _RewardCard({
    required this.title,
    required this.emoji,
    required this.rewardTitle,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFF8F8F8),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: Colors.black87,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  rewardTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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