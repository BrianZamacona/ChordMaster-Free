import 'package:chordmaster_free/domain/theory/circle_of_fifths.dart';
import 'package:chordmaster_free/domain/theory/harmony.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:chordmaster_free/domain/theory/scale_insights.dart';
import 'package:flutter_test/flutter_test.dart';

Set<int> _scaleOf(int tonic) => {for (final i in majorScale) (tonic + i) % 12};

const _cMajor = 0;

void main() {
  group('orden', () {
    test('las 12 tónicas salen de sumar quintas desde C', () {
      expect(
        [for (final pc in circleOrder) noteNames[pc]],
        ['C', 'G', 'D', 'A', 'E', 'B', 'F#', 'C#', 'G#', 'D#', 'A#', 'F'],
      );
      expect(circleOrder.toSet(), hasLength(12));
    });

    test(
      'la relativa menor está 9 semitonos arriba y usa las mismas notas',
      () {
        expect(noteNames[relativeMinorOf(0)], 'A');
        expect(noteNames[relativeMinorOf(7)], 'E');
        for (final tonic in circleOrder) {
          final minor = {
            for (final i in naturalMinorScale)
              (relativeMinorOf(tonic) + i) % 12,
          };
          expect(minor, _scaleOf(tonic));
        }
      },
    );

    test('circleIndexOf es la inversa de circleOrder', () {
      for (var i = 0; i < 12; i++) {
        expect(circleIndexOf(circleOrder[i]), i);
      }
      expect(circleIndexOf(19), 1, reason: 'reduce módulo 12');
    });
  });

  group('armadura', () {
    test('lado derecho ♯, lado izquierdo ♭', () {
      expect(
        [for (var i = 0; i < 12; i++) keySignatureAt(i).short],
        [
          '0',
          '1 ♯',
          '2 ♯',
          '3 ♯',
          '4 ♯',
          '5 ♯',
          '6 ♯',
          '5 ♭',
          '4 ♭',
          '3 ♭',
          '2 ♭',
          '1 ♭',
        ],
      );
    });

    test('la cantidad coincide con las notas fuera de C mayor', () {
      for (var i = 0; i < 12; i++) {
        final outside = _scaleOf(circleOrder[i]).difference(_scaleOf(_cMajor));
        final count = keySignatureAt(i).count;
        // En F# el 6º sostenido es E#, que suena como F, nota de C mayor.
        expect(
          outside,
          hasLength(count == 6 ? 5 : count),
          reason: 'posición $i',
        );
      }
    });

    test('solo F# es enarmónica, de 6 ♭', () {
      for (var i = 0; i < 12; i++) {
        expect(keySignatureAt(i).isEnharmonic, i == 6);
      }
      expect(noteNames[circleOrder[6]], 'F#');
      expect(keySignatureAt(6).name.es, contains('enarmónica de 6 bemoles'));
      expect(keySignatureAt(6).name.en, contains('enharmonic with 6 flats'));
    });

    test('el nombre largo concuerda en número', () {
      expect(keySignatureAt(0).name.es, 'sin alteraciones');
      expect(keySignatureAt(1).name.es, '1 sostenido');
      expect(keySignatureAt(1).name.en, '1 sharp');
      expect(keySignatureAt(2).name.es, '2 sostenidos');
      expect(keySignatureAt(11).name.es, '1 bemol');
      expect(keySignatureAt(9).name.en, '3 flats');
    });

    test('ninguna tonalidad se nombra con bemol', () {
      for (final pc in circleOrder) {
        expect(noteNames[pc], isNot(contains('b')));
      }
    });
  });

  group('regla de construcción', () {
    test('a la derecha, el ♯ nuevo es la 7ª de la nueva tonalidad', () {
      expect(addedAccidentalAt(0), isNull);
      final notes = <String>[];
      for (var i = 1; i <= 6; i++) {
        final added = addedAccidentalAt(i)!;
        final tonic = circleOrder[i];
        expect(added.accidental, Accidental.sharp);
        expect(added.degree, 7);
        expect((added.pitchClass - tonic) % 12, 11, reason: 'la 7ª mayor');
        expect(_scaleOf(tonic), contains(added.pitchClass));
        expect(_scaleOf(circleOrder[i - 1]), isNot(contains(added.pitchClass)));
        notes.add(noteNames[added.pitchClass]);
      }
      expect(notes, ['F#', 'C#', 'G#', 'D#', 'A#', 'F']);
    });

    test('a la izquierda, el ♭ nuevo es la 4ª de la nueva tonalidad', () {
      final notes = <String>[];
      for (var i = 11; i >= 7; i--) {
        final added = addedAccidentalAt(i)!;
        final tonic = circleOrder[i];
        expect(added.accidental, Accidental.flat);
        expect(added.degree, 4);
        expect((added.pitchClass - tonic) % 12, 5, reason: 'la 4ª justa');
        expect(_scaleOf(tonic), contains(added.pitchClass));
        expect(
          _scaleOf(circleOrder[(i + 1) % 12]),
          isNot(contains(added.pitchClass)),
        );
        notes.add(noteNames[added.pitchClass]);
      }
      expect(notes, ['A#', 'D#', 'G#', 'C#', 'F#']);
    });
  });

  group('ventana diatónica', () {
    test('C: IV I V afuera, ii vi iii adentro, vii° aparte', () {
      final window = diatonicWindow(0);
      expect(
        [for (final c in window) '${c.numeral}:${noteNames[c.root]}'],
        ['IV:F', 'I:C', 'V:G', 'ii:D', 'vi:A', 'iii:E', 'vii°:B'],
      );
      expect(
        [for (final c in window) c.place],
        [
          ...List.filled(3, WindowPlace.outerRing),
          ...List.filled(3, WindowPlace.innerRing),
          WindowPlace.outside,
        ],
      );
    });

    test('en las 12 tonalidades coincide con diatonicTriads de majorScale', () {
      final triads = diatonicTriads(majorScale);
      for (final tonic in circleOrder) {
        final window = diatonicByDegree(tonic);
        expect(window, hasLength(7));
        for (var d = 0; d < 7; d++) {
          expect(window[d].numeral, triads[d].numeral);
          expect((window[d].root - tonic) % 12, triads[d].semitones);
          expect(window[d].type, triads[d].type);
          expect(harmonicFunction(window[d].numeral), isA<HarmonicFunction>());
        }
      }
    });

    test('adentro están las relativas de los de afuera', () {
      for (final tonic in circleOrder) {
        final window = diatonicWindow(tonic);
        for (var i = 0; i < 3; i++) {
          expect(window[i + 3].root, relativeMinorOf(window[i].root));
          expect(window[i + 3].offset, window[i].offset);
        }
      }
    });

    test('la cadencia es I – IV – V – I, y V → I es la auténtica', () {
      expect(
        [for (final d in cadenceProgression.degrees) d.numeral],
        ['I', 'IV', 'V', 'I'],
      );
      expect(cadence('V', 'I')!.en, contains('authentic'));
    });
  });

  group('distancia', () {
    test('cuenta pasos por el lado corto', () {
      expect(circleDistance(0, 0), 0);
      expect(circleDistance(0, 7), 1);
      expect(circleDistance(0, 5), 1, reason: 'C y F, a la izquierda');
      expect(circleDistance(0, 6), 6);
      expect(circleDistance(5, 7), 2);
      for (final a in circleOrder) {
        for (final b in circleOrder) {
          expect(circleDistance(a, b), circleDistance(b, a));
          expect(circleDistance(a, b), inInclusiveRange(0, 6));
        }
      }
    });

    test('notas en común: 7 − distancia hasta 5; a 6 son 2, no 1', () {
      for (final a in circleOrder) {
        for (final b in circleOrder) {
          final d = circleDistance(a, b);
          expect(commonNoteCount(a, b), d == 6 ? 2 : 7 - d, reason: '$a, $b');
        }
      }
    });

    test('C y F# comparten exactamente B y F', () {
      final shared = _scaleOf(0).intersection(_scaleOf(6));
      expect({for (final pc in shared) noteNames[pc]}, {'B', 'F'});
    });
  });

  group('mástil', () {
    test(
      'una cuarta: mismo traste en la cuerda siguiente, salvo G → B (+1)',
      () {
        for (var s = 1; s <= 5; s++) {
          final isGtoB = standardOpenStringMidi[s] % 12 == noteIndex('G');
          expect(fourthFretShift(s), isGtoB ? 1 : 0, reason: 'cuerda $s');
        }
      },
    );

    test('una quinta: 2 trastes arriba, salvo G → B (+3)', () {
      for (var s = 1; s <= 5; s++) {
        final isGtoB = standardOpenStringMidi[s] % 12 == noteIndex('G');
        expect(fifthFretShift(s), isGtoB ? 3 : 2, reason: 'cuerda $s');
      }
    });

    test('la forma suena de verdad a 5 y a 7 semitonos', () {
      for (var s = 1; s <= 5; s++) {
        for (var fret = 0; fret < 12; fret++) {
          final from = standardOpenStringMidi[s] + fret;
          expect(
            standardOpenStringMidi[s - 1] + fret + fourthFretShift(s) - from,
            5,
          );
          expect(
            standardOpenStringMidi[s - 1] + fret + fifthFretShift(s) - from,
            7,
          );
        }
      }
    });

    test('fifthOnNeck ubica la tónica y su quinta', () {
      for (final tonic in circleOrder) {
        final p = fifthOnNeck(tonic);
        expect((standardOpenStringMidi[p.string] + p.fret) % 12, tonic);
        expect(
          (standardOpenStringMidi[p.nextString] + p.nextFret) % 12,
          (tonic + perfectFifth) % 12,
        );
        expect(p.nextString, p.string - 1);
      }
      final c = fifthOnNeck(0);
      expect((c.fret, c.nextFret), (8, 10), reason: 'C y G en 6ª y 5ª cuerda');
    });

    test('la frase de la regla dice lo que calcula el dominio', () {
      expect(fifthFretShift(5), 2);
      expect(fourthFretShift(5), 0);
      expect(fifthShapeRule.es, contains('2 trastes arriba'));
      expect(fifthShapeRule.es, contains('3 si pasas de G a B'));
      expect(fifthShapeRule.en, contains('3 going from G to B'));
    });
  });

  group('rueda', () {
    test('ángulo → tonalidad en la ventana', () {
      expect(indexAtWindow(0), 0);
      expect(indexAtWindow(-30), 1, reason: 'girar a la izquierda trae a G');
      expect(indexAtWindow(30), 11, reason: 'girar a la derecha trae a F');
      expect(indexAtWindow(-360), 0);
      expect(indexAtWindow(-14), 0);
      expect(indexAtWindow(-16), 1);
      expect(indexAtWindow(725), 0, reason: 'dos vueltas y 5°');
      for (var i = 0; i < 12; i++) {
        expect(indexAtWindow(rotationForIndex(i)), i);
      }
    });

    test('el acomodo da un múltiplo exacto de 30°', () {
      expect(snapRotation(14), 0);
      expect(snapRotation(16), 30);
      expect(snapRotation(-46), -60);
      expect(snapRotation(733.7), 720);
      expect(snapRotation(1234.5678) % 30, 0);
    });

    test('camino más corto, incluido el cruce 11 → 0', () {
      expect(shortestSteps(11, 0), 1);
      expect(shortestSteps(0, 11), -1);
      expect(shortestSteps(0, 1), 1);
      expect(shortestSteps(3, 3), 0);
      expect(shortestSteps(10, 1), 3);
      expect(shortestSteps(1, 10), -3);
      expect(
        shortestSteps(0, 6),
        6,
        reason: 'empate: sentido horario de índices',
      );
    });

    test('rotationToward llega por el camino corto', () {
      expect(rotationToward(-330, 0), -360, reason: 'de 11 a 0, un solo paso');
      expect(indexAtWindow(rotationToward(-330, 0)), 0);
      expect(rotationToward(0, 11), 30);
      for (var from = 0; from < 12; from++) {
        for (var to = 0; to < 12; to++) {
          final start = rotationForIndex(from);
          final end = rotationToward(start, to);
          expect(indexAtWindow(end), to);
          expect((end - start).abs(), lessThanOrEqualTo(180));
        }
      }
    });

    test('clics entre dos ángulos: uno por tonalidad que pasa', () {
      expect(clicksBetween(0, 10), 0);
      expect(clicksBetween(0, 16), 1);
      expect(clicksBetween(14, 16), 1);
      expect(clicksBetween(0, 90), 3);
      expect(clicksBetween(90, 0), 3);
      expect(clicksBetween(-20, 20), 2);
      expect(clicksBetween(0, 360), 12);
    });

    test('el ángulo del toque sale de la posición respecto al centro', () {
      expect(touchAngle(0, -1), 0, reason: 'arriba');
      expect(touchAngle(1, 0), 90, reason: 'derecha');
      expect(touchAngle(0, 1), 180, reason: 'abajo');
      expect(touchAngle(-1, 0), -90, reason: 'izquierda');
    });

    test('la diferencia de ángulos cruza ±180 por el lado corto', () {
      expect(angleDelta(170, -170), 20);
      expect(angleDelta(-170, 170), -20);
      expect(angleDelta(10, 40), 30);
      expect(angleDelta(40, 10), -30);
    });

    test('el toque elige la tonalidad que está debajo, girada o no', () {
      expect(indexAtTouch(0, 0), 0);
      expect(indexAtTouch(30, 0), 1, reason: 'a la derecha de C está G');
      expect(indexAtTouch(-30, 0), 11, reason: 'a la izquierda de C está F');
      expect(indexAtTouch(0, -30), 1, reason: 'G ya está arriba');
      expect(indexAtTouch(30, -30), 2);
    });

    test('velocidad angular: horario positiva, 0 en el centro', () {
      expect(angularVelocity(0, -100, 100, 0), greaterThan(0));
      expect(angularVelocity(0, -100, -100, 0), lessThan(0));
      expect(angularVelocity(100, 0, 0, 100), greaterThan(0));
      expect(angularVelocity(0, -100, 0, 100), 0, reason: 'radial no gira');
      expect(angularVelocity(0, 0, 100, 100), 0);
      expect(angularVelocity(0, -100, 100, 0), closeTo(57.3, 0.1));
    });
  });

  group('construcción paso a paso', () {
    final steps = circleConstruction();

    test('son 13 pasos de +7 semitonos que vuelven a C', () {
      expect(steps, hasLength(13));
      expect(steps.first.tonic, 0);
      expect(steps.first.previousTonic, isNull);
      expect(steps.last.tonic, 0);
      for (final s in steps.skip(1)) {
        expect((s.tonic - s.previousTonic!) % 12, perfectFifth);
      }
    });

    test('el texto nombra la suma, la alteración y su grado', () {
      expect(steps[0].explanation.es, 'Empezamos en C: sin alteraciones.');
      expect(
        steps[1].explanation.es,
        'C + 7 semitonos = G. Agrega un ♯ en F#, la 7ª de G. Armadura: 1 sostenido.',
      );
      expect(
        steps[1].explanation.en,
        'C + 7 semitones = G. It adds a ♯ on F#, the 7th of G. Key signature: 1 sharp.',
      );
      expect(steps[2].explanation.es, contains('♯ en C#, la 7ª de D'));
    });

    test('el 6º sostenido cae en F, escrito E#, y F# es enarmónica', () {
      expect(steps[6].explanation.es, contains('♯ en F (se escribe E#)'));
      expect(steps[6].explanation.en, contains('♯ on F (written E#)'));
      expect(steps[6].explanation.es, contains('enarmónica de 6 bemoles'));
      expect((noteIndex('F') - noteIndex('F#')) % 12, 11);
    });

    test('del lado de los ♭ explica el paso a la izquierda', () {
      expect(
        steps[7].explanation.es,
        contains(
          'desde G#, un paso a la izquierda agrega un ♭ en F#, la 4ª de C#',
        ),
      );
      expect(
        steps[11].explanation.es,
        contains(
          'desde C, un paso a la izquierda agrega un ♭ en A#, la 4ª de F',
        ),
      );
      expect(steps[11].explanation.es, contains('1 bemol'));
    });

    test('el último paso cierra el círculo tras 12 quintas', () {
      expect(steps[12].explanation.es, startsWith('F + 7 semitonos = C'));
      expect(steps[12].explanation.es, contains('12 quintas'));
      expect((12 * perfectFifth) % 12, 0);
    });

    test('ningún texto nombra una nota con bemol', () {
      final flatNote = RegExp(r'\b[A-G]b\b');
      for (final s in steps) {
        expect(flatNote.hasMatch(s.explanation.es), isFalse);
        expect(flatNote.hasMatch(s.explanation.en), isFalse);
      }
    });
  });
}
