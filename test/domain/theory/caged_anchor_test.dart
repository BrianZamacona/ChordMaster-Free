import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/theory/caged_anchor.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final chords = (jsonDecode(File('assets/data/chords.json').readAsStringSync()) as List).cast<Map>();

  test('el ancla de cada cuerda: el traste de la tónica', () {
    expect(anchorFret(6, noteIndex('A')), 5);
    expect(anchorFret(5, noteIndex('A')), 0);
    expect(anchorFret(4, noteIndex('C')), 10);
    expect(anchorFret(6, noteIndex('E')), 0);
  });

  test('en las 12 tónicas, cada forma CAGED mayor de chords.json tiene la raíz en su cuerda ancla', () {
    for (var root = 0; root < 12; root++) {
      final chord = chords.firstWhere((c) => c['root'] == pitchClassName(root) && c['type'] == 'major');
      final shapes = {
        for (final p in (chord['cagedPositions'] as List).cast<Map>())
          p['shape'] as String: (p['fretPositions'] as List).cast<int>(),
      };
      expect(shapes.keys.toSet(), cagedOrder.toSet(), reason: pitchClassName(root));
      for (final shape in cagedOrder) {
        final fret = shapeAnchorFret(shape, shapes[shape]!, root);
        expect(fret, isNotNull, reason: '${pitchClassName(root)} forma $shape');
        // Es el ancla de esa cuerda, o la misma una octava arriba.
        expect(fret! % 12, anchorFret(cagedAnchorString[shape]!, root), reason: '${pitchClassName(root)} forma $shape');
      }
    }
  });

  test('los pasos arman cada forma una vez, desde la 6ª, la 5ª y la 4ª', () {
    final built = [for (final s in CagedAnchorStep.values) ...shapesOf(s)];
    expect(built.toSet(), cagedOrder.toSet());
    expect(built, hasLength(5));
    for (final s in CagedAnchorStep.values) {
      for (final shape in shapesOf(s)) {
        final string = cagedAnchorString[shape];
        expect(
          string,
          switch (s) {
            CagedAnchorStep.fromSix => 6,
            CagedAnchorStep.fromFive => 5,
            _ => 4,
          },
          reason: shape,
        );
      }
    }
  });

  test('E, A y D empiezan en su ancla y suben; G y C terminan en ella y bajan, en las 12 tónicas', () {
    for (var root = 0; root < 12; root++) {
      final chord = chords.firstWhere((c) => c['root'] == pitchClassName(root) && c['type'] == 'major');
      for (final p in (chord['cagedPositions'] as List).cast<Map>()) {
        final shape = p['shape'] as String;
        final frets = (p['fretPositions'] as List).cast<int>();
        final anchor = shapeAnchorFret(shape, frets, root)!;
        expect(shapeGoesUp(frets, anchor), const {'E': true, 'A': true, 'D': true, 'G': false, 'C': false}[shape],
            reason: '${pitchClassName(root)} forma $shape');
      }
    }
  });
}
