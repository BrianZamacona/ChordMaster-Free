/// Una digitación de acorde vista como la arma la mano: qué dedo va en qué
/// cuerda y traste, cómo se arma dedo a dedo y qué cambia de un acorde a
/// otro. Todo sale de los trastes y dedos de `chords.json`; nada a mano.
library;

import '../../core/i18n/tr.dart';
import '../audio/pluck_synth.dart';
import '../theory/notes.dart';

/// Trastes y dedos en el orden de `chords.json` (6ª → 1ª; `-1` = muteada,
/// `0` = al aire; dedo `0` = ninguno).
class ChordShape {
  const ChordShape({required this.name, required this.frets, required this.fingers});

  final String name;
  final List<int> frets;
  final List<int> fingers;

  /// Número de cuerda (1 = mi aguda) del índice [i] de `chords.json`.
  static int stringAt(int i) => 6 - i;

  int fretOn(int string) => frets[6 - string];

  /// Cuerdas que suenan, de grave a aguda.
  List<int> get sounding => [
    for (var i = 0; i < 6; i++)
      if (frets[i] >= 0) stringAt(i),
  ];

  /// Cuerdas que no se tocan, de grave a aguda.
  List<int> get muted => [
    for (var i = 0; i < 6; i++)
      if (frets[i] < 0) stringAt(i),
  ];

  /// Cuerdas al aire, de grave a aguda.
  List<int> get open => [
    for (var i = 0; i < 6; i++)
      if (frets[i] == 0) stringAt(i),
  ];

  /// La cuerda más grave que suena: desde ahí se rasguea.
  int get strumFrom => sounding.first;

  /// Dónde pisa cada dedo, en orden de dedo (índice primero).
  List<FingerPlacement> get placements => [
    for (var i = 0; i < 6; i++)
      if (frets[i] > 0 && fingers[i] > 0)
        (finger: fingers[i], string: stringAt(i), fret: frets[i]),
  ]..sort((a, b) => a.finger != b.finger ? a.finger - b.finger : b.string - a.string);

  /// Dedos distintos que usa, en orden.
  List<int> get fingerOrder => {for (final p in placements) p.finger}.toList();

  /// La forma con solo los primeros [count] dedos puestos: las cuerdas que
  /// pisarían los demás no se tocan (así todo lo que suena es del acorde).
  ChordShape partial(int count) {
    final kept = fingerOrder.take(count).toSet();
    return ChordShape(
      name: name,
      frets: [
        for (var i = 0; i < 6; i++)
          if (frets[i] > 0 && !kept.contains(fingers[i])) -1 else frets[i],
      ],
      fingers: [
        for (var i = 0; i < 6; i++)
          if (kept.contains(fingers[i])) fingers[i] else 0,
      ],
    );
  }

  /// Cuerdas al aire junto a una pisada: un dedo mal arqueado las apaga.
  List<int> get openNextToFretted => [
    for (final s in open)
      if ([s - 1, s + 1].any((n) => n >= 1 && n <= 6 && fretOn(n) > 0)) s,
  ];

  /// MIDI de lo que suena, de grave a aguda.
  List<int> get midi => [
    for (final s in sounding) standardOpenStringMidi[s - 1] + fretOn(s),
  ];
}

typedef FingerPlacement = ({int finger, int string, int fret});

/// Qué pasa con cada dedo de [to] al venir de [from].
class ChordChange {
  ChordChange(this.from, this.to) {
    for (final p in to.placements) {
      final same = from.placements.where((q) => q.finger == p.finger);
      if (same.any((q) => q.string == p.string && q.fret == p.fret)) {
        kept.add(p);
      } else if (same.any((q) => q.string == p.string)) {
        slid.add((p, same.firstWhere((q) => q.string == p.string).fret));
      } else if (same.any((q) => q.fret == p.fret && (q.string - p.string).abs() == 1)) {
        shifted.add((p, same.firstWhere((q) => q.fret == p.fret).string));
      } else if (from.placements.any((q) => q.string == p.string && q.fret == p.fret)) {
        swapped.add((p, from.placements.firstWhere((q) => q.string == p.string && q.fret == p.fret).finger));
      }
    }
  }

