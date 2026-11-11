/// Un lick o un riff: una frase corta, original, escrita en tablatura con su
/// ritmo y sus técnicas, que muestra cómo suena un estilo. Los estilos se
/// nombran por lo que se toca, nunca por un artista.
library;

import '../../core/i18n/tr.dart';
import '../guides/guides.dart';
import '../lessons/lesson.dart';
import '../theory/notes.dart';

/// Riff = frase de acompañamiento que se repite (suele ir en las cuerdas
/// graves); lick = frase corta de solo; relleno = lo que se toca entre los
/// golpes de la parte rítmica para unir acordes; solo = varios compases, de
/// varios renglones.
enum LickKind { riff, lick, fill, solo }

/// Estilos de la biblioteca.
enum LickStyle {
  stadiumHardRock,
  classicHardRock,
  heavyDoom,
  thrashMetal,
  latinRock,
  symphonicRock,
  psychedelicRock,
  virtuosoHardRock,
  atmosphericRock,
  progressiveMetal,
  singerSongwriterFolk,

  // Géneros (fila Géneros de Guías).
  funk,
  reggae,
  punk,
  country,
  jazz,
  grunge,
  metal,
  southernRock,
  minorBlues,
}

/// Cómo suena un estilo: nombre, resumen y las técnicas que lo distinguen
/// (un test exige que sus licks las usen). Con [genre], es un género: su guía
/// va en la fila Géneros y no en Estilos.
class LickStyleInfo {
  const LickStyleInfo({
    required this.title,
    required this.summary,
    required this.traits,
    this.genre = false,
  });

  final LocalizedText title;
  final LocalizedText summary;
  final Set<TabTechnique> traits;
  final bool genre;
}

/// Una frase de la biblioteca. [id] es permanente (guarda el récord).
class Lick {
  const Lick({
    required this.id,
    required this.style,
    required this.kind,
    required this.level,
    required this.title,
    required this.about,
    required this.scale,
    required this.bpm,
    required this.tab,
    required this.chords,
    this.swing = TabSwing.none,
  });

  final String id;
  final LickStyle style;
  final LickKind kind;
  final GuideLevel level;
  final LocalizedText title;

  /// Qué escuchar o qué cuidar al tocarla. Las notas se escriben relativas a
  /// la tónica (`{R}` = la tónica, `{R+11}` = 11 semitonos arriba) para que
  /// el texto siga siendo cierto al transponer: se lee con [aboutIn].
  final LocalizedText about;

  /// [about] en la tónica [root].
  LocalizedText aboutIn(int root) =>
      LocalizedText(es: renderNoteTemplate(about.es, root), en: renderNoteTemplate(about.en, root));

  /// [about] en su tonalidad.
  LocalizedText get aboutText => aboutIn(scale.root);

  /// La escala de todas sus notas (también la nota a la que llega un bend).
  final LessonScale scale;

  /// Tempo con el que se presenta.
  final int bpm;
  final List<TabNote> tab;
  final TabSwing swing;

  /// Lo que suena debajo, en orden: cada acorde dura su [LickChord.length] y
  /// entre todos duran lo que la tablatura. Un test exige que existan en
  /// chords.json, que sus notas sean de la escala y que la frase caiga en
  /// ellos (ver `licks_test.dart`).
  final List<LickChord> chords;

  /// [chords] con la tónica [root]: la raíz de cada uno y en qué parte de
  /// pulso empieza.
  List<({int root, LickChord chord, int start})> chordsIn(int root) {
    final out = <({int root, LickChord chord, int start})>[];
    var at = 0;
    for (final c in chords) {
      out.add((root: (root + c.degree) % 12, chord: c, start: at));
      at += c.length;
    }
    return out;
  }

  /// Cómo suena la parte rítmica: un golpe hacia abajo al entrar cada acorde
  /// y en cada pulso mientras dura. [chord] es el índice en [chords] y [beat],
  /// el pulso del golpe desde el principio.
  List<({int chord, double beat})> get chordStrokes => [
    for (final (i, c) in chordsIn(scale.root).indexed)
      for (var t = c.start; t < c.start + c.chord.length; t = (t ~/ tabQuarter + 1) * tabQuarter)
        (chord: i, beat: t / tabQuarter),
  ];

  /// Técnicas que usa, en el orden en que aparecen.
  List<TabTechnique> get techniques => {
    for (final n in tab)
      if (!n.isRest && n.technique != TabTechnique.none) n.technique,
  }.toList();
}

/// Un compás de 4/4, en partes de pulso.
const lickBar = 4 * tabQuarter;

/// Un acorde de fondo de una frase: a [degree] semitonos de la tónica (así se
/// transpone con ella), del tipo [type] de chords.json (`minor7`, `power5`…)
/// y que dura [length] partes de pulso (un compás si no se dice).
class LickChord {
  const LickChord(this.degree, this.type, {this.length = lickBar});

  final int degree;
  final String type;
  final int length;
}

/// `{R+n}` en [template] = la nota a n semitonos de [root] (con sostenidos),
/// `{R}` = [root].
String renderNoteTemplate(String template, int root) => template.replaceAllMapped(
  noteTemplatePattern,
  (m) => pitchClassName((root + int.parse(m.group(1) ?? '0')) % 12),
);

/// `{R}` o `{R+n}`.
final noteTemplatePattern = RegExp(r'\{R(?:\+(\d+))?\}');
