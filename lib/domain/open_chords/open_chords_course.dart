/// Cursos "Acordes abiertos": la Parte 1 (Em, G, D y C) y la Parte 2 (Am, E y
/// A), cada acorde armado dedo a dedo y luego los cambios entre ellos con
/// canciones de dominio público.
/// Las digitaciones vienen de `chords.json` ([ChordShape]); el curso solo
/// dice el orden. Los textos de cada paso se generan de la forma.
library;

import '../../core/i18n/tr.dart';
import '../courses/course.dart';
import '../courses/course_songs.dart';
import 'chord_shape.dart';

/// Qué hace un paso del curso.
enum OpenChordContent { howTo, fingers, full, tips, finale, changeHowTo, change, song }

class OpenChordStep implements CourseStep {
  const OpenChordStep({
    required this.id,
    required this.kind,
    required this.content,
    required this.title,
    required this.body,
    required this.chords,
    this.slots = const [],
    this.beatsPerSlot = 4,
    this.beatsPerBar = 4,
    this.origin,
  });

  @override
  final String id;
  @override
  final CourseStepKind kind;
  @override
  final LocalizedText title;
  @override
  final LocalizedText? origin;
  final OpenChordContent content;
  final LocalizedText body;

  /// Las formas que se muestran en diagrama (completas o a medio armar).
  final List<ChordShape> chords;

  /// Lo que suena, en orden: cada forma dura [beatsPerSlot] pulsos.
  final List<ChordShape> slots;
  final int beatsPerSlot;

  /// Compás (4 = 4/4, 3 = 3/4).
  final int beatsPerBar;
}

/// Una parte del curso: los acordes nuevos (en el orden en que se aprenden),
/// los que ya se saben de las anteriores, los cambios con sus canciones y el
/// final. [idPrefix] va delante de cada id (`oc` en la Parte 1, que así
/// conserva los suyos).
class OpenChordsPart {
  const OpenChordsPart({
    required this.idPrefix,
    required this.newChords,
    required this.changes,
    required this.finale,
    this.known = const [],
  });

  final String idPrefix;
  final List<String> newChords;
  final List<String> known;
  final List<(String, String, List<CourseSong>)> changes;
  final OpenChordsFinale finale;

  /// Todos los acordes que usa (los que ya se saben y los nuevos).
  List<String> get chords => [...known, ...newChords];
}

/// Una vuelta del final: compases de un acorde cada uno, dos vueltas.
typedef FinaleRound = ({LocalizedText title, LocalizedText body, List<String> chords});

/// El último nivel de una parte.
class OpenChordsFinale {
  const OpenChordsFinale({required this.intro, required this.rounds, required this.songs});

  final LocalizedText intro;
  final List<FinaleRound> rounds;
  final List<CourseSong> songs;
}

/// Acordes de la Parte 1, en el orden en que se aprenden.
const openChordsCourseChords = ['Em', 'G', 'D', 'C'];

/// Parte 1: Em, G, D y C.
const openChordsPart1 = OpenChordsPart(
  idPrefix: 'oc',
  newChords: openChordsCourseChords,
  changes: [
    ('Em', 'G', <CourseSong>[]),
    ('D', 'G', [skipToMyLou, tomDooley]),
    ('D', 'Em', [drunkenSailor]),
    ('C', 'Em', <CourseSong>[]),
    ('C', 'G', [maryLamb, rowYourBoat]),
    ('C', 'D', <CourseSong>[]),
  ],
  finale: OpenChordsFinale(
    intro: LocalizedText(
      es: 'Canciones completas con G, C y D, y una ronda con los cuatro acordes.',
      en: 'Full songs with G, C and D, and a round with all four chords.',
    ),
    rounds: [
      (
        title: LocalizedText(es: 'Los cuatro: G – D – Em – C', en: 'All four: G – D – Em – C'),
        body: LocalizedText(
          es: 'Un compás de cada uno, dos vueltas. Es la progresión I – V – vi – IV en G.',
          en: 'One bar of each, twice round. It is the I – V – vi – IV progression in G.',
        ),
        chords: ['G', 'D', 'Em', 'C'],
      ),
    ],
    songs: [ohSusanna, saints, amazingGrace],
  ),
);

/// Acordes nuevos de la Parte 2, en el orden en que se aprenden.
const openChordsCourse2Chords = ['Am', 'E', 'A'];

