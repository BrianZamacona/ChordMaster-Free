import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/core/constants/scale_names.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/theory/intervals.dart';
import 'package:chordmaster_free/domain/theory/scale_insights.dart';
import 'package:chordmaster_free/ui/scales/detail/widgets/scale_theory_cards.dart';
import 'package:flutter_test/flutter_test.dart';

const dorian = [0, 2, 3, 5, 7, 9, 10];
const mixolydian = [0, 2, 4, 5, 7, 9, 10];
const lydian = [0, 2, 4, 6, 7, 9, 11];
const harmonicMinor = [0, 2, 3, 5, 7, 8, 11];
const pentMinor = [0, 3, 5, 7, 10];
const pentMajor = [0, 2, 4, 7, 9];
const blues = [0, 3, 5, 6, 7, 10];
const wholeTone = [0, 2, 4, 6, 8, 10];
const dimHalfWhole = [0, 1, 3, 4, 6, 7, 9, 10];

void main() {
  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  test('pasos: mayor T T S T T T S; armónica con tono y medio', () {
    expect(stepPattern(majorScale), [2, 2, 1, 2, 2, 2, 1]);
    expect(stepPatternLabel(majorScale), 'T T S T T T S');
    expect(stepPatternLabel(harmonicMinor), 'T S T T S T+S S');
    CurrentLanguage.value = AppLanguage.en;
    expect(stepPatternLabel(majorScale), 'W W H W W W H');
  });

  test('nota característica de cada modo frente a mayor o menor', () {
    String describe(List<int> s) => describeComparison(compareScale(s)!, s);
    expect(describe(dorian), startsWith('Es la menor natural con 6 en vez de b6.'));
    expect(describe(mixolydian), startsWith('Es la escala mayor con b7 en vez de 7.'));
    expect(describe(lydian), startsWith('Es la escala mayor con #4 en vez de 4.'));
    expect(describe(harmonicMinor), startsWith('Es la menor natural con 7 en vez de b7.'));
    expect(describe(pentMinor), startsWith('Es la menor natural sin 2 ni b6'));
    expect(describe(pentMajor), startsWith('Es la escala mayor sin 4 ni 7'));
    expect(describe(blues), startsWith('Es la pentatónica menor con b5 añadida'));
    expect(compareScale(majorScale), isNull);
    expect(compareScale(naturalMinorScale), isNull);
    expect(compareScale(wholeTone), isNull);
  });

  test('simétricas: tonos enteros cada 2 trastes, disminuida cada 3', () {
    expect(symmetryPeriod(wholeTone), 2);
    expect(symmetryPeriod(dimHalfWhole), 3);
    expect(symmetryPeriod(majorScale), isNull);
  });

  test('acordes sobre la tónica: solo los que caben en la escala', () {
    final major = chordTypesOnTonic(majorScale);
    expect(major, containsAll(['major', 'major7', 'sus2', 'sus4', 'sixth', 'major9']));
    expect(major, isNot(contains('dominant7')));
    expect(major, isNot(contains('minor')));
    final pent = chordTypesOnTonic(pentMinor);
    expect(pent, containsAll(['minor', 'minor7', 'sus4', 'power5']));
    expect(pent, isNot(contains('major')));
    expect(chordTypesOnTonic(mixolydian), contains('dominant7'));
  });

  test('acordes diatónicos con su número romano', () {
    expect([for (final c in diatonicTriads(majorScale)) c.numeral],
        ['I', 'ii', 'iii', 'IV', 'V', 'vi', 'vii°']);
    expect([for (final c in diatonicTriads(naturalMinorScale)) c.numeral],
        ['i', 'ii°', 'bIII', 'iv', 'v', 'bVI', 'bVII']);
    expect([for (final c in diatonicTriads(harmonicMinor)) c.numeral],
        ['i', 'ii°', 'bIII+', 'iv', 'V', 'bVI', 'vii°']);
    expect(diatonicTriads(pentMinor), isEmpty);
  });

  test('escalas para un acorde: solo las que contienen todas sus notas', () {
    final data =
        jsonDecode(File('assets/data/scales_master.json').readAsStringSync())
            as Map<String, dynamic>;
    final all = {
      for (final g in ['scales', 'modes'])
        for (final raw in data[g] as List<dynamic>)
          (raw as Map<String, dynamic>)['id'] as String:
              (raw['intervals'] as List<dynamic>).cast<int>(),
    };
    final dim = scalesForChord([0, 3, 6], all);
    expect(dim, containsAll(['locrian', 'diminished_wh', 'diminished_hw']));
    expect(dim, isNot(contains('whole_tone'))); // no tiene b3
    final m6 = scalesForChord([0, 3, 7, 9], all);
    expect(m6, containsAll(['dorian', 'melodic_minor']));
    expect(m6, isNot(contains('natural_minor'))); // su b6 choca con la 6
    expect(scalesForChord([0, 4, 7, 11, 18], all), ['lydian']);
  });

  test('disminuidas: el nombre sale de los intervalos, no del id', () {
    expect(scaleDisplayName('diminished_hw', dimHalfWhole), 'Disminuida semitono-tono');
    expect(scaleDisplayName('x', [0, 2, 3, 5, 6, 8, 9, 11]), 'Disminuida tono-semitono');
    CurrentLanguage.value = AppLanguage.en;
    expect(scaleDisplayName('dorian', dorian), 'Dorian');
    expect(scaleDisplayName('unknown', majorScale, fallback: 'X'), 'X');
  });

  test('cada escala y modo del JSON tiene ideas de improvisación', () {
    final data =
        jsonDecode(File('assets/data/scales_master.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final g in ['scales', 'modes']) {
      for (final raw in data[g] as List<dynamic>) {
        final s = raw as Map<String, dynamic>;
        final intervals = (s['intervals'] as List<dynamic>).cast<int>();
        expect(
          improvisationTips(s['id'] as String, intervals),
          isNotNull,
          reason: s['id'] as String,
        );
        // Las notas que nombra la teoría existen en la escala.
        final labels = scaleDegreeLabels(intervals);
        final c = compareScale(intervals);
        if (c != null) {
          for (final i in c.added) {
            expect(labels, contains(spellInterval(i, intervals)));
          }
        }
      }
    }
  });
}
