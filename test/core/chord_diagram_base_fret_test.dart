import 'package:chordmaster_free/core/widgets/chord_diagram.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('diagramBaseFret', () {
    test('G con cuerdas al aire: base 1', () {
      expect(diagramBaseFret([3, 2, 0, 0, 0, 3]), 1);
    });

    test('A con cuerdas al aire: base 1', () {
      expect(diagramBaseFret([-1, 0, 2, 2, 2, 0]), 1);
    });

    test('B sin cuerdas al aire: base 2', () {
      expect(diagramBaseFret([-1, 2, 4, 4, 4, 2]), 2);
    });

    test('C# menor: base 4', () {
      expect(diagramBaseFret([-1, 4, 6, 6, 5, -1]), 4);
    });

    test('cuerda al aire pero trastes altos: se mantiene la detección', () {
      expect(diagramBaseFret([0, 7, 9, 9, 8, 7]), 7);
    });
  });
}
