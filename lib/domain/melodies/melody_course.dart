/// Cursos de melodía por niveles (Primeros pasos y Melodías): teoría,
/// ejercicios y canciones de dominio público. Las melodías se escriben como
/// alturas ("C4") y la tablatura sale por regla ([tabForPitches]): nada de
/// trastes a mano. Un test verifica que cada nota caiga en su ventana de
/// trastes y en sus cuerdas, y que pertenezca a la escala del nivel.
library;

import '../../core/i18n/tr.dart';
import '../courses/course.dart';
import '../lessons/lesson.dart';
import '../practice/scale_workouts.dart';
import '../theory/notes.dart';

/// MIDI de una nota con octava: "C4" = 60, "G3" = 55, "C#5" = 73.
int pitchMidi(String pitch) {
  final octave = int.parse(pitch.substring(pitch.length - 1));
  return (octave + 1) * 12 + noteIndex(pitch.substring(0, pitch.length - 1));
}

/// MIDI de una nota de tablatura (cuerda 1 = mi aguda).
int tabMidi(TabNote n) => standardOpenStringMidi[n.string - 1] + n.fret;

/// Tablatura de [pitches] dentro de la ventana de trastes [minFret]–[maxFret]
/// y, si se dan, solo en las cuerdas [strings]: cada nota va en la cuerda
/// donde cae en la ventana; si cabe en dos, en la del traste más bajo. Lanza
/// si alguna no cabe (es un error del curso).
List<TabNote> tabForPitches(
  List<String> pitches, {
  int minFret = 0,
  int maxFret = 3,
  Set<int>? strings,
}) => [
  for (final p in pitches) _place(pitchMidi(p), minFret, maxFret, strings, p),
];

TabNote _place(int midi, int minFret, int maxFret, Set<int>? strings, String name) {
  TabNote? best;
  for (var s = 1; s <= 6; s++) {
    if (strings != null && !strings.contains(s)) continue;
    final fret = midi - standardOpenStringMidi[s - 1];
    if (fret < minFret || fret > maxFret) continue;
    if (best == null || fret < best.fret) best = TabNote(s, fret);
  }
  if (best == null) {
    throw ArgumentError('$name no cabe entre los trastes $minFret y $maxFret');
  }
  return best;
}

/// Un paso de un curso de melodía. Los de teoría no tienen notas.
class MelodyStep implements CourseStep {
  const MelodyStep({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.pitches = const [],
    this.minFret = 0,
    this.maxFret = 3,
    this.strings,
    this.pattern,
    this.bothWays = false,
    this.origin,
  });

  @override
  final String id;
  @override
  final CourseStepKind kind;
  @override
  final LocalizedText title;
  final LocalizedText body;

  /// Alturas en orden (las de un ejercicio con [pattern] son su escalera).
  final List<String> pitches;
  final int minFret;
  final int maxFret;

  /// Cuerdas permitidas (1 = mi aguda); `null` = cualquiera.
  final Set<int>? strings;

  /// Un ejercicio con patrón recorre la escalera como las rutinas de escala
  /// (terceras, grupos de 3 o de 4): subiendo o, con [bothWays], también
  /// bajando.
  final WorkoutPattern? pattern;
  final bool bothWays;

  @override
  final LocalizedText? origin;

  /// La tablatura que se toca.
  List<TabNote> get tab {
    final notes = tabForPitches(
      pitches,
      minFret: minFret,
      maxFret: maxFret,
      strings: strings,
    );
    final p = pattern;
    if (p == null) return notes;
    return workoutNotes(
      p,
      notes,
      direction: bothWays ? WorkoutDirection.both : WorkoutDirection.up,
    );
  }
}

class MelodyLevel extends CourseLevel<MelodyStep> {
  const MelodyLevel({
    required super.title,
    required super.intro,
    required this.scale,
    required super.steps,
  });

  /// Escala de todas sus notas (un test lo verifica).
  final LessonScale scale;
}

const _cMajor = LessonScale(scaleId: 'major', root: 0);

/// La escalera de G a G (3ª cuerda a 1ª, al aire y trastes 1–3).
const _ladderG = ['G3', 'A3', 'B3', 'C4', 'D4', 'E4', 'F4', 'G4'];

/// La escalera de C a C en la posición V (trastes 5–8).
const _ladderC5 = ['C4', 'D4', 'E4', 'F4', 'G4', 'A4', 'B4', 'C5'];

