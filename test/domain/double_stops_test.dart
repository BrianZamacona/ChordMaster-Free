import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/theory/double_stops.dart';
import 'package:flutter_test/flutter_test.dart';

List<List<Object?>> _rows(List<DoubleStopGroup> groups) => [
  for (final g in groups)
    for (final p in g.pairs)
      [
        g.stringPair.$1,
        g.stringPair.$2,
        p.root.stringIndex,
        p.root.fret,
        p.interval.stringIndex,
        p.interval.fret,
        p.distance,
        p.quality,
        p.degree,
      ],
];

void main() {
  test('coincide con el golden del sandbox TS (118 casos)', () {
    final cases =
        jsonDecode(
              File('test/fixtures/golden/double_stops.json').readAsStringSync(),
            )
            as List<dynamic>;
    expect(cases, hasLength(118));

    var total = 0;
    for (final raw in cases) {
      final c = raw as Map<String, dynamic>;
      final range = FretRange(
        (c['range'] as Map<String, dynamic>)['start'] as int,
        (c['range'] as Map<String, dynamic>)['end'] as int,
      );
      final pattern = DoubleStopStringPattern.fromLabel(c['pattern'] as String);
      final groups = c['kind'] == 'diatonic'
          ? findDiatonicDoubleStopPairs(
              c['key'] as String,
              DiatonicDoubleStopInterval.fromLabel(c['interval'] as String),
              range,
              pattern,
            )
          : findDoubleStopPairs(
              c['key'] as String,
              c['distance'] as int,
              range,
              pattern,
            );
      final expected = (c['rows'] as List<dynamic>).cast<List<dynamic>>();
      total += expected.length;
      expect(_rows(groups), expected, reason: jsonEncode({...c, 'rows': null}));
    }
    expect(total, 2005);
  });

  group('propiedades en C mayor', () {
    String quality(DiatonicDoubleStopInterval type, int degree) {
      final pairs = findDiatonicDoubleStopPairs(
        'C',
        type,
        const FretRange(0, 12),
      ).expand((g) => g.pairs).where((p) => p.degree == degree);
      expect(pairs, isNotEmpty);
      return pairs.first.quality;
    }

    test('la 3ª del grado II es menor', () {
      expect(quality(DiatonicDoubleStopInterval.third, 2), '3ª menor');
    });

    test('la 4ª del IV es aumentada', () {
      expect(quality(DiatonicDoubleStopInterval.fourth, 4), '4ª aumentada');
    });

    test('la 5ª del VII es disminuida', () {
      expect(quality(DiatonicDoubleStopInterval.fifth, 7), '5ª disminuida');
    });
  });
}
