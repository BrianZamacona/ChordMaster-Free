import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/chord_metadata.dart';
import '../../core/i18n/tr.dart';
import '../../data/repository/chord_repository.dart';
import '../../domain/open_chords/chord_shape.dart';
import '../../domain/progressions/progression_builder.dart';
import '../../domain/progressions/progression_data.dart';
import '../../domain/progressions/progression_playback.dart';
import '../../domain/theory/notes.dart';
import '../../domain/voicing/voice_leading.dart';
import '../../services/achievement_service.dart';
import '../../services/audio_service.dart';
import '../../services/key_value_store.dart';

/// Immutable state for [ProgressionsViewModel].
class ProgressionsState {
  const ProgressionsState({
    this.tonic = 0,
    this.progressionId = 'v1-2',
    this.progressionsGenerated = 0,
    this.beginner = false,
    this.custom = const [],
    this.chosen = const {},
    this.playingIndex,
    this.bpm = progressionDefaultBpm,
    this.loop = false,
  });

  /// Tempo al escuchar la progresión (un compás por acorde).
  final int bpm;

  /// Repetir la progresión sin parar al escucharla.
  final bool loop;

  /// Acorde que está sonando al escuchar la progresión (`null` = en silencio).
  final int? playingIndex;

  /// Pitch class de la tónica (C = 0).
  final int tonic;
  final String progressionId;
  final int progressionsGenerated;

  /// Modo principiante: penaliza las cejillas al elegir digitaciones.
  final bool beginner;

  /// Grados de "Mi progresión" (lo que antes era el módulo Componer).
  final List<String> custom;

  /// Digitaciones elegidas a mano en el glosario, por índice de acorde
  /// (orden de chords.json). El resto sigue el camino óptimo.
  final Map<int, FingeringChoice> chosen;

  bool get isCustom => progressionId == customProgressionId;

  /// Progresión elegida: una de [progressions] o la propia del usuario.
  Progression get progression => isCustom
      ? Progression(customProgressionId, custom.join(' - '), custom)
      : progressions.firstWhere(
          (p) => p.id == progressionId,
          orElse: () => progressions.first,
        );

  ProgressionsState copyWith({
    int? tonic,
    String? progressionId,
    int? progressionsGenerated,
    bool? beginner,
    List<String>? custom,
    Map<int, FingeringChoice>? chosen,
    Object? playingIndex = _keep,
    int? bpm,
    bool? loop,
  }) => ProgressionsState(
    tonic: tonic ?? this.tonic,
    progressionId: progressionId ?? this.progressionId,
    progressionsGenerated: progressionsGenerated ?? this.progressionsGenerated,
    beginner: beginner ?? this.beginner,
    custom: custom ?? this.custom,
    chosen: chosen ?? this.chosen,
    playingIndex: identical(playingIndex, _keep) ? this.playingIndex : playingIndex as int?,
    bpm: bpm ?? this.bpm,
    loop: loop ?? this.loop,
  );

  static const Object _keep = Object();
}

/// Digitación elegida para un acorde (orden de chords.json, 6ª → 1ª).
typedef FingeringChoice = ({List<int> frets, List<int> fingers});

/// Id de la progresión armada por el usuario.
const customProgressionId = 'custom';

/// Máximo de acordes en "Mi progresión".
const customProgressionMax = 8;

/// Transición entre dos acordes consecutivos de un camino.
class ProgressionTransition {
  const ProgressionTransition({
    required this.fretShift,
    required this.commonNotes,
    required this.cost,
  });

  final int fretShift;
  final int commonNotes;
  final double cost;
}

class ProgressionStep {
  const ProgressionStep({
    required this.numeral,
    required this.voicing,
    this.transition,
    this.chosen = false,
  });

  final String numeral;
  final ProgressionVoicing voicing;

  /// `true` si el usuario la eligió en el glosario (no es la del camino).
  final bool chosen;

  /// `null` en el primer acorde.
  final ProgressionTransition? transition;
}

