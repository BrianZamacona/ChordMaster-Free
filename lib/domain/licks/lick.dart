/// Un lick o un riff: una frase corta, original, escrita en tablatura con su
/// ritmo y sus técnicas, que muestra cómo suena un estilo. Los estilos se
/// nombran por lo que se toca, nunca por un artista.
library;

import '../../core/i18n/tr.dart';
import '../guides/guides.dart';
import '../lessons/lesson.dart';

/// Riff = frase de acompañamiento que se repite (suele ir en las cuerdas
/// graves); lick = frase de solo.
enum LickKind { riff, lick }

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
    this.swing = TabSwing.none,
  });

  final String id;
  final LickStyle style;
  final LickKind kind;
  final GuideLevel level;
  final LocalizedText title;

  /// Qué escuchar o qué cuidar al tocarla.
  final LocalizedText about;

  /// La escala de todas sus notas (también la nota a la que llega un bend).
  final LessonScale scale;

  /// Tempo con el que se presenta.
  final int bpm;
  final List<TabNote> tab;
  final TabSwing swing;

  /// Técnicas que usa, en el orden en que aparecen.
  List<TabTechnique> get techniques => {
    for (final n in tab)
      if (!n.isRest && n.technique != TabTechnique.none) n.technique,
  }.toList();
}
