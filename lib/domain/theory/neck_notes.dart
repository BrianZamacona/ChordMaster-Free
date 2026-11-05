/// Las notas de una escala en todo el mástil, deducidas de la afinación.
library;

import '../../data/models/note_coordinate.dart';
import 'intervals.dart';
import 'notes.dart';

/// Todas las notas de la escala [intervals] sobre [rootSemitone] (C = 0), de la
/// cuerda al aire al traste [maxFret], en cada cuerda (1 = mi aguda). Nombres
/// con sostenidos y el intervalo como en las posiciones ([spellInterval]).
List<NoteCoordinate> scaleNotesOnNeck({
  required int rootSemitone,
  required List<int> intervals,
  int maxFret = 24,
}) {
  final inScale = {for (final i in intervals) i % 12};
  return [
    for (var string = 1; string <= 6; string++)
      for (var fret = 0; fret <= maxFret; fret++)
        if (inScale.contains(
          (standardOpenStringMidi[string - 1] + fret - rootSemitone) % 12,
        ))
          NoteCoordinate(
            string: string,
            fret: fret,
            isRoot:
                (standardOpenStringMidi[string - 1] + fret - rootSemitone) %
                    12 ==
                0,
            note: pitchClassName(standardOpenStringMidi[string - 1] + fret),
            interval: spellInterval(
              standardOpenStringMidi[string - 1] + fret - rootSemitone,
              intervals,
            ),
          ),
  ];
}
