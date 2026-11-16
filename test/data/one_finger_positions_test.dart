import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/fingering_systems/fingering_systems_registry.dart';
import 'package:flutter_test/flutter_test.dart';

/// "Un dedo por traste" (decisión del usuario): la regla de
/// `tool/regenerate_scales_master.py` (`one_finger_box`) contra la guía de
/// Berklee que trajo el usuario y contra lo que dice la teoría del sistema.
void main() {
  final data = jsonDecode(File('assets/data/scales_master.json').readAsStringSync()) as Map<String, dynamic>;
  final all = [...data['scales'] as List<dynamic>, ...data['modes'] as List<dynamic>].cast<Map<String, dynamic>>();
  const openLowToHigh = [40, 45, 50, 55, 59, 64]; // 6ª … 1ª

  /// Trastes por cuerda, de la 6ª a la 1ª.
  List<List<int>> frets(Map<String, dynamic> position) => [
    for (var string = 6; string >= 1; string--)
      [
        for (final c in (position['coordinates'] as List<dynamic>).cast<Map<String, dynamic>>())
          if (c['string'] == string) c['fret_offset'] as int,
      ]..sort(),
  ];

  List<Map<String, dynamic>> oneFinger(Map<String, dynamic> scale) => [
    for (final p in (scale['positions'] as List<dynamic>).cast<Map<String, dynamic>>())
      if (p['system_id'] == 'one_finger') p,
  ];

  test('las 7 posiciones de Do mayor son las de la guía, una por grado en la 6ª cuerda', () {
    final major = all.firstWhere((s) => s['id'] == 'major');
    // Posición 1 empieza en C (el grado 1), la 2 en D… como en la guía:
    // VIII, X, XII, II, III, V y VII.
    expect([for (final p in oneFinger(major)) frets(p)], [
      [[8, 10, 12], [8, 10, 12], [9, 10, 12], [9, 10, 12], [10, 12], [8, 10, 12]],
      [[10, 12, 13], [10, 12], [9, 10, 12], [9, 10, 12], [10, 12, 13], [10, 12, 13]],
      [[12, 13, 15], [12, 14, 15], [12, 14, 15], [12, 14], [12, 13, 15], [12, 13, 15]],
      [[1, 3, 5], [2, 3, 5], [2, 3, 5], [2, 4, 5], [3, 5], [1, 3, 5]],
      [[3, 5], [2, 3, 5], [2, 3, 5], [2, 4, 5], [3, 5, 6], [3, 5]],
      [[5, 7, 8], [5, 7, 8], [5, 7], [4, 5, 7], [5, 6, 8], [5, 7, 8]],
      [[7, 8, 10], [7, 8, 10], [7, 9, 10], [7, 9, 10], [8, 10], [7, 8, 10]],
    ]);
  });

  test('cada escala de 7 notas: lo que dice la teoría del sistema', () {
    final sevens = all.where((s) => (s['intervals'] as List<dynamic>).length == 7).toList();
    expect(sevens, hasLength(24));
    for (final scale in sevens) {
      final id = scale['id'];
      final intervals = (scale['intervals'] as List<dynamic>).cast<int>();
      final positions = oneFinger(scale);
      // Una posición por grado de la escala.
      expect(positions, hasLength(7), reason: '$id');
      for (final (k, p) in positions.indexed) {
        final fs = frets(p);
        final label = '$id posición ${k + 1}';
        // 2 o 3 notas en cada una de las 6 cuerdas, sin cuerdas al aire.
        expect(fs.every((s) => s.length == 2 || s.length == 3), isTrue, reason: label);
        final flat = [for (final s in fs) ...s];
        expect(flat.every((f) => f >= 1), isTrue, reason: label);
        // Cuatro trastes y un estiramiento de cada lado como mucho: 6 trastes.
        expect(flat.reduce((a, b) => a > b ? a : b) - flat.reduce((a, b) => a < b ? a : b), lessThanOrEqualTo(5), reason: label);
        // La escala subiendo, sin saltarse notas, desde el grado k en la 6ª.
        final pitches = [
          for (final (i, s) in fs.indexed)
            for (final f in s) openLowToHigh[i] + f,
        ];
        expect(pitches.first % 12, intervals[k], reason: label);
        final degrees = [for (final m in pitches) intervals.indexOf(m % 12)];
        for (var j = 1; j < pitches.length; j++) {
          expect(pitches[j], greaterThan(pitches[j - 1]), reason: label);
          expect(degrees[j], (degrees[j - 1] + 1) % 7, reason: '$label, nota ${j + 1}');
        }
      }
      // "Se enciman": cada posición comparte notas con la siguiente (a una
      // octava, si una subió 12 trastes para no usar cuerdas al aire).
      for (var k = 0; k + 1 < positions.length; k++) {
        String key(Map<String, dynamic> c) => '${c['string']}:${(c['fret_offset'] as int) % 12}';
        final a = {for (final c in (positions[k]['coordinates'] as List<dynamic>).cast<Map<String, dynamic>>()) key(c)};
        final b = {for (final c in (positions[k + 1]['coordinates'] as List<dynamic>).cast<Map<String, dynamic>>()) key(c)};
        expect(a.intersection(b), isNotEmpty, reason: '$id posiciones ${k + 1} y ${k + 2}');
      }
    }
  });

  test('el sistema está en el registro, con su teoría, y no se llama Berklee', () {
    final theory = FingeringSystemsRegistry.theoryFor('one_finger')!;
    expect(FingeringSystemsRegistry.displayOrder, contains('one_finger'));
    for (final text in [theory.name.es, theory.name.en]) {
      expect(text.toLowerCase(), isNot(contains('berklee')));
    }
    // Las que no son de 7 notas no lo ofrecen.
    for (final scale in all.where((s) => (s['intervals'] as List<dynamic>).length != 7)) {
      expect(oneFinger(scale), isEmpty, reason: '${scale['id']}');
    }
  });
}
