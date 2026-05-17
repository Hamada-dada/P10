import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../models/profile.dart';
import '../services/parent_join_service.dart';
import '../services/profile_service.dart';
import '../widgets/app_top_header.dart';

enum _ProfileRemovalAction {
  deactivate,
  delete,
}

class ManageProfilesScreen extends StatefulWidget {
  const ManageProfilesScreen({super.key});

  @override
  State<ManageProfilesScreen> createState() => _ManageProfilesScreenState();
}

class _ManageProfilesScreenState extends State<ManageProfilesScreen> {
  final ProfileService _profileService = ProfileService();
  final ParentJoinService _parentJoinService = ParentJoinService();

  Profile? _parentProfile;
  List<Profile> _profiles = [];
  List<ParentJoinRequest> _joinRequests = [];

  String? _familyCode;

  bool _isLoading = true;
  String? _errorMessage;
  String? _processingRequestId;
  String? _processingProfileId;

  List<ParentJoinRequest> get _pendingJoinRequests {
    return _joinRequests
        .where((request) => request.status == 'pending')
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<String?> _loadFamilyCode(String familyId) async {
    try {
      final row = await Supabase.instance.client
          .from('families')
          .select('id, family_name, family_code, created_by')
          .eq('id', familyId)
          .maybeSingle();

      if (row == null) return null;

      final familyCode = row['family_code'];

      if (familyCode is String && familyCode.trim().isNotEmpty) {
        return familyCode.trim();
      }

      return null;
    } catch (e, st) {
      debugPrint('ManageProfilesScreen: failed to load family code: $e');
      debugPrintStack(stackTrace: st);
      return null;
    }
  }

  Future<void> _loadProfiles() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final parentProfile = await _profileService.getMyParentProfile();

      if (!mounted) return;

      if (parentProfile == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).parentOnlyManage),
            ),
          );
        }
        return;
      }

      final familyCode = await _loadFamilyCode(parentProfile.familyId);

      final profiles =
      await _profileService.getFamilyProfiles(parentProfile.familyId);

      final joinRequests = await _parentJoinService.getJoinRequestsForFamily(
        parentProfile.familyId,
      );

      profiles.sort(_sortProfiles);

      if (!mounted) return;

      setState(() {
        _parentProfile = parentProfile;
        _familyCode = familyCode;
        _profiles = profiles;
        _joinRequests = joinRequests;
        _processingRequestId = null;
        _processingProfileId = null;
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('ManageProfilesScreen: failed to load profiles: $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;

      setState(() {
        _processingRequestId = null;
        _processingProfileId = null;
        _isLoading = false;
        _errorMessage = AppLocalizations.of(context).errorLoadProfilesManage(e);
      });
    }
  }

  int _sortProfiles(Profile a, Profile b) {
    if (a.role == ProfileRole.parent && b.role != ProfileRole.parent) {
      return -1;
    }

    if (a.role != ProfileRole.parent && b.role == ProfileRole.parent) {
      return 1;
    }

    return a.displayName.toLowerCase().compareTo(
      b.displayName.toLowerCase(),
    );
  }

  String _roleLabel(ProfileRole role) {
    final l = AppLocalizations.of(context);
    switch (role) {
      case ProfileRole.parent:
        return l.roleParentLabel;
      case ProfileRole.childLimited:
        return l.roleChildLimitedLabel;
      case ProfileRole.childExtended:
        return l.roleChildExtendedLabel;
    }
  }

  String _roleDescription(ProfileRole role) {
    final l = AppLocalizations.of(context);
    switch (role) {
      case ProfileRole.parent:
        return l.roleDescriptionParent;
      case ProfileRole.childLimited:
        return l.roleDescriptionChildLimited;
      case ProfileRole.childExtended:
        return l.roleDescriptionChildExtended;
    }
  }

  Color _roleColor(ProfileRole role) {
    switch (role) {
      case ProfileRole.parent:
        return const Color(0xFF2E7D32);
      case ProfileRole.childLimited:
        return const Color(0xFF1565C0);
      case ProfileRole.childExtended:
        return const Color(0xFFB57EDC);
    }
  }

  bool _canRemoveParent(Profile profile) {
    final currentParent = _parentProfile;

    if (currentParent == null) return false;
    if (profile.role != ProfileRole.parent) return false;
    if (!profile.isActive) return false;
    if (profile.id == currentParent.id) return false;

    return true;
  }

  Future<void> _removeParentFromFamily(Profile profile) async {
    if (!_canRemoveParent(profile)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).cannotRemoveParentHere),
        ),
      );
      return;
    }

    final l = AppLocalizations.of(context);
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l.removeParentDialogTitle),
          content: Text(l.removeParentDialogContent(profile.displayName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.remove),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldRemove != true) return;

    try {
      setState(() {
        _processingProfileId = profile.id;
      });

      await _parentJoinService.removeParentFromFamily(profile.id);
      await _loadProfiles();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).parentRemoved(profile.displayName)),
        ),
      );
    } catch (e, st) {
      debugPrint('ManageProfilesScreen: remove parent failed: $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;

      setState(() {
        _processingProfileId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).errorRemoveParent(e)),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _approveJoinRequest(ParentJoinRequest request) async {
    final l = AppLocalizations.of(context);
    final shouldApprove = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l.approveParentDialogTitle),
          content: Text(l.approveParentDialogContent(request.requestedDisplayName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.approve),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldApprove != true) return;

    try {
      setState(() {
        _processingRequestId = request.requestId;
      });

      await _parentJoinService.approveJoinRequest(request.requestId);
      await _loadProfiles();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).parentApproved(request.requestedDisplayName)),
        ),
      );
    } catch (e, st) {
      debugPrint('ManageProfilesScreen: approve request failed: $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;

      setState(() {
        _processingRequestId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).errorApproveRequest(e)),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _rejectJoinRequest(ParentJoinRequest request) async {
    final l = AppLocalizations.of(context);
    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l.rejectRequestDialogTitle),
          content: Text(l.rejectRequestDialogContent(request.requestedDisplayName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.reject),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldReject != true) return;

    try {
      setState(() {
        _processingRequestId = request.requestId;
      });

      await _parentJoinService.rejectJoinRequest(request.requestId);
      await _loadProfiles();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).requestRejected(request.requestedDisplayName)),
        ),
      );
    } catch (e, st) {
      debugPrint('ManageProfilesScreen: reject request failed: $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;

      setState(() {
        _processingRequestId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).errorRejectRequest(e)),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _showCreateChildSheet() async {
    final parentProfile = _parentProfile;

    if (parentProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).parentProfileMissing),
        ),
      );
      return;
    }

    final createdProfile = await showModalBottomSheet<Profile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CreateChildProfileSheet(
          familyId: parentProfile.familyId,
          profileService: _profileService,
        );
      },
    );

    if (!mounted || createdProfile == null) return;

    setState(() {
      _profiles = [
        ..._profiles.where((profile) => profile.id != createdProfile.id),
        createdProfile,
      ];

      _profiles.sort(_sortProfiles);
    });

    await _loadProfiles();

    if (!mounted) return;

    final l = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l.childCreatedDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.childCreatedDialogContent(createdProfile.displayName)),
              const SizedBox(height: 8),
              Text(
                _roleLabel(createdProfile.role),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(l.childLoginCodeLabel),
              const SizedBox(height: 6),
              SelectableText(
                createdProfile.childLoginCode ?? l.noCodeFound,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.close),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetChildCode(Profile profile) async {
    if (!profile.isChild) return;

    final l = AppLocalizations.of(context);
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l.resetChildCodeDialogTitle),
          content: Text(l.resetChildCodeDialogContent(profile.displayName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.resetCodeButton),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldReset != true) return;

    try {
      final newCode = await _profileService.resetChildCode(profile.id);

      await _loadProfiles();

      if (!mounted) return;

      final lAfter = AppLocalizations.of(context);
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(lAfter.newLoginCodeDialogTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(lAfter.newLoginCodeContent(profile.displayName)),
                const SizedBox(height: 10),
                SelectableText(
                  newCode,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(lAfter.close),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).errorDeactivateProfile(e)),
        ),
      );
    }
  }

  Future<void> _changeChildRole(Profile profile, ProfileRole newRole) async {
    if (!profile.isChild) return;

    try {
      await _profileService.updateProfile(
        profileId: profile.id,
        role: newRole,
      );

      await _loadProfiles();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${profile.displayName} er nu ændret til ${_roleLabel(newRole).toLowerCase()}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).errorRejectRequest(e)),
        ),
      );
    }
  }

  Future<void> _showProfileRemovalOptions(Profile profile) async {
    if (profile.role == ProfileRole.parent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).parentCannotBeRemovedHere),
        ),
      );
      return;
    }

    final l = AppLocalizations.of(context);
    final action = await showDialog<_ProfileRemovalAction>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l.removeProfileDialogTitle),
          content: Text(l.removeProfileDialogContent(profile.displayName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancel),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx, _ProfileRemovalAction.deactivate);
              },
              icon: const Icon(Icons.visibility_off_outlined),
              label: Text(l.deactivateButton),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx, _ProfileRemovalAction.delete);
              },
              icon: const Icon(Icons.delete_outline),
              label: Text(l.delete),
            ),
          ],
        );
      },
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _ProfileRemovalAction.deactivate:
        await _deactivateChildProfile(profile);
        break;
      case _ProfileRemovalAction.delete:
        await _deleteChildProfile(profile);
        break;
    }
  }

  Future<void> _deactivateChildProfile(Profile profile) async {
    try {
      setState(() {
        _processingProfileId = profile.id;
      });

      await _profileService.updateProfile(
        profileId: profile.id,
        isActive: false,
      );

      await _loadProfiles();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).profileDeactivated(profile.displayName)),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _processingProfileId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).errorDeactivateProfile(e)),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _deleteChildProfile(Profile profile) async {
    if (!profile.isChild) return;

    final l = AppLocalizations.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l.deletePermanentlyDialogTitle),
          content: Text(l.deletePermanentlyDialogContent(profile.displayName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.delete_outline),
              label: Text(l.deletePermanentlyButton),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldDelete != true) return;

    try {
      setState(() {
        _processingProfileId = profile.id;
      });

      await Supabase.instance.client.rpc(
        'delete_child_profile',
        params: {
          'input_profile_id': profile.id,
        },
      );

      await _loadProfiles();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).profileDeleted(profile.displayName)),
        ),
      );
    } catch (e, st) {
      debugPrint('ManageProfilesScreen: delete profile failed: $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;

      setState(() {
        _processingProfileId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).errorDeleteProfile(e)),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Widget _buildJoinRequestsSection() {
    final pendingRequests = _pendingJoinRequests;

    if (pendingRequests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        _SectionTitle(title: AppLocalizations.of(context).pendingRequestsSectionTitle),
        const SizedBox(height: 8),
        _InlineInfoBox(
          icon: Icons.group_add_outlined,
          title: AppLocalizations.of(context).newParentsInfoTitle,
          text: AppLocalizations.of(context).pendingRequestsInfo(pendingRequests.length),
        ),
        const SizedBox(height: 12),
        ...pendingRequests.map(
              (request) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ParentJoinRequestCard(
                request: request,
                isProcessing: _processingRequestId == request.requestId,
                onApprove: () => _approveJoinRequest(request),
                onReject: () => _rejectJoinRequest(request),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 42,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadProfiles,
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context).retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_profiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.group_outlined,
                size: 42,
                color: colorScheme.onSurface.withValues(alpha: 0.55),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).noProfilesFound,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurface),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadProfiles,
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context).reload),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProfiles,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
        children: [
          _FamilyCodeCard(
            familyCode: _familyCode,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SectionTitle(title: AppLocalizations.of(context).familyProfilesHeader),
              ),
              TextButton.icon(
                onPressed: _loadProfiles,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(AppLocalizations.of(context).reload),
              ),
            ],
          ),
          _buildJoinRequestsSection(),
          const SizedBox(height: 16),
          ..._profiles.map(
                (profile) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ProfileCard(
                  profile: profile,
                  roleLabel: _roleLabel(profile.role),
                  roleDescription: _roleDescription(profile.role),
                  roleColor: _roleColor(profile.role),
                  isProcessing: _processingProfileId == profile.id,
                  onResetCode:
                  profile.isChild ? () => _resetChildCode(profile) : null,
                  onDeactivate: profile.isChild
                      ? () => _showProfileRemovalOptions(profile)
                      : null,
                  onRemoveParent: _canRemoveParent(profile)
                      ? () => _removeParentFromFamily(profile)
                      : null,
                  onChangeRole: profile.isChild
                      ? (newRole) => _changeChildRole(profile, newRole)
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF050706)
          : colorScheme.primaryContainer,
      floatingActionButton: _parentProfile == null
          ? null
          : FloatingActionButton.extended(
        onPressed: _isLoading ? null : _showCreateChildSheet,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(AppLocalizations.of(context).addChildButton),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTopHeader(
                title: AppLocalizations.of(context).manageProfilesTitle,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF101312)
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2A2D2C)
                          : Colors.transparent,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateChildProfileSheet extends StatefulWidget {
  final String familyId;
  final ProfileService profileService;

  const _CreateChildProfileSheet({
    required this.familyId,
    required this.profileService,
  });

  @override
  State<_CreateChildProfileSheet> createState() =>
      _CreateChildProfileSheetState();
}

class _CreateChildProfileSheetState extends State<_CreateChildProfileSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emojiController =
  TextEditingController(text: '🧒');

  ProfileRole _selectedRole = ProfileRole.childLimited;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  Future<void> _createChild() async {
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final profile = await widget.profileService.createChildProfile(
        familyId: widget.familyId,
        name: _nameController.text.trim(),
        displayName: _displayNameController.text.trim().isEmpty
            ? null
            : _displayNameController.text.trim(),
        emoji: _emojiController.text.trim().isEmpty
            ? '🧒'
            : _emojiController.text.trim(),
        role: _selectedRole,
      );

      if (!mounted) return;

      Navigator.pop(context, profile);
    } catch (e, st) {
      debugPrint('CreateChildProfileSheet: failed to create child: $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).errorCreateChild(e)),
        ),
      );
    }
  }

  String _roleTitle(ProfileRole role) {
    final l = AppLocalizations.of(context);
    switch (role) {
      case ProfileRole.parent:
        return l.roleParentLabel;
      case ProfileRole.childLimited:
        return l.limitedAccessOption;
      case ProfileRole.childExtended:
        return l.extendedAccessOption;
    }
  }

  String _roleSubtitle(ProfileRole role) {
    final l = AppLocalizations.of(context);
    switch (role) {
      case ProfileRole.parent:
        return l.roleDescriptionParent;
      case ProfileRole.childLimited:
        return l.roleDescriptionChildLimited;
      case ProfileRole.childExtended:
        return l.roleDescriptionChildExtended;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF101312) : colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2D2C) : Colors.transparent,
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A2D2C)
                            : const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).addChildSheetTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context).addChildSheetSubtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Builder(
                    builder: (ctx) {
                      final l = AppLocalizations.of(ctx);
                      return TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l.name,
                          hintText: l.nameHint,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return l.nameRequired;
                          if (value.trim().length < 2) return l.nameTooShort;
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _displayNameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).displayNameLabel,
                      hintText: AppLocalizations.of(context).displayNameHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emojiController,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).emoji,
                      hintText: '🧒',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    AppLocalizations.of(context).accessLevelLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _RoleOptionTile(
                    title: _roleTitle(ProfileRole.childLimited),
                    subtitle: _roleSubtitle(ProfileRole.childLimited),
                    value: ProfileRole.childLimited,
                    groupValue: _selectedRole,
                    onChanged: _isSaving
                        ? null
                        : (value) {
                      setState(() {
                        _selectedRole = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  _RoleOptionTile(
                    title: _roleTitle(ProfileRole.childExtended),
                    subtitle: _roleSubtitle(ProfileRole.childExtended),
                    value: ProfileRole.childExtended,
                    groupValue: _selectedRole,
                    onChanged: _isSaving
                        ? null
                        : (value) {
                      setState(() {
                        _selectedRole = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            child: Text(AppLocalizations.of(context).cancel),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _createChild,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            child: _isSaving
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : Text(AppLocalizations.of(context).create),
                          ),
                        ),
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

class _FamilyCodeCard extends StatelessWidget {
  final String? familyCode;

  const _FamilyCodeCard({
    required this.familyCode,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hasCode = familyCode != null && familyCode!.trim().isNotEmpty;
    final displayCode = hasCode ? familyCode!.trim() : l.noCodeFound;

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171A19) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.home_outlined,
            size: 26,
            color: Color(0xFF2E7D32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.familyCodeDisplayLabel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.familyCodeDescriptionText,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.85),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF101312) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasCode
                          ? const Color(0xFF2E7D32).withValues(alpha: 0.35)
                          : Colors.redAccent.withValues(alpha: 0.35),
                    ),
                  ),
                  child: GestureDetector(
                    onTap: hasCode
                        ? () async {
                            await Clipboard.setData(ClipboardData(text: displayCode));
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context).codeCopied),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayCode,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: hasCode ? 24 : 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: hasCode ? 2 : 0,
                            color: hasCode ? colorScheme.onSurface : Colors.redAccent,
                          ),
                        ),
                        if (hasCode) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.copy_outlined, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                        ],
                      ],
                    ),
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

