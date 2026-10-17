import 'package:chordmaster_free/features/chords/chord_explorer_screen.dart';
import 'package:chordmaster_free/models/chord.dart';
import 'package:flutter_test/flutter_test.dart';

ChordExplorerItem _item(String shape, List<int> frets) => ChordExplorerItem(
      title: '$shape Form',
      shape: shape,
      fretPositions: frets,
      fingerPositions: const [0, 0, 0, 0, 0, 0],
      baseFret: 1,
    );

void main() {
  test('formas con igual fretPositions: la primera apunta a la última', () {
    final items = [
      _item('C', [-1, 3, 2, 0, 1, 0]),
      _item('G', [0, 2, 2, 0, 0, 0]),
      _item('E', [0, 2, 2, 0, 0, 0]),
    ];

    expect(sharedShapeLabels(items), {1: 'G (usa la digitación E)'});
  });

  test('sin digitaciones repetidas no hay etiquetas', () {
    final items = [
      _item('A', [-1, 0, 2, 2, 2, 0]),
      _item('E', [0, 2, 2, 1, 0, 0]),
    ];

    expect(sharedShapeLabels(items), isEmpty);
  });
}
