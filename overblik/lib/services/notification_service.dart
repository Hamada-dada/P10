import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/activity.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _idsKeyPrefix = 'notification_ids_';
  static const int _schedulingWindowDays = 30;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz_data.initializeTimeZones();
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
      debugPrint('NotificationService: timezone set to ${tzInfo.identifier}');
    } catch (e) {
      debugPrint('NotificationService: timezone init failed: $e');
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(settings: initSettings);
    _initialized = true;
    debugPrint('NotificationService: initialized');

    await requestPermissions();
  }

  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImpl =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await androidImpl?.requestNotificationsPermission() ?? false;
      debugPrint('NotificationService: Android permission granted=$granted');
      return granted;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosImpl =
          _plugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosImpl?.requestPermissions(
            alert: true,
            badge: true,
            sound: false,
          ) ??
          false;
      debugPrint('NotificationService: iOS permission granted=$granted');
      return granted;
    }

    return false;
  }

  Future<void> scheduleActivityReminder(Activity activity) async {
    if (!activity.notificationsEnabled) {
      debugPrint(
        'NotificationService: notifications disabled for ${activity.id}',
      );
      return;
    }

    if (activity.isCompleted) {
      debugPrint(
        'NotificationService: skipping completed activity ${activity.id}',
      );
      return;
    }

    await cancelActivityReminders(activity.id);

    final now = DateTime.now();
    final windowEnd = now.add(Duration(days: _schedulingWindowDays));
    final occurrences = _occurrencesInWindow(activity, now, windowEnd);
    final scheduledIds = <int>[];

    for (final occurrenceStart in occurrences) {
      final reminderTime = occurrenceStart.subtract(
        Duration(minutes: activity.reminderMinutesBefore),
      );

      if (!reminderTime.isAfter(now)) {
        debugPrint(
          'NotificationService: skipping past reminder for ${activity.id} '
          'at $reminderTime',
        );
        continue;
      }

      final id = _notificationId(activity.id, occurrenceStart);
      final tzTime = tz.TZDateTime.from(reminderTime, tz.local);
      final body = activity.description.trim().isNotEmpty
          ? activity.description.trim()
          : 'Starter om ${activity.reminderMinutesBefore} minutter';

      try {
        await _plugin.zonedSchedule(
          id: id,
          title: activity.title,
          body: body,
          scheduledDate: tzTime,
          notificationDetails: _notificationDetails(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: activity.id,
        );
        scheduledIds.add(id);
        debugPrint(
          'NotificationService: scheduled id=$id for activity=${activity.id} '
          'at $reminderTime',
        );
      } catch (e) {
        debugPrint('NotificationService: failed to schedule id=$id: $e');
      }
    }

    await _saveScheduledIds(activity.id, scheduledIds);
    debugPrint(
      'NotificationService: scheduled ${scheduledIds.length} reminders '
      'for ${activity.id}',
    );
  }

  Future<void> cancelActivityReminders(String activityId) async {
    final ids = await _loadScheduledIds(activityId);

    for (final id in ids) {
      try {
        await _plugin.cancel(id: id);
        debugPrint('NotificationService: cancelled id=$id for $activityId');
      } catch (e) {
        debugPrint('NotificationService: failed to cancel id=$id: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_idsKeyPrefix$activityId');
    debugPrint(
      'NotificationService: cancelled ${ids.length} reminders for $activityId',
    );
  }

  Future<void> rescheduleActivityReminder(Activity activity) async {
    await cancelActivityReminders(activity.id);
    await scheduleActivityReminder(activity);
  }

  // ── private ──────────────────────────────────────────────────────────────

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'activity_reminders',
        'Aktivitetspåmindelser',
        channelDescription: 'Påmindelser om kommende aktiviteter',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  int _notificationId(String activityId, DateTime occurrenceStart) {
    final key = '$activityId:${occurrenceStart.millisecondsSinceEpoch}';
    var hash = 5381;
    for (final codeUnit in key.codeUnits) {
      hash = ((hash << 5) + hash) ^ codeUnit;
      hash &= 0x7FFFFFFF;
    }
    return hash;
  }

  List<DateTime> _occurrencesInWindow(
    Activity activity,
    DateTime windowStart,
    DateTime windowEnd,
  ) {
    final recurrence = activity.recurrence;

    if (recurrence == ActivityRecurrence.none ||
        recurrence == ActivityRecurrence.custom) {
      if (!activity.startTime.isBefore(windowStart) &&
          activity.startTime.isBefore(windowEnd)) {
        return [activity.startTime];
      }
      return [];
    }

    final recurrenceEndDate = activity.recurrenceEndDate;
    final effectiveEnd = recurrenceEndDate != null &&
            recurrenceEndDate.add(const Duration(days: 1)).isBefore(windowEnd)
        ? recurrenceEndDate.add(const Duration(days: 1))
        : windowEnd;

    if (!effectiveEnd.isAfter(windowStart)) return [];

    final interval =
        activity.recurrenceInterval < 1 ? 1 : activity.recurrenceInterval;

    var current = activity.startTime;
    if (current.isBefore(windowStart)) {
      current = _fastForward(recurrence, interval, current, windowStart);
    }

    final occurrences = <DateTime>[];
    var safety = 0;

    while (current.isBefore(effectiveEnd) && safety < 90) {
      if (!current.isBefore(windowStart)) {
        occurrences.add(current);
      }
      current = _advance(recurrence, interval, current);
      safety++;
    }

    return occurrences;
  }

  DateTime _fastForward(
    ActivityRecurrence recurrence,
    int interval,
    DateTime start,
    DateTime windowStart,
  ) {
    switch (recurrence) {
      case ActivityRecurrence.daily:
        final days = windowStart.difference(start).inDays;
        if (days <= 0) return start;
        final steps = (days + interval - 1) ~/ interval;
        return start.add(Duration(days: steps * interval));

      case ActivityRecurrence.weekly:
        final periodDays = interval * 7;
        final days = windowStart.difference(start).inDays;
        if (days <= 0) return start;
        final steps = (days + periodDays - 1) ~/ periodDays;
        return start.add(Duration(days: steps * periodDays));

      case ActivityRecurrence.monthly:
        var cur = start;
        var safety = 0;
        while (cur.isBefore(windowStart) && safety < 200) {
          cur = _addMonths(cur, interval);
          safety++;
        }
        return cur;

      default:
        return start;
    }
  }

  DateTime _advance(
    ActivityRecurrence recurrence,
    int interval,
    DateTime current,
  ) {
    switch (recurrence) {
      case ActivityRecurrence.daily:
        return current.add(Duration(days: interval));
      case ActivityRecurrence.weekly:
        return current.add(Duration(days: interval * 7));
      case ActivityRecurrence.monthly:
        return _addMonths(current, interval);
      default:
        return current.add(const Duration(days: 999999));
    }
  }

  DateTime _addMonths(DateTime date, int months) {
    final targetMonthIndex = date.month + months;
    final targetYear = date.year + ((targetMonthIndex - 1) ~/ 12);
    final targetMonth = ((targetMonthIndex - 1) % 12) + 1;
    final lastDay = DateTime(targetYear, targetMonth + 1, 0).day;
    final targetDay = date.day > lastDay ? lastDay : date.day;
    return DateTime(
      targetYear,
      targetMonth,
      targetDay,
      date.hour,
      date.minute,
      date.second,
    );
  }

  Future<void> _saveScheduledIds(String activityId, List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_idsKeyPrefix$activityId', jsonEncode(ids));
  }

  Future<List<int>> _loadScheduledIds(String activityId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_idsKeyPrefix$activityId');
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.whereType<int>().toList();
    } catch (_) {
      return [];
    }
  }
}
