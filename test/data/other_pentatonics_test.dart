import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/core/constants/scale_names.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/theory/scale_insights.dart';
import 'package:flutter_test/flutter_test.dart';

const _majorPenta = [0, 2, 4, 7, 9];

/// La suspendida y la de 7ª mayor (`tool/regenerate_scales_master.py`), y la
/// dominante, que es la mixolidia.
void main() {
  final master = jsonDecode(File('assets/data/scales_master.json').readAsStringSync()) as Map;
  final scales = <String, Map>{for (final s in master['scales'] as List) (s as Map)['id'] as String: s};
  List<int> iv(String id) => (scales[id]!['intervals'] as List).cast<int>();
  List<String> systems(String id) => [for (final s in scales[id]!['systems'] as List) (s as Map)['id'] as String];

  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  test('suspendida: 1 2 4 5 b7, sin 3ª, y es la pentatónica mayor desde su 2º grado', () {
    final s = iv('pentatonic_suspended');
    expect(s, [0, 2, 5, 7, 10]);
    expect(s.contains(3) || s.contains(4), isFalse);
    expect({for (final m in _majorPenta) (m - _majorPenta[1]) % 12}.toList()..sort(), s);
  });

  test('de 7ª mayor: la mayor con 7 en lugar de 6; 1 3 5 7 = maj7 y la 2 = su 9', () {
    final s = iv('pentatonic_major7');
    expect(s, [0, 2, 4, 7, 11]);
    expect(_majorPenta.map((i) => i == 9 ? 11 : i).toList(), s);
    expect(s, containsAll([0, 4, 7, 11, 14 % 12]));
  });

  test('la "dominante" (1 2 3 5 b7) es la mixolidia: no se repite y la mixolidia la nombra', () {
    expect(iv('pentatonic_mixolydian'), [0, 2, 4, 7, 10]);
    final same = [for (final id in scales.keys) if (iv(id).join() == '024710') id];
    expect(same, ['pentatonic_mixolydian']);
    expect(scaleDisplayName('pentatonic_mixolydian', iv('pentatonic_mixolydian')), contains('dominante'));
    final tip = improvisationTips('pentatonic_mixolydian', iv('pentatonic_mixolydian'))!;
    expect(tip.idea.es, contains('pentatónica dominante'));
    expect(tip.idea.en, contains('dominant pentatonic'));
  });

  for (final id in ['pentatonic_suspended', 'pentatonic_major7']) {
    test('$id: pentatónica con CAGED y caja, nombre en los dos idiomas e ideas', () {
      expect(scales[id]!['category'], 'Pentatónica');
      expect(systems(id), ['caged', 'pentatonic_two_notes']);
      expect(improvisationTips(id, iv(id)), isNotNull);
      CurrentLanguage.value = AppLanguage.es;
      expect(scaleDisplayName(id, iv(id)), startsWith('Pentatónica '));
      CurrentLanguage.value = AppLanguage.en;
      expect(scaleDisplayName(id, iv(id)), endsWith(' Pentatonic'));
    });
  }
}
