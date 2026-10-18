import 'package:chordmaster_free/domain/theory/octaves.dart';
import 'package:flutter_test/flutter_test.dart';

const _open = [64, 59, 55, 50, 45, 40]; // 1ª → 6ª

void main() {
  test('las 8 formas de octava de la afinación estándar', () {
    expect(octaveShapes().map((s) => s.toString()), [
      '6→4 +2 (1 oct)',
      '5→3 +2 (1 oct)',
      '4→2 +3 (1 oct)',
      '3→1 +3 (1 oct)',
      '6→3 -3 (1 oct)',
      '5→2 -2 (1 oct)',
      '4→1 -2 (1 oct)',
      '6→1 +0 (2 oct)',
    ]);
  });

  test('cada forma suena exactamente 1 o 2 octavas más arriba', () {
    for (final s in octaveShapes()) {
      for (var fret = 3; fret <= 12; fret++) {
        final low = _open[s.lowString - 1] + fret;
        final high = _open[s.highString - 1] + fret + s.fretShift;
        expect(high - low, 12 * s.octaves, reason: '$s traste $fret');
      }
    }
  });

  test('C en el diapasón (0–12) y sus octavas de la 6ª a la 4ª', () {
    expect(notePositions(0), [
      (string: 6, fret: 8),
      (string: 5, fret: 3),
      (string: 4, fret: 10),
      (string: 3, fret: 5),
      (string: 2, fret: 1),
      (string: 1, fret: 8),
    ]);
    final shape = octaveShapes().first;
    expect(octavePairs(0, shape), [((string: 6, fret: 8), (string: 4, fret: 10))]);
  });

  test('E en las cuerdas al aire: 6→1 a dos octavas en el traste 0 y en el 12', () {
    final twoOctaves = octaveShapes().last;
    expect(octavePairs(4, twoOctaves), [
      ((string: 6, fret: 0), (string: 1, fret: 0)),
      ((string: 6, fret: 12), (string: 1, fret: 12)),
    ]);
  });
}
