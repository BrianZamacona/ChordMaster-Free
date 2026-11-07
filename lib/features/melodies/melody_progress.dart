import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/melodies/melody_progress.dart';
import '../../services/key_value_store.dart';

final melodyProgressProvider =
    NotifierProvider<MelodyProgressViewModel, MelodyProgress>(
  MelodyProgressViewModel.new,
);

class MelodyProgressViewModel extends Notifier<MelodyProgress> {
  static const keyBest = 'melodies_best_bpm';
  static const keyRead = 'melodies_read';

  @override
  MelodyProgress build() {
    _load();
    return const MelodyProgress();
  }

  KeyValueStore get _storage => ref.read(keyValueStoreProvider);

  Future<void> _load() async {
    try {
      final best = await _storage.get<Map<dynamic, dynamic>>(
            StorageBoxes.userProgress,
            keyBest,
          ) ??
          const {};
      final read = await _storage.get<List<dynamic>>(
            StorageBoxes.userProgress,
            keyRead,
          ) ??
          const [];
      state = MelodyProgress(
        best: {
          for (final MapEntry(:key, :value) in best.entries)
            if (key is String && value is int) key: value,
          ...state.best,
        },
        read: {...read.whereType<String>(), ...state.read},
      );
    } catch (e, st) {
      debugPrint('MelodyProgressViewModel._load error: $e\n$st');
    }
  }

  /// "Me salió limpio a [bpm]": guarda el tempo si supera el mejor.
  Future<void> saveClean(String stepId, int bpm) async {
    final current = state.best[stepId];
    if (current != null && current >= bpm) return;
    final best = {...state.best, stepId: bpm};
    state = state.copyWith(best: best);
    try {
      await _storage.save(StorageBoxes.userProgress, keyBest, best);
    } catch (e, st) {
      debugPrint('MelodyProgressViewModel.saveClean error: $e\n$st');
    }
  }

  /// Marca un paso de teoría como leído o, si ya lo estaba, como pendiente.
  Future<void> toggleRead(String stepId) async {
    final read = {...state.read};
    if (!read.remove(stepId)) read.add(stepId);
    state = state.copyWith(read: read);
    try {
      await _storage.save(
        StorageBoxes.userProgress,
        keyRead,
        read.toList()..sort(),
      );
    } catch (e, st) {
      debugPrint('MelodyProgressViewModel.toggleRead error: $e\n$st');
    }
  }
}
