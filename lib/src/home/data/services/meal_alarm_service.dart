import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:befit_fitness_app/src/home/domain/models/daily_food_entry.dart';

const _batteryChannel = MethodChannel('com.befit_fitness.app/battery');

/// Schedules and cancels local notifications for meal reminders.
class MealAlarmService {
  static final MealAlarmService _instance = MealAlarmService._();
  factory MealAlarmService() => _instance;

  MealAlarmService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  static const String _scheduledIdsKey = 'meal_alarm_scheduled_ids';

  /// Channel ID for alarm-style reminders (wake alarm sound, ring until dismissed).
  static const String _channelId = 'meal_reminders_v4';

  /// System default alarm sound URI (Android). Fetched in init().
  String? _defaultAlarmSoundUri;

  /// Channel without custom sound so it always creates successfully on all devices.
  AndroidNotificationChannel get _channel => AndroidNotificationChannel(
        _channelId,
        'Meal reminders',
        description: 'Meal reminders (ring until you stop)',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );

  /// Initialize the notification plugin and timezone. Call from main().
  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final deviceTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(deviceTz.identifier));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: android,
      iOS: ios,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (Platform.isAndroid) {
      try {
        _defaultAlarmSoundUri = await _batteryChannel.invokeMethod<String>('getDefaultAlarmSoundUri');
      } catch (_) {}
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
      await requestNotificationPermissionIfNeeded();
    }

    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, sound: true);
    }

    _initialized = true;
  }

  /// Request notification permission (Android 13+). Call before scheduling so user is prompted when setting an alarm.
  Future<void> requestNotificationPermissionIfNeeded() async {
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }
  }

  void _onNotificationTapped(NotificationResponse response) {}

  /// Builds Android notification details with alarm sound and FLAG_INSISTENT (ring until dismissed).
  AndroidNotificationDetails _buildAndroidNotificationDetails() {
    return AndroidNotificationDetails(
      _channelId,
      'Meal reminders',
      channelDescription: 'Meal reminders (ring until you stop)',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      onlyAlertOnce: false,
      sound: _defaultAlarmSoundUri != null && _defaultAlarmSoundUri!.isNotEmpty
          ? UriAndroidNotificationSound(_defaultAlarmSoundUri!)
          : null,
      additionalFlags: Int32List.fromList([4]),
    );
  }

  /// Simple notification details (no custom sound, no FLAG_INSISTENT). Use as fallback when alarm-style fails.
  AndroidNotificationDetails _buildSimpleAndroidNotificationDetails() {
    return const AndroidNotificationDetails(
      _channelId,
      'Meal reminders',
      channelDescription: 'Meal reminders',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
    );
  }

  /// Returns a stable positive notification id from [entryId].
  int _notificationId(String entryId) {
    return entryId.hashCode.abs() % 0x7FFFFFFF;
  }

  /// Parses alarm time string (supports "HH:mm" or "HH.mm").
  static (int hour, int minute)? _parseAlarmTime(String alarmTime) {
    final normalized = alarmTime.trim().replaceAll('.', ':');
    final parts = normalized.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0].trim());
    final minute = int.tryParse(parts[1].trim());
    if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return (hour, minute);
  }

  /// Schedules a one-time notification for the next occurrence of [alarmTime] (HH:mm or HH.mm).
  /// If that time today has passed, schedules for tomorrow.
  /// Requests notification permission before scheduling so the user is prompted when setting an alarm.
  Future<void> scheduleAlarm(DailyFoodEntry entry) async {
    if (entry.alarmTime == null || entry.alarmTime!.isEmpty) return;
    if (!_initialized) return;

    final parsed = _parseAlarmTime(entry.alarmTime!);
    if (parsed == null) return;
    final (hour, minute) = parsed;

    await requestNotificationPermissionIfNeeded();

    tz.TZDateTime scheduled;
    try {
      final local = tz.local;
      final now = tz.TZDateTime.now(local);
      scheduled = tz.TZDateTime(
        local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
        0,
        0,
      );
      if (!scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      final minFuture = now.add(const Duration(seconds: 1));
      if (!scheduled.isAfter(minFuture)) {
        scheduled = minFuture;
      }
    } catch (e) {
      return;
    }

    final id = _notificationId(entry.id);

    AndroidNotificationDetails androidDetails;
    try {
      androidDetails = _buildAndroidNotificationDetails();
    } catch (e) {
      androidDetails = _buildSimpleAndroidNotificationDetails();
    }
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    AndroidScheduleMode scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final canExact = await androidPlugin?.canScheduleExactNotifications();
      if (canExact == true) {
        scheduleMode = AndroidScheduleMode.alarmClock;
      } else if (canExact == false) {
        scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
      }
    }

    try {
      if (Platform.isAndroid) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.zonedSchedule(
          id,
          'Meal reminder',
          'Time for ${entry.mealName}',
          scheduled,
          androidDetails,
          scheduleMode: scheduleMode,
          payload: entry.id,
        );
      } else {
        await _plugin.zonedSchedule(
          id,
          'Meal reminder',
          'Time for ${entry.mealName}',
          scheduled,
          details,
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: entry.id,
        );
      }
    } catch (e) {
      rethrow;
    }
    await _addScheduledEntryId(entry.id);
  }

  Future<void> _addScheduledEntryId(String entryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_scheduledIdsKey) ?? [];
      if (!list.contains(entryId)) {
        list.add(entryId);
        await prefs.setStringList(_scheduledIdsKey, list);
      }
    } catch (_) {}
  }

  Future<void> _removeScheduledEntryId(String entryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_scheduledIdsKey) ?? [];
      list.remove(entryId);
      await prefs.setStringList(_scheduledIdsKey, list);
    } catch (_) {}
  }

  /// Cancels all scheduled meal reminders. Call when plan is deactivated or at midnight.
  /// Uses both stored IDs and plugin cancelAll() so no reminders ring when plan is inactive.
  Future<void> cancelAllAlarms() async {
    if (!_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_scheduledIdsKey) ?? [];
      for (final entryId in list) {
        final id = _notificationId(entryId);
        await _plugin.cancel(id);
      }
      await prefs.setStringList(_scheduledIdsKey, []);
      // Cancel ALL pending notifications so any meal reminders (including from previous sessions) are removed
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// Schedules a test notification in [seconds] seconds. Use to verify notifications work.
  /// Returns true if scheduled successfully.
  Future<bool> showTestNotificationInSeconds(int seconds) async {
    if (!_initialized) return false;
    await requestNotificationPermissionIfNeeded();
    final local = tz.local;
    final now = tz.TZDateTime.now(local);
    final scheduled = now.add(Duration(seconds: seconds));
    const testId = 0x7FFFFFFE; // Fixed ID so we don't clash with entry IDs
    Future<void> scheduleWith(AndroidNotificationDetails details) async {
      if (Platform.isAndroid) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.zonedSchedule(
          testId,
          'Meal reminder (test)',
          'If you see this, reminders are working!',
          scheduled,
          details,
          scheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } else {
        final notifDetails = NotificationDetails(
          android: details,
          iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        );
        await _plugin.zonedSchedule(
          testId,
          'Meal reminder (test)',
          'If you see this, reminders are working!',
          scheduled,
          notifDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
    try {
      await scheduleWith(_buildAndroidNotificationDetails());
      return true;
    } catch (e) {
      try {
        await scheduleWith(_buildSimpleAndroidNotificationDetails());
        return true;
      } catch (e2) {
        return false;
      }
    }
  }

  /// Cancels the scheduled notification for this entry.
  Future<void> cancelAlarm(String entryId) async {
    if (!_initialized) return;
    final id = _notificationId(entryId);
    await _plugin.cancel(id);
    await _removeScheduledEntryId(entryId);
  }

  /// Reschedules alarms for all entries that have [alarmTime]. Only call when plan is active for today.
  /// Call [cancelAllAlarms] when plan is deactivated or at midnight.
  Future<void> rescheduleFromEntries(List<DailyFoodEntry> entries) async {
    if (!_initialized) return;
    await cancelAllAlarms();
    final withAlarm = entries.where((e) => e.alarmTime != null && e.alarmTime!.isNotEmpty).toList();
    for (final e in withAlarm) {
      await scheduleAlarm(e);
    }
  }
}