const _ode = [
  'E4', 'E4', 'F4', 'G4', 'G4', 'F4', 'E4', 'D4', //
  'C4', 'C4', 'D4', 'E4', 'E4', 'D4', 'D4',
  'E4', 'E4', 'F4', 'G4', 'G4', 'F4', 'E4', 'D4',
  'C4', 'C4', 'D4', 'E4', 'D4', 'C4', 'C4',
];

const _twinkle = [
  'C4', 'C4', 'G4', 'G4', 'A4', 'A4', 'G4', //
  'F4', 'F4', 'E4', 'E4', 'D4', 'D4', 'C4',
  'G4', 'G4', 'F4', 'F4', 'E4', 'E4', 'D4',
  'G4', 'G4', 'F4', 'F4', 'E4', 'E4', 'D4',
  'C4', 'C4', 'G4', 'G4', 'A4', 'A4', 'G4',
  'F4', 'F4', 'E4', 'E4', 'D4', 'D4', 'C4',
];

const _london = [
  'G4', 'A4', 'G4', 'F4', 'E4', 'F4', 'G4', //
  'D4', 'E4', 'F4', 'E4', 'F4', 'G4',
  'G4', 'A4', 'G4', 'F4', 'E4', 'F4', 'G4',
  'D4', 'G4', 'E4', 'C4',
];

const _odeOrigin = LocalizedText(
  es: 'Ludwig van Beethoven, Novena sinfonía (1824)',
  en: 'Ludwig van Beethoven, Ninth Symphony (1824)',
);
const _twinkleOrigin = LocalizedText(
  es: 'Tradicional (Francia, s. XVIII)',
  en: 'Traditional (France, 18th c.)',
);
const _londonOrigin = LocalizedText(
  es: 'Tradicional (Inglaterra, s. XVII)',
  en: 'Traditional (England, 17th c.)',
);

