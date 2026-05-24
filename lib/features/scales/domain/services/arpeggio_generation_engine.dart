import '../models/string_configuration.dart';
import '../models/tablature_constraints.dart';
import '../strategies/fingering_strategy.dart';
import 'scale_generation_engine.dart';

/// Traversal mode for arpeggio generation.
enum ArpeggioTraversalMode {
  strictOrder,
  folded,
}

/// Arpeggio engine built as a restricted scale pipeline.
class ArpeggioGenerationEngine {
  const ArpeggioGenerationEngine({required this.scaleEngine});

  final ScaleGenerationEngine scaleEngine;

  List<PositionedNote> generate({
    required String root,
    required List<int> chordIntervals,
    required FingeringStrategy strategy,
    required StringConfiguration tuning,
    required int startingFret,
    required TablatureConstraints constraints,
    ArpeggioTraversalMode mode = ArpeggioTraversalMode.strictOrder,
  }) {
    final notes = scaleEngine.generate(
      root: root,
      intervals: chordIntervals,
      strategy: strategy,
      tuning: tuning,
      startingFret: startingFret,
      constraints: constraints,
    );
    return mode == ArpeggioTraversalMode.strictOrder
        ? _strictOrder(notes, chordIntervals)
        : _folded(notes, chordIntervals);
  }

  List<PositionedNote> _strictOrder(
      List<PositionedNote> notes, List<int> intervals) {
    if (intervals.isEmpty) return notes;
    final order = intervals.map((i) => i % 12).toList(growable: false);
    return List<PositionedNote>.from(notes)
      ..sort((a, b) {
        final ai = order.indexOf(a.semitoneFromRoot % 12);
        final bi = order.indexOf(b.semitoneFromRoot % 12);
        if (ai != bi) return ai.compareTo(bi);
        final s = a.stringNumber.compareTo(b.stringNumber);
        if (s != 0) return s;
        return a.fret.compareTo(b.fret);
      });
  }

  List<PositionedNote> _folded(
      List<PositionedNote> notes, List<int> intervals) {
    if (intervals.isEmpty) return notes;
    final order = intervals.map((i) => i % 12).toSet();
    return notes
        .where((n) => order.contains(n.semitoneFromRoot % 12))
        .toList(growable: false);
  }
}