/// Parte 2: Am, E y A, y sus cambios con los de la Parte 1.
const openChordsPart2 = OpenChordsPart(
  idPrefix: 'oc2',
  known: openChordsCourseChords,
  newChords: openChordsCourse2Chords,
  changes: [
    ('Am', 'C', <CourseSong>[]),
    ('Am', 'Em', <CourseSong>[]),
    ('Am', 'G', <CourseSong>[]),
    ('E', 'Am', [greensleeves]),
    ('E', 'D', <CourseSong>[]),
    ('A', 'D', <CourseSong>[]),
    ('A', 'E', [wholeWorld]),
  ],
  finale: OpenChordsFinale(
    intro: LocalizedText(
      es: 'Dos vueltas con los acordes nuevos, en A mayor y en A menor, y una '
          'canción en 3/4.',
      en: 'Two rounds with the new chords, in A major and in A minor, and a '
          'song in 3/4.',
    ),
    rounds: [
      (
        title: LocalizedText(es: 'En A mayor: A – D – E – A', en: 'In A major: A – D – E – A'),
        body: LocalizedText(
          es: 'Un compás de cada uno, dos vueltas. Es I – IV – V – I en A.',
          en: 'One bar of each, twice round. It is I – IV – V – I in A.',
        ),
        chords: ['A', 'D', 'E', 'A'],
      ),
      (
        title: LocalizedText(es: 'En A menor: Am – G – C – E', en: 'In A minor: Am – G – C – E'),
        body: LocalizedText(
          es: 'Un compás de cada uno, dos vueltas. El E del final pide volver a Am.',
          en: 'One bar of each, twice round. The E at the end pulls back to Am.',
        ),
        chords: ['Am', 'G', 'C', 'E'],
      ),
    ],
    songs: [downInTheValley],
  ),
);

/// La Parte 1 (Em, G, D y C).
List<CourseLevel<OpenChordStep>> buildOpenChordsCourse(Map<String, ChordShape> shapes) =>
    buildOpenChordsPart(openChordsPart1, shapes);

/// La Parte 2 (Am, E y A).
List<CourseLevel<OpenChordStep>> buildOpenChordsCourse2(Map<String, ChordShape> shapes) =>
    buildOpenChordsPart(openChordsPart2, shapes);

/// Orden de los niveles: cada acorde nuevo y, detrás, sus cambios con los
/// anteriores (en la Parte 1: Em, G, Em–G, D, D–G, D–Em, C, C–Em, C–G, C–D,
/// final). Un cambio va detrás del más nuevo de sus dos acordes.
List<CourseLevel<OpenChordStep>> buildOpenChordsPart(
  OpenChordsPart part,
  Map<String, ChordShape> shapes,
) {
  ChordShape shape(String name) =>
      shapes[name] ?? (throw ArgumentError('Falta la digitación de $name'));
  final p = part.idPrefix;
  // Los que ya se saben cuentan como anteriores a todos los nuevos.
  int order(String chord) => part.newChords.indexOf(chord);
  final levels = <CourseLevel<OpenChordStep>>[];
  for (final (i, name) in part.newChords.indexed) {
    levels.add(_chordLevel(p, shape(name)));
    for (final (a, b, songs) in part.changes) {
      if (order(a) > order(b) ? order(a) == i : order(b) == i) {
        levels.add(_changeLevel(p, shape(a), shape(b), songs, shape));
      }
    }
  }
  levels.add(_finaleLevel(p, part.finale, shape));
  return levels;
}
String _key(String chord) => chord.toLowerCase();

CourseLevel<OpenChordStep> _chordLevel(String p, ChordShape s) {
  final k = _key(s.name);
  final n = s.fingerOrder.length;
  return CourseLevel(
    title: LocalizedText(es: s.name, en: s.name),
    intro: LocalizedText(
      es: '${s.name} con $n dedos: lo armas uno a uno y terminas tocándolo a tempo.',
      en: '${s.name} with $n fingers: you build it one at a time and end up playing it in time.',
    ),
    steps: [
      OpenChordStep(
        id: '${p}_${k}_howto',
        kind: CourseStepKind.theory,
        content: OpenChordContent.howTo,
        title: LocalizedText(es: 'Cómo se toca ${s.name}', en: 'How to play ${s.name}'),
        body: howToPlayText(s),
        chords: [s],
      ),
      for (var c = 1; c < n; c++)
        OpenChordStep(
          id: '${p}_${k}_f$c',
          kind: CourseStepKind.exercise,
          content: OpenChordContent.fingers,
          title: fingerStepTitle(s, c),
          body: fingerStepText(s, c),
          chords: [s.partial(c)],
          slots: List.filled(4, s.partial(c)),
        ),
      OpenChordStep(
        id: '${p}_${k}_full',
        kind: CourseStepKind.exercise,
        content: OpenChordContent.full,
        title: LocalizedText(es: '${s.name} completo', en: 'Full ${s.name}'),
        body: LocalizedText(
          es: 'Con todos los dedos: ${fingerStepText(s, n).es}',
          en: 'With every finger: ${fingerStepText(s, n).en}',
        ),
        chords: [s],
        slots: List.filled(4, s),
      ),
      OpenChordStep(
        id: '${p}_${k}_tips',
        kind: CourseStepKind.theory,
        content: OpenChordContent.tips,
        title: LocalizedText(es: 'Consejos para ${s.name}', en: '${s.name} tips'),
        body: tipsText(s),
        chords: [s],
      ),
      OpenChordStep(
        id: '${p}_${k}_finale',
        kind: CourseStepKind.exercise,
        content: OpenChordContent.finale,
        title: LocalizedText(es: '${s.name}: final', en: '${s.name}: finale'),
        body: LocalizedText(
          es: 'Ocho compases de ${s.name}, un golpe por pulso. Si una cuerda no '
              'suena, para, revisa el dedo y sigue.',
          en: 'Eight bars of ${s.name}, one strum per beat. If a string does not '
              'ring, stop, check the finger and go on.',
        ),
        chords: [s],
        slots: List.filled(8, s),
      ),
    ],
  );
}

