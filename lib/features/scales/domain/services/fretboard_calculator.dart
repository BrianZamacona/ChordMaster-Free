import '../../../../core/constants/music_theory.dart';
import '../models/string_configuration.dart';
import 'fretboard_geometry_service.dart';
import '../strategies/fingering_strategy.dart';

/// Pure-Dart fretboard calculator.
///
/// Given a root note, a list of scale intervals, a [FingeringStrategy], a
/// [StringConfiguration], and a fret window, it returns the selected
/// [PositionedNote]s that form a complete fretboard shape.
///
/// This class is stateless and side-effect free — safe to use as a singleton.
class FretboardCalculator {
  const FretboardCalculator([this._geometry = const FretboardGeometryService()]);

  final FretboardGeometryService _geometry;

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

    final availableCoordinates = _geometry.buildByString(
      root: root,
      intervals: intervals,
      config: config,
      startingFret: startingFret,
      maxFretSpan: maxFretSpan,
    );
    final availableByString = <int, List<PositionedNote>>{
      for (final entry in availableCoordinates.entries)
        entry.key: entry.value.map((c) => c.toPositionedNote()).toList(),
    };

    return strategy.select(
      availableByString: availableByString,
      config: config,
      startingFret: startingFret,
      maxFretSpan: maxFretSpan,
    );
  }
}
