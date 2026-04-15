import '../models/activity.dart';

class ActivityService {
  const ActivityService();

  List<Activity> getActivitiesForDate(DateTime date) {
    if (date.weekday == DateTime.sunday) {
      return [];
    }

    final activities = [
      Activity(
        id: '1',
        title: 'Morgenmad',
        emoji: '🍳',
        startTime: DateTime(date.year, date.month, date.day, 7, 0),
        endTime: DateTime(date.year, date.month, date.day, 7, 15),
        description: 'Spis morgenmad ved bordet.',
        participants: const ['Mig'],
      ),
      Activity(
        id: '2',
        title: 'Skole',
        emoji: '🏫',
        startTime: DateTime(date.year, date.month, date.day, 8, 0),
        endTime: DateTime(date.year, date.month, date.day, 15, 30),
        description: 'Skole fra morgen til eftermiddag.',
        participants: const ['Mig'],
      ),
      Activity(
        id: '3',
        title: 'Aftale med Peter',
        emoji: '🎮',
        startTime: DateTime(date.year, date.month, date.day, 16, 0),
        endTime: DateTime(date.year, date.month, date.day, 17, 30),
        isImportant: true,
        description:
            'Peter kommer forbi. I skal spille sammen og rydde lidt op først.',
        participants: const ['Mig', 'Peter'],
      ),
      Activity(
        id: '4',
        title: 'Takeout',
        emoji: '😋',
        startTime: DateTime(date.year, date.month, date.day, 18, 0),
        endTime: DateTime(date.year, date.month, date.day, 18, 45),
        description: 'Vælg mellem pizza eller sandwich.',
        participants: const ['Mig', 'Mor', 'Far'],
      ),
      Activity(
        id: '5',
        title: 'Lektier',
        emoji: '📘',
        startTime: DateTime(date.year, date.month, date.day, 20, 0),
        endTime: DateTime(date.year, date.month, date.day, 21, 0),
        description: 'Dansk og matematik lektier.',
        participants: const ['Mig'],
      ),
    ];

    activities.sort((a, b) => a.startTime.compareTo(b.startTime));
    return activities;
  }
}