enum RewardType {
  direct,
  streak,
}

class Reward {
  final String id;
  final String title;
  final String emoji;
  final String description;
  final String assignedProfile;
  final List<RewardType> types;

  const Reward({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.assignedProfile,
    this.types = const [],
  });

  bool get isDirectReward => types.contains(RewardType.direct);
  bool get isStreakReward => types.contains(RewardType.streak);

  Reward copyWith({
    String? id,
    String? title,
    String? emoji,
    String? description,
    String? assignedProfile,
    List<RewardType>? types,
  }) {
    return Reward(
      id: id ?? this.id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      description: description ?? this.description,
      assignedProfile: assignedProfile ?? this.assignedProfile,
      types: types ?? this.types,
    );
  }
}