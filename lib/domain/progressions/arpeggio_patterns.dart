/// Acompañamiento arpegiado de Progresiones (decisión del usuario tras revisar
/// Pocket Composer): en lugar de rasguear, el acorde se toca nota por nota, una
/// por corchea. Cada patrón es un compás de 4/4, una letra por corchea: `B` el
/// bajo (la cuerda más grave que suena), `b` el otro bajo (la siguiente), `3`
/// `2` `1` esas cuerdas agudas; si una no suena en la digitación, esa corchea
/// queda en silencio. Las notas se dejan sonar hasta que cambia el acorde.
library;

import '../audio/pluck_synth.dart';
import '../open_chords/chord_shape.dart';

/// Los tres patrones: bajo y subir (6-3-2-1), bajo, subir y bajar
/// (6-3-2-1-2-3) y bajos alternados (6-3-2-3, 5-3-2-3).
const arpeggioPatterns = [
  'B321B321',
  'B3212323',
  'B323b323',
];

/// La cuerda (1 = mi aguda) y el MIDI de la letra [token] sobre [shape];
/// `null` si esa cuerda no suena.
({int string, int midi})? arpeggioNote(ChordShape shape, String token) {
  final sounding = shape.sounding; // de grave a aguda
  final string = switch (token) {
    'B' => sounding.isEmpty ? null : sounding.first,
    'b' => sounding.length < 2 ? null : sounding[1],
    '3' || '2' || '1' => int.parse(token),
    _ => null,
  };
  if (string == null || !sounding.contains(string)) return null;
  return (string: string, midi: shape.midi[sounding.indexOf(string)]);
}

/// Las notas de [shapes] con el patrón [pattern] (de [arpeggioPatterns]); cada
/// forma dura [beats] pulsos (sin darlos, un compás de 4). El patrón sigue la
/// rejilla del compás, no la del acorde, como el rasgueo. Cada nota suena
/// hasta que cambia el acorde o se vuelve a pulsar su cuerda.
List<StringSound> arpeggioEvents(
  List<ChordShape> shapes, {
  required int bpm,
  required String pattern,
  List<int>? beats,
}) {
  final eighth = 30 / bpm;
  final out = <StringSound>[];
  var k = 0;
  for (final (i, shape) in shapes.indexed) {
    final eighths = (beats?[i] ?? 4) * 2;
    final end = (k + eighths) * eighth;
    final lastOn = <int, int>{}; // cuerda -> índice en [out] de su última nota
    for (var e = 0; e < eighths; e++, k++) {
      final note = arpeggioNote(shape, pattern[k % pattern.length]);
      if (note == null) continue;
      final at = k * eighth;
      // Volver a pulsar la cuerda apaga la nota que sonaba en ella.
      if (lastOn[note.string] case final j?) {
        out[j] = StringSound(midi: out[j].midi, at: out[j].at, seconds: at - out[j].at);
      }
      lastOn[note.string] = out.length;
      out.add(StringSound(midi: note.midi, at: at, seconds: end - at));
    }
  }
  return out;
}