class ProgressionPlan {
  const ProgressionPlan({
    required this.progression,
    required this.tonic,
    this.steps = const [],
    this.problem,
  });

  final Progression progression;
  final int tonic;
  final List<ProgressionStep> steps;

  /// Mensaje legible cuando no se pudo armar el camino.
  final String? problem;
}

String _degreeLabel(ProgressionDegree degree, int tonic) {
  final root = pitchClassName(tonic + degree.semitones);
  return '${degree.numeral} (${chordDisplayName(root: root, type: degree.type)})';
}

/// Calcula el camino óptimo y las transiciones; sin efectos secundarios.
ProgressionPlan buildProgressionPlan(
  ProgressionBuilder builder,
  Progression progression,
  int tonic, {
  bool beginner = false,
  Map<int, FingeringChoice> chosen = const {},
}) {
  final layers = builder.layersFor(progression, tonic, beginner: beginner);
  final missing = [
    for (var i = 0; i < layers.length; i++)
      if (layers[i].isEmpty) _degreeLabel(progression.degrees[i], tonic),
  ];
  if (missing.isNotEmpty) {
    return ProgressionPlan(
      progression: progression,
      tonic: tonic,
      problem: tr(
        es: 'No hay digitaciones válidas para: ${missing.join(', ')}.',
        en: 'No valid fingerings for: ${missing.join(', ')}.',
      ),
    );
  }

  final optimal = findOptimalProgressionPath(layers);
  // Las elegidas a mano reemplazan solo su acorde; los demás quedan como en
  // el camino óptimo (la progresión por defecto no cambia).
  final path = [
    for (var i = 0; i < optimal.length; i++)
      if (chosen[i] case final c?)
        builder.voicingFor(
              optimal[i].chord.root,
              optimal[i].chord.type,
              c.frets,
              c.fingers,
            ) ??
            optimal[i]
      else
        optimal[i],
  ];
  if (path.isEmpty) {
    return ProgressionPlan(
      progression: progression,
      tonic: tonic,
      problem: tr(
        es: 'No se encontró un camino de digitaciones para esta progresión.',
        en: 'No fingering path was found for this progression.',
      ),
    );
  }

  return ProgressionPlan(
    progression: progression,
    tonic: tonic,
    steps: [
      for (var i = 0; i < path.length; i++)
        ProgressionStep(
          numeral: progression.degrees[i].numeral,
          voicing: path[i],
          chosen: chosen.containsKey(i),
          transition: i == 0
              ? null
              : ProgressionTransition(
                  fretShift: (path[i].anchorFret - path[i - 1].anchorFret).abs(),
                  commonNotes: retainedPositionCount(path[i - 1], path[i]),
                  cost: calculateVoiceLeadingCost(path[i - 1], path[i]),
                ),
        ),
    ],
  );
}

final progressionBuilderProvider = FutureProvider<ProgressionBuilder>(
  (ref) async =>
      ProgressionBuilder(await ref.read(chordRepositoryProvider).fingerings()),
);

/// Provider for [ProgressionsViewModel].
final progressionsViewModelProvider =
    NotifierProvider<ProgressionsViewModel, ProgressionsState>(
        ProgressionsViewModel.new);

final progressionPlanProvider = Provider<AsyncValue<ProgressionPlan>>((ref) {
  final s = ref.watch(progressionsViewModelProvider);
  final progression = s.progression;
  if (progression.degrees.isEmpty) {
    return AsyncValue.data(ProgressionPlan(progression: progression, tonic: s.tonic));
  }
  return ref
      .watch(progressionBuilderProvider)
      .whenData(
        (b) => buildProgressionPlan(
          b,
          progression,
          s.tonic,
          beginner: s.beginner,
          chosen: s.chosen,
        ),
      );
});

/// Manages progression selection state and the usage counter.
///
/// El contador (logro "composer") sube una vez por progresión distinta
/// (id + tónica), no en cada cambio de selección.
class ProgressionsViewModel extends Notifier<ProgressionsState> {
  static const _keyCount = 'progressions_generated';
  static const _keySeen = 'progressions_seen';
  static const _keyCustom = 'progressions_custom';

