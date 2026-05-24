import '../../../../core/constants/music_theory.dart';
import '../../domain/strategies/fingering_strategy.dart';
import '../models/note_coordinate.dart';
import '../models/scale_pattern.dart' as data_model;

/// Converts the output of [FretboardCalculator] into the strict-coordinate
/// [data_model.ScalePattern] model expected by [FretboardDiagram].
class GeneratedPatternMapper {
  const GeneratedPatternMapper();

  /// Creates a [data_model.ScalePattern] from a list of [PositionedNote]s.
  ///
  /// - [notes]        – output from [FretboardCalculator.calculate].
  /// - [scaleName]    – display name for the scale/mode (e.g. `"Major"`).
  /// - [root]         – tonic pitch class (e.g. `"C"`).
  /// - [strategyName] – pattern family label (e.g. `"3NPS"`).
  /// - [positionName] – shape identifier (e.g. `"Position I"`).
  ///
  /// Returns `null` when [notes] is empty.
  data_model.ScalePattern? map({
    required List<PositionedNote> notes,
    required String scaleName,
    required String root,
    required String strategyName,
    required String positionName,
  }) {
    if (notes.isEmpty) return null;

    final rootIndex = chromaticNotes.indexOf(root);
    if (rootIndex == -1) return null;

    // Compute fret window from actual notes.
    var minFret = notes.first.fret;
    var maxFret = notes.first.fret;
    for (final n in notes) {
      if (n.fret < minFret) minFret = n.fret;
      if (n.fret > maxFret) maxFret = n.fret;
    }
    // Add 1-fret padding above and below for visual clarity.
    final startingFret = (minFret - 1).clamp(0, 22);
    final fretsSpan = (maxFret - startingFret + 2).clamp(1, 22);

    // Build finger assignment: sort unique frets ascending, map to 1–4.
    final uniqueFrets = notes.map((n) => n.fret).toSet().toList()..sort();
    final fingerMap = <int, int>{};
    for (var i = 0; i < uniqueFrets.length; i++) {
      fingerMap[uniqueFrets[i]] = (i % 4) + 1;
    }

    final coordinates = notes.map((n) {
      final noteIndex = (chromaticNotes.indexOf(root) + n.semitoneFromRoot) % 12;
      final noteName = chromaticNotes[noteIndex];
      final intervalLabel =
          intervalSymbols[n.semitoneFromRoot] ?? '${n.semitoneFromRoot}';
      return NoteCoordinate(
        string: n.stringNumber,
        fret: n.fret,
        interval: intervalLabel,
        note: noteName,
        isRoot: n.semitoneFromRoot == 0,
        finger: fingerMap[n.fret],
      );
    }).toList(growable: false);

    return data_model.ScalePattern(
      scaleName: scaleName,
      root: root,
      patternType: strategyName,
      positionName: positionName,
      startingFret: startingFret,
      fretsSpan: fretsSpan,
      coordinates: coordinates,
    );
  }
}
