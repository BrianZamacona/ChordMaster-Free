/// Rutinas de escala generadas por regla: sobre una posición de
/// `scales_master.json`, cada patrón recorre sus notas de grave a aguda y de
/// vuelta. Nada se escribe a mano: todo sale de la posición.
library;

import '../../core/i18n/tr.dart';
import '../lessons/lesson.dart';
import 'tab_playback.dart';

enum WorkoutLevel { beginner, intermediate, advanced }

/// Cómo se recorre la escalera de notas de la posición.
enum WorkoutPattern { upDown, thirds, groupsOf3, groupsOf4 }

/// Patrones de cada nivel, de lo más simple a lo más exigente.
const workoutPatterns = {
  WorkoutLevel.beginner: [WorkoutPattern.upDown],
  WorkoutLevel.intermediate: [WorkoutPattern.thirds, WorkoutPattern.groupsOf3],
  WorkoutLevel.advanced: [WorkoutPattern.groupsOf4, WorkoutPattern.thirds],
};

/// Tempo sugerido de cada nivel, en corcheas.
const workoutBpm = {
  WorkoutLevel.beginner: 60,
  WorkoutLevel.intermediate: 70,
  WorkoutLevel.advanced: 90,
};

/// Sistema de digitación de las rutinas: 3NPS en las escalas de 7 notas, las
/// cajas en las pentatónicas y el blues, CAGED en el resto.
String workoutSystemFor(List<int> intervals, String scaleId) {
  if ({'pentatonic_minor', 'pentatonic_major', 'blues_minor'}.contains(scaleId)) {
    return 'pentatonic_two_notes';
  }
  return intervals.length == 7 ? 'three_nps' : 'caged';
}

LocalizedText workoutLevelName(WorkoutLevel level) => switch (level) {
  WorkoutLevel.beginner => const LocalizedText(es: 'Principiante', en: 'Beginner'),
  WorkoutLevel.intermediate => const LocalizedText(es: 'Intermedio', en: 'Intermediate'),
  WorkoutLevel.advanced => const LocalizedText(es: 'Avanzado', en: 'Advanced'),
};

LocalizedText workoutPatternName(WorkoutPattern pattern) => switch (pattern) {
  WorkoutPattern.upDown => const LocalizedText(es: 'Subir y bajar', en: 'Up and down'),
  WorkoutPattern.thirds => const LocalizedText(es: 'En terceras', en: 'In thirds'),
  WorkoutPattern.groupsOf3 => const LocalizedText(es: 'Grupos de tres', en: 'Groups of three'),
  WorkoutPattern.groupsOf4 => const LocalizedText(es: 'Grupos de cuatro', en: 'Groups of four'),
};

LocalizedText workoutPatternHint(WorkoutPattern pattern) => switch (pattern) {
  WorkoutPattern.upDown => const LocalizedText(
    es: 'Toda la posición de la nota más grave a la más aguda y de vuelta.',
    en: 'The whole position from the lowest note to the highest and back.',
  ),
  WorkoutPattern.thirds => const LocalizedText(
    es: 'Cada nota y la que está dos lugares más arriba en la escala.',
    en: 'Each note and the one two places higher in the scale.',
  ),
  WorkoutPattern.groupsOf3 => const LocalizedText(
    es: 'Tres notas seguidas, y vuelves a empezar desde la siguiente.',
    en: 'Three notes in a row, then start again from the next one.',
  ),
  WorkoutPattern.groupsOf4 => const LocalizedText(
    es: 'Cuatro notas seguidas, y vuelves a empezar desde la siguiente.',
    en: 'Four notes in a row, then start again from the next one.',
  ),
};

/// Las notas de una posición en orden de altura, sin repetir alturas: si la
/// misma nota está en dos cuerdas, queda la de la cuerda más grave, para que
/// la escalera avance de cuerda en cuerda.
List<TabNote> positionLadder(List<TabNote> position) {
  final byPitch = <int, TabNote>{};
  for (final n in position) {
    final midi = tabMidi(n);
    final kept = byPitch[midi];
    if (kept == null || n.string > kept.string) byPitch[midi] = n;
  }
  final pitches = byPitch.keys.toList()..sort();
  return [for (final p in pitches) byPitch[p]!];
}

/// Las notas de [pattern] sobre la escalera [ladder]: primero sube y después
/// baja con el mismo dibujo.
List<TabNote> workoutNotes(WorkoutPattern pattern, List<TabNote> ladder) {
  final n = ladder.length;
  switch (pattern) {
    case WorkoutPattern.upDown:
      return [...ladder, ...ladder.reversed.skip(1)];
    case WorkoutPattern.thirds:
      if (n < 3) return const [];
      return [
        for (var i = 0; i + 2 < n; i++) ...[ladder[i], ladder[i + 2]],
        for (var i = n - 1; i - 2 >= 0; i--) ...[ladder[i], ladder[i - 2]],
      ];
    case WorkoutPattern.groupsOf3:
      return _groups(ladder, 3);
    case WorkoutPattern.groupsOf4:
      return _groups(ladder, 4);
  }
}

List<TabNote> _groups(List<TabNote> ladder, int size) {
  final n = ladder.length;
  if (n < size) return const [];
  return [
    for (var i = 0; i + size <= n; i++)
      for (var j = 0; j < size; j++) ladder[i + j],
    for (var i = n - 1; i - size + 1 >= 0; i--)
      for (var j = 0; j < size; j++) ladder[i - j],
  ];
}
