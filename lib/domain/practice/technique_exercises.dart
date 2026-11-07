/// Ejercicios de técnica para la mano izquierda, generados por regla: un dedo
/// por traste en una ventana de cuatro trastes que empieza en [startFret].
/// No dependen de una escala (son cromáticos); sirven para calentar, para la
/// independencia de los dedos y para la sincronía entre las manos.
library;

import '../../core/i18n/tr.dart';
import '../lessons/lesson.dart';

enum TechniqueExercise { chromatic, spider, diagonal, stringSkip }

/// Trastes donde puede empezar la ventana: abajo cuesta más estirar, arriba
/// los trastes son más cortos.
const techniqueStartFrets = [1, 5, 9];

/// Tempo con el que se empieza si no hay récord, y sus límites.
const techniqueDefaultBpm = 60;
const techniqueMinBpm = 40;
const techniqueMaxBpm = 200;
const techniqueBpmStep = 5;

/// Cuerdas de grave a aguda (6 = mi grave … 1 = mi aguda).
const _lowToHigh = [6, 5, 4, 3, 2, 1];

/// Cuerdas del salto de cuerda: se salta una y se vuelve a la de al lado.
const _skipOrder = [6, 4, 5, 3, 4, 2, 3, 1];

/// Dedos en el orden en que se tocan. Dedo 1 = índice, en el primer traste de
/// la ventana; el dedo n va en el traste `start + n − 1`.
List<int> techniqueFingers(TechniqueExercise exercise) => switch (exercise) {
  TechniqueExercise.spider => const [1, 3, 2, 4],
  _ => const [1, 2, 3, 4],
};

/// Las notas del ejercicio en tablatura (cuerda 1 = mi aguda).
///
/// - Cromático: 1-2-3-4 en cada cuerda, de la 6ª a la 1ª, y de vuelta 4-3-2-1.
/// - Araña: igual con 1-3-2-4 (y 4-2-3-1 al volver), que obliga a cruzar.
/// - Diagonal: 1-2-3-4 subiendo de cuerda y un traste más arriba en cada una:
///   la mano se desplaza sin parar.
/// - Salto de cuerda: 1-2-3-4 en 6, 4, 5, 3, 4, 2, 3, 1.
List<TabNote> techniqueNotes(TechniqueExercise exercise, {int startFret = 1}) {
  final fingers = techniqueFingers(exercise);
  List<TabNote> onString(int string, int start, List<int> order) => [
    for (final f in order) TabNote(string, start + f - 1),
  ];
  return switch (exercise) {
    TechniqueExercise.chromatic || TechniqueExercise.spider => [
      for (final s in _lowToHigh) ...onString(s, startFret, fingers),
      for (final s in _lowToHigh.reversed)
        ...onString(s, startFret, fingers.reversed.toList()),
    ],
    TechniqueExercise.diagonal => [
      for (final (i, s) in _lowToHigh.indexed)
        ...onString(s, startFret + i, fingers),
    ],
    TechniqueExercise.stringSkip => [
      for (final s in _skipOrder) ...onString(s, startFret, fingers),
    ],
  };
}

/// Próximo tempo a intentar: el récord más un paso, o el inicial si no hay.
int techniqueNextBpm(int? record) => record == null
    ? techniqueDefaultBpm
    : (record + techniqueBpmStep).clamp(techniqueMinBpm, techniqueMaxBpm);

LocalizedText techniqueName(TechniqueExercise exercise) => switch (exercise) {
  TechniqueExercise.chromatic =>
    const LocalizedText(es: 'Cromático 1-2-3-4', en: 'Chromatic 1-2-3-4'),
  TechniqueExercise.spider =>
    const LocalizedText(es: 'Araña 1-3-2-4', en: 'Spider 1-3-2-4'),
  TechniqueExercise.diagonal =>
    const LocalizedText(es: 'Diagonal', en: 'Diagonal'),
  TechniqueExercise.stringSkip =>
    const LocalizedText(es: 'Salto de cuerda', en: 'String skipping'),
};

LocalizedText techniqueHint(TechniqueExercise exercise) => switch (exercise) {
  TechniqueExercise.chromatic => const LocalizedText(
    es: 'Un dedo por traste en cada cuerda, de la 6ª a la 1ª y de vuelta. '
        'Deja los dedos apoyados cerca de los trastes.',
    en: 'One finger per fret on each string, from the 6th to the 1st and '
        'back. Keep your fingers close to the frets.',
  ),
  TechniqueExercise.spider => const LocalizedText(
    es: 'Índice, anular, medio y meñique: los dedos se cruzan y ganan '
        'independencia.',
    en: 'Index, ring, middle and pinky: the fingers cross over and gain '
        'independence.',
  ),
  TechniqueExercise.diagonal => const LocalizedText(
    es: 'Cada cuerda empieza un traste más arriba: la mano sube por el mástil '
        'sin perder la forma.',
    en: 'Each string starts one fret higher: your hand moves up the neck '
        'without losing its shape.',
  ),
  TechniqueExercise.stringSkip => const LocalizedText(
    es: 'Salta una cuerda y vuelve a la de al lado: la púa aprende a cruzar '
        'sin tocar la del medio.',
    en: 'Skip a string and come back to the next one: the pick learns to '
        'cross without hitting the one in between.',
  ),
};
