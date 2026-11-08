import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/scale_definition.dart';
import '../../../data/repository/scale_repository.dart';
import '../../../domain/fingering_systems/fingering_systems_registry.dart';
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

  /// Posición predeterminada entre las visibles: la primera declarada del
  /// primer sistema de [FingeringSystemsRegistry.previewOrder], p. ej. la
  /// Posición 1 de 3NPS en C mayor.
  int get defaultPatternIndex {
    int rank(ResolvedPattern p) {
      final i = FingeringSystemsRegistry.previewOrder.indexOf(p.systemId);
      return i < 0 ? FingeringSystemsRegistry.previewOrder.length : i;
    }

    var best = 0;
    for (var i = 1; i < visiblePatterns.length; i++) {
      final a = visiblePatterns[i];
      final b = visiblePatterns[best];
      final byRank = rank(a).compareTo(rank(b));
      if (byRank < 0 || (byRank == 0 && a.declaredOrder < b.declaredOrder)) {
        best = i;
      }
    }
    return best;
  }

  /// La digitación elegida o, sin elegir, la predeterminada: el diapasón fijo
  /// de la pantalla nunca queda vacío.
  ResolvedPattern? get currentPattern => visiblePatterns.isEmpty
      ? null
      : visiblePatterns[(selectedPatternIndex ?? defaultPatternIndex).clamp(
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

/// Escala, tónica inicial (semitono, C = 0) y, si se pide, la digitación con
/// la que abre (id de `scales_master.json`, p. ej. `caged_a` desde una guía).
typedef ScaleDetailArgs = ({ScaleDefinition scale, int root, String? position});

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
    final loaded = _load(initial);
    if (_arg.position case final id?) loaded.then((_) => _openPosition(id));
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

  /// Abre en la digitación [positionId]: elige su sistema y la marca.
  Future<void> _openPosition(String positionId) async {
    if (!ref.mounted) return;
    final pattern = state.visiblePatterns.where((p) => p.positionId == positionId).firstOrNull;
    if (pattern == null) return;
    await _load(state.copyWith(selectedSystemId: pattern.systemId, clearPattern: true));
    if (!ref.mounted) return;
    selectPattern(state.visiblePatterns.indexWhere((p) => p.positionId == positionId));
  }

  Future<void> _load(ScaleDetailState pending) async {
    state = pending.copyWith(isLoading: true);
    final patterns = await ref.read(scaleRepositoryProvider).getPositions(
          scaleId: pending.scale.id,
          rootSemitone: pending.rootSemitone,
          systemFilter: pending.selectedSystemId,
        );
    if (!ref.mounted) return;
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
