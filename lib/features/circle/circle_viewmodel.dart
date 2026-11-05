import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/progressions/progression_data.dart';
import '../../domain/theory/circle_of_fifths.dart';
import '../../services/audio_service.dart';
import '../../services/key_value_store.dart';
import '../progressions/progressions_viewmodel.dart';

/// Estado del módulo Círculo de quintas.
class CircleState {
  const CircleState({
    this.index = 0,
    this.playingStep,
    this.tickEnabled = false,
  });

  /// Posición en la ventana (índice de [circleOrder]).
  final int index;

  /// Acorde de la cadencia que está sonando (`null` = en silencio).
  final int? playingStep;

  /// Si la rueda suena con un tic además de vibrar.
  final bool tickEnabled;

  /// Tónica elegida (clase de altura).
  int get tonic => circleOrder[index];

  CircleState copyWith({
    int? index,
    Object? playingStep = _keep,
    bool? tickEnabled,
  }) => CircleState(
    index: index ?? this.index,
    playingStep: identical(playingStep, _keep)
        ? this.playingStep
        : playingStep as int?,
    tickEnabled: tickEnabled ?? this.tickEnabled,
  );

  static const Object _keep = Object();
}

final circleViewModelProvider = NotifierProvider<CircleViewModel, CircleState>(
  CircleViewModel.new,
);

class CircleViewModel extends Notifier<CircleState> {
  static const keyTick = 'circle_wheel_tick';

  @override
  CircleState build() {
    _load();
    return const CircleState();
  }

  KeyValueStore get _storage => ref.read(keyValueStoreProvider);

  Future<void> _load() async {
    try {
      final tick = await _storage.get<bool>(StorageBoxes.settings, keyTick);
      if (tick != null) state = state.copyWith(tickEnabled: tick);
    } catch (e, st) {
      debugPrint('CircleViewModel._load error: $e\n$st');
    }
  }

  /// Sube en cada escucha o cambio: una cadencia vieja deja de sonar.
  int _listenToken = 0;

  /// La rueda dejó [index] en la ventana.
  void select(int index) {
    if (index == state.index) return;
    _listenToken++;
    state = state.copyWith(index: index, playingStep: null);
  }

  /// Una tonalidad pasó por la ventana.
  void wheelClick() {
    if (state.tickEnabled) ref.read(audioServiceProvider).playMetronomeTick();
  }

  Future<void> toggleTick() async {
    final enabled = !state.tickEnabled;
    state = state.copyWith(tickEnabled: enabled);
    try {
      await _storage.save(StorageBoxes.settings, keyTick, enabled);
    } catch (e, st) {
      debugPrint('CircleViewModel.toggleTick error: $e\n$st');
    }
  }

  /// Rasguea una digitación de chords.json.
  Future<void> playChord(List<int> jsonFrets) {
    _stopCadence();
    return ref.read(audioServiceProvider).playFingering(jsonFrets);
  }

  /// Toca I – IV – V – I de la tonalidad elegida, con el mismo camino de
  /// digitaciones que Progresiones. Llamarla mientras suena la detiene.
  Future<void> listenCadence() async {
    if (state.playingStep != null) {
      _stopCadence();
      return;
    }
    final token = ++_listenToken;
    final builder = await ref.read(progressionBuilderProvider.future);
    if (token != _listenToken) return;
    final plan = buildProgressionPlan(builder, cadenceProgression, state.tonic);
    final audio = ref.read(audioServiceProvider);
    for (final (i, step) in plan.steps.indexed) {
      if (token != _listenToken) return;
      state = state.copyWith(playingStep: i);
      await audio.playFingering(step.voicing.jsonFrets);
      await Future<void>.delayed(
        Duration(
          milliseconds: (ProgressionsViewModel.listenStepSeconds * 1000)
              .round(),
        ),
      );
    }
    if (token == _listenToken) state = state.copyWith(playingStep: null);
  }

  void _stopCadence() {
    _listenToken++;
    if (state.playingStep != null) state = state.copyWith(playingStep: null);
  }
}

/// Texto de la cadencia ("I – IV – V – I").
String get cadenceLabel =>
    [for (final d in cadenceProgression.degrees) d.numeral].join(' – ');

/// Grados de la cadencia, para marcar el que suena.
List<ProgressionDegree> get cadenceDegrees => cadenceProgression.degrees;
