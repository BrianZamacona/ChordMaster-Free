import 'package:chordmaster_free/features/health/health_viewmodel.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_store.dart';

class _FakeNotifications extends NotificationService {
  _FakeNotifications() : super.forTesting();

  int shown = 0;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> showBreakReminder() async => shown++;

  @override
  Future<void> cancelAllReminders() async {}
}

void main() {
  testWidgets('con avisos cada 15 min: uno a los 15, otro a los 30; sin avisos fuera de la sesión', (
    tester,
  ) async {
    final notifications = _FakeNotifications();
    // Ajustes guardados: avisos activados, cada 15 min.
    final storage = InMemoryStore()
      ..settings['health_reminders_enabled'] = true
      ..settings['health_reminder_interval'] = 15;
    final container = ProviderContainer(
      overrides: [
        keyValueStoreProvider.overrideWithValue(storage),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
    );
    addTearDown(container.dispose);
    final vm = container.read(healthViewModelProvider.notifier);
    await tester.pump();
    expect(container.read(healthViewModelProvider).remindersEnabled, isTrue);
    expect(container.read(healthViewModelProvider).reminderIntervalMinutes, 15);

    var now = DateTime(2026);
    vm
      ..clock = (() => now)
      ..startSession();

    Future<void> advance(Duration d) async {
      now = now.add(d);
      await tester.pump(const Duration(seconds: 1));
    }

    await advance(const Duration(minutes: 14, seconds: 58));
    expect(notifications.shown, 0);
    expect(container.read(healthViewModelProvider).breakDue, isFalse);

    await advance(const Duration(seconds: 3)); // 15:01
    expect(notifications.shown, 1);
    expect(container.read(healthViewModelProvider).breakDue, isTrue);
    vm.dismissBreak();

    await advance(const Duration(minutes: 15)); // 30:01
    expect(notifications.shown, 2);
    expect(container.read(healthViewModelProvider).sessionSeconds, 30 * 60 + 1);

    // En pausa no avisa aunque pase el tiempo; al reanudar sigue donde iba.
    vm.stopSession();
    now = now.add(const Duration(hours: 1));
    await tester.pump(const Duration(seconds: 2));
    expect(notifications.shown, 2);
    vm.startSession();
    await advance(const Duration(seconds: 10));
    expect(container.read(healthViewModelProvider).sessionSeconds, 30 * 60 + 11);
    vm.stopSession();
  });
}
