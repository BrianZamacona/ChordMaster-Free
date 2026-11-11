/// Síntesis de cuerda pulsada (Karplus-Strong) y clic de metrónomo, en Dart
/// puro: la app genera su propio sonido y no necesita archivos de audio.
///
/// Es determinista (ruido con semilla fija) para poder probarlo.
library;

import 'dart:math' as math;
import 'dart:typed_data';

/// Frecuencia de muestreo de todo lo que se genera.
const synthSampleRate = 44100;

/// Frecuencia en Hz de una nota MIDI (A4 = 69 = 440 Hz).
double midiToHz(int midi) => 440.0 * math.pow(2, (midi - 69) / 12);

/// Una nota que empieza en [at] segundos.
typedef NoteEvent = ({int midi, double at});

/// Cuerda pulsada de [hz] durante [seconds] (Karplus-Strong con afinación
/// fraccionaria por filtro pasa-todo, Jaffe-Smith). Amplitud ≤ 1.
Float64List pluck(double hz, double seconds, {int seed = 1, double decay = 0.996}) {
  final total = (seconds * synthSampleRate).round();
  final out = Float64List(total);
  // Retardo del lazo = N + 0.5 (promedio) + d (pasa-todo) = periodo exacto.
  final period = synthSampleRate / hz;
  final n = (period - 0.5 - 1e-6).floor();
  final d = period - 0.5 - n;
  final c = (1 - d) / (1 + d);

  // Ataque: ruido suavizado (pulsación con la yema, no con púa metálica).
  final rng = math.Random(seed);
  final buf = Float64List(n);
  var smooth = 0.0;
  for (var i = 0; i < n; i++) {
    smooth = 0.5 * smooth + 0.5 * (rng.nextDouble() * 2 - 1);
    buf[i] = smooth;
  }
  var mean = 0.0;
  for (final v in buf) {
    mean += v;
  }
  mean /= n;
  for (var i = 0; i < n; i++) {
    buf[i] -= mean; // sin componente continua
  }

  var idx = 0;
  var prev = 0.0; // muestra leída en el paso anterior (una más reciente)
  var apIn = 0.0;
  var apOut = 0.0;
  for (var t = 0; t < total; t++) {
    final cur = buf[idx];
    out[t] = cur;
    // Promedio de dos muestras consecutivas: medio paso de retardo extra.
    final avg = decay * 0.5 * (cur + prev);
    prev = cur;
    final ap = c * avg + apIn - c * apOut;
    apIn = avg;
    apOut = ap;
    buf[idx] = ap;
    idx = (idx + 1) % n;
  }
  _fadeOut(out);
  return out;
}

/// Mezcla de cuerdas pulsadas: cada evento suena desde su instante hasta el
/// final de [seconds] o, con [ring], solo esos segundos (en una frase la nota
/// siguiente apaga la anterior, y así el costo no crece con el cuadrado).
/// Normalizada a un pico de 0.9.
Float64List renderNotes(
  List<NoteEvent> events, {
  double seconds = 2.5,
  double? ring,
}) {
  final total = (seconds * synthSampleRate).round();
  final mix = Float64List(total);
  final ringSamples = ring == null ? null : (ring * synthSampleRate).round();
  for (final (i, e) in events.indexed) {
    final start = (e.at * synthSampleRate).round();
    if (start >= total) continue;
    var length = total - start;
    if (ringSamples != null && ringSamples < length) length = ringSamples;
    final note = pluck(midiToHz(e.midi), length / synthSampleRate, seed: i + 1);
    for (var t = 0; t < note.length && start + t < total; t++) {
      mix[start + t] += note[t];
    }
  }
  _normalize(mix, 0.9);
  return mix;
}

/// Cómo se pulsa una cuerda.
enum StringTouch {
  /// Normal: suena hasta que la apaga la nota siguiente en esa cuerda.
  open,

  /// Apagada con la palma: corta y sorda ([palmMuteSeconds]).
  palmMute,

  /// Nota muerta: solo el golpe ([deadNoteSeconds]).
  dead,
}

/// En cuánto se apaga (−60 dB) una nota con la palma.
const palmMuteSeconds = 0.3;

