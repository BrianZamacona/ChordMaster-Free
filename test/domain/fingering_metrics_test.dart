import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/theory/double_stops.dart'
    show noteNames, openStringMidi;
import 'package:chordmaster_free/domain/voicing/fingering_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> _ints(Object? raw) => (raw! as List<dynamic>).cast<int>();

void main() {
  final chords =
      (jsonDecode(File('assets/data/chords.json').readAsStringSync())
              as List<dynamic>)
          .cast<Map<String, dynamic>>();
  final cMajor = chords.firstWhere((c) => c['name'] == 'C Major');

  FingeringMetrics analyze(Map<String, dynamic> chord, Map<String, dynamic> item) =>
      analyzeFingering(
        jsonFrets: _ints(item['fretPositions']),
        jsonFingers: _ints(item['fingerPositions']),
        root: chord['root'] as String,
        intervals: _ints(chord['intervals']),
      );

  test('C abierto', () {
    expect(cMajor['fretPositions'], [-1, 3, 2, 0, 1, 0]);
    final m = analyze(cMajor, cMajor);
    expect(m.bassNote, 'C');
    expect(m.inversion, 'Fundamental');
    expect(m.fingers, 3);
    expect(m.barre, isNull);
    expect(m.mutedStrings, 1);
    expect(m.mutedInside, 0);
    expect(m.lowestFret, 1);
    expect(m.fretSpan, 2);
    expect(m.toneLabels, ['R', '3', '5', 'R', '3']);
    expect(m.ergonomicCost, isNotNull);
  });

  test('inversiones de tríada de C Major', () {
    final inversions = (cMajor['triadInversions'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final byTitle = {for (final i in inversions) i['title'] as String: i};

    final first = analyze(cMajor, byTitle['1st Inversion']!);
    expect(first.inversion, '1ª inversión');
    expect(first.bassNote, 'E');
    expect(first.toneLabels.first, '3');

    final second = analyze(cMajor, byTitle['2nd Inversion']!);
    expect(second.inversion, '2ª inversión');
    expect(second.bassNote, 'G');
  });

  test('todo chords.json: etiquetas no vacías y bajo dentro del acorde', () {
    final outside = <String>[];
    var total = 0;
    for (final c in chords) {
      final items = <Map<String, dynamic>>[
        c,
        for (final f in const [
          'cagedPositions',
          'voicings',
          'triadInversions',
          'advancedInversions',
        ])
          ...(c[f] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>(),
      ];
      final rootPc = noteNames.indexOf(c['root'] as String);
      final allowed = {for (final i in _ints(c['intervals'])) (rootPc + i) % 12};
      for (final item in items) {
        total++;
        final m = analyze(c, item);
        expect(m.toneLabels, isNotEmpty, reason: '${c['name']} ${item['fretPositions']}');
        if (!allowed.contains(noteNames.indexOf(m.bassNote)) ||
            m.inversion == 'Fuera del acorde') {
          outside.add('${c['name']} ${item['fretPositions']}');
        }
      }
    }
    expect(total, 1092);
    expect(outside, isEmpty, reason: '$outside');
    expect(openStringMidi, hasLength(6));
  });

  group('bestIndices', () {
    test('un mejor', () => expect(bestIndices([3, 1, 2]), {1}));
    test('empate marca a todos los empatados', () {
      expect(bestIndices([2, 1, 1]), {1, 2});
    });
    test('ignora nulls', () => expect(bestIndices([null, 4, 2]), {2}));
    test('todos iguales: ninguno', () => expect(bestIndices([2, 2, 2]), isEmpty));
    test('menos de dos comparables: ninguno', () {
      expect(bestIndices([null, 3, null]), isEmpty);
      expect(bestIndices([null, null]), isEmpty);
    });
    test('acepta doubles', () => expect(bestIndices([1.5, 1.5, 2.25]), {0, 1}));
  });
}
