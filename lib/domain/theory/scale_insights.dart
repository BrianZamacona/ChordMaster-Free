import '../../core/constants/chord_metadata.dart' show chordTypeMetadata;
import '../../core/i18n/tr.dart';
import 'intervals.dart';

/// Teoría de una escala generada por reglas a partir de sus `intervals`
/// (semitonos sobre la tónica): pasos, qué la distingue, qué acordes caben y
/// sus acordes diatónicos. Nada se escribe a mano por escala salvo las ideas
/// de improvisación ([improvisationTips]).

const majorScale = [0, 2, 4, 5, 7, 9, 11];
const naturalMinorScale = [0, 2, 3, 5, 7, 8, 10];
const _minorPentatonic = [0, 3, 5, 7, 10];

List<int> _normalized(List<int> scale) =>
    {for (final i in scale) i % 12}.toList()..sort();

/// Distancia en semitonos entre notas seguidas, cerrando en la octava.
List<int> stepPattern(List<int> scale) {
  final s = _normalized(scale);
  return [for (var i = 0; i < s.length; i++) (i + 1 < s.length ? s[i + 1] : 12) - s[i]];
}

/// Pasos como texto: T = tono, S = semitono (W/H en inglés); 3 = T+S, y
/// los saltos de las pentatónicas de los modos, 4 = 2T y 5 = 2T+S.
String stepPatternLabel(List<int> scale) => [
  for (final step in stepPattern(scale)) _stepLabel(step),
].join(' ');

String _stepLabel(int step) {
  final tone = tr(es: 'T', en: 'W');
  final half = tr(es: 'S', en: 'H');
  final tones = step ~/ 2;
  final whole = switch (tones) {
    0 => '',
    1 => tone,
    _ => '$tones$tone',
  };
  if (step.isEven) return whole;
  return whole.isEmpty ? half : '$whole+$half';
}

/// Qué distingue a la escala, comparada con la referencia más cercana.
class ScaleComparison {
  const ScaleComparison({
    required this.reference,
    required this.referenceIntervals,
    this.added = const [],
    this.removed = const [],
  });

  /// Escala de referencia: mayor, menor natural o pentatónica.
  final LocalizedText reference;
  final List<int> referenceIntervals;

  /// Notas que tiene y la referencia no (semitonos): sus notas
  /// características.
  final List<int> added;

  /// Notas de la referencia que no tiene.
  final List<int> removed;
}

const _refMajor = LocalizedText(es: 'la escala mayor', en: 'the major scale');
const _refMinor = LocalizedText(
  es: 'la menor natural',
  en: 'the natural minor scale',
);

/// `null` si es igual a una referencia o si no hay una cercana (simétricas).
ScaleComparison? compareScale(List<int> scale) {
  final s = _normalized(scale).toSet();
  ScaleComparison diff(List<int> ref, LocalizedText name) => ScaleComparison(
    reference: name,
    referenceIntervals: ref,
    added: [for (final i in s.toList()..sort()) if (!ref.contains(i)) i],
    removed: [for (final i in ref) if (!s.contains(i)) i],
  );

  if (s.length == 7) {
    final vsMajor = diff(majorScale, _refMajor);
    final vsMinor = diff(naturalMinorScale, _refMinor);
    final best = vsMajor.added.length <= vsMinor.added.length ? vsMajor : vsMinor;
    if (best.added.isEmpty) return null;
    return best.added.length <= 2 ? best : null;
  }
  if (s.length < 7) {
    // Pentatónicas: la mayor o la menor sin dos notas. Blues: pentatónica + 1.
    if (s.containsAll(_minorPentatonic) && s.length == 6) {
      return ScaleComparison(
        reference: const LocalizedText(
          es: 'la pentatónica menor',
          en: 'the minor pentatonic',
        ),
        referenceIntervals: _minorPentatonic,
        added: [for (final i in s.toList()..sort()) if (!_minorPentatonic.contains(i)) i],
      );
    }
    if (majorScale.toSet().containsAll(s)) return diff(majorScale, _refMajor);
    if (naturalMinorScale.toSet().containsAll(s)) {
      return diff(naturalMinorScale, _refMinor);
    }
  }
  return null;
}

/// Si sus pasos se repiten (tonos enteros, disminuidas), la escala es
/// simétrica: se repite cada pocos trastes.
int? symmetryPeriod(List<int> scale) {
  final steps = stepPattern(scale);
  for (var period = 1; period < steps.length; period++) {
    if (steps.length % period != 0) continue;
    var ok = true;
    for (var i = period; i < steps.length && ok; i++) {
      ok = steps[i] == steps[i - period];
    }
    if (ok) return steps.take(period).fold<int>(0, (a, b) => a + b);
  }
  return null;
}

