import 'package:chordmaster_free/features/scales/data/models/scale_pattern.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScalePattern.fromJson', () {
    test('parses strict-coordinate JSON successfully', () {
      final pattern = ScalePattern.fromJson({
        'scale_name': 'Major',
        'root': 'C',
        'pattern_type': 'CAGED',
        'position_name': 'Forma de A',
        'starting_fret': 2,
        'frets_span': 4,
        'coordinates': [
          {
            'string': 5,
            'fret': 3,
            'interval': '1',
            'note': 'C',
            'is_root': true,
            'finger': 2,
          },
        ],
      });

      expect(pattern.scaleName, 'Major');
      expect(pattern.root, 'C');
      expect(pattern.patternType, 'CAGED');
      expect(pattern.positionName, 'Forma de A');
      expect(pattern.startingFret, 2);
      expect(pattern.fretsSpan, 4);
      expect(pattern.coordinates, hasLength(1));
      expect(pattern.coordinates.first.isRoot, isTrue);
      expect(pattern.coordinates.first.finger, 2);
    });

    test('throws when coordinates key is missing list', () {
      expect(
        () => ScalePattern.fromJson({
          'scale_name': 'Major',
          'root': 'C',
          'pattern_type': 'CAGED',
          'position_name': 'Forma de A',
          'starting_fret': 2,
          'frets_span': 4,
        }),
        throwsFormatException,
      );
    });
  });
}