/// En cuánto se apaga una nota muerta.
const deadNoteSeconds = 0.05;

/// Profundidad del vibrato (semitonos, hacia cada lado) y su frecuencia.
const vibratoDepth = 0.3;
const vibratoHz = 5.5;

/// Un cambio de altura sin volver a pulsar: desde [at] segundos después del
/// ataque, la cuerda llega a [midi] en [seconds]. Con [excite], el dedo que
/// cae o se suelta (ligado) le da un poco de energía a la cuerda.
typedef Glide = ({double at, double midi, double seconds, bool excite});

/// Una cuerda que suena: se pulsa en [at] (segundos) con [midi] y suena
/// [seconds]. [glides] la llevan a otras alturas sin volver a pulsar
/// (ligados, slides, bends); desde [vibratoFrom] (segundos tras el ataque)
/// la altura oscila.
class StringSound {
  const StringSound({
    required this.midi,
    required this.at,
    required this.seconds,
    this.glides = const [],
    this.vibratoFrom,
    this.touch = StringTouch.open,
    this.gain = 1,
  });

  final int midi;
  final double at;
  final double seconds;
  final List<Glide> glides;
  final double? vibratoFrom;
  final StringTouch touch;

  /// Volumen frente a las demás cuerdas de la mezcla (1 = igual): el
  /// acompañamiento va más bajo que la frase.
  final double gain;

  /// La misma cuerda con volumen [gain].
  StringSound withGain(double gain) => StringSound(
    midi: midi,
    at: at,
    seconds: seconds,
    glides: glides,
    vibratoFrom: vibratoFrom,
    touch: touch,
    gain: gain,
  );

  /// La altura (MIDI, con decimales) a los [t] segundos del ataque.
  double midiAt(double t) {
    var m = midi.toDouble();
    for (final g in glides) {
      if (t <= g.at) break;
      final from = m;
      m = g.seconds <= 0 || t >= g.at + g.seconds
          ? g.midi
          : from + (g.midi - from) * (t - g.at) / g.seconds;
    }
    final v = vibratoFrom;
    if (v != null && t > v) {
      // Entra de a poco en 0.15 s, como la mano que empieza a moverse.
      final double ramp = math.min(1, (t - v) / 0.15);
      m += vibratoDepth * ramp * math.sin(2 * math.pi * vibratoHz * (t - v));
    }
    return m;
  }

  /// La altura cambia mientras suena.
  bool get moves => glides.isNotEmpty || vibratoFrom != null;

  @override
  bool operator ==(Object other) => other is StringSound && other.toString() == toString();

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() =>
      '$midi@${at.toStringAsFixed(4)}+${seconds.toStringAsFixed(3)}'
      '${touch == StringTouch.open ? '' : ':${touch.name}'}'
      '${[for (final g in glides) '>${g.midi}@${g.at.toStringAsFixed(3)}/${g.seconds.toStringAsFixed(3)}${g.excite ? 'x' : ''}'].join()}'
      '${vibratoFrom == null ? '' : '~${vibratoFrom!.toStringAsFixed(3)}'}'
      '${gain == 1 ? '' : '*${gain.toStringAsFixed(2)}'}';
}

/// Coeficiente de pérdida por vuelta del lazo para que una cuerda de [hz]
/// caiga 60 dB en [seconds].
double decayFor(double hz, double seconds) => math.pow(0.001, 1 / (seconds * hz)).toDouble();

/// Mezcla de [sounds] durante [seconds], normalizada a un pico de 0.9.
Float64List renderStrings(List<StringSound> sounds, {required double seconds}) {
  final total = (seconds * synthSampleRate).round();
  final mix = Float64List(total);
  for (final (i, s) in sounds.indexed) {
    final start = (s.at * synthSampleRate).round();
    if (start >= total) continue;
    final length = math.min(total - start, (s.seconds * synthSampleRate).round());
    if (length <= 0) continue;
    final note = _renderString(s, length / synthSampleRate, seed: i + 1);
    for (var t = 0; t < note.length && start + t < total; t++) {
      mix[start + t] += note[t] * s.gain;
    }
  }
  _normalize(mix, 0.9);
  return mix;
}

