/// Retos de varios días: se superan practicando un módulo en días distintos.
/// Los días se guardan como "aaaa-mm-dd" por actividad; nada se marca a mano.
library;

import '../../core/i18n/tr.dart';

/// Lo que cuenta como un día de práctica de cada tipo.
enum PracticeActivity {
  /// Terminar una lección.
  lessons,

  /// Escuchar una rutina de escala.
  workouts,

  /// Guardar un tempo limpio en Técnica.
  technique,

  /// Responder en Oído.
  ear,

  /// Terminar una ronda del juego de ritmo con puntaje.
  rhythm,
}

/// Clave de un día, sin hora: "2026-11-07".
String dayKey(DateTime day) =>
    '${day.year}-${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Días seguidos con práctica que terminan hoy o, si hoy aún no practicaste,
/// ayer (la racha no se pierde hasta que acaba el día).
int currentRun(Set<String> days, DateTime today) {
  var day = _dateOnly(today);
  if (!days.contains(dayKey(day))) day = day.subtract(const Duration(days: 1));
  var run = 0;
  while (days.contains(dayKey(day))) {
    run++;
    day = DateTime(day.year, day.month, day.day - 1);
  }
  return run;
}

/// Días con práctica dentro de los últimos [window] días, hoy incluido.
int daysInWindow(Set<String> days, DateTime today, int window) {
  final start = _dateOnly(today);
  return [
    for (var i = 0; i < window; i++)
      if (days.contains(dayKey(DateTime(start.year, start.month, start.day - i)))) i,
  ].length;
}

/// Los últimos [window] días, del más viejo a hoy, y si hubo práctica.
List<({String day, bool practiced})> windowDays(
  Set<String> days,
  DateTime today,
  int window,
) {
  final start = _dateOnly(today);
  return [
    for (var i = window - 1; i >= 0; i--)
      if (dayKey(DateTime(start.year, start.month, start.day - i)) case final k)
        (day: k, practiced: days.contains(k)),
  ];
}

class MultiDayChallenge {
  const MultiDayChallenge({
    required this.id,
    required this.title,
    required this.body,
    required this.goal,
    this.activity,
    this.window = 7,
    this.consecutive = false,
  });

  /// Identificador estable (se guarda al superarlo).
  final String id;
  final LocalizedText title;
  final LocalizedText body;

  /// Actividad que cuenta; null = cualquiera.
  final PracticeActivity? activity;

  /// Días que hacen falta.
  final int goal;

  /// Ventana en días donde se cuentan (si no son seguidos).
  final int window;

  /// Si los días deben ser seguidos.
  final bool consecutive;
}

/// Días que cuenta un reto, según su actividad.
Set<String> daysFor(
  MultiDayChallenge challenge,
  Map<PracticeActivity, Set<String>> log,
) {
  final activity = challenge.activity;
  if (activity != null) return log[activity] ?? const {};
  return {for (final days in log.values) ...days};
}

/// Avance de un reto hoy: días que cuentan, de [MultiDayChallenge.goal].
int challengeDays(
  MultiDayChallenge challenge,
  Map<PracticeActivity, Set<String>> log,
  DateTime today,
) {
  final days = daysFor(challenge, log);
  final count = challenge.consecutive
      ? currentRun(days, today)
      : daysInWindow(days, today, challenge.window);
  return count > challenge.goal ? challenge.goal : count;
}

const multiDayChallenges = [
  MultiDayChallenge(
    id: 'md_steady_week',
    title: LocalizedText(es: 'Semana constante', en: 'Steady week'),
    body: LocalizedText(
      es: 'Practica algo 7 días seguidos: una lección, una rutina, Técnica, '
          'Oído o Ritmo.',
      en: 'Practice something 7 days in a row: a lesson, a workout, Technique, '
          'Ear or Rhythm.',
    ),
    goal: 7,
    consecutive: true,
  ),
  MultiDayChallenge(
    id: 'md_steel_fingers',
    title: LocalizedText(es: 'Dedos de acero', en: 'Fingers of steel'),
    body: LocalizedText(
      es: 'Guarda un tempo limpio en Técnica 5 días de una semana.',
      en: 'Save a clean tempo in Technique on 5 days of a week.',
    ),
    activity: PracticeActivity.technique,
    goal: 5,
  ),
  MultiDayChallenge(
    id: 'md_daily_scales',
    title: LocalizedText(es: 'Escalas a diario', en: 'Daily scales'),
    body: LocalizedText(
      es: 'Escucha y toca una rutina de escala 5 días de una semana.',
      en: 'Listen to and play a scale workout on 5 days of a week.',
    ),
    activity: PracticeActivity.workouts,
    goal: 5,
  ),
  MultiDayChallenge(
    id: 'md_step_a_day',
    title: LocalizedText(es: 'Un paso al día', en: 'A step a day'),
    body: LocalizedText(
      es: 'Termina lecciones en 3 días distintos de una semana.',
      en: 'Finish lessons on 3 different days of a week.',
    ),
    activity: PracticeActivity.lessons,
    goal: 3,
  ),
  MultiDayChallenge(
    id: 'md_ear_week',
    title: LocalizedText(es: 'Oído de cada día', en: 'Everyday ear'),
    body: LocalizedText(
      es: 'Responde en Oído 5 días de una semana.',
      en: 'Answer in Ear training on 5 days of a week.',
    ),
    activity: PracticeActivity.ear,
    goal: 5,
  ),
  MultiDayChallenge(
    id: 'md_in_time',
    title: LocalizedText(es: 'A tiempo', en: 'In time'),
    body: LocalizedText(
      es: 'Termina una ronda del juego de ritmo 4 días de una semana.',
      en: 'Finish a round of the rhythm game on 4 days of a week.',
    ),
    activity: PracticeActivity.rhythm,
    goal: 4,
  ),
];
