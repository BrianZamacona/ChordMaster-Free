import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/music_theory.dart';
import '../../models/progression.dart';
import '../../services/achievement_service.dart';
import '../../services/storage_service.dart';

/// Immutable state for [ProgressionsViewModel].
class ProgressionsState {
  const ProgressionsState({
    this.selectedKey = 'C',
    this.isMajor = true,
    this.generatedProgressions = const [],
    this.progressionsGenerated = 0,
  });

  final String selectedKey;
  final bool isMajor;
  final List<Progression> generatedProgressions;
  final int progressionsGenerated;

  ProgressionsState copyWith({
    String? selectedKey,
    bool? isMajor,
    List<Progression>? generatedProgressions,
    int? progressionsGenerated,
  }) => ProgressionsState(
    selectedKey: selectedKey ?? this.selectedKey,
    isMajor: isMajor ?? this.isMajor,
    generatedProgressions: generatedProgressions ?? this.generatedProgressions,
    progressionsGenerated: progressionsGenerated ?? this.progressionsGenerated,
  );
}

/// Provider for [ProgressionsViewModel].
final progressionsViewModelProvider =
    NotifierProvider<ProgressionsViewModel, ProgressionsState>(
        ProgressionsViewModel.new);

/// Common chord progression patterns: (name, style, numerals, semitone offsets from key).
const _progressionTemplates = [
  ('I – IV – V', 'Classic', ['I', 'IV', 'V'], [0, 5, 7]),
  ('I – V – vi – IV', 'Pop', ['I', 'V', 'vi', 'IV'], [0, 7, 9, 5]),
  ('ii – V – I', 'Jazz', ['ii', 'V', 'I'], [2, 7, 0]),
  ('I – vi – IV – V', '50s', ['I', 'vi', 'IV', 'V'], [0, 9, 5, 7]),
  ('I – IV – vi – V', 'Rock', ['I', 'IV', 'vi', 'V'], [0, 5, 9, 7]),
  ('vi – IV – I – V', 'Minor feel', ['vi', 'IV', 'I', 'V'], [9, 5, 0, 7]),
  ('I – iii – IV – V', 'Soul', ['I', 'iii', 'IV', 'V'], [0, 4, 5, 7]),
  ('I – IV – I – V', 'Blues', ['I', 'IV', 'I', 'V'], [0, 5, 0, 7]),
];

/// Manages progressions generation state.
class ProgressionsViewModel extends Notifier<ProgressionsState> {
  static const _keyCount = 'progressions_generated';

  @override
  ProgressionsState build() {
    _loadCount();
    return const ProgressionsState();
  }

  Future<void> _loadCount() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final count =
          await storage.get<int>(StorageService.userProgressBox, _keyCount) ?? 0;
      state = state.copyWith(progressionsGenerated: count);
    } catch (e, st) {
      debugPrint('ProgressionsViewModel._loadCount error: $e\n$st');
    }
  }

  void setKey(String key) => state = state.copyWith(selectedKey: key);
  void setMajor({required bool isMajor}) => state = state.copyWith(isMajor: isMajor);

  /// Generates common progressions for the selected key/mode.
  Future<void> generate() async {
    final key = state.selectedKey;
    final rootIndex = chromaticNotes.indexOf(key);
    if (rootIndex == -1) return;

    final progressions = <Progression>[];
    for (var i = 0; i < _progressionTemplates.length; i++) {
      final t = _progressionTemplates[i];
      final numerals = t.$3;
      final semitoneOffsets = t.$4;

      final chords = List.generate(semitoneOffsets.length, (j) {
        final noteIndex = (rootIndex + semitoneOffsets[j]) % 12;
        final note = chromaticNotes[noteIndex];
        final numeral = numerals[j];
        final isMinor = numeral == numeral.toLowerCase();
        return isMinor ? '${note}m' : note;
      });

      progressions.add(Progression(
        id: '${key}_${state.isMajor ? "maj" : "min"}_$i',
        name: t.$1,
        style: t.$2,
        numerals: List<String>.from(numerals),
        chords: chords,
        key: key,
        isMajor: state.isMajor,
      ));
    }

    final newCount = state.progressionsGenerated + 1;
    state = state.copyWith(
      generatedProgressions: progressions,
      progressionsGenerated: newCount,
    );

    try {
      final storage = ref.read(storageServiceProvider);
      await storage.save(StorageService.userProgressBox, _keyCount, newCount);
      if (newCount >= 5) {
        await AchievementService.instance.unlock('composer');
      }
    } catch (e, st) {
      debugPrint('ProgressionsViewModel.generate error: $e\n$st');
    }
  }
}
