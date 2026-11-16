/// Curso de tapping (decisión del usuario tras revisar Learn Tapping): del
/// primer tap en una cuerda al trino con las dos manos, en el orden en que se
/// aprende. Frases propias, armadas por regla con [tapTriplet], [tapTripletDown]
/// y [tapTrill]; un test verifica la escritura, la escala de cada nivel y lo
/// que afirma cada texto.
library;

import '../../core/i18n/tr.dart';
import '../courses/course.dart';
import '../lessons/lesson.dart';

/// Un paso del curso: la teoría no tiene notas; un ejercicio, su tablatura.
class TappingStep implements TabCourseStep {
  const TappingStep({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.tab = const [],
  });

  @override
  final String id;
  @override
  final CourseStepKind kind;
  @override
  final LocalizedText title;
  @override
  final LocalizedText body;
  @override
  final List<TabNote> tab;

  @override
  LocalizedText? get origin => null;
}

class TappingLevel extends CourseLevel<TappingStep> {
  const TappingLevel({
    required super.title,
    required super.intro,
    required this.scale,
    required super.steps,
  });

  /// Escala de todas sus notas (un test lo verifica).
  final LessonScale scale;
}

/// Tresillo en la cuerda [string]: tapping en [tap], pull-off a [low] y
/// hammer-on a [high] (índice y meñique de la mano izquierda).
List<TabNote> tapTriplet(int string, int tap, int low, int high) => [
  TabNote(string, tap, technique: TabTechnique.tap, length: tabTripletEighth),
  TabNote(string, low, technique: TabTechnique.pullOff, length: tabTripletEighth),
  TabNote(string, high, technique: TabTechnique.hammerOn, length: tabTripletEighth),
];

/// Tresillo que baja: tapping en [tap] y dos pull-offs, a [high] y a [low].
List<TabNote> tapTripletDown(int string, int tap, int high, int low) => [
  TabNote(string, tap, technique: TabTechnique.tap, length: tabTripletEighth),
  TabNote(string, high, technique: TabTechnique.pullOff, length: tabTripletEighth),
  TabNote(string, low, technique: TabTechnique.pullOff, length: tabTripletEighth),
];

/// Trino con las dos manos en la cuerda [string] durante [beats] pulsos:
/// tapping en [tap] y pull-off a [low], en semicorcheas.
List<TabNote> tapTrill(int string, int tap, int low, int beats) => [
  for (var i = 0; i < beats * 2; i++) ...[
    TabNote(string, tap, technique: TabTechnique.tap, length: tabSixteenth),
    TabNote(string, low, technique: TabTechnique.pullOff, length: tabSixteenth),
  ],
];

/// Cuatro semicorcheas que bajan de cuerda: tapping en [tap] y pull-off a
/// [pull] en [string]; en la cuerda de abajo, hammer-on desde la nada a [from]
/// y hammer-on a [to].
List<TabNote> tapAndDrop(int string, int tap, int pull, int from, int to) => [
  TabNote(string, tap, technique: TabTechnique.tap, length: tabSixteenth),
  TabNote(string, pull, technique: TabTechnique.pullOff, length: tabSixteenth),
  TabNote(string + 1, from, technique: TabTechnique.hammerFromNowhere, length: tabSixteenth),
  TabNote(string + 1, to, technique: TabTechnique.hammerOn, length: tabSixteenth),
];

/// La nota que cierra un ejercicio: un tapping de una negra.
TabNote tapEnd(int string, int fret) =>
    TabNote(string, fret, technique: TabTechnique.tap, length: tabQuarter);

/// Am en la 2ª cuerda: A (10) y C (13) con la izquierda, E (17) con la derecha.
List<TabNote> get _am => tapTriplet(2, 17, 10, 13);

/// E en la 2ª cuerda: G# (9) y B (12) con la izquierda, E (17) con la derecha.
List<TabNote> get _e => tapTriplet(2, 17, 9, 12);

/// La izquierda se queda en A (10) y C (13); la derecha pisa [tap].
List<TabNote> _onAm(int tap) => tapTriplet(2, tap, 10, 13);

const _aMinor = LessonScale(scaleId: 'natural_minor', root: 9);
const _aHarmonicMinor = LessonScale(scaleId: 'harmonic_minor', root: 9);
const _aMinorPentatonic = LessonScale(scaleId: 'pentatonic_minor', root: 9);

