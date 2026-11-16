/// Los acordes que ofrece "Mi progresión": los de cada grado de una escala de
/// base (la mayor o uno de sus modos), en tríada o con su 7ª, por regla
/// (`diatonicTriads`). Se guardan como número romano (`ii7`, `♭VIImaj7`), que
/// `parseDegreeNumeral` vuelve a leer: los de antes (`I`, `vi`) siguen valiendo.
library;

import '../theory/harmony.dart';
import '../theory/scale_insights.dart';
import 'progression_data.dart';

/// Escalas de base de "Mi progresión": las rotaciones de la mayor, en el
/// orden de [modeScaleIds] (0 = mayor, 5 = menor natural).
const customBaseModes = [0, 1, 2, 3, 4, 5, 6];

/// La escala de base por defecto: la mayor.
const customDefaultMode = 0;

/// Acordes de cada grado de la escala de base [mode] (rotación de la mayor),
/// del I al VII: tríadas o, con [sevenths], cuatríadas (1-3-5-7 con notas de la
/// escala).
List<ProgressionDegree> customChordChoices(int mode, {bool sevenths = false}) => [
  for (final c in diatonicTriads(modeIntervals(mode)))
    () {
      final numeral = _withSeventh(_glyphs(c.numeral), sevenths ? c.seventhType : null);
      final parsed = parseDegreeNumeral(numeral)!;
      return ProgressionDegree(numeral, parsed.semitones, parsed.type);
    }(),
];

/// Si [numeral] se puede poner en "Mi progresión" (un grado bien escrito).
bool isCustomNumeral(String numeral) => parseDegreeNumeral(numeral) != null;

/// `b`/`#` de `spellInterval` con los signos de las progresiones (♭, ♯).
String _glyphs(String numeral) => numeral.replaceAll('b', '♭').replaceAll('#', '♯');

String _withSeventh(String triad, String? seventhType) => switch (seventhType) {
  null => triad,
  'major7' => '${triad}maj7',
  'dominant7' || 'minor7' => '${triad}7',
  'halfDiminished' => triad.replaceFirst('°', 'ø7'),
  'diminished7' => triad.replaceFirst('°', '°7'),
  _ => throw StateError('$triad: sin 7ª en los datos ($seventhType)'),
};
