/// A single note selected by a [FingeringGenerator] on the fretboard.
class GeneratedNote {
  const GeneratedNote({
    required this.string,
    required this.fret,
    required this.semitoneFromRoot,
  });

  /// Guitar string number using the SAME convention as
  /// `NoteCoordinate.string` in `lib/data/models/note_coordinate.dart`:
  /// 1 = highest-pitched string (high e), 6 = lowest (low E).
  ///
  /// This is the OPPOSITE convention from the old, orphaned
  /// `lib/features/scales/domain/strategies/fingering_strategy.dart`
  /// (which used 1 = lowest string). That mismatch was never caught
  /// because that module was never wired to the current fretboard
  /// renderer. Every generator under `domain/fingering_systems/` must
  /// use the 1 = highest-string convention.
  final int string;

  /// Absolute fret number (0 = open string).
  final int fret;

  /// Semitone distance from the tonic (0 = root, 2 = major 2nd, etc.).
  final int semitoneFromRoot;
}

/// Defines how notes are selected on each string to form a scale shape.
///
/// Implement this interface for each fingering system (CAGED, 3NPS, etc.)
/// under its own subfolder here, and register it in
/// [FingeringSystemsRegistry].
abstract class FingeringGenerator {
  const FingeringGenerator();

  /// Must match the corresponding [FingeringSystemTheory.id].
  String get systemId;

  /// Selects the notes that form a complete fretboard shape.
  ///
  /// [availableByString] maps string number (1 = highest, see [GeneratedNote])
  /// to the list of all scale notes that fall within the requested fret
  /// window on that string. The generator may trim, reorder, or extend
  /// the selection.
  List<GeneratedNote> select({
    required Map<int, List<GeneratedNote>> availableByString,
    required int stringCount,
    required int startingFret,
    required int maxFretSpan,
  });
}
