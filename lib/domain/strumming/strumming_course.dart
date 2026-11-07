/// Curso "Patrones de rasgueo – Parte 1": cinco patrones en 4/4 con los
/// acordes de Acordes abiertos (Em, G, D, C). Cada patrón se aprende, se
/// practica con uno, dos y cuatro acordes, y luego se toca en canciones de
/// dominio público. Los textos de cada patrón se generan del patrón.
library;

import '../../core/i18n/tr.dart';
import '../courses/course.dart';
import '../courses/course_songs.dart';
import '../open_chords/chord_shape.dart';
import 'strum_pattern.dart';

/// Los cinco patrones, del más simple al más movido (una letra por corchea).
const strummingPatterns = [
  'D D D D ', // 1: negras, abajo en cada número
  'DUDUDUDU', // 2: corcheas, abajo y arriba
  'D DUD DU', // 3: negra y dos corcheas, dos veces
  'D DU UDU', // 4: el rasgueo pop, con el 3 al aire
  'D D DUDU', // 5: dos negras y cuatro corcheas
];

/// Acordes del curso (los de Acordes abiertos – Parte 1).
const strummingCourseChords = ['Em', 'G', 'D', 'C'];

/// Qué hace un paso del curso.
enum StrumContent { theory, pattern, hints, practice, song, finale }

