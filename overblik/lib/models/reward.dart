enum RewardType {
  direct,
  streak,
}

class Reward {
  final String id;
  final String familyId;
  final String profileId;
  final String title;
  final String emoji;
  final String description;
  final RewardType type;
  final int targetCount;
  final int currentCount;
  final bool isTriggered;

  const Reward({
    required this.id,
    required this.familyId,
    required this.profileId,
    required this.title,
    required this.emoji,
    required this.description,
    required this.type,
    required this.targetCount,
    required this.currentCount,
    required this.isTriggered,
  });

  bool get isDirectReward => type == RewardType.direct;
  bool get isStreakReward => type == RewardType.streak;

  factory Reward.fromMap(Map<String, dynamic> map) {
    final rewardType = map['reward_type'] as String? ?? 'direct';

    return Reward(
      id: map['id'] as String,
      familyId: map['family_id'] as String,
      profileId: map['profile_id'] as String,
      title: map['title'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '🎁',
      description: map['description'] as String? ?? '',
      type: rewardType == 'streak' ? RewardType.streak : RewardType.direct,
      targetCount: map['target_count'] as int? ?? 1,
      currentCount: map['current_count'] as int? ?? 0,
      isTriggered: map['is_triggered'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'family_id': familyId,
      'profile_id': profileId,
      'title': title,
      'emoji': emoji,
      'description': description,
      'reward_type': type == RewardType.streak ? 'streak' : 'direct',
      'target_count': targetCount,
      'current_count': currentCount,
      'is_triggered': isTriggered,
    };
  }
}