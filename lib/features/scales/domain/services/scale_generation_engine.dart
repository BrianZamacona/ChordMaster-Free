import '../models/string_configuration.dart';
import '../models/tablature_constraints.dart';
import '../strategies/fingering_strategy.dart';
import 'fretboard_calculator.dart';

/// Formal scale engine using tuning + tablature constraints.
class ScaleGenerationEngine {
  const ScaleGenerationEngine({required this.calculator});

  final FretboardCalculator calculator;

  List<PositionedNote> generate({
    required String root,
    required List<int> intervals,
    required FingeringStrategy strategy,
    required StringConfiguration tuning,
    required int startingFret,
    required TablatureConstraints constraints,
  }) {
    final notes = calculator.calculate(
      root: root,
      intervals: intervals,
      strategy: strategy,
      config: tuning,
      startingFret: startingFret.clamp(constraints.minFret, constraints.maxFret),
      maxFretSpan: constraints.maxSpanPerString,
    );
    return _applyConstraints(notes, constraints);
  }

  List<PositionedNote> _applyConstraints(
      List<PositionedNote> notes, TablatureConstraints c) {
    final filtered = notes.where((n) {
      if (!c.includeOpenStrings && n.fret == 0) return false;
      return n.fret >= c.minFret && n.fret <= c.maxFret;
    }).toList(growable: false);

    if (c.allowedStringSets.isEmpty) return filtered;
    return filtered.where((n) {
      for (final set in c.allowedStringSets) {
        if (set.contains(n.stringNumber)) return true;
      }
      return false;
    }).toList(growable: false);
  }
}
