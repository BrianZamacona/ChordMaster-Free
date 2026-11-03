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

/// Una lección del camino.
///
/// Los acordes se nombran por su `displayName` de `chords.json` y la escala
/// por su id; un test verifica que todos existan, así la lección nunca enlaza
/// a algo que la biblioteca no tiene.
class Lesson {
  const Lesson({
    required this.id,
    required this.track,
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
  final LessonTrack track;

  /// Unidad dentro del camino (p. ej. "Acordes abiertos").
  final LocalizedText unit;
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
