import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _open = [4, 9, 2, 7, 11, 4]; // 6ª -> 1ª
const _notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

void main() {
  final chords = (jsonDecode(File('assets/data/chords.json').readAsStringSync())
          as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .where((c) => c['type'] == 'power5')
      .toList();

  test('12 power chords, cada uno con raíz en la 6ª, 5ª, 4ª y 3ª cuerda', () {
    expect(chords, hasLength(12));
    for (final c in chords) {
      final root = _notes.indexOf(c['root'] as String);
      final voicings = (c['voicings'] as List<dynamic>).cast<Map<String, dynamic>>();
      expect(voicings, hasLength(8), reason: c['name'] as String);
      for (final (i, v) in voicings.take(4).indexed) {
        final frets = (v['fretPositions'] as List<dynamic>).cast<int>();
        final played = [
          for (var s = 0; s < 6; s++)
            if (frets[s] >= 0) (s, (_open[s] + frets[s]) % 12),
        ];
        // R-5-R: tres cuerdas seguidas, la más grave es la raíz, sin repetir la 5ª.
        expect(played, hasLength(3), reason: '${c['name']} $frets');
        expect(played.first.$1, i, reason: 'raíz en la ${6 - i}ª cuerda');
        expect([for (final p in played) (p.$2 - root + 12) % 12], [0, 7, 0]);
      }
    }
  });

  test('inversiones 5-R-5: la 5ª en el bajo en la 6ª, 5ª, 4ª y 3ª cuerda', () {
    for (final c in chords) {
      final root = _notes.indexOf(c['root'] as String);
      final voicings = (c['voicings'] as List<dynamic>).cast<Map<String, dynamic>>();
      for (final (i, v) in voicings.skip(4).indexed) {
        final frets = (v['fretPositions'] as List<dynamic>).cast<int>();
        final played = [
          for (var s = 0; s < 6; s++)
            if (frets[s] >= 0) (s, (_open[s] + frets[s]) % 12),
        ];
        expect(played.first.$1, i, reason: '${c['name']} $frets');
        expect([for (final p in played) (p.$2 - root + 12) % 12], [7, 0, 7],
            reason: '${c['name']} $frets');
      }
    }
    final c5 = chords.firstWhere((c) => c['root'] == 'C');
    expect([for (final v in (c5['voicings'] as List<dynamic>).skip(4)) v['fretPositions']], [
      [3, 3, 5, -1, -1, -1],
      [-1, 10, 10, 12, -1, -1],
      [-1, -1, 5, 5, 8, -1],
      [-1, -1, -1, 0, 1, 3],
    ]);
  });

  test('C5: 8 en la 6ª, 3 en la 5ª, 10 en la 4ª y 5 en la 3ª', () {
    final c5 = chords.firstWhere((c) => c['root'] == 'C');
    expect(c5['fretPositions'], [-1, 3, 5, 5, -1, -1]);
    expect([for (final v in (c5['voicings'] as List<dynamic>).take(4)) v['fretPositions']], [
      [8, 10, 10, -1, -1, -1],
      [-1, 3, 5, 5, -1, -1],
      [-1, -1, 10, 12, 13, -1],
      [-1, -1, -1, 5, 8, 8],
    ]);
  });

  test('E5, A5 y D5 abren al aire como principal', () {
    String main(String root) =>
        (chords.firstWhere((c) => c['root'] == root)['fretPositions'] as List).join(',');
    expect(main('E'), '0,2,2,-1,-1,-1');
    expect(main('A'), '-1,0,2,2,-1,-1');
    expect(main('D'), '-1,-1,0,2,3,-1');
  });
}
