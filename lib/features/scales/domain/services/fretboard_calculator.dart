import '../../../../core/constants/music_theory.dart';
import '../models/string_configuration.dart';
import '../strategies/fingering_strategy.dart';

/// Pure-Dart fretboard calculator.
///
/// Given a root note, a list of scale intervals, a [FingeringStrategy], a
/// [StringConfiguration], and a fret window, it returns the selected
/// [PositionedNote]s that form a complete fretboard shape.
///
/// This class is stateless and side-effect free — safe to use as a singleton.
class FretboardCalculator {
  const FretboardCalculator();

  /// Calculates the fretboard shape for the given parameters.
  ///
  /// - [root]         – pitch class of the tonic (e.g. `"C"`).
  /// - [intervals]    – semitone offsets from root (e.g. `[0,2,4,5,7,9,11]`).
  /// - [strategy]     – note-selection strategy to apply.
  /// - [config]       – string configuration (tuning + string count).
  /// - [startingFret] – lowest fret of the search window (inclusive).
  /// - [maxFretSpan]  – number of frets to scan above [startingFret]
  ///                    (window = [startingFret … startingFret + maxFretSpan]).
  ///
  /// Returns an empty list if [root] is not a recognised chromatic pitch class.
  List<PositionedNote> calculate({
    required String root,
    required List<int> intervals,
    required FingeringStrategy strategy,
    required StringConfiguration config,
    required int startingFret,
    required int maxFretSpan,
  }) {
    final rootIndex = chromaticNotes.indexOf(root);
    if (rootIndex == -1) return const [];

    // Build a set of valid scale semitones (mod 12).
    final scaleSemitones = <int>{
      for (final i in intervals) i % 12,
    };

    // Enumerate available scale notes for each string within the window.
    final availableByString = <int, List<PositionedNote>>{};
    for (var s = 1; s <= config.stringCount; s++) {
      final openNote = config.openNoteForString(s);
      final openIndex = chromaticNotes.indexOf(openNote);
      if (openIndex == -1) continue;

      final notesOnString = <PositionedNote>[];
      for (var fret = startingFret; fret <= startingFret + maxFretSpan; fret++) {
        final noteIndex = (openIndex + fret) % 12;
        final semitone = (noteIndex - rootIndex + 12) % 12;
        if (scaleSemitones.contains(semitone)) {
          notesOnString.add(
            PositionedNote(
              stringNumber: s,
              fret: fret,
              semitoneFromRoot: semitone,
            ),
          );
        }
      }
      if (notesOnString.isNotEmpty) {
        availableByString[s] = notesOnString;
      }
    }

    return strategy.select(
      availableByString: availableByString,
      config: config,
      startingFret: startingFret,
      maxFretSpan: maxFretSpan,
    );
  }
}
