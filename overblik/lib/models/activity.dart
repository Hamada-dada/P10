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

ActivityOwner activityOwnerFromString(String value) {
  return ActivityOwner.values.firstWhere(
    (e) => e.name == value,
    orElse: () => ActivityOwner.me,
  );
}

ActivityRecurrence activityRecurrenceFromString(String value) {
  return ActivityRecurrence.values.firstWhere(
    (e) => e.name == value,
    orElse: () => ActivityRecurrence.none,
  );
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
  final List<bool> checklistChecked;
  final String? directRewardId;
  final String? streakRewardId;
  final int? streakTarget;
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
    this.checklistChecked = const [],
    this.directRewardId,
    this.streakRewardId,
    this.streakTarget,
    this.imagePath = '',
    this.recurrence = ActivityRecurrence.none,
    this.recurrenceInterval = 1,
  });

  Duration get duration => endTime.difference(startTime);

  List<bool> get normalizedChecklistChecked {
    return List<bool>.generate(
      checklistItems.length,
      (index) => index < checklistChecked.length ? checklistChecked[index] : false,
    );
  }

  Map<String, dynamic> toActivityRow() {
    return {
      'id': id,
      'title': title,
      'emoji': emoji,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'owner': owner.name,
      'is_completed': isCompleted,
      'is_important': isImportant,
      'is_favorite': isFavorite,
      'description': description,
      'direct_reward_id': directRewardId,
      'streak_reward_id': streakRewardId,
      'streak_target': streakTarget,
      'image_path': imagePath,
      'recurrence': recurrence.name,
      'recurrence_interval': recurrenceInterval,
    };
  }

  factory Activity.fromDatabase({
    required Map<String, dynamic> activityRow,
    required List<String> participants,
    required List<String> checklistItems,
    required List<bool> checklistChecked,
  }) {
    return Activity(
      id: activityRow['id'] as String,
      title: activityRow['title'] as String? ?? '',
      emoji: activityRow['emoji'] as String? ?? '',
      startTime: DateTime.parse(activityRow['start_time'] as String),
      endTime: DateTime.parse(activityRow['end_time'] as String),
      owner: activityOwnerFromString(activityRow['owner'] as String? ?? 'me'),
      isCompleted: activityRow['is_completed'] as bool? ?? false,
      isImportant: activityRow['is_important'] as bool? ?? false,
      isFavorite: activityRow['is_favorite'] as bool? ?? false,
      description: activityRow['description'] as String? ?? '',
      participants: participants,
      checklistItems: checklistItems,
      checklistChecked: checklistChecked,
      directRewardId: activityRow['direct_reward_id'] as String?,
      streakRewardId: activityRow['streak_reward_id'] as String?,
      streakTarget: activityRow['streak_target'] as int?,
      imagePath: activityRow['image_path'] as String? ?? '',
      recurrence: activityRecurrenceFromString(
        activityRow['recurrence'] as String? ?? 'none',
      ),
      recurrenceInterval: activityRow['recurrence_interval'] as int? ?? 1,
    );
  }

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
    List<bool>? checklistChecked,
    String? directRewardId,
    String? streakRewardId,
    int? streakTarget,
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
      checklistChecked: checklistChecked ?? this.checklistChecked,
      directRewardId: directRewardId ?? this.directRewardId,
      streakRewardId: streakRewardId ?? this.streakRewardId,
      streakTarget: streakTarget ?? this.streakTarget,
      imagePath: imagePath ?? this.imagePath,
      recurrence: recurrence ?? this.recurrence,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
    );
  }
}