final List<TappingLevel> tappingCourse = [
  TappingLevel(
    title: const LocalizedText(es: 'El primer tap', en: 'The first tap'),
    intro: const LocalizedText(
      es: 'Una sola cuerda: el tap, el pull-off que lo suelta y el arpegio de Am.',
      en: 'A single string: the tap, the pull-off that releases it and the Am arpeggio.',
    ),
    scale: _aMinor,
    steps: [
      const TappingStep(
        id: 'tp1_intro',
        kind: CourseStepKind.theory,
        title: LocalizedText(es: 'Qué es el tapping', en: 'What tapping is'),
        body: LocalizedText(
          es: 'En el tapping, un dedo de la mano de la púa pisa un traste con fuerza y la cuerda '
              'suena sin púa; luego lo suelta con un pull-off hacia una nota de la mano izquierda. '
              'Así se tocan arpegios y saltos que una mano sola no alcanza. En la tablatura va una '
              'T encima de la nota.\n\n'
              'Con qué dedo: el índice o el medio de la mano derecha. Con el medio, la púa se queda '
              'entre el pulgar y el índice; con el índice, guárdala en la palma. Apoya el pulgar en '
              'el borde del mástil y pisa justo detrás del traste, no sobre el alambre.\n\n'
              'Soltar no es levantar el dedo: tira un poco de la cuerda hacia el piso al soltarla, '
              'así la nota de abajo suena tan fuerte como el tap.',
          en: 'In tapping, a finger of the picking hand frets a note hard and the string sounds '
              'without the pick; then it lets go with a pull-off to a fretting-hand note. That way '
              'you play arpeggios and jumps one hand alone cannot reach. In tab, a T goes above the '
              'note.\n\n'
              'Which finger: the index or middle finger of the picking hand. With the middle, the '
              'pick stays between thumb and index; with the index, tuck it into your palm. Rest your '
              'thumb on the edge of the neck and fret just behind the fret, not on the wire.\n\n'
              'Letting go is not lifting the finger: pull the string slightly toward the floor as '
              'you release it, so the lower note rings as loud as the tap.',
        ),
      ),
      TappingStep(
        id: 'tp1_tap_pull',
        kind: CourseStepKind.exercise,
        title: const LocalizedText(es: 'Tap y pull-off', en: 'Tap and pull-off'),
        body: const LocalizedText(
          es: 'Mano izquierda: el índice en el traste 10 de la 2ª cuerda (A). Mano derecha: '
              'tapping en el traste 17 (E) y pull-off al 10. Solo dos notas, parejas, hasta que las '
              'dos suenen igual de fuerte.',
          en: 'Fretting hand: index on fret 10 of the 2nd string (A). Picking hand: tap fret 17 '
              '(E) and pull off to 10. Just two notes, even, until both sound equally loud.',
        ),
        tab: [
          for (var i = 0; i < 7; i++) ...[
            const TabNote(2, 17, technique: TabTechnique.tap),
            const TabNote(2, 10, technique: TabTechnique.pullOff),
          ],
          tapEnd(2, 17),
        ],
      ),
      TappingStep(
        id: 'tp1_arpeggio',
        kind: CourseStepKind.exercise,
        title: const LocalizedText(es: 'El arpegio de Am', en: 'The Am arpeggio'),
        body: const LocalizedText(
          es: 'Ahora el meñique espera en el traste 13 (C): tapping en el 17, pull-off al 10 y '
              'hammer-on al 13. A, C y E son las notas de Am. Van tres por pulso (tresillos): que '
              'no quede un hueco entre el hammer-on y el tap que sigue.',
          en: 'Now the pinky waits on fret 13 (C): tap 17, pull off to 10 and hammer on to 13. A, '
              'C and E are the notes of Am. They go three per beat (triplets): leave no gap between '
              'the hammer-on and the next tap.',
        ),
        tab: [for (var i = 0; i < 7; i++) ..._am, tapEnd(2, 17)],
      ),
      TappingStep(
        id: 'tp1_down',
        kind: CourseStepKind.exercise,
        title: const LocalizedText(es: 'Al revés', en: 'The other way'),
        body: const LocalizedText(
          es: 'Las mismas tres notas en otro orden: tapping en el 17 (E), pull-off al 13 (C) y '
              'otro pull-off al 10 (A). El índice ya está en el 10 antes de que suelte el meñique.',
          en: 'The same three notes in another order: tap 17 (E), pull off to 13 (C) and pull off '
              'again to 10 (A). The index is already on 10 before the pinky lets go.',
        ),
        tab: [for (var i = 0; i < 7; i++) ...tapTripletDown(2, 17, 13, 10), tapEnd(2, 17)],
      ),
    ],
  ),
  TappingLevel(
    title: const LocalizedText(es: 'Mueve una mano', en: 'Move one hand'),
    intro: const LocalizedText(
      es: 'Una mano se queda y la otra cambia de lugar: así el arpegio cambia de acorde.',
      en: 'One hand stays and the other moves: that is how the arpeggio changes chords.',
    ),
    scale: _aHarmonicMinor,
    steps: [
      const TappingStep(
        id: 'tp2_mute',
        kind: CourseStepKind.theory,
        title: LocalizedText(es: 'Que solo suene una cuerda', en: 'Only one string should ring'),
        body: LocalizedText(
          es: 'Sin púa, las cuerdas que no tocas también vibran, y con distorsión se oyen. Apoya el '
              'canto de la mano derecha sobre las cuerdas graves, cerca del puente, y deja que la '
              'yema del índice izquierdo roce la 1ª cuerda para callarla.\n\n'
              'Pruébalo lento: entre un tap y otro solo debe sonar la nota que pisas.',
          en: 'Without the pick, the strings you are not playing also vibrate, and with distortion '
              'you hear them. Rest the edge of your picking hand on the low strings, near the '
              'bridge, and let the tip of your fretting index brush the 1st string to keep it '
              'quiet.\n\n'
              'Try it slowly: between taps only the note you fret should ring.',
        ),
      ),
      TappingStep(
        id: 'tp2_left_moves',
        kind: CourseStepKind.exercise,
        title: const LocalizedText(es: 'Cambia la izquierda', en: 'Move the fretting hand'),
        body: const LocalizedText(
          es: 'La derecha se queda en el traste 17 (E). La izquierda pasa de Am (10 y 13: A y C) a '
              'E (9 y 12: G# y B). E, G# y B son las notas de E, el V de A menor; la G# sale de la '
              'menor armónica.',
          en: 'The picking hand stays on fret 17 (E). The fretting hand moves from Am (10 and 13: A '
              'and C) to E (9 and 12: G# and B). E, G# and B are the notes of E, the V of A minor; '
              'the G# comes from the harmonic minor.',
        ),
        tab: [..._am, ..._am, ..._e, ..._e, ..._am, ..._am, ..._e, tapEnd(2, 17)],
      ),
      TappingStep(
        id: 'tp2_right_moves',
        kind: CourseStepKind.exercise,
        title: const LocalizedText(es: 'Mueve la derecha', en: 'Move the tapping hand'),
        body: const LocalizedText(
          es: 'Ahora la izquierda se queda en el 10 y el 13 (A y C) y la derecha camina: 17 (E), '
              '18 (F) y 15 (D). Mira la mano que se mueve, no la que se queda.',
          en: 'Now the fretting hand stays on 10 and 13 (A and C) and the tapping hand walks: 17 '
              '(E), 18 (F) and 15 (D). Watch the hand that moves, not the one that stays.',
        ),
        tab: [
          ..._onAm(17),
          ..._onAm(17),
          ..._onAm(18),
          ..._onAm(18),
          ..._onAm(15),
          ..._onAm(15),
          ..._onAm(17),
          tapEnd(2, 17),
        ],
      ),
    ],
  ),
  TappingLevel(
    title: const LocalizedText(es: 'De cuerda en cuerda', en: 'From string to string'),
    intro: const LocalizedText(
      es: 'La pentatónica de A menor en varias cuerdas, con la derecha fija en el traste 17.',
      en: 'The A minor pentatonic across strings, with the tapping hand fixed on fret 17.',
    ),
    scale: _aMinorPentatonic,
    steps: [
      const TappingStep(
        id: 'tp3_nowhere',
        kind: CourseStepKind.theory,
        title: LocalizedText(es: 'Hammer-on desde la nada', en: 'Hammer-on from nowhere'),
        body: LocalizedText(
          es: 'Para pasar a otra cuerda sin púa, un dedo de la mano izquierda cae con fuerza sobre '
              'la cuerda nueva y la hace sonar solo: es un hammer-on desde la nada. En la '
              'tablatura, una h sin nota antes en esa cuerda.\n\n'
              'Suena más suave que un tap, así que pisa con la punta y con decisión, y apaga la '
              'cuerda de arriba al pasar.',
          en: 'To move to another string without the pick, a fretting-hand finger lands hard on the '
              'new string and makes it sound on its own: a hammer-on from nowhere. In tab, an h with '
              'no note before it on that string.\n\n'
              'It sounds softer than a tap, so land with the fingertip and with intent, and mute the '
              'string above as you move.',
        ),
      ),
      TappingStep(
        id: 'tp3_two_strings',
        kind: CourseStepKind.exercise,
        title: const LocalizedText(es: 'Dos cuerdas', en: 'Two strings'),
        body: const LocalizedText(
          es: 'La derecha se queda en el traste 17; la izquierda, entre el 12 y el 15. En la 1ª '
              'cuerda: 17, 12 y 15 (A, E y G). En la 2ª: 17, 13 y 15 (E, C y D). Todas son de la '
              'pentatónica de A menor.',
          en: 'The tapping hand stays on fret 17; the fretting hand, between 12 and 15. On the 1st '
              'string: 17, 12 and 15 (A, E and G). On the 2nd: 17, 13 and 15 (E, C and D). All of '
              'them belong to the A minor pentatonic.',
        ),
        tab: [
          ...tapTriplet(1, 17, 12, 15),
          ...tapTriplet(1, 17, 12, 15),
          ...tapTriplet(2, 17, 13, 15),
          ...tapTriplet(2, 17, 13, 15),
          ...tapTriplet(1, 17, 12, 15),
          ...tapTriplet(1, 17, 12, 15),
          ...tapTriplet(2, 17, 13, 15),
          tapEnd(1, 17),
        ],
      ),
      TappingStep(
        id: 'tp3_down_strings',
        kind: CourseStepKind.exercise,
        title: const LocalizedText(es: 'Bajando de cuerda', en: 'Down the strings'),
        body: const LocalizedText(
          es: 'Cuatro notas por pulso: tapping y pull-off en una cuerda, y en la de abajo un '
              'hammer-on desde la nada y otro hammer-on. Empieza en la 1ª cuerda y baja hasta la 4ª '
              'sin mover la derecha del traste 17.',
          en: 'Four notes per beat: tap and pull-off on one string, then on the string below a '
              'hammer-on from nowhere and another hammer-on. Start on the 1st string and go down to '
              'the 4th without moving the tapping hand off fret 17.',
        ),
        tab: [
          ...tapAndDrop(1, 17, 12, 13, 15),
          ...tapAndDrop(1, 17, 12, 13, 15),
          ...tapAndDrop(2, 17, 13, 12, 14),
          ...tapAndDrop(2, 17, 13, 12, 14),
          ...tapAndDrop(3, 17, 12, 12, 14),
          ...tapAndDrop(3, 17, 12, 12, 14),
          ...tapAndDrop(2, 17, 13, 12, 14),
          tapEnd(1, 17),
        ],
      ),
    ],
  ),
  TappingLevel(
    title: const LocalizedText(es: 'El trino con las dos manos', en: 'The two-hand trill'),
    intro: const LocalizedText(
      es: 'Dos notas que se turnan rápido entre las manos, en un lugar y subiendo por el mástil.',
      en: 'Two notes traded quickly between the hands, in one spot and moving up the neck.',
    ),
    scale: _aHarmonicMinor,
    steps: [
      const TappingStep(
        id: 'tp4_trill_idea',
        kind: CourseStepKind.theory,
        title: LocalizedText(es: 'El trino', en: 'The trill'),
        body: LocalizedText(
          es: 'Un trino alterna dos notas lo más rápido que puedas. Con el tapping, las manos se '
              'turnan: tapping arriba, pull-off abajo, y otra vez.\n\n'
              'Empieza lento, con las dos notas parejas y el mismo volumen: la velocidad llega sola. '
              'Si se te enredan las manos, vuelve a un tempo en que salga limpio.',
          en: 'A trill alternates two notes as fast as you can. With tapping, the hands take turns: '
              'tap above, pull off below, and again.\n\n'
              'Start slowly, with both notes even and at the same volume: speed comes on its own. '
              'If your hands get tangled, go back to a tempo where it comes out clean.',
        ),
      ),
      TappingStep(
        id: 'tp4_trill',
        kind: CourseStepKind.exercise,
        title: const LocalizedText(es: 'Trino en una cuerda', en: 'Trill on one string'),
        body: const LocalizedText(
          es: 'En la 2ª cuerda: tapping en el 17 (E) y pull-off al 13 (C), cuatro notas por pulso '
              '(semicorcheas).',
          en: 'On the 2nd string: tap 17 (E) and pull off to 13 (C), four notes per beat '
              '(sixteenths).',
        ),
        tab: [...tapTrill(2, 17, 13, 7), tapEnd(2, 17)],
      ),
      TappingStep(
        id: 'tp4_trill_climb',
        kind: CourseStepKind.exercise,
        title: const LocalizedText(es: 'El trino sube', en: 'The trill climbs'),
        body: const LocalizedText(
          es: 'El trino cambia de lugar: 15 y 12 (D y B), 17 y 13 (E y C), 18 y 15 '
              '(F y D). Las dos manos se mueven juntas: que el cambio no deje un hueco.',
          en: 'The trill changes place: 15 and 12 (D and B), 17 and 13 (E and C), '
              '18 and 15 (F and D). Both hands move together: leave no gap at the change.',
        ),
        tab: [
          ...tapTrill(2, 15, 12, 2),
          ...tapTrill(2, 17, 13, 2),
          ...tapTrill(2, 18, 15, 2),
          ...tapTrill(2, 17, 13, 1),
          tapEnd(2, 17),
        ],
      ),
      TappingStep(
        id: 'tp4_final',
        kind: CourseStepKind.exercise,
        title: const LocalizedText(es: 'Todo junto', en: 'All together'),
        body: const LocalizedText(
          es: 'Los arpegios de Am y E en tresillos, y para cerrar el trino de E y C que cae al A '
              'del traste 10.',
          en: 'The Am and E arpeggios in triplets, and to finish the E and C trill that falls to '
              'the A on fret 10.',
        ),
        tab: [
          ..._am,
          ..._am,
          ..._e,
          ..._e,
          ...tapTrill(2, 17, 13, 3),
          const TabNote(2, 10, technique: TabTechnique.pullOff, length: tabQuarter),
        ],
      ),
      // Armónicos con tap (decisión del usuario: un paso al final del curso).
      TappingStep(
        id: 'tp4_harmonics',
        kind: CourseStepKind.exercise,
        title: const LocalizedText(es: 'Armónicos con tap', en: 'Tapped harmonics'),
        body: const LocalizedText(
          es: 'Pisa la nota, púlsala y, con un dedo de la mano derecha, golpea justo sobre el alambre '
              '12 trastes más arriba y suéltalo enseguida: suena la misma nota una octava arriba, como '
              'una campana. En Am: A (2 y 14), C (1 y 13), E (5 y 17) y A (5 y 17 en la 1ª); en E: B '
              '(4 y 16), G# (1 y 13) y E (5 y 17), y cierra en el A.',
          en: 'Fret the note, pick it and, with a right-hand finger, strike right over the wire 12 '
              'frets higher and let go at once: the same note rings an octave up, like a bell. On Am: '
              'A (2 and 14), C (1 and 13), E (5 and 17) and A (5 and 17 on the 1st); on E: B (4 and '
              '16), G# (1 and 13) and E (5 and 17), and it ends on the A.',
        ),
        tab: [
          for (final (string, fret) in const [(3, 2), (2, 1), (2, 5), (1, 5), (3, 4), (3, 1), (2, 5)]) ...[
            TabNote(string, fret),
            TabNote(string, fret + 12, technique: TabTechnique.tapHarmonic),
          ],
          const TabNote(3, 2, length: tabQuarter),
        ],
      ),
    ],
  ),
];

/// Pasos por id.
final Map<String, TappingStep> tappingStepsById = {
  for (final s in courseSteps(tappingCourse)) s.id: s,
};
