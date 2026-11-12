import 'dart:io';
import 'dart:math';

import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/data/repository/scale_repository.dart';
import 'package:chordmaster_free/domain/practice/caged_drill.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:chordmaster_free/features/caged/caged_drill_viewmodel.dart';
import 'package:chordmaster_free/features/hubs/hubs.dart';
import 'package:chordmaster_free/services/audio_service.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:chordmaster_free/ui/widgets/fretboard_diagram.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_store.dart';
import '../support/play_along_fakes.dart';

class _FileBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => throw UnimplementedError();

  @override
  Future<String> loadString(String key, {bool cache = true}) async => File(key).readAsStringSync();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> loadReal(WidgetTester tester, Finder until) async {
    for (var i = 0; i < 20 && until.evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await settle(tester);
    }
  }

  test('Practicar lo enlaza', () {
    expect([for (final e in PracticeHubScreen.entries) e.route], contains('/practice/caged'));
  });

  for (final code in ['es', 'en']) {
    testWidgets('a 360 dp ($code): escala, arpegio y acorde de lo sorteado; otra sortea de nuevo', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 1600);
      addTearDown(tester.view.reset);
      final expected = drawCaged(Random(3));
      appRouter.go('/');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            keyValueStoreProvider.overrideWithValue(InMemoryStore(settings: {'localeCode': code})),
            audioServiceProvider.overrideWithValue(FakeAudio()),
            scaleRepositoryProvider.overrideWithValue(ScaleRepository(bundle: _FileBundle())),
            cagedDrillRandomProvider.overrideWithValue(Random(3)),
          ],
          child: const ChordMasterApp(),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
      appRouter.go('/practice/caged');
      await settle(tester);
      await loadReal(tester, find.byKey(const Key('caged-drill-scale')));
      expect(tester.takeException(), isNull);

      final key = pitchClassName(expected.root);
      expect(
        tester.widget<Text>(find.byKey(const Key('caged-drill-draw'))).data,
        AppStrings.cagedDrillDraw(key, expected.shape),
      );
      // Fase 1: la escala en la forma sorteada.
      final scale = tester.widget<FretboardDiagram>(find.byKey(const Key('caged-drill-scale')));
      expect(scale.pattern.positionId, cagedPositionId(expected.shape));
      expect(scale.highlighted, isNull);
      // Fase 2: el arpegio, resaltado (tónica, 3ª mayor y 5ª).
      await tester.tap(find.byKey(const Key('caged-drill-next')));
      await tester.pump();
      final arpeggio = tester.widget<FretboardDiagram>(find.byKey(const Key('caged-drill-arpeggio')));
      final pcs = {
        for (final c in arpeggio.highlighted!) (standardOpenStringMidi[c.string - 1] + c.fret - expected.root) % 12,
      };
      expect(pcs, {0, 4, 7});
      // Fase 3: el acorde de la forma.
      await tester.tap(find.byKey(const Key('caged-drill-next')));
      await tester.pump();
      await loadReal(tester, find.byKey(const Key('caged-drill-chord')));
      expect(find.byKey(const Key('caged-drill-chord')), findsOneWidget);
      expect(find.byKey(const Key('caged-drill-next')), findsNothing);
      // Otra: vuelve a la fase 1 con otra pareja.
      final reroll = find.byKey(const Key('caged-drill-reroll'));
      expect(tester.getRect(reroll).right, lessThanOrEqualTo(360));
      await tester.tap(reroll);
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(const Key('caged-drill-draw'))).data,
        isNot(AppStrings.cagedDrillDraw(key, expected.shape)),
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('caged-drill-phase'))).data,
        AppStrings.cagedDrillPhaseOf(1, 3),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
