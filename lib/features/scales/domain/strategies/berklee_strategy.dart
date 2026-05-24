import '../models/string_configuration.dart';
import 'fingering_strategy.dart';

/// Selects up to four scale notes per string.
///
/// Based on the Berklee guitar method which uses 4-note-per-string patterns
/// for diatonic scales, producing a wide horizontal shape ideal for high-speed
/// picking technique.
class BerkleeStrategy extends FingeringStrategy {
  const BerkleeStrategy();

  static const strategyName = 'Berklee (4NPS)';

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
      result.addAll(sorted.take(4));
    }
    return result;
  }
}