class StrumStep implements CourseStep {
  const StrumStep({
    required this.id,
    required this.kind,
    required this.content,
    required this.title,
    required this.body,
    this.slots = const [],
    this.patterns = const [],
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
  final StrumContent content;
  final LocalizedText body;

  /// Un acorde por compás de 4/4.
  final List<ChordShape> slots;

  /// El patrón de cada compás (mismo largo que [slots]). En teoría, el patrón
  /// que se explica, si hay uno.
  final List<String> patterns;
}

/// "Patrón 3".
LocalizedText patternName(int index) =>
    LocalizedText(es: 'Patrón ${index + 1}', en: 'Pattern ${index + 1}');

String _countsEs(List<int> eighths) {
  final items = [
    for (final i in eighths)
      if (i.isEven) '${i ~/ 2 + 1}' else 'la «y» del ${i ~/ 2 + 1}',
  ];
  return items.length < 2
      ? items.join()
      : '${items.sublist(0, items.length - 1).join(', ')} y ${items.last}';
}

String _countsEn(List<int> eighths) {
  final items = [
    for (final i in eighths)
      if (i.isEven) '${i ~/ 2 + 1}' else 'the “and” of ${i ~/ 2 + 1}',
  ];
  return items.length < 2
      ? items.join()
      : '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
}

/// Cómo se toca [pattern], dicho desde el conteo "1 y 2 y 3 y 4 y".
LocalizedText patternText(String pattern) {
  final downs = strokesAt(pattern, 'D');
  final ups = strokesAt(pattern, 'U');
  final n = strokeCount(pattern);
  final es = StringBuffer('Cuenta «1 y 2 y 3 y 4 y». Abajo en ${_countsEs(downs)}');
  final en = StringBuffer('Count “1 and 2 and 3 and 4 and”. Down on ${_countsEn(downs)}');
  if (ups.isEmpty) {
    es.write('; ningún golpe hacia arriba.');
    en.write('; no up strums.');
  } else {
    es.write('; arriba en ${_countsEs(ups)}.');
    en.write('; up on ${_countsEn(ups)}.');
  }
  es.write(' Son $n golpes por compás.');
  en.write(' That is $n strums per bar.');
  final skipped = [
    for (var i = 0; i < pattern.length; i++)
      if (pattern[i] == ' ') i,
  ];
  if (skipped.isNotEmpty && ups.isNotEmpty) {
    es.write(' En ${_countsEs(skipped)} la mano pasa sin tocar las cuerdas.');
    en.write(' On ${_countsEn(skipped)} the hand passes without touching the strings.');
  }
  return LocalizedText(es: es.toString(), en: en.toString());
}

/// Consejos del patrón: el péndulo (la mano no para) y dónde está el golpe
/// que se salta.
LocalizedText hintsText(String pattern) {
  final es = <String>[];
  final en = <String>[];
  if (followsPendulum(pattern)) {
    es.add(
      'La mano se mueve como un péndulo y no para: baja en cada número y sube '
      'en cada «y», toque o no las cuerdas.',
    );
    en.add(
      'Your hand moves like a pendulum and never stops: down on every number and '
      'up on every “and”, whether or not it hits the strings.',
    );
  }
  final missedDowns = [
    for (var i = 0; i < pattern.length; i += 2)
      if (pattern[i] == ' ') i,
  ];
  if (missedDowns.isNotEmpty) {
    es.add(
      'En el ${[for (final i in missedDowns) i ~/ 2 + 1].join(' y el ')} la mano '
      'baja sin tocar: así la «y» que sigue sale hacia arriba, en su lugar.',
    );
    en.add(
      'On ${_countsEn(missedDowns)} the hand goes down without touching: that way '
      'the next “and” comes out as an up strum, in its place.',
    );
  }
  es.add('Cuenta en voz alta y empieza despacio: el tempo se sube cuando sale limpio.');
  en.add('Count out loud and start slow: raise the tempo once it comes out clean.');
  return LocalizedText(es: es.join(' '), en: en.join(' '));
}

/// Canciones de cada patrón (solo de 4/4).
const _songsFor = <int, List<CourseSong>>{
  0: [skipToMyLou, tomDooley, maryLamb],
  1: [rowYourBoat, drunkenSailor, saints],
  2: [ohSusanna, skipToMyLou, drunkenSailor],
  3: [saints, maryLamb, tomDooley],
  4: [ohSusanna, rowYourBoat, saints],
};

/// Canciones donde se alternan los patrones 3 y 4, compás a compás.
const _combinedSongs = [skipToMyLou, ohSusanna, drunkenSailor];

/// Los niveles: cada patrón y, detrás, el patrón en canciones; antes del
/// quinto, uno que combina el 3 y el 4; al final, el cierre del curso.
List<CourseLevel<StrumStep>> buildStrummingCourse(Map<String, ChordShape> shapes) {
  ChordShape shape(String name) =>
      shapes[name] ?? (throw ArgumentError('Falta la digitación de $name'));
  final levels = <CourseLevel<StrumStep>>[];
  for (var p = 0; p < strummingPatterns.length; p++) {
    if (p == 4) levels.add(_combinedLevel(shape));
    levels
      ..add(_patternLevel(p, shape))
      ..add(_songsLevel(p, _songsFor[p]!, shape));
  }
  levels.add(_finaleLevel(shape));
  return levels;
}

CourseLevel<StrumStep> _patternLevel(int p, ChordShape Function(String) shape) {
  final pattern = strummingPatterns[p];
  final name = patternName(p);
  final k = 'sp${p + 1}';
  StrumStep practice(String suffix, LocalizedText title, LocalizedText body, List<String> bars) =>
      StrumStep(
        id: '${k}_$suffix',
        kind: CourseStepKind.exercise,
        content: StrumContent.practice,
        title: title,
        body: body,
        slots: [for (final c in bars) shape(c)],
        patterns: List.filled(bars.length, pattern),
      );
  return CourseLevel(
    title: name,
    intro: LocalizedText(
      es: '${name.es}: ${strokeCount(pattern)} golpes por compás. Lo aprendes '
          'con un acorde y lo llevas a dos y a cuatro.',
      en: '${name.en}: ${strokeCount(pattern)} strums per bar. You learn it with '
          'one chord and take it to two and four.',
    ),
    steps: [
      if (p == 0)
        const StrumStep(
          id: 'sp_tempo_beat',
          kind: CourseStepKind.theory,
          content: StrumContent.theory,
          title: LocalizedText(es: 'Tempo, pulso y BPM', en: 'Tempo, beat and BPM'),
          body: LocalizedText(
            es: 'El pulso es el golpe parejo que marcas con el pie. El tempo es '
                'qué tan rápido va, en pulsos por minuto (BPM): a 60 BPM hay un '
                'pulso por segundo. En 4/4 cada compás tiene 4 pulsos y se cuenta '
                '«1 2 3 4»; entre pulso y pulso cabe una «y»: «1 y 2 y 3 y 4 y».',
            en: 'The beat is the steady pulse you tap with your foot. The tempo is '
                'how fast it goes, in beats per minute (BPM): at 60 BPM there is '
                'one beat per second. In 4/4 each bar has 4 beats, counted '
                '“1 2 3 4”; an “and” fits between beats: “1 and 2 and 3 and 4 and”.',
          ),
        ),
      if (p == 2)
        const StrumStep(
          id: 'sp_count_ands',
          kind: CourseStepKind.theory,
          content: StrumContent.theory,
          title: LocalizedText(es: 'Contar las «y»', en: 'Counting the “ands”'),
          body: LocalizedText(
            es: 'Desde aquí los golpes caen también entre los números. Cuenta '
                '«1 y 2 y 3 y 4 y» en voz alta: los números van hacia abajo y '
                'las «y» hacia arriba, siempre.',
            en: 'From here on strums also fall between the numbers. Count '
                '“1 and 2 and 3 and 4 and” out loud: numbers go down and “ands” '
                'go up, always.',
          ),
        ),
      StrumStep(
        id: '${k}_learn',
        kind: CourseStepKind.theory,
        content: StrumContent.pattern,
        title: LocalizedText(es: 'Aprende el ${name.es.toLowerCase()}', en: 'Learn ${name.en.toLowerCase()}'),
        body: patternText(pattern),
        patterns: [pattern],
      ),
      if (p == 1)
        practice(
          'up',
          const LocalizedText(es: 'Rasgueo hacia arriba', en: 'Up strum practice'),
          const LocalizedText(
            es: 'Arriba solo rozas las cuerdas agudas: la mano sube suelta, sin '
                'empujar. Con Em, cuatro compases.',
            en: 'On the way up you only brush the high strings: the hand rises '
                'loose, without pushing. With Em, four bars.',
          ),
          ['Em', 'Em', 'Em', 'Em'],
        ),
      practice(
        'one',
        const LocalizedText(es: 'Con un acorde', en: 'Practice with one chord'),
        const LocalizedText(
          es: 'Cuatro compases de Em: sin cambios, toda la atención en la mano '
              'derecha.',
          en: 'Four bars of Em: no changes, all your attention on the strumming '
              'hand.',
        ),
        ['Em', 'Em', 'Em', 'Em'],
      ),
      StrumStep(
        id: '${k}_hints',
        kind: CourseStepKind.theory,
        content: StrumContent.hints,
        title: LocalizedText(es: 'Consejos del ${name.es.toLowerCase()}', en: '${name.en} hints'),
        body: hintsText(pattern),
        patterns: [pattern],
      ),
      practice(
        'two',
        const LocalizedText(es: 'Con dos acordes', en: 'Practice with two chords'),
        const LocalizedText(
          es: 'G y D, un compás cada uno. El cambio va en el último golpe del '
              'compás: si hace falta, déjalo al aire.',
          en: 'G and D, one bar each. The change goes on the last strum of the '
              'bar: if you need to, let it ring open.',
        ),
        ['G', 'D', 'G', 'D'],
      ),
      practice(
        'four',
        const LocalizedText(es: 'Con cuatro acordes', en: 'Practice with four chords'),
        const LocalizedText(
          es: 'G – D – Em – C, un compás cada uno: la progresión I – V – vi – IV '
              'en G.',
          en: 'G – D – Em – C, one bar each: the I – V – vi – IV progression in G.',
        ),
        ['G', 'D', 'Em', 'C'],
      ),
    ],
  );
}

StrumStep _songStep(
  String levelKey,
  CourseSong song,
  List<String> patternCycle,
  ChordShape Function(String) shape,
) => StrumStep(
  id: '${levelKey}_${song.id}',
  kind: CourseStepKind.song,
  content: StrumContent.song,
  title: song.title,
  origin: song.origin,
  body: LocalizedText(
    es: '${song.bars.length} compases, un acorde por compás: '
        '${{for (final c in song.bars) c}.join(', ')}.',
    en: '${song.bars.length} bars, one chord per bar: '
        '${{for (final c in song.bars) c}.join(', ')}.',
  ),
  slots: [for (final c in song.bars) shape(c)],
  patterns: [for (var i = 0; i < song.bars.length; i++) patternCycle[i % patternCycle.length]],
);

CourseLevel<StrumStep> _songsLevel(
  int p,
  List<CourseSong> songs,
  ChordShape Function(String) shape,
) {
  final name = patternName(p);
  return CourseLevel(
    title: LocalizedText(
      es: 'El ${name.es.toLowerCase()} en canciones',
      en: '${name.en} in songs',
    ),
    intro: LocalizedText(
      es: 'Canciones de dominio público con el ${name.es.toLowerCase()} en cada compás.',
      en: 'Public-domain songs with ${name.en.toLowerCase()} in every bar.',
    ),
    steps: [
      for (final song in songs) _songStep('sp${p + 1}s', song, [strummingPatterns[p]], shape),
    ],
  );
}

CourseLevel<StrumStep> _combinedLevel(ChordShape Function(String) shape) {
  final cycle = [strummingPatterns[2], strummingPatterns[3]];
  return CourseLevel(
    title: const LocalizedText(es: 'Combina los patrones 3 y 4', en: 'Combine patterns 3 and 4'),
    intro: const LocalizedText(
      es: 'Un compás con el 3 y el siguiente con el 4: cambia el rasgueo sin '
          'parar la mano.',
      en: 'One bar of pattern 3 and the next of pattern 4: change the strum '
          'without stopping your hand.',
    ),
    steps: [
      StrumStep(
        id: 'sp34_practice',
        kind: CourseStepKind.exercise,
        content: StrumContent.practice,
        title: const LocalizedText(es: '3 y 4 con un acorde', en: '3 and 4 with one chord'),
        body: const LocalizedText(
          es: 'Cuatro compases de G alternando los dos patrones.',
          en: 'Four bars of G alternating the two patterns.',
        ),
        slots: [for (var i = 0; i < 4; i++) shape('G')],
        patterns: [for (var i = 0; i < 4; i++) cycle[i % 2]],
      ),
      for (final song in _combinedSongs) _songStep('sp34', song, cycle, shape),
    ],
  );
}

CourseLevel<StrumStep> _finaleLevel(ChordShape Function(String) shape) {
  final bars = [for (var i = 0; i < 2; i++) ...['G', 'D', 'Em', 'C']];
  StrumStep part(int n, List<int> which, LocalizedText body) => StrumStep(
    id: 'sp_final_$n',
    kind: CourseStepKind.exercise,
    content: StrumContent.finale,
    title: LocalizedText(es: 'Parte $n', en: 'Part $n'),
    body: body,
    slots: [for (final c in bars) shape(c)],
    patterns: [for (var i = 0; i < bars.length; i++) strummingPatterns[which[i % which.length]]],
  );
  return CourseLevel(
    title: const LocalizedText(es: 'Final del curso', en: 'Course finale'),
    intro: const LocalizedText(
      es: 'G – D – Em – C dos vueltas, cambiando de patrón sobre la marcha.',
      en: 'G – D – Em – C twice round, switching patterns on the fly.',
    ),
    steps: [
      part(
        1,
        [0, 1],
        const LocalizedText(
          es: 'Patrones 1 y 2, un compás cada uno.',
          en: 'Patterns 1 and 2, one bar each.',
        ),
      ),
      part(
        2,
        [2, 3],
        const LocalizedText(
          es: 'Patrones 3 y 4, un compás cada uno.',
          en: 'Patterns 3 and 4, one bar each.',
        ),
      ),
      part(
        3,
        [0, 1, 2, 3, 4],
        const LocalizedText(
          es: 'Los cinco patrones en orden, uno por compás, y vuelta a empezar.',
          en: 'All five patterns in order, one per bar, and round again.',
        ),
      ),
    ],
  );
}