  final ChordShape from;
  final ChordShape to;

  /// Dedos que no se mueven (mismo dedo, cuerda y traste).
  final kept = <FingerPlacement>[];

  /// Dedos que siguen en su cuerda y solo cambian de traste (con el traste
  /// de origen).
  final slid = <(FingerPlacement, int)>[];

  /// Dedos que pasan a la cuerda vecina en el mismo traste (con la cuerda de
  /// origen).
  final shifted = <(FingerPlacement, int)>[];

  /// Pisadas que repiten lugar pero con otro dedo (con el dedo de origen).
  final swapped = <(FingerPlacement, int)>[];
}

// ── Textos generados ─────────────────────────────────────────────────────────

LocalizedText _fingerText(int finger) => LocalizedText(
  es: const {1: 'índice', 2: 'medio', 3: 'anular'}[finger] ?? 'meñique',
  en: const {1: 'index', 2: 'middle', 3: 'ring'}[finger] ?? 'pinky',
);

String _ordEs(int n) => '$nª';
String _ordEn(int n) => '$n${const {1: 'st', 2: 'nd', 3: 'rd'}[n] ?? 'th'}';

String _listEs(List<String> items) => items.length < 2
    ? items.join()
    : '${items.sublist(0, items.length - 1).join(', ')} y ${items.last}';
String _listEn(List<String> items) => items.length < 2
    ? items.join()
    : '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';

LocalizedText _place(FingerPlacement p) => LocalizedText(
  es: 'dedo ${_fingerText(p.finger).es} en la ${_ordEs(p.string)} cuerda, traste ${p.fret}',
  en: '${_fingerText(p.finger).en} finger on the ${_ordEn(p.string)} string, fret ${p.fret}',
);

/// "la 6ª" o "la 6ª ni la 5ª".
String _noneEs(List<int> strings) => [for (final s in strings) 'la ${_ordEs(s)}'].join(' ni ');

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// "Cómo se toca": cada dedo en orden, desde dónde rasguear y qué no suena.
LocalizedText howToPlayText(ChordShape shape) {
  final places = [for (final p in shape.placements) _place(p)];
  final es = StringBuffer('${_cap(_listEs([for (final p in places) p.es]))}. ');
  final en = StringBuffer('${_cap(_listEn([for (final p in places) p.en]))}. ');
  es.write('Rasguea desde la ${_ordEs(shape.strumFrom)} cuerda');
  en.write('Strum from the ${_ordEn(shape.strumFrom)} string');
  if (shape.muted.isEmpty) {
    es.write(': suenan las seis.');
    en.write(': all six ring.');
  } else {
    es.write('; no toques ${_noneEs(shape.muted)}.');
    en.write('; skip the ${_listEn([for (final s in shape.muted) _ordEn(s)])}.');
  }
  if (shape.open.isNotEmpty) {
    es.write(' Al aire: ${_listEs([for (final s in shape.open) _ordEs(s)])}.');
    en.write(' Open: ${_listEn([for (final s in shape.open) _ordEn(s)])}.');
  }
  return LocalizedText(es: es.toString(), en: en.toString());
}

/// Título de un paso dedo a dedo: el primero es "Solo el dedo X"; los demás,
/// "Agrega el X".
LocalizedText fingerStepTitle(ChordShape shape, int count) {
  final f = _fingerText(shape.fingerOrder[count - 1]);
  return count == 1
      ? LocalizedText(es: 'Solo el dedo ${f.es}', en: '${_cap(f.en)} finger only')
      : LocalizedText(es: 'Agrega el ${f.es}', en: 'Add the ${f.en} finger');
}