  @override
  ProgressionsState build() {
    ref.onDispose(() => _listenTimer?.cancel());
    _seen.clear();
    _loaded = _loadCount();
    return const ProgressionsState();
  }

  /// Progresiones ya contadas, como `id@tónica`.
  final _seen = <String>{};

  /// Los conteos esperan a la carga: si no, un cambio hecho antes de que
  /// termine se pisaría con el valor guardado (o lo pisaría a él).
  late Future<void> _loaded;

  @visibleForTesting
  Future<void> get loaded => _loaded;

  Future<void> _loadCount() async {
    try {
      final storage = ref.read(keyValueStoreProvider);
      final count =
          await storage.get<int>(StorageBoxes.userProgress, _keyCount) ?? 0;
      final seen = await storage.get<List<dynamic>>(
            StorageBoxes.userProgress,
            _keySeen,
          ) ??
          const [];
      _seen.addAll(seen.whereType<String>());
      final custom = await storage.get<List<dynamic>>(
            StorageBoxes.userProgress,
            _keyCustom,
          ) ??
          const [];
      state = state.copyWith(
        progressionsGenerated: count,
        // Si el usuario ya empezó a armar una antes de terminar la carga, gana lo suyo.
        custom: state.custom.isNotEmpty
            ? state.custom
            : [for (final n in custom.whereType<String>()) if (majorDegreeNumerals.contains(n)) n],
      );
    } catch (e, st) {
      debugPrint('ProgressionsViewModel._loadCount error: $e\n$st');
    }
  }

  /// Cada cuánto se mira qué acorde suena.
  static const listenFrame = Duration(milliseconds: 30);

  /// Sube en cada escucha o cambio: una escucha vieja deja de marcar.
  int _listenToken = 0;
  Timer? _listenTimer;

  /// La progresión que suena (para volver a empezarla al cambiar el tempo).
  ProgressionPlan? _listening;

  /// Rasguea [plan] entera (un compás por acorde, al tempo y, con bucle, sin
  /// parar), marcando cuál suena. Llamarla otra vez mientras suena la detiene.
  Future<void> listen(ProgressionPlan plan) async {
    if (state.playingIndex != null) {
      _stopListening();
      return;
    }
    await _start(plan);
  }

  Future<void> _start(ProgressionPlan plan) async {
    final token = ++_listenToken;
    _listenTimer?.cancel();
    _listening = plan;
    final bpm = state.bpm;
    final loop = state.loop;
    final count = plan.steps.length;
    final shapes = [
      for (final s in plan.steps)
        ChordShape(name: '', frets: s.voicing.jsonFrets, fingers: List.filled(6, 0)),
    ];
    final sounds = progressionStrum(shapes, bpm: bpm);
    final seconds = progressionAudioSeconds(count, bpm: bpm, loop: loop);
    final audio = ref.read(audioServiceProvider);
    state = state.copyWith(playingIndex: 0);
    // El temporizador cuenta sus vueltas (`tick` salta si una se atrasa):
    // así la marca sigue al audio, y en los tests avanza con el reloj falso.
    _listenTimer = Timer.periodic(listenFrame, (timer) {
      if (token != _listenToken) return timer.cancel();
      final elapsed = timer.tick * listenFrame.inMicroseconds / 1e6;
      final i = progressionChordAt(elapsed, count, bpm: bpm, loop: loop);
      if (i == null) {
        _stopListening(silence: false);
      } else if (i != state.playingIndex) {
        state = state.copyWith(playingIndex: i);
      }
    });
    await (loop ? audio.loopTab(sounds, seconds: seconds) : audio.playTab(sounds, seconds: seconds));
  }

  void _stopListening({bool silence = true}) {
    _listenToken++;
    _listenTimer?.cancel();
    _listenTimer = null;
    final wasPlaying = state.playingIndex != null;
    if (wasPlaying) state = state.copyWith(playingIndex: null);
    if (wasPlaying && silence) ref.read(audioServiceProvider).stopAll();
  }

