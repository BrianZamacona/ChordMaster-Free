import '../models/string_configuration.dart';
import 'fingering_strategy.dart';

/// Selects up to four scale notes per string in strict ascending fret order.
///
/// Produces a pure horizontal shape that sweeps linearly across the fretboard
/// without skipping strings.  Useful for legato runs and wide-stretch patterns.
class LinearFourNotesStrategy extends FingeringStrategy {
  const LinearFourNotesStrategy();

  static const strategyName = 'Linear (4NPS)';

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
      // Strictly ascending, take up to 4.
      final sorted = List<PositionedNote>.from(notes)
        ..sort((a, b) => a.fret.compareTo(b.fret));
      result.addAll(sorted.take(4));
    }
    return result;
  }
}
