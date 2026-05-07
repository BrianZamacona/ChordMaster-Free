import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/core/constants/chord_metadata.dart';
import 'package:chordmaster_free/models/chord.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final datasetPath =
      '/home/runner/work/ChordMaster-Free/ChordMaster-Free/assets/data/chords.json';

  group('chord dataset integrity', () {
    late List<dynamic> rawData;
    late List<Chord> chords;

    setUpAll(() {
      rawData = jsonDecode(File(datasetPath).readAsStringSync()) as List<dynamic>;
      chords = rawData
          .map((entry) => Chord.fromJson(entry as Map<String, dynamic>))
          .toList(growable: false);
    });

    test('expands the catalog beyond the original baseline', () {
      expect(chords.length, greaterThan(108));
    });

    test('contains no duplicate chord names', () {
      final uniqueNames = chords.map((chord) => chord.name).toSet();
      expect(uniqueNames.length, chords.length);
    });

    test('uses only supported types and allowed tags', () {
      for (final chord in chords) {
        expect(chordTypeMetadata.containsKey(chord.type), isTrue,
            reason: 'Unknown type: ${chord.type}');
        for (final tag in chord.tags) {
          expect(allowedChordTags, contains(tag),
              reason: 'Unexpected tag "$tag" in ${chord.name}');
        }
      }
    });

    test('includes curated expansion categories and Hendrix aliases', () {
      expect(chords.any((chord) => chord.type == 'power5'), isTrue);
      expect(chords.any((chord) => chord.type == 'major9'), isTrue);
      expect(chords.any((chord) => chord.type == 'dominant7Sharp9'), isTrue);
      expect(
        chords.any((chord) => chord.aliases.contains('Hendrix Chord')),
        isTrue,
      );
    });

    test('keeps chord difficulty and positions within valid ranges', () {
      for (final chord in chords) {
        expect(chord.difficulty, inInclusiveRange(1, 5));
        expect(chord.fretPositions, hasLength(6));
        expect(chord.fingerPositions, hasLength(6));
        for (final fret in chord.fretPositions) {
          expect(fret, inInclusiveRange(-1, 24));
        }
        for (final finger in chord.fingerPositions) {
          expect(finger, inInclusiveRange(0, 4));
        }
      }
    });
  });
}
