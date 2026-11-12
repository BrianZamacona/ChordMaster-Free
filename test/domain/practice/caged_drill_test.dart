import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:chordmaster_free/domain/practice/caged_drill.dart';
import 'package:chordmaster_free/domain/theory/caged_anchor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nunca repite la pareja anterior y, con tiempo, sale cada una de las 60', () {
    final rng = Random(7);
    CagedDraw? previous;
    final seen = <CagedDraw>{};
    for (var i = 0; i < 3000; i++) {
      final d = drawCaged(rng, previous: previous);
      expect(d, isNot(previous));
      expect(d.root, inInclusiveRange(0, 11));
      expect(cagedOrder, contains(d.shape));
      seen.add(d);
      previous = d;
    }
    expect(seen, hasLength(60));
  });

  test('cada forma tiene su posición CAGED en la escala mayor de scales_master.json', () {
    final master = jsonDecode(File('assets/data/scales_master.json').readAsStringSync()) as Map;
    final major = (master['scales'] as List).cast<Map>().firstWhere((s) => s['id'] == 'major');
    final ids = {for (final p in (major['positions'] as List).cast<Map>()) p['id'] as String};
    for (final shape in cagedOrder) {
      expect(ids, contains(cagedPositionId(shape)), reason: shape);
    }
    expect(CagedDrillPhase.values, hasLength(3));
  });
}
