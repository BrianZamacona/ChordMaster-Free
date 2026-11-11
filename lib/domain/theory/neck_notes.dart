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

/// Lo que la forma [selected] comparte con la siguiente de [patterns] subiendo
/// por el mástil (por su primer traste; la última sigue en la primera, una
/// octava arriba): por dónde se pasa de una forma a la otra. Las dos en todas
/// sus octavas ([patternAcrossNeck]). Vacío si [selected] no está en la lista
/// o es la única.
Set<NoteCoordinate> sharedWithNext(
  List<List<NoteCoordinate>> patterns,
  List<NoteCoordinate> selected, {
  int maxFret = 24,
}) {
  int lowest(List<NoteCoordinate> p) => p.map((c) => c.fret).reduce((a, b) => a < b ? a : b);
  final ordered = [...patterns.where((p) => p.isNotEmpty)]..sort((a, b) => lowest(a).compareTo(lowest(b)));
  final index = ordered.indexWhere((p) => p.toSet().containsAll(selected) && selected.toSet().containsAll(p));
  if (index < 0 || ordered.length < 2) return const {};
  final next = ordered[(index + 1) % ordered.length];
  return patternAcrossNeck(selected, maxFret: maxFret).toSet().intersection(
    patternAcrossNeck(next, maxFret: maxFret).toSet(),
  );
}