Float64List _renderString(StringSound s, double seconds, {required int seed}) {
  final hz = midiToHz(s.midi);
  final decay = switch (s.touch) {
    StringTouch.open => 0.996,
    StringTouch.palmMute => decayFor(hz, palmMuteSeconds),
    StringTouch.dead => decayFor(hz, deadNoteSeconds),
  };
  if (!s.moves) return pluck(hz, seconds, seed: seed, decay: decay);
  return _pluckMoving(s, seconds, seed: seed, decay: decay);
}

/// Karplus-Strong con retardo variable: el periodo sigue a [StringSound.midiAt]
/// muestra a muestra (interpolación lineal), así un ligado, un slide o un bend
/// cambian la altura de la cuerda que ya vibra, sin volver a pulsarla.
Float64List _pluckMoving(
  StringSound s,
  double seconds, {
  required int seed,
  required double decay,
}) {
  final total = (seconds * synthSampleRate).round();
  final out = Float64List(total);
  // El periodo más largo (la nota más grave que alcanza, con el vibrato).
  var lowest = s.midi.toDouble();
  for (final g in s.glides) {
    lowest = math.min(lowest, g.midi);
  }
  if (s.vibratoFrom != null) lowest -= vibratoDepth;
  final size = (synthSampleRate / (440.0 * math.pow(2, (lowest - 69) / 12))).ceil() + 4;
  final history = Float64List(size);
  final rng = math.Random(seed);

  // Ruido suavizado: el ataque y, más débil, cada dedo que cae (ligado).
  final bursts = <({int from, int to, double gain})>[];
  final firstPeriod = (synthSampleRate / midiToHz(s.midi)).round();
  bursts.add((from: 0, to: firstPeriod, gain: 1));
  for (final g in s.glides) {
    if (!g.excite) continue;
    final from = ((g.at + g.seconds) * synthSampleRate).round();
    final period = (synthSampleRate / (440.0 * math.pow(2, (g.midi - 69) / 12))).round();
    bursts.add((from: from, to: from + period, gain: 0.3));
  }
  var smooth = 0.0;

  double read(double delay, int t) {
    // Muestra de hace [delay] (fraccionario) desde la muestra t.
    final pos = t - delay;
    final i = pos.floor();
    final frac = pos - i;
    double at(int k) => k < 0 || t - k > size - 1 ? 0 : history[k % size];
    return at(i) * (1 - frac) + at(i + 1) * frac;
  }

  for (var t = 0; t < total; t++) {
    final midi = s.midiAt(t / synthSampleRate);
    final period = synthSampleRate / (440.0 * math.pow(2, (midi - 69) / 12));
    // Retardo del lazo = D (lectura) + 0.5 (promedio de dos muestras) = periodo.
    final d = period - 0.5;
    var y = decay * 0.5 * (read(d, t) + read(d + 1, t));
    for (final b in bursts) {
      if (t >= b.from && t < b.to) {
        smooth = 0.5 * smooth + 0.5 * (rng.nextDouble() * 2 - 1);
        y += b.gain * smooth;
      }
    }
    history[t % size] = y;
    out[t] = y;
  }
  _fadeOut(out);
  return out;
}

/// Segundos entre una cuerda y la siguiente al rasguear.
const defaultStrumGap = 0.035;

/// Rasgueo de grave a aguda: [midiNotes] separadas [strum] segundos.
Float64List renderStrum(
  List<int> midiNotes, {
  double strum = defaultStrumGap,
  double seconds = 2.5,
}) {
  final sorted = [...midiNotes]..sort();
  return renderNotes(
    [for (final (i, m) in sorted.indexed) (midi: m, at: i * strum)],
    seconds: seconds,
  );
}

/// Clic de metrónomo: seno corto con caída rápida; el acento es más agudo y
/// más fuerte.
Float64List renderClick({bool accent = false}) {
  const seconds = 0.06;
  final total = (seconds * synthSampleRate).round();
  final out = Float64List(total);
  final hz = accent ? 1760.0 : 1320.0;
  final gain = accent ? 0.9 : 0.6;
  for (var t = 0; t < total; t++) {
    final time = t / synthSampleRate;
    out[t] = gain * math.sin(2 * math.pi * hz * time) * math.exp(-time / 0.012);
  }
  _fadeOut(out, seconds: 0.005);
  return out;
}

