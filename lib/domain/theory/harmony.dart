import '../../core/i18n/tr.dart';
import '../progressions/progression_data.dart';
import 'intervals.dart';
import 'notes.dart';
import 'scale_insights.dart';

/// Función armónica de un grado de la tonalidad mayor.
///
/// Armonía funcional clásica: I, iii y vi dan reposo (tónica); ii y IV
/// preparan (subdominante); V y vii° crean la tensión que pide volver al I
/// (dominante; los dos contienen la sensible, la 7ª de la escala).
enum HarmonicFunction { tonic, subdominant, dominant }

const _functionByNumeral = {
  'I': HarmonicFunction.tonic,
  'ii': HarmonicFunction.subdominant,
  'iii': HarmonicFunction.tonic,
  'IV': HarmonicFunction.subdominant,
  'V': HarmonicFunction.dominant,
  'vi': HarmonicFunction.tonic,
  'vii°': HarmonicFunction.dominant,
};

HarmonicFunction harmonicFunction(String numeral) => _functionByNumeral[numeral]!;

/// Función de los grados de fuera de la mayor que la tienen clara: el I7 y la
/// i son el reposo, el IV7 y la iv preparan, el V7 y la v tensan. Los demás
/// (♭VII, ♭VI, ♭III, ♭II, II, i°) no tienen una sola función: dependen del
/// estilo, así que no se les pone etiqueta.
const _otherFunctions = {
  'I7': HarmonicFunction.tonic,
  'i': HarmonicFunction.tonic,
  'i7': HarmonicFunction.tonic,
  'IV7': HarmonicFunction.subdominant,
  'iv': HarmonicFunction.subdominant,
  'iv7': HarmonicFunction.subdominant,
  'V7': HarmonicFunction.dominant,
  'v': HarmonicFunction.dominant,
};

/// La función de [numeral], o `null` si no tiene una sola.
HarmonicFunction? functionOf(String numeral) => _functionByNumeral[numeral] ?? _otherFunctions[numeral];

LocalizedText harmonicFunctionName(HarmonicFunction f) => switch (f) {
  HarmonicFunction.tonic => const LocalizedText(es: 'reposo', en: 'rest'),
  HarmonicFunction.subdominant => const LocalizedText(
    es: 'preparación',
    en: 'build-up',
  ),
  HarmonicFunction.dominant => const LocalizedText(es: 'tensión', en: 'tension'),
};

