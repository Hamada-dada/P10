import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferencesService {
  NotificationPreferencesService._internal();
  static final NotificationPreferencesService _instance =
      NotificationPreferencesService._internal();
  factory NotificationPreferencesService() => _instance;

  static const String _defaultEnabledKey = 'notif_default_enabled';
  static const String _defaultReminderMinutesKey =
      'notif_default_reminder_minutes';
  static const String _defaultNotificationStyleKey =
      'notif_default_notification_style';

  static const bool _fallbackEnabled = true;
  static const int _fallbackReminderMinutes = 10;
  static const String _fallbackNotificationStyle = 'tydelig';

  /// Fixed quick-pick options shown in reminder dropdowns.
  static const List<int> fixedReminderOptions = [10, 30, 60];

  /// Valid values for notification style.
  static const List<String> notificationStyleOptions = [
    'rolig',
    'tydelig',
    'diskret',
  ];

  static bool isFixedOption(int minutes) =>
      fixedReminderOptions.contains(minutes);

  /// Human-readable label for a reminder duration in minutes.
  static String reminderLabel(int minutes) {
    if (minutes == 60) return '1 time før';
    return '$minutes minutter før';
  }

  /// Human-readable label for a notification style value.
  static String notificationStyleLabel(String style) {
    switch (style) {
      case 'rolig':
        return 'Rolig';
      case 'diskret':
        return 'Diskret';
      case 'tydelig':
      default:
        return 'Tydelig';
    }
  }

  /// Short description shown below the style dropdown.
  static String notificationStyleDescription(String style) {
    switch (style) {
      case 'rolig':
        return 'Vibration, ingen lyd – mindre forstyrrende';
      case 'diskret':
        return 'Ingen lyd, ingen vibration – stille påmindelser';
      case 'tydelig':
      default:
        return 'Lyd og vibration – let at lægge mærke til';
    }
  }

  Future<bool> loadDefaultEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_defaultEnabledKey) ?? _fallbackEnabled;
  }

  Future<int> loadDefaultReminderMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_defaultReminderMinutesKey);
    if (stored != null && fixedReminderOptions.contains(stored)) {
      return stored;
    }
    // Stored value is not a valid fixed option — normalize and persist.
    if (stored != null) {
      await prefs.setInt(_defaultReminderMinutesKey, _fallbackReminderMinutes);
    }
    return _fallbackReminderMinutes;
  }

  Future<String> loadDefaultNotificationStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_defaultNotificationStyleKey);
    if (stored != null && notificationStyleOptions.contains(stored)) {
      return stored;
    }
    return _fallbackNotificationStyle;
  }

  Future<void> saveDefaultEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_defaultEnabledKey, value);
  }

  Future<void> saveDefaultReminderMinutes(int value) async {
    final normalized =
        fixedReminderOptions.contains(value) ? value : _fallbackReminderMinutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_defaultReminderMinutesKey, normalized);
  }

  Future<void> saveDefaultNotificationStyle(String value) async {
    if (!notificationStyleOptions.contains(value)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultNotificationStyleKey, value);
  }
}
