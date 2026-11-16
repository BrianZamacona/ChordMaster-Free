import 'package:chordmaster_free/domain/progressions/custom_progression.dart';
import 'package:chordmaster_free/domain/progressions/progression_builder.dart';
import 'package:chordmaster_free/domain/progressions/progression_data.dart';
import 'package:chordmaster_free/domain/theory/harmony.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/chord_data.dart';

void main() {
  const major = 0;
  const minor = 5;

  Map<String, String> byLabel(ChordSource s, int mode, {bool sevenths = false}) => {
    for (final c in chordsFrom(s, mode, sevenths: sevenths)) c.label: c.degree.numeral,
  };

  ProgressionDegree degree(String numeral) => Progression('x', '', [numeral]).degrees.single;

  test('el número romano por regla se vuelve a leer igual', () {
    const types = ['major', 'minor', 'diminished', 'augmented', 'major7', 'dominant7', 'minor7', 'halfDiminished', 'diminished7'];
    for (var s = 0; s < 12; s++) {
      for (final t in types) {
        for (final sharp in [false, true]) {
          expect(parseDegreeNumeral(spellDegree(s, t, sharp: sharp)), (semitones: s, type: t), reason: '$s $t');
        }
      }
    }
    expect(spellDegree(10, 'major'), '♭VII');
    expect(spellDegree(1, 'diminished7', sharp: true), '♯i°7');
  });

  test('de la escala: los mismos acordes que la escala de base', () {
    expect(
      [for (final c in chordsFrom(ChordSource.scale, major)) c.degree.numeral],
      [for (final d in customChordChoices(major)) d.numeral],
    );
  });

  group('dominantes secundarias', () {
    test('en la mayor: el V7 de cada grado, sin repetir el V7 de la escala', () {
      expect(byLabel(ChordSource.secondaryDominant, major), {
        'V7/ii': 'VI7',
        'V7/iii': 'VII7',
        'V7/IV': 'I7',
        'V7/V': 'II7',
        'V7/vi': 'III7',
      });
    });

    test('en la menor: el V7 de la tónica (el de la menor armónica) está', () {
      expect(byLabel(ChordSource.secondaryDominant, minor)['V7/i'], 'V7');
    });

    test('su 3ª sube medio tono a la raíz del grado (lo que dice el texto)', () {
      for (final mode in customBaseModes) {
        for (final c in chordsFrom(ChordSource.secondaryDominant, mode)) {
          final target = c.degree.semitones - 7;
          expect((c.degree.semitones + 4 + 1) % 12, target % 12, reason: c.label);
          expect(c.degree.type, 'dominant7');
        }
      }
    });
  });

  test('vii°7 secundarios en la mayor: medio tono debajo de cada grado, con ♯', () {
    expect(byLabel(ChordSource.leadingTone, major), {
      'vii°7/I': 'vii°7',
      'vii°7/ii': '♯i°7',
      'vii°7/iii': '♯ii°7',
      'vii°7/IV': 'iii°7',
      'vii°7/V': '♯iv°7',
      'vii°7/vi': '♯v°7',
    });
  });

  group('sustituto tritonal', () {
    test('en la mayor: medio tono arriba de cada grado, con ♭', () {
      expect(byLabel(ChordSource.tritoneSub, major), {
        'subV7/I': '♭II7',
        'subV7/ii': '♭III7',
        'subV7/iii': 'IV7',
        'subV7/IV': '♭V7',
        'subV7/V': '♭VI7',
        'subV7/vi': '♭VII7',
      });
    });

    test('comparte la 3ª y la 7ª del V7 al que reemplaza (lo que dice el texto)', () {
      for (final mode in customBaseModes) {
        for (final c in chordsFrom(ChordSource.tritoneSub, mode)) {
          final target = c.degree.semitones - 1;
          final dominant = ProgressionDegree('V7', (target + 7) % 12, 'dominant7');
          final shared = degreeChordTones(c.degree).intersection(degreeChordTones(dominant));
          expect(shared, {(target + 7 + 4) % 12, (target + 7 + 10) % 12}, reason: c.label);
        }
      }
    });
  });

  test('prestados en la mayor: los de las paralelas que no son de la escala', () {
    final borrowed = {for (final c in chordsFrom(ChordSource.borrowed, major)) c.degree.numeral: c.why.es};
    expect(borrowed['iv'], contains('la menor natural'));
    expect(borrowed['♭VI'], contains('la menor natural'));
    expect(borrowed['♭VII'], contains('la mixolidia'));
    expect(borrowed['♭III'], contains('la dórica'));
    expect(borrowed.keys, isNot(contains('IV')));
    // Cada uno es de la paralela que nombra.
    const names = ['la mayor', 'la dórica', 'la frigia', 'la lidia', 'la mixolidia', 'la menor natural', 'la locria'];
    for (final mode in customBaseModes) {
      for (final sevenths in [false, true]) {
        for (final c in chordsFrom(ChordSource.borrowed, mode, sevenths: sevenths)) {
          final from = names.indexWhere((n) => c.why.es.contains('de $n:'));
          expect(from, isNot(-1), reason: c.why.es);
          expect(
            customChordChoices(from, sevenths: sevenths).map((d) => d.numeral),
            contains(c.degree.numeral),
            reason: '${c.degree.numeral} en ${names[from]}',
          );
        }
      }
    }
  });

  group('armonía negativa', () {
    test('en la mayor: el reflejo de cada grado', () {
      expect(byLabel(ChordSource.negative, major), {
        'i ⇄ I': 'i',
        '♭VII ⇄ ii': '♭VII',
        '♭VI ⇄ iii': '♭VI',
        'v ⇄ IV': 'v',
        'iv ⇄ V': 'iv',
        '♭III ⇄ vi': '♭III',
        'ii° ⇄ vii°': 'ii°',
      });
      expect(byLabel(ChordSource.negative, major, sevenths: true)['♭VImaj7 ⇄ Imaj7'], '♭VImaj7');
      expect(byLabel(ChordSource.negative, major, sevenths: true)['iiø7 ⇄ V7'], 'iiø7');
    });

    test('reflejar dos veces deja el acorde igual, en todas las escalas', () {
      for (final mode in customBaseModes) {
        for (final sevenths in [false, true]) {
          for (final d in customChordChoices(mode, sevenths: sevenths)) {
            final m = negativeOf(d);
            final back = negativeOf(ProgressionDegree('x', m.semitones, m.type));
            expect(back, (semitones: d.semitones, type: d.type), reason: d.numeral);
          }
        }
      }
    });
  });

  test('todos los acordes de todas las fuentes existen en chords.json, en las 12 tónicas', () {
    final builder = ProgressionBuilder([for (final c in loadChordJson()) ChordFingerings.fromJson(c)]);
    for (final mode in customBaseModes) {
      for (final sevenths in [false, true]) {
        for (final source in ChordSource.values) {
          final chords = chordsFrom(source, mode, sevenths: sevenths);
          expect(chords, isNotEmpty, reason: '$source $mode');
          final p = Progression('custom', '', [for (final c in chords) c.degree.numeral]);
          for (var tonic = 0; tonic < 12; tonic++) {
            for (final (i, layer) in builder.layersFor(p, tonic).indexed) {
              expect(layer, isNotEmpty, reason: '${chords[i].label} en ${noteNames[tonic]}');
            }
          }
        }
      }
    }
  });

  test('ninguna fuente repite un acorde de la escala de base', () {
    for (final mode in customBaseModes) {
      final inBase = {
        for (final s in [false, true])
          for (final d in customChordChoices(mode, sevenths: s)) d.numeral,
      };
      for (final source in ChordSource.values.skip(1)) {
        for (final c in chordsFrom(source, mode)) {
          expect(inBase, isNot(contains(c.degree.numeral)), reason: '$source ${c.label}');
        }
      }
    }
  });

  test('sourcesOf: la fuente de un acorde de fuera; ninguna para los de la escala', () {
    expect(sourcesOf(degree('ii'), major), isEmpty);
    expect(sourcesOf(degree('VI7'), major).first.label, 'V7/ii');
    expect(sourcesOf(degree('♭VI'), major).first.why.es, contains('prestado'));
    // Las de dominante antes que el préstamo; el préstamo antes que el tritono.
    expect(sourcesOf(degree('V7'), minor).first.label, 'V7/i');
    expect(sourcesOf(degree('I7'), major).first.label, 'V7/IV');
    expect(sourcesOf(degree('♭VII7'), major).first.why.es, contains('prestado de la menor natural'));
  });

  test('en «¿Por qué?» un acorde de fuera no lleva la función de su número', () {
    final p = Progression('custom', '', ['I', 'I7', 'IV']);
    final plain = explainProgression(p, 0).first.es;
    final outside = explainProgression(p, 0, outside: {'I7'}).first.es;
    expect(plain, contains('I7 (reposo)'));
    expect(outside, 'Recorrido: I (reposo) → I7 → IV (preparación).');
  });
}
