import 'package:chordmaster_free/domain/progressions/saved_progressions.dart';
import 'package:chordmaster_free/domain/progressions/song.dart';
import 'package:flutter_test/flutter_test.dart';

SavedProgression _one(String name, {int mode = 0, String numeral = 'I'}) =>
    SavedProgression(name: name, mode: mode, sections: [[(numeral: numeral, beats: 4)]]);

void main() {
  const blues = SavedProgression(
    name: 'Blues',
    mode: 4,
    sections: [
      [(numeral: 'I7', beats: 4), (numeral: 'IV7', beats: 2), (numeral: 'V7', beats: 2)],
      [(numeral: 'IV7', beats: 8)],
    ],
    order: [0, 0, 1, 0],
  );

  test('se guarda y se vuelve a leer igual, con sus secciones y su orden', () {
    final json = blues.toJson();
    expect(json, {
      'name': 'Blues',
      'mode': 4,
      'sections': [
        ['I7', 'IV7@2', 'V7@2'],
        ['IV7@8'],
      ],
      'order': [0, 0, 1, 0],
    });
    final back = SavedProgression.fromJson(json)!;
    expect((back.name, back.mode), (blues.name, blues.mode));
    expect(back.sections, blues.sections);
    expect(back.order, blues.order);
  });

  test('las de antes, de una sola sección, se leen como la sección A', () {
    final old = SavedProgression.fromJson({
      'name': 'Vieja',
      'mode': 0,
      'chords': ['ii7', 'V7@2'],
    })!;
    expect(old.sections, [
      [(numeral: 'ii7', beats: 4), (numeral: 'V7', beats: 2)],
    ]);
    expect(old.order, [0]);
  });

  test('lo que no se puede leer se descarta', () {
    for (final bad in <Object?>[
      null,
      'Blues',
      {'name': '  ', 'mode': 0, 'sections': [['I']]},
      {'name': 'x', 'mode': 9, 'sections': [['I']]},
      {'name': 'x', 'mode': 0, 'sections': <Object>[]},
      {'name': 'x', 'mode': 0, 'sections': [<String>[]]},
      {'name': 'x', 'mode': 0, 'sections': [['I', 'X']]},
      {'name': 'x', 'mode': 0, 'sections': [['I', 3]]},
      {'name': 'x', 'mode': 0, 'sections': [['I@3']]},
      {'name': 'x', 'mode': 0, 'sections': [List.filled(9, 'I')]},
      {'name': 'x', 'mode': 0, 'sections': List.filled(songMaxSections + 1, ['I'])},
      {'name': 'x', 'mode': 0, 'sections': [['I']], 'order': [1]},
      {'name': 'x', 'mode': 0, 'sections': [['I']], 'order': <int>[]},
      {'name': 'x', 'mode': 0, 'sections': [['I']], 'order': List.filled(songMaxParts + 1, 0)},
    ]) {
      expect(SavedProgression.fromJson(bad), isNull, reason: '$bad');
    }
  });

  test('la canción que se arma puede tener una sección vacía; la guardada no', () {
    expect(parseSong([<String>[]], null, allowEmpty: true)?.sections, [<Object>[]]);
    expect(parseSong([<String>[]], null), isNull);
    final cleaned = withoutEmptySections([
      [(numeral: 'I', beats: 4)],
      [],
      [(numeral: 'V', beats: 4)],
    ], [0, 1, 2, 1]);
    expect(cleaned.sections, [
      [(numeral: 'I', beats: 4)],
      [(numeral: 'V', beats: 4)],
    ]);
    expect(cleaned.order, [0, 1]);
  });

  test('guardar con un nombre que ya está la reemplaza en su lugar; si no, va primero', () {
    var saved = upsertSaved(const [], blues)!;
    saved = upsertSaved(saved, _one('Otra'))!;
    expect([for (final s in saved) s.name], ['Otra', 'Blues']);
    saved = upsertSaved(saved, _one(' blues ', mode: 5, numeral: 'i'))!;
    expect([for (final s in saved) (s.name, s.mode)], [('Otra', 0), (' blues ', 5)]);
  });

  test('no se guardan más de $savedProgressionsMax', () {
    var saved = <SavedProgression>[];
    for (var i = 0; i < savedProgressionsMax; i++) {
      saved = upsertSaved(saved, _one('p$i'))!;
    }
    expect(upsertSaved(saved, blues), isNull);
    // Reemplazar una que ya está sí se puede.
    expect(upsertSaved(saved, _one('P3', mode: 1, numeral: 'i')), isNotNull);
  });

  test('el nombre que se propone es el primero libre', () {
    final saved = [_one('Mi progresión 1'), _one('mi progresión 2')];
    expect(nextProgressionName(const [], 'Mi progresión'), 'Mi progresión 1');
    expect(nextProgressionName(saved, 'Mi progresión'), 'Mi progresión 3');
  });

  group('la canción', () {
    test('cada acorde en el orden en que suena; una sección vacía no suena', () {
      expect(songTimeline([2, 1], [0, 1, 0]), [
        (part: 0, section: 0, chord: 0),
        (part: 0, section: 0, chord: 1),
        (part: 1, section: 1, chord: 0),
        (part: 2, section: 0, chord: 0),
        (part: 2, section: 0, chord: 1),
      ]);
      expect(songTimeline([2, 0], [1, 0]), [(part: 1, section: 0, chord: 0), (part: 1, section: 0, chord: 1)]);
    });

    test('quitar una sección quita sus partes y corre las letras de después', () {
      expect(orderWithoutSection([0, 1, 2, 1, 0], 1), [0, 1, 0]);
      expect(orderWithoutSection([1, 1], 1), [0]);
    });

    test('las letras', () {
      expect([for (var i = 0; i < songMaxSections; i++) sectionLetter(i)], ['A', 'B', 'C', 'D']);
      expect(songOrderLabel([0, 0, 1, 0]), 'A A B A');
    });
  });
}