/// Tipos de acorde (claves de chords.json) cuyas notas, construidas sobre la
/// tónica, están todas en la escala: los que puedes acompañar con ella sin
/// que ninguna nota del acorde choque.
List<String> chordTypesOnTonic(List<int> scale) {
  final s = _normalized(scale).toSet();
  final fits = [
    for (final e in chordTypeMetadata.entries)
      if (e.value.intervals.every((i) => s.contains(i % 12))) e,
  ]..sort((a, b) => a.value.order.compareTo(b.value.order));
  return [for (final e in fits) e.key];
}

/// Escalas (de [candidates], por id) que contienen todas las notas de un
/// acorde con esos [chordIntervals] construido sobre su tónica: las que
/// puedes tocar sobre ese acorde sin chocar con él.
List<String> scalesForChord(
  List<int> chordIntervals,
  Map<String, List<int>> candidates,
) => [
  for (final e in candidates.entries)
    if (chordIntervals.every((i) => _normalized(e.value).contains(i % 12))) e.key,
];

/// Acorde diatónico: tríada construida por terceras sobre un grado.
class DiatonicChord {
  const DiatonicChord({
    required this.numeral,
    required this.semitones,
    required this.type,
    this.seventhType = '',
  });

  /// Número romano con alteración (`bIII`, `ii`, `vii°`, `III+`).
  final String numeral;

  /// Semitonos de la raíz sobre la tónica.
  final int semitones;

  /// `major`, `minor`, `diminished` o `augmented` (claves de chords.json).
  final String type;

  /// Cuatríada del grado (1-3-5-7 con notas de la escala): `major7`,
  /// `dominant7`, `minor7`, `halfDiminished`, `diminished7` (claves de
  /// chords.json) o `minorMajor7` / `augmentedMajor7`, que no están en los
  /// datos. Vacío si la escala no es de 7 notas.
  final String seventhType;
}

const _romans = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];

/// Tríadas de cada grado (solo escalas de 7 notas: 1ª, 3ª y 5ª salen de
/// tomar una nota sí y una no).
List<DiatonicChord> diatonicTriads(List<int> scale) {
  final s = _normalized(scale);
  if (s.length != 7) return const [];
  return [
    for (var d = 0; d < 7; d++)
      () {
        final root = s[d];
        final third = (s[(d + 2) % 7] - root + 12) % 12;
        final fifth = (s[(d + 4) % 7] - root + 12) % 12;
        final seventh = (s[(d + 6) % 7] - root + 12) % 12;
        final type = switch ((third, fifth)) {
          (4, 7) => 'major',
          (3, 7) => 'minor',
          (3, 6) => 'diminished',
          (4, 8) => 'augmented',
          _ => 'other',
        };
        final label = spellInterval(root, s);
        final accidental = label.substring(0, label.length - 1);
        final roman = type == 'minor' || type == 'diminished'
            ? _romans[d].toLowerCase()
            : _romans[d];
        final suffix = switch (type) {
          'diminished' => '°',
          'augmented' => '+',
          _ => '',
        };
        final seventhType = switch ((type, seventh)) {
          ('major', 11) => 'major7',
          ('major', 10) => 'dominant7',
          ('minor', 10) => 'minor7',
          ('minor', 11) => 'minorMajor7',
          ('diminished', 10) => 'halfDiminished',
          ('diminished', 9) => 'diminished7',
          ('augmented', 11) => 'augmentedMajor7',
          _ => 'other',
        };
        return DiatonicChord(
          numeral: '$accidental$roman$suffix',
          semitones: root,
          type: type,
          seventhType: seventhType,
        );
      }(),
  ];
}

/// De qué escala de 7 notas salen los acordes que acompañan a [scale]:
/// ella misma; o, si es una pentatónica o la blues, la mayor o menor
/// natural de la que procede (sus acordes armonizan igual). `null` para
/// las simétricas, que se armonizan con [symmetricChords].
List<int>? harmonizationSource(List<int> scale) {
  final s = _normalized(scale);
  if (s.length == 7) return s;
  if (s.length > 7) return null;
  final c = compareScale(s);
  if (c == null) return null;
  if (c.added.isEmpty) return c.referenceIntervals;
  // Blues: pentatónica menor + b5 -> la menor natural.
  if (c.referenceIntervals.join(',') == _minorPentatonic.join(',')) {
    return naturalMinorScale;
  }
  return null;
}

