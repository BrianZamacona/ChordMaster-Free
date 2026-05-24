import '../models/string_configuration.dart';
import '../models/tablature_constraints.dart';
import '../strategies/fingering_strategy.dart';
import 'scale_generation_engine.dart';

/// Voicing options for chord generation.
class ChordVoicingOptions {
  const ChordVoicingOptions({
    this.omitRoot = false,
    this.inversion = 0,
    this.drop2 = false,
    this.drop3 = false,
  });

  final bool omitRoot;
  final int inversion;
  final bool drop2;
  final bool drop3;
}

/// Chord/voicing engine with omission and inversion filters.
class ChordVoicingEngine {
  const ChordVoicingEngine({required this.scaleEngine});

  final ScaleGenerationEngine scaleEngine;

  List<PositionedNote> generate({
    required String root,
    required List<int> chordIntervals,
    required FingeringStrategy strategy,
    required StringConfiguration tuning,
    required int startingFret,
    required TablatureConstraints constraints,
    ChordVoicingOptions options = const ChordVoicingOptions(),
  }) {
    var notes = scaleEngine.generate(
      root: root,
      intervals: chordIntervals,
      strategy: strategy,
      tuning: tuning,
      startingFret: startingFret,
      constraints: constraints,
    );

    if (options.omitRoot) {
      notes = notes.where((n) => n.semitoneFromRoot % 12 != 0).toList();
    }

    if (options.inversion > 0) {
      notes = _rotateByInversion(notes, options.inversion);
    }

    if (options.drop2 || options.drop3) {
      notes = _applyDropVoicing(notes, drop2: options.drop2, drop3: options.drop3);
    }

    return notes;
  }

  List<PositionedNote> _rotateByInversion(
      List<PositionedNote> notes, int inversion) {
    if (notes.isEmpty) return notes;
    final normalized = inversion % notes.length;
    return [
      ...notes.skip(normalized),
      ...notes.take(normalized),
    ];
  }

  List<PositionedNote> _applyDropVoicing(
    List<PositionedNote> notes, {
    required bool drop2,
    required bool drop3,
  }) {
    if (notes.length < 3) return notes;
    final sorted = List<PositionedNote>.from(notes)
      ..sort((a, b) => b.fret.compareTo(a.fret));
    final mutable = List<PositionedNote>.from(sorted);

    if (drop2 && mutable.length >= 2) {
      final second = mutable[1];
      mutable[1] = PositionedNote(
        stringNumber: second.stringNumber,
        fret: (second.fret - 12).clamp(0, second.fret),
        semitoneFromRoot: second.semitoneFromRoot,
      );
    }
    if (drop3 && mutable.length >= 3) {
      final third = mutable[2];
      mutable[2] = PositionedNote(
        stringNumber: third.stringNumber,
        fret: (third.fret - 12).clamp(0, third.fret),
        semitoneFromRoot: third.semitoneFromRoot,
      );
    }

    mutable.sort((a, b) {
      final s = a.stringNumber.compareTo(b.stringNumber);
      if (s != 0) return s;
      return a.fret.compareTo(b.fret);
    });
    return mutable;
  }
}
