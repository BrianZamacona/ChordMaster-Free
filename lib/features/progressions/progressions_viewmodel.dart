import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/progressions/progression_builder.dart';
import '../../domain/progressions/progression_data.dart';
import '../../domain/theory/double_stops.dart' show noteNames;
import '../../domain/voicing/voice_leading.dart';
import '../../services/achievement_service.dart';
import '../../services/storage_service.dart';

/// Immutable state for [ProgressionsViewModel].
class ProgressionsState {
  const ProgressionsState({
    this.tonic = 0,
    this.progressionId = 'v1-2',
    this.progressionsGenerated = 0,
    this.beginner = false,
  });

  /// Pitch class de la tónica (C = 0).
  final int tonic;
  final String progressionId;
  final int progressionsGenerated;

  /// Modo principiante: penaliza las cejillas al elegir digitaciones.
  final bool beginner;

  ProgressionsState copyWith({
    int? tonic,
    String? progressionId,
    int? progressionsGenerated,
    bool? beginner,
  }) => ProgressionsState(
    tonic: tonic ?? this.tonic,
    progressionId: progressionId ?? this.progressionId,
    progressionsGenerated: progressionsGenerated ?? this.progressionsGenerated,
    beginner: beginner ?? this.beginner,
  );
}

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
  });

  final String numeral;
  final ProgressionVoicing voicing;

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
  final root = noteNames[(tonic + degree.semitones) % 12];
  return '${degree.numeral} ($root ${degree.type})';
}

/// Calcula el camino óptimo y las transiciones; sin efectos secundarios.
ProgressionPlan buildProgressionPlan(
  ProgressionBuilder builder,
  Progression progression,
  int tonic, {
  bool beginner = false,
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
      problem: 'No hay digitaciones válidas para: ${missing.join(', ')}.',
    );
  }

  final path = findOptimalProgressionPath(layers);
  if (path.isEmpty) {
    return ProgressionPlan(
      progression: progression,
      tonic: tonic,
      problem: 'No se encontró un camino de digitaciones para esta progresión.',
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

/// Carga chords.json una sola vez.
final progressionBuilderProvider = FutureProvider<ProgressionBuilder>((ref) async {
  final raw = await rootBundle.loadString('assets/data/chords.json');
  final chords = jsonDecode(raw) as List<dynamic>;
  return ProgressionBuilder([
    for (final c in chords) ChordFingerings.fromJson(c as Map<String, dynamic>),
  ]);
});

/// Provider for [ProgressionsViewModel].
final progressionsViewModelProvider =
    NotifierProvider<ProgressionsViewModel, ProgressionsState>(
        ProgressionsViewModel.new);

final progressionPlanProvider = Provider<AsyncValue<ProgressionPlan>>((ref) {
  final s = ref.watch(progressionsViewModelProvider);
  final progression = progressions.firstWhere(
    (p) => p.id == s.progressionId,
    orElse: () => progressions.first,
  );
  return ref
      .watch(progressionBuilderProvider)
      .whenData(
        (b) => buildProgressionPlan(
          b,
          progression,
          s.tonic,
          beginner: s.beginner,
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

  @override
  ProgressionsState build() {
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
      final storage = ref.read(storageServiceProvider);
      final count =
          await storage.get<int>(StorageService.userProgressBox, _keyCount) ?? 0;
      final seen = await storage.get<List<dynamic>>(
            StorageService.userProgressBox,
            _keySeen,
          ) ??
          const [];
      _seen.addAll(seen.whereType<String>());
      state = state.copyWith(progressionsGenerated: count);
    } catch (e, st) {
      debugPrint('ProgressionsViewModel._loadCount error: $e\n$st');
    }
  }

  void setTonic(int tonic) {
    state = state.copyWith(tonic: tonic);
    _countGeneration('${state.progressionId}@$tonic');
  }

  void setBeginner({required bool beginner}) =>
      state = state.copyWith(beginner: beginner);

  void setProgression(String id) {
    state = state.copyWith(progressionId: id);
    _countGeneration('$id@${state.tonic}');
  }

  /// Cuenta [key] una sola vez. La clave se arma al llamar (no tras el
  /// `await`) para contar lo que el usuario eligió aunque ya haya cambiado.
  Future<void> _countGeneration(String key) async {
    await _loaded;
    if (!_seen.add(key)) return;
    final newCount = state.progressionsGenerated + 1;
    state = state.copyWith(progressionsGenerated: newCount);
    try {
      final storage = ref.read(storageServiceProvider);
      await storage.save(StorageService.userProgressBox, _keyCount, newCount);
      await storage.save(
        StorageService.userProgressBox,
        _keySeen,
        _seen.toList(growable: false),
      );
      if (newCount >= 5) {
        await AchievementService.instance.unlock('composer');
      }
    } catch (e, st) {
      debugPrint('ProgressionsViewModel._countGeneration error: $e\n$st');
    }
  }
}
