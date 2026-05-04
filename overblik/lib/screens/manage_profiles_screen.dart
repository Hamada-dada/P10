import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      debugPrint(
        'ManageProfilesScreen: loading family code for familyId=$familyId',
      );

      final row = await Supabase.instance.client
          .from('families')
          .select('id, family_name, family_code, created_by')
          .eq('id', familyId)
          .maybeSingle();

      debugPrint('ManageProfilesScreen: family row = $row');

      if (row == null) {
        debugPrint(
          'ManageProfilesScreen: no family row returned. '
          'Likely causes: RLS blocks SELECT on families, or family_id does not exist.',
        );
        return null;
      }

      final familyCode = row['family_code'];

      debugPrint('ManageProfilesScreen: raw family_code = $familyCode');

      if (familyCode is String && familyCode.trim().isNotEmpty) {
        return familyCode.trim();
      }

      debugPrint(
        'ManageProfilesScreen: family_code is missing or empty for familyId=$familyId',
      );

      return null;
    } catch (e, st) {
      debugPrint('ManageProfilesScreen: failed to load family code: $e');
      debugPrintStack(stackTrace: st);
      return null;
    }
  }

  Future<void> _loadProfiles() async {
    try {
      debugPrint('ManageProfilesScreen: loading profiles...');

      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final parentProfile = await _profileService.getMyParentProfile();

      debugPrint(
        'ManageProfilesScreen: parent=${parentProfile?.name}, '
        'role=${parentProfile?.role}, family=${parentProfile?.familyId}',
      );

      if (!mounted) return;

      if (parentProfile == null) {
        setState(() {
          _parentProfile = null;
          _familyCode = null;
          _profiles = [];
          _joinRequests = [];
          _processingRequestId = null;
          _processingProfileId = null;
          _isLoading = false;
          _errorMessage = 'Kunne ikke finde forælderprofilen.';
        });
        return;
      }

      final familyCode = await _loadFamilyCode(parentProfile.familyId);

      final profiles =
          await _profileService.getFamilyProfiles(parentProfile.familyId);

      final joinRequests = await _parentJoinService.getJoinRequestsForFamily(
        parentProfile.familyId,
      );

      debugPrint(
        'ManageProfilesScreen: loaded ${profiles.length} profiles from family ${parentProfile.familyId}',
      );

      debugPrint(
        'ManageProfilesScreen: loaded ${joinRequests.length} parent join requests',
      );

      for (final profile in profiles) {
        debugPrint(
          'ManageProfilesScreen: ${profile.name} | ${profile.role} | active=${profile.isActive}',
        );
      }

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
        _errorMessage = 'Kunne ikke hente profiler: $e';
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
    switch (role) {
      case ProfileRole.parent:
        return 'Forælder';
      case ProfileRole.childLimited:
        return 'Barn · begrænset adgang';
      case ProfileRole.childExtended:
        return 'Barn · udvidet adgang';
    }
  }

  String _roleDescription(ProfileRole role) {
    switch (role) {
      case ProfileRole.parent:
        return 'Kan administrere familie, profiler, aktiviteter og indstillinger.';
      case ProfileRole.childLimited:
        return 'Kan se kalenderen, gennemføre aktiviteter og krydse checklisten af.';
      case ProfileRole.childExtended:
        return 'Kan også oprette, redigere og slette egne aktiviteter.';
    }
  }

  Color _roleColor(ProfileRole role) {
    switch (role) {
      case ProfileRole.parent:
        return const Color(0xFF2E7D32);
      case ProfileRole.childLimited:
        return const Color(0xFF1565C0);
      case ProfileRole.childExtended:
        return const Color(0xFF6A1B9A);
    }
  }

  bool _canRemoveParent(Profile profile) {
    final currentParent = _parentProfile;

    if (currentParent == null) return false;
    if (profile.role != ProfileRole.parent) return false;
    if (!profile.isActive) return false;

    // A parent must not remove their own active profile.
    if (profile.id == currentParent.id) return false;

    return true;
  }

  Future<void> _removeParentFromFamily(Profile profile) async {
    if (!_canRemoveParent(profile)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Denne forælder kan ikke fjernes her.'),
        ),
      );
      return;
    }

    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Fjern forælder?'),
          content: Text(
            'Vil du fjerne ${profile.displayName} som forælder i familien? '
            'Personen mister adgang til familiens kalender.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuller'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Fjern'),
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
          content: Text('${profile.displayName} blev fjernet som forælder.'),
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
          content: Text('Kunne ikke fjerne forælder: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _approveJoinRequest(ParentJoinRequest request) async {
    final shouldApprove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Godkend forælder?'),
          content: Text(
            'Vil du give ${request.requestedDisplayName} adgang som forælder?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuller'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Godkend'),
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
          content: Text(
            '${request.requestedDisplayName} blev godkendt som forælder.',
          ),
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
          content: Text('Kunne ikke godkende anmodning: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _rejectJoinRequest(ParentJoinRequest request) async {
    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Afvis anmodning?'),
          content: Text(
            'Vil du afvise anmodningen fra ${request.requestedDisplayName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuller'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Afvis'),
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
          content: Text(
            'Anmodningen fra ${request.requestedDisplayName} blev afvist.',
          ),
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
          content: Text('Kunne ikke afvise anmodning: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _showCreateChildSheet() async {
    final parentProfile = _parentProfile;

    if (parentProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Forælderprofilen mangler. Prøv at genindlæse.'),
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

    debugPrint(
      'ManageProfilesScreen: created profile ${createdProfile.name} | ${createdProfile.role}',
    );

    setState(() {
      _profiles = [
        ..._profiles.where((profile) => profile.id != createdProfile.id),
        createdProfile,
      ];

      _profiles.sort(_sortProfiles);
    });

    await _loadProfiles();

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Barn oprettet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${createdProfile.displayName} blev oprettet som:'),
              const SizedBox(height: 8),
              Text(
                _roleLabel(createdProfile.role),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Barnets login-kode:'),
              const SizedBox(height: 6),
              SelectableText(
                createdProfile.childLoginCode ?? 'Ingen kode',
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Luk'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetChildCode(Profile profile) async {
    if (!profile.isChild) return;

    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nulstil barnets kode?'),
          content: Text(
            'Vil du oprette en ny login-kode til ${profile.displayName}? '
            'Den gamle kode virker ikke bagefter.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuller'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Nulstil kode'),
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

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Ny login-kode'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ny kode til ${profile.displayName}:'),
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
                onPressed: () => Navigator.pop(context),
                child: const Text('Luk'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke nulstille kode: $e'),
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
          content: Text('Kunne ikke ændre rolle: $e'),
        ),
      );
    }
  }

  Future<void> _showProfileRemovalOptions(Profile profile) async {
    if (profile.role == ProfileRole.parent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Forælderprofilen kan ikke fjernes her.'),
        ),
      );
      return;
    }

    final action = await showDialog<_ProfileRemovalAction>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Fjern profil?'),
          content: Text(
            'Hvad vil du gøre med ${profile.displayName}?\n\n'
            'Deaktivering skjuler profilen, men bevarer data.\n'
            'Permanent sletning fjerner profilen fra systemet.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuller'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context, _ProfileRemovalAction.deactivate);
              },
              icon: const Icon(Icons.visibility_off_outlined),
              label: const Text('Deaktivér'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, _ProfileRemovalAction.delete);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Slet'),
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
          content: Text('${profile.displayName} blev deaktiveret.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _processingProfileId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke deaktivere profil: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _deleteChildProfile(Profile profile) async {
    if (!profile.isChild) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Slet profil permanent?'),
          content: Text(
            'Er du sikker på, at du vil slette ${profile.displayName} permanent?\n\n'
            'Dette kan ikke fortrydes. Hvis profilen bruges i aktiviteter eller deltagerlister, kan databasen blokere sletningen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuller'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Slet permanent'),
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
          content: Text('${profile.displayName} blev slettet.'),
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
          content: Text('Kunne ikke slette profil: $e'),
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
        const _SectionTitle(title: 'Afventende forældreanmodninger'),
        const SizedBox(height: 8),
        _InlineInfoBox(
          icon: Icons.group_add_outlined,
          title: 'Nye forældre',
          text:
              '${pendingRequests.length} anmodning(er) afventer godkendelse. Godkend kun personer, der skal have fuld forælderadgang til familien.',
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
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadProfiles,
                icon: const Icon(Icons.refresh),
                label: const Text('Prøv igen'),
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
              const Icon(
                Icons.group_outlined,
                size: 42,
                color: Colors.black54,
              ),
              const SizedBox(height: 12),
              const Text(
                'Der blev ikke fundet nogen profiler.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadProfiles,
                icon: const Icon(Icons.refresh),
                label: const Text('Genindlæs'),
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
              const Expanded(
                child: _SectionTitle(title: 'Familieprofiler'),
              ),
              TextButton.icon(
                onPressed: _loadProfiles,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Genindlæs'),
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
    return Scaffold(
      backgroundColor: const Color(0xFFA2E5AD),
      floatingActionButton: _parentProfile == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _isLoading ? null : _showCreateChildSheet,
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Tilføj barn'),
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppTopHeader(
                title: 'Profiler',
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
          content: Text('Kunne ikke oprette barn: $e'),
        ),
      );
    }
  }

  String _roleTitle(ProfileRole role) {
    switch (role) {
      case ProfileRole.parent:
        return 'Forælder';
      case ProfileRole.childLimited:
        return 'Begrænset adgang';
      case ProfileRole.childExtended:
        return 'Udvidet adgang';
    }
  }

  String _roleSubtitle(ProfileRole role) {
    switch (role) {
      case ProfileRole.parent:
        return 'Ikke relevant ved oprettelse af barn.';
      case ProfileRole.childLimited:
        return 'Kan se kalenderen, gennemføre aktiviteter og krydse checklisten af.';
      case ProfileRole.childExtended:
        return 'Kan også oprette, redigere og slette egne aktiviteter.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
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
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tilføj barn',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Opret en børneprofil og vælg, hvor meget adgang barnet skal have.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Navn',
                      hintText: 'Fx Adam',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Skriv barnets navn';
                      }

                      if (value.trim().length < 2) {
                        return 'Navnet er for kort';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _displayNameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Visningsnavn',
                      hintText: 'Valgfrit',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emojiController,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Emoji',
                      hintText: '🧒',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Adgangsniveau',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 13),
                            child: Text('Annuller'),
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
                                : const Text('Opret'),
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
    final hasCode = familyCode != null && familyCode!.trim().isNotEmpty;
    final displayCode = hasCode ? familyCode!.trim() : 'Ingen kode fundet';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
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
                const Text(
                  'Familiens kode',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Denne kode bruges sammen med barnets egen login-kode ved børnelogin.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasCode
                          ? const Color(0xFF2E7D32).withValues(alpha: 0.35)
                          : Colors.redAccent.withValues(alpha: 0.35),
                    ),
                  ),
                  child: SelectableText(
                    displayCode,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: hasCode ? 24 : 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: hasCode ? 2 : 0,
                      color: hasCode ? Colors.black : Colors.redAccent,
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

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Ukendt tidspunkt';
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFECB3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
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
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Anmodet: ${_formatDateTime(request.createdAt)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
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
          const Text(
            'Denne person får fuld forælderadgang, hvis anmodningen godkendes.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black87,
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
                  label: const Text('Afvis'),
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
                  label: const Text('Godkend'),
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: profile.isActive
              ? const Color(0xFFE0E0E0)
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
                backgroundColor: Colors.white,
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
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
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
              color: Colors.white,
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
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
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
              label: const Text('Fjern forælder'),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE0E0E0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.key_outlined, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Barnets login-kode',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_isChildCodeVisible)
                    Flexible(
                      child: SelectableText(
                        hasChildLoginCode ? childLoginCode : 'Ingen kode',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: hasChildLoginCode ? 1.4 : 0,
                          color: hasChildLoginCode
                              ? Colors.black
                              : Colors.redAccent,
                        ),
                      ),
                    )
                  else
                    const Text(
                      '••••••',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.4,
                      ),
                    ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isChildCodeVisible = !_isChildCodeVisible;
                      });
                    },
                    icon: Icon(
                      _isChildCodeVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                    ),
                    label: Text(_isChildCodeVisible ? 'Skjul' : 'Vis'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ProfileRole>(
              initialValue: profile.role,
              decoration: const InputDecoration(
                labelText: 'Adgangsniveau',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: ProfileRole.childLimited,
                  child: Text('Begrænset adgang'),
                ),
                DropdownMenuItem(
                  value: ProfileRole.childExtended,
                  child: Text('Udvidet adgang'),
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
                    label: const Text('Ny kode'),
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
                    label: const Text('Deaktivér / slet'),
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

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onChanged == null ? null : () => onChanged!(value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F5E9) : const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF2E7D32) : const Color(0xFFE0E0E0),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? const Color(0xFF2E7D32) : Colors.black54,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
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
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Colors.black,
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.black87),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
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