import 'dart:math' as math;
import 'dart:typed_data';

import 'package:chordmaster_free/domain/audio/pitch_detection.dart';
import 'package:chordmaster_free/domain/audio/pluck_synth.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ventana como la del afinador: 44.1 kHz decimado a 22.05 kHz, 2 × periodo
/// máximo de muestras, tomada tras el ataque.
Float64List _window(Float64List x, {double from = 0.15}) {
  final half = decimateByTwo(x);
  final start = (from * synthSampleRate / 2).round();
  return Float64List.sublistView(half, start, start + 2048);
}

double _cents(double hz, double target) => 1200 * math.log(hz / target) / math.ln2;

void main() {
  const rate = synthSampleRate ~/ 2;

  test('las 6 cuerdas al aire y A4, a menos de 2 cents (sin errores de octava)', () {
    for (final midi in [40, 45, 50, 55, 59, 64, 69]) {
      final hz = midiToHz(midi);
      final got = detectPitchHz(_window(pluck(hz, 0.5)), rate);
      expect(got, isNotNull, reason: 'MIDI $midi');
      expect(_cents(got!, hz).abs(), lessThan(2), reason: 'MIDI $midi: $got Hz');
    }
  });

  test('una cuerda desafinada 20 cents se lee como tal', () {
    final hz = midiToHz(45) * math.pow(2, 20 / 1200);
    final got = detectPitchHz(_window(pluck(hz, 0.5)), rate)!;
    final note = nearestNote(got);
    expect(note.name, 'A2');
    expect(note.cents, closeTo(20, 2));
  });

  test('silencio y ruido blanco: sin lectura', () {
    expect(detectPitchHz(Float64List(2048), rate), isNull);
    final rng = math.Random(7);
    final noise = Float64List.fromList([for (var i = 0; i < 2048; i++) rng.nextDouble() * 2 - 1]);
    expect(detectPitchHz(noise, rate), isNull);
  });

  test('nearestNote: nombre con octava, MIDI y cents; respeta el La de referencia', () {
    expect(nearestNote(440).name, 'A4');
    expect(nearestNote(82.41).name, 'E2');
    expect(nearestNote(466.16).name, 'A#4');
    expect(nearestNote(440).cents, closeTo(0, 1e-9));
    // Con La = 442, un 440 suena bajo (unos −7.85 cents).
    expect(nearestNote(440, a4: 442).cents, closeTo(-7.85, 0.05));
  });

  test('PCM 16 bits little-endian a −1..1', () {
    final bytes = Uint8List.fromList([0x00, 0x00, 0xFF, 0x7F, 0x00, 0x80]);
    expect(pcm16ToSamples(bytes), [0, 32767 / 32768, -1]);
  });
}
