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
  });

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
  }) => HealthState(
    isSessionActive: isSessionActive ?? this.isSessionActive,
    sessionSeconds: sessionSeconds ?? this.sessionSeconds,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    reminderIntervalMinutes: reminderIntervalMinutes ?? this.reminderIntervalMinutes,
    isLoading: isLoading ?? this.isLoading,
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

  /// Starts the practice session timer.
  void startSession() {
    if (state.isSessionActive) return;
    state = state.copyWith(isSessionActive: true, sessionSeconds: 0);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(sessionSeconds: state.sessionSeconds + 1);
    });
  }

  /// Stops the practice session timer.
  void stopSession() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isSessionActive: false);
  }

  /// Resets the session timer.
  void resetSession() {
    stopSession();
    state = state.copyWith(sessionSeconds: 0);
  }

  /// Toggles break reminders on/off.
  Future<void> toggleReminders({required bool enabled}) async {
    try {
      final storage = ref.read(storageServiceProvider);
      state = state.copyWith(remindersEnabled: enabled);
      await storage.save(StorageService.settingsBox, _keyRemindersEnabled, enabled);
      if (enabled) {
        final granted = await NotificationService.instance.requestPermissions();
        if (granted) {
          await NotificationService.instance.scheduleHealthReminder(
            Duration(minutes: state.reminderIntervalMinutes),
          );
          await AchievementService.instance.unlock('health_conscious');
        } else {
          state = state.copyWith(remindersEnabled: false);
          await storage.save(StorageService.settingsBox, _keyRemindersEnabled, false);
        }
      } else {
        await NotificationService.instance.cancelAllReminders();
      }
    } catch (e, st) {
      debugPrint('HealthViewModel.toggleReminders error: $e\n$st');
    }
  }

  /// Sets the break reminder interval in minutes.
  Future<void> setReminderInterval(int minutes) async {
    try {
      final storage = ref.read(storageServiceProvider);
      state = state.copyWith(reminderIntervalMinutes: minutes);
      await storage.save(StorageService.settingsBox, _keyReminderInterval, minutes);
      if (state.remindersEnabled) {
        await NotificationService.instance.scheduleHealthReminder(
          Duration(minutes: minutes),
        );
      }
    } catch (e, st) {
      debugPrint('HealthViewModel.setReminderInterval error: $e\n$st');
    }
  }
}
