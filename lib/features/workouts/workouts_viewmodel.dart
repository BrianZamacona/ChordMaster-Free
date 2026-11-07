import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/scale_definition.dart';
import '../../data/repository/scale_repository.dart';
import '../../domain/lessons/lesson.dart';
import '../../domain/practice/scale_workouts.dart';

/// Escala, tónica, nivel y posición de las rutinas.
class WorkoutsState {
  const WorkoutsState({
    this.scales = const [],
    this.scaleId = 'major',
    this.root = 0,
    this.level = WorkoutLevel.beginner,
    this.positions = const [],
    this.positionIndex = 0,
    this.isLoading = true,
  });

  /// Escalas y modos disponibles.
  final List<ScaleDefinition> scales;
  final String scaleId;
  final int root;
  final WorkoutLevel level;

  /// Posiciones de la escala en su sistema de rutinas, ordenadas por traste.
  final List<ResolvedPattern> positions;
  final int positionIndex;
  final bool isLoading;

  ScaleDefinition? get scale =>
      scales.where((s) => s.id == scaleId).firstOrNull;

  ResolvedPattern? get position => positions.isEmpty
      ? null
      : positions[positionIndex.clamp(0, positions.length - 1)];

  /// La escalera de notas de la posición elegida.
  List<TabNote> get ladder => position == null
      ? const []
      : positionLadder([
          for (final c in position!.coordinates) TabNote(c.string, c.fret),
        ]);

  WorkoutsState copyWith({
    List<ScaleDefinition>? scales,
    String? scaleId,
    int? root,
    WorkoutLevel? level,
    List<ResolvedPattern>? positions,
    int? positionIndex,
    bool? isLoading,
  }) =>
      WorkoutsState(
        scales: scales ?? this.scales,
        scaleId: scaleId ?? this.scaleId,
        root: root ?? this.root,
        level: level ?? this.level,
        positions: positions ?? this.positions,
        positionIndex: positionIndex ?? this.positionIndex,
        isLoading: isLoading ?? this.isLoading,
      );
}

/// Escala y tónica con las que abren las rutinas (p. ej. desde una guía).
typedef WorkoutsArgs = ({String scaleId, int root});

final workoutsViewModelProvider = NotifierProvider.autoDispose
    .family<WorkoutsViewModel, WorkoutsState, WorkoutsArgs>(
  WorkoutsViewModel.new,
);

class WorkoutsViewModel extends Notifier<WorkoutsState> {
  WorkoutsViewModel(this._args);

  final WorkoutsArgs _args;

  @override
  WorkoutsState build() {
    final initial = WorkoutsState(scaleId: _args.scaleId, root: _args.root % 12);
    _load(initial);
    return initial;
  }

  ScaleRepository get _repo => ref.read(scaleRepositoryProvider);

  Future<void> _load(WorkoutsState pending) async {
    state = pending.copyWith(isLoading: true);
    try {
      final scales = pending.scales.isNotEmpty
          ? pending.scales
          : [...await _repo.getAllScales(), ...await _repo.getAllModes()];
      final scale = scales.where((s) => s.id == pending.scaleId).firstOrNull ??
          scales.first;
      final positions = await _repo.getPositions(
        scaleId: scale.id,
        rootSemitone: pending.root,
        systemFilter: workoutSystemFor(scale.intervals, scale.id),
      );
      if (!ref.mounted) return;
      state = pending.copyWith(
        scales: scales,
        scaleId: scale.id,
        positions: positions,
        positionIndex: pending.positionIndex.clamp(
          0,
          positions.isEmpty ? 0 : positions.length - 1,
        ),
        isLoading: false,
      );
    } catch (e, st) {
      debugPrint('WorkoutsViewModel._load error: $e\n$st');
      if (ref.mounted) state = state.copyWith(isLoading: false);
    }
  }

  void changeScale(String scaleId) =>
      _load(state.copyWith(scaleId: scaleId, positionIndex: 0));

  void changeRoot(int root) =>
      _load(state.copyWith(root: root % 12, positionIndex: 0));

  void changeLevel(WorkoutLevel level) => state = state.copyWith(level: level);

  /// Posición anterior (−1) o siguiente (+1), sin salirse de la lista.
  void stepPosition(int delta) {
    final next = state.positionIndex + delta;
    if (next < 0 || next >= state.positions.length) return;
    state = state.copyWith(positionIndex: next);
  }
}
