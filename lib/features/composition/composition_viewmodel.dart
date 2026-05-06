import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/achievement_service.dart';
import '../../services/storage_service.dart';

// ── State ────────────────────────────────────────────────────────────────────

/// Immutable state for [CompositionViewModel].
class CompositionState {
  const CompositionState({
    this.chords = const [],
    this.savedCount = 0,
  });

  /// Chords in the current composition, in order.
  final List<String> chords;

  /// How many compositions have been saved (for potential future achievements).
  final int savedCount;

  CompositionState copyWith({
    List<String>? chords,
    int? savedCount,
  }) =>
      CompositionState(
        chords: chords ?? this.chords,
        savedCount: savedCount ?? this.savedCount,
      );

  /// The composition as a readable text string.
  String get asText => chords.join(' → ');
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// Provider for [CompositionViewModel].
final compositionViewModelProvider =
    NotifierProvider<CompositionViewModel, CompositionState>(
        CompositionViewModel.new);

// ── Chord palette ────────────────────────────────────────────────────────────

/// Common chords available in the chord palette.
const List<String> compositionChordPalette = [
  'C', 'Cm', 'C7', 'Cmaj7',
  'D', 'Dm', 'D7', 'Dmaj7',
  'E', 'Em', 'E7',
  'F', 'Fm', 'F7', 'Fmaj7',
  'G', 'Gm', 'G7', 'Gmaj7',
  'A', 'Am', 'A7', 'Amaj7',
  'B', 'Bm', 'B7',
  'C#m', 'F#m', 'G#m',
  'Bb', 'Bbm', 'Eb', 'Ab',
];

// ── ViewModel ─────────────────────────────────────────────────────────────────

/// Manages composition state: chord list, reorder, undo.
class CompositionViewModel extends Notifier<CompositionState> {
  static const _keySavedCount = 'composition_saved_count';

  @override
  CompositionState build() {
    _loadCount();
    return const CompositionState();
  }

  Future<void> _loadCount() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final count =
          await storage.get<int>(StorageService.userProgressBox, _keySavedCount) ?? 0;
      state = state.copyWith(savedCount: count);
    } catch (e, st) {
      debugPrint('CompositionViewModel._loadCount error: $e\n$st');
    }
  }

  /// Adds a chord to the end of the composition.
  void addChord(String chord) {
    state = state.copyWith(chords: [...state.chords, chord]);
  }

  /// Removes the chord at [index].
  void removeChord(int index) {
    if (index < 0 || index >= state.chords.length) return;
    final updated = List<String>.from(state.chords)..removeAt(index);
    state = state.copyWith(chords: updated);
  }

  /// Clears all chords.
  void clearChords() => state = state.copyWith(chords: []);

  /// Reorders a chord from [oldIndex] to [newIndex].
  void reorderChords(int oldIndex, int newIndex) {
    final updated = List<String>.from(state.chords);
    if (newIndex > oldIndex) newIndex--;
    final chord = updated.removeAt(oldIndex);
    updated.insert(newIndex, chord);
    state = state.copyWith(chords: updated);
  }

  /// Saves the current composition (increments save count).
  Future<void> saveComposition() async {
    if (state.chords.isEmpty) return;
    final newCount = state.savedCount + 1;
    state = state.copyWith(savedCount: newCount);
    try {
      final storage = ref.read(storageServiceProvider);
      await storage.save(
          StorageService.userProgressBox, _keySavedCount, newCount);
      await AchievementService.instance.unlock('composer');
    } catch (e, st) {
      debugPrint('CompositionViewModel.saveComposition error: $e\n$st');
    }
  }
}
