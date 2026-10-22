/// Notas y afinación estándar: la única tabla cromática de la app.
library;

/// Las 12 clases de altura con sostenidos; el índice es la clase (C = 0).
const noteNames = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', //
];

/// MIDI de las cuerdas al aire en afinación estándar; índice 0 = 1ª cuerda
/// (mi aguda), como en todo `lib/domain/`.
const standardOpenStringMidi = [64, 59, 55, 50, 45, 40];

/// Clase de altura (0–11) de [note], o -1 si no es una nota con sostenido.
int noteIndex(String note) => noteNames.indexOf(note);

/// Nombre de la nota que está [semitones] por encima de C; acepta cualquier
/// entero (MIDI, sumas de intervalos, negativos) y lo reduce módulo 12.
String pitchClassName(int semitones) => noteNames[semitones % 12];
