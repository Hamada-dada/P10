class Activity {
  final String id;
  final String title;
  final String emoji;
  final DateTime startTime;
  final DateTime endTime;
  final bool isCompleted;
  final bool isImportant;
  final String description;
  final List<String> participants;

  const Activity({
    required this.id,
    required this.title,
    required this.emoji,
    required this.startTime,
    required this.endTime,
    this.isCompleted = false,
    this.isImportant = false,
    this.description = '',
    this.participants = const [],
  });
}