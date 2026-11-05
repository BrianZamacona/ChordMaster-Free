/// Las notas de una escala en todo el mástil, deducidas de la afinación.
library;

import '../../data/models/note_coordinate.dart';
import 'intervals.dart';
import 'notes.dart';

/// Una posición en todas las octavas donde cabe completa: 12 trastes arriba o
/// abajo las notas son las mismas. Nunca recorta: si una copia se saldría de la
/// cuerda al aire o de [maxFret], no se incluye.
List<NoteCoordinate> patternAcrossNeck(
  List<NoteCoordinate> coordinates, {
  int maxFret = 24,
}) {
  if (coordinates.isEmpty) return const [];
  final frets = coordinates.map((c) => c.fret);
  final lowest = frets.reduce((a, b) => a < b ? a : b);
  final highest = frets.reduce((a, b) => a > b ? a : b);
  return [
    for (var shift = -maxFret; shift <= maxFret; shift += 12)
      if (lowest + shift >= 0 && highest + shift <= maxFret)
        for (final c in coordinates)
          NoteCoordinate(
            string: c.string,
            fret: c.fret + shift,
            isRoot: c.isRoot,
            note: c.note,
            interval: c.interval,
            finger: c.finger,
          ),
  ];
}

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
