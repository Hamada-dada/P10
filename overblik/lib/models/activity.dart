enum ActivityRecurrence {
  none,
  daily,
  weekly,
  monthly,
  custom,
}

ActivityRecurrence activityRecurrenceFromString(String value) {
  switch (value) {
    case 'daily':
      return ActivityRecurrence.daily;
    case 'weekly':
      return ActivityRecurrence.weekly;
    case 'monthly':
      return ActivityRecurrence.monthly;
    case 'custom':
      return ActivityRecurrence.custom;
    case 'none':
    default:
      return ActivityRecurrence.none;
  }
}

String activityRecurrenceToDatabase(ActivityRecurrence recurrence) {
  switch (recurrence) {
    case ActivityRecurrence.daily:
      return 'daily';
    case ActivityRecurrence.weekly:
      return 'weekly';
    case ActivityRecurrence.monthly:
      return 'monthly';
    case ActivityRecurrence.custom:
      return 'custom';
    case ActivityRecurrence.none:
      return 'none';
  }
}

class ActivityParticipant {
  final String? profileId;
  final String? externalName;

  const ActivityParticipant({
    this.profileId,
    this.externalName,
  }) : assert(
          (profileId != null && externalName == null) ||
              (profileId == null && externalName != null),
          'Participant must have either profileId or externalName',
        );

  bool get isProfileParticipant => profileId != null;
  bool get isExternalParticipant => externalName != null;

  String get displayValue => externalName ?? profileId ?? '';

  Map<String, dynamic> toDatabaseRow(String activityId) {
    return {
      'activity_id': activityId,
      'profile_id': profileId,
      'external_name': externalName,
    };
  }

  factory ActivityParticipant.fromDatabaseRow(Map<String, dynamic> row) {
    return ActivityParticipant(
      profileId: row['profile_id'] as String?,
      externalName: row['external_name'] as String?,
    );
  }
}

class ActivityChecklistItem {
  final String? id;
  final String title;
  final bool isChecked;
  final int position;

  const ActivityChecklistItem({
    this.id,
    required this.title,
    required this.isChecked,
    required this.position,
  });

  Map<String, dynamic> toDatabaseRow(String activityId) {
    return {
      'id': id,
      'activity_id': activityId,
      'title': title,
      'is_checked': isChecked,
      'position': position,
    };
  }

  factory ActivityChecklistItem.fromDatabaseRow(Map<String, dynamic> row) {
    return ActivityChecklistItem(
      id: row['id'] as String?,
      title: row['title'] as String? ?? '',
      isChecked: row['is_checked'] as bool? ?? false,
      position: row['position'] as int? ?? 0,
    );
  }
}

class Activity {
  final String id;
  final String familyId;

  final String title;
  final String emoji;
  final String description;

  final DateTime startTime;
  final DateTime endTime;

  final String? createdBy;
  final String? ownerProfileId;

  final bool isCompleted;
  final bool isImportant;
  final bool isFavorite;

  final String imagePath;

  final String? directRewardId;
  final String? streakRewardId;
  final int? streakTarget;

  final ActivityRecurrence recurrence;
  final int recurrenceInterval;
  final DateTime? recurrenceEndDate;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final List<ActivityParticipant> participants;
  final List<ActivityChecklistItem> checklistItems;

  const Activity({
    required this.id,
    required this.familyId,
    required this.title,
    required this.emoji,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.createdBy,
    required this.ownerProfileId,
    required this.isCompleted,
    required this.isImportant,
    required this.isFavorite,
    required this.imagePath,
    required this.directRewardId,
    required this.streakRewardId,
    required this.streakTarget,
    required this.recurrence,
    required this.recurrenceInterval,
    required this.recurrenceEndDate,
    required this.createdAt,
    required this.updatedAt,
    required this.participants,
    required this.checklistItems,
  });

  Duration get duration => endTime.difference(startTime);

