import 'package:chordmaster_free/features/scales/data/models/note_coordinate.dart';
import 'package:chordmaster_free/features/scales/data/scale_pattern_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScalePatternGenerator.pentatonicBoxes', () {
    test('builds canonical A minor pentatonic position 1', () {
      final patterns = ScalePatternGenerator.pentatonicBoxes(
        scaleName: 'Pentatonic Minor',
        root: 'A',
        intervals: const [0, 3, 5, 7, 10],
      );

      final position1 = patterns.first;
      final fretsByString = _fretsByString(position1.coordinates);

      expect(fretsByString[1], [5, 8]); // E
      expect(fretsByString[2], [5, 7]); // A
      expect(fretsByString[3], [5, 7]); // D
      expect(fretsByString[4], [5, 7]); // G
      expect(fretsByString[5], [5, 8]); // B
      expect(fretsByString[6], [5, 8]); // e
    });

    test('adds blue note between 4 and 5 in A blues position 1', () {
      final patterns = ScalePatternGenerator.pentatonicBoxes(
        scaleName: 'Blues',
        root: 'A',
        intervals: const [0, 3, 5, 6, 7, 10],
      );

      final position1 = patterns.first;
      final fretsByString = _fretsByString(position1.coordinates);

      expect(fretsByString[2], [5, 6, 7]); // D-Eb-E cluster
    });
  });
}

Map<int, List<int>> _fretsByString(List<NoteCoordinate> coordinates) {
  final result = <int, List<int>>{};
  for (final c in coordinates) {
    result.putIfAbsent(c.string, () => <int>[]).add(c.fret);
  }
  for (final entry in result.entries) {
    entry.value.sort();
  }
  return result;
}