/// Qué aporta cada grado, en una frase.
LocalizedText degreeRole(String numeral) => switch (numeral) {
  'I' => const LocalizedText(
    es: 'I: la tónica, el "hogar" de la tonalidad. Todo tiende a volver aquí.',
    en: 'I: the tonic, the "home" of the key. Everything wants to return here.',
  ),
  'ii' => const LocalizedText(
    es: 'ii: menor, prepara el V. El paso ii → V → I es la base del jazz.',
    en: 'ii: minor, it sets up the V. The ii → V → I move is the backbone of jazz.',
  ),
  'iii' => const LocalizedText(
    es: 'iii: menor, comparte dos notas con el I; prolonga el reposo con otro color.',
    en: 'iii: minor, it shares two notes with I; it extends the rest with a new color.',
  ),
  'IV' => const LocalizedText(
    es: 'IV: mayor, se aleja del hogar sin tensión fuerte; abre la frase.',
    en: 'IV: major, it moves away from home without strong tension; it opens the phrase.',
  ),
  'V' => const LocalizedText(
    es: 'V: mayor, contiene la sensible (7ª de la escala), que quiere subir medio tono a la tónica.',
    en: 'V: major, it contains the leading tone (7th of the scale), which wants to rise a half step to the tonic.',
  ),
  'vi' => const LocalizedText(
    es: 'vi: el relativo menor; comparte dos notas con el I, por eso suena a reposo triste.',
    en: 'vi: the relative minor; it shares two notes with I, so it sounds like a sad rest.',
  ),
  'vii°' => const LocalizedText(
    es: 'vii°: disminuido, es un V7 sin raíz; tensión máxima hacia el I.',
    en: 'vii°: diminished, it is a V7 without its root; maximum pull toward I.',
  ),
  'I7' => const LocalizedText(
    es: 'I7: la tónica con 7ª menor. En el blues hasta el reposo lleva esa tensión.',
    en: 'I7: the tonic with a minor 7th. In the blues even the rest carries that tension.',
  ),
  'IV7' => const LocalizedText(
    es: 'IV7: el IV con 7ª menor; en el blues abre la segunda frase, en el compás 5.',
    en: 'IV7: the IV with a minor 7th; in the blues it opens the second phrase, in bar 5.',
  ),
  'V7' => const LocalizedText(
    es: 'V7: el V con 7ª menor, que es la 4ª de la escala: con la sensible pide volver a la tónica.',
    en: 'V7: the V with a minor 7th, the 4th of the scale: with the leading tone it pulls back to the tonic.',
  ),
  'i' || 'i7' => LocalizedText(
    es: '$numeral: la tónica menor, el hogar de una tonalidad menor.',
    en: '$numeral: the minor tonic, the home of a minor key.',
  ),
  'iv' || 'iv7' => LocalizedText(
    es: '$numeral: menor, prepara como el IV pero con la 3ª menor, más oscuro.',
    en: '$numeral: minor, it builds up like the IV but with a minor 3rd, darker.',
  ),
  'v' => const LocalizedText(
    es: 'v: menor, sin sensible (su 3ª queda un tono debajo de la tónica): empuja menos que el V7.',
    en: 'v: minor, with no leading tone (its 3rd sits a whole step below the tonic): it pulls less than V7.',
  ),
  '♭III' => const LocalizedText(
    es: '♭III: mayor, a tres semitonos de la tónica: es la tónica de la relativa mayor.',
    en: '♭III: major, three half steps above the tonic: it is the tonic of the relative major.',
  ),
  '♭VI' => const LocalizedText(
    es: '♭VI: mayor, sobre la 6ª menor de la escala.',
    en: '♭VI: major, built on the minor 6th of the scale.',
  ),
  '♭VII' => const LocalizedText(
    es: '♭VII: mayor, un tono debajo de la tónica: va hacia ella sin sensible, en lugar del V.',
    en: '♭VII: major, a whole step below the tonic: it leads home without a leading tone, instead of the V.',
  ),
  '♭II' => const LocalizedText(
    es: '♭II: mayor, medio tono sobre la tónica: trae la 2ª menor del frigio y del locrio.',
    en: '♭II: major, a half step above the tonic: it brings the minor 2nd of Phrygian and Locrian.',
  ),
  'II' => const LocalizedText(
    es: 'II: mayor sobre la 2ª: su 3ª es la #4 del lidio.',
    en: 'II: major on the 2nd: its 3rd is the #4 of Lydian.',
  ),
  'i°' => const LocalizedText(
    es: 'i°: disminuido sobre la tónica: su 5ª es la b5 del locrio.',
    en: 'i°: diminished on the tonic: its 5th is the b5 of Locrian.',
  ),
  _ => throw ArgumentError.value(numeral, 'numeral'),
};

/// Notas (pitch classes) de la tríada del grado en la tonalidad [tonic].
Set<int> degreeTriad(ProgressionDegree d, int tonic) {
  final root = (tonic + d.semitones) % 12;
  final third = d.type == 'major' || d.type == 'dominant7' ? 4 : 3;
  final fifth = d.type == 'diminished' ? 6 : 7;
  return {root, (root + third) % 12, (root + fifth) % 12};
}

/// Nombres (con sostenidos) de las notas que comparten dos grados seguidos.
List<String> commonTones(ProgressionDegree a, ProgressionDegree b, int tonic) {
  final shared = degreeTriad(a, tonic).intersection(degreeTriad(b, tonic));
  return [for (final pc in shared.toList()..sort()) noteNames[pc]];
}

/// Cadencia (cierre) entre dos grados seguidos, si la hay.
LocalizedText? cadence(String from, String to) => switch ((from, to)) {
  ('V', 'I') || ('vii°', 'I') || ('V7', 'I7') || ('V7', 'i') || ('V7', 'i7') => const LocalizedText(
    es: 'cadencia auténtica: la tensión se resuelve en el hogar, el cierre más fuerte',
    en: 'authentic cadence: tension resolves home, the strongest ending',
  ),
  ('IV', 'I') => const LocalizedText(
    es: 'cadencia plagal: cierre suave, el "amén" de los himnos',
    en: 'plagal cadence: a soft ending, the "amen" of hymns',
  ),
  ('V', 'vi') => const LocalizedText(
    es: 'cadencia rota: el oído espera el I y llega su relativo menor',
    en: 'deceptive cadence: the ear expects I and gets its relative minor',
  ),
  _ => null,
};

