import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/practice/multi_day_challenges.dart';
import 'key_value_store.dart';

/// Días en que se practicó cada actividad, para los retos de varios días.
/// Se guardan en [StorageBoxes.userProgress] como `{actividad: [días]}` y solo
/// los últimos [keepDays] (ningún reto mira más atrás).
final activityLogProvider =
    NotifierProvider<ActivityLog, Map<PracticeActivity, Set<String>>>(
  ActivityLog.new,
);

class ActivityLog extends Notifier<Map<PracticeActivity, Set<String>>> {
  static const keyDays = 'activity_days';
  static const keepDays = 30;

  @override
  Map<PracticeActivity, Set<String>> build() {
    _load();
    return const {};
  }

  KeyValueStore get _storage => ref.read(keyValueStoreProvider);

  Future<void> _load() async {
    try {
      final raw = await _storage.get<Map<dynamic, dynamic>>(
            StorageBoxes.userProgress,
            keyDays,
          ) ??
          const {};
      final byName = {for (final a in PracticeActivity.values) a.name: a};
      final loaded = {
        for (final MapEntry(:key, :value) in raw.entries)
          if (byName[key] case final a? when value is List)
            a: value.whereType<String>().toSet(),
      };
      // Lo que se registró mientras se leía el disco se conserva.
      state = {
        for (final a in {...loaded.keys, ...state.keys})
          a: {...?loaded[a], ...?state[a]},
      };
    } catch (e, st) {
      debugPrint('ActivityLog._load error: $e\n$st');
    }
  }

  /// Anota que hoy se practicó [activity].
  Future<void> record(PracticeActivity activity, {DateTime? now}) async {
    final today = now ?? DateTime.now();
    final key = dayKey(today);
    if (state[activity]?.contains(key) ?? false) return;
    final oldest = dayKey(today.subtract(const Duration(days: keepDays)));
    state = {
      ...state,
      activity: {
        for (final d in {...?state[activity], key})
          if (d.compareTo(oldest) > 0) d,
      },
    };
    try {
      await _storage.save(StorageBoxes.userProgress, keyDays, {
        for (final MapEntry(:key, :value) in state.entries)
          key.name: value.toList()..sort(),
      });
    } catch (e, st) {
      debugPrint('ActivityLog.record error: $e\n$st');
    }
  }
}
