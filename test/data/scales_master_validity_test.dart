import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Cuerdas 1..6 (1 = mi aguda), afinación estándar: e B G D A E.
const _openHighToLow = [4, 11, 7, 2, 9, 4];

const _intervalSemitones = {
  '1': 0, 'b2': 1, '2': 2, '#2': 3, 'b3': 3, '3': 4, '4': 5, '#4': 6,
  'b5': 6, '5': 7, '#5': 8, 'b6': 8, '6': 9, 'bb7': 9, 'b7': 10, '7': 11, //
};

const _majorIntervals = [0, 2, 4, 5, 7, 9, 11];
const _modeRotation = {
  'ionian': 0, 'dorian': 1, 'phrygian': 2, 'lydian': 3,
  'mixolydian': 4, 'aeolian': 5, 'locrian': 6, //
};

void main() {
  late Map<String, dynamic> data;

  setUpAll(() {
    data =
        jsonDecode(File('assets/data/scales_master.json').readAsStringSync())
            as Map<String, dynamic>;
  });

  List<Map<String, dynamic>> all() => [
        for (final g in ['scales', 'modes'])
          for (final s in (data[g] as List<dynamic>))
            s as Map<String, dynamic>,
      ];

  test('scales_master.json: toda nota de cada posición pertenece a la escala', () {
    final defects = <String>[];
    var total = 0;
    for (final scale in all()) {
      final allowed = {
        for (final i in (scale['intervals'] as List<dynamic>)) (i as int) % 12,
      };
      for (final raw in (scale['positions'] as List<dynamic>)) {
        final pos = raw as Map<String, dynamic>;
        for (final rawC in (pos['coordinates'] as List<dynamic>)) {
          final c = rawC as Map<String, dynamic>;
          total++;
          final string = c['string'] as int;
          final semitone =
              (_openHighToLow[string - 1] + (c['fret_offset'] as int)) % 12;
          final label = c['interval'] as String?;
          final labelWrong = label != null &&
              _intervalSemitones.containsKey(label) &&
              _intervalSemitones[label] != semitone;
          if (!allowed.contains(semitone) || labelWrong) {
            defects.add('${scale['id']} / ${pos['id']} $c -> semitono $semitone');
          }
        }
      }
    }
    expect(total, greaterThan(0));
    expect(defects, isEmpty, reason: defects.take(10).join('\n'));
  });

  test('scales_master.json: cada posición tiene 6 cuerdas y cuerdas 1..6', () {
    for (final scale in all()) {
      for (final raw in (scale['positions'] as List<dynamic>)) {
        final pos = raw as Map<String, dynamic>;
        final strings = {
          for (final c in (pos['coordinates'] as List<dynamic>))
            (c as Map<String, dynamic>)['string'] as int,
        };
        expect(strings, {1, 2, 3, 4, 5, 6},
            reason: '${scale['id']} / ${pos['id']}');
      }
    }
  });

  test('scales_master.json: los modos son rotaciones de la escala mayor', () {
    final modes = (data['modes'] as List<dynamic>).cast<Map<String, dynamic>>();
    expect(modes, hasLength(7));
    for (final mode in modes) {
      final rotation = _modeRotation[mode['id']];
      expect(rotation, isNotNull, reason: 'modo desconocido ${mode['id']}');
      final expected = {
        for (final m in _majorIntervals) (m - _majorIntervals[rotation!]) % 12,
      }.toList()
        ..sort();
      expect(
        (mode['intervals'] as List<dynamic>).cast<int>(),
        expected,
        reason: 'intervalos de ${mode['id']}',
      );
    }
  });
}