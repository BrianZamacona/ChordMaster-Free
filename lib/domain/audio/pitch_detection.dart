/// Detección de afinación para el afinador: algoritmo YIN (de Cheveigné y
/// Kawahara, 2002) con interpolación parabólica, más la nota más cercana con
/// un La de referencia configurable.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import '../theory/double_stops.dart' show noteNames;

/// Frecuencia fundamental de [samples] (−1..1) en Hz, o `null` si es
/// silencio, ruido o no hay un periodo claro.
///
/// - [minHz]/[maxHz]: rango buscado (guitarra: E2 = 82 Hz … ~1 kHz).
/// - [threshold]: umbral de la diferencia normalizada de YIN; más bajo =
///   más exigente.
/// - [minRms]: por debajo de este nivel se considera silencio.
///
/// Necesita al menos `2 × sampleRate / minHz` muestras.
double? detectPitchHz(
  Float64List samples,
  int sampleRate, {
  double minHz = 60,
  double maxHz = 1100,
  double threshold = 0.12,
  double minRms = 0.005,
}) {
  final tauMax = (sampleRate / minHz).ceil();
  final tauMin = math.max(2, (sampleRate / maxHz).floor());
  final window = samples.length - tauMax;
  if (window < tauMax) return null;

  var energy = 0.0;
  for (var i = 0; i < samples.length; i++) {
    energy += samples[i] * samples[i];
  }
  if (math.sqrt(energy / samples.length) < minRms) return null;

  // 1-2. Diferencia y diferencia media normalizada acumulada (CMNDF).
  final d = Float64List(tauMax + 1);
  for (var tau = 1; tau <= tauMax; tau++) {
    var sum = 0.0;
    for (var i = 0; i < window; i++) {
      final delta = samples[i] - samples[i + tau];
      sum += delta * delta;
    }
    d[tau] = sum;
  }
  final cmnd = Float64List(tauMax + 1)..[0] = 1;
  var running = 0.0;
  for (var tau = 1; tau <= tauMax; tau++) {
    running += d[tau];
    cmnd[tau] = running == 0 ? 1 : d[tau] * tau / running;
  }

  // 3. Primer mínimo por debajo del umbral (evita errores de octava).
  var tau = -1;
  for (var t = tauMin; t < tauMax; t++) {
    if (cmnd[t] < threshold) {
      while (t + 1 < tauMax && cmnd[t + 1] < cmnd[t]) {
        t++;
      }
      tau = t;
      break;
    }
  }
  if (tau < 0) return null;

  // 4. Interpolación parabólica alrededor del mínimo.
  final a = cmnd[tau - 1], b = cmnd[tau], c = cmnd[tau + 1];
  final denom = a - 2 * b + c;
  final refined = denom == 0 ? tau.toDouble() : tau + 0.5 * (a - c) / denom;
  return sampleRate / refined;
}

/// Nota temperada más cercana a [hz] con La4 = [a4] Hz: nombre con
/// sostenidos y octava ("E2", "A#3"), número MIDI y desvío en cents
/// (positivo = alto).
({String name, int midi, double cents}) nearestNote(double hz, {double a4 = 440}) {
  final exact = 69 + 12 * math.log(hz / a4) / math.ln2;
  final midi = exact.round();
  return (
    name: '${noteNames[midi % 12]}${midi ~/ 12 - 1}',
    midi: midi,
    cents: (exact - midi) * 100,
  );
}

/// Reduce a la mitad la frecuencia de muestreo promediando pares de
/// muestras (filtro paso bajo simple; la guitarra no pasa de ~1.3 kHz de
/// fundamental).
Float64List decimateByTwo(Float64List x) {
  final out = Float64List(x.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = 0.5 * (x[2 * i] + x[2 * i + 1]);
  }
  return out;
}

/// PCM de 16 bits con signo, little-endian (lo que entrega el micrófono), a
/// muestras −1..1.
Float64List pcm16ToSamples(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  final out = Float64List(bytes.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = data.getInt16(i * 2, Endian.little) / 32768.0;
  }
  return out;
}