  /// Tempo de la escucha (de 5 en 5, 40–200). Si suena, vuelve a empezar.
  void setBpm(int bpm) {
    final next = progressionTempo(bpm);
    if (next == state.bpm) return;
    state = state.copyWith(bpm: next);
    _restartIfPlaying();
  }

  /// Repetir la vuelta sin parar. Si suena, vuelve a empezar.
  void setLoop({required bool loop}) {
    if (loop == state.loop) return;
    state = state.copyWith(loop: loop);
    _restartIfPlaying();
  }

  void _restartIfPlaying() {
    final plan = _listening;
    if (state.playingIndex == null || plan == null) return;
    unawaited(_start(plan));
  }

  /// Usa [choice] para el acorde [index] de la progresión (glosario).
  void chooseFingering(int index, FingeringChoice choice) =>
      state = state.copyWith(chosen: {...state.chosen, index: choice});

  /// Vuelve a la digitación del camino óptimo en el acorde [index].
  void resetFingering(int index) =>
      state = state.copyWith(chosen: {...state.chosen}..remove(index));

  // Las elegidas a mano se descartan al cambiar tonalidad, progresión o modo:
  // los acordes ya no son los mismos.
  void setTonic(int tonic) {
    _stopListening();
    state = state.copyWith(tonic: tonic, chosen: const {});
    if (!state.isCustom) {
      _countGeneration('${state.progressionId}@$tonic');
    } else if (state.custom.length >= 3) {
      _countGeneration('$customProgressionId:${state.custom.join('-')}@$tonic');
    }
  }

  void setBeginner({required bool beginner}) {
    _stopListening();
    state = state.copyWith(beginner: beginner, chosen: const {});
  }

  void setProgression(String id) {
    _stopListening();
    state = state.copyWith(progressionId: id, chosen: const {});
    if (id != customProgressionId) _countGeneration('$id@${state.tonic}');
  }

  /// Añade un grado a "Mi progresión" (máximo [customProgressionMax]).
  void addCustomDegree(String numeral) {
    if (!majorDegreeNumerals.contains(numeral) ||
        state.custom.length >= customProgressionMax) {
      return;
    }
    _setCustom([...state.custom, numeral]);
  }

  void removeCustomDegree(int index) {
    if (index < 0 || index >= state.custom.length) return;
    _setCustom([...state.custom]..removeAt(index));
  }

  void clearCustom() => _setCustom(const []);

  void _setCustom(List<String> custom) {
    _stopListening();
    state = state.copyWith(
      custom: custom,
      progressionId: customProgressionId,
      chosen: const {},
    );
    _saveCustom(custom);
    // Cuenta como progresión generada a partir de 3 acordes.
    if (custom.length >= 3) {
      _countGeneration('$customProgressionId:${custom.join('-')}@${state.tonic}');
    }
  }

  Future<void> _saveCustom(List<String> custom) async {
    await _loaded;
    try {
      await ref
          .read(keyValueStoreProvider)
          .save(StorageBoxes.userProgress, _keyCustom, custom);
    } catch (e, st) {
      debugPrint('ProgressionsViewModel._saveCustom error: $e\n$st');
    }
  }

  /// Cuenta [key] una sola vez. La clave se arma al llamar (no tras el
  /// `await`) para contar lo que el usuario eligió aunque ya haya cambiado.
  Future<void> _countGeneration(String key) async {
    await _loaded;
    if (!_seen.add(key)) return;
    final newCount = state.progressionsGenerated + 1;
    state = state.copyWith(progressionsGenerated: newCount);
    try {
      final storage = ref.read(keyValueStoreProvider);
      await storage.save(StorageBoxes.userProgress, _keyCount, newCount);
      await storage.save(
        StorageBoxes.userProgress,
        _keySeen,
        _seen.toList(growable: false),
      );
      if (newCount >= 5) {
        await ref.read(achievementServiceProvider).unlock('composer');
      }
    } catch (e, st) {
      debugPrint('ProgressionsViewModel._countGeneration error: $e\n$st');
    }
  }
}
