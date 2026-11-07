import 'package:chordmaster_free/domain/lessons/curriculum.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/lessons/unit_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final firstSteps = unitsOf(LessonTrack.foundations).first;

  test('minutos y avance salen de las lecciones', () {
    final lessons = lessonsOfUnit(firstSteps);
    final s = UnitSummary(firstSteps, completed: {lessons.first.id});
    expect(s.minutes, lessons.fold<int>(0, (a, l) => a + l.minutes));
    expect(s.done, 1);
    expect(s.minutesDone, lessons.first.minutes);
    expect(s.finished, isFalse);
    expect(
      UnitSummary(firstSteps, completed: {for (final l in lessons) l.id}).finished,
      isTrue,
    );
  });

  test('acordes y escalas sin repetir, en orden de aparición', () {
    for (final unit in unitsById.values) {
      final s = UnitSummary(unit);
      final expected = <String>[];
      for (final l in s.lessons) {
        for (final c in l.chords) {
          if (!expected.contains(c)) expected.add(c);
        }
      }
      expect(s.chords, expected, reason: unit.id);
      final keys = [for (final sc in s.scales) (sc.scaleId, sc.root)];
      expect(keys.toSet(), hasLength(keys.length), reason: unit.id);
      expect(
        s.tabNotes,
        s.lessons.fold<int>(0, (a, l) => a + l.tab.length),
        reason: unit.id,
      );
    }
  });

  test('el reto solo cierra la última unidad de cada nivel', () {
    for (final track in [LessonTrack.rhythm, LessonTrack.lead]) {
      for (final level in levelsOf(track)) {
        final row = unitsOf(track, level: level);
        for (final (i, unit) in row.indexed) {
          final challenge = UnitSummary(unit).closingChallenge;
          if (i == row.length - 1) {
            expect(challenge, challengesOf(track, level: level).single);
          } else {
            expect(challenge, isNull);
          }
        }
      }
    }
    for (final unit in unitsOf(LessonTrack.foundations)) {
      expect(UnitSummary(unit).closingChallenge, isNull);
    }
  });

  test('la siguiente unidad sigue el camino y pasa de nivel', () {
    for (final track in LessonTrack.values) {
      final all = unitsOf(track);
      for (var i = 0; i < all.length - 1; i++) {
        expect(UnitSummary(all[i]).nextUnit, all[i + 1]);
      }
      expect(UnitSummary(all.last).nextUnit, isNull);
    }
  });

  test('la posición cuenta dentro del nivel', () {
    for (final track in LessonTrack.values) {
      for (final level in levelsOf(track)) {
        final row = unitsOf(track, level: level);
        for (final (i, unit) in row.indexed) {
          expect(UnitSummary(unit).position, (i + 1, row.length));
        }
      }
    }
  });
}
