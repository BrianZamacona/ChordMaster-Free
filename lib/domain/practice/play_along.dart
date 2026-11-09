/// Tocar una tablatura con el micrófono: la app espera cada nota (sin
/// apuro), cuenta los errores y, al terminar, mide el tempo por la distancia
/// entre notas. Esa distancia no depende del retraso del micrófono, que es
/// igual en todas.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import '../audio/note_onsets.dart';
import '../lessons/lesson.dart';
import 'tab_playback.dart';
import 'technique_exercises.dart';

/// Qué fue una nota oída.
enum HeardKind {
  /// La que tocaba: se avanza.
  right,

  /// Otra nota: cuenta como error y se sigue esperando la correcta.
  wrong,

  /// La nota anterior otra vez, u otra nota sin ataque nuevo (cuerdas que
  /// siguen sonando): ni avanza ni es error.
  echo,

  /// Ya estaba terminada.
  ignored,
}

/// Una pausa de más de este múltiplo de la distancia típica entre notas
/// cuenta como detenerse.
const playAlongPauseFactor = 2.5;

/// Margen del tempo medido al redondearlo para el récord (2 %).
const playAlongTempoMargin = 0.02;

/// Cuánto baja "Más lento": dos pasos del selector de tempo.
const playAlongSlowerBy = 2 * techniqueBpmStep;

/// El tempo de "Más lento": [playAlongSlowerBy] menos, sin bajar del mínimo.
int slowerBpm(int bpm) => math.max(techniqueMinBpm, bpm - playAlongSlowerBy);

/// Sigue una tablatura nota por nota. Los silencios y las notas muertas no
/// tienen altura: no se esperan (la nota muerta es solo un golpe).
class NoteFollower {
  NoteFollower(List<TabNote> tab, {TabSwing swing = TabSwing.none}) : length = tab.length {
    final positions = tabPositions(tab);
    for (final (i, n) in tab.indexed) {
      if (n.isRest || n.technique == TabTechnique.dead) continue;
      _indices.add(i);
      expected.add(tabMidi(n));
      _beats.add(tabSwungBeats(positions[i], swing));
    }
  }

  /// Notas de la tablatura (con silencios y notas muertas).
  final int length;

  /// MIDI esperado de cada nota que se oye (al pulsarla: un bend se espera en
  /// su traste, y la nota empujada llega sin ataque).
  final expected = <int>[];
  final _indices = <int>[];
  final _beats = <double>[];

  int _next = 0;
  final _mistakesAt = <int>[];
  final _times = <double>[];

  /// Índice en la tablatura de la nota que se espera ([length] al terminar):
  /// las de antes salieron bien.
  int get position => done ? length : _indices[_next];
  int get mistakes => _mistakesAt.length;
  bool get done => _next >= expected.length;

  /// La nota que se espera, o `null` al terminar.
  int? get expectedMidi => done ? null : expected[_next];

  /// Instantes en que salió bien cada nota.
  List<double> get times => List.unmodifiable(_times);

  HeardKind hear(HeardNote note) {
    if (done) return HeardKind.ignored;
    if (note.midi == expected[_next]) {
      _next++;
      _times.add(note.at);
      return HeardKind.right;
    }
    if (!note.plucked || (_next > 0 && note.midi == expected[_next - 1])) {
      return HeardKind.echo;
    }
    _mistakesAt.add(position);
    return HeardKind.wrong;
  }

  /// Cómo salió (solo tiene sentido al terminar).
  PlayAlongResult get result => PlayAlongResult.from(
    _times,
    beats: _beats.sublist(0, _times.length),
    mistakesAt: _mistakesAt,
  );
}

/// Una tablatura tocada con el micrófono: cada ventana se analiza buscando la
/// nota que toca ahora, y lo oído avanza el [follower].
class PlayAlongSession {
  PlayAlongSession(List<TabNote> tab, {this.a4 = 440, TabSwing swing = TabSwing.none})
    : follower = NoteFollower(tab, swing: swing),
      _detector = NoteOnsetDetector(a4: a4);

  final double a4;
  final NoteFollower follower;
  final NoteOnsetDetector _detector;

  /// La última nota que empezó (MIDI), acertada o no.
  int? lastHeard;

  /// La nota que se espera, o `null` al terminar.
  int? get expectedMidi => follower.expectedMidi;

