import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Singleton service that manages local notifications for ChordMaster Free.
///
/// Handles initialisation for both Android and iOS, permission requests, and
/// scheduling / cancelling periodic health reminders that encourage the user
/// to take a break and stretch their hands.
///
/// ### Usage
/// ```dart
/// await NotificationService().initialize();
/// final granted = await NotificationService().requestPermissions();
/// if (granted) {
///   await NotificationService().scheduleHealthReminder(
///     const Duration(hours: 1),
///   );
/// }
/// ```
class NotificationService {

  /// Factory constructor always returns [instance].
  factory NotificationService() => instance;

  NotificationService._internal();
  /// The singleton instance.
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Notification ID used for the periodic health reminder.
  static const int _healthReminderId = 1001;

  /// Notification channel ID for health reminders (Android).
  static const String _channelId = 'health_reminders';

  /// Human-readable channel name shown in Android notification settings.
  static const String _channelName = 'Health Reminders';

  /// Channel description shown in Android notification settings.
  static const String _channelDesc =
      'Periodic reminders to take a break and stretch your hands.';

  bool _initialised = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Initialises the notifications plugin for Android and iOS.
  ///
  /// Creates the Android notification channel and configures iOS settings.
  /// Safe to call multiple times; subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_initialised) return;
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(initSettings);

      // Create the Android notification channel.
      if (!kIsWeb && Platform.isAndroid) {
        const channel = AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.defaultImportance,
        );
        await _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(channel);
      }

      _initialised = true;
    } catch (e, st) {
      debugPrint('NotificationService.initialize error: $e\n$st');
    }
  }

  // ── Permissions ───────────────────────────────────────────────────────────

  /// Requests notification permissions from the operating system.
  ///
  /// On iOS this shows the system permission dialog; on Android 13+ it
  /// requests the POST_NOTIFICATIONS permission.
  ///
  /// Returns `true` if permission was granted, `false` otherwise.
  Future<bool> requestPermissions() async {
    try {
      if (kIsWeb) return false;

      if (Platform.isIOS) {
        final iosImpl = _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final granted = await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      if (Platform.isAndroid) {
        final androidImpl = _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final granted =
            await androidImpl?.requestNotificationsPermission() ?? false;
        return granted;
      }

      return false;
    } catch (e, st) {
      debugPrint('NotificationService.requestPermissions error: $e\n$st');
      return false;
    }
  }

  // ── Scheduling ────────────────────────────────────────────────────────────

  /// Schedules a repeating health reminder notification at the given
  /// [interval].
  ///
  /// The reminder uses the message:
  /// *"Time for a break! Stretch your hands 🎸"*
  ///
  /// Only the [RepeatInterval] values supported by
  /// `flutter_local_notifications` (`hourly`, `daily`, `weekly`) are mapped.
  /// Intervals shorter than one hour fall back to hourly; longer intervals
  /// default to daily.
  ///
  /// Cancels any existing health reminder before scheduling the new one.
  Future<void> scheduleHealthReminder(Duration interval) async {
    try {
      await cancelAllReminders();

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final repeatInterval = _durationToRepeatInterval(interval);

      await _notifications.periodicallyShow(
        _healthReminderId,
        'ChordMaster Reminder',
        'Time for a break! Stretch your hands 🎸',
        repeatInterval,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e, st) {
      debugPrint('NotificationService.scheduleHealthReminder error: $e\n$st');
    }
  }

  /// Cancels all scheduled health reminder notifications.
  Future<void> cancelAllReminders() async {
    try {
      await _notifications.cancel(_healthReminderId);
    } catch (e, st) {
      debugPrint('NotificationService.cancelAllReminders error: $e\n$st');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Maps a [Duration] to the closest supported [RepeatInterval].
  ///
  /// - < 1 h  → [RepeatInterval.hourly]
  /// - 1 h    → [RepeatInterval.hourly]
  /// - ≥ 7 d  → [RepeatInterval.weekly]
  /// - otherwise → [RepeatInterval.daily]
  RepeatInterval _durationToRepeatInterval(Duration interval) {
    if (interval.inHours < 1) return RepeatInterval.hourly;
    if (interval.inHours == 1) return RepeatInterval.hourly;
    if (interval.inDays >= 7) return RepeatInterval.weekly;
    if (interval.inDays >= 1) return RepeatInterval.daily;
    return RepeatInterval.hourly;
  }
}
