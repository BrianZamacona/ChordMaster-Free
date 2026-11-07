/// "Práctica de hoy": tres pasos cortos que cambian cada día por regla, sin
/// azar: la siguiente lección del camino, una rutina de escala y un ejercicio
/// de técnica. Cada paso queda hecho cuando su actividad se anota hoy.
library;

import '../lessons/lesson.dart';
import 'multi_day_challenges.dart';
import 'technique_exercises.dart';

/// Escalas que rotan en la rutina del día: las de los caminos de Lecciones,
/// en tonalidades cómodas para la guitarra.
const dailyWorkoutScales = [
  LessonScale(scaleId: 'pentatonic_minor', root: 9), // A
  LessonScale(scaleId: 'major', root: 7), // G
  LessonScale(scaleId: 'natural_minor', root: 4), // E
  LessonScale(scaleId: 'blues_minor', root: 9), // A
  LessonScale(scaleId: 'pentatonic_major', root: 0), // C
  LessonScale(scaleId: 'major', root: 0), // C
  LessonScale(scaleId: 'dorian', root: 2), // D
];

/// Número de día desde una fecha fija: sube de uno en uno cada día, sin
/// depender de la hora ni del cambio de horario.
int dayNumber(DateTime day) =>
    DateTime.utc(day.year, day.month, day.day).difference(DateTime.utc(2024)).inDays;

/// Escala de la rutina de [day].
LessonScale dailyWorkoutScale(DateTime day) =>
    dailyWorkoutScales[dayNumber(day) % dailyWorkoutScales.length];

/// Ejercicio de técnica de [day].
TechniqueExercise dailyTechnique(DateTime day) =>
    TechniqueExercise.values[dayNumber(day) % TechniqueExercise.values.length];

/// Actividades de los pasos, en orden: lección, rutina y técnica.
const dailyPlanActivities = [
  PracticeActivity.lessons,
  PracticeActivity.workouts,
  PracticeActivity.technique,
];

/// Cuántos pasos de hoy ya están hechos.
int dailyPlanDone(Map<PracticeActivity, Set<String>> log, DateTime today) => [
  for (final a in dailyPlanActivities)
    if (log[a]?.contains(dayKey(today)) ?? false) a,
].length;
