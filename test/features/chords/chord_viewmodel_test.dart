import 'package:chordmaster_free/features/chords/chord_viewmodel.dart';
import 'package:chordmaster_free/models/chord.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final chords = [
    const Chord(
      name: 'C Major',
      root: 'C',
      type: 'major',
      intervals: [0, 4, 7],
      fretPositions: [-1, 3, 2, 0, 1, 0],
      fingerPositions: [0, 3, 2, 0, 1, 0],
      displayName: 'C',
      tags: ['standard'],
    ),
    const Chord(
      name: 'C 7#9',
      root: 'C',
      type: 'dominant7Sharp9',
      intervals: [0, 4, 7, 10, 15],
      fretPositions: [-1, 3, 2, 3, 4, -1],
      fingerPositions: [0, 2, 1, 3, 4, 0],
      displayName: 'C7#9',
      aliases: ['Hendrix Chord'],
      tags: ['blues', 'jazz', 'rock', 'exotic'],
    ),
    const Chord(
      name: 'D 5',
      root: 'D',
      type: 'power5',
      intervals: [0, 7],
      fretPositions: [-1, 5, 7, 7, -1, 5],
      fingerPositions: [0, 1, 3, 4, 0, 1],
      displayName: 'D5',
      tags: ['power', 'rock', 'blues'],
    ),
    const Chord(
      name: 'E Maj 9',
      root: 'E',
      type: 'major9',
      intervals: [0, 4, 7, 11, 14],
      fretPositions: [-1, 7, 6, 8, 7, 7],
      fingerPositions: [0, 2, 1, 4, 3, 3],
      displayName: 'Emaj9',
      tags: ['jazz'],
    ),
  ];

  group('filterChords', () {
    test('finds aliases and compact display names', () {
      final results = filterChords(chords: chords, searchQuery: 'hendrix');

      expect(results.map((chord) => chord.type), ['dominant7Sharp9']);
    });

    test('filters by tag, root, type, and query together', () {
      final results = filterChords(
        chords: chords,
        selectedTag: 'jazz',
        selectedRoot: 'E',
        selectedType: 'major9',
        searchQuery: 'maj9',
      );

      expect(results.map((chord) => chord.name), ['E Maj 9']);
    });

    test('finds power chords via category search', () {
      final results = filterChords(chords: chords, searchQuery: 'power');

      expect(results.map((chord) => chord.type), ['power5']);
    });
  });
}