/// Qué se hace en un paso dedo a dedo.
LocalizedText fingerStepText(ChordShape shape, int count) {
  final finger = shape.fingerOrder[count - 1];
  final places = [
    for (final p in shape.placements)
      if (p.finger == finger) _place(p),
  ];
  final partial = shape.partial(count);
  final skip = partial.muted;
  final es = StringBuffer(
    '${count == 1 ? 'Pon solo el' : 'Agrega el'} '
    '${_listEs([for (final p in places) p.es])}. ',
  );
  final en = StringBuffer(
    '${count == 1 ? 'Place only the' : 'Add the'} '
    '${_listEn([for (final p in places) p.en])}. ',
  );
  es.write('Rasguea un golpe por pulso');
  en.write('Strum once per beat');
  if (skip.isNotEmpty) {
    es.write(' sin tocar ${_noneEs(skip)} (la X del diagrama)');
    en.write(' without the ${_listEn([for (final s in skip) _ordEn(s)])} (the X in the diagram)');
  }
  es.write(': todo lo que suena ya es ${shape.name}.');
  en.write(': everything that rings is already ${shape.name}.');
  return LocalizedText(es: es.toString(), en: en.toString());
}

/// Consejos sacados de la forma: desde dónde rasguear y qué cuerdas al aire
/// hay que cuidar; más uno general.
LocalizedText tipsText(ChordShape shape) {
  final es = StringBuffer(
    'Pisa con la punta del dedo, justo detrás del alambre: menos fuerza y '
    'sin zumbido. ',
  );
  final en = StringBuffer(
    'Press with your fingertip right behind the fret wire: less effort and '
    'no buzz. ',
  );
  final careful = shape.openNextToFretted;
  if (careful.length == 1) {
    es.write(
      'La ${_ordEs(careful.single)} va al aire junto a un dedo: arquéalo para '
      'no apagarla. ',
    );
    en.write(
      'The open ${_ordEn(careful.single)} string sits next to a finger: arch it '
      'so you do not mute it. ',
    );
  } else if (careful.isNotEmpty) {
    es.write(
      '${_cap(_listEs([for (final s in careful) 'la ${_ordEs(s)}']))} van al aire junto a '
      'un dedo: arquea los dedos para no apagarlas. ',
    );
    en.write(
      'The open ${_listEn([for (final s in careful) _ordEn(s)])} strings sit next '
      'to a finger: arch your fingers so you do not mute them. ',
    );
  }
  if (shape.muted.isEmpty) {
    es.write('Rasguea las seis cuerdas, desde la 6ª.');
    en.write('Strum all six strings, from the 6th.');
  } else {
    es.write(
      'Empieza el rasgueo en la ${_ordEs(shape.strumFrom)} cuerda: '
      '${_listEs([for (final s in shape.muted) 'la ${_ordEs(s)}'])} '
      '${shape.muted.length == 1 ? 'no suena' : 'no suenan'} en ${shape.name}.',
    );
    en.write(
      'Start the strum on the ${_ordEn(shape.strumFrom)} string: the '
      '${_listEn([for (final s in shape.muted) _ordEn(s)])} '
      '${shape.muted.length == 1 ? 'is' : 'are'} not part of ${shape.name}.',
    );
  }
  return LocalizedText(es: es.toString(), en: en.toString());
}

