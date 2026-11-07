/// Curso de melodías por niveles: teoría, ejercicios y canciones de dominio
/// público. Las melodías se escriben como alturas ("C4") y la tablatura sale
/// por regla ([tabForPitches]): nada de trastes a mano. Un test verifica que
/// cada nota caiga en su ventana de trastes y pertenezca a su escala.
library;

import '../../core/i18n/tr.dart';
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

/// Tablatura de [pitches] dentro de la ventana de trastes [minFret]–[maxFret]:
/// cada nota va en la cuerda donde cae en la ventana; si cabe en dos, en la
/// del traste más bajo. Lanza si alguna no cabe (es un error del curso).
List<TabNote> tabForPitches(
  List<String> pitches, {
  int minFret = 0,
  int maxFret = 3,
}) => [
  for (final p in pitches) _place(pitchMidi(p), minFret, maxFret, p),
];

TabNote _place(int midi, int minFret, int maxFret, String name) {
  TabNote? best;
  for (var s = 1; s <= 6; s++) {
    final fret = midi - standardOpenStringMidi[s - 1];
    if (fret < minFret || fret > maxFret) continue;
    if (best == null || fret < best.fret) best = TabNote(s, fret);
  }
  if (best == null) {
    throw ArgumentError('$name no cabe entre los trastes $minFret y $maxFret');
  }
  return best;
}

enum MelodyStepKind { theory, exercise, song }

/// Un paso del curso. Los de teoría no tienen notas.
class MelodyStep {
  const MelodyStep({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.pitches = const [],
    this.minFret = 0,
    this.maxFret = 3,
    this.thirds = false,
    this.origin,
  });

  /// Identificador estable: es la clave guardada en el progreso.
  final String id;
  final MelodyStepKind kind;
  final LocalizedText title;
  final LocalizedText body;

  /// Alturas en orden (las de un ejercicio son su escalera de notas).
  final List<String> pitches;
  final int minFret;
  final int maxFret;

  /// Un ejercicio en terceras recorre la escalera de dos en dos, como en las
  /// rutinas de escala.
  final bool thirds;

  /// De dónde viene una canción (tradicional, compositor y año).
  final LocalizedText? origin;

  /// La tablatura que se toca.
  List<TabNote> get tab {
    final notes = tabForPitches(pitches, minFret: minFret, maxFret: maxFret);
    return thirds
        ? workoutNotes(WorkoutPattern.thirds, notes, direction: WorkoutDirection.up)
        : notes;
  }
}

class MelodyLevel {
  const MelodyLevel({
    required this.title,
    required this.intro,
    required this.scale,
    required this.steps,
  });

  final LocalizedText title;
  final LocalizedText intro;

  /// Escala de todas sus notas (un test lo verifica).
  final LessonScale scale;
  final List<MelodyStep> steps;
}

/// Tempos que dan una, dos y tres estrellas al tocar un paso limpio.
const melodyStarTempos = [60, 80, 100];

/// Estrellas de un paso con mejor tempo limpio [bestBpm].
int starsFor(int? bestBpm) =>
    bestBpm == null ? 0 : melodyStarTempos.where((t) => bestBpm >= t).length;

const _cMajor = LessonScale(scaleId: 'major', root: 0);

