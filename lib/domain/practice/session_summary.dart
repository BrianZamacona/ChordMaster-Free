/// El resumen de la sesión de hoy (idea del "feedback" de la app de Gibson,
/// pero por reglas, sin IA): qué se tocó con el micrófono, qué salió limpio,
/// los récords nuevos y qué conviene repetir, con su renglón y su tempo.
library;

import 'play_along.dart';
import 'technique_exercises.dart';

/// Qué se tocó: un paso de curso o un ejercicio de Técnica.
sealed class RunTarget {
  const RunTarget();

  /// Clave estable para guardarlo y agrupar las pasadas.
  String get key;

  static RunTarget? fromKey(String key) {
    final parts = key.split(':');
    return switch (parts) {
      ['course', final course, final step] => CourseStepTarget(course, step),
      ['technique', final name, final fret] => switch ((
        TechniqueExercise.values.where((e) => e.name == name).firstOrNull,
        int.tryParse(fret),
      )) {
        (final e?, final f?) => TechniqueTarget(e, f),
        _ => null,
      },
      _ => null,
    };
  }
}

/// Un paso de un curso: [course] es el nombre de `LessonCourse`.
class CourseStepTarget extends RunTarget {
  const CourseStepTarget(this.course, this.stepId);

  final String course;
  final String stepId;

  @override
  String get key => 'course:$course:$stepId';
}

class TechniqueTarget extends RunTarget {
  const TechniqueTarget(this.exercise, this.startFret);

  final TechniqueExercise exercise;
  final int startFret;

  @override
  String get key => 'technique:${exercise.name}:$startFret';
}

/// Una pasada entera tocada con el micrófono.
class PracticeRun {
  const PracticeRun({
    required this.target,
    required this.mistakes,
    required this.bpm,
    required this.clean,
    required this.lineToPractice,
    required this.tempo,
    this.newRecord,
  });

  /// De lo que midió el micrófono; [tempo] = el que tenía la pantalla.
  factory PracticeRun.from(
    RunTarget target,
    PlayAlongResult result, {
    required int tempo,
    int? newRecord,
  }) => PracticeRun(
    target: target,
    mistakes: result.mistakes,
    bpm: result.bpm?.round(),
    clean: result.clean,
    lineToPractice: result.lineToPractice,
    tempo: tempo,
    newRecord: newRecord,
  );

  final RunTarget target;
  final int mistakes;

  /// Tempo medido (redondeado); `null` si no se pudo medir.
  final int? bpm;
  final bool clean;

  /// Renglón (desde 0) que conviene repetir, si no salió limpia.
  final int? lineToPractice;

  /// El tempo elegido en la pantalla al tocarla.
  final int tempo;

  /// El récord que se guardó con esta pasada, si superó al anterior.
  final int? newRecord;

  Map<String, Object?> toJson() => {
    'target': target.key,
    'mistakes': mistakes,
    'bpm': bpm,
    'clean': clean,
    'line': lineToPractice,
    'tempo': tempo,
    'record': newRecord,
  };

  /// `null` si los datos no se entienden (versión vieja o dañados).
  static PracticeRun? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final target = RunTarget.fromKey('${raw['target']}');
    final mistakes = raw['mistakes'];
    final tempo = raw['tempo'];
    if (target == null || mistakes is! int || tempo is! int) return null;
    return PracticeRun(
      target: target,
      mistakes: mistakes,
      bpm: raw['bpm'] as int?,
      clean: raw['clean'] == true,
      lineToPractice: raw['line'] as int?,
      tempo: tempo,
      newRecord: raw['record'] as int?,
    );
  }
}

/// Algo para repetir: dónde costó y a qué tempo volver.
class ToRepeat {
  const ToRepeat({
    required this.target,
    required this.mistakes,
    required this.line,
    required this.slowerBpm,
  });

  final RunTarget target;
  final int mistakes;

  /// Renglón (desde 0) a repetir, o `null` si no se sabe cuál.
  final int? line;
  final int slowerBpm;
}

/// Lo que salió limpio hoy: el mejor tempo medido.
class CleanToday {
  const CleanToday({required this.target, required this.bestBpm});

  final RunTarget target;
  final int bestBpm;
}

class SessionSummary {
  const SessionSummary({
    required this.runs,
    required this.cleanRuns,
    required this.records,
    required this.toRepeat,
    required this.cleanToday,
  });

  final int runs;
  final int cleanRuns;

  /// Récords nuevos de hoy (el mayor de cada cosa).
  final Map<String, int> records;

  /// Lo que en su última pasada no salió limpio, en el orden en que se tocó.
  final List<ToRepeat> toRepeat;

  /// Lo que salió limpio al menos una vez y su última pasada también.
  final List<CleanToday> cleanToday;

  bool get isEmpty => runs == 0;
}

/// El resumen de [runs] (en el orden en que se tocaron). Por cosa tocada
/// manda la última pasada: si salió limpia, va a "limpio hoy"; si no, a
/// "para repetir" con el renglón y 10 BPM menos que el tempo de la pantalla.
SessionSummary summarizeSession(List<PracticeRun> runs) {
  final last = <String, PracticeRun>{};
  final best = <String, int>{};
  final records = <String, int>{};
  for (final r in runs) {
    final k = r.target.key;
    last.remove(k);
    last[k] = r;
    if (r.clean && r.bpm != null && r.bpm! > (best[k] ?? 0)) best[k] = r.bpm!;
    if (r.newRecord case final rec? when rec > (records[k] ?? 0)) records[k] = rec;
  }
  return SessionSummary(
    runs: runs.length,
    cleanRuns: runs.where((r) => r.clean).length,
    records: records,
    toRepeat: [
      for (final r in last.values)
        if (!r.clean)
          ToRepeat(
            target: r.target,
            mistakes: r.mistakes,
            line: r.lineToPractice,
            slowerBpm: slowerBpm(r.tempo),
          ),
    ],
    cleanToday: [
      for (final r in last.values)
        if (best[r.target.key] case final b? when r.clean)
          CleanToday(target: r.target, bestBpm: b),
    ],
  );
}
