import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../services/profile_service.dart';
import '../widgets/app_top_header.dart';

class ManageProfilesScreen extends StatefulWidget {
  const ManageProfilesScreen({super.key});

  @override
  State<ManageProfilesScreen> createState() => _ManageProfilesScreenState();
}

class _ManageProfilesScreenState extends State<ManageProfilesScreen> {
  final ProfileService _profileService = ProfileService();

  Profile? _parentProfile;
  List<Profile> _profiles = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
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
          _profiles = [];
          _isLoading = false;
          _errorMessage = 'Kunne ikke finde forælderprofilen.';
        });
        return;
      }

      final profiles =
          await _profileService.getFamilyProfiles(parentProfile.familyId);

      debugPrint(
        'ManageProfilesScreen: loaded ${profiles.length} profiles from family ${parentProfile.familyId}',
      );

      for (final profile in profiles) {
        debugPrint(
          'ManageProfilesScreen: ${profile.name} | ${profile.role} | active=${profile.isActive}',
        );
      }

      profiles.sort((a, b) {
        if (a.role == ProfileRole.parent && b.role != ProfileRole.parent) {
          return -1;
        }

        if (a.role != ProfileRole.parent && b.role == ProfileRole.parent) {
          return 1;
        }

        return a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            );
      });

      if (!mounted) return;

      setState(() {
        _parentProfile = parentProfile;
        _profiles = profiles;
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('ManageProfilesScreen: failed to load profiles: $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Kunne ikke hente profiler: $e';
      });
    }
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

    if (createdProfile == null) return;

    debugPrint(
      'ManageProfilesScreen: created profile ${createdProfile.name} | ${createdProfile.role}',
    );

    if (!mounted) return;

    setState(() {
      _profiles = [
        ..._profiles.where((profile) => profile.id != createdProfile.id),
        createdProfile,
      ];

      _profiles.sort((a, b) {
        if (a.role == ProfileRole.parent && b.role != ProfileRole.parent) {
          return -1;
        }

        if (a.role != ProfileRole.parent && b.role == ProfileRole.parent) {
          return 1;
        }

        return a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            );
      });
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

    if (shouldReset != true) return;

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

  Future<void> _deactivateProfile(Profile profile) async {
    if (profile.role == ProfileRole.parent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Forælderprofilen kan ikke deaktiveres her.'),
        ),
      );
      return;
    }

    final shouldDeactivate = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Deaktivér profil?'),
          content: Text(
            'Vil du deaktivere ${profile.displayName}? Profilen slettes ikke, '
            'men den skjules/deaktiveres i systemet.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuller'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Deaktivér'),
            ),
          ],
        );
      },
    );

    if (shouldDeactivate != true) return;

    try {
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke deaktivere profil: $e'),
        ),
      );
    }
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
          const SizedBox(height: 8),
          _InlineInfoBox(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Adgangsstyring',
            text:
                'Der er ${_profiles.length} profiler i familien. Forældre har fuld adgang. Børn kan enten have begrænset eller udvidet adgang.',
          ),
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
                  onResetCode:
                      profile.isChild ? () => _resetChildCode(profile) : null,
                  onDeactivate:
                      profile.isChild ? () => _deactivateProfile(profile) : null,
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
      floatingActionButton: FloatingActionButton.extended(
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
                            if (value == null) return;
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
                            if (value == null) return;
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

class _ProfileCard extends StatelessWidget {
  final Profile profile;
  final String roleLabel;
  final String roleDescription;
  final Color roleColor;
  final VoidCallback? onResetCode;
  final VoidCallback? onDeactivate;
  final ValueChanged<ProfileRole>? onChangeRole;

  const _ProfileCard({
    required this.profile,
    required this.roleLabel,
    required this.roleDescription,
    required this.roleColor,
    this.onResetCode,
    this.onDeactivate,
    this.onChangeRole,
  });

  @override
  Widget build(BuildContext context) {
    final isChild = profile.isChild;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: profile.isActive
              ? const Color(0xFFE0E0E0)
              : Colors.redAccent.withOpacity(0.35),
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
                color: roleColor.withOpacity(0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  profile.role == ProfileRole.parent
                      ? Icons.admin_panel_settings_outlined
                      : Icons.child_care_outlined,
                  color: roleColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roleLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: roleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        roleDescription,
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
          if (isChild) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.key_outlined, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Login-kode:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                SelectableText(
                  profile.childLoginCode ?? 'Ingen kode',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ProfileRole>(
              value: profile.role,
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
              onChanged: onChangeRole == null
                  ? null
                  : (value) {
                      if (value == null || value == profile.role) return;
                      onChangeRole!(value);
                    },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onResetCode,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Ny kode'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDeactivate,
                    icon: const Icon(Icons.visibility_off_outlined),
                    label: const Text('Deaktivér'),
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
  final ValueChanged<ProfileRole?>? onChanged;

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
            Radio<ProfileRole>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: const Color(0xFF2E7D32),
            ),
            const SizedBox(width: 4),
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