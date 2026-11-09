/// Guías temáticas: recorridos cortos por un tema (un género, una técnica, una
/// escala) que enlazan lecciones, escalas, acordes, licks y módulos que ya
/// existen en la app. No traen contenido propio con trastes: lo que afirman se
/// verifica en `test/domain/guides/guides_test.dart`.
library;

import '../../core/i18n/tr.dart';
import '../lessons/lesson.dart';
import 'style_guides.dart';

/// Fila del catálogo de guías.
enum GuideCategory { acoustic, scales, genres, styles, theory, lead }

/// Nombre visible de cada fila.
LocalizedText guideCategoryTitle(GuideCategory category) => switch (category) {
  GuideCategory.acoustic => const LocalizedText(
    es: 'Domina la guitarra acústica',
    en: 'Master the acoustic guitar',
  ),
  GuideCategory.scales => const LocalizedText(
    es: 'Escalas y calentamientos',
    en: 'Scales and warm-ups',
  ),
  GuideCategory.genres => const LocalizedText(es: 'Géneros', en: 'Genres'),
  GuideCategory.styles => const LocalizedText(es: 'Estilos', en: 'Styles'),
  GuideCategory.theory => const LocalizedText(es: 'Teoría', en: 'Theory'),
  GuideCategory.lead => const LocalizedText(
    es: 'Técnica solista',
    en: 'Lead technique',
  ),
};

/// Para quién es una guía. Una guía nunca es de un nivel menor que el de las
/// lecciones que enlaza (hay test).
enum GuideLevel { beginner, intermediate, advanced }

/// Nombre visible de cada nivel.
LocalizedText guideLevelTitle(GuideLevel level) => switch (level) {
  GuideLevel.beginner => const LocalizedText(es: 'Principiante', en: 'Beginner'),
  GuideLevel.intermediate => const LocalizedText(es: 'Intermedio', en: 'Intermediate'),
  GuideLevel.advanced => const LocalizedText(es: 'Avanzado', en: 'Advanced'),
};

/// Módulo de la app al que lleva un capítulo.
enum GuideModule {
  tuner,
  metronome,
  progressions,
  doubleStops,
  circle,
  earTraining,
  rhythmGame,
  songs,
  capo,
  scales,
  health,
  technique,
}

/// A dónde lleva un capítulo.
sealed class GuideTarget {
  const GuideTarget();
}

/// Una lección del camino, por id.
class LessonLink extends GuideTarget {
  const LessonLink(this.lessonId);
  final String lessonId;
}

/// Un paso de un curso del mapa (por id del paso).
class CourseLink extends GuideTarget {
  const CourseLink(this.course, this.stepId);
  final LessonCourse course;
  final String stepId;
}

/// El detalle de una escala en su tónica y, con [position], abierto en esa
/// digitación (id de `scales_master.json`, p. ej. `caged_a`).
class ScaleLink extends GuideTarget {
  const ScaleLink(this.scale, {this.position});
  final LessonScale scale;
  final String? position;
}

/// La ficha de un acorde (`displayName` de `chords.json`).
class ChordLink extends GuideTarget {
  const ChordLink(this.chord);
  final String chord;
}

/// Las rutinas de una escala en su tónica.
class WorkoutLink extends GuideTarget {
  const WorkoutLink(this.scale);
  final LessonScale scale;
}

/// Una frase de Licks y riffs, por id.
class LickLink extends GuideTarget {
  const LickLink(this.lickId);
  final String lickId;
}

/// Un módulo de la app.
class ModuleLink extends GuideTarget {
  const ModuleLink(this.module);
  final GuideModule module;
}

/// Un paso de la guía.
class GuideChapter {
  const GuideChapter({
    required this.title,
    required this.body,
    required this.target,
  });

  final LocalizedText title;
  final LocalizedText body;
  final GuideTarget target;
}

/// Una guía del catálogo.
class Guide {
  const Guide({
    required this.id,
    required this.category,
    required this.level,
    required this.title,
    required this.subtitle,
    required this.art,
    required this.chapters,
  });

  /// Identificador estable: va en la ruta `/learn/guides/:id`.
  final String id;
  final GuideCategory category;
  final GuideLevel level;
  final LocalizedText title;
  final LocalizedText subtitle;

  /// Dibujo de la tarjeta, generado desde los datos como en el mapa.
  final UnitArt art;
  final List<GuideChapter> chapters;
}

/// Todas las guías, en el orden de cada fila: las escritas a mano y una por
/// estilo de Licks y riffs ([styleGuides]).
final List<Guide> guides = [..._writtenGuides, ...styleGuides];

