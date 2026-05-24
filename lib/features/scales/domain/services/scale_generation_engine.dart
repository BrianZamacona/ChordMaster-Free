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
    var filtered = notes.where((n) {
      if (!c.includeOpenStrings && n.fret == 0) return false;
      return n.fret >= c.minFret && n.fret <= c.maxFret;
    }).toList(growable: false);

    if (c.allowedStringSets.isNotEmpty) {
      filtered = filtered.where((n) {
        for (final set in c.allowedStringSets) {
          if (set.contains(n.stringNumber)) return true;
        }
        return false;
      }).toList(growable: false);
    }

    filtered = _enforceNotesPerString(
      filtered,
      minNotesPerString: c.minNotesPerString,
      maxNotesPerString: c.maxNotesPerString,
    );
    filtered = _applySemitoneMotionConstraints(
      filtered,
      maxSemitoneJump: c.maxSemitoneJump,
      allowOctaveWrap: c.allowOctaveWrap,
    );

    return _enforceNotesPerString(
      filtered,
      minNotesPerString: c.minNotesPerString,
      maxNotesPerString: c.maxNotesPerString,
    );
  }

  List<PositionedNote> _enforceNotesPerString(
    List<PositionedNote> notes, {
    required int minNotesPerString,
    required int maxNotesPerString,
  }) {
    if (notes.isEmpty) return const [];
    final byString = <int, List<PositionedNote>>{};
    for (final note in notes) {
      byString.putIfAbsent(note.stringNumber, () => []).add(note);
    }

    final constrained = <PositionedNote>[];
    final sortedStrings = byString.keys.toList()..sort();
    for (final stringNumber in sortedStrings) {
      final stringNotes = byString[stringNumber]!;
      stringNotes.sort((a, b) => a.fret.compareTo(b.fret));

      var effective = stringNotes;
      if (maxNotesPerString > 0 && effective.length > maxNotesPerString) {
        effective = effective.take(maxNotesPerString).toList(growable: false);
      }
      if (minNotesPerString > 0 && effective.length < minNotesPerString) {
        continue;
      }
      constrained.addAll(effective);
    }

    constrained.sort((a, b) {
      final stringCompare = a.stringNumber.compareTo(b.stringNumber);
      if (stringCompare != 0) return stringCompare;
      return a.fret.compareTo(b.fret);
    });
    return constrained;
  }

  List<PositionedNote> _applySemitoneMotionConstraints(
    List<PositionedNote> notes, {
    required int maxSemitoneJump,
    required bool allowOctaveWrap,
  }) {
    if (notes.length < 2 || maxSemitoneJump < 0) return notes;
    final sorted = List<PositionedNote>.from(notes)
      ..sort((a, b) {
        final stringCompare = a.stringNumber.compareTo(b.stringNumber);
        if (stringCompare != 0) return stringCompare;
        return a.fret.compareTo(b.fret);
      });

    final constrained = <PositionedNote>[sorted.first];
    for (final current in sorted.skip(1)) {
      final previous = constrained.last;
      final prev = previous.semitoneFromRoot % 12;
      final curr = current.semitoneFromRoot % 12;

      if (!allowOctaveWrap && curr < prev) continue;

      var jump = (curr - prev).abs();
      if (allowOctaveWrap) {
        jump = jump > 6 ? 12 - jump : jump;
      }
      if (jump > maxSemitoneJump) continue;
      constrained.add(current);
    }
    return constrained;
  }
}
