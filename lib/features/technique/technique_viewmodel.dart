import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/practice/multi_day_challenges.dart';
import '../../domain/practice/technique_exercises.dart';
import '../../services/activity_log.dart';
import '../../services/key_value_store.dart';

/// Traste de inicio, tempo y récords de los ejercicios de técnica.
class TechniqueState {
  const TechniqueState({
    this.startFret = 1,
    this.bpm = techniqueDefaultBpm,
    this.records = const {},
  });

  final int startFret;
  final int bpm;

  /// Mejor tempo tocado limpio, por ejercicio.
  final Map<TechniqueExercise, int> records;

  TechniqueState copyWith({
    int? startFret,
    int? bpm,
    Map<TechniqueExercise, int>? records,
  }) =>
      TechniqueState(
        startFret: startFret ?? this.startFret,
        bpm: bpm ?? this.bpm,
        records: records ?? this.records,
      );
}

final techniqueViewModelProvider =
    NotifierProvider.autoDispose<TechniqueViewModel, TechniqueState>(
  TechniqueViewModel.new,
);

/// Los récords se guardan en [StorageBoxes.userProgress] como
/// `{ejercicio: bpm}`.
class TechniqueViewModel extends Notifier<TechniqueState> {
  static const keyRecords = 'technique_best_bpm';

  @override
  TechniqueState build() {
    _load();
    return const TechniqueState();
  }

  KeyValueStore get _storage => ref.read(keyValueStoreProvider);

  Future<void> _load() async {
    try {
      final raw = await _storage.get<Map<dynamic, dynamic>>(
            StorageBoxes.userProgress,
            keyRecords,
          ) ??
          const {};
      final byName = {for (final e in TechniqueExercise.values) e.name: e};
      state = state.copyWith(
        records: {
          for (final MapEntry(:key, :value) in raw.entries)
            if (byName[key] case final e? when value is int) e: value,
        },
      );
    } catch (e, st) {
      debugPrint('TechniqueViewModel._load error: $e\n$st');
    }
  }

  void changeStartFret(int fret) => state = state.copyWith(startFret: fret);

  /// Sube o baja el tempo un paso ([techniqueBpmStep]).
  void stepBpm(int direction) => state = state.copyWith(
    bpm: (state.bpm + direction * techniqueBpmStep)
        .clamp(techniqueMinBpm, techniqueMaxBpm),
  );

  /// "Me salió limpio": guarda el tempo actual si supera el récord.
  Future<void> saveRecord(TechniqueExercise exercise) async {
    unawaited(ref.read(activityLogProvider.notifier).record(PracticeActivity.technique));
    final current = state.records[exercise];
    if (current != null && current >= state.bpm) return;
    final records = {...state.records, exercise: state.bpm};
    state = state.copyWith(records: records);
    try {
      await _storage.save(StorageBoxes.userProgress, keyRecords, {
        for (final MapEntry(:key, :value) in records.entries) key.name: value,
      });
    } catch (e, st) {
      debugPrint('TechniqueViewModel.saveRecord error: $e\n$st');
    }
  }
}
