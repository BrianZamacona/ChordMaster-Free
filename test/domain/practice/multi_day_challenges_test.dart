import 'package:chordmaster_free/domain/practice/multi_day_challenges.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 3, 2, 18, 30);
  String daysAgo(int n) => dayKey(DateTime(2026, 3, 2 - n));

  test('la clave del día no lleva hora y cruza meses', () {
    expect(dayKey(today), '2026-03-02');
    expect(daysAgo(2), '2026-02-28');
  });

  group('racha', () {
    test('cuenta los días seguidos hasta hoy', () {
      expect(currentRun({daysAgo(0), daysAgo(1), daysAgo(2)}, today), 3);
    });

    test('si hoy aún no practicaste, sigue desde ayer', () {
      expect(currentRun({daysAgo(1), daysAgo(2)}, today), 2);
    });

    test('un hueco la corta', () {
      expect(currentRun({daysAgo(0), daysAgo(2), daysAgo(3)}, today), 1);
      expect(currentRun({daysAgo(2)}, today), 0);
    });
  });

  test('en la ventana solo cuentan los últimos días', () {
    final days = {daysAgo(0), daysAgo(3), daysAgo(6), daysAgo(7)};
    expect(daysInWindow(days, today, 7), 3);
    final w = windowDays(days, today, 7);
    expect(w, hasLength(7));
    expect(w.first.day, daysAgo(6));
    expect(w.last.day, daysAgo(0));
    expect([for (final d in w) d.practiced], [true, false, false, true, false, false, true]);
  });

  group('retos', () {
    final steady = multiDayChallenges.firstWhere((c) => c.consecutive);
    final technique = multiDayChallenges.firstWhere(
      (c) => c.activity == PracticeActivity.technique,
    );

    test('ids únicos, metas alcanzables y textos en los dos idiomas', () {
      expect({for (final c in multiDayChallenges) c.id}, hasLength(multiDayChallenges.length));
      for (final c in multiDayChallenges) {
        expect(c.goal, inInclusiveRange(1, c.window), reason: c.id);
        for (final t in [c.title, c.body]) {
          expect(t.es.trim(), isNotEmpty);
          expect(t.en.trim(), isNotEmpty);
        }
      }
    });

    test('todos se pueden superar practicando su actividad cada día', () {
      final everyDay = {for (var i = 0; i < 7; i++) daysAgo(i)};
      final log = {for (final a in PracticeActivity.values) a: everyDay};
      for (final c in multiDayChallenges) {
        expect(challengeDays(c, log, today), c.goal, reason: c.id);
      }
    });

    test('el de cualquier práctica junta todas las actividades', () {
      final log = {
        PracticeActivity.lessons: {daysAgo(0), daysAgo(2)},
        PracticeActivity.ear: {daysAgo(1)},
      };
      expect(challengeDays(steady, log, today), 3);
    });

    test('el de una actividad no cuenta las otras y no pasa de la meta', () {
      final log = {
        PracticeActivity.ear: {daysAgo(0), daysAgo(1)},
        PracticeActivity.technique: {for (var i = 0; i < 7; i++) daysAgo(i)},
      };
      expect(challengeDays(technique, log, today), technique.goal);
      expect(challengeDays(technique, {PracticeActivity.ear: log[PracticeActivity.ear]!}, today), 0);
    });
  });
}
