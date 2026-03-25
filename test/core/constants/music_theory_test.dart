import 'package:chordmaster_free/core/constants/music_theory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('music theory helpers', () {
    test('getNoteAtInterval wraps chromatic notes correctly', () {
      expect(getNoteAtInterval('C', 7), 'G');
      expect(getNoteAtInterval('B', 1), 'C');
    });

    test('transposeNote preserves octave-aware transposition', () {
      expect(transposeNote('A4', 2), 'B4');
      expect(transposeNote('B3', 1), 'C4');
    });

    test('transposeNote falls back to chromatic wrap without octave', () {
      expect(transposeNote('F#', 1), 'G');
      expect(transposeNote('C', 11), 'B');
    });
  });
}