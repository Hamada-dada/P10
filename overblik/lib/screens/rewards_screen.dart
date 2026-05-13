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
  bool _isLoadingProfiles = true;
  String? _profilesError;

  String _selectedProfileFilter = 'Alle';

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      final profiles = await _profileService.getMyFamilyProfiles();

      if (!mounted) return;

      setState(() {
        _profiles = profiles;
        _isLoadingProfiles = false;
        _profilesError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _profiles = [];
        _isLoadingProfiles = false;
        _profilesError = 'Kunne ikke hente profiler';
      });
    }
  }

  List<String> get _profileFilterOptions {
    return [
      'Alle',
      ..._profiles.map((profile) => profile.name),
    ];
  }

  List<Reward> get _filteredRewards {
    final allRewards = _rewardService.getAllRewards();

    if (_selectedProfileFilter == 'Alle') {
      return allRewards;
    }

    return allRewards
        .where((reward) => reward.assignedProfile == _selectedProfileFilter)
        .toList();
  }

  void _openCreateRewardDialog() {
    if (_profiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingen profiler fundet endnu.'),
        ),
      );
      return;
    }

    final childProfiles = _profiles.where((profile) => profile.isChild).toList();

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

    String selectedProfile = childProfiles.first.name;

    bool isDirectReward = true;
    bool isStreakReward = false;

    showDialog<void>(
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
                      initialValue: selectedProfile,
                      decoration: const InputDecoration(
                        labelText: 'Tilhører profil',
                        border: OutlineInputBorder(),
                      ),
                      items: childProfiles.map((profile) {
                        return DropdownMenuItem<String>(
                          value: profile.name,
                          child: Text('${profile.emoji} ${profile.name}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedProfile = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Direkte belønning'),
                      subtitle: const Text(
                        'Kan bruges direkte efter en aktivitet.',
                      ),
                      value: isDirectReward,
                      onChanged: (value) {
                        setDialogState(() {
                          isDirectReward = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Langsigtet belønning'),
                      subtitle: const Text(
                        'Kan bruges ved gentagelser eller streaks.',
                      ),
                      value: isStreakReward,
                      onChanged: (value) {
                        setDialogState(() {
                          isStreakReward = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    titleController.dispose();
                    emojiController.dispose();
                    descriptionController.dispose();

                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Annuller'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final emoji = emojiController.text.trim();
                    final description = descriptionController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Skriv en titel til belønningen.'),
                        ),
                      );
                      return;
                    }

                    final types = <RewardType>[
                      if (isDirectReward) RewardType.direct,
                      if (isStreakReward) RewardType.streak,
                    ];

                    if (types.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Vælg mindst én type belønning.',
                          ),
                        ),
                      );
                      return;
                    }

                    _rewardService.addReward(
                      Reward(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: title,
                        emoji: emoji.isEmpty ? '🎁' : emoji,
                        description: description,
                        assignedProfile: selectedProfile,
                        types: types,
                      ),
                    );

                    setState(() {});

                    titleController.dispose();
                    emojiController.dispose();
                    descriptionController.dispose();

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Belønning oprettet'),
                      ),
                    );
                  },
                  child: const Text('Gem'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteReward(String id) {
    _rewardService.deleteReward(id);

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Belønning slettet'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingProfiles) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF050706)
            : colorScheme.primaryContainer,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _profilesError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadProfiles,
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
                  child: ListView(
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
                                    ? colorScheme.primary.withValues(alpha: 0.22)
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
        color: isDark ? const Color(0xFF101312) : colorScheme.surface,
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
        color: isDark ? const Color(0xFF101312) : colorScheme.surface,
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