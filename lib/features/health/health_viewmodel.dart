import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/achievement_service.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';

/// Immutable state for [HealthViewModel].
class HealthState {
  const HealthState({
    this.isSessionActive = false,
    this.sessionSeconds = 0,
    this.remindersEnabled = false,
    this.reminderIntervalMinutes = 30,
    this.isLoading = true,
    this.breakDue = false,
  });

  /// Toca pausa: se cumplió el intervalo durante la sesión (aviso en pantalla
  /// hasta que el usuario lo cierre).
  final bool breakDue;

  final bool isSessionActive;
  final int sessionSeconds;
  final bool remindersEnabled;
  final int reminderIntervalMinutes;
  final bool isLoading;

  HealthState copyWith({
    bool? isSessionActive,
    int? sessionSeconds,
    bool? remindersEnabled,
    int? reminderIntervalMinutes,
    bool? isLoading,
    bool? breakDue,
  }) => HealthState(
    isSessionActive: isSessionActive ?? this.isSessionActive,
    sessionSeconds: sessionSeconds ?? this.sessionSeconds,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    reminderIntervalMinutes: reminderIntervalMinutes ?? this.reminderIntervalMinutes,
    isLoading: isLoading ?? this.isLoading,
    breakDue: breakDue ?? this.breakDue,
  );
}

/// Provider for [HealthViewModel].
final healthViewModelProvider =
    NotifierProvider<HealthViewModel, HealthState>(HealthViewModel.new);

/// Manages practice health state: session timer, break reminders.
class HealthViewModel extends Notifier<HealthState> {
  static const _keyRemindersEnabled = 'health_reminders_enabled';
  static const _keyReminderInterval = 'health_reminder_interval';

  Timer? _timer;

  @override
  HealthState build() {
    ref.onDispose(() => _timer?.cancel());
    _loadSettings();
    return const HealthState();
  }

  Future<void> _loadSettings() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final enabled = await storage.get<bool>(
            StorageService.settingsBox, _keyRemindersEnabled) ??
          false;
      final interval = await storage.get<int>(
            StorageService.settingsBox, _keyReminderInterval) ??
          30;
      state = state.copyWith(
        remindersEnabled: enabled,
        reminderIntervalMinutes: interval,
        isLoading: false,
      );
    } catch (e, st) {
      debugPrint('HealthViewModel._loadSettings error: $e\n$st');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Reloj de la sesión: el tiempo sale de [clock] (no de contar ticks), así
  /// no se atrasa si el sistema retrasa el temporizador. Los tests lo
  /// reemplazan para avanzar el tiempo sin esperar.
  @visibleForTesting
  DateTime Function() clock = DateTime.now;
  DateTime? _startedAt;
  int _secondsBefore = 0;


  /// Empieza (o reanuda) la sesión de práctica.
  void startSession() {
    if (state.isSessionActive) return;
    _startedAt = clock();
    _secondsBefore = state.sessionSeconds;
    state = state.copyWith(isSessionActive: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final previous = state.sessionSeconds;
    final now = _secondsBefore + clock().difference(_startedAt!).inSeconds;
    state = state.copyWith(sessionSeconds: now);
    // Aviso de pausa al cruzar cada múltiplo del intervalo.
    final every = state.reminderIntervalMinutes * 60;
    if (state.remindersEnabled && now ~/ every > previous ~/ every) {
      state = state.copyWith(breakDue: true);
      ref.read(notificationServiceProvider).showBreakReminder();
    }
  }

  /// Pausa la sesión (se puede reanudar).
  void stopSession() {
    _timer?.cancel();
    _timer = null;
    _startedAt = null;
    state = state.copyWith(isSessionActive: false);
  }

  /// Vuelve el reloj a cero.
  void resetSession() {
    stopSession();
    state = state.copyWith(sessionSeconds: 0, breakDue: false);
  }

  /// El usuario vio el aviso de pausa.
  void dismissBreak() => state = state.copyWith(breakDue: false);

  /// Toggles break reminders on/off.
  Future<void> toggleReminders({required bool enabled}) async {
    try {
      final storage = ref.read(storageServiceProvider);
      state = state.copyWith(remindersEnabled: enabled);
      await storage.save(StorageService.settingsBox, _keyRemindersEnabled, enabled);
      if (enabled) {
        // Sin permiso de notificaciones el aviso igual sale en pantalla.
        await ref.read(notificationServiceProvider).requestPermissions();
        await AchievementService.instance.unlock('health_conscious');
      } else {
        state = state.copyWith(breakDue: false);
        await ref.read(notificationServiceProvider).cancelAllReminders();
      }
    } catch (e, st) {
      debugPrint('HealthViewModel.toggleReminders error: $e\n$st');
    }
  }

  /// Cada cuántos minutos de práctica avisar.
  Future<void> setReminderInterval(int minutes) async {
    try {
      state = state.copyWith(reminderIntervalMinutes: minutes);
      await ref
          .read(storageServiceProvider)
          .save(StorageService.settingsBox, _keyReminderInterval, minutes);
    } catch (e, st) {
      debugPrint('HealthViewModel.setReminderInterval error: $e\n$st');
    }
  }

}
