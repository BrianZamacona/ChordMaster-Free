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

/// Rasgueo de grave a aguda: [midiNotes] separadas [strum] segundos.
Float64List renderStrum(List<int> midiNotes, {double strum = 0.035, double seconds = 2.5}) {
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
