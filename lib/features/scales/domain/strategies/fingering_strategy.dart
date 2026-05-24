import '../models/string_configuration.dart';

/// A single note selected by a [FingeringStrategy] on the fretboard.
class PositionedNote {
  const PositionedNote({
    required this.stringNumber,
    required this.fret,
    required this.semitoneFromRoot,
  });

  /// Guitar string number (1 = highest string, n = lowest string).
  final int stringNumber;

  /// Absolute fret number (0 = open string).
  final int fret;

  /// Semitone distance from the tonic (0 = root, 2 = major 2nd, etc.).
  final int semitoneFromRoot;
}

/// Defines how notes are selected on each string to form a scale shape.
///
/// Implement this interface for each fingering system (3NPS, CAGED, etc.).
abstract class FingeringStrategy {
  const FingeringStrategy();

  /// Human-readable label used as [ScalePattern.patternType].
  String get name;

  /// Selects the notes that form a complete fretboard shape.
  ///
  /// [availableByString] maps string number (1 = highest) to the list of
  /// all scale [PositionedNote]s that fall within the requested fret window on
  /// that string.  The strategy may trim, reorder, or extend the selection.
  List<PositionedNote> select({
    required Map<int, List<PositionedNote>> availableByString,
    required StringConfiguration config,
    required int startingFret,
    required int maxFretSpan,
  });
}