CourseLevel<OpenChordStep> _changeLevel(
  String p,
  ChordShape a,
  ChordShape b,
  List<CourseSong> songs,
  ChordShape Function(String) shape,
) {
  final k = '${_key(a.name)}_${_key(b.name)}';
  final pair = '${a.name} – ${b.name}';
  return CourseLevel(
    title: LocalizedText(es: 'Cambio $pair', en: '$pair change'),
    intro: LocalizedText(
      es: 'Pasa de ${a.name} a ${b.name} y de vuelta, primero cada compás y '
          'luego cada dos pulsos.',
      en: 'Go from ${a.name} to ${b.name} and back, first every bar and then '
          'every two beats.',
    ),
    steps: [
      OpenChordStep(
        id: '${p}_${k}_howto',
        kind: CourseStepKind.theory,
        content: OpenChordContent.changeHowTo,
        title: LocalizedText(
          es: 'Cambiar entre ${a.name} y ${b.name}',
          en: 'Changing between ${a.name} and ${b.name}',
        ),
        body: changeText(ChordChange(a, b)),
        chords: [a, b],
      ),
      OpenChordStep(
        id: '${p}_${k}_practice',
        kind: CourseStepKind.exercise,
        content: OpenChordContent.change,
        title: LocalizedText(es: '$pair: práctica', en: '$pair: practice'),
        body: const LocalizedText(
          es: 'Un compás de cada uno, un golpe por pulso. Cambia en el último '
              'pulso, no después.',
          en: 'One bar of each, one strum per beat. Change on the last beat, '
              'not after it.',
        ),
        chords: [a, b],
        slots: [a, b, a, b, a, b, a, b],
      ),
      OpenChordStep(
        id: '${p}_${k}_finale',
        kind: CourseStepKind.exercise,
        content: OpenChordContent.change,
        title: LocalizedText(es: '$pair: final', en: '$pair: finale'),
        body: LocalizedText(
          es: 'Ahora cambia cada dos pulsos: dos golpes de ${a.name}, dos de ${b.name}.',
          en: 'Now change every two beats: two strums of ${a.name}, two of ${b.name}.',
        ),
        chords: [a, b],
        slots: [for (var i = 0; i < 8; i++) if (i.isEven) a else b],
        beatsPerSlot: 2,
      ),
      for (final song in songs) _songStep(p, song, shape),
    ],
  );
}

CourseLevel<OpenChordStep> _finaleLevel(
  String p,
  OpenChordsFinale finale,
  ChordShape Function(String) shape,
) => CourseLevel(
  title: const LocalizedText(es: 'Final del curso', en: 'Course finale'),
  intro: finale.intro,
  steps: [
    for (final (i, round) in finale.rounds.indexed)
      OpenChordStep(
        // La primera vuelta conserva el id de la Parte 1 (`oc_final_round`).
        id: i == 0 ? '${p}_final_round' : '${p}_final_round_${i + 1}',
        kind: CourseStepKind.exercise,
        content: OpenChordContent.change,
        title: round.title,
        body: round.body,
        chords: [for (final c in round.chords) shape(c)],
        slots: [for (var i = 0; i < 2; i++) ...round.chords.map(shape)],
      ),
    for (final song in finale.songs) _songStep(p, song, shape),
  ],
);
OpenChordStep _songStep(String p, CourseSong song, ChordShape Function(String) shape) {
  final chords = {for (final c in song.bars) c}.toList();
  return OpenChordStep(
    id: '${p}_song_${song.id}',
    kind: CourseStepKind.song,
    content: OpenChordContent.song,
    title: song.title,
    origin: song.origin,
    body: LocalizedText(
      es: '${song.bars.length} compases en ${song.beatsPerBar}/4, un acorde por '
          'compás: ${chords.join(', ')}. Solo los acordes; la melodía la canta '
          'o la imagina quien toca.',
      en: '${song.bars.length} bars in ${song.beatsPerBar}/4, one chord per bar: '
          '${chords.join(', ')}. Chords only; whoever plays sings or imagines '
          'the tune.',
    ),
    chords: [for (final c in chords) shape(c)],
    slots: [for (final c in song.bars) shape(c)],
    beatsPerSlot: song.beatsPerBar,
    beatsPerBar: song.beatsPerBar,
  );
}
