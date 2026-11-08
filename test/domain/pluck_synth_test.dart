import 'dart:math' as math;
import 'dart:typed_data';

import 'package:chordmaster_free/domain/audio/pluck_synth.dart';
import 'package:flutter_test/flutter_test.dart';

/// Frecuencia fundamental por autocorrelación (busca el periodo entre 50 y
/// 1500 Hz) en una ventana tras el ataque.
double _estimateHz(Float64List x) {
  const start = 4410; // 0.1 s: ya pasó el ruido del ataque
  const window = 8192;
  const minLag = synthSampleRate ~/ 1500;
  const maxLag = synthSampleRate ~/ 50;
  var bestLag = minLag;
  var best = double.negativeInfinity;
  final corr = Float64List(maxLag + 2);
  for (var lag = minLag; lag <= maxLag + 1; lag++) {
    var sum = 0.0;
    for (var i = 0; i < window; i++) {
      sum += x[start + i] * x[start + i + lag];
    }
    corr[lag] = sum;
  }
  // Primer pico alto (evita confundir con múltiplos del periodo).
  final globalMax = corr.reduce((a, b) => a > b ? a : b);
  for (var lag = minLag + 1; lag <= maxLag; lag++) {
    if (corr[lag] > 0.8 * globalMax && corr[lag] >= corr[lag - 1] && corr[lag] >= corr[lag + 1]) {
      bestLag = lag;
      best = corr[lag];
      break;
    }
  }
  expect(best, isNot(double.negativeInfinity));
  // Interpolación parabólica para afinar entre muestras.
  final a = corr[bestLag - 1], b = corr[bestLag], c = corr[bestLag + 1];
  final shift = 0.5 * (a - c) / (a - 2 * b + c);
  return synthSampleRate / (bestLag + shift);
}

double _cents(double hz, double target) => 1200 * math.log(hz / target) / math.ln2;

void main() {
  test('A4 = 440 Hz y E2 = 82.41 Hz (cuerda 6 al aire), a menos de 1 cent', () {
    for (final (midi, hz) in [(69, 440.0), (40, 82.407), (64, 329.63), (52, 164.81)]) {
      final x = pluck(midiToHz(midi), 0.5);
      final cents = _cents(_estimateHz(x), hz);
      expect(cents.abs(), lessThan(1), reason: 'MIDI $midi: $cents cents');
    }
  });

  test('la cuerda se apaga: el final suena mucho menos que el ataque', () {
    final x = pluck(midiToHz(64), 2);
    double rms(int from, int to) {
      var s = 0.0;
      for (var i = from; i < to; i++) {
        s += x[i] * x[i];
      }
      return s / (to - from);
    }

    expect(rms(x.length - 4410, x.length), lessThan(rms(0, 4410) * 0.1));
    expect(x.last, 0);
  });

  test('determinista: misma semilla, mismas muestras', () {
    expect(pluck(220, 0.1), pluck(220, 0.1));
    expect(pluck(220, 0.1, seed: 2), isNot(pluck(220, 0.1)));
  });

  test('rasgueo normalizado a 0.9 y con la duración pedida', () {
    final x = renderStrum([48, 52, 55, 60, 64], seconds: 1.5);
    expect(x.length, (1.5 * synthSampleRate).round());
    final peak = x.map((v) => v.abs()).reduce((a, b) => a > b ? a : b);
    expect(peak, closeTo(0.9, 1e-9));
  });

  test('clic: 60 ms, el acento más fuerte', () {
    final tick = renderClick();
    final accent = renderClick(accent: true);
    expect(tick.length, (0.06 * synthSampleRate).round());
    double peak(Float64List x) => x.map((v) => v.abs()).reduce((a, b) => a > b ? a : b);
    expect(peak(accent), greaterThan(peak(tick)));
  });

  test('WAV: cabecera RIFF/WAVE PCM 16 bits mono y tamaño correcto', () {
    final samples = Float64List.fromList([0, 0.5, -0.5, 1, -1]);
    final wav = encodeWav(samples);
    final data = ByteData.sublistView(wav);
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    expect(data.getUint16(20, Endian.little), 1);
    expect(data.getUint16(22, Endian.little), 1);
    expect(data.getUint32(24, Endian.little), synthSampleRate);
    expect(data.getUint16(34, Endian.little), 16);
    expect(data.getUint32(40, Endian.little), 10);
    expect(wav.length, 44 + 10);
    expect(data.getInt16(44 + 6, Endian.little), 32767);
    expect(data.getInt16(44 + 8, Endian.little), -32767);
  });

  group('metrónomo en bucle', () {
    test('120 BPM en 4/4: un clic cada 0.5 s exactos, acento solo en el 1', () {
      final clicks = metronomeClicks(bpm: 120, beats: 4);
      expect([for (final c in clicks) c.at], [0, 22050, 44100, 66150]);
      expect([for (final c in clicks) c.kind],
          [ClickKind.accent, ClickKind.beat, ClickKind.beat, ClickKind.beat]);
    });

    test('las subdivisiones no son tiempos: corcheas en 3/4 = 6 clics, 3 tiempos', () {
      final clicks = metronomeClicks(bpm: 90, beats: 3, perBeat: 2);
      expect(clicks, hasLength(6));
      expect(clicks.where((c) => c.kind != ClickKind.subdivision), hasLength(3));
      expect(clicks[1].kind, ClickKind.subdivision);
      expect(clicks[2].kind, ClickKind.beat);
    });

    test('en cualquier tempo y subdivisión, los clics quedan a ±1 muestra de su instante', () {
      for (final bpm in [20, 61, 97, 133, 300]) {
        for (final per in [1, 2, 3, 4]) {
          final step = 60 * synthSampleRate / bpm / per;
          for (final (i, c) in metronomeClicks(bpm: bpm, beats: 7, perBeat: per).indexed) {
            expect((c.at - i * step).abs(), lessThanOrEqualTo(1), reason: '$bpm/$per');
          }
        }
      }
    });

    test('el bucle son compases enteros y dura al menos 8 s', () {
      final bar = metronomeBarSamples(bpm: 100, beats: 4);
      final loop = renderMetronomeLoop(bpm: 100, beats: 4);
      expect(loop.length % bar, 0);
      expect(loop.length, greaterThanOrEqualTo(8 * synthSampleRate));
      // Cada compás empieza con el acento: la misma señal en cada vuelta.
      expect(loop.sublist(bar, bar + 100), loop.sublist(0, 100));
    });
  });
}
