/// Cómo suena una tablatura: cada nota a su tiempo, a un tempo dado. La
/// pantalla usa los mismos instantes para marcar la nota que suena.
library;

import 'dart:math' as math;

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
  final fretted = [for (final n in notes) if (!n.isRest && n.fret > 0) n.fret];
  if (fretted.isEmpty) return [for (final _ in notes) null];
  final low = fretted.reduce((a, b) => a < b ? a : b);
  final high = fretted.reduce((a, b) => a > b ? a : b);
  final start = high <= handSpanFrets ? 1 : low;
  if (high - start >= handSpanFrets) return null;
  return [
    for (final n in notes)
      if (n.isRest || n.fret == 0) null else n.fret - start + 1,
  ];
}

/// Segundos de una corchea a [bpm] (sin swing).
double tabStepSeconds(int bpm) => 60 / bpm / defaultNotesPerBeat;

/// Pulsos desde el principio hasta la semicorchea [position], con [swing]:
/// el contratiempo se corre a dos tercios de su pulso (corcheas) o de su
/// corchea (semicorcheas), como en un tresillo. Los pulsos no se mueven.
double tabSwungBeats(int position, TabSwing swing) {
  final fraction = (position % 4) / 4;
  return position ~/ 4 +
      switch (swing) {
        TabSwing.none => fraction,
        TabSwing.eighths => _swing(fraction, 1),
        TabSwing.sixteenths => _swing(fraction, 0.5),
      };
}

/// Dentro de cada tramo de [unit] pulsos, la primera mitad se estira a dos
/// tercios y la segunda se encoge al tercio que queda.
double _swing(double fraction, double unit) {
  final base = (fraction / unit).floor() * unit;
  final within = fraction - base;
  return base +
      (within < unit / 2
          ? within * 4 / 3
          : unit * 2 / 3 + (within - unit / 2) * 2 / 3);
}

/// Semicorchea en la que empieza cada nota (y silencio) de [notes].
List<int> tabPositions(List<TabNote> notes) {
  final positions = <int>[];
  var at = 0;
  for (final n in notes) {
    positions.add(at);
    at += n.length;
  }
  return positions;
}

/// Semicorcheas que dura [notes] entera.
int tabLength(List<TabNote> notes) => notes.fold(0, (sum, n) => sum + n.length);

/// Segundos desde el principio en que empieza cada nota de [notes].
List<double> tabOnsetSeconds(
  List<TabNote> notes, {
  required int bpm,
  TabSwing swing = TabSwing.none,
}) => [
  for (final p in tabPositions(notes)) tabSwungBeats(p, swing) * 60 / bpm,
];

/// Segundos hasta que termina la última nota (o silencio) de [notes]: ahí
/// vuelve a empezar un bucle.
double tabEndSeconds(
  List<TabNote> notes, {
  required int bpm,
  TabSwing swing = TabSwing.none,
}) => tabSwungBeats(tabLength(notes), swing) * 60 / bpm;

/// Cuánto tarda un slide en llegar: termina justo al tiempo de su nota.
const slideSeconds = 0.09;

/// Cuándo empieza a subir un bend tras la púa y cuánto tarda en llegar; un
/// release baja en [bendSeconds].
const bendDelaySeconds = 0.05;
const bendSeconds = 0.14;

/// Cuándo empieza el vibrato tras la púa.
const vibratoDelaySeconds = 0.12;

