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

/// Notas por renglón: la pantalla dibuja la tablatura de a tantas notas (a 360
/// dp caben sin apretarse) y cada renglón se puede practicar suelto.
const tabNotesPerLine = 8;

/// Cuántos renglones ocupan [count] notas.
int tabLineCount(int count) => (count + tabNotesPerLine - 1) ~/ tabNotesPerLine;

/// Renglón (desde 0) de la nota [index].
int tabLineOf(int index) => index ~/ tabNotesPerLine;

/// Notas del renglón [line]: de [start] a [end] (sin incluirlo).
({int start, int end}) tabLineRange(int count, int line) {
  final start = line * tabNotesPerLine;
  final end = start + tabNotesPerLine;
  return (start: start, end: end < count ? end : count);
}

/// Trastes que cubre la mano quieta: un dedo por traste.
const handSpanFrets = 4;

/// El dedo de la mano izquierda de cada nota (1 índice … 4 meñique; `null` =
/// cuerda al aire), por la regla de un dedo por traste: si todo lo pisado cabe
/// en los trastes 1 a 4, el dedo es el traste (primera posición); si no, el
/// índice va en el traste más bajo. `null` si lo pisado no cabe en
/// [handSpanFrets] trastes (la mano se mueve y la regla no alcanza).
List<int?>? tabFingers(List<TabNote> notes) {
  final fretted = [for (final n in notes) if (n.fret > 0) n.fret];
  if (fretted.isEmpty) return [for (final _ in notes) null];
  final low = fretted.reduce((a, b) => a < b ? a : b);
  final high = fretted.reduce((a, b) => a > b ? a : b);
  final start = high <= handSpanFrets ? 1 : low;
  if (high - start >= handSpanFrets) return null;
  return [
    for (final n in notes)
      if (n.fret == 0) null else n.fret - start + 1,
  ];
}

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
