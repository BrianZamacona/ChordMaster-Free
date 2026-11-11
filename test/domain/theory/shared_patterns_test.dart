import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/data/models/note_coordinate.dart';
import 'package:chordmaster_free/domain/theory/neck_notes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final master = jsonDecode(File('assets/data/scales_master.json').readAsStringSync()) as Map;
  final major = (master['scales'] as List).cast<Map>().firstWhere((s) => s['id'] == 'major');
  List<NoteCoordinate> coords(Map p) => [
    for (final c in (p['coordinates'] as List).cast<Map>())
      NoteCoordinate(string: c['string'] as int, fret: c['fret_offset'] as int, isRoot: false),
  ];
  List<List<NoteCoordinate>> system(String id) => [
    for (final p in (major['positions'] as List).cast<Map>())
      if (p['system_id'] == id) coords(p),
  ];
  int lowest(List<NoteCoordinate> p) => p.map((c) => c.fret).reduce((a, b) => a < b ? a : b);

  test('dos formas que se tocan comparten las notas del borde', () {
    const a = [NoteCoordinate(string: 1, fret: 3, isRoot: false), NoteCoordinate(string: 1, fret: 5, isRoot: false)];
    const b = [NoteCoordinate(string: 1, fret: 5, isRoot: false), NoteCoordinate(string: 1, fret: 7, isRoot: false)];
    expect(sharedWithNext([a, b], a).map((c) => c.fret % 12).toSet(), {5});
    // La última sigue en la primera, una octava arriba: b (5–7) toca a a en el
    // 5 y, una octava arriba, en el 17.
    expect(sharedWithNext([a, b], b).map((c) => c.fret % 12).toSet(), {5});
    expect(sharedWithNext([a], a), isEmpty);
  });

  test('cada forma CAGED de la mayor comparte notas con la siguiente, y solo notas de las dos', () {
    final shapes = system('caged')..sort((a, b) => lowest(a).compareTo(lowest(b)));
    expect(shapes, hasLength(5));
    for (var i = 0; i < shapes.length; i++) {
      final shared = sharedWithNext(shapes, shapes[i]);
      final next = shapes[(i + 1) % shapes.length];
      expect(shared, isNotEmpty, reason: 'forma $i');
      expect(patternAcrossNeck(shapes[i]).toSet(), containsAll(shared));
      expect(patternAcrossNeck(next).toSet(), containsAll(shared));
      // No es la forma entera: es el borde por donde se pasa a la siguiente.
      expect(shared.length, lessThan(patternAcrossNeck(shapes[i]).toSet().length), reason: 'forma $i');
    }
  });
}