/// Lo que suena de [notes]: una cuerda por cada nota pulsada. Una nota que se
/// liga ([TabTechnique.legato]) no se vuelve a pulsar: cambia la altura de la
/// cuerda que ya suena. Volver a pulsar una cuerda apaga lo que sonaba en ella;
/// las demás siguen sonando hasta [tabNoteRingSeconds] (o menos, apagadas).
List<StringSound> tabSounds(
  List<TabNote> notes, {
  required int bpm,
  TabSwing swing = TabSwing.none,
}) {
  final onsets = tabOnsetSeconds(notes, bpm: bpm, swing: swing);
  final voices = <_Voice>[];
  final ringing = <int, _Voice>{};
  for (final (i, n) in notes.indexed) {
    if (n.isRest) continue;
    final t = onsets[i];
    final midi = tabMidi(n).toDouble();
    final open = ringing[n.string];
    if (n.technique.legato && open != null) {
      final rel = t - open.at;
      final glide = switch (n.technique) {
        TabTechnique.slide => (
          at: math.max(open.lastEvent - open.at, rel - slideSeconds),
          midi: midi,
          seconds: math.min(slideSeconds, rel - (open.lastEvent - open.at)),
          excite: false,
        ),
        TabTechnique.release => (at: rel, midi: midi, seconds: bendSeconds, excite: false),
        // Ligados: el dedo cae o se suelta de golpe.
        _ => (at: rel, midi: midi, seconds: 0.0, excite: true),
      };
      open.glides.add(glide);
      open.lastEvent = t;
      continue;
    }
    // Pulsar otra vez la cuerda apaga lo que sonaba en ella.
    if (open != null) open.cutAt = t;
    final voice = _Voice(
      at: t,
      midi: tabMidi(n),
      touch: switch (n.technique) {
        TabTechnique.palmMute => StringTouch.palmMute,
        TabTechnique.dead => StringTouch.dead,
        _ => StringTouch.open,
      },
    );
    if (n.technique == TabTechnique.bend) {
      voice.glides.add((
        at: bendDelaySeconds,
        midi: midi + n.bend,
        seconds: bendSeconds,
        excite: false,
      ));
    }
    if (n.technique == TabTechnique.vibrato) voice.vibratoFrom = vibratoDelaySeconds;
    voices.add(voice);
    ringing[n.string] = voice;
  }
  return [for (final v in voices) v.sound];
}

class _Voice {
  _Voice({required this.at, required this.midi, required this.touch}) : lastEvent = at;

  final double at;
  final int midi;
  final StringTouch touch;
  final glides = <Glide>[];
  double? vibratoFrom;

  /// Último ataque o ligado: desde ahí suena [tabNoteRingSeconds].
  double lastEvent;

  /// Cuándo la apaga otra púa en la misma cuerda.
  double? cutAt;

  StringSound get sound {
    final ring = switch (touch) {
      StringTouch.open => tabNoteRingSeconds,
      StringTouch.palmMute => palmMuteSeconds,
      StringTouch.dead => deadNoteSeconds * 2,
    };
    var end = lastEvent + ring;
    if (cutAt != null && cutAt! < end) end = cutAt!;
    return StringSound(
      midi: midi,
      at: at,
      seconds: end - at,
      glides: List.unmodifiable(glides),
      vibratoFrom: vibratoFrom,
      touch: touch,
    );
  }
}

/// Duración total del audio: hasta que deja de sonar la última nota.
double tabDurationSeconds(
  List<TabNote> notes, {
  required int bpm,
  TabSwing swing = TabSwing.none,
}) {
  final onsets = tabOnsetSeconds(notes, bpm: bpm, swing: swing);
  var end = tabEndSeconds(notes, bpm: bpm, swing: swing);
  for (final (i, n) in notes.indexed) {
    if (!n.isRest && onsets[i] + tabNoteRingSeconds > end) {
      end = onsets[i] + tabNoteRingSeconds;
    }
  }
  return end;
}

/// Qué nota (o silencio) suena a los [elapsed] segundos; `null` antes de
/// empezar y al terminar la última.
int? tabIndexAt(
  double elapsed,
  List<TabNote> notes, {
  required int bpm,
  TabSwing swing = TabSwing.none,
}) {
  if (elapsed < 0 || notes.isEmpty) return null;
  if (elapsed >= tabEndSeconds(notes, bpm: bpm, swing: swing)) return null;
  final onsets = tabOnsetSeconds(notes, bpm: bpm, swing: swing);
  var index = 0;
  // Un margen mínimo: el redondeo no debe atrasar una nota que ya empezó.
  while (index + 1 < onsets.length && onsets[index + 1] <= elapsed + 1e-9) {
    index++;
  }
  return index;
}

/// Cómo se cuenta la semicorchea [position] de un compás de [beatsPerBar]
/// pulsos: el número del pulso, y entre pulsos [e], [and] y [a]
/// ("1 e y a" / "1 e & a"). Las corcheas solas se cuentan "1 y 2 y".
String tabCountAt(
  int position, {
  required String e,
  required String and,
  required String a,
  int beatsPerBar = 4,
}) => switch (position % 4) {
  0 => '${position ~/ 4 % beatsPerBar + 1}',
  1 => e,
  2 => and,
  _ => a,
};

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
