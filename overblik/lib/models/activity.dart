enum ActivityOwner {
  me,
  mother,
  father,
  family,
}

enum ActivityRecurrence {
  none,
  daily,
  weekly,
  monthly,
  custom,
}

class Activity {
  final String id;
  final String title;
  final String emoji;
  final DateTime startTime;
  final DateTime endTime;
  final bool isCompleted;
  final bool isImportant;
  final bool isFavorite;
  final String description;
  final List<String> participants;
  final List<String> checklistItems;
  final String reward;
  final bool isRewardRecurring;
  final String imagePath;
  final ActivityOwner owner;
  final ActivityRecurrence recurrence;
  final int recurrenceInterval;

  const Activity({
    required this.id,
    required this.title,
    required this.emoji,
    required this.startTime,
    required this.endTime,
    required this.owner,
    this.isCompleted = false,
    this.isImportant = false,
    this.isFavorite = false,
    this.description = '',
    this.participants = const [],
    this.checklistItems = const [],
    this.reward = '',
    this.isRewardRecurring = false,
    this.imagePath = '',
    this.recurrence = ActivityRecurrence.none,
    this.recurrenceInterval = 1,
  });

  Duration get duration => endTime.difference(startTime);

  Activity copyWith({
    String? id,
    String? title,
    String? emoji,
    DateTime? startTime,
    DateTime? endTime,
    bool? isCompleted,
    bool? isImportant,
    bool? isFavorite,
    String? description,
    List<String>? participants,
    List<String>? checklistItems,
    String? reward,
    bool? isRewardRecurring,
    String? imagePath,
    ActivityOwner? owner,
    ActivityRecurrence? recurrence,
    int? recurrenceInterval,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      owner: owner ?? this.owner,
      isCompleted: isCompleted ?? this.isCompleted,
      isImportant: isImportant ?? this.isImportant,
      isFavorite: isFavorite ?? this.isFavorite,
      description: description ?? this.description,
      participants: participants ?? this.participants,
      checklistItems: checklistItems ?? this.checklistItems,
      reward: reward ?? this.reward,
      isRewardRecurring: isRewardRecurring ?? this.isRewardRecurring,
      imagePath: imagePath ?? this.imagePath,
      recurrence: recurrence ?? this.recurrence,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
    );
  }
}