/// Explicación de una progresión generada por reglas: el recorrido de
/// funciones, las cadencias (también la de vuelta al inicio, porque las
/// progresiones se tocan en bucle) y qué notas une cada cambio.
List<LocalizedText> explainProgression(Progression p, int tonic) {
  final degrees = p.degrees;
  if (degrees.isEmpty) return const [];
  final out = <LocalizedText>[];

  // Un grado repetido en compases seguidos (el blues) se nombra una vez.
  final steps = [
    for (final (i, d) in degrees.indexed)
      if (i == 0 || degrees[i - 1].numeral != d.numeral) d,
  ];
  String path(AppLanguage lang) => steps
      .map((d) {
        final f = functionOf(d.numeral);
        if (f == null) return d.numeral;
        final name = harmonicFunctionName(f);
        return '${d.numeral} (${lang == AppLanguage.es ? name.es : name.en})';
      })
      .join(' → ');
  out.add(LocalizedText(
    es: 'Recorrido: ${path(AppLanguage.es)}.',
    en: 'Journey: ${path(AppLanguage.en)}.',
  ));

  final pairs = [
    for (var i = 0; i + 1 < degrees.length; i++) (degrees[i], degrees[i + 1]),
    if (degrees.length > 1) (degrees.last, degrees.first),
  ];
  final seenCadences = <String>{};
  for (final (a, b) in pairs) {
    final c = cadence(a.numeral, b.numeral);
    if (c == null || !seenCadences.add('${a.numeral}-${b.numeral}')) continue;
    final loop = identical(a, degrees.last) && identical(b, degrees.first);
    out.add(LocalizedText(
      es: '${a.numeral} → ${b.numeral}${loop ? ' (al repetir)' : ''}: ${c.es}.',
      en: '${a.numeral} → ${b.numeral}${loop ? ' (on repeat)' : ''}: ${c.en}.',
    ));
  }

  if (p.kind == ProgressionKind.blues) out.addAll(_bluesLines(p));
  if (p.mode != null) out.add(_modeLine(p, tonic));

  if (degrees.last.numeral == 'V' && p.kind != ProgressionKind.blues) {
    out.add(const LocalizedText(
      es: 'Termina en V (semicadencia): queda en suspenso y empuja a empezar de nuevo.',
      en: 'It ends on V (half cadence): it hangs in suspense and pushes you to start again.',
    ));
  }

  final seenPairs = <String>{};
  for (var i = 0; i + 1 < degrees.length; i++) {
    final a = degrees[i];
    final b = degrees[i + 1];
    if (a.numeral == b.numeral || !seenPairs.add('${a.numeral}-${b.numeral}')) continue;
    final shared = commonTones(a, b, tonic);
    if (shared.isEmpty) continue;
    final notes = shared.join(', ');
    out.add(LocalizedText(
      es: '${a.numeral} → ${b.numeral}: ${shared.length == 1 ? 'comparten la nota' : 'comparten las notas'} $notes; por eso el cambio suena unido.',
      en: '${a.numeral} → ${b.numeral}: ${shared.length == 1 ? 'they share' : 'they share the notes'} $notes, which is why the change sounds connected.',
    ));
  }
  return out;
}

/// "1–4, 7–8 y 11": compases (desde 1) seguidos juntados en tramos.
LocalizedText barList(List<int> bars) {
  final runs = <String>[];
  var i = 0;
  while (i < bars.length) {
    var j = i;
    while (j + 1 < bars.length && bars[j + 1] == bars[j] + 1) {
      j++;
    }
    runs.add(i == j ? '${bars[i]}' : '${bars[i]}–${bars[j]}');
    i = j + 1;
  }
  String join(String and) =>
      runs.length == 1 ? runs.single : '${runs.sublist(0, runs.length - 1).join(', ')} $and ${runs.last}';
  return LocalizedText(es: join('y'), en: join('and'));
}

