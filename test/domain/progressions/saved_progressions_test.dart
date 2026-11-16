import 'package:chordmaster_free/domain/progressions/saved_progressions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const blues = SavedProgression(
    name: 'Blues',
    mode: 4,
    chords: [(numeral: 'I7', beats: 4), (numeral: 'IV7', beats: 2), (numeral: 'V7', beats: 2)],
  );

  test('se guarda y se vuelve a leer igual', () {
    final json = blues.toJson();
    expect(json, {'name': 'Blues', 'mode': 4, 'chords': ['I7', 'IV7@2', 'V7@2']});
    final back = SavedProgression.fromJson(json)!;
    expect((back.name, back.mode), (blues.name, blues.mode));
    expect(back.chords, blues.chords);
  });

  test('lo que no se puede leer se descarta', () {
    for (final bad in <Object?>[
      null,
      'Blues',
      {'name': '  ', 'mode': 0, 'chords': ['I']},
      {'name': 'x', 'mode': 9, 'chords': ['I']},
      {'name': 'x', 'mode': 0, 'chords': <String>[]},
      {'name': 'x', 'mode': 0, 'chords': ['I', 'X']},
      {'name': 'x', 'mode': 0, 'chords': ['I', 3]},
      {'name': 'x', 'mode': 0, 'chords': ['I@3']},
      {'name': 'x', 'mode': 0, 'chords': List.filled(9, 'I')},
    ]) {
      expect(SavedProgression.fromJson(bad), isNull, reason: '$bad');
    }
  });

  test('guardar con un nombre que ya está la reemplaza en su lugar; si no, va primero', () {
    const other = SavedProgression(name: 'Otra', mode: 0, chords: [(numeral: 'I', beats: 4)]);
    var saved = upsertSaved(const [], blues)!;
    saved = upsertSaved(saved, other)!;
    expect([for (final s in saved) s.name], ['Otra', 'Blues']);
    const renamed = SavedProgression(name: ' blues ', mode: 5, chords: [(numeral: 'i', beats: 4)]);
    saved = upsertSaved(saved, renamed)!;
    expect([for (final s in saved) (s.name, s.mode)], [('Otra', 0), (' blues ', 5)]);
  });

  test('no se guardan más de $savedProgressionsMax', () {
    var saved = <SavedProgression>[];
    for (var i = 0; i < savedProgressionsMax; i++) {
      saved = upsertSaved(saved, SavedProgression(name: 'p$i', mode: 0, chords: const [(numeral: 'I', beats: 4)]))!;
    }
    expect(upsertSaved(saved, blues), isNull);
    // Reemplazar una que ya está sí se puede.
    expect(upsertSaved(saved, const SavedProgression(name: 'P3', mode: 1, chords: [(numeral: 'i', beats: 4)])), isNotNull);
  });

  test('el nombre que se propone es el primero libre', () {
    final saved = [
      const SavedProgression(name: 'Mi progresión 1', mode: 0, chords: [(numeral: 'I', beats: 4)]),
      const SavedProgression(name: 'mi progresión 2', mode: 0, chords: [(numeral: 'I', beats: 4)]),
    ];
    expect(nextProgressionName(const [], 'Mi progresión'), 'Mi progresión 1');
    expect(nextProgressionName(saved, 'Mi progresión'), 'Mi progresión 3');
  });
}
