import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/core/constants/scale_names.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/theory/harmony.dart';
import 'package:chordmaster_free/domain/theory/scale_insights.dart';
import 'package:flutter_test/flutter_test.dart';

/// La pentatónica de cada modo (`tool/regenerate_scales_master.py`): la de su
/// calidad con la nota característica del modo en lugar de la más cercana,
/// sin tocar la raíz, la 3ª ni la 5ª justa.
void main() {
  final master = jsonDecode(File('assets/data/scales_master.json').readAsStringSync()) as Map;
  final scales = {for (final s in master['scales'] as List) (s as Map)['id'] as String: s};
  const modes = {'dorian': 1, 'phrygian': 2, 'lydian': 3, 'mixolydian': 4};

  for (final MapEntry(key: mode, value: rotation) in modes.entries) {
    test('pentatónica $mode: cinco notas del modo, con su raíz, su 3ª, su 5ª y su nota característica', () {
      final s = scales['pentatonic_$mode']!;
      final iv = (s['intervals'] as List).cast<int>();
      final modeIv = modeIntervals(rotation);
      expect(iv, hasLength(5));
      expect(modeIv, containsAll(iv));
      expect(iv, contains(0));
      expect(iv, contains(modeIv.contains(4) ? 4 : 3));
      if (modeIv.contains(7)) expect(iv, contains(7));
      expect(iv, containsAll(compareScale(modeIv)!.added));
      // Parte de la pentatónica de su calidad: comparte con ella todo menos
      // las notas características.
      final base = modeIv.contains(4) ? [0, 2, 4, 7, 9] : [0, 3, 5, 7, 10];
      final changed = iv.where((i) => !base.contains(i)).toSet();
      expect(changed, compareScale(modeIv)!.added.toSet());
      // Con su nombre en los dos idiomas.
      CurrentLanguage.value = AppLanguage.es;
      expect(scaleDisplayName(s['id'] as String, iv), startsWith('Pentatónica '));
      CurrentLanguage.value = AppLanguage.en;
      expect(scaleDisplayName(s['id'] as String, iv), endsWith(' Pentatonic'));
      CurrentLanguage.value = AppLanguage.es;
    });
  }

  test('los intervalos que da la regla', () {
    List<int> iv(String m) => (scales['pentatonic_$m']!['intervals'] as List).cast<int>();
    expect(iv('dorian'), [0, 3, 5, 7, 9]);
    expect(iv('phrygian'), [0, 1, 3, 5, 7]);
    expect(iv('lydian'), [0, 2, 4, 6, 7]);
    expect(iv('mixolydian'), [0, 2, 4, 7, 10]);
    // El locrio no tiene: no cabría en una caja ni llenaría las 6 cuerdas.
    expect(scales, isNot(contains('pentatonic_locrian')));
    for (final m in modes.keys) {
      final systems = [for (final s in scales['pentatonic_$m']!['systems'] as List) (s as Map)['id']];
      expect(systems, ['caged', 'pentatonic_two_notes'], reason: m);
    }
  });

  test('lo que dice cada idea de improvisación: qué nota cambia frente a su pentatónica', () {
    List<int> iv(String m) => (scales['pentatonic_$m']!['intervals'] as List).cast<int>();
    // Dórica y frigia: la menor sin la b7; lidia y mixolidia: la mayor sin la 6.
    for (final (m, base, out, inn) in [
      ('dorian', [0, 3, 5, 7, 10], 10, 9),
      ('phrygian', [0, 3, 5, 7, 10], 10, 1),
      ('lydian', [0, 2, 4, 7, 9], 9, 6),
      ('mixolydian', [0, 2, 4, 7, 9], 9, 10),
    ]) {
      expect(iv(m), [...base]..remove(out)..add(inn)..sort(), reason: m);
      final tip = improvisationTips('pentatonic_$m', iv(m))!;
      expect(tip.idea.es, isNotEmpty);
      expect(tip.style.en, isNotEmpty);
    }
    // El acorde 7 (1 3 5 b7) cabe en la mixolidia.
    expect(iv('mixolydian'), containsAll([0, 4, 7, 10]));
  });
}
