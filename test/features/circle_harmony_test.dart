import 'dart:io';

import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/data/repository/scale_repository.dart';
import 'package:chordmaster_free/domain/theory/circle_harmony.dart';
import 'package:chordmaster_free/domain/theory/circle_of_fifths.dart';
import 'package:chordmaster_free/features/chords/chord_viewmodel.dart';
import 'package:chordmaster_free/features/circle/circle_harmony_screen.dart';
import 'package:chordmaster_free/features/circle/circle_harmony_viewmodel.dart';
import 'package:chordmaster_free/services/audio_service.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:chordmaster_free/ui/scales/detail/scale_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/chord_data.dart';
import '../support/in_memory_store.dart';
import '../support/play_along_fakes.dart';

class _FileBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => throw UnimplementedError();

  @override
  Future<String> loadString(String key, {bool cache = true}) async => File(key).readAsStringSync();
}

void main() {
  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<FakeAudio> open(WidgetTester tester, {String code = 'es', Size size = const Size(360, 5200)}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final audio = FakeAudio();
    appRouter.go('/');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(InMemoryStore(settings: {'localeCode': code})),
          audioServiceProvider.overrideWithValue(audio),
          scaleRepositoryProvider.overrideWithValue(ScaleRepository(bundle: _FileBundle())),
        ],
        child: const ChordMasterApp(),
      ),
    );
    // chords.json se decodifica en otro isolate y scales_master.json se lee: tiempo real.
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    appRouter.go('/circle');
    await settle(tester);
    await tester.tap(find.byKey(const Key('circle-open-harmony')));
    await settle(tester);
    // chords.json se decodifica en otro isolate: se espera a que esté.
    final container = ProviderScope.containerOf(tester.element(find.byType(CircleHarmonyScreen)));
    for (var i = 0; i < 40; i++) {
      if (container.read(chordViewModelProvider).allChords.isNotEmpty) break;
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
    }
    await settle(tester);
    return audio;
  }

  test('todos los acordes que suenan existen en chords.json, en las 12 tonalidades', () {
    final names = {for (final c in loadChordJson()) c['displayName'] as String};
    for (var t = 0; t < 12; t++) {
      final chords = [
        for (final s in secondaryDominants(t)) ...[s.dominant, s.target],
        ...dominantChain(t),
        ...twoFiveOne(t),
        ...borrowedChords(t),
        for (var to = 0; to < 12; to++)
          for (final p in modulation(t, to).pivots) (numeral: '', root: p.root, type: p.type),
      ];
      for (final c in chords) {
        expect(names, contains(circleChordName(c)), reason: '$t ${c.numeral}');
      }
    }
  });

  testWidgets('el círculo la abre con las cuatro tarjetas de su tonalidad', (tester) async {
    await open(tester);
    expect(find.text(AppStrings.circleHarmonyTitle), findsWidgets);
    for (final k in ['secondary', 'modulation', 'borrow', 'modes']) {
      expect(find.byKey(Key('harmony-$k')), findsOneWidget, reason: k);
    }
    // En C: A7 → Dm.
    expect(find.text(AppStrings.circleSecondaryRow('A7', 'Dm')), findsOneWidget);
  });

  testWidgets('la cadena suena con sus cinco acordes; modular a D cambia los pivotes', (tester) async {
    final audio = await open(tester);
    await tester.tap(find.byKey(const Key('harmony-chain')));
    await tester.pump();
    final starts = {for (final s in audio.played.single) (s.at * 10).round()};
    expect(starts.length, greaterThanOrEqualTo(5));
    await tester.tap(find.byKey(const Key('harmony-to-2')));
    await tester.pump();
    expect(find.text(AppStrings.circleModulationSteps(circleStep(0, 2))), findsOneWidget);
    expect(find.byKey(const Key('harmony-pivot-I')), findsNothing); // C no está en D.
    expect(find.byKey(const Key('harmony-pivot-iii')), findsOneWidget); // Em = ii de D.
  });

  testWidgets('un modo abre su escala en la tónica', (tester) async {
    await open(tester);
    final tile = find.byKey(const Key('harmony-mode-dorian'));
    await tester.ensureVisible(tile);
    await tester.pump();
    await tester.tap(tile);
    await settle(tester);
    expect(find.byType(ScaleDetailScreen), findsOneWidget);
  });

  for (final code in ['es', 'en']) {
    testWidgets('a 360 dp ($code) las 12 tonalidades sin desbordes', (tester) async {
      await open(tester, code: code);
      for (final t in circleOrder) {
        final chip = find.byKey(Key('harmony-key-$t'));
        await tester.ensureVisible(chip);
        await tester.pump();
        await tester.tap(chip);
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$t');
      }
    });
  }
}
