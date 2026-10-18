
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_strings.dart';

/// Servicio singleton que gestiona las notificaciones locales para ChordMaster Free.
/// Provider del servicio (los tests lo reemplazan por un doble).
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService.instance);

class NotificationService {
  factory NotificationService() => instance;
  NotificationService._internal();

  /// Para dobles de prueba (se inyectan con [notificationServiceProvider]).
  @visibleForTesting
  NotificationService.forTesting();

  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static const int _healthReminderId = 1001;
  static const String _channelId = 'health_reminders';
  // Se ven en los ajustes de notificaciones de Android: en el idioma de la app.
  static String get _channelName => AppStrings.reminderChannelName;
  static String get _channelDesc => AppStrings.reminderChannelDesc;

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
        final channel = AndroidNotificationChannel(
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

  /// Muestra ahora el aviso de pausa (lo dispara la sesión de práctica cada
  /// N minutos; no hay notificaciones programadas fuera de la práctica).
  Future<void> showBreakReminder() async {
    try {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(presentBadge: false),
      );
      await _notifications.show(
        id: _healthReminderId,
        title: AppStrings.reminderTitle,
        body: AppStrings.reminderBody,
        notificationDetails: details,
      );
    } catch (e, st) {
      debugPrint('NotificationService.showBreakReminder error: $e\n$st');
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
}
