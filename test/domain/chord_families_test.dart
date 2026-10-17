import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/theory/chord_families.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final chords = (jsonDecode(File('assets/data/chords.json').readAsStringSync())
          as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final types = {for (final c in chords) c['type'] as String};

  test('cada tipo de chords.json tiene familia y no sobra ninguna', () {
    expect(types, hasLength(24));
    expect(chordFamilyByType.keys.toSet(), types);
  });

  test('tamaño de cada familia: 7 · 7 · 7 · 3', () {
    int count(ChordFamily f) =>
        chordFamilyByType.values.where((x) => x == f).length;
    expect(count(ChordFamily.triads), 7);
    expect(count(ChordFamily.sixthsAndSevenths), 7);
    expect(count(ChordFamily.extended), 7);
    expect(count(ChordFamily.altered), 3);
  });

  test('las tríadas tienen como mucho 3 notas distintas; el resto, 4 o más', () {
    for (final c in chords) {
      final pcs = {for (final i in (c['intervals'] as List<dynamic>)) (i as int) % 12};
      final family = chordFamilyByType[c['type']]!;
      if (family == ChordFamily.triads) {
        expect(pcs.length, lessThanOrEqualTo(3), reason: c['name'] as String);
      } else {
        expect(pcs.length, greaterThanOrEqualTo(4), reason: c['name'] as String);
      }
    }
  });
}
