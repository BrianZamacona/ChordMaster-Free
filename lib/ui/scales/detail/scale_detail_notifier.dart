import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/scale_definition.dart';
import '../../../data/repository/scale_repository.dart';
import '../../../services/achievement_service.dart';
import '../../../services/storage_service.dart';

const _noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

class ScaleDetailState {
  const ScaleDetailState({
    required this.scale,
    required this.rootSemitone,
    required this.selectedSystemId,
    required this.visiblePatterns,
    required this.selectedPatternIndex,
    this.isLoading = false,
  });

  final ScaleDefinition scale;
  final int rootSemitone;
  final String? selectedSystemId;
  final List<ResolvedPattern> visiblePatterns;
  final int selectedPatternIndex;
  final bool isLoading;

  String get rootName => _noteNames[rootSemitone];
  bool get hasPattern => visiblePatterns.isNotEmpty;

  ResolvedPattern? get currentPattern => visiblePatterns.isEmpty
      ? null
      : visiblePatterns[selectedPatternIndex.clamp(0, visiblePatterns.length - 1)];

  List<String> get scaleNoteNames {
    final rootIdx = rootSemitone;
    return scale.intervals.map((i) => _noteNames[(rootIdx + i) % 12]).toList();
  }

  ScaleDetailState copyWith({
    int? rootSemitone,
    String? selectedSystemId,
    List<ResolvedPattern>? visiblePatterns,
    int? selectedPatternIndex,
    bool? isLoading,
    bool clearSystem = false,
  }) =>
      ScaleDetailState(
        scale: scale,
        rootSemitone: rootSemitone ?? this.rootSemitone,
        selectedSystemId: clearSystem ? null : selectedSystemId ?? this.selectedSystemId,
        visiblePatterns: visiblePatterns ?? this.visiblePatterns,
        selectedPatternIndex: selectedPatternIndex ?? this.selectedPatternIndex,
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
      selectedPatternIndex: 0,
    );
    _load(initial);
    // Logro "Explorador de escalas": 10 escalas distintas abiertas.
    AchievementService.instance.recordDistinct(
      storage: ref.read(storageServiceProvider),
      key: 'viewed_scale_ids',
      value: _arg.scale.id,
      goal: 10,
      achievementId: 'scale_explorer',
    );
    return initial;
  }

  void changeRoot(int semitone) =>
      _load(state.copyWith(rootSemitone: semitone, selectedPatternIndex: 0));
  void changeSystem(String? systemId) => _load(systemId == null
      ? state.copyWith(clearSystem: true, selectedPatternIndex: 0)
      : state.copyWith(selectedSystemId: systemId, selectedPatternIndex: 0));
  void selectPattern(int index) {
    if (index < state.visiblePatterns.length) {
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
      selectedPatternIndex: patterns.isEmpty ? 0 : pending.selectedPatternIndex.clamp(0, patterns.length - 1),
    );
  }
}

final scaleDetailProvider = NotifierProvider.autoDispose
    .family<ScaleDetailNotifier, ScaleDetailState, ScaleDetailArgs>(
  ScaleDetailNotifier.new,
);