/// Cómo cambiar de [change.from] a [change.to]: qué dedo se queda, cuál se
/// desliza, cuál pasa a la cuerda vecina y qué lugar repite con otro dedo; si nada coincide, la forma
/// entera como un bloque.
LocalizedText changeText(ChordChange change) {
  final a = change.from.name;
  final b = change.to.name;
  final es = <String>[];
  final en = <String>[];
  for (final p in change.kept) {
    es.add('El ${_place(p).es} es igual en $a y en $b: no lo levantes, es tu guía.');
    en.add('The ${_place(p).en} is the same in $a and $b: keep it down as your guide.');
  }
  for (final (p, fromFret) in change.slid) {
    es.add(
      'El dedo ${_fingerText(p.finger).es} sigue en la ${_ordEs(p.string)} cuerda: '
      'deslízalo del traste $fromFret al ${p.fret} sin despegarlo.',
    );
    en.add(
      'The ${_fingerText(p.finger).en} finger stays on the ${_ordEn(p.string)} string: '
      'slide it from fret $fromFret to ${p.fret} without lifting it.',
    );
  }
  for (final (p, fromString) in change.shifted) {
    es.add(
      'El dedo ${_fingerText(p.finger).es} pasa de la ${_ordEs(fromString)} a la '
      '${_ordEs(p.string)} cuerda en el mismo traste ${p.fret}.',
    );
    en.add(
      'The ${_fingerText(p.finger).en} finger moves from the ${_ordEn(fromString)} to the '
      '${_ordEn(p.string)} string on the same fret ${p.fret}.',
    );
  }
  for (final (p, fromFinger) in change.swapped) {
    es.add(
      'La ${_ordEs(p.string)} cuerda, traste ${p.fret}, se pisa en los dos, pero '
      'con otro dedo: ${_fingerText(fromFinger).es} en $a y ${_fingerText(p.finger).es} en $b.',
    );
    en.add(
      'The ${_ordEn(p.string)} string, fret ${p.fret}, is pressed in both, but '
      'with another finger: ${_fingerText(fromFinger).en} in $a and ${_fingerText(p.finger).en} in $b.',
    );
  }
  if (change.kept.isEmpty && change.slid.isEmpty && change.shifted.isEmpty) {
    es.add('Ningún dedo se queda: levanta la mano y pon la forma de $b entera, como un bloque.');
    en.add('No finger stays: lift your hand and place the whole $b shape at once, as a block.');
  }
  es.add('Primero sin rasguear: pon y quita la forma hasta que salga sola.');
  en.add('First without strumming: place and lift the shape until it comes on its own.');
  return LocalizedText(es: es.join(' '), en: en.join(' '));
}

// ── Audio ────────────────────────────────────────────────────────────────────

/// Cuerdas que toca un golpe hacia arriba: las más agudas (la mano sube y
/// roza solo la parte de abajo del rasgueo).
const upStrumStrings = 4;

/// Lo que suena en un golpe [stroke] (`D` o `U`) sobre [shape]: abajo, todas
/// las cuerdas de grave a aguda; arriba, las [upStrumStrings] más agudas, de
/// aguda a grave.
List<int> strokeMidi(ChordShape shape, String stroke) {
  final all = shape.midi;
  if (stroke != 'U') return all;
  final from = all.length > upStrumStrings ? all.length - upStrumStrings : 0;
  return all.sublist(from).reversed.toList();
}

/// El rasgueo de cada forma de [slots], que dura [beatsPerSlot] pulsos. Cada
/// forma sigue su patrón de [patterns] (una letra por corchea, como en
/// `strum_pattern.dart`); sin patrones, un golpe hacia abajo por pulso. Las
/// cuerdas de un golpe se separan [defaultStrumGap].
List<NoteEvent> strumEvents(
  List<ChordShape> slots, {
  required int bpm,
  required int beatsPerSlot,
  List<String>? patterns,
}) {
  final eighth = 30 / bpm;
  final perSlot = beatsPerSlot * 2;
  return [
    for (final (i, shape) in slots.indexed)
      for (final (k, stroke) in (patterns?[i] ?? 'D ' * beatsPerSlot).split('').indexed)
        if (stroke != ' ')
          for (final (j, m) in strokeMidi(shape, stroke).indexed)
            (midi: m, at: (i * perSlot + k) * eighth + j * defaultStrumGap),
  ];
}

/// Cuánto suena cada cuerda de un golpe: hasta el siguiente pulso.
double strumRingSeconds(int bpm) => 60 / bpm;

/// Duración total del audio de [count] formas.
double strumDurationSeconds(int count, {required int bpm, required int beatsPerSlot}) =>
    count == 0 ? 0 : count * beatsPerSlot * 60 / bpm + 0.3;

/// Qué corchea suena a los [elapsed] segundos, contando desde la primera
/// forma; `null` antes y al terminar.
int? strumEighthAt(
  double elapsed,
  int count, {
  required int bpm,
  required int beatsPerSlot,
}) {
  if (elapsed < 0 || count == 0) return null;
  final i = (elapsed / (30 / bpm)).floor();
  return i < count * beatsPerSlot * 2 ? i : null;
}
