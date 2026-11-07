/// Curso "Acordes abiertos – Parte 1": Em, G, D y C, cada uno armado dedo a
/// dedo, y luego los cambios entre ellos con canciones de dominio público.
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

/// Acordes del curso, en el orden en que se aprenden.
const openChordsCourseChords = ['Em', 'G', 'D', 'C'];

/// Cambios del curso, en orden, con sus canciones.
const _changes = [
  ('Em', 'G', <CourseSong>[]),
  ('D', 'G', [skipToMyLou, tomDooley]),
  ('D', 'Em', [drunkenSailor]),
  ('C', 'Em', <CourseSong>[]),
  ('C', 'G', [maryLamb, rowYourBoat]),
  ('C', 'D', <CourseSong>[]),
];

/// Canciones del final, con los cuatro acordes.
const _finaleSongs = [ohSusanna, saints, amazingGrace];

/// Orden de los niveles: cada acorde nuevo y, detrás, sus cambios con los
/// anteriores (Em, G, Em–G, D, D–G, D–Em, C, C–Em, C–G, C–D, final).
List<CourseLevel<OpenChordStep>> buildOpenChordsCourse(Map<String, ChordShape> shapes) {
  ChordShape shape(String name) =>
      shapes[name] ?? (throw ArgumentError('Falta la digitación de $name'));
  final levels = <CourseLevel<OpenChordStep>>[];
  int order(String chord) => openChordsCourseChords.indexOf(chord);
  for (final (i, name) in openChordsCourseChords.indexed) {
    levels.add(_chordLevel(shape(name)));
    // Cada cambio va detrás del más nuevo de sus dos acordes.
    for (final (a, b, songs) in _changes) {
      if (order(a) > order(b) ? order(a) == i : order(b) == i) {
        levels.add(_changeLevel(shape(a), shape(b), songs, shape));
      }
    }
  }
  levels.add(_finaleLevel(shape));
  return levels;
}

String _key(String chord) => chord.toLowerCase();

CourseLevel<OpenChordStep> _chordLevel(ChordShape s) {
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
        id: 'oc_${k}_howto',
        kind: CourseStepKind.theory,
        content: OpenChordContent.howTo,
        title: LocalizedText(es: 'Cómo se toca ${s.name}', en: 'How to play ${s.name}'),
        body: howToPlayText(s),
        chords: [s],
      ),
      for (var c = 1; c < n; c++)
        OpenChordStep(
          id: 'oc_${k}_f$c',
          kind: CourseStepKind.exercise,
          content: OpenChordContent.fingers,
          title: fingerStepTitle(s, c),
          body: fingerStepText(s, c),
          chords: [s.partial(c)],
          slots: List.filled(4, s.partial(c)),
        ),
      OpenChordStep(
        id: 'oc_${k}_full',
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
        id: 'oc_${k}_tips',
        kind: CourseStepKind.theory,
        content: OpenChordContent.tips,
        title: LocalizedText(es: 'Consejos para ${s.name}', en: '${s.name} tips'),
        body: tipsText(s),
        chords: [s],
      ),
      OpenChordStep(
        id: 'oc_${k}_finale',
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
        id: 'oc_${k}_howto',
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
        id: 'oc_${k}_practice',
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
        id: 'oc_${k}_finale',
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
      for (final song in songs) _songStep(song, shape),
    ],
  );
}

CourseLevel<OpenChordStep> _finaleLevel(ChordShape Function(String) shape) => CourseLevel(
  title: const LocalizedText(es: 'Final del curso', en: 'Course finale'),
  intro: const LocalizedText(
    es: 'Canciones completas con G, C y D, y una ronda con los cuatro acordes.',
    en: 'Full songs with G, C and D, and a round with all four chords.',
  ),
  steps: [
    OpenChordStep(
      id: 'oc_final_round',
      kind: CourseStepKind.exercise,
      content: OpenChordContent.change,
      title: const LocalizedText(es: 'Los cuatro: G – D – Em – C', en: 'All four: G – D – Em – C'),
      body: const LocalizedText(
        es: 'Un compás de cada uno, dos vueltas. Es la progresión I – V – vi – IV en G.',
        en: 'One bar of each, twice round. It is the I – V – vi – IV progression in G.',
      ),
      chords: [shape('G'), shape('D'), shape('Em'), shape('C')],
      slots: [for (var i = 0; i < 2; i++) ...['G', 'D', 'Em', 'C'].map(shape)],
    ),
    for (final song in _finaleSongs) _songStep(song, shape),
  ],
);

OpenChordStep _songStep(CourseSong song, ChordShape Function(String) shape) {
  final chords = {for (final c in song.bars) c}.toList();
  return OpenChordStep(
    id: 'oc_song_${song.id}',
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
