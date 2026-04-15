enum ActivityOwner {
  me,
  mother,
  father,
  family,
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
  final ActivityOwner owner;

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
  });

  Duration get duration => endTime.difference(startTime);
}