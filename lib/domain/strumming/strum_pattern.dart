/// Patrones de rasgueo de un compás: una letra por corchea, `D` = abajo,
/// `U` = arriba, espacio = la mano pasa sin tocar; en minúscula (`d`, `u`), el
/// golpe va apagado (la mano izquierda apoya sin pisar: solo se oye el
/// "chas"). 8 corcheas = 4/4; 6 = 6/8.
library;

/// Conteo de la corchea [index] de [pattern]: un compás de 6 corcheas es 6/8 y
/// se cuenta de 1 a 6; uno de 8 es 4/4 y se cuenta "1 [and] 2 [and]…".
String strumCountAt(String pattern, int index, String and) {
  if (pattern.length == 6) return '${index + 1}';
  return index.isEven ? '${index ~/ 2 + 1}' : and;
}

/// Golpes que suenan en un compás de [pattern].
int strokeCount(String pattern) => pattern.replaceAll(' ', '').length;

/// Corcheas de [pattern] con golpe [stroke] (`D` o `U`), apagado o no.
List<int> strokesAt(String pattern, String stroke) => [
  for (var i = 0; i < pattern.length; i++)
    if (pattern[i].toUpperCase() == stroke) i,
];

/// El golpe va apagado (`d` o `u`).
bool isMutedStroke(String stroke) => stroke == 'd' || stroke == 'u';

/// Un patrón de 4/4 es "de péndulo" si cada golpe va en su lugar natural: abajo
/// en los números y arriba en las "y". Así la mano nunca cambia de sentido a
/// destiempo.
bool followsPendulum(String pattern) => [
  for (var i = 0; i < pattern.length; i++)
    pattern[i] == ' ' || pattern[i].toUpperCase() == (i.isEven ? 'D' : 'U'),
].every((ok) => ok);
