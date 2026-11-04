import '../../core/i18n/tr.dart';

/// Camino al que pertenece una lección. Fundamentos es común; al terminarlo
/// la ruta se divide en rítmica y líder.
enum LessonTrack { foundations, rhythm, lead }

/// Herramienta de la app que una lección pide abrir.
enum LessonTool { tuner, metronome }

/// Escala que una lección enseña: id de `scales_master.json` y tónica
/// (semitono, 0 = C, como `noteIndex`).
class LessonScale {
  const LessonScale({required this.scaleId, required this.root});

  final String scaleId;
  final int root;
}

/// Lo que se dibuja en el nodo de una unidad en el mapa. Se genera desde los
/// datos de la app (diagrama, escala, rasgueo o notas), nunca es una imagen.
sealed class UnitArt {
  const UnitArt();
}

/// Diagrama de un acorde (`displayName` de `chords.json`).
class ChordArt extends UnitArt {
  const ChordArt(this.chord);
  final String chord;
}

/// Notas de una escala en su tónica.
class ScaleArt extends UnitArt {
  const ScaleArt(this.scale);
  final LessonScale scale;
}

/// Un compás de rasgueo (mismo formato que [Lesson.strumPattern]).
class StrumArt extends UnitArt {
  const StrumArt(this.pattern);
  final String pattern;
}

/// Una fila de nombres de nota (con sostenidos).
class NotesArt extends UnitArt {
  const NotesArt(this.notes);
  final List<String> notes;
}

/// Grupo de lecciones: un nodo del mapa.
class LessonUnit {
  const LessonUnit({
    required this.id,
    required this.track,
    required this.title,
    required this.art,
  });

  /// Identificador estable (va en la ruta `/learn/lessons/unit/:id`).
  final String id;
  final LessonTrack track;
  final LocalizedText title;
  final UnitArt art;
}

/// Qué mide un reto. Cada tipo lee el récord de un módulo de práctica.
enum ChallengeKind {
  /// Mejor precisión del juego de ritmo, en %.
  rhythmAccuracy,

  /// Mejor racha de intervalos acertados seguidos en Oído.
  earStreak,
}

/// Reto al final de un camino. Se supera solo, cuando el récord del módulo
/// de práctica llega a [goal]; no se marca a mano.
class LessonChallenge {
  const LessonChallenge({
    required this.id,
    required this.track,
    required this.title,
    required this.body,
    required this.kind,
    required this.goal,
  });

  final String id;
  final LessonTrack track;
  final LocalizedText title;
  final LocalizedText body;
  final ChallengeKind kind;
  final int goal;

  bool isPassed(int best) => best >= goal;
}

/// Una lección del camino.
///
/// Los acordes se nombran por su `displayName` de `chords.json` y la escala
/// por su id; un test verifica que todos existan, así la lección nunca enlaza
/// a algo que la biblioteca no tiene.
class Lesson {
  const Lesson({
    required this.id,
    required this.unit,
    required this.title,
    required this.body,
    required this.steps,
    required this.minutes,
    this.chords = const [],
    this.scale,
    this.strumPattern,
    this.tool,
    this.bpm,
  });

  /// Identificador estable: es la clave guardada en el progreso.
  final String id;

  /// Unidad (nodo del mapa) a la que pertenece.
  final LessonUnit unit;
  LessonTrack get track => unit.track;
  final LocalizedText title;

  /// Explicación de la lección, en un párrafo.
  final LocalizedText body;

  /// Qué hacer, en orden.
  final List<LocalizedText> steps;

  /// Duración aproximada.
  final int minutes;

  /// Acordes que se practican (`displayName` de `chords.json`).
  final List<String> chords;
  final LessonScale? scale;

  /// Rasgueo: D = abajo, U = arriba, espacio = la mano pasa sin tocar.
  /// Una letra o espacio por corchea.
  final String? strumPattern;
  final LessonTool? tool;

  /// Tempo sugerido para practicar.
  final int? bpm;
}
