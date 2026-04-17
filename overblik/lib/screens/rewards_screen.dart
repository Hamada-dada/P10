import 'package:flutter/material.dart';

import '../models/reward.dart';
import '../services/reward_service.dart';
import '../widgets/reward_card.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final RewardService _rewardService = RewardService();

  final List<String> _profiles = const [
    'Alle',
    'Jørn',
    'Emma',
    'Noah',
  ];

  String _selectedProfileFilter = 'Alle';

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
    final titleController = TextEditingController();
    final emojiController = TextEditingController();
    final descriptionController = TextEditingController();

    String selectedProfile = _profiles.length > 1 ? _profiles[1] : 'Jørn';
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
                      items: _profiles
                          .where((profile) => profile != 'Alle')
                          .map(
                            (profile) => DropdownMenuItem(
                              value: profile,
                              child: Text(profile),
                            ),
                          )
                          .toList(),
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
    final rewards = _filteredRewards;

    return Scaffold(
      backgroundColor: const Color(0xFFA2E5AD),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
                          children: _profiles.map((profile) {
                            final isSelected =
                                profile == _selectedProfileFilter;

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(profile),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedProfileFilter = profile;
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
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: onAdd,
          icon: const Icon(
            Icons.add_circle_outline,
            size: 30,
            color: Colors.black,
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
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Colors.black,
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.card_giftcard_outlined,
            size: 28,
            color: Colors.black87,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              selectedProfile == 'Alle'
                  ? 'Du har $totalCount belønninger i alt'
                  : 'Du har $totalCount belønninger til $selectedProfile',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black,
                fontWeight: FontWeight.w500,
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.card_giftcard_outlined,
            size: 34,
            color: Colors.black54,
          ),
          SizedBox(height: 10),
          Text(
            'Ingen belønninger endnu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Opret en belønning for at kunne knytte den til en aktivitet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}