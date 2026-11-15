import 'dart:math';

import 'package:chordmaster_free/domain/theory/fretboard_mastery.dart';
import 'package:chordmaster_free/domain/theory/fretboard_quiz.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const c = (string: 5, fret: 3);

  test('sin explorar → débil al fallar → en camino → dominado con 3 aciertos seguidos', () {
    var m = const FretMastery();
    expect(m.of(c), SpotMastery.unexplored);
    m = m.record(c, right: false);
    expect(m.of(c), SpotMastery.weak);
    expect(m.weak, {c});
    m = m.record(c, right: true).record(c, right: true);
    expect(m.of(c), SpotMastery.learning);
    expect(m.weak, isEmpty);
    m = m.record(c, right: true);
    expect(m.of(c), SpotMastery.mastered);
    // Un error lo vuelve débil aunque estuviera dominado.
    expect(m.record(c, right: false).of(c), SpotMastery.weak);
  });

  test('el mapa reparte los 78 lugares del 0 al 12 entre los cuatro estados', () {
    final m = const FretMastery().record(c, right: false).record((string: 1, fret: 0), right: true);
    final all = [for (final level in SpotMastery.values) ...m.spotsAt(level)];
    expect(all, hasLength(6 * 13));
    expect(m.spotsAt(SpotMastery.weak), {c});
    expect(m.spotsAt(SpotMastery.learning), {(string: 1, fret: 0)});
    expect(m.spotsAt(SpotMastery.unexplored), hasLength(76));
  });

  test('se guarda y se vuelve a leer igual; lo que no se entiende se descarta', () {
    final m = const FretMastery().record(c, right: true).record((string: 6, fret: 12), right: false);
    final back = FretMastery.fromJson(m.toJson());
    expect(back.spots, m.spots);
    final junk = FretMastery.fromJson({
      '5:3': [2, 1],
      '7:1': [1, 1],
      '1:13': [1, 0],
      'x': [1, 0],
      '2:2': [1, 3],
      '3:3': 'a',
    });
    expect(junk.spots.keys, [c]);
    expect(FretMastery.fromJson(null).spots, isEmpty);
  });

  group('el repaso', () {
    test('una de cada tres preguntas, más o menos, es sobre un lugar que costó', () {
      final rng = Random(4);
      final weak = {c, (string: 2, fret: 7)};
      final tested = [for (var i = 0; i < 3000; i++) testedSpot(nextFretQuestion(rng, const FretQuizFilter(), weak))];
      final share = tested.where(weak.contains).length / tested.length;
      // Un tercio de repaso, más lo que salga por azar.
      expect(share, inInclusiveRange(0.30, 0.40));
    });

    test('la pregunta de repaso es sobre ese lugar y tiene su respuesta', () {
      final rng = Random(9);
      for (var i = 0; i < 300; i++) {
        final q = reviewQuestion(rng, c);
        expect(testedSpot(q), c);
        expect(q.choices, contains(q.answer));
        expect(q.choices.toSet(), hasLength(fretQuizChoices));
        expect(q, isNot(isA<OctaveQuestion>()));
      }
    });

    test('un lugar fuera del filtro no se repasa', () {
      final rng = Random(1);
      const filter = FretQuizFilter(strings: {1, 2});
      for (var i = 0; i < 500; i++) {
        final spot = testedSpot(nextFretQuestion(rng, filter, {c}));
        expect(spot, isNot(c));
      }
    });

    test('lo que pone a prueba cada pregunta: el lugar marcado, el buscado o la octava', () {
      final rng = Random(3);
      for (var i = 0; i < 300; i++) {
        final q = nextFretQuestion(rng);
        final spot = testedSpot(q);
        switch (q) {
          case NameNoteQuestion():
            expect(pitchClassAt(spot), q.answer);
          case FindNoteQuestion():
            expect((spot.string, spot.fret, pitchClassAt(spot)), (q.string, q.answer, q.note));
          case OctaveQuestion():
            expect(spot, q.to);
        }
      }
    });
  });
}
