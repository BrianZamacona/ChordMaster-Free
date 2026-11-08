import 'package:chordmaster_free/domain/courses/course.dart';
import 'package:chordmaster_free/domain/lessons/curriculum.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/melodies/basics_course.dart';
import 'package:chordmaster_free/domain/melodies/melody_course.dart';
import 'package:chordmaster_free/domain/practice/tab_playback.dart';
import 'package:chordmaster_free/domain/practice/technique_exercises.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dedo de cada traste pisado en [tab] (según [tabFingers]).
Map<int, int> fingerByFret(List<TabNote> tab) {
  final fingers = tabFingers(tab)!;
  return {
    for (final (i, n) in tab.indexed) n.fret: ?fingers[i],
  };
}

void main() {
  group('la regla', () {
    test('primera posición: el dedo es el traste; al aire, ninguno', () {
      const tab = [TabNote(1, 0), TabNote(1, 1), TabNote(1, 3), TabNote(2, 2)];
      expect(tabFingers(tab), [null, 1, 3, 2]);
    });

    test('más arriba, el índice va en el traste más bajo', () {
      const tab = [TabNote(3, 5), TabNote(2, 7), TabNote(1, 8)];
      expect(tabFingers(tab), [1, 3, 4]);
    });

    test('si lo pisado no cabe en cuatro trastes, no hay regla', () {
      expect(tabFingers(const [TabNote(1, 1), TabNote(1, 5)]), isNull);
      expect(tabFingers(const [TabNote(1, 5), TabNote(1, 9)]), isNull);
    });

    test('todo al aire: ningún dedo', () {
      expect(tabFingers(const [TabNote(1, 0), TabNote(2, 0)]), [null, null]);
    });

    test('mismo traste, mismo dedo; más alto, dedo más alto', () {
      final tabs = [
        for (final levels in [basicsCourse, melodyCourse])
          for (final s in courseSteps(levels)) s.tab,
        for (final l in lessonsById.values) l.tab,
        for (final e in TechniqueExercise.values)
          for (final start in techniqueStartFrets) techniqueNotes(e, startFret: start),
      ];
      for (final tab in tabs.where((t) => t.isNotEmpty)) {
        final fingers = tabFingers(tab);
        if (fingers == null) continue;
        final byFret = <int, int>{};
        for (final (i, n) in tab.indexed) {
          final f = fingers[i];
          if (n.fret == 0) {
            expect(f, isNull);
            continue;
          }
          expect(f, inInclusiveRange(1, 4));
          expect(byFret.putIfAbsent(n.fret, () => f!), f);
        }
        final frets = byFret.keys.toList()..sort();
        for (var i = 1; i < frets.length; i++) {
          expect(byFret[frets[i]], greaterThan(byFret[frets[i - 1]]!));
        }
      }
    });
  });

  group('coincide con lo que dicen los textos', () {
    test('Primeros pasos: índice en el 1 y anular en el 3', () {
      expect(fingerByFret(basicsStepsById['b_fret_index']!.tab), {1: 1});
      final two = fingerByFret(basicsStepsById['b_fret_two']!.tab);
      expect(two[1], 1);
      expect(two[3], 3);
    });

    test('Primeros pasos: el dedo medio va en el traste 2', () {
      final steps = [
        for (final s in courseSteps(basicsCourse))
          if (s.tab.any((n) => n.fret == 2)) s,
      ];
      expect(steps, isNotEmpty);
      for (final s in steps) {
        expect(fingerByFret(s.tab)[2], 2, reason: s.id);
      }
    });

    test('Melodías: en la posición V el índice va en el traste 5', () {
      final steps = [
        for (final s in courseSteps(melodyCourse))
          if (s.tab.isNotEmpty && s.tab.every((n) => n.fret == 0 || n.fret >= 5)) s,
      ];
      expect(steps, isNotEmpty);
      for (final s in steps) {
        if (tabFingers(s.tab) == null) continue;
        expect(fingerByFret(s.tab)[5], 1, reason: s.id);
      }
    });

    test('Técnica desde el traste 1, 5 y 9: el índice en el primero', () {
      for (final start in techniqueStartFrets) {
        final notes = techniqueNotes(TechniqueExercise.chromatic, startFret: start);
        expect(fingerByFret(notes), {start: 1, start + 1: 2, start + 2: 3, start + 3: 4});
      }
    });
  });
}