/// Acordes propios de una escala simétrica (semitonos sobre la tónica y
/// tipo): tonos enteros -> tríadas aumentadas en cada nota; disminuida
/// semitono-tono -> acordes 7 a distancia de 3 trastes (0, 3, 6, 9);
/// tono-semitono -> los dos dim7 que contiene (sobre 1 y 2).
List<({int semitones, String type})> symmetricChords(List<int> scale) {
  final s = _normalized(scale);
  if (s.length == 6 && symmetryPeriod(s) == 2) {
    return [for (final i in s) (semitones: i, type: 'augmented')];
  }
  if (s.length == 8) {
    return s[1] == 1
        ? [for (final i in [0, 3, 6, 9]) (semitones: i, type: 'dominant7')]
        : [(semitones: 0, type: 'diminished7'), (semitones: 2, type: 'diminished7')];
  }
  return const [];
}

/// Ideas para improvisar con cada escala (texto curado, no datos de trastes).
class ImprovisationTip {
  const ImprovisationTip({required this.style, required this.idea});

  /// Dónde suena (estilos, contexto armónico).
  final LocalizedText style;

  /// Un consejo práctico concreto.
  final LocalizedText idea;
}

ImprovisationTip? improvisationTips(String scaleId, List<int> scale) {
  // Las disminuidas se distinguen por sus intervalos, no por el id.
  final s = _normalized(scale);
  if (s.length == 8) {
    return s[1] == 1
        ? const ImprovisationTip(
            style: LocalizedText(
              es: 'Jazz y fusión, sobre acordes dominantes (7) con tensiones alteradas.',
              en: 'Jazz and fusion, over dominant (7) chords with altered tensions.',
            ),
            idea: LocalizedText(
              es: 'Empieza por semitono: contiene b9, #9, 3, #11, 5, 13 y b7 del acorde 7. Sube el mismo lick 3 trastes y sigue en la escala.',
              en: 'It starts with a half step: it holds the b9, #9, 3, #11, 5, 13 and b7 of a 7 chord. Move a lick up 3 frets and you stay in the scale.',
            ),
          )
        : const ImprovisationTip(
            style: LocalizedText(
              es: 'Sobre acordes disminuidos 7 (dim7), en jazz y música de cine.',
              en: 'Over diminished 7 (dim7) chords, in jazz and film music.',
            ),
            idea: LocalizedText(
              es: 'Empieza por tono: las cuatro notas del dim7 más una nota de paso entre cada una. Se repite cada 3 trastes.',
              en: 'It starts with a whole step: the four notes of the dim7 plus a passing note between each. It repeats every 3 frets.',
            ),
          );
  }
  return switch (scaleId) {
    'pentatonic_dorian' => const ImprovisationTip(
      style: LocalizedText(
        es: 'Funk, rock latino y jazz modal, sobre un vamp dórico (i–IV).',
        en: 'Funk, Latin rock and modal jazz, over a Dorian vamp (i–IV).',
      ),
      idea: LocalizedText(
        es: 'Es la pentatónica menor con la 6 en lugar de la b7: esa 6 es la nota del dórico; apóyala sobre el IV mayor.',
        en: 'It is the minor pentatonic with the 6 instead of the b7: that 6 is the Dorian note; lean on it over the major IV.',
      ),
    ),
    'pentatonic_phrygian' => const ImprovisationTip(
      style: LocalizedText(
        es: 'Metal y rock oscuro, sobre un vamp frigio (i–♭II).',
        en: 'Metal and dark rock, over a Phrygian vamp (i–♭II).',
      ),
      idea: LocalizedText(
        es: 'Es la pentatónica menor con la b2 en lugar de la b7: la b2, medio tono sobre la tónica, es el color frigio.',
        en: 'It is the minor pentatonic with the b2 instead of the b7: the b2, a half step above the tonic, is the Phrygian color.',
      ),
    ),
    'pentatonic_lydian' => const ImprovisationTip(
      style: LocalizedText(
        es: 'Música de cine y fusión, sobre un vamp lidio (I–II).',
        en: 'Film music and fusion, over a Lydian vamp (I–II).',
      ),
      idea: LocalizedText(
        es: 'Es la pentatónica mayor con la #4 en lugar de la 6: apoya la #4 sobre el II mayor, que la tiene de 3ª.',
        en: 'It is the major pentatonic with the #4 instead of the 6: lean on the #4 over the major II, which has it as its 3rd.',
      ),
    ),
    'pentatonic_mixolydian' => const ImprovisationTip(
      style: LocalizedText(
        es: 'Rock clásico, blues-rock y country, sobre un vamp I–♭VII o un acorde 7.',
        en: 'Classic rock, blues-rock and country, over a I–♭VII vamp or a 7 chord.',
      ),
      idea: LocalizedText(
        es: 'Es la pentatónica mayor con la b7 en lugar de la 6: 1 2 3 5 b7, las notas del acorde 7 más la 2.',
        en: 'It is the major pentatonic with the b7 instead of the 6: 1 2 3 5 b7, the notes of the 7 chord plus the 2.',
      ),
    ),
    'major' || 'ionian' => const ImprovisationTip(
      style: LocalizedText(
        es: 'Pop, folk, country y melodías cantables sobre acordes mayores.',
        en: 'Pop, folk, country and singable melodies over major chords.',
      ),
      idea: LocalizedText(
        es: 'Cae en las notas del acorde (1, 3, 5) en los tiempos fuertes; la 4 suena tensa sobre el I, úsala de paso hacia la 3.',
        en: 'Land on chord tones (1, 3, 5) on strong beats; the 4 clashes over the I, use it as a passing note into the 3.',
      ),
    ),
    'natural_minor' || 'aeolian' => const ImprovisationTip(
      style: LocalizedText(
        es: 'Rock, metal y baladas en tonalidad menor.',
        en: 'Rock, metal and ballads in a minor key.',
      ),
      idea: LocalizedText(
        es: 'Es la pentatónica menor + la 2 y la b6: añade esas dos notas a tus frases pentatónicas para que suenen más melódicas y oscuras.',
        en: 'It is the minor pentatonic + the 2 and b6: add those two notes to your pentatonic phrases for a darker, more melodic sound.',
      ),
    ),
    'pentatonic_minor' => const ImprovisationTip(
      style: LocalizedText(
        es: 'Rock y blues. En blues se toca también sobre acordes 7: el choque de su b3 con la 3 del acorde es el sonido blues.',
        en: 'Rock and blues. In blues it is also played over 7 chords: its b3 rubbing against the chord\'s 3 is the blues sound.',
      ),
      idea: LocalizedText(
        es: 'Sin semitonos entre sus notas, ninguna choca fuerte: la escala más segura para empezar. Prueba un bend de la 4 a la 5.',
        en: 'With no half steps between its notes, nothing clashes hard: the safest scale to start with. Try bending the 4 up to the 5.',
      ),
    ),
    'pentatonic_major' => const ImprovisationTip(
      style: LocalizedText(
        es: 'Country, pop y rock sureño sobre acordes mayores.',
        en: 'Country, pop and southern rock over major chords.',
      ),
      idea: LocalizedText(
        es: 'Es la mayor sin 4 ni 7 (las notas que chocan): suena alegre y abierta. Tiene las mismas notas que la pentatónica menor de su relativo (C mayor = A menor).',
        en: 'It is the major scale without the 4 and 7 (the clashing notes): bright and open. Same notes as the minor pentatonic of its relative (C major = A minor).',
      ),
    ),
    'blues_minor' => const ImprovisationTip(
      style: LocalizedText(
        es: 'Blues, rock y jazz sobre la progresión de blues (I7, IV7, V7).',
        en: 'Blues, rock and jazz over the blues progression (I7, IV7, V7).',
      ),
      idea: LocalizedText(
        es: 'La b5 (blue note) es de paso: pásala entre la 4 y la 5 y no te quedes en ella.',
        en: 'The b5 (blue note) is a passing note: slide through it between the 4 and 5, do not rest on it.',
      ),
    ),
    'harmonic_minor' => const ImprovisationTip(
      style: LocalizedText(
        es: 'Neoclásico, metal, flamenco y tango, sobre el V7 de una tonalidad menor.',
        en: 'Neoclassical, metal, flamenco and tango, over the V7 of a minor key.',
      ),
      idea: LocalizedText(
        es: 'Su 7 natural (sensible) sube medio tono a la tónica; el salto b6 → 7 (tono y medio) es su sonido "exótico".',
        en: 'Its natural 7 (leading tone) rises a half step to the tonic; the b6 → 7 leap (a step and a half) is its "exotic" sound.',
      ),
    ),
    'melodic_minor' => const ImprovisationTip(
      style: LocalizedText(
        es: 'Jazz: sobre acordes menores con 7 mayor (m(maj7)) y como fuente de sonidos alterados.',
        en: 'Jazz: over minor chords with a major 7 (m(maj7)) and as a source of altered sounds.',
      ),
      idea: LocalizedText(
        es: 'Es la mayor con b3: piensa en una escala mayor y baja solo la 3.',
        en: 'It is the major scale with a b3: think major and lower only the 3.',
      ),
    ),
    'whole_tone' => const ImprovisationTip(
      style: LocalizedText(
        es: 'Sobre acordes aumentados y 7(#5); sonido de sueño o suspenso (Debussy, jazz).',
        en: 'Over augmented and 7(#5) chords; a dreamy, suspended sound (Debussy, jazz).',
      ),
      idea: LocalizedText(
        es: 'Todo son tonos enteros: no hay tónica clara. Úsala en momentos breves y resuelve a una escala normal.',
        en: 'All whole steps: there is no clear home. Use it briefly and resolve to a regular scale.',
      ),
    ),
    'hungarian_minor' => const ImprovisationTip(
      style: LocalizedText(
        es: 'Música de Europa del Este, metal y bandas sonoras.',
        en: 'Eastern European music, metal and soundtracks.',
      ),
      idea: LocalizedText(
        es: 'Tiene dos saltos de tono y medio (b3 → #4 y b6 → 7): recórrelos despacio, son su carácter.',
        en: 'It has two step-and-a-half leaps (b3 → #4 and b6 → 7): play them slowly, they are its character.',
      ),
    ),
    'phrygian_dominant' => const ImprovisationTip(
      style: LocalizedText(
        es: 'Flamenco, música árabe y metal, sobre un acorde mayor o 7 de tónica.',
        en: 'Flamenco, Middle Eastern music and metal, over a major or 7 tonic chord.',
      ),
      idea: LocalizedText(
        es: 'Es el 5º modo de la menor armónica: la b2 cayendo a la tónica es el gesto flamenco.',
        en: 'It is the 5th mode of harmonic minor: the b2 falling to the tonic is the flamenco gesture.',
      ),
    ),
    'dorian' => const ImprovisationTip(
      style: LocalizedText(
        es: 'Funk, jazz, rock latino (Santana) sobre acordes m7 que se quedan.',
        en: 'Funk, jazz, Latin rock (Santana) over m7 chords that stay put.',
      ),
      idea: LocalizedText(
        es: 'Es la menor natural con 6 mayor: toca pentatónica menor y añade la 6 para el color dórico.',
        en: 'It is natural minor with a major 6: play minor pentatonic and add the 6 for the Dorian color.',
      ),
    ),
    'phrygian' => const ImprovisationTip(
      style: LocalizedText(
        es: 'Metal y flamenco sobre acordes menores.',
        en: 'Metal and flamenco over minor chords.',
      ),
      idea: LocalizedText(
        es: 'La b2 a medio tono de la tónica da la tensión: alterna b2 y 1 sobre una cuerda al aire grave.',
        en: 'The b2 a half step above the tonic gives the tension: alternate b2 and 1 over a low open string.',
      ),
    ),
    'lydian' => const ImprovisationTip(
      style: LocalizedText(
        es: 'Bandas sonoras, rock instrumental (Satriani, Vai) sobre acordes maj7.',
        en: 'Soundtracks, instrumental rock (Satriani, Vai) over maj7 chords.',
      ),
      idea: LocalizedText(
        es: 'Es la mayor con #4: esa nota quita la tensión de la 4 y suena luminosa. Apóyate en ella.',
        en: 'It is the major scale with a #4: that note removes the 4\'s clash and sounds bright. Lean on it.',
      ),
    ),
    'mixolydian' => const ImprovisationTip(
      style: LocalizedText(
        es: 'Blues-rock, country y funk sobre acordes 7 (dominantes).',
        en: 'Blues-rock, country and funk over 7 (dominant) chords.',
      ),
      idea: LocalizedText(
        es: 'Es la mayor con b7, igual que el acorde 7: apunta a la 3 y a la b7, que definen el acorde.',
        en: 'It is the major scale with a b7, just like the 7 chord: target the 3 and b7, which define the chord.',
      ),
    ),
    'locrian' => const ImprovisationTip(
      style: LocalizedText(
        es: 'Sobre el acorde m7(b5) (semidisminuido), en jazz y metal.',
        en: 'Over the m7(b5) (half-diminished) chord, in jazz and metal.',
      ),
      idea: LocalizedText(
        es: 'Con b5, su tónica no es estable: úsala sobre el acorde m7(b5) y resuelve a otro acorde.',
        en: 'With a b5 its tonic is unstable: use it over the m7(b5) chord and resolve elsewhere.',
      ),
    ),
    _ => null,
  };
}
