import 'package:chordmaster_free/models/chord.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Chord.fromJson', () {
    test('parses extended metadata fields', () {
      final chord = Chord.fromJson({
        'name': 'C 7#9',
        'root': 'C',
        'type': 'dominant7Sharp9',
        'intervals': [0, 4, 7, 10, 15],
        'fretPositions': [-1, 3, 2, 3, 4, -1],
        'fingerPositions': [0, 2, 1, 3, 4, 0],
        'difficulty': 3,
        'displayName': 'C7#9',
        'aliases': ['Hendrix Chord'],
        'tags': ['blues', 'jazz'],
        'description': 'Altered dominant color.',
        'baseFret': 3,
        'voicingName': 'Movable voicing',
        'cagedPositions': [
          {
            'title': 'A Form',
            'shape': 'A',
            'description': 'Movable form.',
            'fretPositions': [-1, 3, 5, 5, 5, 3],
            'fingerPositions': [0, 1, 3, 4, 2, 1],
            'baseFret': 3,
          },
        ],
      });

      expect(chord.displayName, 'C7#9');
      expect(chord.aliases, ['Hendrix Chord']);
      expect(chord.tags, ['blues', 'jazz']);
      expect(chord.description, 'Altered dominant color.');
      expect(chord.baseFret, 3);
      expect(chord.voicingName, 'Movable voicing');
      expect(chord.cagedPositions, hasLength(1));
      expect(chord.cagedPositions.first.title, 'A Form');
      expect(chord.cagedPositions.first.shape, 'A');
    });

    test('keeps backward compatibility for legacy chord JSON', () {
      final chord = Chord.fromJson({
        'name': 'C Major',
        'root': 'C',
        'type': 'major',
        'intervals': [0, 4, 7],
        'fretPositions': [-1, 3, 2, 0, 1, 0],
        'fingerPositions': [0, 3, 2, 0, 1, 0],
      });

      expect(chord.displayName, isNull);
      expect(chord.aliases, isEmpty);
      expect(chord.tags, isEmpty);
      expect(chord.description, isNull);
      expect(chord.baseFret, isNull);
      expect(chord.voicingName, isNull);
      expect(chord.difficulty, 1);
      expect(chord.cagedPositions, isEmpty);
      expect(chord.voicings, isEmpty);
      expect(chord.triadInversions, isEmpty);
      expect(chord.advancedInversions, isEmpty);
    });

    test('rejects invalid fret list length', () {
      expect(
        () => Chord.fromJson({
          'name': 'Broken Chord',
          'root': 'C',
          'type': 'major',
          'intervals': [0, 4, 7],
          'fretPositions': [0, 1, 2],
          'fingerPositions': [0, 1, 2, 3, 4, 0],
        }),
        throwsFormatException,
      );
    });

    test('rejects invalid explorer item payload', () {
      expect(
        () => Chord.fromJson({
          'name': 'Broken Explorer Chord',
          'root': 'C',
          'type': 'major',
          'intervals': [0, 4, 7],
          'fretPositions': [-1, 3, 2, 0, 1, 0],
          'fingerPositions': [0, 3, 2, 0, 1, 0],
          'cagedPositions': [
            {
              'title': 'Bad Entry',
              // Invalid because explorer fret positions must always have 6 strings.
              'fretPositions': [3, 5, 5],
              'fingerPositions': [1, 3, 4, 2, 1, 1],
            },
          ],
        }),
        throwsFormatException,
      );
    });
  });
}
