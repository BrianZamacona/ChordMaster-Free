import '../models/string_configuration.dart';
import 'fingering_strategy.dart';

/// Selects up to three scale notes per string.
///
/// Chooses the three lowest-fret scale notes in the window for each string,
/// skipping strings that have no notes available.  This is the standard
/// 3-notes-per-string (3NPS) approach used in modern guitar pedagogy.
class ThreeNotesPerStringStrategy extends FingeringStrategy {
  const ThreeNotesPerStringStrategy();

  static const strategyName = '3NPS';

  @override
  String get name => strategyName;

  @override
  List<PositionedNote> select({
    required Map<int, List<PositionedNote>> availableByString,
    required StringConfiguration config,
    required int startingFret,
    required int maxFretSpan,
  }) {
    final result = <PositionedNote>[];
    for (var s = config.stringCount; s >= 1; s--) {
      final notes = availableByString[s];
      if (notes == null || notes.isEmpty) continue;
      // Sort ascending by fret, take at most 3.
      final sorted = List<PositionedNote>.from(notes)
        ..sort((a, b) => a.fret.compareTo(b.fret));
      result.addAll(sorted.take(3));
    }
    return result;
  }
}
