import 'package:flutter_test/flutter_test.dart';

import '../support/chord_data.dart';

/// Cada digitación de chords.json se puede tocar con una mano: un dedo pisa
/// un solo traste (puede ser cejilla, varias cuerdas en el mismo traste) y
/// no hacen falta más de cuatro dedos. Lo garantiza regenerate_chord_data.py.
void main() {
  final shapes = <(String, List<int>, List<int>)>[
    for (final c in loadChordJson()) ...[
      (c['displayName'] as String, (c['fretPositions'] as List).cast<int>(), (c['fingerPositions'] as List).cast<int>()),
      for (final section in ['cagedPositions', 'voicings', 'triadInversions', 'advancedInversions'])
        for (final p in (c[section] as List?) ?? const [])
          if ((p as Map)['fingerPositions'] != null)
            (
              '${c['displayName']} $section ${p['title']}',
              (p['fretPositions'] as List).cast<int>(),
              (p['fingerPositions'] as List).cast<int>(),
            ),
    ],
  ];

  test('un dedo nunca pisa dos trastes distintos', () {
    expect(shapes.length, greaterThan(1000));
    for (final (name, frets, fingers) in shapes) {
      final fretsOf = <int, Set<int>>{};
      for (var i = 0; i < 6; i++) {
        if (fingers[i] > 0 && frets[i] > 0) fretsOf.putIfAbsent(fingers[i], () => {}).add(frets[i]);
      }
      for (final MapEntry(key: finger, value: fs) in fretsOf.entries) {
        expect(fs, hasLength(1), reason: '$name: dedo $finger en $fs ($frets / $fingers)');
      }
      expect(fingers.where((f) => f > 4), isEmpty, reason: name);
    }
  });

  test('Dm: el índice en la 1ª, el medio en la 3ª y el anular en la 2ª', () {
    final dm = loadChordJson().firstWhere((c) => c['displayName'] == 'Dm');
    expect(dm['fretPositions'], [-1, -1, 0, 2, 3, 1]);
    expect(dm['fingerPositions'], [0, 0, 0, 2, 3, 1]);
  });
}
