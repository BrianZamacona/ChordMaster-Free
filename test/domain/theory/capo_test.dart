import 'package:chordmaster_free/domain/progressions/progression_data.dart';
import 'package:chordmaster_free/domain/theory/capo.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/chord_data.dart';

void main() {
  final names = {for (final c in loadChordJson()) c['displayName'] as String};

  test('nombre de acorde: tónica y sufijo', () {
    expect(chordRoot('F#m'), noteIndex('F#'));
    expect(chordSuffix('F#m'), 'm');
    expect(chordRoot('C'), 0);
    expect(chordSuffix('A7'), '7');
  });

  test('el capo sube la forma un semitono por traste', () {
    expect(soundingChord('G', 2), 'A');
    expect(soundingChord('Am', 3), 'Cm');
    expect(soundingChord('E', 12), 'E');
  });

  test('E mayor: forma E sin capo, D en el 2, C en el 4 y A en el 7', () {
    expect(capoOptions(noteIndex('E')), const [
      CapoOption(fret: 0, shape: 'E'),
      CapoOption(fret: 2, shape: 'D'),
      CapoOption(fret: 4, shape: 'C'),
      CapoOption(fret: 7, shape: 'A'),
    ]);
  });

  test('cada opción suena en la tonalidad pedida y no pasa del traste 7', () {
    for (var key = 0; key < 12; key++) {
      for (final minor in [false, true]) {
        final options = capoOptions(key, minor: minor);
        expect(options, isNotEmpty, reason: '$key $minor');
        for (final o in options) {
          expect(o.fret, inInclusiveRange(0, comfortableCapoFret));
          expect(chordRoot(soundingChord(o.shape, o.fret)), key);
        }
        final frets = options.map((o) => o.fret).toList();
        expect(frets, [...frets]..sort());
      }
    }
  });

  test('las cinco formas mayores cubren cualquier tonalidad sin pasar del 7', () {
    // C, D, E, G y A quedan a 2 o 3 semitonos entre sí: nunca hay un hueco de 8.
    final roots = majorShapes.map(chordRoot).toList()..sort();
    final gaps = [
      for (var i = 0; i < roots.length; i++)
        (roots[(i + 1) % roots.length] - roots[i]) % 12,
    ];
    expect(gaps.every((g) => g <= comfortableCapoFret + 1), isTrue);
  });

  test('I – IV – V con la forma G y capo 2: G C D suenan A D E', () {
    expect(capoProgression('G', 2), [
      (shape: 'G', sounds: 'A'),
      (shape: 'C', sounds: 'D'),
      (shape: 'D', sounds: 'E'),
    ]);
    expect(capoProgression('Am', 5).map((c) => c.sounds), ['Dm', 'Gm', 'Am']);
  });

  test('todas las formas de la progresión existen en la biblioteca', () {
    for (final shape in [...majorShapes, ...minorShapes]) {
      for (final c in capoProgression(shape, 0)) {
        expect(names, contains(c.shape), reason: shape);
      }
    }
  });

  group('girar una progresión', () {
    List<({int semitones, String type})> degreesOf(Progression p) => [
      for (final d in p.degrees) (semitones: d.semitones, type: d.type),
    ];

    test('I – V – vi – IV en A con la forma de G en el 2: G D Em C suena A E F#m D', () {
      final p = majorProgressions.firstWhere((p) => p.label == 'I - V - vi - IV');
      expect(chordsInKey(degreesOf(p), noteIndex('A')), ['A', 'E', 'F#m', 'D']);
      final t = capoTransposition(
        degreesOf(p),
        const CapoOption(fret: 2, shape: 'G'),
      );
      expect(t.shapes, ['G', 'D', 'Em', 'C']);
      expect(t.sounds, ['A', 'E', 'F#m', 'D']);
    });

    test('con cada forma y en cada tonalidad suena la progresión pedida', () {
      for (final p in majorProgressions) {
        for (var key = 0; key < 12; key++) {
          for (final o in capoOptions(key)) {
            final t = capoTransposition(degreesOf(p), o);
            expect(t.sounds, chordsInKey(degreesOf(p), key), reason: '${p.id} $o');
            for (final shape in t.shapes) {
              expect(names, contains(shape), reason: '${p.id} $o $shape');
            }
          }
        }
      }
    });

    test('los sufijos salen del tipo', () {
      expect(chordTypeSuffix('major'), '');
      expect(chordTypeSuffix('minor'), 'm');
      expect(chordTypeSuffix('diminished'), 'dim');
    });
  });
}