/// Tipo de clic del metrónomo.
enum ClickKind { accent, beat, subdivision }

/// Cuándo suena cada clic de un compás de [beats] tiempos a [bpm], con
/// [perBeat] clics por tiempo (1 = negras, 2 = corcheas, 3 = tresillos,
/// 4 = semicorcheas): muestra de inicio y tipo. El compás dura un número
/// entero de muestras ([metronomeBarSamples]) y cada clic cae en la muestra
/// más cercana a su instante exacto.
List<({int at, ClickKind kind})> metronomeClicks({
  required int bpm,
  required int beats,
  int perBeat = 1,
}) {
  final bar = metronomeBarSamples(bpm: bpm, beats: beats);
  final count = beats * perBeat;
  return [
    for (var i = 0; i < count; i++)
      (
        at: (i * bar / count).round(),
        kind: i == 0
            ? ClickKind.accent
            : i % perBeat == 0
                ? ClickKind.beat
                : ClickKind.subdivision,
      ),
  ];
}

/// Muestras de un compás de [beats] tiempos a [bpm].
int metronomeBarSamples({required int bpm, required int beats}) =>
    (beats * 60 * synthSampleRate / bpm).round();

/// Compases de metrónomo listos para repetirse en bucle sin hueco: el
/// tiempo lo marcan las muestras, no un temporizador. Se repite el compás
/// hasta durar al menos [minSeconds] (menos vueltas del reproductor), y un
/// clic que pasa del final continúa al principio.
Float64List renderMetronomeLoop({
  required int bpm,
  required int beats,
  int perBeat = 1,
  double minSeconds = 8,
}) {
  final bar = metronomeBarSamples(bpm: bpm, beats: beats);
  final bars = math.max(1, (minSeconds * synthSampleRate / bar).ceil());
  final out = Float64List(bar * bars);
  final sounds = {
    ClickKind.accent: renderClick(accent: true),
    ClickKind.beat: renderClick(),
    ClickKind.subdivision: Float64List.fromList([for (final x in renderClick()) x * 0.45]),
  };
  final clicks = metronomeClicks(bpm: bpm, beats: beats, perBeat: perBeat);
  for (var b = 0; b < bars; b++) {
    for (final c in clicks) {
      final sound = sounds[c.kind]!;
      for (var t = 0; t < sound.length; t++) {
        out[(b * bar + c.at + t) % out.length] += sound[t];
      }
    }
  }
  return out;
}

/// WAV PCM de 16 bits, mono, de [samples] (-1..1).
Uint8List encodeWav(Float64List samples) {
  final dataBytes = samples.length * 2;
  final bytes = ByteData(44 + dataBytes);
  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      bytes.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  bytes.setUint32(4, 36 + dataBytes, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  bytes
    ..setUint32(16, 16, Endian.little) // tamaño del bloque fmt
    ..setUint16(20, 1, Endian.little) // PCM
    ..setUint16(22, 1, Endian.little) // mono
    ..setUint32(24, synthSampleRate, Endian.little)
    ..setUint32(28, synthSampleRate * 2, Endian.little) // bytes por segundo
    ..setUint16(32, 2, Endian.little) // bytes por muestra
    ..setUint16(34, 16, Endian.little); // bits
  ascii(36, 'data');
  bytes.setUint32(40, dataBytes, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    final v = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    bytes.setInt16(44 + i * 2, v, Endian.little);
  }
  return bytes.buffer.asUint8List();
}

void _normalize(Float64List x, double peak) {
  var max = 0.0;
  for (final v in x) {
    if (v.abs() > max) max = v.abs();
  }
  if (max == 0) return;
  final k = peak / max;
  for (var i = 0; i < x.length; i++) {
    x[i] *= k;
  }
}

/// Rampa final para que no haya chasquido al cortar.
void _fadeOut(Float64List x, {double seconds = 0.05}) {
  final n = math.min(x.length, (seconds * synthSampleRate).round());
  for (var i = 0; i < n; i++) {
    x[x.length - 1 - i] *= i / n;
  }
}
