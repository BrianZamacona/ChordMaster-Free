import 'dart:io';

import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/data/repository/scale_repository.dart';
import 'package:chordmaster_free/features/hubs/hubs.dart';
import 'package:chordmaster_free/services/audio_service.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/navigation.dart';
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

  test('Aprender lo enlaza', () {
    expect([for (final e in LearnHubScreen.entries) e.route], contains('/learn/caged'));
  });

  for (final code in ['es', 'en']) {
    testWidgets('a 360 dp ($code): los cinco pasos en C, con los trastes de cada ancla y las formas', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 2000);
      addTearDown(tester.view.reset);
      appRouter.go('/');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            keyValueStoreProvider.overrideWithValue(InMemoryStore(settings: {'localeCode': code})),
            audioServiceProvider.overrideWithValue(FakeAudio()),
            scaleRepositoryProvider.overrideWithValue(ScaleRepository(bundle: _FileBundle())),
          ],
          child: const ChordMasterApp(),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
      appRouter.go('/learn/caged');
      await settle(tester);
      // chords.json se decodifica en otro isolate: hace falta tiempo real.
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
      await settle(tester);
      expect(tester.takeException(), isNull);

      String body() => tester.widget<Text>(find.byKey(const Key('caged-body'))).data!;
      expect(body(), AppStrings.cagedStepBody(0, key: 'C', six: 8, five: 3, four: 10));
      final next = find.byKey(const Key('caged-next'));
      expect(tester.getRect(next).right, lessThanOrEqualTo(360));
      await tester.tap(next);
      await tester.pump();
      expect(body(), AppStrings.cagedStepBody(1, key: 'C', six: 8, five: 3, four: 10));
      await tester.tap(next);
      await tester.pump();
      for (var i = 0; i < 20 && find.byKey(const Key('caged-shape-E-text')).evaluate().isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
        await settle(tester);
      }
      // Desde la 6ª: E y G, con la raíz en el traste 8.
      for (final s in ['E', 'G']) {
        expect(find.byKey(Key('caged-shape-$s')), findsOneWidget);
      }
      expect(
        tester.widget<Text>(find.byKey(const Key('caged-shape-E-text'))).data,
        AppStrings.cagedShapeAnchor(string: 6, fret: 8, up: true),
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('caged-shape-G-text'))).data,
        AppStrings.cagedShapeAnchor(string: 6, fret: 8, up: false),
      );
      await tester.tap(next);
      await tester.pump();
      await tester.tap(next);
      await tester.pump();
      expect(find.byKey(const Key('caged-shape-D')), findsOneWidget);
      expect(find.byKey(const Key('caged-next')), findsNothing);
      final prev = find.byKey(const Key('caged-prev'));
      expect(tester.getRect(prev).left, greaterThanOrEqualTo(0));
      expect(tester.takeException(), isNull);
    });
  }
}
