
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Servicio singleton que gestiona las notificaciones locales para ChordMaster Free.
class NotificationService {
  factory NotificationService() => instance;
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static const int _healthReminderId = 1001;
  static const String _channelId = 'health_reminders';
  static const String _channelName = 'Health Reminders';
  static const String _channelDesc = 'Periodic reminders to take a break and stretch your hands.';

  bool _initialised = false;

  /// Inicializa el plugin de notificaciones para Android e iOS.
  Future<void> initialize() async {
    if (_initialised) return;
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await _notifications.initialize(settings: initSettings);
      if (!kIsWeb && Platform.isAndroid) {
        const channel = AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
        );
        await _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }
      _initialised = true;
    } catch (e, st) {
      debugPrint('NotificationService.initialize error: $e\n$st');
    }
  }

  /// Solicita permisos de notificación al sistema operativo.
  Future<bool> requestPermissions() async {
    try {
      if (kIsWeb) return false;
      if (Platform.isIOS) {
        final iosImpl = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);
        return granted ?? false;
      }
      if (Platform.isAndroid) {
        final androidImpl = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidImpl?.requestNotificationsPermission() ?? false;
        return granted;
      }
      return false;
    } catch (e, st) {
      debugPrint('NotificationService.requestPermissions error: $e\n$st');
      return false;
    }
  }

  /// Programa un recordatorio de salud periódico.
  Future<void> scheduleHealthReminder(Duration interval) async {
    try {
      await cancelAllReminders();
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        icon: '@mipmap/ic_launcher',
      );
      const iosDetails = DarwinNotificationDetails(presentBadge: false);
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      final repeatInterval = _durationToRepeatInterval(interval);
      await _notifications.periodicallyShow(
        id: _healthReminderId,
        title: 'ChordMaster Reminder',
        body: 'Time for a break! Stretch your hands 🎸',
        repeatInterval: repeatInterval,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e, st) {
      debugPrint('NotificationService.scheduleHealthReminder error: $e\n$st');
    }
  }

  /// Cancela todos los recordatorios de salud programados.
  Future<void> cancelAllReminders() async {
    try {
      await _notifications.cancel(id: _healthReminderId);
    } catch (e, st) {
      debugPrint('NotificationService.cancelAllReminders error: $e\n$st');
    }
  }

  /// Mapea una [Duration] al [RepeatInterval] más cercano soportado.
  RepeatInterval _durationToRepeatInterval(Duration interval) {
    if (interval.inHours < 1) return RepeatInterval.hourly;
    if (interval.inHours == 1) return RepeatInterval.hourly;
    if (interval.inDays >= 7) return RepeatInterval.weekly;
    if (interval.inDays >= 1) return RepeatInterval.daily;
    return RepeatInterval.hourly;
  }
}
