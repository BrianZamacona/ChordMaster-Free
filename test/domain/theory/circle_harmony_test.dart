import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/theory/circle_harmony.dart';
import 'package:chordmaster_free/domain/theory/circle_of_fifths.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:chordmaster_free/domain/theory/scale_insights.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final master = jsonDecode(File('assets/data/scales_master.json').readAsStringSync()) as Map;
  final modeIntervals = {
    for (final m in master['modes'] as List) (m as Map)['id'] as String: (m['intervals'] as List).cast<int>(),
  };
  final chordTypes = {
    for (final c in (jsonDecode(File('assets/data/chords.json').readAsStringSync()) as List))
      (c as Map)['type'] ?? c['quality'],
  };
  String name(int pc) => pitchClassName(pc);
  Set<int> major(int t) => {for (final i in majorScale) (t + i) % 12};

  test('paso en el círculo: a la derecha positivo, a la izquierda negativo', () {
    expect(circleStep(0, 7), 1); // C → G
    expect(circleStep(0, 5), -1); // C → F
    expect(circleStep(0, 6), 6); // C → F#
    expect(circleStep(7, 0), -1);
  });

  group('dominantes secundarias', () {
    test('en C: A7→Dm, B7→Em, C7→F, D7→G, E7→Am', () {
      final d = secondaryDominants(0);
      expect([for (final s in d) '${s.dominant.numeral}=${name(s.dominant.root)}7→${s.target.numeral}'], [
        'VI7=A7→ii',
        'VII7=B7→iii',
        'I7=C7→IV',
        'II7=D7→V',
        'III7=E7→vi',
      ]);
    });

    test('en las 12 tonalidades: el dominante es el vecino de la derecha y su raíz está una quinta arriba', () {
      for (var t = 0; t < 12; t++) {
        for (final s in secondaryDominants(t)) {
          expect(circleStep(s.target.root, s.dominant.root), 1);
          expect((s.dominant.root - s.target.root) % 12, 7);
          expect(s.dominant.type, 'dominant7');
        }
      }
    });

    test('la cadena III7–VI7–II7–V7–I baja un paso a la izquierda cada vez', () {
      for (var t = 0; t < 12; t++) {
        final chain = dominantChain(t);
        expect(chain.map((c) => c.numeral), ['III7', 'VI7', 'II7', 'V7', 'I']);
        for (var i = 1; i < chain.length; i++) {
          expect(circleStep(chain[i - 1].root, chain[i].root), -1);
        }
        expect(chain.last.root, t);
      }
      expect([for (final c in dominantChain(0)) name(c.root)], ['E', 'A', 'D', 'G', 'C']);
    });

    test('ii–V–I son tres posiciones seguidas, contra reloj', () {
      for (var t = 0; t < 12; t++) {
        final c = twoFiveOne(t);
        expect(circleStep(c[0].root, c[1].root), -1);
        expect(circleStep(c[1].root, c[2].root), -1);
      }
      expect([for (final c in twoFiveOne(0)) name(c.root)], ['D', 'G', 'C']);
    });

    test('todos los tipos existen en chords.json', () {
      final types = {
        for (var t = 0; t < 12; t++) ...[
          for (final s in secondaryDominants(t)) s.dominant.type,
          for (final c in [...dominantChain(t), ...twoFiveOne(t), ...borrowedChords(t)]) c.type,
        ],
      };
      expect(chordTypes, containsAll(types));
    });
  });

  group('modulación', () {
    test('C → G: un paso, seis notas comunes y los pivotes C, Em, G y Am', () {
      final m = modulation(0, 7);
      expect(m.steps, 1);
      expect(m.commonNotes.map(name), ['C', 'D', 'E', 'G', 'A', 'B']);
      expect([for (final p in m.pivots) '${p.numeralInFrom}=${p.numeralInTo}'], ['I=IV', 'iii=vi', 'V=I', 'vi=ii']);
    });

    test('en todos los pares: notas comunes = escalas, y cada pivote es diatónico en las dos', () {
      for (var a = 0; a < 12; a++) {
        for (var b = 0; b < 12; b++) {
          final m = modulation(a, b);
          expect(m.commonNotes.toSet(), major(a).intersection(major(b)));
          expect(m.commonNotes.length, commonNoteCount(a, b));
          expect(m.steps.abs(), circleDistance(a, b));
          for (final p in m.pivots) {
            expect(diatonicByDegree(a).any((c) => c.root == p.root && c.type == p.type), isTrue);
            expect(diatonicByDegree(b).any((c) => c.root == p.root && c.type == p.type), isTrue);
          }
        }
      }
    });

    test('a la misma tonalidad, todo es común; lejos, quedan pocos pivotes', () {
      expect(modulation(4, 4).pivots, hasLength(7));
      expect(modulation(0, 6).pivots, isEmpty);
    });
  });

  group('intercambio modal', () {
    test('la menor paralela está tres pasos a la izquierda (C menor = armadura de D#, 3 ♭)', () {
      for (var t = 0; t < 12; t++) {
        expect(circleOrder[parallelMinorIndex(t)], (t + 3) % 12);
        expect(relativeMinorOf(circleOrder[parallelMinorIndex(t)]), t);
      }
      expect(keySignatureAt(parallelMinorIndex(0)).short, '3 ♭');
    });

    test('en C se piden Fm, G# y A# (iv, ♭VI, ♭VII), con sostenidos', () {
      final b = borrowedChords(0);
      expect([for (final c in b) '${c.numeral} ${name(c.root)} ${c.type}'], [
        'iv F minor',
        'bVI G# major',
        'bVII A# major',
      ]);
    });

    test('son de la menor paralela y no de la mayor', () {
      for (var t = 0; t < 12; t++) {
        final minor = {for (final i in naturalMinorScale) (t + i) % 12};
        for (final c in borrowedChords(t)) {
          expect(minor, contains(c.root));
          expect(diatonicByDegree(t).any((d) => d.root == c.root && d.type == c.type), isFalse);
        }
      }
    });
  });

  group('modos por brillo', () {
    test('lidio → locrio, un paso a la izquierda cada vez, desde +1 hasta −5', () {
      final m = modesByBrightness(0);
      expect(m.map((s) => s.modeId), ['lydian', 'ionian', 'mixolydian', 'dorian', 'aeolian', 'phrygian', 'locrian']);
      expect(m.map((s) => s.steps), [1, 0, -1, -2, -3, -4, -5]);
      expect(m.map((s) => name(s.parent)), ['G', 'C', 'F', 'A#', 'D#', 'G#', 'C#']);
    });

    test('cada modo es el de scales_master.json y sale de su mayor', () {
      for (var t = 0; t < 12; t++) {
        for (final s in modesByBrightness(t)) {
          expect(s.intervals, modeIntervals[s.modeId], reason: s.modeId);
          expect({for (final i in s.intervals) (t + i) % 12}, major(s.parent));
        }
      }
    });

    test('cada paso cambia una sola nota: #4, 4, b7, b3, b6, b2, b5', () {
      expect(modesByBrightness(0).map((s) => s.changed), ['#4', '4', 'b7', 'b3', 'b6', 'b2', 'b5']);
    });
  });
}
