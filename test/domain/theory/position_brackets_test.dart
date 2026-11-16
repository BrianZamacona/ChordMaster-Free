import 'package:chordmaster_free/domain/theory/position_brackets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Las cinco formas CAGED de C mayor (trastes de scales_master.json).
  const caged = [(start: 0, end: 4), (start: 3, end: 7), (start: 5, end: 9), (start: 8, end: 12), (start: 10, end: 14)];

  test('cada forma en todas las octavas donde cabe entera, sin recortar', () {
    final b = positionBrackets(caged);
    // C (0–4) cabe en el 0, el 12 y... el 24 no: 24–28 se sale.
    expect([for (final x in b) if (x.index == 0) (x.start, x.end)], [(0, 4), (12, 16)]);
    // D (10–14) también una octava arriba (22–26 no cabe) y abajo no (−2).
    expect([for (final x in b) if (x.index == 4) (x.start, x.end)], [(10, 14)]);
    for (final x in b) {
      expect(x.start, greaterThanOrEqualTo(0));
      expect(x.end, lessThanOrEqualTo(24));
      expect(x.end - x.start, caged[x.index].end - caged[x.index].start);
    }
  });

  test('dos llaves de la misma fila nunca se tocan, ni en un traste', () {
    final b = positionBrackets(caged);
    for (final x in b) {
      for (final y in b) {
        if (identical(x, y) || x.row != y.row) continue;
        expect(x.end < y.start || y.end < x.start, isTrue, reason: '$x $y');
      }
    }
    // Las CAGED se enciman de a tres como mucho.
    expect(bracketRows(b), 3);
  });

  test('ordenadas por traste y en la primera fila libre', () {
    final b = positionBrackets(const [(start: 1, end: 4), (start: 5, end: 8), (start: 3, end: 6)]);
    expect([for (final x in b) (x.index, x.start, x.row)], [(0, 1, 0), (2, 3, 1), (1, 5, 0), (0, 13, 0), (2, 15, 1), (1, 17, 0)]);
    expect(bracketRows(b), 2);
    expect(bracketRows(const []), 0);
  });
}