const melodyCourse = [
  MelodyLevel(
    title: LocalizedText(es: 'Las tres cuerdas agudas', en: 'The three high strings'),
    intro: LocalizedText(
      es: 'Sol, Si y Mi aguda: casi todas las melodías viven aquí. Empiezas al '
          'aire y con los trastes 1 a 3.',
      en: 'G, B and high E: most melodies live here. You start with open '
          'strings and frets 1 to 3.',
    ),
    scale: _cMajor,
    steps: [
      MelodyStep(
        id: 'm1_notes',
        kind: MelodyStepKind.theory,
        title: LocalizedText(es: 'Las notas de C mayor', en: 'The notes of C major'),
        body: LocalizedText(
          es: 'En la 3ª cuerda: G al aire y A en el traste 2. En la 2ª: B al '
              'aire, C en el 1 y D en el 3. En la 1ª: E al aire, F en el 1 y G '
              'en el 3. Un dedo por traste: el índice en el 1, el medio en el 2 '
              'y el anular en el 3.',
          en: 'On the 3rd string: open G and A on fret 2. On the 2nd: open B, C '
              'on fret 1 and D on fret 3. On the 1st: open E, F on fret 1 and G '
              'on fret 3. One finger per fret: index on 1, middle on 2 and ring '
              'on 3.',
        ),
      ),
      MelodyStep(
        id: 'm1_ladder',
        kind: MelodyStepKind.exercise,
        title: LocalizedText(es: 'Escalera de G a G', en: 'Ladder from G to G'),
        body: LocalizedText(
          es: 'Las ocho notas de G a G, de la 3ª cuerda a la 1ª.',
          en: 'The eight notes from G to G, from the 3rd string to the 1st.',
        ),
        pitches: ['G3', 'A3', 'B3', 'C4', 'D4', 'E4', 'F4', 'G4'],
      ),
      MelodyStep(
        id: 'm1_twinkle',
        kind: MelodyStepKind.song,
        title: LocalizedText(es: 'Estrellita', en: 'Twinkle, Twinkle'),
        body: LocalizedText(
          es: 'La canción infantil, en C. Empieza en el C del traste 1 de la 2ª '
              'cuerda; la única nota nueva es A, en el traste 5 de la 1ª '
              '(estira el meñique).',
          en: 'The nursery tune, in C. It starts on the C at fret 1 of the 2nd '
              'string; the only new note is A, at fret 5 of the 1st (stretch '
              'your pinky).',
        ),
        origin: LocalizedText(
          es: 'Tradicional (Francia, s. XVIII)',
          en: 'Traditional (France, 18th c.)',
        ),
        pitches: [
          'C4', 'C4', 'G4', 'G4', 'A4', 'A4', 'G4', //
          'F4', 'F4', 'E4', 'E4', 'D4', 'D4', 'C4',
          'G4', 'G4', 'F4', 'F4', 'E4', 'E4', 'D4',
          'G4', 'G4', 'F4', 'F4', 'E4', 'E4', 'D4',
          'C4', 'C4', 'G4', 'G4', 'A4', 'A4', 'G4',
          'F4', 'F4', 'E4', 'E4', 'D4', 'D4', 'C4',
        ],
        maxFret: 5,
      ),
    ],
  ),
  MelodyLevel(
    title: LocalizedText(es: 'Saltos entre cuerdas', en: 'Jumping strings'),
    intro: LocalizedText(
      es: 'Las melodías no van siempre de nota en nota: saltan. Aquí la púa '
          'cruza cuerdas sin tocar la de en medio.',
      en: 'Melodies do not always move note by note: they jump. Here the pick '
          'crosses strings without hitting the one in between.',
    ),
    scale: _cMajor,
    steps: [
      MelodyStep(
        id: 'm2_skips',
        kind: MelodyStepKind.theory,
        title: LocalizedText(es: 'Terceras', en: 'Thirds'),
        body: LocalizedText(
          es: 'Una tercera salta una nota de la escala: de C a E, de D a F. En '
              'la guitarra casi siempre es pasar a la cuerda de al lado.',
          en: 'A third skips one note of the scale: from C to E, from D to F. '
              'On the guitar it is almost always a move to the next string.',
        ),
      ),
      MelodyStep(
        id: 'm2_thirds',
        kind: MelodyStepKind.exercise,
        title: LocalizedText(es: 'Escalera en terceras', en: 'Ladder in thirds'),
        body: LocalizedText(
          es: 'G-B, A-C, B-D… cada nota y la que está dos lugares más arriba.',
          en: 'G-B, A-C, B-D… each note and the one two places higher.',
        ),
        pitches: ['G3', 'A3', 'B3', 'C4', 'D4', 'E4', 'F4', 'G4'],
        thirds: true,
      ),
      MelodyStep(
        id: 'm2_frere',
        kind: MelodyStepKind.song,
        title: LocalizedText(es: 'Martinillo', en: 'Frère Jacques'),
        body: LocalizedText(
          es: 'El canon, en C. Al final baja al G al aire de la 3ª cuerda.',
          en: 'The round, in C. At the end it drops to the open G on the 3rd '
              'string.',
        ),
        origin: LocalizedText(
          es: 'Tradicional (Francia, s. XVIII)',
          en: 'Traditional (France, 18th c.)',
        ),
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
    title: LocalizedText(es: 'Trastes altos', en: 'Higher frets'),
    intro: LocalizedText(
      es: 'Las mismas notas suenan más arriba del mástil. En la posición V la '
          'mano cubre los trastes 5 a 8 sin moverse.',
      en: 'The same notes sound higher up the neck. In position V your hand '
          'covers frets 5 to 8 without moving.',
    ),
    scale: _cMajor,
    steps: [
      MelodyStep(
        id: 'm3_position',
        kind: MelodyStepKind.theory,
        title: LocalizedText(es: 'La posición V', en: 'Position V'),
        body: LocalizedText(
          es: 'El índice va en el traste 5. El C del traste 5 de la 3ª cuerda es '
              'el mismo C del traste 1 de la 2ª: misma nota, otro lugar.',
          en: 'Your index goes on fret 5. The C at fret 5 of the 3rd string is '
              'the same C as fret 1 of the 2nd: same note, another place.',
        ),
      ),
      MelodyStep(
        id: 'm3_ladder',
        kind: MelodyStepKind.exercise,
        title: LocalizedText(es: 'C mayor en la posición V', en: 'C major in position V'),
        body: LocalizedText(
          es: 'De C a C, de la 3ª cuerda a la 1ª, entre los trastes 5 y 8.',
          en: 'From C to C, from the 3rd string to the 1st, between frets 5 and 8.',
        ),
        pitches: ['C4', 'D4', 'E4', 'F4', 'G4', 'A4', 'B4', 'C5'],
        minFret: 5,
        maxFret: 8,
      ),
      MelodyStep(
        id: 'm3_ode',
        kind: MelodyStepKind.song,
        title: LocalizedText(es: 'Himno de la alegría arriba', en: 'Ode to Joy up high'),
        body: LocalizedText(
          es: 'La melodía que ya tocaste al aire, ahora en la posición V.',
          en: 'The melody you already played in open position, now in position V.',
        ),
        origin: LocalizedText(es: 'Beethoven (1824)', en: 'Beethoven (1824)'),
        pitches: [
          'E4', 'E4', 'F4', 'G4', 'G4', 'F4', 'E4', 'D4', //
          'C4', 'C4', 'D4', 'E4', 'E4', 'D4', 'D4',
          'E4', 'E4', 'F4', 'G4', 'G4', 'F4', 'E4', 'D4',
          'C4', 'C4', 'D4', 'E4', 'D4', 'C4', 'C4',
        ],
        minFret: 5,
        maxFret: 8,
      ),
    ],
  ),
  MelodyLevel(
    title: LocalizedText(es: 'Melodías conocidas', en: 'Famous melodies'),
    intro: LocalizedText(
      es: 'Dos canciones tradicionales para tocar de memoria. Primero lento, '
          'luego sube el tempo hasta las tres estrellas.',
      en: 'Two traditional songs to play by heart. Slow first, then raise the '
          'tempo up to three stars.',
    ),
    scale: _cMajor,
    steps: [
      MelodyStep(
        id: 'm4_memory',
        kind: MelodyStepKind.theory,
        title: LocalizedText(es: 'Tocar de memoria', en: 'Playing by heart'),
        body: LocalizedText(
          es: 'Aprende la canción por frases: toca la primera tres veces sin '
              'mirar, luego la segunda, y únelas.',
          en: 'Learn the song phrase by phrase: play the first one three times '
              'without looking, then the second, and join them.',
        ),
      ),
      MelodyStep(
        id: 'm4_mary',
        kind: MelodyStepKind.song,
        title: LocalizedText(es: 'María tenía un corderito', en: 'Mary Had a Little Lamb'),
        body: LocalizedText(
          es: 'En C, con solo cuatro notas: C, D, E y G.',
          en: 'In C, with only four notes: C, D, E and G.',
        ),
        origin: LocalizedText(
          es: 'Tradicional (EE. UU., s. XIX)',
          en: 'Traditional (USA, 19th c.)',
        ),
        pitches: [
          'E4', 'D4', 'C4', 'D4', 'E4', 'E4', 'E4', //
          'D4', 'D4', 'D4', 'E4', 'G4', 'G4',
          'E4', 'D4', 'C4', 'D4', 'E4', 'E4', 'E4',
          'E4', 'D4', 'D4', 'E4', 'D4', 'C4',
        ],
        maxFret: 5,
      ),
      MelodyStep(
        id: 'm4_london',
        kind: MelodyStepKind.song,
        title: LocalizedText(es: 'El puente de Londres', en: 'London Bridge'),
        body: LocalizedText(
          es: 'En C. La melodía baja de G a E y vuelve a subir.',
          en: 'In C. The melody steps down from G to E and climbs back up.',
        ),
        origin: LocalizedText(
          es: 'Tradicional (Inglaterra, s. XVII)',
          en: 'Traditional (England, 17th c.)',
        ),
        pitches: [
          'G4', 'A4', 'G4', 'F4', 'E4', 'F4', 'G4', //
          'D4', 'E4', 'F4', 'E4', 'F4', 'G4',
          'G4', 'A4', 'G4', 'F4', 'E4', 'F4', 'G4',
          'D4', 'G4', 'E4', 'C4',
        ],
        maxFret: 5,
      ),
    ],
  ),
];

/// Pasos por id.
final Map<String, MelodyStep> melodyStepsById = {
  for (final l in melodyCourse)
    for (final s in l.steps) s.id: s,
};

/// Nivel de un paso (desde 1).
int levelOf(MelodyStep step) =>
    melodyCourse.indexWhere((l) => l.steps.contains(step)) + 1;