/// Melodías: de una cuerda a la vez a tocar de memoria, pasando por combinar
/// cuerdas, subir y bajar, el mástil, patrones y velocidad.
const melodyCourse = [
  MelodyLevel(
    title: LocalizedText(es: 'Una cuerda a la vez', en: 'One string at a time'),
    intro: LocalizedText(
      es: 'Melodías en una sola cuerda: solo mueves la mano por los trastes.',
      en: 'Melodies on a single string: you only move your hand along the frets.',
    ),
    scale: _cMajor,
    steps: [
      MelodyStep(
        id: 'mo_theory',
        kind: CourseStepKind.theory,
        title: LocalizedText(es: 'Una melodía en una sola cuerda', en: 'A melody on one string'),
        body: LocalizedText(
          es: 'En una misma cuerda, cada traste sube la nota. En la 1ª cuerda: E '
              'al aire, F en el traste 1, G en el 3 y A en el 5. Así tocas una '
              'melodía sin cambiar de cuerda, solo moviendo la mano.',
          en: 'On a single string, each fret raises the note. On the 1st string: '
              'open E, F on fret 1, G on fret 3 and A on fret 5. That way you play '
              'a melody without changing strings, just moving your hand.',
        ),
      ),
      MelodyStep(
        id: 'mo_first',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: 'Melodía en la 1ª cuerda', en: 'Melody on the 1st string'),
        body: LocalizedText(
          es: 'De E a A y de vuelta, todo en la 1ª cuerda.',
          en: 'From E to A and back, all on the 1st string.',
        ),
        pitches: ['E4', 'F4', 'G4', 'A4', 'G4', 'F4', 'E4', 'F4', 'G4', 'E4'],
        maxFret: 5,
        strings: {1},
      ),
      MelodyStep(
        id: 'mo_second',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: 'Melodía en la 2ª cuerda', en: 'Melody on the 2nd string'),
        body: LocalizedText(
          es: 'De B a E y de vuelta, todo en la 2ª cuerda.',
          en: 'From B to E and back, all on the 2nd string.',
        ),
        pitches: ['B3', 'C4', 'D4', 'E4', 'D4', 'C4', 'B3', 'C4', 'D4', 'B3'],
        maxFret: 5,
        strings: {2},
      ),
      MelodyStep(
        id: 'mo_third',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: 'Melodía en la 3ª cuerda', en: 'Melody on the 3rd string'),
        body: LocalizedText(
          es: 'De G a C y de vuelta, todo en la 3ª cuerda.',
          en: 'From G to C and back, all on the 3rd string.',
        ),
        pitches: ['G3', 'A3', 'B3', 'C4', 'B3', 'A3', 'G3', 'A3', 'B3', 'G3'],
        maxFret: 5,
        strings: {3},
      ),
      MelodyStep(
        id: 'mo_ode',
        kind: CourseStepKind.song,
        title: LocalizedText(es: 'Himno de la alegría en una cuerda', en: 'Ode to Joy on one string'),
        body: LocalizedText(
          es: 'Toda en la 2ª cuerda: C en el traste 1, D en el 3, E en el 5, F en '
              'el 6 y G en el 8.',
          en: 'All on the 2nd string: C on fret 1, D on 3, E on 5, F on 6 and G '
              'on 8.',
        ),
        origin: _odeOrigin,
        pitches: _ode,
        maxFret: 8,
        strings: {2},
      ),
    ],
  ),
  MelodyLevel(
    title: LocalizedText(es: 'Combina cuerdas', en: 'Combine strings'),
    intro: LocalizedText(
      es: 'La misma melodía repartida en dos cuerdas: menos salto de mano.',
      en: 'The same melody spread over two strings: less hand movement.',
    ),
    scale: _cMajor,
    steps: [
      MelodyStep(
        id: 'mc_theory',
        kind: CourseStepKind.theory,
        title: LocalizedText(es: 'Cambiar de cuerda', en: 'Changing strings'),
        body: LocalizedText(
          es: 'Al pasar de una cuerda a otra, levanta el dedo justo cuando suena '
              'la nota siguiente. El D del traste 3 de la 2ª cuerda y el E de la '
              '1ª al aire son notas vecinas de la escala: pasar de una a otra es '
              'un solo paso.',
          en: 'When you move to another string, lift the finger just as the next '
              'note sounds. The D on fret 3 of the 2nd string and the open E of '
              'the 1st are neighbouring scale notes: going from one to the other '
              'is a single step.',
        ),
      ),
      MelodyStep(
        id: 'mc_12',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: '1ª y 2ª cuerdas', en: '1st and 2nd strings'),
        body: LocalizedText(
          es: 'De B a G y de vuelta, entre las dos cuerdas más agudas.',
          en: 'From B to G and back, across the two highest strings.',
        ),
        pitches: ['B3', 'C4', 'D4', 'E4', 'F4', 'G4', 'F4', 'E4', 'D4', 'C4', 'B3'],
        strings: {1, 2},
      ),
      MelodyStep(
        id: 'mc_23',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: '2ª y 3ª cuerdas', en: '2nd and 3rd strings'),
        body: LocalizedText(
          es: 'De G a D y de vuelta, entre la 3ª y la 2ª cuerda.',
          en: 'From G to D and back, across the 3rd and 2nd strings.',
        ),
        pitches: ['G3', 'A3', 'B3', 'C4', 'D4', 'C4', 'B3', 'A3', 'G3'],
        strings: {2, 3},
      ),
      MelodyStep(
        id: 'mc_twinkle',
        kind: CourseStepKind.song,
        title: LocalizedText(es: 'Estrellita', en: 'Twinkle, Twinkle, Little Star'),
        body: LocalizedText(
          es: 'En C, entre la 1ª y la 2ª cuerda. Su A está en el traste 5 de la 1ª.',
          en: 'In C, across the 1st and 2nd strings. Its A is on fret 5 of the 1st.',
        ),
        origin: _twinkleOrigin,
        pitches: _twinkle,
        maxFret: 5,
      ),
      MelodyStep(
        id: 'mc_frere',
        kind: CourseStepKind.song,
        title: LocalizedText(es: 'Martinillo', en: 'Frère Jacques'),
        body: LocalizedText(
          es: 'El canon, en C. Al final baja al G al aire de la 3ª cuerda.',
          en: 'The round, in C. At the end it drops to the open G of the 3rd string.',
        ),
        origin: LocalizedText(es: 'Tradicional (Francia, s. XVIII)', en: 'Traditional (France, 18th c.)'),
        pitches: [
          'C4', 'D4', 'E4', 'C4', 'C4', 'D4', 'E4', 'C4', //
          'E4', 'F4', 'G4', 'E4', 'F4', 'G4',
          'G4', 'A4', 'G4', 'F4', 'E4', 'C4',
          'G4', 'A4', 'G4', 'F4', 'E4', 'C4',
          'C4', 'G3', 'C4', 'C4', 'G3', 'C4',
        ],
        maxFret: 5,
      ),
    ],
  ),
  MelodyLevel(
    title: LocalizedText(es: 'Sube y baja', en: 'Up and down'),
    intro: LocalizedText(
      es: 'La escala como una escalera: subir, bajar y saltar peldaños.',
      en: 'The scale as a ladder: climbing, coming down and skipping steps.',
    ),
    scale: _cMajor,
    steps: [
      MelodyStep(
        id: 'mu_theory',
        kind: CourseStepKind.theory,
        title: LocalizedText(es: 'La escalera de la melodía', en: 'The melody ladder'),
        body: LocalizedText(
          es: 'Una escala es una escalera: cada nota es un peldaño. De G a G hay '
              'ocho notas. Subir y bajar sin saltarte peldaños enseña a la mano '
              'dónde está cada una.',
          en: 'A scale is a ladder: each note is a step. From G to G there are '
              'eight notes. Going up and down without skipping steps teaches your '
              'hand where each one is.',
        ),
      ),
      MelodyStep(
        id: 'mu_ladder',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: 'De G a G, ida y vuelta', en: 'G to G, up and back'),
        body: LocalizedText(
          es: 'Sube de la 3ª cuerda a la 1ª y baja otra vez.',
          en: 'Climb from the 3rd string to the 1st and come back down.',
        ),
        pitches: _ladderG,
        pattern: WorkoutPattern.upDown,
        bothWays: true,
      ),
      MelodyStep(
        id: 'mu_thirds',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: 'Saltos de tercera', en: 'Leaps of a third'),
        body: LocalizedText(
          es: 'G-B, A-C, B-D… cada nota y la que está dos peldaños más arriba.',
          en: 'G-B, A-C, B-D… each note and the one two steps higher.',
        ),
        pitches: _ladderG,
        pattern: WorkoutPattern.thirds,
      ),
      MelodyStep(
        id: 'mu_london',
        kind: CourseStepKind.song,
        title: LocalizedText(es: 'El puente de Londres', en: 'London Bridge'),
        body: LocalizedText(
          es: 'En C. La melodía baja de G a E y vuelve a subir.',
          en: 'In C. The melody steps down from G to E and climbs back up.',
        ),
        origin: _londonOrigin,
        pitches: _london,
        maxFret: 5,
      ),
    ],
  ),
  MelodyLevel(
    title: LocalizedText(es: 'Explora el mástil', en: 'Explore the neck'),
    intro: LocalizedText(
      es: 'Las mismas notas más arriba, en la posición V.',
      en: 'The same notes higher up, in position V.',
    ),
    scale: _cMajor,
    steps: [
      MelodyStep(
        id: 'mn_theory',
        kind: CourseStepKind.theory,
        title: LocalizedText(es: 'La misma nota en otro lugar', en: 'The same note somewhere else'),
        body: LocalizedText(
          es: 'Pon el índice en el traste 5. El C del traste 5 de la 3ª cuerda es '
              'el mismo C del traste 1 de la 2ª: una nota tiene varios lugares en '
              'el mástil.',
          en: 'Put your index finger on fret 5. The C on fret 5 of the 3rd string '
              'is the same C as fret 1 of the 2nd: a note has several places on '
              'the neck.',
        ),
      ),
      MelodyStep(
        id: 'mn_ladder',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: 'De C a C en la posición V', en: 'C to C in position V'),
        body: LocalizedText(
          es: 'De la 3ª cuerda a la 1ª, entre los trastes 5 y 8.',
          en: 'From the 3rd string to the 1st, between frets 5 and 8.',
        ),
        pitches: _ladderC5,
        minFret: 5,
        maxFret: 8,
      ),
      MelodyStep(
        id: 'mn_ode',
        kind: CourseStepKind.song,
        title: LocalizedText(es: 'Himno de la alegría, arriba', en: 'Ode to Joy, up high'),
        body: LocalizedText(
          es: 'La melodía que tocaste en una cuerda, ahora en la posición V.',
          en: 'The melody you played on one string, now in position V.',
        ),
        origin: _odeOrigin,
        pitches: _ode,
        minFret: 5,
        maxFret: 8,
      ),
    ],
  ),
  MelodyLevel(
    title: LocalizedText(es: 'Patrones', en: 'Patterns'),
    intro: LocalizedText(
      es: 'Formas cortas que se repiten mientras suben: la mano se mueve sola.',
      en: 'Short shapes that repeat as they climb: your hand moves on its own.',
    ),
    scale: _cMajor,
    steps: [
      MelodyStep(
        id: 'mp_theory',
        kind: CourseStepKind.theory,
        title: LocalizedText(es: 'Grupos de 3 y de 4', en: 'Groups of 3 and 4'),
        body: LocalizedText(
          es: 'Un patrón repite una forma corta un peldaño más arriba cada vez: '
              '1-2-3, 2-3-4, 3-4-5… Con grupos de 4: 1-2-3-4, 2-3-4-5… Así la '
              'escala suena a melodía.',
          en: 'A pattern repeats a short shape one step higher each time: 1-2-3, '
              '2-3-4, 3-4-5… With groups of 4: 1-2-3-4, 2-3-4-5… That way the '
              'scale sounds like a melody.',
        ),
      ),
      MelodyStep(
        id: 'mp_groups3',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: 'Grupos de 3', en: 'Groups of 3'),
        body: LocalizedText(
          es: 'G-A-B, A-B-C, B-C-D… hasta el G de arriba.',
          en: 'G-A-B, A-B-C, B-C-D… up to the high G.',
        ),
        pitches: _ladderG,
        pattern: WorkoutPattern.groupsOf3,
      ),
      MelodyStep(
        id: 'mp_groups4',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: 'Grupos de 4', en: 'Groups of 4'),
        body: LocalizedText(
          es: 'G-A-B-C, A-B-C-D… hasta el G de arriba.',
          en: 'G-A-B-C, A-B-C-D… up to the high G.',
        ),
        pitches: _ladderG,
        pattern: WorkoutPattern.groupsOf4,
      ),
      MelodyStep(
        id: 'mp_groups3_both',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: 'Grupos de 3, ida y vuelta', en: 'Groups of 3, up and back'),
        body: LocalizedText(
          es: 'Sube en grupos de 3 y baja con el mismo dibujo desde el G de arriba.',
          en: 'Climb in groups of 3 and come down with the same shape from the high G.',
        ),
        pitches: _ladderG,
        pattern: WorkoutPattern.groupsOf3,
        bothWays: true,
      ),
    ],
  ),
  MelodyLevel(
    title: LocalizedText(es: 'Más velocidad', en: 'More speed'),
    intro: LocalizedText(
      es: 'Lo que ya sabes, más largo y más rápido, sin perder limpieza.',
      en: 'What you already know, longer and faster, without losing cleanness.',
    ),
    scale: _cMajor,
    steps: [
      MelodyStep(
        id: 'ms_theory',
        kind: CourseStepKind.theory,
        title: LocalizedText(es: 'Cómo subir la velocidad', en: 'How to build speed'),
        body: LocalizedText(
          es: 'La velocidad sale de tocar limpio. Sube el tempo de 5 en 5 BPM solo '
              'cuando el anterior te salga tres veces seguidas sin errores. Ponte '
              'una meta pequeña por día, como ganar 5 BPM.',
          en: 'Speed comes from playing cleanly. Raise the tempo 5 BPM at a time, '
              'only once the previous one comes out three times in a row without '
              'mistakes. Set yourself a small goal each day, like gaining 5 BPM.',
        ),
      ),
      MelodyStep(
        id: 'ms_ladder',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: 'Posición V, ida y vuelta', en: 'Position V, up and back'),
        body: LocalizedText(
          es: 'De C a C y de vuelta, entre los trastes 5 y 8.',
          en: 'C to C and back, between frets 5 and 8.',
        ),
        pitches: _ladderC5,
        minFret: 5,
        maxFret: 8,
        pattern: WorkoutPattern.upDown,
        bothWays: true,
      ),
      MelodyStep(
        id: 'ms_thirds',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: 'Terceras en la posición V', en: 'Thirds in position V'),
        body: LocalizedText(
          es: 'Saltos de tercera subiendo y bajando, entre los trastes 5 y 8.',
          en: 'Leaps of a third up and down, between frets 5 and 8.',
        ),
        pitches: _ladderC5,
        minFret: 5,
        maxFret: 8,
        pattern: WorkoutPattern.thirds,
        bothWays: true,
      ),
      MelodyStep(
        id: 'ms_groups4',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: 'Grupos de 4, ida y vuelta', en: 'Groups of 4, up and back'),
        body: LocalizedText(
          es: 'El patrón más largo del curso: sube y baja en grupos de 4.',
          en: 'The longest pattern of the course: up and down in groups of 4.',
        ),
        pitches: _ladderG,
        pattern: WorkoutPattern.groupsOf4,
        bothWays: true,
      ),
    ],
  ),
  MelodyLevel(
    title: LocalizedText(es: 'De memoria', en: 'By heart'),
    intro: LocalizedText(
      es: 'Canciones enteras sin mirar la tablatura.',
      en: 'Whole songs without looking at the tab.',
    ),
    scale: _cMajor,
    steps: [
      MelodyStep(
        id: 'mm_theory',
        kind: CourseStepKind.theory,
        title: LocalizedText(es: 'Tocar de memoria', en: 'Playing by heart'),
        body: LocalizedText(
          es: 'Aprende la canción por frases: toca la primera tres veces sin '
              'mirar, luego la segunda y después únelas. Cantarla por dentro '
              'ayuda a no perderte.',
          en: 'Learn the song phrase by phrase: play the first one three times '
              'without looking, then the second, then join them. Singing it in '
              'your head keeps you on track.',
        ),
      ),
      MelodyStep(
        id: 'mm_mary',
        kind: CourseStepKind.song,
        title: LocalizedText(es: 'María tenía un corderito', en: 'Mary Had a Little Lamb'),
        body: LocalizedText(
          es: 'En C, con solo cuatro notas: C, D, E y G.',
          en: 'In C, with only four notes: C, D, E and G.',
        ),
        origin: LocalizedText(es: 'Tradicional (EE. UU., 1830)', en: 'Traditional (USA, 1830)'),
        pitches: [
          'E4', 'D4', 'C4', 'D4', 'E4', 'E4', 'E4', //
          'D4', 'D4', 'D4', 'E4', 'G4', 'G4',
          'E4', 'D4', 'C4', 'D4', 'E4', 'E4', 'E4',
          'E4', 'D4', 'D4', 'E4', 'D4', 'C4',
        ],
      ),
      MelodyStep(
        id: 'mm_jingle',
        kind: CourseStepKind.song,
        title: LocalizedText(es: 'Jingle Bells', en: 'Jingle Bells'),
        body: LocalizedText(
          es: 'El estribillo, en C, entre la 1ª y la 2ª cuerda.',
          en: 'The chorus, in C, across the 1st and 2nd strings.',
        ),
        origin: LocalizedText(es: 'James Lord Pierpont, 1857', en: 'James Lord Pierpont, 1857'),
        pitches: [
          'E4', 'E4', 'E4', 'E4', 'E4', 'E4', //
          'E4', 'G4', 'C4', 'D4', 'E4',
          'F4', 'F4', 'F4', 'F4', 'F4', 'E4', 'E4', 'E4',
          'E4', 'D4', 'D4', 'E4', 'D4', 'G4',
        ],
        strings: {1, 2},
      ),
    ],
  ),
  MelodyLevel(
    title: LocalizedText(es: 'Final del curso', en: 'Course finale'),
    intro: LocalizedText(
      es: 'Dos canciones en la posición V y un último patrón.',
      en: 'Two songs in position V and one last pattern.',
    ),
    scale: _cMajor,
    steps: [
      MelodyStep(
        id: 'mf_part1',
        kind: CourseStepKind.song,
        title: LocalizedText(es: 'Parte 1: Estrellita arriba', en: 'Part 1: Twinkle up high'),
        body: LocalizedText(
          es: 'La canción del nivel 2, ahora entre los trastes 5 y 8.',
          en: 'The song from level 2, now between frets 5 and 8.',
        ),
        origin: _twinkleOrigin,
        pitches: _twinkle,
        minFret: 5,
        maxFret: 8,
      ),
      MelodyStep(
        id: 'mf_part2',
        kind: CourseStepKind.song,
        title: LocalizedText(es: 'Parte 2: El puente de Londres arriba', en: 'Part 2: London Bridge up high'),
        body: LocalizedText(
          es: 'La canción del nivel 3, ahora entre los trastes 5 y 8.',
          en: 'The song from level 3, now between frets 5 and 8.',
        ),
        origin: _londonOrigin,
        pitches: _london,
        minFret: 5,
        maxFret: 8,
      ),
      MelodyStep(
        id: 'mf_part3',
        kind: CourseStepKind.exercise,
        title: LocalizedText(es: 'Parte 3: grupos de 3 arriba', en: 'Part 3: groups of 3 up high'),
        body: LocalizedText(
          es: 'Grupos de 3 subiendo y bajando en la posición V.',
          en: 'Groups of 3 up and down in position V.',
        ),
        pitches: _ladderC5,
        minFret: 5,
        maxFret: 8,
        pattern: WorkoutPattern.groupsOf3,
        bothWays: true,
      ),
    ],
  ),
];

/// Pasos de Melodías por id.
final Map<String, MelodyStep> melodyStepsById = {
  for (final l in melodyCourse)
    for (final s in l.steps) s.id: s,
};
