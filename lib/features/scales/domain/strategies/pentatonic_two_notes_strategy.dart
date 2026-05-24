import '../models/string_configuration.dart';
import 'fingering_strategy.dart';

/// Selects up to two scale notes per string.
///
/// The classic 2-notes-per-string pentatonic box shape.  Works best with
/// 5-note scales (pentatonic major/minor) but applies to any scale type.
class PentatonicTwoNotesStrategy extends FingeringStrategy {
  const PentatonicTwoNotesStrategy();

  static const strategyName = 'Pentatonic Box (2NPS)';

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
      final sorted = List<PositionedNote>.from(notes)
        ..sort((a, b) => a.fret.compareTo(b.fret));
      result.addAll(sorted.take(2));
    }
    return result;
  }
}