  /// Una ventana del micrófono que termina en el instante [at] (segundos);
  /// [hop] = muestras nuevas desde la anterior. Devuelve qué fue la nota que
  /// empezó, si empezó una.
  HeardKind? listen(
    Float64List window,
    int sampleRate, {
    required double at,
    required int hop,
  }) {
    final expected = expectedMidi;
    final frame = analyzeFrame(
      window,
      sampleRate,
      at: at,
      hop: hop,
      expectedMidi: expected,
      a4: a4,
    );
    final note = _detector.feed(frame, expected: expected);
    if (note == null) return null;
    lastHeard = note.midi;
    return follower.hear(note);
  }
}

/// Lo que se mide al terminar.
class PlayAlongResult {
  const PlayAlongResult({
    required this.mistakesAt,
    required this.bpm,
    required this.pauseAt,
  });

  /// [times]: instante de cada nota correcta, en orden, y [beats]: en qué
  /// pulso cae cada una en la tablatura (sin darlos, corcheas seguidas);
  /// [mistakesAt]: la nota que se esperaba (índice) cuando sonó cada error.
  factory PlayAlongResult.from(
    List<double> times, {
    List<double>? beats,
    List<int> mistakesAt = const [],
  }) {
    final at = beats ?? [for (var i = 0; i < times.length; i++) i / defaultNotesPerBeat];
    final errors = List<int>.unmodifiable(mistakesAt);
    if (times.length < 2 || at.last <= at.first) {
      return PlayAlongResult(mistakesAt: errors, bpm: null, pauseAt: null);
    }
    // El tempo, por la distancia de la primera a la última: el micrófono
    // ubica cada nota en cuadros de ~46 ms, y en toda la pasada ese redondeo
    // se diluye. Las pausas, contra la típica (segundos por pulso de cada
    // tramo, así una nota larga no cuenta como pausa).
    final seconds = times.last - times.first;
    final perBeat = [
      for (var i = 1; i < times.length; i++)
        if (at[i] > at[i - 1]) (times[i] - times[i - 1]) / (at[i] - at[i - 1]) else double.infinity,
    ];
    final typical = _median(perBeat);
    final pause = perBeat.indexWhere((g) => g > typical * playAlongPauseFactor);
    return PlayAlongResult(
      mistakesAt: errors,
      bpm: seconds <= 0 ? null : 60 * (at.last - at.first) / seconds,
      // La pausa es antes de la nota que tardó en llegar.
      pauseAt: pause < 0 ? null : pause + 1,
    );
  }

  /// Dónde sonó cada error: el índice de la nota que se esperaba.
  final List<int> mistakesAt;

  int get mistakes => mistakesAt.length;

  /// Tempo medio al que se tocó, contando cada nota como corchea (como el
  /// reproductor); `null` con menos de dos notas.
  final double? bpm;

  /// La primera nota que llegó tras una pausa larga, o `null` si no hubo.
  final int? pauseAt;

  /// Hubo una pausa larga en medio.
  bool get paused => pauseAt != null;

  /// Limpia = sin errores, sin detenerse y con tempo medible.
  bool get clean => mistakes == 0 && !paused && bpm != null;

  /// Tempo que se guarda como récord limpio: el tocado, redondeado hacia abajo
  /// al paso del selector de tempo (con un margen de [playAlongTempoMargin],
  /// lo que puede errar la medida: 99.6 BPM cuenta como 100) y dentro de su
  /// rango. `null` si no salió limpia o fue más lenta que el mínimo.
  int? get cleanBpm {
    if (!clean) return null;
    final floored =
        (bpm! * (1 + playAlongTempoMargin) / techniqueBpmStep).floor() * techniqueBpmStep;
    if (floored < techniqueMinBpm) return null;
    return math.min(floored, techniqueMaxBpm);
  }

  /// El renglón (desde 0, de [tabNotesPerLine] notas) que conviene repetir:
  /// el de más errores (si empatan, el primero) o, sin errores, el de la
  /// pausa. `null` si salió limpia.
  int? get lineToPractice {
    if (mistakesAt.isNotEmpty) {
      final perLine = <int, int>{};
      for (final i in mistakesAt) {
        perLine.update(tabLineOf(i), (n) => n + 1, ifAbsent: () => 1);
      }
      final most = perLine.values.reduce(math.max);
      return perLine.keys.where((l) => perLine[l] == most).reduce(math.min);
    }
    final pause = pauseAt;
    return pause == null ? null : tabLineOf(pause);
  }
}
double _median(List<double> xs) {
  final s = [...xs]..sort();
  final m = s.length ~/ 2;
  return s.length.isOdd ? s[m] : (s[m - 1] + s[m]) / 2;
}
