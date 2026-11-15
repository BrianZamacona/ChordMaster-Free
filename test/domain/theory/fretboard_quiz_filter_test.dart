import 'dart:math';

import 'package:chordmaster_free/domain/theory/fretboard_quiz.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Un filtro válido al azar: algunas cuerdas, un tramo de 4 a 13 trastes y
  /// naturales o no.
  FretQuizFilter randomFilter(Random rng) {
    final strings = {for (var s = 1; s <= 6; s++) if (rng.nextBool()) s};
    if (strings.isEmpty) strings.add(rng.nextInt(6) + 1);
    final from = rng.nextInt(fretQuizMaxFret - fretQuizMinSpan + 1);
    final to = from + fretQuizMinSpan + rng.nextInt(fretQuizMaxFret - from - fretQuizMinSpan + 1);
    return FretQuizFilter(strings: strings, fromFret: from, toFret: to, naturalsOnly: rng.nextBool());
  }

  test('notas naturales: las siete sin sostenido', () {
    expect([for (var pc = 0; pc < 12; pc++) if (isNaturalNote(pc)) pitchClassName(pc)], ['C', 'D', 'E', 'F', 'G', 'A', 'B']);
  });

  test('un filtro necesita cuerdas y al menos cuatro trastes seguidos', () {
    expect(const FretQuizFilter().isValid, isTrue);
    expect(const FretQuizFilter().isAll, isTrue);
    expect(const FretQuizFilter(strings: {}).isValid, isFalse);
    expect(const FretQuizFilter(fromFret: 5, toFret: 7).isValid, isFalse);
    expect(const FretQuizFilter(fromFret: 5, toFret: 8).isValid, isTrue);
    expect(const FretQuizFilter(toFret: 13).isValid, isFalse);
  });

  test('se guarda y se vuelve a leer igual; lo que no se entiende es el mástil entero', () {
    const f = FretQuizFilter(strings: {6, 5}, fromFret: 3, toFret: 9, naturalsOnly: true);
    expect(FretQuizFilter.fromJson(f.toJson()), f);
    expect(FretQuizFilter.fromJson(null), const FretQuizFilter());
    expect(FretQuizFilter.fromJson({'strings': [1], 'from': 0, 'to': 1, 'naturals': false}), const FretQuizFilter());
    expect(FretQuizFilter.fromJson({'strings': 'x'}), const FretQuizFilter());
  });

  test('en 300 filtros al azar, cada pregunta queda dentro del filtro con cuatro opciones', () {
    final rng = Random(11);
    for (var i = 0; i < 300; i++) {
      final f = randomFilter(rng);
      bool inRange(int fret) => fret >= f.fromFret && fret <= f.toFret;
      for (var k = 0; k < 40; k++) {
        final q = nextFretQuestion(rng, f);
        final reason = '${f.toJson()} $q';
        expect(q.choices.toSet(), hasLength(fretQuizChoices), reason: reason);
        expect(q.choices, contains(q.answer), reason: reason);
        switch (q) {
          case NameNoteQuestion(:final spot):
            expect(f.strings, contains(spot.string), reason: reason);
            expect(inRange(spot.fret), isTrue, reason: reason);
            if (f.naturalsOnly) {
              // La nota y las opciones: todas naturales.
              expect(q.choices.every(isNaturalNote), isTrue, reason: reason);
            }
          case FindNoteQuestion(:final string, :final note):
            expect(f.strings, contains(string), reason: reason);
            if (f.naturalsOnly) expect(isNaturalNote(note), isTrue, reason: reason);
            // Doce trastes desde el primero: la nota sale una sola vez.
            final last = min(f.toFret, f.fromFret + findNoteMaxFret);
            final where = [for (var fr = f.fromFret; fr <= last; fr++) if (pitchClassAt((string: string, fret: fr)) == note) fr];
            expect(where, [q.answer], reason: reason);
            for (final c in q.choices) {
              expect(c, inInclusiveRange(f.fromFret, last), reason: reason);
            }
          case OctaveQuestion(:final from, :final to):
            expect(f.strings, containsAll([from.string, to.string]), reason: reason);
            expect(inRange(from.fret) && inRange(to.fret), isTrue, reason: reason);
            if (f.naturalsOnly) expect(isNaturalNote(pitchClassAt(from)), isTrue, reason: reason);
            expect(q.choices.every(inRange), isTrue, reason: reason);
        }
      }
    }
  });

  test('sin dos cuerdas que formen octava, no sale la pregunta de la octava', () {
    const f = FretQuizFilter(strings: {6});
    expect(fretQuizHasOctaves(f), isFalse);
    final rng = Random(2);
    final qs = [for (var i = 0; i < 300; i++) nextFretQuestion(rng, f)];
    expect(qs.whereType<OctaveQuestion>(), isEmpty);
    expect(qs.whereType<NameNoteQuestion>(), isNotEmpty);
    expect(qs.whereType<FindNoteQuestion>(), isNotEmpty);
    expect(fretQuizHasOctaves(const FretQuizFilter(strings: {6, 4})), isTrue);
  });
}
