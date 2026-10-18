import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/theory/double_stops.dart' show noteNames;
import 'package:chordmaster_free/domain/voicing/ergonomics.dart';
import 'package:chordmaster_free/domain/voicing/slash_chords.dart';
import 'package:chordmaster_free/domain/voicing/voicing_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final chords = (jsonDecode(File('assets/data/chords.json').readAsStringSync())
          as List<dynamic>)
      .cast<Map<String, dynamic>>();

  List<SlashVoicing> slash(String name, String bass) {
    final c = chords.firstWhere((c) => c['name'] == name);
    List<int> frets(Object? raw) => (raw! as List<dynamic>).cast<int>();
    final sources = [
      VoicingAdapter.fromChordJson(frets(c['fretPositions'])),
      for (final f in const ['cagedPositions', 'voicings', 'triadInversions'])
        for (final v in (c[f] as List<dynamic>? ?? const []))
          VoicingAdapter.fromChordJson(frets((v as Map<String, dynamic>)['fretPositions'])),
    ];
    return slashVoicings(
      sources: sources,
      rootPc: noteNames.indexOf(c['root'] as String),
      intervals: frets(c['intervals']),
      bassPc: noteNames.indexOf(bass),
    );
  }

  // Orden de chords.json (6ª → 1ª), para leerlo como se escribe.
  List<String> json(List<SlashVoicing> v) => [
    for (final s in v) VoicingAdapter.toChordJsonOrder([for (final f in s.frets) f ?? -1]).join(','),
  ];

  test('formas clásicas: C/E, C/G, C/B, D/F#, G/B y Am/G', () {
    expect(json(slash('C Major', 'E')), contains('0,3,2,0,1,0'));
    expect(json(slash('C Major', 'G')), contains('3,3,2,0,1,0'));
    expect(json(slash('C Major', 'B')), contains('-1,2,2,0,1,0'));
    expect(json(slash('D Major', 'F#')), contains('2,-1,0,2,3,2'));
    expect(json(slash('G Major', 'B')), contains('-1,2,0,0,0,3'));
    expect(json(slash('A Minor', 'G')), contains('3,0,2,2,1,0'));
  });

  test('la primera opción es la forma abierta completa', () {
    expect(json(slash('C Major', 'E')).first, '0,3,2,0,1,0');
    expect(json(slash('C Major', 'G')).first, '3,3,2,0,1,0');
    expect(json(slash('D Major', 'F#')).first, '2,-1,0,2,3,2');
    expect(json(slash('G Major', 'B')).first, '-1,2,0,0,0,3');
    expect(json(slash('A Minor', 'G')).first, '3,0,2,2,1,0');
  });

  test('en todas: el bajo es la nota más grave y el resto conserva raíz y 3ª', () {
    for (final c in chords.where((c) => c['type'] == 'major' || c['type'] == 'minor')) {
      final root = noteNames.indexOf(c['root'] as String);
      final third = (root + (c['type'] == 'major' ? 4 : 3)) % 12;
      for (var bass = 0; bass < 12; bass++) {
        if (bass == root) continue;
        final result = slash(c['name'] as String, noteNames[bass]);
        expect(result, isNotEmpty, reason: '${c['name']}/${noteNames[bass]}');
        for (final v in result) {
          final pitches = [
            for (var s = 0; s < 6; s++)
              if (v.frets[s] != null) (s, standardOpenStringMidi[s] + v.frets[s]!),
          ];
          final lowest = pitches.reduce((a, b) => a.$2 < b.$2 ? a : b);
          expect(lowest.$2 % 12, bass, reason: '${c['name']}/${noteNames[bass]} ${v.frets}');
          final upper = {for (final p in pitches) if (p != lowest) p.$2 % 12};
          expect(upper, containsAll([root, third]));
          expect(v.cost.isFinite, isTrue);
          expect(v.fingers.where((f) => f > 0).toSet().length, lessThanOrEqualTo(4));
        }
      }
    }
  });

  group('assignFingers', () {
    test('C/E: 0-3-2-0-1-0 con los dedos de la C abierta', () {
      expect(
        VoicingAdapter.toChordJsonOrder(assignFingers(VoicingAdapter.fromChordJson([0, 3, 2, 0, 1, 0]))!),
        [0, 3, 2, 0, 1, 0],
      );
    });

    test('F con cejilla: índice en el traste 1', () {
      expect(
        VoicingAdapter.toChordJsonOrder(assignFingers(VoicingAdapter.fromChordJson([1, 3, 3, 2, 1, 1]))!),
        [1, 3, 4, 2, 1, 1],
      );
    });

    test('sin cejilla posible con 5 notas en trastes distintos', () {
      expect(assignFingers(VoicingAdapter.fromChordJson([1, 2, 3, 4, 5, -1])), isNull);
    });
  });
}
