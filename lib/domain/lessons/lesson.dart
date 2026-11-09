import '../../core/i18n/tr.dart';

/// Camino al que pertenece una lección. Fundamentos es común; al terminarlo
/// la ruta se divide en rítmica y líder.
enum LessonTrack { foundations, rhythm, lead }

/// Herramienta o módulo de la app que una lección pide abrir.
enum LessonTool { tuner, metronome, progressions, doubleStops, circle }

/// Partes de pulso (negra) de [TabNote.length]: 12 deja escribir
/// semicorcheas, corcheas y también tresillos.
const tabTicksPerBeat = 12;

/// Duraciones en partes de pulso.
const tabSixteenth = 3, tabEighth = 6, tabQuarter = 12, tabHalf = 24;

/// Tresillos: tres notas en el lugar de dos (de corchea: tres por pulso; de
/// semicorchea: tres por corchea).
const tabTripletEighth = 4, tabTripletSixteenth = 2;

/// La duración es de tresillo.
bool isTripletLength(int length) => length == tabTripletEighth || length == tabTripletSixteenth;

/// Cómo se toca una nota además de pulsarla. Las que siguen sonando sin volver
/// a pulsar ([legato]) continúan la nota anterior, en la misma cuerda.
enum TabTechnique {
  /// Pulsada, sin más.
  none,

  /// Ligado ascendente (h): un dedo cae sobre un traste más alto.
  hammerOn,

  /// Ligado descendente (p): un dedo se suelta hacia un traste más bajo.
  pullOff,

  /// Slide (/ o \): el dedo se desliza hasta el traste nuevo.
  slide,

  /// Bend (b): se pulsa y la cuerda se empuja [TabNote.bend] semitonos.
  bend,

  /// Release (r): la cuerda empujada vuelve a su traste, sin pulsar.
  release,

  /// Vibrato (~): la altura oscila un poco mientras la nota suena.
  vibrato,

  /// Apagado con la palma (PM): suena corta y sorda.
  palmMute,

  /// Nota muerta (x): la mano izquierda apaga la cuerda; solo se oye el golpe.
  dead;

  /// Sigue sonando la nota anterior: no se vuelve a pulsar.
  bool get legato => this == hammerOn || this == pullOff || this == slide || this == release;
}

/// Dirección de la púa: ⊓ abajo, V arriba.
enum PickStroke { down, up }

/// Una nota de tablatura: cuerda (1 = mi aguda, como en `scales_master.json`)
/// y traste (0 = al aire), cuánto dura ([length], en partes de pulso
/// ([tabTicksPerBeat]): hasta la nota siguiente), cómo se toca ([technique], con [bend] semitonos si es un
/// bend) y, si importa, con qué golpe de púa ([pick]). [TabNote.rest] es un
/// silencio: dura, pero no suena.
class TabNote {
  const TabNote(
    this.string,
    this.fret, {
    this.length = tabEighth,
    this.technique = TabTechnique.none,
    this.bend = 0,
    this.pick,
  });

  const TabNote.rest(this.length)
      : string = 0,
        fret = 0,
        technique = TabTechnique.none,
        bend = 0,
        pick = null;

  final int string;
  final int fret;
  final int length;
  final TabTechnique technique;

  /// Semitonos que sube un bend (1 = medio tono, 2 = un tono).
  final int bend;
  final PickStroke? pick;

  bool get isRest => string == 0;

  @override
  bool operator ==(Object other) =>
      other is TabNote &&
      other.string == string &&
      other.fret == fret &&
      other.length == length &&
      other.technique == technique &&
      other.bend == bend &&
      other.pick == pick;

  @override
  int get hashCode => Object.hash(string, fret, length, technique, bend, pick);

  @override
  String toString() => isRest
      ? 'TabNote.rest($length)'
      : 'TabNote($string, $fret${length == tabEighth ? '' : ', length: $length'}'
          '${technique == TabTechnique.none ? '' : ', $technique'}'
          '${bend == 0 ? '' : ', bend: $bend'}${pick == null ? '' : ', $pick'})';
}

/// Swing: el contratiempo llega tarde, a dos tercios del pulso (corcheas) o
/// de la corchea (semicorcheas), como en un tresillo.
enum TabSwing { none, eighths, sixteenths }

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

/// Curso por niveles que ocupa un nodo del mapa en lugar de lecciones.
enum LessonCourse { basics, melodies, openChords, strumming, openChords2 }

/// Grupo de lecciones, o un curso por niveles ([course]): un nodo del mapa.
class LessonUnit {
  const LessonUnit({
    required this.id,
    required this.track,
    required this.title,
    required this.summary,
    required this.art,
    this.level = 1,
    this.course,
  });

  /// Identificador estable (va en la ruta `/learn/lessons/unit/:id`).
  final String id;
  final LessonTrack track;
  final LocalizedText title;

  /// Qué se aprende en la unidad, en una o dos frases (vista previa).
  final LocalizedText summary;
  final UnitArt art;

  /// Nivel del camino (1 o 2). Fundamentos solo tiene nivel 1.
  final int level;

  /// Si no es `null`, el nodo abre ese curso y no tiene lecciones.
  final LessonCourse? course;
}

/// Qué mide un reto. Cada tipo lee el récord de un módulo de práctica.
enum ChallengeKind {
  /// Mejor precisión del juego de ritmo, en %.
  rhythmAccuracy,

  /// Mejor racha de intervalos acertados seguidos en Oído.
  earStreak,
}

/// Reto al final de un nivel de un camino. Se supera solo, cuando el récord del módulo
/// de práctica llega a [goal]; no se marca a mano.
class LessonChallenge {
  const LessonChallenge({
    required this.id,
    required this.track,
    required this.title,
    required this.body,
    required this.kind,
    required this.goal,
    this.level = 1,
  });

  final String id;
  final LessonTrack track;
  final LocalizedText title;
  final LocalizedText body;
  final ChallengeKind kind;
  final int goal;

  /// El reto cierra este nivel del camino.
  final int level;

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
    this.tab = const [],
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

  /// Melodía, riff o lick en tablatura, en orden. Un test verifica que cada
  /// nota pertenezca a [scale].
  final List<TabNote> tab;
}
