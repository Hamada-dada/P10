import '../models/reward.dart';

class RewardService {
  RewardService._internal();

  static final RewardService _instance = RewardService._internal();

  factory RewardService() => _instance;

  final List<Reward> _rewards = [
    const Reward(
      id: 'reward-1',
      title: '30 min iPad',
      emoji: '📱',
      description: 'Kan bruges efter en gennemført aktivitet.',
      assignedProfile: 'Jørn',
      types: [RewardType.direct],
    ),
    const Reward(
      id: 'reward-2',
      title: 'Lego tid',
      emoji: '🧱',
      description: 'Langsigtet belønning efter flere gennemførelser.',
      assignedProfile: 'Jørn',
      types: [RewardType.streak],
    ),
    const Reward(
      id: 'reward-3',
      title: 'Is efter aftensmad',
      emoji: '🍦',
      description: 'En lille belønning efter en svær opgave.',
      assignedProfile: 'Emma',
      types: [RewardType.direct],
    ),
  ];

  List<Reward> getAllRewards() {
    final copy = List<Reward>.from(_rewards);
    copy.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return copy;
  }

  Reward? getRewardById(String id) {
    try {
      return _rewards.firstWhere((reward) => reward.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Reward> getRewardsForProfile(String profileName) {
    final rewards = _rewards
        .where((reward) => reward.assignedProfile == profileName)
        .toList();

    rewards.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return rewards;
  }

  List<Reward> getRewardsForProfileAndType(
    String profileName,
    RewardType type,
  ) {
    final rewards = _rewards
        .where(
          (reward) =>
              reward.assignedProfile == profileName &&
              reward.types.contains(type),
        )
        .toList();

    rewards.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return rewards;
  }

  void addReward(Reward reward) {
    _rewards.add(reward);
  }

  void updateReward(Reward updatedReward) {
    final index = _rewards.indexWhere((reward) => reward.id == updatedReward.id);

    if (index == -1) {
      return;
    }

    _rewards[index] = updatedReward;
  }

  void deleteReward(String rewardId) {
    _rewards.removeWhere((reward) => reward.id == rewardId);
  }

  List<String> getAssignedProfiles() {
    final profiles = _rewards.map((reward) => reward.assignedProfile).toSet().toList();
    profiles.sort();
    return profiles;
  }
}