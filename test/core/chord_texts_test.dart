import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/constants/chord_metadata.dart';
import 'package:chordmaster_free/core/constants/chord_texts.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  final chords =
      (jsonDecode(File('assets/data/chords.json').readAsStringSync())
              as List<dynamic>)
          .cast<Map<String, dynamic>>();

  test('cada tipo, estilo y texto del explorador de chords.json tiene traducción', () {
    final missing = <String>{};
    for (final c in chords) {
      if (!chordTypeNames.containsKey(c['type'])) missing.add('tipo ${c['type']}');
      if (!chordTypeDescriptions.containsKey(c['type'])) {
        missing.add('descripción ${c['type']}');
      }
      for (final tag in (c['tags'] as List<dynamic>? ?? const [])) {
        if (!chordTagNames.containsKey(tag)) missing.add('estilo $tag');
      }
      for (final f in ['cagedPositions', 'voicings', 'triadInversions', 'advancedInversions']) {
        for (final item in (c[f] as List<dynamic>? ?? const [])) {
          final m = item as Map<String, dynamic>;
          for (final k in ['title', 'shape', 'description']) {
            final text = m[k] as String?;
            // Las formas CAGED son letras (C, A, G...): no se traducen.
            if (text != null && text.length > 1 && !chordDataSpanish.containsKey(text)) {
              missing.add(text);
            }
          }
        }
      }
    }
    expect(missing, isEmpty);
  });

  test('etiquetas siguen al idioma', () {
    expect(chordTypeLabel('minor7'), 'Menor séptima');
    expect(chordTagLabel('standard'), 'Todo uso');
    expect(chordDataText('C Form'), 'Forma C');
    CurrentLanguage.value = AppLanguage.en;
    expect(chordTypeLabel('minor7'), 'Minor 7th');
    expect(chordDescription('major', 'ignored'), 'Bright, stable major triad.');
    expect(chordDataText('C Form'), 'C Form');
  });

  test('calidades de intervalo de double stops en inglés', () {
    expect(AppStrings.intervalQualityLabel('3ª mayor'), '3ª mayor');
    CurrentLanguage.value = AppLanguage.en;
    expect(AppStrings.intervalQualityLabel('3ª mayor'), 'major 3rd');
    expect(AppStrings.intervalQualityLabel('4ª aumentada'), 'augmented 4th');
    expect(AppStrings.intervalQualityLabel('5ª disminuida'), 'diminished 5th');
    expect(AppStrings.intervalQualityLabel('7ª menor'), 'minor 7th');
  });
}
