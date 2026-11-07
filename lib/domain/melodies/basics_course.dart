/// Primeros pasos (Fundamentos): conocer la guitarra, afinar, pisar un traste,
/// luego dos y tres, sumar la 2ª y la 3ª cuerda y el dedo medio, con melodías
/// de dominio público que solo usan lo aprendido. Mismo modelo que Melodías
/// ([MelodyStep]): las notas se escriben como alturas y la tablatura sale por
/// regla, dentro de las cuerdas y trastes de cada paso.
library;

import '../../core/i18n/tr.dart';
import '../courses/course.dart';
import '../lessons/lesson.dart';
import 'melody_course.dart';

const _cMajor = LessonScale(scaleId: 'major', root: 0);

const basicsCourse = [
  MelodyLevel(
    title: LocalizedText(es: 'Primeros pasos', en: 'First steps'),
    intro: LocalizedText(
      es: 'Conoce la guitarra, afínala, aprende a sostenerla y toca las seis '
          'cuerdas al aire.',
      en: 'Meet the guitar, tune it, learn how to hold it and play the six open '
          'strings.',
    ),
    scale: _cMajor,
    steps: [
      MelodyStep(
        id: 'b_meet',
        kind: CourseStepKind.theory,
        title: LocalizedText(es: 'Conoce tu guitarra', en: 'Meet your guitar'),
        body: LocalizedText(
          es: 'Las cuerdas se cuentan desde la más delgada: la 1ª es la E aguda y '
              'la 6ª, la E grave. Al aire, de la 6ª a la 1ª, suenan E, A, D, G, B '
              'y E. Los trastes son las casillas entre los alambres del mástil; '
              'el traste 1 es el más cercano a la cabeza.',
          en: 'Strings are counted from the thinnest: the 1st is the high E and '
              'the 6th, the low E. Open, from the 6th to the 1st, they sound E, A, '
              'D, G, B and E. Frets are the spaces between the wires on the neck; '
              'fret 1 is the one closest to the headstock.',
        ),
      ),
      MelodyStep(
        id: 'b_tune',
        kind: CourseStepKind.theory,
        title: LocalizedText(es: 'Afina tu guitarra', en: 'Tune your guitar'),
        body: LocalizedText(
          es: 'Antes de tocar, afina: en la pestaña Afinar, toca una cuerda al '
              'aire y gira su clavija hasta que la aguja quede en el centro. '
              'Empieza por la 6ª y termina en la 1ª.',
          en: 'Before playing, tune up: in the Tune tab, play an open string and '
              'turn its tuning peg until the needle sits in the middle. Start '
              'with the 6th and finish with the 1st.',
        ),
      ),
      MelodyStep(
        id: 'b_hold',
        kind: CourseStepKind.theory,
        title: LocalizedText(es: 'Cómo sostener la guitarra y la púa', en: 'Holding the guitar and the pick'),
        body: LocalizedText(
          es: 'Siéntate derecho, con la guitarra apoyada en la pierna y el mástil '
              'un poco hacia arriba. Sostén la púa entre el pulgar y el costado '
              'del índice, con poca punta afuera. Pulsa una cuerda a la vez con '
              'un movimiento corto.',
          en: 'Sit up straight, with the guitar resting on your leg and the neck '
              'tilted slightly up. Hold the pick between your thumb and the side '
              'of your index finger, with little of the tip showing. Pick one '
              'string at a time with a short motion.',
        ),
      ),
      MelodyStep(
        id: 'b_open',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: 'Las seis cuerdas al aire', en: 'The six open strings'),
        body: LocalizedText(
          es: 'De la 6ª a la 1ª y de vuelta, una cuerda por nota, sin pisar nada.',
          en: 'From the 6th to the 1st and back, one string per note, without '
              'fretting anything.',
        ),
        pitches: ['E2', 'A2', 'D3', 'G3', 'B3', 'E4', 'E4', 'B3', 'G3', 'D3', 'A2', 'E2'],
        maxFret: 0,
      ),
    ],
  ),
  MelodyLevel(
    title: LocalizedText(es: 'Aprende a pisar', en: 'Learn to fret'),
    intro: LocalizedText(
      es: 'Tu primer traste en la 1ª cuerda, con el índice, y luego dos.',
      en: 'Your first fret on the 1st string, with the index finger, then two.',
    ),
    scale: _cMajor,
    steps: [
      MelodyStep(
        id: 'b_fret_how',
        kind: CourseStepKind.theory,
        title: LocalizedText(es: 'Cómo se pisa un traste', en: 'How to fret a note'),
        body: LocalizedText(
          es: 'Pisa con la punta del dedo, justo detrás del alambre, no encima. '
              'El pulgar descansa detrás del mástil. En la 1ª cuerda, el traste 1 '
              'pisado con el índice suena F.',
          en: 'Press with your fingertip right behind the wire, not on top of '
              'it. Your thumb rests behind the neck. On the 1st string, fret 1 '
              'pressed with your index finger sounds F.',
        ),
      ),
      MelodyStep(
        id: 'b_fret_index',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: 'El índice en el traste 1', en: 'Index finger on fret 1'),
        body: LocalizedText(
          es: 'E al aire y F en el traste 1, una y otra vez, en la 1ª cuerda.',
          en: 'Open E and F on fret 1, again and again, on the 1st string.',
        ),
        pitches: ['E4', 'F4', 'E4', 'F4', 'E4', 'F4', 'E4', 'F4'],
        maxFret: 1,
        strings: {1},
      ),
      MelodyStep(
        id: 'b_fret_hints',
        kind: CourseStepKind.theory,
        title: LocalizedText(es: 'Consejos para pisar', en: 'Fretting tips'),
        body: LocalizedText(
          es: 'Si la nota zumba, acerca el dedo al alambre o aprieta un poco más; '
              'si suena apagada, levanta la palma para que el dedo quede de punta. '
              'No hace falta mucha fuerza: solo la que la nota necesita para '
              'sonar limpia.',
          en: 'If the note buzzes, move your finger closer to the wire or press a '
              'little harder; if it sounds muted, lift your palm so the finger '
              'stands on its tip. You do not need much strength: just what the '
              'note needs to ring clean.',
        ),
      ),
      MelodyStep(
        id: 'b_fret_two',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: 'Dos trastes: 1 y 3', en: 'Two frets: 1 and 3'),
        body: LocalizedText(
          es: 'El índice en el traste 1 (F) y el anular en el 3 (G), en la 1ª cuerda.',
          en: 'Index finger on fret 1 (F) and ring finger on fret 3 (G), on the 1st '
              'string.',
        ),
        pitches: ['E4', 'F4', 'G4', 'F4', 'E4', 'F4', 'G4', 'F4', 'E4'],
        strings: {1},
      ),
    ],
  ),
  MelodyLevel(
    title: LocalizedText(es: 'Varios trastes', en: 'Several frets'),
    intro: LocalizedText(
      es: 'Un dedo por traste: sube y baja por la 1ª cuerda sin mover la mano.',
      en: 'One finger per fret: go up and down the 1st string without moving '
          'your hand.',
    ),
    scale: _cMajor,
    steps: [
      MelodyStep(
        id: 'b_frets_rule',
        kind: CourseStepKind.theory,
        title: LocalizedText(es: 'Un dedo por traste', en: 'One finger per fret'),
        body: LocalizedText(
          es: 'Cerca de la cabeza, cada dedo tiene su traste: el índice en el 1, '
              'el medio en el 2, el anular en el 3 y el meñique en el 4. Así la '
              'mano no salta y cada nota está a un dedo de distancia.',
          en: 'Near the headstock, each finger has its own fret: index on 1, '
              'middle on 2, ring on 3 and pinky on 4. That way your hand does not '
              'jump and every note is one finger away.',
        ),
      ),
      MelodyStep(
        id: 'b_frets_updown',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: 'Sube y baja en la 1ª', en: 'Up and down the 1st string'),
        body: LocalizedText(
          es: 'E, F y G subiendo y bajando, con el índice y el anular.',
          en: 'E, F and G up and down, with your index and ring fingers.',
        ),
        pitches: ['E4', 'F4', 'G4', 'F4', 'E4', 'G4', 'F4', 'E4'],
        strings: {1},
      ),
      MelodyStep(
        id: 'b_frets_finale',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: 'Final: la 1ª cuerda', en: 'Finale: the 1st string'),
        body: LocalizedText(
          es: 'Diez notas seguidas en la 1ª cuerda. Si una zumba, revisa el dedo y sigue.',
          en: 'Ten notes in a row on the 1st string. If one buzzes, check the '
              'finger and keep going.',
        ),
        pitches: ['E4', 'F4', 'G4', 'F4', 'E4', 'F4', 'G4', 'G4', 'F4', 'E4'],
        strings: {1},
      ),
    ],
  ),
  MelodyLevel(
    title: LocalizedText(es: 'Dos cuerdas', en: 'Two strings'),
    intro: LocalizedText(
      es: 'Suma la 2ª cuerda y toca tus primeras canciones.',
      en: 'Add the 2nd string and play your first songs.',
    ),
    scale: _cMajor,
    steps: [
      MelodyStep(
        id: 'b_two_add',
        kind: CourseStepKind.theory,
        title: LocalizedText(es: 'Agrega la 2ª cuerda', en: 'Add the 2nd string'),
        body: LocalizedText(
          es: 'La 2ª cuerda al aire es B. En el traste 1 suena C y en el 3, D. '
              'Del D de la 2ª al E de la 1ª al aire hay un solo paso de la escala.',
          en: 'The open 2nd string is B. Fret 1 sounds C and fret 3, D. From the D '
              'on the 2nd string to the open E of the 1st is a single scale step.',
        ),
      ),
      MelodyStep(
        id: 'b_two_open',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: 'Dos cuerdas al aire', en: 'Two open strings'),
        body: LocalizedText(
          es: 'B de la 2ª y E de la 1ª, alternando, sin pisar nada.',
          en: 'B on the 2nd and E on the 1st, alternating, without fretting.',
        ),
        pitches: ['B3', 'E4', 'B3', 'E4', 'B3', 'E4', 'B3', 'E4'],
        maxFret: 0,
        strings: {1, 2},
      ),
      MelodyStep(
        id: 'b_two_fret',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: 'Pisa la 2ª cuerda', en: 'Fret the 2nd string'),
        body: LocalizedText(
          es: 'B, C y D en la 2ª cuerda, y llega al E de la 1ª.',
          en: 'B, C and D on the 2nd string, then reach the E of the 1st.',
        ),
        pitches: ['B3', 'C4', 'D4', 'C4', 'B3', 'C4', 'D4', 'E4'],
        strings: {1, 2},
      ),
      MelodyStep(
        id: 'b_two_pain',
        kind: CourseStepKind.theory,
        title: LocalizedText(es: 'Sobre el dolor en los dedos', en: 'About sore fingers'),
        body: LocalizedText(
          es: 'Al principio las yemas duelen: es normal y pasa en unas semanas, '
              'cuando se forma callo. Practica ratos cortos y descansa si duele '
              'mucho. Un dolor fuerte o en la muñeca no es normal: para.',
          en: 'At first your fingertips hurt: that is normal and it goes away in a '
              'few weeks, once calluses form. Practice in short sessions and rest '
              'if it hurts a lot. Sharp pain or pain in your wrist is not normal: '
              'stop.',
        ),
      ),
      MelodyStep(
        id: 'b_two_buns',
        kind: CourseStepKind.song,
        title: LocalizedText(es: 'Hot Cross Buns', en: 'Hot Cross Buns'),
        body: LocalizedText(
          es: 'Tres notas: E de la 1ª al aire, D y C de la 2ª.',
          en: 'Three notes: open E on the 1st, D and C on the 2nd.',
        ),
        origin: LocalizedText(es: 'Tradicional (Inglaterra, s. XVIII)', en: 'Traditional (England, 18th c.)'),
        pitches: [
          'E4', 'D4', 'C4', 'E4', 'D4', 'C4', //
          'C4', 'C4', 'C4', 'C4', 'D4', 'D4', 'D4', 'D4',
          'E4', 'D4', 'C4',
        ],
        strings: {1, 2},
      ),
      MelodyStep(
        id: 'b_two_lune',
        kind: CourseStepKind.song,
        title: LocalizedText(es: 'Au clair de la lune', en: 'Au clair de la lune'),
        body: LocalizedText(
          es: 'C, D y E: empieza en el traste 1 de la 2ª cuerda.',
          en: 'C, D and E: it starts on fret 1 of the 2nd string.',
        ),
        origin: LocalizedText(es: 'Tradicional (Francia, s. XVIII)', en: 'Traditional (France, 18th c.)'),
        pitches: ['C4', 'C4', 'C4', 'D4', 'E4', 'D4', 'C4', 'E4', 'D4', 'D4', 'C4'],
        strings: {1, 2},
      ),
    ],
  ),
  MelodyLevel(
    title: LocalizedText(es: 'El dedo medio', en: 'The middle finger'),
    intro: LocalizedText(
      es: 'Suma la 3ª cuerda y el dedo medio: ya tienes ocho notas.',
      en: 'Add the 3rd string and the middle finger: you now have eight notes.',
    ),
    scale: _cMajor,
    steps: [
      MelodyStep(
        id: 'b_mid_how',
        kind: CourseStepKind.theory,
        title: LocalizedText(es: 'Pisa con el dedo medio', en: 'Fret with the middle finger'),
        body: LocalizedText(
          es: 'El dedo medio va en el traste 2. En la 3ª cuerda, al aire suena G '
              'y en el traste 2 suena A: dos notas vecinas de la escala.',
          en: 'The middle finger goes on fret 2. On the 3rd string, open sounds G '
              'and fret 2 sounds A: two neighbouring scale notes.',
        ),
      ),
      MelodyStep(
        id: 'b_mid_ga',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: 'G y A en la 3ª', en: 'G and A on the 3rd string'),
        body: LocalizedText(
          es: 'G al aire y A con el dedo medio, y de paso el B de la 2ª al aire.',
          en: 'Open G and A with the middle finger, plus the open B of the 2nd.',
        ),
        pitches: ['G3', 'A3', 'G3', 'A3', 'B3', 'A3', 'G3', 'A3'],
        maxFret: 2,
        strings: {2, 3},
      ),
      MelodyStep(
        id: 'b_mid_ladder',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: 'De G a G', en: 'From G to G'),
        body: LocalizedText(
          es: 'Las ocho notas de G a G, de la 3ª cuerda a la 1ª.',
          en: 'The eight notes from G to G, from the 3rd string to the 1st.',
        ),
        pitches: ['G3', 'A3', 'B3', 'C4', 'D4', 'E4', 'F4', 'G4'],
      ),
      MelodyStep(
        id: 'b_mid_twinkle',
        kind: CourseStepKind.song,
        title: LocalizedText(es: 'Estrellita en G', en: 'Twinkle in G'),
        body: LocalizedText(
          es: 'En G: empieza en la 3ª cuerda al aire y llega al E de la 1ª.',
          en: 'In G: it starts on the open 3rd string and reaches the E of the 1st.',
        ),
        origin: LocalizedText(es: 'Tradicional (Francia, s. XVIII)', en: 'Traditional (France, 18th c.)'),
        pitches: [
          'G3', 'G3', 'D4', 'D4', 'E4', 'E4', 'D4', //
          'C4', 'C4', 'B3', 'B3', 'A3', 'A3', 'G3',
        ],
      ),
    ],
  ),
  MelodyLevel(
    title: LocalizedText(es: 'Final del curso', en: 'Course finale'),
    intro: LocalizedText(
      es: 'Todo lo de Primeros pasos en tres partes.',
      en: 'Everything from First steps in three parts.',
    ),
    scale: _cMajor,
    steps: [
      MelodyStep(
        id: 'b_final_1',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: 'Parte 1: cuerdas y trastes', en: 'Part 1: strings and frets'),
        body: LocalizedText(
          es: 'Las seis cuerdas al aire y luego F y G en la 1ª.',
          en: 'The six open strings, then F and G on the 1st.',
        ),
        pitches: ['E2', 'A2', 'D3', 'G3', 'B3', 'E4', 'F4', 'G4'],
      ),
      MelodyStep(
        id: 'b_final_2',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: 'Parte 2: la escalera', en: 'Part 2: the ladder'),
        body: LocalizedText(
          es: 'De G a G, ida y vuelta.',
          en: 'From G to G, up and back.',
        ),
        pitches: [
          'G3', 'A3', 'B3', 'C4', 'D4', 'E4', 'F4', 'G4', //
          'F4', 'E4', 'D4', 'C4', 'B3', 'A3', 'G3',
        ],
      ),
      MelodyStep(
        id: 'b_final_3',
        kind: CourseStepKind.song,
        title: LocalizedText(es: 'Parte 3: Himno de la alegría', en: 'Part 3: Ode to Joy'),
        body: LocalizedText(
          es: 'En C, entre la 1ª y la 2ª cuerda.',
          en: 'In C, across the 1st and 2nd strings.',
        ),
        origin: LocalizedText(
          es: 'Ludwig van Beethoven, Novena sinfonía (1824)',
          en: 'Ludwig van Beethoven, Ninth Symphony (1824)',
        ),
        pitches: [
          'E4', 'E4', 'F4', 'G4', 'G4', 'F4', 'E4', 'D4', //
          'C4', 'C4', 'D4', 'E4', 'E4', 'D4', 'D4',
        ],
        strings: {1, 2},
      ),
    ],
  ),
];

/// Pasos de Primeros pasos por id.
final Map<String, MelodyStep> basicsStepsById = {
  for (final l in basicsCourse)
    for (final s in l.steps) s.id: s,
};
