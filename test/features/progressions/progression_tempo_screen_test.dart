import 'dart:io';

import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/data/repository/scale_repository.dart';
import 'package:chordmaster_free/domain/progressions/progression_playback.dart';
import 'package:chordmaster_free/services/audio_service.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/in_memory_store.dart';
import '../../support/play_along_fakes.dart';

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

  for (final code in ['es', 'en']) {
    testWidgets('a 360 dp ($code): tempo y bucle caben y el tempo cambia de 5 en 5', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 2400);
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
      appRouter.go('/progressions');
      await settle(tester);
      // chords.json se decodifica en otro isolate y el camino se arma después:
      // hace falta tiempo real.
      for (var i = 0; i < 20 && find.byKey(const Key('progression-listen')).evaluate().isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
        await settle(tester);
      }

      expect(tester.takeException(), isNull);
      for (final k in ['progression-listen', 'progression-bpm-down', 'progression-bpm', 'progression-bpm-up', 'progression-loop']) {
        final f = find.byKey(Key(k));
        expect(f, findsOneWidget, reason: k);
        expect(tester.getRect(f).right, lessThanOrEqualTo(360), reason: k);
      }
      final bpm = find.byKey(const Key('progression-bpm'));
      expect(tester.widget<Text>(bpm).data, AppStrings.progressionBpm(progressionDefaultBpm));
      await tester.tap(find.byKey(const Key('progression-bpm-up')));
      await tester.pump();
      expect(tester.widget<Text>(bpm).data, AppStrings.progressionBpm(progressionDefaultBpm + 5));
      await tester.tap(find.byKey(const Key('progression-loop')));
      await tester.pump();
      expect(tester.widget<FilterChip>(find.byKey(const Key('progression-loop'))).selected, isTrue);
      expect(find.text(AppStrings.progressionBarPerChord), findsOneWidget);
    });
  }
}
