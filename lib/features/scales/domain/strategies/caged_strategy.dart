import '../models/string_configuration.dart';
import 'fingering_strategy.dart';

/// Selects 2–3 scale notes per string within a tight 4-fret box.
///
/// Mirrors the CAGED-system approach: a closed position shape where each
/// string contributes 2 or 3 notes confined to a ≤ 4-fret span.  Notes
/// outside the [_cagedSpan] window relative to [startingFret] are excluded.
class CagedStrategy extends FingeringStrategy {
  const CagedStrategy();

  static const strategyName = 'CAGED';
  static const _cagedSpan = 4;

  @override
  String get name => strategyName;

  @override
  List<PositionedNote> select({
    required Map<int, List<PositionedNote>> availableByString,
    required StringConfiguration config,
    required int startingFret,
    required int maxFretSpan,
  }) {
    final endFret = startingFret + _cagedSpan;
    final result = <PositionedNote>[];
    for (var s = config.stringCount; s >= 1; s--) {
      final notes = availableByString[s];
      if (notes == null || notes.isEmpty) continue;
      // Restrict to the 4-fret box and take up to 3 notes.
      final inBox = notes
          .where((n) => n.fret >= startingFret && n.fret <= endFret)
          .toList()
        ..sort((a, b) => a.fret.compareTo(b.fret));
      if (inBox.isEmpty) continue;
      // CAGED shapes typically use 2 notes on outer strings, 3 on inner.
      final take = inBox.length >= 3 ? 3 : inBox.length;
      result.addAll(inBox.take(take));
    }
    return result;
  }
}
