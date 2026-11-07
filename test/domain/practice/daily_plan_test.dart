import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/practice/daily_plan.dart';
import 'package:chordmaster_free/domain/practice/multi_day_challenges.dart';
import 'package:chordmaster_free/domain/practice/technique_exercises.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el número de día sube de uno en uno, también al cambiar de mes y año', () {
    int gap(DateTime a, DateTime b) => dayNumber(b) - dayNumber(a);
    expect(gap(DateTime(2025, 12, 31, 23, 59), DateTime(2026)), 1);
    expect(gap(DateTime(2026, 2, 28), DateTime(2026, 3)), 1);
    expect(gap(DateTime(2026, 3, 1, 1), DateTime(2026, 3, 1, 23)), 0);
  });

  test('en una semana salen todas las escalas y en cuatro días toda la técnica', () {
    final start = DateTime(2026, 5, 4);
    final week = [for (var i = 0; i < 7; i++) DateTime(2026, 5, 4 + i)];
    expect(
      {for (final d in week) dailyWorkoutScale(d)}.length,
      dailyWorkoutScales.length,
    );
    expect(
      {for (var i = 0; i < 4; i++) dailyTechnique(DateTime(2026, 5, 4 + i))},
      TechniqueExercise.values.toSet(),
    );
    // La hora no cambia el plan.
    expect(dailyWorkoutScale(start), dailyWorkoutScale(DateTime(2026, 5, 4, 23)));
  });

  test('cada escala del plan existe en scales_master.json', () {
    final json = jsonDecode(File('assets/data/scales_master.json').readAsStringSync())
        as Map<String, dynamic>;
    final ids = {
      for (final s in [...json['scales'] as List, ...json['modes'] as List])
        (s as Map<String, dynamic>)['id'] as String,
    };
    for (final s in dailyWorkoutScales) {
      expect(ids, contains(s.scaleId));
      expect(s.root, inInclusiveRange(0, 11));
    }
  });

  test('los pasos hechos son las actividades anotadas hoy', () {
    final today = DateTime(2026, 5, 4, 20);
    final log = {
      PracticeActivity.lessons: {dayKey(today)},
      PracticeActivity.workouts: {dayKey(DateTime(2026, 5, 3))},
      PracticeActivity.ear: {dayKey(today)},
    };
    expect(dailyPlanDone(log, today), 1);
    expect(dailyPlanDone(const {}, today), 0);
  });
}
