import 'package:chordmaster_free/domain/open_chords/chord_shape.dart';
import 'package:chordmaster_free/domain/progressions/arpeggio_patterns.dart';
import 'package:chordmaster_free/domain/progressions/progression_data.dart';
import 'package:chordmaster_free/domain/progressions/progression_playback.dart';
import 'package:chordmaster_free/domain/strumming/strumming_course.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // x32010 y xx0232 (orden de chords.json: 6ª → 1ª).
  const c = ChordShape(name: 'C', frets: [-1, 3, 2, 0, 1, 0], fingers: [0, 3, 2, 0, 1, 0]);
  const d = ChordShape(name: 'D', frets: [-1, -1, 0, 2, 3, 2], fingers: [0, 0, 0, 1, 3, 2]);

  List<int> midis(List<ChordShape> shapes, int pattern, {List<int>? beats}) => [
    for (final s in arpeggioEvents(shapes, bpm: 60, pattern: arpeggioPatterns[pattern], beats: beats)) s.midi,
  ];

  test('tres patrones de un compás, una letra por corchea', () {
    expect(arpeggioPatterns, hasLength(3));
    for (final p in arpeggioPatterns) {
      expect(p, hasLength(8));
      expect(p.split('').toSet().difference({'B', 'b', '3', '2', '1'}), isEmpty);
      // Empieza por el bajo, en el 1.
      expect(p[0], 'B');
    }
  });

  test('en C: el bajo es la 5ª cuerda, el otro bajo la 4ª; todo es del acorde', () {
    expect(midis([c], 0), [48, 55, 60, 64, 48, 55, 60, 64]); // 6-3-2-1, dos veces
    expect(midis([c], 1), [48, 55, 60, 64, 60, 55, 60, 55]); // sube y baja
    expect(midis([c], 2), [48, 55, 60, 55, 52, 55, 60, 55]); // bajos alternados
    for (var p = 0; p < arpeggioPatterns.length; p++) {
      for (final m in midis([c, d], p)) {
        expect({0, 4, 7, 2, 6, 9}, contains(m % 12));
      }
    }
    // D (xx0232): el bajo es la 4ª al aire.
    expect(midis([d], 0).first, 50);
  });

  test('una nota por corchea; se deja sonar hasta que su cuerda vuelve a sonar o cambia el acorde', () {
    final events = arpeggioEvents([c, d], bpm: 60, pattern: arpeggioPatterns[0]);
    expect([for (final e in events.take(8)) e.at], [0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5]);
    // El bajo de C vuelve a sonar en el 3: la primera dura hasta ahí.
    expect(events[0].seconds, 2);
    // La última nota de C suena hasta que entra D (a los 4 s).
    expect(events[7].at + events[7].seconds, closeTo(4, 1e-9));
    // Ninguna cuerda suena dos veces a la vez.
    for (final a in events) {
      for (final b in events) {
        if (identical(a, b) || a.midi != b.midi) continue;
        expect(a.at + a.seconds <= b.at || b.at + b.seconds <= a.at, isTrue);
      }
    }
  });

  test('sigue el compás aunque el acorde dure medio: dos de medio compás tocan un patrón entero', () {
    expect(midis([c, c], 0, beats: const [2, 2]), midis([c], 0));
  });

  test('en la escucha: detrás de los cinco rasgueos; el 12/8 sigue rasgueando', () {
    expect(progressionPatternCount, strummingPatterns.length + arpeggioPatterns.length);
    expect(arpeggioOf(0), isNull);
    expect(arpeggioOf(strummingPatterns.length), 0);
    expect(arpeggioOf(progressionPatternCount), isNull);
    final arp = progressionAccompaniment([c], bpm: 60, pattern: strummingPatterns.length);
    expect([for (final s in arp) s.midi], midis([c], 0));
    final triplet = progressionAccompaniment([c], bpm: 60, pattern: strummingPatterns.length, feel: ProgressionFeel.triplet);
    expect(triplet, hasLength(4 * 3 * 5)); // 12 golpes de 5 cuerdas
  });
}
