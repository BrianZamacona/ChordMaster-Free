import '../fingering_generator.dart';

/// Selects pentatonic-style notes per string.
///
/// The classic 2-notes-per-string pentatonic box shape. Works best with
/// 5-note scales (pentatonic major/minor). For blues scales, it allows a
/// 3-note cluster (4-b5-5) when the blue note is between the other two
/// notes on the same string.
///
/// Migrated from the orphaned
/// `lib/features/scales/domain/strategies/pentatonic_two_notes_strategy.dart`.
/// See `fingering_generator.dart` for the string-numbering convention
/// this migration corrects.
class PentatonicTwoNotesGenerator extends FingeringGenerator {
  const PentatonicTwoNotesGenerator();

  @override
  String get systemId => 'pentatonic_two_notes';

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
      final bluesCluster = _findBluesCluster(sorted);
      if (bluesCluster != null) {
        result.addAll(bluesCluster);
        continue;
      }
      result.addAll(sorted.take(2));
    }
    return result;
  }

  List<GeneratedNote>? _findBluesCluster(List<GeneratedNote> sorted) {
    GeneratedNote? fourth;
    GeneratedNote? flatFifth;
    GeneratedNote? fifth;

    for (final note in sorted) {
      switch (note.semitoneFromRoot) {
        case 5:
          fourth ??= note;
          break;
        case 6:
          flatFifth ??= note;
          break;
        case 7:
          fifth ??= note;
          break;
        default:
          break;
      }
    }

    if (fourth == null || flatFifth == null || fifth == null) return null;

    final frets = [fourth.fret, flatFifth.fret, fifth.fret]..sort();
    if (frets[2] - frets[0] > 2) return null;
    if (frets[1] - frets[0] != 1 || frets[2] - frets[1] != 1) return null;

    final cluster = [fourth, flatFifth, fifth]
      ..sort((a, b) => a.fret.compareTo(b.fret));
    return cluster;
  }
}
