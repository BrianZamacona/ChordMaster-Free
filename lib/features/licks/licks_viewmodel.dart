import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/licks/lick_transpose.dart';
import '../../domain/licks/licks.dart';
import '../../domain/practice/multi_day_challenges.dart';
import '../../domain/practice/technique_exercises.dart';
import '../../services/activity_log.dart';
import '../../services/key_value_store.dart';

/// Récords y tempo de cada frase de la biblioteca.
class LicksState {
  const LicksState({
    this.records = const {},
    this.tempos = const {},
    this.favorites = const {},
    this.roots = const {},
    this.backing = false,
  });

  /// ▶ suena con el acompañamiento (los acordes de fondo) debajo; de la
  /// sesión, para todas las frases.
  final bool backing;

  /// Mejor tempo tocado limpio con el micrófono, por id.
  final Map<String, int> records;

  /// Tempo elegido en esta sesión ("más lento"), por id; sin él, el suyo.
  final Map<String, int> tempos;

  /// Frases marcadas con la estrella.
  final Set<String> favorites;

  /// Tónica elegida en esta sesión (transponer), por id; sin ella, la suya.
  final Map<String, int> roots;

  int tempoOf(String id) => tempos[id] ?? licksById[id]!.bpm;
  int rootOf(String id) => roots[id] ?? licksById[id]!.scale.root;

  LicksState copyWith({
    Map<String, int>? records,
    Map<String, int>? tempos,
    Set<String>? favorites,
    Map<String, int>? roots,
    bool? backing,
  }) => LicksState(
    records: records ?? this.records,
    tempos: tempos ?? this.tempos,
    favorites: favorites ?? this.favorites,
    roots: roots ?? this.roots,
    backing: backing ?? this.backing,
  );
}

final licksViewModelProvider = NotifierProvider<LicksViewModel, LicksState>(LicksViewModel.new);

/// Los récords se guardan en [StorageBoxes.userProgress] como `{id: bpm}` y
/// los favoritos como una lista de ids.
class LicksViewModel extends Notifier<LicksState> {
  static const keyRecords = 'licks_best_bpm';
  static const keyFavorites = 'licks_favorites';

  @override
  LicksState build() {
    _load();
    return const LicksState();
  }

  KeyValueStore get _storage => ref.read(keyValueStoreProvider);

  Future<void> _load() async {
    try {
      final raw = await _storage.get<Map<dynamic, dynamic>>(StorageBoxes.userProgress, keyRecords) ??
          const {};
      final favorites =
          await _storage.get<List<dynamic>>(StorageBoxes.userProgress, keyFavorites) ?? const [];
      if (!ref.mounted) return;
      state = state.copyWith(
        records: {
          for (final MapEntry(:key, :value) in raw.entries)
            if (key is String && licksById.containsKey(key) && value is int) key: value,
        },
        // Un id que ya no existe se descarta.
        favorites: {
          ...state.favorites,
          for (final id in favorites)
            if (id is String && licksById.containsKey(id)) id,
        },
      );
    } catch (e, st) {
      debugPrint('LicksViewModel._load error: $e\n$st');
    }
  }

  /// Marca o desmarca [id] como favorita y lo guarda.
  Future<void> toggleFavorite(String id) async {
    final favorites = {...state.favorites};
    if (!favorites.remove(id)) favorites.add(id);
    state = state.copyWith(favorites: favorites);
    try {
      await _storage.save(StorageBoxes.userProgress, keyFavorites, favorites.toList()..sort());
    } catch (e, st) {
      debugPrint('LicksViewModel.toggleFavorite error: $e\n$st');
    }
  }

  /// Tónica de [id] para esta sesión (solo si la frase se puede llevar ahí).
  void setRoot(String id, int root) {
    if (transposeShift(licksById[id]!, root) == null) return;
    state = state.copyWith(roots: {...state.roots, id: root % 12});
  }

  /// Suena (o no) el acompañamiento debajo de la frase.
  void setBacking({required bool on}) => state = state.copyWith(backing: on);

  /// Tempo de [id] para esta sesión (dentro de los límites de Técnica).
  void setTempo(String id, int bpm) => state = state.copyWith(
    tempos: {...state.tempos, id: bpm.clamp(techniqueMinBpm, techniqueMaxBpm)},
  );

  /// Una pasada limpia a [bpm]: cuenta como día de técnica y, si supera el
  /// récord, se guarda. Devuelve si fue récord.
  Future<bool> saveClean(String id, int bpm) async {
    unawaited(ref.read(activityLogProvider.notifier).record(PracticeActivity.technique));
    final best = state.records[id];
    if (best != null && best >= bpm) return false;
    final records = {...state.records, id: bpm};
    state = state.copyWith(records: records);
    try {
      await _storage.save(StorageBoxes.userProgress, keyRecords, records);
    } catch (e, st) {
      debugPrint('LicksViewModel.saveClean error: $e\n$st');
    }
    return true;
  }
}
