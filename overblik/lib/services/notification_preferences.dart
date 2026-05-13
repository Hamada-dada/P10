import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferencesService {
  NotificationPreferencesService._internal();
  static final NotificationPreferencesService _instance =
      NotificationPreferencesService._internal();
  factory NotificationPreferencesService() => _instance;

  static const String _defaultEnabledKey = 'notif_default_enabled';
  static const String _defaultReminderMinutesKey =
      'notif_default_reminder_minutes';

  static const bool _fallbackEnabled = true;
  static const int _fallbackReminderMinutes = 10;

  /// Fixed quick-pick options shown in dropdowns.
  static const List<int> fixedReminderOptions = [10, 30, 60];

  static bool isFixedOption(int minutes) =>
      fixedReminderOptions.contains(minutes);

  Future<bool> loadDefaultEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_defaultEnabledKey) ?? _fallbackEnabled;
  }

  Future<int> loadDefaultReminderMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_defaultReminderMinutesKey);
    if (stored != null && stored >= 0 && stored <= 10080) {
      return stored;
    }
    return _fallbackReminderMinutes;
  }

  Future<void> saveDefaultEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_defaultEnabledKey, value);
  }

  Future<void> saveDefaultReminderMinutes(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_defaultReminderMinutesKey, value);
  }
}
