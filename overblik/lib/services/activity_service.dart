import '../models/activity.dart';

class ActivityService {
  List<Activity> getActivitiesForDate(DateTime date) {
    if (date.weekday == DateTime.sunday) {
      return [];
    }

    return [
      Activity(
        id: '1',
        title: 'Morgenmad',
        emoji: '🍳',
        startTime: DateTime(date.year, date.month, date.day, 7, 0),
        endTime: DateTime(date.year, date.month, date.day, 7, 15),
        owner: ActivityOwner.me,
        description: 'Spis morgenmad i køkkenet.',
        participants: const ['Mig'],
      ),
      Activity(
        id: '2',
        title: 'Skole',
        emoji: '🏫',
        startTime: DateTime(date.year, date.month, date.day, 8, 0),
        endTime: DateTime(date.year, date.month, date.day, 15, 30),
        owner: ActivityOwner.me,
        description: 'Skoledag med almindeligt skema.',
        participants: const ['Mig'],
      ),
      Activity(
        id: '3',
        title: 'Aftale med Peter',
        emoji: '🎮',
        startTime: DateTime(date.year, date.month, date.day, 16, 0),
        endTime: DateTime(date.year, date.month, date.day, 17, 30),
        owner: ActivityOwner.me,
        isImportant: true,
        description: 'Peter kommer forbi, og I skal spille sammen.',
        participants: const ['Mig', 'Peter'],
      ),
      Activity(
        id: '4',
        title: 'Takeout',
        emoji: '😋',
        startTime: DateTime(date.year, date.month, date.day, 18, 0),
        endTime: DateTime(date.year, date.month, date.day, 18, 45),
        owner: ActivityOwner.family,
        description: 'Vælg mellem pizza eller sandwich.',
        participants: const ['Mig', 'Mor', 'Far'],
      ),
      Activity(
        id: '5',
        title: 'Lektier',
        emoji: '📘',
        startTime: DateTime(date.year, date.month, date.day, 20, 0),
        endTime: DateTime(date.year, date.month, date.day, 21, 0),
        owner: ActivityOwner.me,
        description: 'Dansk lektier og matematik lektier.',
        participants: const ['Mig'],
      ),
    ];
  }

  List<Activity> getActivitiesForWeek(DateTime focusedDate) {
    final startOfWeek = _startOfWeek(focusedDate);
    final List<Activity> allActivities = [];

    for (int i = 0; i < 7; i++) {
      final currentDate = startOfWeek.add(Duration(days: i));
      allActivities.addAll(getActivitiesForDate(currentDate));
    }

    return allActivities;
  }

  Activity? getLongestActivityForDate(DateTime date) {
    final activities = getActivitiesForDate(date);

    if (activities.isEmpty) {
      return null;
    }

    Activity longestActivity = activities.first;

    for (final activity in activities) {
      if (activity.duration > longestActivity.duration) {
        longestActivity = activity;
      }
    }

    return longestActivity;
  }

  List<Activity?> getLongestActivitiesForWeek(DateTime focusedDate) {
    final startOfWeek = _startOfWeek(focusedDate);
    final List<Activity?> longestActivities = [];

    for (int i = 0; i < 7; i++) {
      final currentDate = startOfWeek.add(Duration(days: i));
      longestActivities.add(getLongestActivityForDate(currentDate));
    }

    return longestActivities;
  }

  List<DateTime> getWeekDates(DateTime focusedDate) {
    final startOfWeek = _startOfWeek(focusedDate);

    return List.generate(
      7,
      (index) => startOfWeek.add(Duration(days: index)),
    );
  }

  DateTime startOfWeek(DateTime date) {
    return _startOfWeek(date);
  }

  DateTime _startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }
}