const List<Guide> _writtenGuides = [
  // ── Domina la guitarra acústica ──────────────────────────────────────────
  Guide(
    id: 'chord_variations',
    category: GuideCategory.acoustic,
    level: GuideLevel.intermediate,
    title: LocalizedText(es: 'Variaciones de acordes', en: 'Chord variations'),
    subtitle: LocalizedText(
      es: 'Más color moviendo un solo dedo',
      en: 'More color by moving a single finger',
    ),
    art: ChordArt('Asus2'),
    chapters: [
      GuideChapter(
        title: LocalizedText(es: 'Mayor y menor', en: 'Major and minor'),
        body: LocalizedText(
          es: 'De D a Dm cambia una sola nota: la 3ª baja un semitono.',
          en: 'From D to Dm a single note changes: the 3rd drops a half step.',
        ),
        target: LessonLink('r11_d_dm'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Séptimas', en: 'Sevenths'),
        body: LocalizedText(
          es: 'Levanta un dedo de E o de A y aparece la séptima.',
          en: 'Lift one finger from E or A and the seventh appears.',
        ),
        target: LessonLink('r12_sevenths'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'maj7 y m7', en: 'maj7 and m7'),
        body: LocalizedText(
          es: 'Cmaj7, Am7 y Fmaj7: el mismo truco para un sonido más suave.',
          en: 'Cmaj7, Am7 and Fmaj7: the same trick for a softer sound.',
        ),
        target: LessonLink('r13_color_chords'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Suspendidos', en: 'Suspended chords'),
        body: LocalizedText(
          es: 'En Asus2 la 3ª se cambia por la 2ª: suena abierto, sin mayor ni menor.',
          en: 'In Asus2 the 3rd becomes the 2nd: it sounds open, neither major nor minor.',
        ),
        target: ChordLink('Asus2'),
      ),
    ],
  ),
  Guide(
    id: 'chord_changes',
    category: GuideCategory.acoustic,
    level: GuideLevel.beginner,
    title: LocalizedText(es: 'Mejores cambios de acorde', en: 'Better chord changes'),
    subtitle: LocalizedText(
      es: 'Cambiar sin cortar el ritmo',
      en: 'Change chords without breaking the rhythm',
    ),
    art: ChordArt('Em'),
    chapters: [
      GuideChapter(
        title: LocalizedText(es: 'Mover los dedos en bloque', en: 'Move fingers as a block'),
        body: LocalizedText(
          es: 'De Em a Am los dedos 2 y 3 bajan juntos una cuerda.',
          en: 'From Em to Am fingers 2 and 3 move down one string together.',
        ),
        target: CourseLink(LessonCourse.openChords2, 'oc2_am_em_howto'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Preparar el siguiente', en: 'Get the next one ready'),
        body: LocalizedText(
          es: 'Durante el último rasgueo, la mano ya viaja al acorde que sigue.',
          en: 'During the last strum, the hand is already traveling to the next chord.',
        ),
        target: CourseLink(LessonCourse.openChords, 'oc_em_g_practice'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'El cambio más difícil primero', en: 'Hardest change first'),
        body: LocalizedText(
          es: 'Practica aparte el cambio que más cuesta antes de tocar la vuelta.',
          en: 'Practice the toughest change on its own before playing the loop.',
        ),
        target: CourseLink(LessonCourse.openChords, 'oc_final_round'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Las digitaciones más cómodas', en: 'The most comfortable fingerings'),
        body: LocalizedText(
          es: 'Progresiones elige la forma de cada acorde que menos mueve la mano.',
          en: 'Progressions picks the shape of each chord that moves the hand the least.',
        ),
        target: ModuleLink(GuideModule.progressions),
      ),
    ],
  ),
  Guide(
    id: 'capo',
    category: GuideCategory.acoustic,
    level: GuideLevel.beginner,
    title: LocalizedText(es: 'Cómo usar el capo', en: 'How to use a capo'),
    subtitle: LocalizedText(
      es: 'Otra tonalidad con las formas de siempre',
      en: 'A new key with the shapes you know',
    ),
    art: ChordArt('G'),
    chapters: [
      GuideChapter(
        title: LocalizedText(es: 'Qué hace el capo', en: 'What a capo does'),
        body: LocalizedText(
          es: 'Sube todas las cuerdas un semitono por traste: con capo en el 2, '
              'la forma de G suena como A.',
          en: 'It raises every string a half step per fret: with the capo on 2, '
              'the G shape sounds like A.',
        ),
        target: ModuleLink(GuideModule.capo),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Elige la forma', en: 'Pick the shape'),
        body: LocalizedText(
          es: 'Con las cinco formas abiertas (C, A, G, E y D) llegas a cualquier '
              'tonalidad sin pasar del traste 7.',
          en: 'With the five open shapes (C, A, G, E and D) you can reach any key '
              'without going past fret 7.',
        ),
        target: ModuleLink(GuideModule.capo),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Afina con el capo puesto', en: 'Tune with the capo on'),
        body: LocalizedText(
          es: 'El capo puede desafinar un poco las cuerdas: revísalas después de ponerlo.',
          en: 'A capo can pull the strings slightly out of tune: check them after putting it on.',
        ),
        target: ModuleLink(GuideModule.tuner),
      ),
    ],
  ),
  Guide(
    id: 'strumming_next_level',
    category: GuideCategory.acoustic,
    level: GuideLevel.intermediate,
    title: LocalizedText(es: 'Rasgueo al siguiente nivel', en: 'Strumming to the next level'),
    subtitle: LocalizedText(
      es: 'De las negras al 6/8',
      en: 'From quarter notes to 6/8',
    ),
    art: StrumArt('D DU UDU'),
    chapters: [
      GuideChapter(
        title: LocalizedText(es: 'Corcheas', en: 'Eighth notes'),
        body: LocalizedText(
          es: 'La mano nunca se detiene: abajo en los números, arriba en las "y".',
          en: 'The hand never stops: down on the numbers, up on the "ands".',
        ),
        target: CourseLink(LessonCourse.strumming, 'sp2_learn'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'El rasgueo pop', en: 'The pop strum'),
        body: LocalizedText(
          es: 'Huecos donde la mano pasa sin tocar.',
          en: 'Gaps where the hand passes without touching.',
        ),
        target: CourseLink(LessonCourse.strumming, 'sp4_learn'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Apagado con la palma', en: 'Palm muting'),
        body: LocalizedText(
          es: 'Un sonido corto y percusivo para el rock.',
          en: 'A short, percussive sound for rock.',
        ),
        target: LessonLink('r7_palm_mute'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Acento en 2 y 4', en: 'Accent on 2 and 4'),
        body: LocalizedText(
          es: 'Golpea más fuerte donde suena la caja de la batería.',
          en: 'Hit harder where the snare drum lands.',
        ),
        target: LessonLink('r15_backbeat'),
      ),
      GuideChapter(
        title: LocalizedText(es: '3/4 y 6/8', en: '3/4 and 6/8'),
        body: LocalizedText(
          es: 'Compases de tres y de seis para valses y baladas.',
          en: 'Bars of three and six for waltzes and ballads.',
        ),
        target: LessonLink('r14_six_eight'),
      ),
    ],
  ),

  // ── Escalas y calentamientos ─────────────────────────────────────────────
  Guide(
    id: 'warmups',
    category: GuideCategory.scales,
    level: GuideLevel.beginner,
    title: LocalizedText(es: 'Calentamientos', en: 'Warm-ups'),
    subtitle: LocalizedText(
      es: 'El mejor comienzo para practicar',
      en: 'The best start to a practice session',
    ),
    art: NotesArt(['E', 'F', 'F#', 'G']),
    chapters: [
      GuideChapter(
        title: LocalizedText(es: 'Cromático', en: 'Chromatic'),
        body: LocalizedText(
          es: 'Un dedo por traste en cada cuerda, despacio y parejo.',
          en: 'One finger per fret on every string, slow and even.',
        ),
        target: LessonLink('l2_chromatic'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Araña y diagonal', en: 'Spider and diagonal'),
        body: LocalizedText(
          es: 'Con 1-3-2-4 los dedos se cruzan; en diagonal la mano sube un '
              'traste en cada cuerda.',
          en: 'With 1-3-2-4 the fingers cross over; on the diagonal the hand '
              'moves up one fret on each string.',
        ),
        target: ModuleLink(GuideModule.technique),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Con metrónomo', en: 'With the metronome'),
        body: LocalizedText(
          es: 'Empieza lento y sube de 5 en 5 BPM solo cuando salga limpio.',
          en: 'Start slow and go up 5 BPM at a time only when it comes out clean.',
        ),
        target: ModuleLink(GuideModule.metronome),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Rutina de escala', en: 'Scale workout'),
        body: LocalizedText(
          es: 'Sube y baja una posición de la escala mayor antes de tocar canciones.',
          en: 'Run a major scale position up and down before playing songs.',
        ),
        target: WorkoutLink(LessonScale(scaleId: 'major', root: 0)),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Descansos', en: 'Breaks'),
        body: LocalizedText(
          es: 'Practica en bloques cortos: Salud de práctica cuenta tu tiempo y '
              'te avisa cuándo descansar.',
          en: 'Practice in short blocks: Practice health counts your time and '
              'tells you when to rest.',
        ),
        target: ModuleLink(GuideModule.health),
      ),
    ],
  ),
  Guide(
    id: 'minor_pentatonic',
    category: GuideCategory.scales,
    level: GuideLevel.beginner,
    title: LocalizedText(es: 'Pentatónica menor', en: 'Minor pentatonic'),
    subtitle: LocalizedText(
      es: 'Cinco notas para improvisar',
      en: 'Five notes to improvise with',
    ),
    art: ScaleArt(LessonScale(scaleId: 'pentatonic_minor', root: 9)),
    chapters: [
      GuideChapter(
        title: LocalizedText(es: 'La primera caja', en: 'The first box'),
        body: LocalizedText(
          es: 'A C D E G, desde el traste 5 de la 6ª cuerda.',
          en: 'A C D E G, from fret 5 on the 6th string.',
        ),
        target: LessonLink('l1_minor_pentatonic'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'La segunda caja', en: 'The second box'),
        body: LocalizedText(
          es: 'Sigue subiendo por el mástil con las mismas notas.',
          en: 'Keep climbing the neck with the same notes.',
        ),
        target: LessonLink('l10_second_box'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Todo el mástil', en: 'The whole neck'),
        body: LocalizedText(
          es: 'Amplía el diapasón para ver todas las posiciones a la vez.',
          en: 'Expand the fretboard to see every position at once.',
        ),
        target: ScaleLink(LessonScale(scaleId: 'pentatonic_minor', root: 9)),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Rutinas', en: 'Workouts'),
        body: LocalizedText(
          es: 'Sube, baja, terceras y grupos de notas, en tres niveles y con audio.',
          en: 'Up, down, thirds and note groups, in three levels and with audio.',
        ),
        target: WorkoutLink(LessonScale(scaleId: 'pentatonic_minor', root: 9)),
      ),
    ],
  ),
  Guide(
    id: 'major_pentatonic',
    category: GuideCategory.scales,
    level: GuideLevel.intermediate,
    title: LocalizedText(es: 'Pentatónica mayor', en: 'Major pentatonic'),
    subtitle: LocalizedText(
      es: 'El sonido alegre del country y el pop',
      en: 'The bright sound of country and pop',
    ),
    art: ScaleArt(LessonScale(scaleId: 'pentatonic_major', root: 0)),
    chapters: [
      GuideChapter(
        title: LocalizedText(es: 'Mismas notas, otra casa', en: 'Same notes, a new home'),
        body: LocalizedText(
          es: 'C pentatónica mayor tiene las notas de A pentatónica menor.',
          en: 'C major pentatonic has the notes of A minor pentatonic.',
        ),
        target: LessonLink('l7_major_pentatonic'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'En el diapasón', en: 'On the fretboard'),
        body: LocalizedText(
          es: 'Sus cajas y todo el mástil, en la tónica que elijas.',
          en: 'Its boxes and the whole neck, in the key you choose.',
        ),
        target: ScaleLink(LessonScale(scaleId: 'pentatonic_major', root: 0)),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Rutinas', en: 'Workouts'),
        body: LocalizedText(
          es: 'Sube, baja, terceras y grupos de notas, en tres niveles y con audio.',
          en: 'Up, down, thirds and note groups, in three levels and with audio.',
        ),
        target: WorkoutLink(LessonScale(scaleId: 'pentatonic_major', root: 0)),
      ),
    ],
  ),
  Guide(
    id: 'blues_scale',
    category: GuideCategory.scales,
    level: GuideLevel.intermediate,
    title: LocalizedText(es: 'Escala de blues', en: 'Blues scale'),
    subtitle: LocalizedText(
      es: 'La pentatónica con una nota de paso',
      en: 'The pentatonic plus a passing note',
    ),
    art: ScaleArt(LessonScale(scaleId: 'blues_minor', root: 9)),
    chapters: [
      GuideChapter(
        title: LocalizedText(es: 'La b5', en: 'The b5'),
        body: LocalizedText(
          es: 'Una nota entre la 4 y la 5 que se usa de paso.',
          en: 'A note between the 4 and the 5, used in passing.',
        ),
        target: LessonLink('l6_blues_scale'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'En el diapasón', en: 'On the fretboard'),
        body: LocalizedText(
          es: 'Cajas y mástil completo de A blues.',
          en: 'Boxes and the whole neck for A blues.',
        ),
        target: ScaleLink(LessonScale(scaleId: 'blues_minor', root: 9)),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Rutinas', en: 'Workouts'),
        body: LocalizedText(
          es: 'Sube, baja, terceras y grupos de notas, en tres niveles y con audio.',
          en: 'Up, down, thirds and note groups, in three levels and with audio.',
        ),
        target: WorkoutLink(LessonScale(scaleId: 'blues_minor', root: 9)),
      ),
    ],
  ),
  Guide(
    id: 'major_scale',
    category: GuideCategory.scales,
    level: GuideLevel.intermediate,
    title: LocalizedText(es: 'Escala mayor', en: 'Major scale'),
    subtitle: LocalizedText(
      es: 'La base de la armonía',
      en: 'The foundation of harmony',
    ),
    art: ScaleArt(LessonScale(scaleId: 'major', root: 7)),
    chapters: [
      GuideChapter(
        title: LocalizedText(es: 'La fórmula', en: 'The formula'),
        body: LocalizedText(
          es: 'Tono, tono, semitono, tono, tono, tono, semitono.',
          en: 'Whole, whole, half, whole, whole, whole, half.',
        ),
        target: LessonLink('l14_major_scale'),
      ),
      GuideChapter(
        title: LocalizedText(es: '3NPS y CAGED', en: '3NPS and CAGED'),
        body: LocalizedText(
          es: 'Dos formas de recorrer el mástil con la misma escala.',
          en: 'Two ways to cover the neck with the same scale.',
        ),
        target: ScaleLink(LessonScale(scaleId: 'major', root: 7)),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Rutinas', en: 'Workouts'),
        body: LocalizedText(
          es: 'Sube, baja, terceras y grupos de notas, en tres niveles y con audio.',
          en: 'Up, down, thirds and note groups, in three levels and with audio.',
        ),
        target: WorkoutLink(LessonScale(scaleId: 'major', root: 7)),
      ),
    ],
  ),
  Guide(
    id: 'minor_scale',
    category: GuideCategory.scales,
    level: GuideLevel.intermediate,
    title: LocalizedText(es: 'Escala menor', en: 'Minor scale'),
    subtitle: LocalizedText(
      es: 'La relativa de la mayor',
      en: 'The relative of the major',
    ),
    art: ScaleArt(LessonScale(scaleId: 'natural_minor', root: 4)),
    chapters: [
      GuideChapter(
        title: LocalizedText(es: 'Misma escala, otra casa', en: 'Same scale, a new home'),
        body: LocalizedText(
          es: 'E menor natural tiene las mismas notas que G mayor.',
          en: 'E natural minor has the same notes as G major.',
        ),
        target: LessonLink('l15_relative_minor'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'En el diapasón', en: 'On the fretboard'),
        body: LocalizedText(
          es: 'Posiciones y mástil completo de E menor.',
          en: 'Positions and the whole neck for E minor.',
        ),
        target: ScaleLink(LessonScale(scaleId: 'natural_minor', root: 4)),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Rutinas', en: 'Workouts'),
        body: LocalizedText(
          es: 'Sube, baja, terceras y grupos de notas, en tres niveles y con audio.',
          en: 'Up, down, thirds and note groups, in three levels and with audio.',
        ),
        target: WorkoutLink(LessonScale(scaleId: 'natural_minor', root: 4)),
      ),
    ],
  ),

  // ── Géneros ──────────────────────────────────────────────────────────────
  Guide(
    id: 'intro_blues',
    category: GuideCategory.genres,
    level: GuideLevel.intermediate,
    title: LocalizedText(es: 'Introducción al blues', en: 'Intro to blues'),
    subtitle: LocalizedText(
      es: 'Doce compases y tres acordes',
      en: 'Twelve bars and three chords',
    ),
    art: ChordArt('A7'),
    chapters: [
      GuideChapter(
        title: LocalizedText(es: 'Los tres acordes', en: 'The three chords'),
        body: LocalizedText(
          es: 'El blues en A usa I, IV y V como séptimas: A7, D7 y E7.',
          en: 'The blues in A uses I, IV and V as sevenths: A7, D7 and E7.',
        ),
        target: LessonLink('r8_twelve_bar'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'El boogie', en: 'The boogie'),
        body: LocalizedText(
          es: 'El acompañamiento clásico, alternando la 5ª y la 6ª.',
          en: 'The classic backing, alternating the 5th and 6th.',
        ),
        target: LessonLink('r17_boogie'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Para el solo', en: 'For the solo'),
        body: LocalizedText(
          es: 'La escala de blues y un primer solo sobre la vuelta.',
          en: 'The blues scale and a first solo over the form.',
        ),
        target: LessonLink('l8_first_solo'),
      ),
    ],
  ),
  Guide(
    id: 'intro_rock',
    category: GuideCategory.genres,
    level: GuideLevel.intermediate,
    title: LocalizedText(es: 'Introducción al rock', en: 'Intro to rock'),
    subtitle: LocalizedText(
      es: 'Power chords, riffs y pentatónica',
      en: 'Power chords, riffs and the pentatonic',
    ),
    art: ChordArt('E5'),
    chapters: [
      GuideChapter(
        title: LocalizedText(es: 'Power chords', en: 'Power chords'),
        body: LocalizedText(
          es: 'Tónica y quinta: sin 3ª, ni mayor ni menor.',
          en: 'Root and fifth: no 3rd, neither major nor minor.',
        ),
        target: LessonLink('r6_power_chords'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Apagado con la palma', en: 'Palm muting'),
        body: LocalizedText(
          es: 'El golpe corto que empuja el ritmo.',
          en: 'The short attack that drives the rhythm.',
        ),
        target: LessonLink('r7_palm_mute'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Tu primer riff', en: 'Your first riff'),
        body: LocalizedText(
          es: 'E5, G5 y A5 sobre la pentatónica menor de E.',
          en: 'E5, G5 and A5 over the E minor pentatonic.',
        ),
        target: LessonLink('r16_power_riff'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Licks', en: 'Licks'),
        body: LocalizedText(
          es: 'Frases con bend para tus solos.',
          en: 'Phrases with bends for your solos.',
        ),
        target: LessonLink('l11_bend_lick'),
      ),
    ],
  ),
  Guide(
    id: 'intro_folk_pop',
    category: GuideCategory.genres,
    level: GuideLevel.beginner,
    title: LocalizedText(es: 'Introducción al folk y al pop', en: 'Intro to folk and pop'),
    subtitle: LocalizedText(
      es: 'Acordes abiertos y canciones',
      en: 'Open chords and songs',
    ),
    art: ChordArt('C'),
    chapters: [
      GuideChapter(
        title: LocalizedText(es: 'La progresión de mil canciones', en: 'The thousand-song progression'),
        body: LocalizedText(
          es: 'G – D – Em – C con el rasgueo pop.',
          en: 'G – D – Em – C with the pop strum.',
        ),
        target: CourseLink(LessonCourse.strumming, 'sp4_four'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Con los dedos', en: 'Fingerpicking'),
        body: LocalizedText(
          es: 'El pulgar en el bajo y los dedos arriba.',
          en: 'Thumb on the bass and fingers on top.',
        ),
        target: LessonLink('r9_arpeggio'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Bajo alterno', en: 'Alternating bass'),
        body: LocalizedText(
          es: 'El pulgar alterna dos bajos como en el folk.',
          en: 'The thumb alternates two bass notes, folk style.',
        ),
        target: LessonLink('r10_alternating_bass'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Canciones', en: 'Songs'),
        body: LocalizedText(
          es: 'Pon todo en práctica con una canción de la biblioteca.',
          en: 'Put it all to work with a song from the library.',
        ),
        target: ModuleLink(GuideModule.songs),
      ),
    ],
  ),

  // ── Teoría ───────────────────────────────────────────────────────────────
  Guide(
    id: 'theory_fretboard',
    category: GuideCategory.theory,
    level: GuideLevel.beginner,
    title: LocalizedText(es: 'El mástil', en: 'The fretboard'),
    subtitle: LocalizedText(
      es: 'Nombres de notas, sostenidos y octavas',
      en: 'Note names, sharps and octaves',
    ),
    art: NotesArt(['E', 'F', 'G', 'A']),
    chapters: [
      GuideChapter(
        title: LocalizedText(es: 'Las cuerdas al aire', en: 'The open strings'),
        body: LocalizedText(
          es: 'De la 6ª a la 1ª: E, A, D, G, B y E.',
          en: 'From the 6th to the 1st: E, A, D, G, B and E.',
        ),
        target: CourseLink(LessonCourse.basics, 'b_meet'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Las notas graves', en: 'The low notes'),
        body: LocalizedText(
          es: 'Las notas de la 6ª y la 5ª cuerda ubican cualquier cejilla.',
          en: 'The notes on the 6th and 5th strings locate any barre chord.',
        ),
        target: LessonLink('l9_low_string_notes'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Octavas', en: 'Octaves'),
        body: LocalizedText(
          es: 'El traste 12 repite la cuerda al aire una octava arriba.',
          en: 'Fret 12 repeats the open string an octave higher.',
        ),
        target: ScaleLink(LessonScale(scaleId: 'major', root: 0)),
      ),
    ],
  ),
  Guide(
    id: 'theory_harmony',
    category: GuideCategory.theory,
    level: GuideLevel.intermediate,
    title: LocalizedText(es: 'Armonía', en: 'Harmony'),
    subtitle: LocalizedText(
      es: 'Escalas, acordes y tonalidades',
      en: 'Scales, chords and keys',
    ),
    art: NotesArt(['C', 'F', 'G']),
    chapters: [
      GuideChapter(
        title: LocalizedText(es: 'Los acordes de una tonalidad', en: 'The chords of a key'),
        body: LocalizedText(
          es: 'En una tonalidad mayor: I, ii, iii, IV, V, vi y vii°.',
          en: 'In a major key: I, ii, iii, IV, V, vi and vii°.',
        ),
        target: ModuleLink(GuideModule.circle),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Tonalidades vecinas', en: 'Neighboring keys'),
        body: LocalizedText(
          es: 'Dos vecinas en el círculo comparten 6 de sus 7 notas.',
          en: 'Two neighbors on the circle share 6 of their 7 notes.',
        ),
        target: LessonLink('l16_neighbor_keys'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Por qué suena así', en: 'Why it sounds that way'),
        body: LocalizedText(
          es: 'Tensión y reposo en las progresiones más usadas.',
          en: 'Tension and rest in the most common progressions.',
        ),
        target: ModuleLink(GuideModule.progressions),
      ),
    ],
  ),
  Guide(
    id: 'theory_rhythm',
    category: GuideCategory.theory,
    level: GuideLevel.intermediate,
    title: LocalizedText(es: 'Ritmo', en: 'Rhythm'),
    subtitle: LocalizedText(
      es: 'Negras, corcheas y compases',
      en: 'Quarter notes, eighth notes and time signatures',
    ),
    art: StrumArt('D D D D '),
    chapters: [
      GuideChapter(
        title: LocalizedText(es: 'Negras', en: 'Quarter notes'),
        body: LocalizedText(
          es: 'Un golpe por pulso: cuatro por compás en 4/4.',
          en: 'One stroke per beat: four per bar in 4/4.',
        ),
        target: CourseLink(LessonCourse.strumming, 'sp1_one'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Corcheas', en: 'Eighth notes'),
        body: LocalizedText(
          es: 'Dos golpes por pulso: ocho por compás en 4/4.',
          en: 'Two strokes per beat: eight per bar in 4/4.',
        ),
        target: CourseLink(LessonCourse.strumming, 'sp2_learn'),
      ),
      GuideChapter(
        title: LocalizedText(es: '3/4', en: '3/4'),
        body: LocalizedText(
          es: 'Tres pulsos por compás, como el vals.',
          en: 'Three beats per bar, like a waltz.',
        ),
        target: LessonLink('r4_three_four'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Pon a prueba tu pulso', en: 'Test your timing'),
        body: LocalizedText(
          es: 'El juego de ritmo mide qué tan cerca del clic tocas.',
          en: 'The rhythm game measures how close to the click you play.',
        ),
        target: ModuleLink(GuideModule.rhythmGame),
      ),
    ],
  ),
  Guide(
    id: 'theory_ear',
    category: GuideCategory.theory,
    level: GuideLevel.intermediate,
    title: LocalizedText(es: 'Oído', en: 'Ear training'),
    subtitle: LocalizedText(
      es: 'Reconocer lo que escuchas',
      en: 'Recognize what you hear',
    ),
    art: NotesArt(['C', 'E', 'G']),
    chapters: [
      GuideChapter(
        title: LocalizedText(es: 'Intervalos', en: 'Intervals'),
        body: LocalizedText(
          es: 'Escucha dos notas y di a qué distancia están.',
          en: 'Hear two notes and name the distance between them.',
        ),
        target: ModuleLink(GuideModule.earTraining),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Mayor y menor de oído', en: 'Major and minor by ear'),
        body: LocalizedText(
          es: 'Toca D y Dm seguidos: la única nota que cambia es la 3ª.',
          en: 'Play D and Dm back to back: the only note that changes is the 3rd.',
        ),
        target: LessonLink('r11_d_dm'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Afinar de oído', en: 'Tuning by ear'),
        body: LocalizedText(
          es: 'Compara cada cuerda con el afinador hasta que suenen iguales.',
          en: 'Compare each string with the tuner until they sound the same.',
        ),
        target: ModuleLink(GuideModule.tuner),
      ),
    ],
  ),

  // ── Técnica solista ──────────────────────────────────────────────────────
  Guide(
    id: 'intro_caged',
    category: GuideCategory.lead,
    level: GuideLevel.intermediate,
    title: LocalizedText(es: 'Introducción a CAGED', en: 'Intro to CAGED'),
    subtitle: LocalizedText(
      es: 'Cinco formas para todo el mástil',
      en: 'Five shapes for the whole neck',
    ),
    art: NotesArt(['C', 'A', 'G', 'E', 'D']),
    chapters: [
      GuideChapter(
        title: LocalizedText(es: 'Las cinco formas', en: 'The five shapes'),
        body: LocalizedText(
          es: 'C, A, G, E y D, en ese orden subiendo por el mástil.',
          en: 'C, A, G, E and D, in that order going up the neck.',
        ),
        target: ScaleLink(LessonScale(scaleId: 'major', root: 0)),
      ),
      GuideChapter(
        title: LocalizedText(es: 'La cejilla es la forma E', en: 'The barre is the E shape'),
        body: LocalizedText(
          es: 'F con cejilla es la forma de E movida un traste.',
          en: 'Barre F is the E shape moved up one fret.',
        ),
        target: LessonLink('r5_barre'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Con el capo', en: 'With a capo'),
        body: LocalizedText(
          es: 'Las mismas formas abiertas sirven en cualquier tonalidad.',
          en: 'The same open shapes work in any key.',
        ),
        target: ModuleLink(GuideModule.capo),
      ),
    ],
  ),
  Guide(
    id: 'caged_chord_scale',
    category: GuideCategory.lead,
    level: GuideLevel.intermediate,
    title: LocalizedText(es: 'CAGED: acorde y escala', en: 'CAGED: chord and scale'),
    subtitle: LocalizedText(
      es: 'Cada forma del acorde con su escala alrededor',
      en: 'Each chord shape with its scale around it',
    ),
    art: ChordArt('C'),
    chapters: [
      GuideChapter(
        title: LocalizedText(es: 'Cinco formas de C', en: 'Five shapes of C'),
        body: LocalizedText(
          es: 'La ficha de C muestra sus cinco formas: C al aire, A en el traste 3, '
              'G en el 5, E en el 8 y D en el 10.',
          en: 'The C page shows its five shapes: open C, A at fret 3, G at 5, '
              'E at 8 and D at 10.',
        ),
        target: ChordLink('C'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Forma C', en: 'C shape'),
        body: LocalizedText(
          es: 'El C al aire (de la 6ª a la 1ª: x 3 2 0 1 0). Sus notas están dentro '
              'de la forma C de la escala mayor, del traste 0 al 4.',
          en: 'Open C (6th to 1st: x 3 2 0 1 0). Its notes sit inside the C shape '
              'of the major scale, from fret 0 to 4.',
        ),
        target: ScaleLink(LessonScale(scaleId: 'major', root: 0), position: 'caged_c'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Forma A', en: 'A shape'),
        body: LocalizedText(
          es: 'C con la forma A en el traste 3 (x 3 5 5 5 3). Sus notas están '
              'dentro de la forma A de la escala, del traste 3 al 7.',
          en: 'C with the A shape at fret 3 (x 3 5 5 5 3). Its notes sit inside '
              'the A shape of the scale, from fret 3 to 7.',
        ),
        target: ScaleLink(LessonScale(scaleId: 'major', root: 0), position: 'caged_a'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Forma G', en: 'G shape'),
        body: LocalizedText(
          es: 'C con la forma G en el traste 5 (8 7 5 5 5 8). Sus notas están '
              'dentro de la forma G de la escala, del traste 5 al 9.',
          en: 'C with the G shape at fret 5 (8 7 5 5 5 8). Its notes sit inside '
              'the G shape of the scale, from fret 5 to 9.',
        ),
        target: ScaleLink(LessonScale(scaleId: 'major', root: 0), position: 'caged_g'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Forma E', en: 'E shape'),
        body: LocalizedText(
          es: 'C con la forma E en el traste 8 (8 10 10 9 8 8). Sus notas están '
              'dentro de la forma E de la escala, del traste 8 al 12.',
          en: 'C with the E shape at fret 8 (8 10 10 9 8 8). Its notes sit inside '
              'the E shape of the scale, from fret 8 to 12.',
        ),
        target: ScaleLink(LessonScale(scaleId: 'major', root: 0), position: 'caged_e'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Forma D', en: 'D shape'),
        body: LocalizedText(
          es: 'C con la forma D en el traste 10 (x x 10 12 13 12). Sus notas están '
              'dentro de la forma D de la escala, del traste 10 al 14.',
          en: 'C with the D shape at fret 10 (x x 10 12 13 12). Its notes sit '
              'inside the D shape of the scale, from fret 10 to 14.',
        ),
        target: ScaleLink(LessonScale(scaleId: 'major', root: 0), position: 'caged_d'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Encadénalas', en: 'Chain them'),
        body: LocalizedText(
          es: 'Cada forma empieza antes de que termine la anterior: C, A, G, E, D '
              'y, desde el traste 12, otra vez C.',
          en: 'Each shape starts before the previous one ends: C, A, G, E, D and, '
              'from fret 12, C again.',
        ),
        target: ScaleLink(LessonScale(scaleId: 'major', root: 0)),
      ),
    ],
  ),
  Guide(
    id: 'intro_arpeggios',
    category: GuideCategory.lead,
    level: GuideLevel.intermediate,
    title: LocalizedText(es: 'Introducción a los arpegios', en: 'Intro to arpeggios'),
    subtitle: LocalizedText(
      es: 'Las notas del acorde, una por una',
      en: 'The chord tones, one at a time',
    ),
    art: ChordArt('Am'),
    chapters: [
      GuideChapter(
        title: LocalizedText(es: 'Con los dedos', en: 'With your fingers'),
        body: LocalizedText(
          es: 'p, i, m, a: una nota del acorde por clic.',
          en: 'p, i, m, a: one chord tone per click.',
        ),
        target: LessonLink('r9_arpeggio'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Tríadas por el mástil', en: 'Triads across the neck'),
        body: LocalizedText(
          es: 'La ficha de cada acorde muestra sus tríadas e inversiones.',
          en: 'Each chord page shows its triads and inversions.',
        ),
        target: ChordLink('C'),
      ),
    ],
  ),
  Guide(
    id: 'intro_modes',
    category: GuideCategory.lead,
    level: GuideLevel.advanced,
    title: LocalizedText(es: 'Introducción a los modos', en: 'Intro to modes'),
    subtitle: LocalizedText(
      es: 'Siete colores de la escala mayor',
      en: 'Seven colors of the major scale',
    ),
    art: ScaleArt(LessonScale(scaleId: 'dorian', root: 2)),
    chapters: [
      GuideChapter(
        title: LocalizedText(es: 'Qué es un modo', en: 'What a mode is'),
        body: LocalizedText(
          es: 'La escala mayor empezada en cada uno de sus siete grados.',
          en: 'The major scale started on each of its seven degrees.',
        ),
        target: ModuleLink(GuideModule.scales),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Dórico', en: 'Dorian'),
        body: LocalizedText(
          es: 'D dórico usa las notas de C mayor con D como casa.',
          en: 'D Dorian uses the notes of C major with D as home.',
        ),
        target: ScaleLink(LessonScale(scaleId: 'dorian', root: 2)),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Mixolidio', en: 'Mixolydian'),
        body: LocalizedText(
          es: 'G mixolidio también usa las notas de C mayor, con G como casa.',
          en: 'G Mixolydian also uses the notes of C major, with G as home.',
        ),
        target: ScaleLink(LessonScale(scaleId: 'mixolydian', root: 7)),
      ),
    ],
  ),
  Guide(
    id: 'bends_vibrato',
    category: GuideCategory.lead,
    level: GuideLevel.intermediate,
    title: LocalizedText(es: 'Bends y vibrato', en: 'Bends and vibrato'),
    subtitle: LocalizedText(
      es: 'Que la guitarra cante',
      en: 'Make the guitar sing',
    ),
    art: ScaleArt(LessonScale(scaleId: 'pentatonic_minor', root: 9)),
    chapters: [
      GuideChapter(
        title: LocalizedText(es: 'Bends afinados', en: 'Bends in tune'),
        body: LocalizedText(
          es: 'Un bend de un tono debe llegar a la nota dos trastes arriba.',
          en: 'A whole-step bend should reach the note two frets up.',
        ),
        target: LessonLink('l4_bends'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Vibrato', en: 'Vibrato'),
        body: LocalizedText(
          es: 'Un movimiento parejo que hace sonar la nota viva.',
          en: 'An even motion that makes the note come alive.',
        ),
        target: LessonLink('l5_vibrato'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'En un lick', en: 'In a lick'),
        body: LocalizedText(
          es: 'Úsalos para cerrar una frase.',
          en: 'Use them to end a phrase.',
        ),
        target: LessonLink('l11_bend_lick'),
      ),
    ],
  ),
  Guide(
    id: 'phrasing',
    category: GuideCategory.lead,
    level: GuideLevel.intermediate,
    title: LocalizedText(es: 'Fraseo', en: 'Phrasing'),
    subtitle: LocalizedText(
      es: 'Ligados y frases que dialogan',
      en: 'Legato and phrases that talk back',
    ),
    art: NotesArt(['A', 'G', 'E', 'D']),
    chapters: [
      GuideChapter(
        title: LocalizedText(es: 'Ligados', en: 'Legato'),
        body: LocalizedText(
          es: 'Hammer-on y pull-off: notas sin púa.',
          en: 'Hammer-ons and pull-offs: notes without the pick.',
        ),
        target: LessonLink('l3_legato'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Pregunta y respuesta', en: 'Call and response'),
        body: LocalizedText(
          es: 'Una frase que pregunta y otra que vuelve a la tónica.',
          en: 'One phrase that asks and another that returns to the root.',
        ),
        target: LessonLink('l13_call_response'),
      ),
      GuideChapter(
        title: LocalizedText(es: 'Double stops', en: 'Double stops'),
        body: LocalizedText(
          es: 'Dos notas a la vez para frases más llenas.',
          en: 'Two notes at once for fuller phrases.',
        ),
        target: LessonLink('l17_thirds'),
      ),
    ],
  ),
];

/// Guías de [category], en orden.
List<Guide> guidesIn(GuideCategory category) =>
    [for (final g in guides) if (g.category == category) g];

/// Guías por id.
final Map<String, Guide> guidesById = {for (final g in guides) g.id: g};

const _folds = {
  'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n', //
};

/// Texto para comparar al buscar: minúsculas y sin tildes.
String foldForSearch(String text) {
  final lower = text.toLowerCase();
  final out = StringBuffer();
  for (final ch in lower.split('')) {
    out.write(_folds[ch] ?? ch);
  }
  return out.toString();
}

/// Guías que contienen todas las palabras de [query] en su título, subtítulo o
/// en el título de un capítulo, en el idioma actual, y, con [level], solo las
/// de ese nivel. Vacía y sin nivel = todas.
List<Guide> searchGuides(String query, {GuideLevel? level}) {
  final words = foldForSearch(query)
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  return [
    for (final g in guides)
      if ((level == null || g.level == level) && (words.isEmpty || _matches(g, words))) g,
  ];
}

bool _matches(Guide guide, List<String> words) {
  final haystack = foldForSearch(
    [
      guide.title.text,
      guide.subtitle.text,
      for (final c in guide.chapters) c.title.text,
    ].join(' '),
  );
  return words.every(haystack.contains);
}
