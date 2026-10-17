import '../fingering_generator.dart';

/// Selects up to three scale notes per string.
///
/// Chooses the three lowest-fret scale notes in the window for each
/// string, skipping strings that have no notes available. This is the
/// standard 3-notes-per-string (3NPS) approach used in modern guitar
/// pedagogy.
///
/// See `fingering_generator.dart` for the string-numbering convention.
class ThreeNpsGenerator extends FingeringGenerator {
  const ThreeNpsGenerator();

  @override
  String get systemId => 'three_nps';

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
      result.addAll(sorted.take(3));
    }
    return result;
  }
}
