import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _open = [4, 9, 2, 7, 11, 4]; // 6ª -> 1ª
const _midi = [40, 45, 50, 55, 59, 64];
const _notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

void main() {
  final chords = (jsonDecode(File('assets/data/chords.json').readAsStringSync())
          as List<dynamic>)
      .cast<Map<String, dynamic>>();
  List<Map<String, dynamic>> section(Map<String, dynamic> c, String key) =>
      (c[key] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
  List<int> frets(Map<String, dynamic> v) => (v['fretPositions'] as List<dynamic>).cast<int>();

  const triadTypes = {
    'major': [0, 4, 7],
    'minor': [0, 3, 7],
    'diminished': [0, 3, 6],
    'augmented': [0, 4, 8],
  };

  test('tríadas: 3 inversiones en cada grupo de 3 cuerdas, cerradas y móviles', () {
    final triadChords = chords.where((c) => triadTypes.containsKey(c['type'])).toList();
    expect(triadChords, hasLength(48));
    for (final c in triadChords) {
      final root = _notes.indexOf(c['root'] as String);
      final tones = triadTypes[c['type']]!;
      final triads = section(c, 'triadInversions');
      expect(triads, hasLength(12), reason: c['name'] as String);
      for (final (i, v) in triads.indexed) {
        final f = frets(v);
        final strings = [for (var s = 0; s < 6; s++) if (f[s] >= 0) s];
        final reason = '${c['name']} ${v['title']} $f';
        // Grupos 3-2-1, 4-3-2, 5-4-3, 6-5-4 (índices 6ª -> 1ª: 3, 2, 1, 0).
        final low = 3 - i ~/ 3;
        expect(strings, [low, low + 1, low + 2], reason: reason);
        expect(strings.every((s) => f[s] >= 1), isTrue, reason: reason);
        // Bajo: raíz, 3ª o 5ª según la inversión; notas en orden ascendente
        // dentro de una octava (posición cerrada).
        final intervals = [for (final s in strings) (_open[s] + f[s] - root) % 12];
        final inversion = i % 3;
        expect(intervals, [...tones.sublist(inversion), ...tones.sublist(0, inversion)],
            reason: reason);
        final pitches = [for (final s in strings) _midi[s] + f[s]];
        expect(pitches.last - pitches.first, lessThan(12), reason: reason);
      }
    }
  });

  test('C mayor en las cuerdas 6-5-4: 8-7-5, 12-10-10 y 3-3-2', () {
    final c = chords.firstWhere((c) => c['name'] == 'C Major');
    expect([for (final v in section(c, 'triadInversions').sublist(9)) frets(v)], [
      [8, 7, 5, -1, -1, -1],
      [12, 10, 10, -1, -1, -1],
      [3, 3, 2, -1, -1, -1],
    ]);
  });

  const drop3Types = {
    'major7': [0, 11, 4, 7],
    'dominant7': [0, 10, 4, 7],
    'minor7': [0, 10, 3, 7],
    'halfDiminished': [0, 10, 3, 6],
    'diminished7': [0, 9, 3, 6],
  };

  test('Drop 3: R-7-3-5 con raíz en la 6ª (6-4-3-2) y en la 5ª (5-3-2-1)', () {
    final drop3Chords = chords.where((c) => drop3Types.containsKey(c['type'])).toList();
    expect(drop3Chords, hasLength(60));
    for (final c in drop3Chords) {
      final root = _notes.indexOf(c['root'] as String);
      final shapes = section(c, 'voicings').where((v) => v['shape'] == 'Drop 3').toList();
      expect(shapes, hasLength(2), reason: c['name'] as String);
      for (final (i, v) in shapes.indexed) {
        final f = frets(v);
        final strings = [for (var s = 0; s < 6; s++) if (f[s] >= 0) s];
        final reason = '${c['name']} $f';
        expect(strings, [i, i + 2, i + 3, i + 4], reason: reason);
        expect([for (final s in strings) (_open[s] + f[s] - root) % 12], drop3Types[c['type']],
            reason: reason);
        // Un dedo por nota: nada de cejilla sobre la cuerda muteada.
        final fingers = (v['fingerPositions'] as List<dynamic>).cast<int>();
        expect({for (final s in strings) fingers[s]}, hasLength(4), reason: reason);
      }
    }
  });

  test('Cmaj7 Drop 3: 8x998x y x3x453', () {
    final c = chords.firstWhere((c) => c['name'] == 'C Maj 7');
    expect(
      [for (final v in section(c, 'voicings').where((v) => v['shape'] == 'Drop 3')) frets(v)],
      [
        [8, -1, 9, 9, 8, -1],
        [-1, 3, -1, 4, 5, 3],
      ],
    );
  });
}
