/// Nombre de intervalos dentro de una escala (`1`, `b3`, `#4`, `b6`...).
library;

const _majorScale = [0, 2, 4, 5, 7, 9, 11];

/// Nombres por defecto, sin contexto de escala (acordes, pentatónicas,
/// escalas simétricas): 8 semitonos = `#5`, como en el acorde aumentado.
const _defaultNames = {
  0: '1',
  1: 'b2',
  2: '2',
  3: 'b3',
  4: '3',
  5: '4',
  6: 'b5',
  7: '5',
  8: '#5',
  9: '6',
  10: 'b7',
  11: '7',
};

/// Etiqueta de [semitones] sobre la tónica dentro de la escala [scale].
///
/// En una escala de 7 notas cada grado usa una letra distinta, así que la
/// nota se nombra por su número de grado y la alteración respecto a la
/// escala mayor: en la menor natural, 8 semitonos es el 6º grado → `b6`
/// (no `#5`); en la lidia, 6 semitonos es el 4º → `#4`; en la locria, el
/// 5º → `b5`. Fuera de escalas de 7 notas se usan los nombres por defecto.
String spellInterval(int semitones, [List<int> scale = const []]) {
  final s = semitones % 12;
  final degrees = {for (final i in scale) i % 12}.toList()..sort();
  if (degrees.length == 7 && degrees.contains(s)) {
    final degree = degrees.indexOf(s);
    final diff = s - _majorScale[degree];
    final accidental = diff < 0 ? 'b' * -diff : '#' * diff;
    return '$accidental${degree + 1}';
  }
  return _defaultNames[s]!;
}

/// Etiquetas de todas las notas de [scale], en orden.
List<String> scaleDegreeLabels(List<int> scale) =>
    [for (final i in scale) spellInterval(i, scale)];
