import '../fingering_generator.dart';

/// Selects up to four scale notes per string.
///
/// Based on the Berklee guitar method which uses 4-note-per-string
/// patterns for diatonic scales, producing a wide horizontal shape
/// ideal for high-speed picking technique.
///
/// Migrated from the orphaned
/// `lib/features/scales/domain/strategies/berklee_strategy.dart`.
/// See `fingering_generator.dart` for the string-numbering convention
/// this migration corrects.
class BerkleeGenerator extends FingeringGenerator {
  const BerkleeGenerator();

  @override
  String get systemId => 'berklee';

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
