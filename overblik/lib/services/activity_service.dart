import '../models/activity.dart';

class ActivityService {
  ActivityService._internal();

  static final ActivityService _instance = ActivityService._internal();

  factory ActivityService() => _instance;

  final List<Activity> _activities = [];
  final Set<String> _seededDates = {};

  List<Activity> getActivitiesForDate(DateTime date) {
    _ensureSeededForDate(date);

    final normalizedDate = _dateOnly(date);

    final activitiesForDate = _activities.where((activity) {
      final activityDate = _dateOnly(activity.startTime);
      return activityDate == normalizedDate;
    }).toList();

    activitiesForDate.sort((a, b) => a.startTime.compareTo(b.startTime));
    return activitiesForDate;
  }

  List<Activity> getActivitiesForWeek(DateTime focusedDate) {
    final startOfWeek = _startOfWeek(focusedDate);
    final List<Activity> allActivities = [];

    for (int i = 0; i < 7; i++) {
      final currentDate = startOfWeek.add(Duration(days: i));
      allActivities.addAll(getActivitiesForDate(currentDate));
    }

    allActivities.sort((a, b) => a.startTime.compareTo(b.startTime));
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

  Activity? getActivityById(String id) {
    try {
      return _activities.firstWhere((activity) => activity.id == id);
    } catch (_) {
      return null;
    }
  }

  void addActivity(Activity activity) {
    _ensureSeededForDate(activity.startTime);
    _activities.add(activity);
  }

  void updateActivity(Activity updatedActivity) {
    final index =
        _activities.indexWhere((activity) => activity.id == updatedActivity.id);

    if (index == -1) {
      return;
    }

    _activities[index] = updatedActivity;
  }

  void deleteActivity(String activityId) {
    _activities.removeWhere((activity) => activity.id == activityId);
  }

  List<Activity> getAllActivities() {
    final copy = List<Activity>.from(_activities);
    copy.sort((a, b) => a.startTime.compareTo(b.startTime));
    return copy;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  String _dateKey(DateTime date) {
    final normalized = _dateOnly(date);
    return '${normalized.year}-${normalized.month}-${normalized.day}';
  }

  void _ensureSeededForDate(DateTime date) {
    final key = _dateKey(date);

    if (_seededDates.contains(key)) {
      return;
    }

    _seededDates.add(key);

    if (date.weekday == DateTime.sunday) {
      return;
    }

    _activities.addAll(_buildSeedActivitiesForDate(date));
  }

  List<Activity> _buildSeedActivitiesForDate(DateTime date) {
    final day = date.day;

    final hasPeter = date.weekday == DateTime.wednesday || day % 5 == 0;
    final hasTakeout = date.weekday == DateTime.friday || day % 3 == 0;
    final hasHomework = date.weekday != DateTime.saturday;
    final hasSport = date.weekday == DateTime.thursday;
    final hasDogWalk = date.weekday == DateTime.saturday;

    final List<Activity> seedActivities = [
      Activity(
        id: 'seed-${_dateKey(date)}-morgenmad',
        title: 'Morgenmad',
        emoji: '🍳',
        startTime: DateTime(date.year, date.month, date.day, 7, 0),
        endTime: DateTime(date.year, date.month, date.day, 7, 15),
        owner: ActivityOwner.me,
        description: 'Spis morgenmad i køkkenet.',
        participants: const ['Mig'],
      ),
      Activity(
        id: 'seed-${_dateKey(date)}-skole',
        title: 'Skole',
        emoji: '🏫',
        startTime: DateTime(date.year, date.month, date.day, 8, 0),
        endTime: DateTime(date.year, date.month, date.day, 15, 30),
        owner: ActivityOwner.me,
        description: 'Skoledag med almindeligt skema.',
        participants: const ['Mig'],
      ),
    ];

    if (hasPeter) {
      seedActivities.add(
        Activity(
          id: 'seed-${_dateKey(date)}-peter',
          title: 'Aftale med Peter',
          emoji: '🎮',
          startTime: DateTime(date.year, date.month, date.day, 16, 0),
          endTime: DateTime(date.year, date.month, date.day, 17, 30),
          owner: ActivityOwner.me,
          isImportant: true,
          description:
              'Peter kommer forbi, og I skal spille sammen. Før Peter kommer skal du gøre dig klar derhjemme.',
          participants: const ['Mig', 'Peter'],
        ),
      );
    }

    if (hasTakeout) {
      seedActivities.add(
        Activity(
          id: 'seed-${_dateKey(date)}-takeout',
          title: 'Takeout',
          emoji: '😋',
          startTime: DateTime(date.year, date.month, date.day, 18, 0),
          endTime: DateTime(date.year, date.month, date.day, 18, 45),
          owner: ActivityOwner.family,
          description: 'Vælg mellem pizza eller sandwich.',
          participants: const ['Mig', 'Mor', 'Far'],
        ),
      );
    }

    if (hasSport) {
      seedActivities.add(
        Activity(
          id: 'seed-${_dateKey(date)}-sport',
          title: 'Idræt',
          emoji: '⚽',
          startTime: DateTime(date.year, date.month, date.day, 17, 0),
          endTime: DateTime(date.year, date.month, date.day, 18, 0),
          owner: ActivityOwner.me,
          isFavorite: true,
          description: 'Idrætstræning i hallen.',
          participants: const ['Mig'],
        ),
      );
    }

    if (hasHomework) {
      seedActivities.add(
        Activity(
          id: 'seed-${_dateKey(date)}-lektier',
          title: 'Lektier',
          emoji: '📘',
          startTime: DateTime(date.year, date.month, date.day, 20, 0),
          endTime: DateTime(date.year, date.month, date.day, 21, 0),
          owner: ActivityOwner.me,
          description: 'Dansk lektier og matematik lektier.',
          participants: const ['Mig'],
        ),
      );
    }

    if (hasDogWalk) {
      seedActivities.add(
        Activity(
          id: 'seed-${_dateKey(date)}-hund',
          title: 'Gå med hunden',
          emoji: '🐕',
          startTime: DateTime(date.year, date.month, date.day, 8, 30),
          endTime: DateTime(date.year, date.month, date.day, 9, 0),
          owner: ActivityOwner.family,
          description: 'Gå en kort tur med hunden.',
          participants: const ['Mig', 'Far'],
        ),
      );
    }

    seedActivities.sort((a, b) => a.startTime.compareTo(b.startTime));
    return seedActivities;
  }
}