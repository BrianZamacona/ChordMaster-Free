import 'dart:io';

import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/constants/scale_names.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/data/repository/scale_repository.dart';
import 'package:chordmaster_free/ui/scales/scales_screen.dart';
import 'package:chordmaster_free/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FileBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => throw UnimplementedError();

  @override
  Future<String> loadString(String key, {bool cache = true}) async => File(key).readAsStringSync();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  for (final lang in AppLanguage.values) {
    testWidgets('a 360 dp (${lang.name}): los modos de la melódica y de la armónica, cada uno en su sección', (
      tester,
    ) async {
      CurrentLanguage.value = lang;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 780);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [scaleRepositoryProvider.overrideWithValue(ScaleRepository(bundle: _FileBundle()))],
          child: MaterialApp(theme: lightTheme, home: const ScalesScreen()),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      Future<double> topOf(Finder f) async {
        await tester.scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first);
        return tester.getTopLeft(f).dy;
      }

      // Las secciones van en orden: modos de la mayor, de la melódica, de la armónica.
      final melodic = find.text(scaleCategoryName('Modo de la melódica'));
      final harmonic = find.text(scaleCategoryName('Modo de la armónica'));
      expect(await topOf(find.text(AppStrings.scaleModes)), isNotNull);
      final dorianB2 = await topOf(find.byKey(const Key('scale-dorian_b2')));
      expect(await topOf(melodic), lessThan(dorianB2));
      expect(find.text(AppStrings.scaleModesMelodicNote), findsOneWidget);
      await topOf(find.byKey(const Key('scale-altered')));
      expect(find.text(scaleDisplayName('altered', const [0, 1, 3, 4, 6, 8, 10])), findsOneWidget);
      final h = await topOf(harmonic);
      expect(find.text(AppStrings.scaleModesHarmonicNote), findsOneWidget);
      // La frigia dominante es el 5º modo de la armónica: va en esa sección.
      expect(await topOf(find.byKey(const Key('scale-phrygian_dominant'))), greaterThan(h));
      await topOf(find.byKey(const Key('scale-super_locrian_bb7')));
      expect(tester.takeException(), isNull);
    });
  }
}
