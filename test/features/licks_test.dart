import 'dart:io';

import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/data/repository/scale_repository.dart';
import 'package:chordmaster_free/domain/licks/lick.dart';
import 'package:chordmaster_free/domain/licks/licks.dart';
import 'package:chordmaster_free/domain/practice/tab_playback.dart';
import 'package:chordmaster_free/features/licks/licks_viewmodel.dart';
import 'package:chordmaster_free/services/audio_service.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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

  String location() => switch (appRouter.routerDelegate.currentConfiguration.last) {
    final ImperativeRouteMatch m => m.matches.uri.path,
    _ => appRouter.routerDelegate.currentConfiguration.uri.path,
  };

  Future<(FakeAudio, InMemoryStore)> open(
    WidgetTester tester,
    String path, {
    String code = 'es',
    Size size = const Size(360, 2400),
    Map<String, Object?>? progress,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final audio = FakeAudio();
    final store = InMemoryStore(settings: {'localeCode': code}, progress: progress);
    appRouter.go('/');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(store),
          audioServiceProvider.overrideWithValue(audio),
          scaleRepositoryProvider.overrideWithValue(ScaleRepository(bundle: _FileBundle())),
        ],
        child: const ChordMasterApp(),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    appRouter.go(path);
    await settle(tester);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    await settle(tester);
    return (audio, store);
  }

  for (final code in ['es', 'en']) {
    group('a 360 dp en $code', () {
      testWidgets('la biblioteca muestra cada estilo con sus frases, sin desbordar', (tester) async {
        await open(tester, '/licks', code: code, size: const Size(360, 6000));
        expect(tester.takeException(), isNull);
        for (final style in LickStyle.values) {
          expect(find.byKey(Key('licks-style-${style.name}')), findsOneWidget, reason: style.name);
        }
        for (final l in licks) {
          final card = tester.getRect(find.byKey(Key('lick-${l.id}')));
          expect(card.right, lessThanOrEqualTo(360), reason: l.id);
        }
      });

      testWidgets('el detalle cabe: tablatura, marcas y botones', (tester) async {
        await open(tester, '/licks', code: code);
        for (final l in licks) {
          appRouter.go('/licks/${l.id}');
          await settle(tester);
          expect(tester.takeException(), isNull, reason: l.id);
          final line = tester.getRect(find.byKey(const Key('lesson-tab-line-0')));
          expect(line.right, lessThanOrEqualTo(360), reason: l.id);
          expect(find.byKey(const Key('tab-mic')), findsOneWidget, reason: l.id);
        }
      });
    });
  }

  testWidgets('Inicio la abre y atrás vuelve a Inicio', (tester) async {
    await open(tester, '/', size: const Size(500, 3000));
    final tile = find.text(AppStrings.moduleLicks).first;
    await tester.ensureVisible(tile);
    await tester.pump();
    await tester.tap(tile);
    await settle(tester);
    expect(location(), '/licks');
    await tester.tap(find.byKey(Key('lick-${licks.first.id}')));
    await settle(tester);
    expect(location(), '/licks/${licks.first.id}');
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(location(), '/');
  });

  testWidgets('filtrar por nivel y tipo deja solo esas frases', (tester) async {
    await open(tester, '/licks', size: const Size(360, 6000));
    await tester.tap(find.byKey(const Key('licks-level-advanced')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('licks-kind-riff')));
    await tester.pump();
    for (final l in licks) {
      final shown = l.level.name == 'advanced' && l.kind == LickKind.riff;
      expect(find.byKey(Key('lick-${l.id}')), shown ? findsOneWidget : findsNothing, reason: l.id);
    }
    // Un estilo sin riffs avanzados se oculta.
    expect(find.byKey(const Key('licks-style-classicHardRock')), findsNothing);
  });

  testWidgets('▶ toca la frase con sus técnicas al tempo del lick', (tester) async {
    final lick = licksById['stadium_lick']!;
    final (audio, _) = await open(tester, '/licks/${lick.id}');
    final play = find.byKey(const Key('tab-play'));
    await tester.ensureVisible(play);
    await tester.pump();
    await tester.tap(play);
    await tester.pump();
    expect(audio.played.single, tabSounds(lick.tab, bpm: lick.bpm));
    await tester.tap(play);
    await tester.pump();
  });

  testWidgets('el récord guardado se muestra en la lista y en el detalle', (tester) async {
    await open(
      tester,
      '/licks',
      size: const Size(360, 6000),
      progress: {LicksViewModel.keyRecords: {'doom_riff': 75}},
    );
    final card = find.byKey(const Key('lick-doom_riff'));
    expect(
      find.descendant(of: card, matching: find.text(AppStrings.techniqueRecord(75))),
      findsOneWidget,
    );
    await tester.tap(card);
    await settle(tester);
    expect(find.text(AppStrings.techniqueRecord(75)), findsOneWidget);
  });

  test('una pasada limpia guarda el récord solo si lo supera', () async {
    final store = InMemoryStore();
    final container = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final vm = container.read(licksViewModelProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    expect(await vm.saveClean('folk_lick', 70), isTrue);
    expect(await vm.saveClean('folk_lick', 65), isFalse);
    expect(store.progress[LicksViewModel.keyRecords], {'folk_lick': 70});
  });
}