class _ParentJoinRequestCard extends StatelessWidget {
  final ParentJoinRequest request;
  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ParentJoinRequestCard({
    required this.request,
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
  });

  String _formatDateTime(DateTime? dateTime, BuildContext context) {
    if (dateTime == null) {
      return AppLocalizations.of(context).unknownTime;
    }

    final localDateTime = dateTime.toLocal();

    final day = localDateTime.day.toString().padLeft(2, '0');
    final month = localDateTime.month.toString().padLeft(2, '0');
    final year = localDateTime.year.toString();
    final hour = localDateTime.hour.toString().padLeft(2, '0');
    final minute = localDateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171A19) : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2D2C) : const Color(0xFFFFECB3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isDark ? const Color(0xFF101312) : Colors.white,
                child: Text(
                  request.requestedEmoji,
                  style: const TextStyle(fontSize: 23),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.requestedDisplayName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context).requestedAtLabel(_formatDateTime(request.createdAt, context)),
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (isProcessing)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).parentAccessInfo,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.85),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isProcessing ? null : onReject,
                  icon: const Icon(Icons.close),
                  label: Text(AppLocalizations.of(context).reject),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isProcessing ? null : onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check),
                  label: Text(AppLocalizations.of(context).approve),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatefulWidget {
  final Profile profile;
  final String roleLabel;
  final String roleDescription;
  final Color roleColor;
  final bool isProcessing;
  final VoidCallback? onResetCode;
  final VoidCallback? onDeactivate;
  final VoidCallback? onRemoveParent;
  final ValueChanged<ProfileRole>? onChangeRole;

  const _ProfileCard({
    required this.profile,
    required this.roleLabel,
    required this.roleDescription,
    required this.roleColor,
    required this.isProcessing,
    this.onResetCode,
    this.onDeactivate,
    this.onRemoveParent,
    this.onChangeRole,
  });

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  bool _isChildCodeVisible = false;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final isChild = profile.isChild;
    final childLoginCode = profile.childLoginCode?.trim();
    final hasChildLoginCode =
        childLoginCode != null && childLoginCode.isNotEmpty;

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark
        ? const Color(0xFF171A19)
        : colorScheme.surfaceContainerHighest;

    final innerCardColor = isDark ? const Color(0xFF101312) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: profile.isActive
              ? (isDark ? const Color(0xFF2A2D2C) : const Color(0xFFE0E0E0))
              : Colors.redAccent.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: innerCardColor,
                child: Text(
                  profile.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (!profile.isActive)
                const Icon(
                  Icons.visibility_off_outlined,
                  color: Colors.redAccent,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: innerCardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.roleColor.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  profile.role == ProfileRole.parent
                      ? Icons.admin_panel_settings_outlined
                      : Icons.child_care_outlined,
                  color: widget.roleColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.roleLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: widget.roleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.roleDescription,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withValues(alpha: 0.85),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (profile.role == ProfileRole.parent &&
              widget.onRemoveParent != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: widget.isProcessing ? null : widget.onRemoveParent,
              icon: widget.isProcessing
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.person_remove_outlined),
              label: Text(AppLocalizations.of(context).removeParentLabel),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
          if (isChild) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: innerCardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF2A2D2C) : const Color(0xFFE0E0E0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.key_outlined,
                    size: 20,
                    color: colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).childLoginCodeTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_isChildCodeVisible)
                    Flexible(
                      child: GestureDetector(
                        onTap: hasChildLoginCode
                            ? () async {
                                await Clipboard.setData(ClipboardData(text: childLoginCode));
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppLocalizations.of(context).codeCopied),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            : null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              hasChildLoginCode ? childLoginCode : AppLocalizations.of(context).noCodeFound,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: hasChildLoginCode ? 1.4 : 0,
                                color: hasChildLoginCode
                                    ? colorScheme.onSurface
                                    : Colors.redAccent,
                              ),
                            ),
                            if (hasChildLoginCode) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.copy_outlined, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                            ],
                          ],
                        ),
                      ),
                    )
                  else
                    Text(
                      '••••••',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.4,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isChildCodeVisible = !_isChildCodeVisible;
                      });
                    },
                    tooltip: _isChildCodeVisible
                        ? AppLocalizations.of(context).hideCode
                        : AppLocalizations.of(context).showCode,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _isChildCodeVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ProfileRole>(
              initialValue: profile.role,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).accessLevelLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: ProfileRole.childLimited,
                  child: Text(AppLocalizations.of(context).limitedAccessOption),
                ),
                DropdownMenuItem(
                  value: ProfileRole.childExtended,
                  child: Text(AppLocalizations.of(context).extendedAccessOption),
                ),
              ],
              onChanged: widget.onChangeRole == null
                  ? null
                  : (value) {
                if (value == null || value == profile.role) return;
                widget.onChangeRole!(value);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                    widget.isProcessing ? null : widget.onResetCode,
                    icon: const Icon(Icons.refresh),
                    label: Text(AppLocalizations.of(context).newCodeButton),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                    widget.isProcessing ? null : widget.onDeactivate,
                    icon: widget.isProcessing
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.manage_accounts_outlined),
                    label: Text(AppLocalizations.of(context).deactivateDeleteButton),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final ProfileRole value;
  final ProfileRole groupValue;
  final ValueChanged<ProfileRole>? onChanged;

  const _RoleOptionTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onChanged == null ? null : () => onChanged!(value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2E7D32).withValues(alpha: isDark ? 0.22 : 0.12)
              : (isDark
              ? const Color(0xFF171A19)
              : colorScheme.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF2E7D32)
                : (isDark ? const Color(0xFF2A2D2C) : const Color(0xFFE0E0E0)),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected
                  ? const Color(0xFF2E7D32)
                  : colorScheme.onSurface.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.85),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _InlineInfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _InlineInfoBox({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF171A19)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2D2C) : Colors.transparent,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: colorScheme.onSurface),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.85),
                    height: 1.4,
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