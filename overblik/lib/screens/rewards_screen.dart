import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/reward.dart';
import '../services/profile_service.dart';
import '../services/reward_service.dart';
import '../widgets/reward_card.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final RewardService _rewardService = RewardService();
  final ProfileService _profileService = ProfileService();

  List<Profile> _profiles = [];
  List<Reward> _rewards = [];

  bool _isLoading = true;
  String? _errorMessage;

  String _selectedProfileFilter = 'Alle';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final profiles = await _profileService.getMyFamilyProfiles();
      final rewards = await _rewardService.getAllRewards();

      if (!mounted) return;

      setState(() {
        _profiles = profiles;
        _rewards = rewards;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _profiles = [];
        _rewards = [];
        _isLoading = false;
        _errorMessage = 'Kunne ikke hente belønninger: $e';
      });
    }
  }

  List<Profile> get _childProfiles {
    return _profiles.where((profile) => profile.isChild).toList();
  }

  List<String> get _profileFilterOptions {
    return [
      'Alle',
      ..._childProfiles.map((profile) => profile.name),
    ];
  }

  Profile? _profileById(String profileId) {
    try {
      return _profiles.firstWhere((profile) => profile.id == profileId);
    } catch (_) {
      return null;
    }
  }

  List<Reward> get _filteredRewards {
    if (_selectedProfileFilter == 'Alle') {
      return _rewards;
    }

    return _rewards.where((reward) {
      final profile = _profileById(reward.profileId);
      return profile?.name == _selectedProfileFilter;
    }).toList();
  }

  Future<void> _openCreateRewardDialog() async {
    final childProfiles = _childProfiles;

    if (childProfiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Du skal oprette et barn først, før du kan lave en belønning.',
          ),
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final emojiController = TextEditingController();
    final descriptionController = TextEditingController();
    final targetCountController = TextEditingController(text: '1');

    Profile selectedProfile = childProfiles.first;
    RewardType selectedType = RewardType.direct;
    bool isSaving = false;

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Opret belønning'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titel',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emojiController,
                      decoration: const InputDecoration(
                        labelText: 'Emoji',
                        hintText: 'f.eks. 🍦',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Beskrivelse',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedProfile.id,
                      decoration: const InputDecoration(
                        labelText: 'Tilhører barn',
                        border: OutlineInputBorder(),
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
                    const SizedBox(height: 12),
                    DropdownButtonFormField<RewardType>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Belønningstype',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: RewardType.direct,
                          child: Text('Direkte belønning'),
                        ),
                        DropdownMenuItem(
                          value: RewardType.streak,
                          child: Text('Langsigtet belønning'),
                        ),
                      ],
                      onChanged: isSaving
                          ? null
                          : (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedType = value;

                          if (selectedType == RewardType.direct) {
                            targetCountController.text = '1';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: targetCountController,
                      enabled: selectedType == RewardType.streak && !isSaving,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: selectedType == RewardType.direct
                            ? 'Antal gennemførelser'
                            : 'Udløses efter X gennemførelser',
                        helperText: selectedType == RewardType.direct
                            ? 'Direkte belønninger udløses efter 1 gang.'
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Annuller'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    final title = titleController.text.trim();
                    final emoji = emojiController.text.trim();
                    final description =
                    descriptionController.text.trim();

                    final targetCount =
                        int.tryParse(targetCountController.text.trim()) ??
                            1;

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Skriv en titel til belønningen.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (targetCount < 1) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Antal gennemførelser skal være mindst 1.',
                          ),
                        ),
                      );
                      return;
                    }

                    setDialogState(() {
                      isSaving = true;
                    });

                    try {
                      await _rewardService.addReward(
                        Reward(
                          id: '',
                          familyId: selectedProfile.familyId,
                          profileId: selectedProfile.id,
                          title: title,
                          emoji: emoji.isEmpty ? '🎁' : emoji,
                          description: description,
                          type: selectedType,
                          targetCount:
                          selectedType == RewardType.direct
                              ? 1
                              : targetCount,
                          currentCount: 0,
                          isTriggered: false,
                        ),
                      );

                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext, true);
                    } catch (e) {
                      if (!dialogContext.mounted) return;

                      setDialogState(() {
                        isSaving = false;
                      });

                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Kunne ikke oprette belønning: $e',
                          ),
                        ),
                      );
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Gem'),
                ),
              ],
            );
          },
        );
      },
    );

    // VIGTIGT: Ingen dispose her. Det var årsagen til crash med _dependents.isEmpty.

    if (created == true) {
      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belønning oprettet'),
        ),
      );
    }
  }

  Future<void> _deleteReward(String id) async {
    try {
      await _rewardService.deleteReward(id);
      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belønning slettet'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke slette belønning: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF050706)
            : colorScheme.primaryContainer,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF050706)
            : colorScheme.primaryContainer,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Prøv igen'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final rewards = _filteredRewards;
    final profileFilters = _profileFilterOptions;

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
              _TopBar(
                title: 'Belønninger',
                onBack: () => Navigator.maybePop(context),
                onAdd: _openCreateRewardDialog,
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
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                      children: [
                        const _SectionTitle(title: 'Profilfilter'),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: profileFilters.map((profileName) {
                              final isSelected =
                                  profileName == _selectedProfileFilter;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(profileName),
                                  selected: isSelected,
                                  selectedColor: isDark
                                      ? colorScheme.primary
                                      .withValues(alpha: 0.22)
                                      : colorScheme.primaryContainer,
                                  backgroundColor: isDark
                                      ? const Color(0xFF101312)
                                      : colorScheme.surface,
                                  side: BorderSide(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : isDark
                                        ? const Color(0xFF2A2D2C)
                                        : const Color(0xFFE0E0E0),
                                  ),
                                  labelStyle: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedProfileFilter = profileName;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const _SectionTitle(title: 'Oversigt'),
                        const SizedBox(height: 10),
                        _SummaryCard(
                          totalCount: rewards.length,
                          selectedProfile: _selectedProfileFilter,
                        ),
                        const SizedBox(height: 20),
                        const _SectionTitle(title: 'Belønningsliste'),
                        const SizedBox(height: 10),
                        if (rewards.isEmpty)
                          const _EmptyRewardsState()
                        else
                          ...rewards.map(
                                (reward) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: RewardCard(
                                reward: reward,
                                onDelete: () => _deleteReward(reward.id),
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
  final VoidCallback onAdd;

  const _TopBar({
    required this.title,
    required this.onBack,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: onAdd,
          icon: Icon(
            Icons.add_circle_outline,
            size: 30,
            color: colorScheme.onSurface,
          ),
        ),
      ],
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
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int totalCount;
  final String selectedProfile;

  const _SummaryCard({
    required this.totalCount,
    required this.selectedProfile,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171A19) : colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? colorScheme.primary.withValues(alpha: 0.45)
              : const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.card_giftcard_outlined,
            size: 28,
            color: isDark ? colorScheme.primary : colorScheme.onSurface,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              selectedProfile == 'Alle'
                  ? 'Du har $totalCount belønninger i alt'
                  : 'Du har $totalCount belønninger til $selectedProfile',
              style: TextStyle(
                fontSize: 15,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRewardsState extends StatelessWidget {
  const _EmptyRewardsState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171A19) : colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? colorScheme.primary.withValues(alpha: 0.45)
              : const Color(0xFFE0E0E0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.card_giftcard_outlined,
            size: 34,
            color: isDark
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 10),
          Text(
            'Ingen belønninger endnu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Opret en belønning for at kunne knytte den til en aktivitet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.78),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}