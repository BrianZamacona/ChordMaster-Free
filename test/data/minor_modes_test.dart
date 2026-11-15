import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/core/constants/scale_names.dart';
import 'package:chordmaster_free/domain/theory/intervals.dart';
import 'package:chordmaster_free/domain/theory/scale_insights.dart';
import 'package:flutter_test/flutter_test.dart';

const _melodic = [0, 2, 3, 5, 7, 9, 11];
const _harmonic = [0, 2, 3, 5, 7, 8, 11];
const _major = [0, 2, 4, 5, 7, 9, 11];
const _minor = [0, 2, 3, 5, 7, 8, 10];

/// Grado (desde 0) de cada modo dentro de su escala madre.
const _families = {
  'Modo de la melódica': (_melodic, [
    'dorian_b2', 'lydian_augmented', 'lydian_dominant', 'mixolydian_b6', 'locrian_sharp2', 'altered', //
  ]),
  'Modo de la armónica': (_harmonic, [
    'locrian_sharp6', 'ionian_augmented', 'dorian_sharp4', 'phrygian_dominant', 'lydian_sharp2',
    'super_locrian_bb7', //
  ]),
};

List<int> _rotate(List<int> scale, int degree) =>
    {for (final m in scale) (m - scale[degree]) % 12}.toList()..sort();

/// Un modo de la mayor con una nota cambiada.
List<int> _modeWith(int degree, int from, int to) =>
    _rotate(_major, degree).map((i) => i == from ? to : i).toList()..sort();

void main() {
  late Map<String, List<int>> intervals;
  late Map<String, String> categories;

  setUpAll(() {
    final data = jsonDecode(File('assets/data/scales_master.json').readAsStringSync()) as Map<String, dynamic>;
    final scales = (data['scales'] as List).cast<Map<String, dynamic>>();
    intervals = {for (final s in scales) s['id'] as String: (s['intervals'] as List).cast<int>()};
    categories = {for (final s in scales) s['id'] as String: s['category'] as String};
  });

  test('cada familia tiene los grados 2 a 7 de su escala madre, en orden y por rotación', () {
    for (final MapEntry(key: category, value: (parent, ids)) in _families.entries) {
      for (final (i, id) in ids.indexed) {
        expect(intervals[id], _rotate(parent, i + 1), reason: id);
        expect(categories[id], category, reason: id);
      }
      final inData = [for (final MapEntry(:key, :value) in categories.entries) if (value == category) key];
      expect(inData, ids, reason: category);
    }
  });

  test('cada modo tiene nombre en los dos idiomas e ideas de improvisación', () {
    for (final (_, ids) in _families.values) {
      for (final id in ids) {
        expect(scaleDisplayName(id, intervals[id]!), isNot(id));
        expect(improvisationTips(id, intervals[id]!), isNotNull, reason: id);
      }
    }
  });

  group('lo que afirma cada idea', () {
    List<String> labels(String id) => scaleDegreeLabels(intervals[id]!);

    test('dórica b2 = dórica con b2 = frigia con 6', () {
      expect(intervals['dorian_b2'], _modeWith(1, 2, 1));
      expect(intervals['dorian_b2'], _modeWith(2, 8, 9));
      expect(labels('dorian_b2'), containsAll(['b2', '6']));
    });

    test('lidia aumentada: del 1 al #5 todo por tonos, luego 6 y 7', () {
      expect(labels('lydian_augmented'), ['1', '2', '3', '#4', '#5', '6', '7']);
      final iv = intervals['lydian_augmented']!;
      for (var i = 0; i < 4; i++) {
        expect(iv[i + 1] - iv[i], 2);
      }
    });

    test('lidia dominante = mixolidia con #4 = lidia con b7', () {
      expect(intervals['lydian_dominant'], _modeWith(4, 5, 6));
      expect(intervals['lydian_dominant'], _modeWith(3, 11, 10));
    });

    test('mixolidia b6: abajo la mayor, arriba la menor natural', () {
      final iv = intervals['mixolydian_b6']!;
      expect(iv.where((i) => i <= 5), _major.where((i) => i <= 5));
      expect(iv.where((i) => i >= 7), _minor.where((i) => i >= 7));
      expect(labels('mixolydian_b6'), containsAll(['1', '2', '3', '4', '5', 'b6', 'b7']));
    });

    test('locria #2 = locria con 2', () {
      expect(intervals['locrian_sharp2'], _modeWith(6, 1, 2));
    });

    test('alterada: 1, 3 (escrita b4), b7 y b9 #9 b5 #5, sin la 5', () {
      final iv = intervals['altered']!;
      expect(iv, containsAll([0, 4, 10, 1, 3, 6, 8]));
      expect(iv, isNot(contains(7)));
      expect(spellInterval(4, iv), 'b4');
    });

    test('locria #6 = locria con 6, y esa 6 es la 7 de la armónica', () {
      expect(intervals['locrian_sharp6'], _modeWith(6, 8, 9));
      // Sobre el 2º grado (2 semitonos), la 6 cae en la 7 de la armónica.
      expect((2 + 9) % 12, _harmonic[6]);
    });

    test('jónica #5 y dórica #4 y lidia #2: el tono y medio y el medio tono que dicen', () {
      final ion = intervals['ionian_augmented']!;
      expect(ion, _modeWith(0, 7, 8));
      expect(ion.contains(5) && !ion.contains(6) && !ion.contains(7) && ion.contains(9), isTrue);
      final dor = intervals['dorian_sharp4']!;
      expect(dor, _modeWith(1, 5, 6));
      expect(dor.contains(3) && !dor.contains(4) && !dor.contains(5) && dor.contains(7), isTrue);
      final lyd = intervals['lydian_sharp2']!;
      expect(lyd, _modeWith(3, 2, 3));
      expect(spellInterval(3, lyd), '#2');
      expect(lyd.contains(1) || lyd.contains(2), isFalse);
    });

    test('superlocria bb7 = alterada con bb7; 1 b3 b5 bb7 son el dim7', () {
      final iv = intervals['super_locrian_bb7']!;
      expect(iv, intervals['altered']!.map((i) => i == 10 ? 9 : i).toList()..sort());
      expect(iv, containsAll([0, 3, 6, 9]));
      expect([for (final i in [0, 3, 6, 9]) spellInterval(i, iv)], ['1', 'b3', 'b5', 'bb7']);
    });
  });
}
