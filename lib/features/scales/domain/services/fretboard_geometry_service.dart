import '../../../../core/constants/music_theory.dart';
import '../models/string_configuration.dart';
import '../strategies/fingering_strategy.dart';

/// Strict string/fret coordinate on the instrument fretboard.
class FretboardCoordinate {
  const FretboardCoordinate({
    required this.stringNumber,
    required this.fret,
    required this.note,
    required this.semitoneFromRoot,
    this.isDrone = false,
  });

  final int stringNumber;
  final int fret;
  final String note;
  final int semitoneFromRoot;
  final bool isDrone;

  PositionedNote toPositionedNote() => PositionedNote(
        stringNumber: stringNumber,
        fret: fret,
        semitoneFromRoot: semitoneFromRoot,
      );
}

/// Builds and sorts strict geometric fretboard coordinates from a tuning.
class FretboardGeometryService {
  const FretboardGeometryService();

  /// Returns all scale-note coordinates per string inside the requested window.
  ///
  /// The output map is keyed by string number (1 = lowest) and values are
  /// sorted by ascending fret to keep deterministic geometry.
  Map<int, List<FretboardCoordinate>> buildByString({
    required String root,
    required List<int> intervals,
    required StringConfiguration config,
    required int startingFret,
    required int maxFretSpan,
  }) {
    final rootIndex = chromaticNotes.indexOf(root);
    if (rootIndex == -1) return const {};

    final scaleSemitones = <int>{for (final i in intervals) i % 12};
    final byString = <int, List<FretboardCoordinate>>{};

    for (var s = 1; s <= config.stringCount; s++) {
      if (!config.isStringPlayable(s)) continue;
      final openPitch = config.openNoteForString(s);
      final openIndex = chromaticNotes.indexOf(openPitch);
      if (openIndex == -1) continue;

      final list = <FretboardCoordinate>[];
      for (var fret = startingFret; fret <= startingFret + maxFretSpan; fret++) {
        final noteIndex = (openIndex + fret) % 12;
        final semitone = (noteIndex - rootIndex + 12) % 12;
        if (!scaleSemitones.contains(semitone)) continue;
        list.add(
          FretboardCoordinate(
            stringNumber: s,
            fret: fret,
            note: chromaticNotes[noteIndex],
            semitoneFromRoot: semitone,
            isDrone: config.droneStrings.contains(s),
          ),
        );
      }

      if (list.isNotEmpty) {
        list.sort((a, b) => a.fret.compareTo(b.fret));
        byString[s] = list;
      }
    }

    return byString;
  }

  /// Flattens [buildByString] output into strict geometric order.
  ///
  /// Order: low string → high string, then low fret → high fret.
  List<FretboardCoordinate> flattenGeometric(
      Map<int, List<FretboardCoordinate>> byString) {
    final all = byString.values.expand((e) => e).toList(growable: false);
    all.sort((a, b) {
      final stringCompare = a.stringNumber.compareTo(b.stringNumber);
      if (stringCompare != 0) return stringCompare;
      return a.fret.compareTo(b.fret);
    });
    return all;
  }
}
