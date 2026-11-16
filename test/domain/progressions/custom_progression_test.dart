import 'package:chordmaster_free/domain/progressions/custom_progression.dart';
import 'package:chordmaster_free/domain/progressions/progression_builder.dart';
import 'package:chordmaster_free/domain/progressions/progression_data.dart';
import 'package:chordmaster_free/domain/theory/harmony.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/chord_data.dart';

void main() {
  List<String> numerals(int mode, {bool sevenths = false}) => [
    for (final d in customChordChoices(mode, sevenths: sevenths)) d.numeral,
  ];

  group('números romanos por regla', () {
    test('coinciden con las tablas de las progresiones de siempre', () {
      for (final n in allDegreeNumerals) {
        final d = Progression('x', '', [n]).degrees.single;
        expect(parseDegreeNumeral(n), (semitones: d.semitones, type: d.type), reason: n);
      }
    });

    test('las cuatríadas y las alteraciones', () {
      expect(parseDegreeNumeral('Imaj7'), (semitones: 0, type: 'major7'));
      expect(parseDegreeNumeral('ii7'), (semitones: 2, type: 'minor7'));
      expect(parseDegreeNumeral('viiø7'), (semitones: 11, type: 'halfDiminished'));
      expect(parseDegreeNumeral('vii°7'), (semitones: 11, type: 'diminished7'));
      expect(parseDegreeNumeral('♭VIImaj7'), (semitones: 10, type: 'major7'));
      expect(parseDegreeNumeral('♯iv°'), (semitones: 6, type: 'diminished'));
      expect(parseDegreeNumeral('♭III+'), (semitones: 3, type: 'augmented'));
      for (final bad in ['X', 'Iø7', 'vmaj7', 'I°', 'ii+', '♭', '']) {
        expect(parseDegreeNumeral(bad), isNull, reason: bad);
      }
    });
  });

  group('acordes de cada escala de base', () {
    test('la mayor: tríadas y cuatríadas de siempre', () {
      expect(numerals(0), ['I', 'ii', 'iii', 'IV', 'V', 'vi', 'vii°']);
      expect(numerals(0, sevenths: true), ['Imaj7', 'ii7', 'iii7', 'IVmaj7', 'V7', 'vi7', 'viiø7']);
    });

    test('la menor natural y los modos, contados desde su tónica', () {
      expect(numerals(5), ['i', 'ii°', '♭III', 'iv', 'v', '♭VI', '♭VII']);
      expect(numerals(5, sevenths: true), ['i7', 'iiø7', '♭IIImaj7', 'iv7', 'v7', '♭VImaj7', '♭VII7']);
      expect(numerals(1), ['i', 'ii', '♭III', 'IV', 'v', 'vi°', '♭VII']);
      expect(numerals(2), ['i', '♭II', '♭III', 'iv', 'v°', '♭VI', '♭vii']);
      expect(numerals(3), ['I', 'II', 'iii', '♯iv°', 'V', 'vi', 'vii']);
      expect(numerals(4), ['I', 'ii', 'iii°', 'IV', 'v', 'vi', '♭VII']);
      expect(numerals(6), ['i°', '♭II', '♭iii', 'iv', '♭V', '♭VI', '♭vii']);
    });

    test('cada acorde tiene solo notas de su escala, y su nombre se vuelve a leer igual', () {
      for (final mode in customBaseModes) {
        final scale = modeIntervals(mode).toSet();
        for (final sevenths in [false, true]) {
          final chords = customChordChoices(mode, sevenths: sevenths);
          expect([for (final c in chords) c.semitones], modeIntervals(mode), reason: '$mode');
          for (final c in chords) {
            expect(scale.containsAll(degreeChordTones(c)), isTrue, reason: '${c.numeral} en el modo $mode');
            expect(parseDegreeNumeral(c.numeral), (semitones: c.semitones, type: c.type));
            expect(isCustomNumeral(c.numeral), isTrue);
          }
        }
      }
    });

    test('todos tienen digitación en chords.json, en las 12 tónicas', () {
      final builder = ProgressionBuilder([for (final c in loadChordJson()) ChordFingerings.fromJson(c)]);
      for (final mode in customBaseModes) {
        for (final sevenths in [false, true]) {
          final p = Progression('custom', '', numerals(mode, sevenths: sevenths));
          for (var tonic = 0; tonic < 12; tonic++) {
            final layers = builder.layersFor(p, tonic);
            for (final (i, layer) in layers.indexed) {
              expect(layer, isNotEmpty, reason: '${p.degrees[i].numeral} en ${noteNames[tonic]} (modo $mode)');
            }
          }
        }
      }
    });
  });

  group('la teoría entiende las 7ª', () {
    test('función, frase y cadencia de su tríada', () {
      expect(functionOf('ii7'), HarmonicFunction.subdominant);
      expect(functionOf('Imaj7'), HarmonicFunction.tonic);
      expect(functionOf('viiø7'), HarmonicFunction.dominant);
      expect(degreeRoleOf('viiø7'), degreeRole('vii°'));
      expect(degreeRoleOf('♯iv°'), isNull);
      expect(cadence('V7', 'Imaj7'), cadence('V', 'I'));
      expect(cadence('IVmaj7', 'Imaj7'), cadence('IV', 'I'));
      // El IV7 → I7 del blues sigue sin contarse como plagal.
      expect(cadence('IV7', 'I7'), isNull);
    });

    test('las notas de la tríada de una cuatríada (notas en común)', () {
      final imaj7 = Progression('x', '', ['Imaj7']).degrees.single;
      final viiHalf = Progression('x', '', ['viiø7']).degrees.single;
      expect(degreeTriad(imaj7, 0), {0, 4, 7});
      expect(degreeChordTones(imaj7), {0, 4, 7, 11});
      expect(degreeTriad(viiHalf, 0), {11, 2, 5});
    });

    test('ii7 – V7 – Imaj7: recorrido con funciones y cadencia auténtica', () {
      final lines = [for (final l in explainProgression(Progression('custom', '', ['ii7', 'V7', 'Imaj7']), 0)) l.es];
      expect(lines.first, 'Recorrido: ii7 (preparación) → V7 (tensión) → Imaj7 (reposo).');
      expect(lines, contains(startsWith('V7 → Imaj7: cadencia auténtica')));
    });
  });
}
