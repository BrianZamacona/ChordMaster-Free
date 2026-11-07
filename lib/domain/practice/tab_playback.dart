/// Cómo suena una tablatura: cada nota a su tiempo, a un tempo dado. La
/// pantalla usa los mismos instantes para marcar la nota que suena.
library;

import '../audio/pluck_synth.dart';
import '../lessons/lesson.dart';
import '../theory/notes.dart';

/// Corcheas: dos notas por pulso.
const defaultNotesPerBeat = 2;

/// Cuánto deja sonar cada nota: la siguiente la apaga, como al tocar.
const tabNoteRingSeconds = 1.2;

/// MIDI de una nota de tablatura (cuerda 1 = mi aguda).
int tabMidi(TabNote note) => standardOpenStringMidi[note.string - 1] + note.fret;

/// Segundos entre una nota y la siguiente.
double tabStepSeconds(int bpm, {int notesPerBeat = defaultNotesPerBeat}) =>
    60 / bpm / notesPerBeat;

/// Los eventos que suenan, uno por nota, separados por [tabStepSeconds].
List<NoteEvent> tabEvents(
  List<TabNote> notes, {
  required int bpm,
  int notesPerBeat = defaultNotesPerBeat,
}) {
  final step = tabStepSeconds(bpm, notesPerBeat: notesPerBeat);
  return [
    for (final (i, n) in notes.indexed) (midi: tabMidi(n), at: i * step),
  ];
}

/// Duración total del audio: hasta que deja de sonar la última nota.
double tabDurationSeconds(
  int count, {
  required int bpm,
  int notesPerBeat = defaultNotesPerBeat,
}) =>
    count == 0
        ? 0
        : (count - 1) * tabStepSeconds(bpm, notesPerBeat: notesPerBeat) +
            tabNoteRingSeconds;

/// Qué nota suena a los [elapsed] segundos; `null` antes de empezar y al
/// terminar la última.
int? tabIndexAt(
  double elapsed,
  int count, {
  required int bpm,
  int notesPerBeat = defaultNotesPerBeat,
}) {
  if (elapsed < 0 || count == 0) return null;
  final index = (elapsed / tabStepSeconds(bpm, notesPerBeat: notesPerBeat))
      .floor();
  return index < count ? index : null;
}

/// Clave corta y estable para el archivo de audio de una frase (FNV-1a de 32
/// bits): la misma frase da siempre el mismo nombre.
String stableKey(String text) {
  var hash = 0x811c9dc5;
  for (final unit in text.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
