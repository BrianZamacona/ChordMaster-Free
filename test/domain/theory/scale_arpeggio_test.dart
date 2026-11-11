import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:chordmaster_free/domain/theory/scale_arpeggio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final master = jsonDecode(File('assets/data/scales_master.json').readAsStringSync()) as Map;
  final scales = {
    for (final s in [...master['scales'] as List, ...master['modes'] as List])
      (s as Map)['id'] as String: (s['intervals'] as List).cast<int>(),
  };

  test('la tríada de la tónica de cada escala', () {
    expect(tonicTriad(scales['major']!), [0, 4, 7]);
    expect(tonicTriad(scales['natural_minor']!), [0, 3, 7]);
    expect(tonicTriad(scales['locrian']!), [0, 3, 6]);
    expect(tonicTriad(scales['pentatonic_minor']!), [0, 3, 7]);
    expect(tonicTriad(scales['pentatonic_major']!), [0, 4, 7]);
    expect(tonicTriad(scales['blues_minor']!), [0, 3, 7]);
    expect(tonicTriad(scales['whole_tone']!), [0, 4, 8]);
    expect(tonicTriad(scales['diminished_wh']!), [0, 3, 6]);
    expect(triadType([0, 4, 7]), 'major');
    expect(triadType([0, 4, 8]), 'augmented');
  });

  test('en todas las escalas y modos: es una tríada que cabe en la escala, con un tipo de chords.json', () {
    final chords = (jsonDecode(File('assets/data/chords.json').readAsStringSync()) as List).cast<Map>();
    final types = {for (final c in chords) c['type'] as String};
    for (final MapEntry(key: id, value: iv) in scales.entries) {
      final triad = tonicTriad(iv);
      expect(triad, isNotNull, reason: id);
      expect(iv, containsAll(triad!), reason: id);
      expect(types, contains(triadType(triad)), reason: id);
    }
  });

  test('qué nota del mástil es del arpegio', () {
    final c = noteIndex('C');
    // 2ª cuerda al aire = B (no es de C mayor); traste 1 = C; 3ª al aire = G.
    expect(isTriadNote(2, 0, c, const [0, 4, 7]), isFalse);
    expect(isTriadNote(2, 1, c, const [0, 4, 7]), isTrue);
    expect(isTriadNote(3, 0, c, const [0, 4, 7]), isTrue);
    // En A menor, la C sí es del arpegio (su b3).
    expect(isTriadNote(2, 1, noteIndex('A'), const [0, 3, 7]), isTrue);
  });
}
