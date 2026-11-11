import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/progressions/progression_data.dart';
import 'package:chordmaster_free/domain/theory/play_over.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final master = jsonDecode(File('assets/data/scales_master.json').readAsStringSync()) as Map;
  // Como la pantalla: primero las escalas y después los modos.
  final candidates = {
    for (final s in [...master['scales'] as List, ...master['modes'] as List])
      (s as Map)['id'] as String: (s['intervals'] as List).cast<int>(),
  };
  Progression byId(String id) => progressions.firstWhere((p) => p.id == id);
  PlayOverScales over(String id) => playOverScales(byId(id), candidates);

  test('cada escala que «cabe» tiene todas las notas de todos los acordes, y cada pentatónica cabe en ella', () {
    for (final p in progressions) {
      final r = playOverScales(p, candidates);
      final tones = progressionTones(p);
      for (final id in r.fit) {
        expect(candidates[id], containsAll(tones), reason: '${p.id} $id');
      }
      for (final id in r.pentatonic) {
        expect(candidates[id]!.toSet(), hasLength(5), reason: '${p.id} $id');
        expect(candidates[r.fit.first], containsAll(candidates[id]!), reason: '${p.id} $id');
      }
      // Las mismas notas salen una sola vez (mayor = jónica).
      final sets = [for (final id in r.fit) (candidates[id]!.toSet().toList()..sort()).join(',')];
      expect(sets.toSet(), hasLength(sets.length), reason: p.id);
    }
  });

  test('en mayor: la escala mayor y su pentatónica; en menor y en los modos, la suya', () {
    expect(over('v1-2').fit, ['major']);
    expect(over('v1-2').pentatonic, ['pentatonic_major']);
    expect(over('m1').fit, contains('natural_minor'));
    expect(over('m1').pentatonic, contains('pentatonic_minor'));
    expect(over('m3').fit, contains('harmonic_minor'));
    for (final p in progressions.where((p) => p.kind == ProgressionKind.modal)) {
      expect(playOverScales(p, candidates).fit, contains(modeScaleIds[p.mode!]), reason: p.id);
    }
    expect(over('v1-1').blues, isEmpty);
  });

  test('en el blues ninguna de 7 notas contiene los tres acordes: van las tres de siempre, y lo que dicen es cierto', () {
    final r = over('blues-12');
    expect(r.fit, isEmpty);
    expect(r.blues, bluesScaleIds);
    final minor = candidates['pentatonic_minor']!;
    final blues = candidates['blues_minor']!;
    final major = candidates['pentatonic_major']!;
    // Raíz, 5ª y b7 del I7, y la b3 que roza su 3ª.
    expect(minor, containsAll([0, 7, 10, 3]));
    // La de blues = la menor con la b5.
    expect(blues.toSet(), {...minor, 6});
    // La mayor: raíz, 3ª y 5ª del I7, sin la b3.
    expect(major, containsAll([0, 4, 7]));
    expect(major, isNot(contains(3)));
    for (final id in bluesScaleIds) {
      expect(bluesScaleRole(id).es, isNotEmpty);
      expect(bluesScaleRole(id).en, isNotEmpty);
    }
  });

  test('el arpegio de cada acorde, con sus intervalos', () {
    final b = byId('blues-12');
    final v7 = b.degrees[8];
    expect([for (final n in degreeArpeggio(v7)) n.label], ['1', '3', '5', 'b7']);
    // Desde la tónica: el V7 es 7, 11, 2 y 5 (G B D F en C).
    expect([for (final n in degreeArpeggio(v7)) n.semitones], [7, 11, 2, 5]);
    final dim = byId('mode-locrian').degrees.first;
    expect([for (final n in degreeArpeggio(dim)) n.label], ['1', 'b3', 'b5']);
  });
}