/// El blues de 12 compases: en qué compases va cada grado y, si el último es
/// el V7, que es la vuelta (turnaround).
List<LocalizedText> _bluesLines(Progression p) {
  final bars = <String, List<int>>{};
  for (final (i, d) in p.degrees.indexed) {
    (bars[d.numeral] ??= []).add(i + 1);
  }
  String where(AppLanguage lang) => [
    for (final e in bars.entries)
      '${e.key} ${lang == AppLanguage.es ? 'en' : 'in'} ${lang == AppLanguage.es ? barList(e.value).es : barList(e.value).en}',
  ].join('; ');
  final out = [
    LocalizedText(
      es: 'Los ${p.degrees.length} compases, uno por acorde: ${where(AppLanguage.es)}.',
      en: 'The ${p.degrees.length} bars, one chord each: ${where(AppLanguage.en)}.',
    ),
  ];
  if (p.degrees.length > 1 && p.degrees[1].numeral != p.degrees.first.numeral) {
    out.add(LocalizedText(
      es: 'Cambio rápido: el ${p.degrees[1].numeral} ya llega en el compás 2 y vuelve el ${p.degrees.first.numeral}.',
      en: 'Quick change: the ${p.degrees[1].numeral} already comes in bar 2 and the ${p.degrees.first.numeral} returns.',
    ));
  }
  if (p.degrees.last.numeral == 'V7') {
    out.add(LocalizedText(
      es: 'El V7 del compás ${p.degrees.length} es la vuelta (turnaround): empuja a empezar otra vez.',
      en: 'The V7 in bar ${p.degrees.length} is the turnaround: it pushes you to start again.',
    ));
  }
  if (p.feel == ProgressionFeel.triplet) {
    out.add(const LocalizedText(
      es: 'En 12/8: cada pulso se divide en tres, como un tresillo; así suena el blues lento.',
      en: 'In 12/8: each beat splits in three, like a triplet; that is the slow blues feel.',
    ));
  }
  return out;
}

/// La escala mayor rotada [rotation] grados: el modo (1 = dórico … 6 = locrio).
List<int> modeIntervals(int rotation) {
  final start = majorScale[rotation];
  return [for (var i = 0; i < 7; i++) (majorScale[(rotation + i) % 7] - start) % 12];
}

/// Las notas que distinguen al modo de [p] (frente a la mayor o la menor
/// natural, `compareScale`) y el primer grado del vamp donde suena cada una.
List<({int semitones, String numeral})> modeColorTones(Progression p) {
  final added = compareScale(modeIntervals(p.mode!))?.added ?? const <int>[];
  return [
    for (final n in added)
      if (p.degrees.where((d) => degreeChordTones(d).contains(n)).firstOrNull case final d?)
        (semitones: n, numeral: d.numeral),
  ];
}

/// Semitonos desde la tónica de las notas del acorde del grado [d] (tríada o
/// cuatríada, según su tipo).
Set<int> degreeChordTones(ProgressionDegree d) => {
  for (final i in degreeChordIntervals(d.type)) (d.semitones + i) % 12,
};

/// Intervalos desde la raíz de un acorde de [type] (los tipos de las
/// progresiones).
List<int> degreeChordIntervals(String type) => switch (type) {
  'major' => const [0, 4, 7],
  'minor' => const [0, 3, 7],
  'diminished' => const [0, 3, 6],
  'dominant7' => const [0, 4, 7, 10],
  'minor7' => const [0, 3, 7, 10],
  _ => throw ArgumentError.value(type, 'type'),
};

LocalizedText _modeLine(Progression p, int tonic) {
  final scale = modeIntervals(p.mode!);
  String tones(AppLanguage lang) => [
    for (final t in modeColorTones(p))
      '${lang == AppLanguage.es ? 'el grado' : 'degree'} ${spellInterval(t.semitones, scale)} (${pitchClassName(tonic + t.semitones)}) ${lang == AppLanguage.es ? 'en el' : 'in the'} ${t.numeral}',
  ].join(lang == AppLanguage.es ? ' y ' : ' and ');
  return LocalizedText(
    es: 'El vamp hace oír lo que distingue al modo: ${tones(AppLanguage.es)}.',
    en: 'The vamp makes you hear what sets the mode apart: ${tones(AppLanguage.en)}.',
  );
}