  List<String> get participantLabels {
    return participants
        .map((p) => p.externalName ?? p.profileId ?? '')
        .where((value) => value.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> toActivityRow() {
    return {
      'id': id,
      'family_id': familyId,
      'title': title,
      'emoji': emoji.isEmpty ? null : emoji,
      'description': description.isEmpty ? null : description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'created_by': createdBy,
      'owner_profile_id': ownerProfileId,
      'is_completed': isCompleted,
      'is_important': isImportant,
      'is_favorite': isFavorite,
      'image_path': imagePath.isEmpty ? null : imagePath,
      'direct_reward_id': directRewardId,
      'streak_reward_id': streakRewardId,
      'streak_target': streakTarget,
      'recurrence': activityRecurrenceToDatabase(recurrence),
      'recurrence_interval': recurrenceInterval,
      //'recurrence_end_date': recurrenceEndDate?.toIso8601String(),
    };
  }

  factory Activity.fromDatabase({
    required Map<String, dynamic> activityRow,
    required List<ActivityParticipant> participants,
    required List<ActivityChecklistItem> checklistItems,
  }) {
    return Activity(
      id: activityRow['id'] as String,
      familyId: activityRow['family_id'] as String,
      title: activityRow['title'] as String? ?? '',
      emoji: activityRow['emoji'] as String? ?? '',
      description: activityRow['description'] as String? ?? '',
      startTime: DateTime.parse(activityRow['start_time'] as String),
      endTime: DateTime.parse(activityRow['end_time'] as String),
      createdBy: activityRow['created_by'] as String?,
      ownerProfileId: activityRow['owner_profile_id'] as String?,
      isCompleted: activityRow['is_completed'] as bool? ?? false,
      isImportant: activityRow['is_important'] as bool? ?? false,
      isFavorite: activityRow['is_favorite'] as bool? ?? false,
      imagePath: activityRow['image_path'] as String? ?? '',
      directRewardId: activityRow['direct_reward_id'] as String?,
      streakRewardId: activityRow['streak_reward_id'] as String?,
      streakTarget: activityRow['streak_target'] as int?,
      recurrence: activityRecurrenceFromString(
        activityRow['recurrence'] as String? ?? 'none',
      ),
      recurrenceInterval: activityRow['recurrence_interval'] as int? ?? 1,
      recurrenceEndDate: activityRow['recurrence_end_date'] != null
          ? DateTime.tryParse(activityRow['recurrence_end_date'] as String)
          : null,
      createdAt: activityRow['created_at'] != null
          ? DateTime.tryParse(activityRow['created_at'] as String)
          : null,
      updatedAt: activityRow['updated_at'] != null
          ? DateTime.tryParse(activityRow['updated_at'] as String)
          : null,
      participants: participants,
      checklistItems: checklistItems,
    );
  }

  Activity copyWith({
    String? id,
    String? familyId,
    String? title,
    String? emoji,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? createdBy,
    String? ownerProfileId,
    bool? isCompleted,
    bool? isImportant,
    bool? isFavorite,
    String? imagePath,
    String? directRewardId,
    String? streakRewardId,
    int? streakTarget,
    ActivityRecurrence? recurrence,
    int? recurrenceInterval,
    DateTime? recurrenceEndDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ActivityParticipant>? participants,
    List<ActivityChecklistItem>? checklistItems,
  }) {
    return Activity(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdBy: createdBy ?? this.createdBy,
      ownerProfileId: ownerProfileId ?? this.ownerProfileId,
      isCompleted: isCompleted ?? this.isCompleted,
      isImportant: isImportant ?? this.isImportant,
      isFavorite: isFavorite ?? this.isFavorite,
      imagePath: imagePath ?? this.imagePath,
      directRewardId: directRewardId ?? this.directRewardId,
      streakRewardId: streakRewardId ?? this.streakRewardId,
      streakTarget: streakTarget ?? this.streakTarget,
      recurrence: recurrence ?? this.recurrence,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      participants: participants ?? this.participants,
      checklistItems: checklistItems ?? this.checklistItems,
    );
  }
}