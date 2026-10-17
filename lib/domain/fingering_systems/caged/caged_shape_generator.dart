import '../fingering_generator.dart';

/// Selects 2-3 scale notes per string within a tight 4-fret box.
///
/// Mirrors the CAGED-system approach: a closed position shape where each
/// string contributes 2 or 3 notes confined to a <= 4-fret span. Notes
/// outside the [_cagedSpan] window relative to [startingFret] are
/// excluded.
///
/// The loop below uses the 1 = highest-string convention (see
/// [GeneratedNote]) and iterates low to high pitch (string count down to 1).
class CagedShapeGenerator extends FingeringGenerator {
  const CagedShapeGenerator();

  static const _cagedSpan = 4;

  @override
  String get systemId => 'caged';

  @override
  List<GeneratedNote> select({
    required Map<int, List<GeneratedNote>> availableByString,
    required int stringCount,
    required int startingFret,
    required int maxFretSpan,
  }) {
    final endFret = startingFret + _cagedSpan;
    final result = <GeneratedNote>[];
    for (var s = stringCount; s >= 1; s--) {
      final notes = availableByString[s];
      if (notes == null || notes.isEmpty) continue;
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
