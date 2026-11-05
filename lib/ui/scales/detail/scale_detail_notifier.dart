import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/scale_definition.dart';
import '../../../data/repository/scale_repository.dart';
import '../../../domain/theory/notes.dart';
import '../../../services/achievement_service.dart';

class ScaleDetailState {
  const ScaleDetailState({
    required this.scale,
    required this.rootSemitone,
    required this.selectedSystemId,
    required this.visiblePatterns,
    this.selectedPatternIndex,
    this.isLoading = false,
  });

  final ScaleDefinition scale;
  final int rootSemitone;
  final String? selectedSystemId;
  final List<ResolvedPattern> visiblePatterns;

  /// Digitación elegida; `null` = ninguna, es decir, todo el mástil.
  final int? selectedPatternIndex;
  final bool isLoading;

  String get rootName => noteNames[rootSemitone];

  bool get hasSelectedPattern =>
      selectedPatternIndex != null && visiblePatterns.isNotEmpty;

  /// La digitación elegida o, sin elegir, la primera: el diapasón fijo de la
  /// pantalla nunca queda vacío.
  ResolvedPattern? get currentPattern => visiblePatterns.isEmpty
      ? null
      : visiblePatterns[(selectedPatternIndex ?? 0).clamp(
          0,
          visiblePatterns.length - 1,
        )];

  List<String> get scaleNoteNames {
    final rootIdx = rootSemitone;
    return scale.intervals.map((i) => pitchClassName(rootIdx + i)).toList();
  }

  ScaleDetailState copyWith({
    int? rootSemitone,
    String? selectedSystemId,
    List<ResolvedPattern>? visiblePatterns,
    int? selectedPatternIndex,
    bool? isLoading,
    bool clearSystem = false,
    bool clearPattern = false,
  }) =>
      ScaleDetailState(
        scale: scale,
        rootSemitone: rootSemitone ?? this.rootSemitone,
        selectedSystemId: clearSystem ? null : selectedSystemId ?? this.selectedSystemId,
        visiblePatterns: visiblePatterns ?? this.visiblePatterns,
        selectedPatternIndex: clearPattern
            ? null
            : selectedPatternIndex ?? this.selectedPatternIndex,
        isLoading: isLoading ?? this.isLoading,
      );
}

/// Escala y tónica inicial (semitono, C = 0) del detalle.
typedef ScaleDetailArgs = ({ScaleDefinition scale, int root});

class ScaleDetailNotifier extends Notifier<ScaleDetailState> {
  ScaleDetailNotifier(this._arg);

  final ScaleDetailArgs _arg;

  @override
  ScaleDetailState build() {
    final initial = ScaleDetailState(
      scale: _arg.scale,
      rootSemitone: _arg.root % 12,
      selectedSystemId: null,
      visiblePatterns: const [],
    );
    _load(initial);
    // Logro "Explorador de escalas": 10 escalas distintas abiertas.
    ref.read(achievementServiceProvider).recordDistinct(
      key: 'viewed_scale_ids',
      value: _arg.scale.id,
      goal: 10,
      achievementId: 'scale_explorer',
    );
    return initial;
  }

  void changeRoot(int semitone) =>
      _load(state.copyWith(rootSemitone: semitone, clearPattern: true));
  void changeSystem(String? systemId) => _load(systemId == null
      ? state.copyWith(clearSystem: true, clearPattern: true)
      : state.copyWith(selectedSystemId: systemId, clearPattern: true));

  /// Elige una digitación de las visibles; `null` vuelve a todo el mástil.
  void selectPattern(int? index) {
    if (index == null) {
      state = state.copyWith(clearPattern: true);
    } else if (index >= 0 && index < state.visiblePatterns.length) {
      state = state.copyWith(selectedPatternIndex: index);
    }
  }

  Future<void> _load(ScaleDetailState pending) async {
    state = pending.copyWith(isLoading: true);
    final patterns = await ref.read(scaleRepositoryProvider).getPositions(
          scaleId: pending.scale.id,
          rootSemitone: pending.rootSemitone,
          systemFilter: pending.selectedSystemId,
        );
    state = pending.copyWith(
      visiblePatterns: patterns,
      isLoading: false,
    );
  }
}

final scaleDetailProvider = NotifierProvider.autoDispose
    .family<ScaleDetailNotifier, ScaleDetailState, ScaleDetailArgs>(
  ScaleDetailNotifier.new,
);
