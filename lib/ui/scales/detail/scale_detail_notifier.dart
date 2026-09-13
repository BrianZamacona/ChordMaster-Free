import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/scale_definition.dart';
import '../../../data/repository/scale_repository.dart';

const _noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

class ScaleDetailState {
  const ScaleDetailState({
    required this.scale,
    required this.rootSemitone,
    required this.stringCount,
    required this.startFret,
    required this.endFret,
    required this.selectedSystemId,
    required this.visiblePatterns,
    required this.selectedPatternIndex,
    this.isLoading = false,
  });

  final ScaleDefinition scale;
  final int rootSemitone;
  final int stringCount;
  final int startFret;
  final int endFret;
  final String? selectedSystemId;
  final List<ResolvedPattern> visiblePatterns;
  final int selectedPatternIndex;
  final bool isLoading;

  String get rootName => _noteNames[rootSemitone];
  int get viewSpan => endFret - startFret;
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
    int? stringCount,
    int? startFret,
    int? endFret,
    String? selectedSystemId,
    List<ResolvedPattern>? visiblePatterns,
    int? selectedPatternIndex,
    bool? isLoading,
    bool clearSystem = false,
  }) =>
      ScaleDetailState(
        scale: scale,
        rootSemitone: rootSemitone ?? this.rootSemitone,
        stringCount: stringCount ?? this.stringCount,
        startFret: startFret ?? this.startFret,
        endFret: endFret ?? this.endFret,
        selectedSystemId: clearSystem ? null : selectedSystemId ?? this.selectedSystemId,
        visiblePatterns: visiblePatterns ?? this.visiblePatterns,
        selectedPatternIndex: selectedPatternIndex ?? this.selectedPatternIndex,
        isLoading: isLoading ?? this.isLoading,
      );
}

class ScaleDetailNotifier extends AutoDisposeFamilyNotifier<ScaleDetailState, ScaleDefinition> {
  @override
  ScaleDetailState build(ScaleDefinition arg) {
    final initial = ScaleDetailState(
      scale: arg,
      rootSemitone: 0,
      stringCount: 6,
      startFret: 0,
      endFret: 12,
      selectedSystemId: null,
      visiblePatterns: const [],
      selectedPatternIndex: 0,
    );
    _load(initial);
    return initial;
  }

  void changeRoot(int semitone) =>
      _load(state.copyWith(rootSemitone: semitone, selectedPatternIndex: 0));
  void changeStringCount(int n) =>
      _load(state.copyWith(stringCount: n, selectedPatternIndex: 0));
  void changeSystem(String? systemId) => _load(systemId == null
      ? state.copyWith(clearSystem: true, selectedPatternIndex: 0)
      : state.copyWith(selectedSystemId: systemId, selectedPatternIndex: 0));
  void selectPattern(int index) {
    if (index < state.visiblePatterns.length) {
      state = state.copyWith(selectedPatternIndex: index);
    }
  }

  void changeRange(int start, int end) {
    if (end - start < 4) return;
    _load(state.copyWith(startFret: start, endFret: end, selectedPatternIndex: 0));
  }

  Future<void> _load(ScaleDetailState pending) async {
    state = pending.copyWith(isLoading: true);
    final patterns = await ref.read(scaleRepositoryProvider).getVisiblePatterns(
          scaleId: pending.scale.id,
          rootSemitone: pending.rootSemitone,
          startFret: pending.startFret,
          endFret: pending.endFret,
          stringCount: pending.stringCount,
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
    .family<ScaleDetailNotifier, ScaleDetailState, ScaleDefinition>(
  ScaleDetailNotifier.new,
);
