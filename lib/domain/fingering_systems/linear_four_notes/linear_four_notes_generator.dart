import '../fingering_generator.dart';

/// Selects up to four scale notes per string in strict ascending fret
/// order.
///
/// Produces a pure horizontal shape that sweeps linearly across the
/// fretboard without skipping strings. Useful for legato runs and
/// wide-stretch patterns.
///
/// Migrated from the orphaned
/// `lib/features/scales/domain/strategies/linear_four_notes_strategy.dart`.
/// See `fingering_generator.dart` for the string-numbering convention
/// this migration corrects.
class LinearFourNotesGenerator extends FingeringGenerator {
  const LinearFourNotesGenerator();

  @override
  String get systemId => 'linear_four_notes';

  @override
  List<GeneratedNote> select({
    required Map<int, List<GeneratedNote>> availableByString,
    required int stringCount,
    required int startingFret,
    required int maxFretSpan,
  }) {
    final result = <GeneratedNote>[];
    for (var s = stringCount; s >= 1; s--) {
      final notes = availableByString[s];
      if (notes == null || notes.isEmpty) continue;
      final sorted = List<GeneratedNote>.from(notes)
        ..sort((a, b) => a.fret.compareTo(b.fret));
      result.addAll(sorted.take(4));
    }
    return result;
  }
}
