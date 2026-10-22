import '../../core/i18n/tr.dart';
import '../progressions/progression_data.dart';
import 'notes.dart';

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
  _ => throw ArgumentError.value(numeral, 'numeral'),
};

/// Notas (pitch classes) de la tríada del grado en la tonalidad [tonic].
Set<int> degreeTriad(ProgressionDegree d, int tonic) {
  final root = (tonic + d.semitones) % 12;
  final third = d.type == 'major' ? 4 : 3;
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
  ('V', 'I') || ('vii°', 'I') => const LocalizedText(
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

  String path(AppLanguage lang) => degrees
      .map((d) {
        final name = harmonicFunctionName(harmonicFunction(d.numeral));
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

  if (degrees.last.numeral == 'V') {
    out.add(const LocalizedText(
      es: 'Termina en V (semicadencia): queda en suspenso y empuja a empezar de nuevo.',
      en: 'It ends on V (half cadence): it hangs in suspense and pushes you to start again.',
    ));
  }

  for (var i = 0; i + 1 < degrees.length; i++) {
    final a = degrees[i];
    final b = degrees[i + 1];
    if (a.numeral == b.numeral) continue;
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
