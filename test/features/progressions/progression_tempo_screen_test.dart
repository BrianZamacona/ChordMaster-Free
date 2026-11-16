import 'dart:io';

import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/data/repository/scale_repository.dart';
import 'package:chordmaster_free/domain/progressions/custom_progression.dart';
import 'package:chordmaster_free/domain/progressions/progression_data.dart';
import 'package:chordmaster_free/domain/progressions/progression_playback.dart';
import 'package:chordmaster_free/domain/progressions/song.dart';
import 'package:chordmaster_free/features/progressions/progressions_screen.dart';
import 'package:chordmaster_free/features/progressions/progressions_viewmodel.dart';
import 'package:chordmaster_free/services/audio_service.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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

  String location() => switch (appRouter.routerDelegate.currentConfiguration.last) {
    final ImperativeRouteMatch m => m.matches.uri.path,
    _ => appRouter.routerDelegate.currentConfiguration.uri.path,
  };

  late FakeAudio audio;

  Future<void> open(WidgetTester tester, String code) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 2400);
    addTearDown(tester.view.reset);
    appRouter.go('/');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(InMemoryStore(settings: {'localeCode': code})),
          audioServiceProvider.overrideWithValue(audio = FakeAudio()),
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
  }

  for (final code in ['es', 'en']) {
    testWidgets('a 360 dp ($code): tempo y bucle caben y el tempo cambia de 5 en 5', (tester) async {
      await open(tester, code);
      expect(tester.takeException(), isNull);
      for (final k in [
        'progression-listen',
        'progression-bpm-down',
        'progression-bpm',
        'progression-bpm-up',
        'progression-loop',
        for (var i = 0; i < 5; i++) 'progression-pattern-$i',
        'progression-pattern-view',
      ]) {
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
  
    testWidgets('a 360 dp ($code): Mi progresión con 7ª cabe en cada escala de base y cada fuente', (tester) async {
      await open(tester, code);
      final container = ProviderScope.containerOf(tester.element(find.byType(ProgressionsContent)));
      final vm = container.read(progressionsViewModelProvider.notifier)
        ..setProgression(customProgressionId)
        ..setCustomSevenths(sevenths: true);
      // Ocho acordes, uno de cada duración: sus chips y la hoja caben.
      for (var i = 0; i < customProgressionMax; i++) {
        vm
          ..addCustomDegree('viiø7')
          ..setCustomBeats(i, customChordBeats[i % customChordBeats.length]);
      }
      await settle(tester);
      for (var i = 0; i < customProgressionMax; i++) {
        expect(tester.getRect(find.byKey(Key('custom-$i'))).right, lessThanOrEqualTo(360), reason: 'custom-$i');
      }
      await tester.tap(find.byKey(const Key('custom-7')));
      await settle(tester);
      for (final b in customChordBeats) {
        expect(tester.getRect(find.byKey(Key('custom-beats-$b'))).right, lessThanOrEqualTo(360));
      }
      for (final k in ['custom-duplicate', 'custom-copy']) {
        expect(tester.getRect(find.byKey(Key(k))).right, lessThanOrEqualTo(360), reason: k);
      }
      // La hoja va por encima de la barra de pestañas (no detrás): con ella
      // abierta, la barra no recibe el toque.
      final bar = find.byType(NavigationBar);
      final hit = tester.hitTestOnBinding(tester.getCenter(bar));
      expect(hit.path.any((e) => e.target == tester.renderObject(bar)), isFalse);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('custom-beats-1')));
      await settle(tester);
      // La ventana de guardar: el aviso entero, en su propio texto.
      await tester.ensureVisible(find.byKey(const Key('custom-save')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('custom-save')));
      await settle(tester);
      final hint = find.byKey(const Key('custom-save-hint'));
      expect(tester.widget<Text>(hint).data, AppStrings.saveProgressionHint);
      expect(tester.widget<Text>(hint).maxLines, isNull);
      expect(tester.getRect(hint).right, lessThanOrEqualTo(360));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(AppStrings.cancel));
      await settle(tester);
      // Guardar, con el nombre largo de la hoja de "Mis progresiones".
      vm
        ..copyCustom(0)
        ..saveCustomAs('Progresión de práctica con un nombre largo');
      await settle(tester);
      for (final k in ['custom-save', 'custom-saved', 'custom-paste']) {
        final f = find.byKey(Key(k));
        await tester.ensureVisible(f);
        await settle(tester);
        expect(tester.getRect(f).right, lessThanOrEqualTo(360), reason: k);
      }
      await tester.ensureVisible(find.byKey(const Key('custom-saved')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('custom-saved')));
      await settle(tester);
      expect(tester.getRect(find.byKey(const Key('saved-delete-0'))).right, lessThanOrEqualTo(360));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('saved-0')));
      await settle(tester);
      for (final mode in customBaseModes) {
        vm.setCustomMode(mode);
        await settle(tester);
        expect(tester.takeException(), isNull, reason: '$mode');
        for (final k in ['custom-mode', 'custom-sevenths']) {
          expect(tester.getRect(find.byKey(Key(k))).right, lessThanOrEqualTo(360), reason: '$k ($mode)');
        }
        for (final source in ChordSource.values) {
          vm.setCustomSource(source);
          await settle(tester);
          expect(tester.takeException(), isNull, reason: '$source $mode');
          for (final k in ['custom-source-${source.name}', 'custom-source-hint']) {
            expect(tester.getRect(find.byKey(Key(k))).right, lessThanOrEqualTo(360), reason: k);
          }
          for (final c in chordsFrom(source, mode, sevenths: true)) {
            final chip = find.byKey(Key('add-degree-${c.degree.numeral}'));
            expect(chip, findsOneWidget, reason: '${c.label} ($source $mode)');
            expect(tester.getRect(chip).right, lessThanOrEqualTo(360), reason: c.label);
          }
        }
      }
    });

    testWidgets('a 360 dp ($code): secciones y orden de la canción, y escucharla entera', (tester) async {
      await open(tester, code);
      final container = ProviderScope.containerOf(tester.element(find.byType(ProgressionsContent)));
      final vm = container.read(progressionsViewModelProvider.notifier)
        ..setProgression(customProgressionId)
        ..addCustomDegree('I')
        ..addCustomDegree('V');
      await settle(tester);
      // Sin canción: no hay orden ni elección de qué escuchar.
      expect(find.byKey(const Key('song-part-0')), findsNothing);
      expect(find.byKey(const Key('listen-scope')), findsNothing);

      await tester.tap(find.byKey(const Key('custom-section-add')));
      await settle(tester);
      vm
        ..addCustomDegree('IV')
        ..addCustomDegree('I')
        ..addPart(0)
        ..addSection()
        ..addSection();
      await settle(tester);
      expect(tester.takeException(), isNull);
      final state = container.read(progressionsViewModelProvider);
      expect(state.order, [0, 1, 0, 2, 3]);
      for (final k in [
        for (var i = 0; i < songMaxSections; i++) 'custom-section-$i',
        'custom-section-remove',
        for (var i = 0; i < state.order.length; i++) 'song-part-$i',
        for (var i = 0; i < songMaxSections; i++) 'song-add-$i',
      ]) {
        final f = find.byKey(Key(k));
        await tester.ensureVisible(f);
        await settle(tester);
        expect(tester.getRect(f).right, lessThanOrEqualTo(360), reason: k);
      }
      // Sin las vacías (C y D), la canción es A B A.
      vm
        ..removeSection(3)
        ..removeSection(2)
        ..selectSection(0);
      await settle(tester);
      final listen = find.byKey(const Key('progression-listen'));
      for (var i = 0; i < 20 && listen.evaluate().isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
        await settle(tester);
      }
      final scope = find.byKey(const Key('listen-scope'));
      await tester.ensureVisible(scope);
      await settle(tester);
      expect(tester.getRect(scope).right, lessThanOrEqualTo(360));
      await tester.tap(find.text(AppStrings.songListenWhole));
      await settle(tester);
      await tester.ensureVisible(listen);
      await tester.tap(listen);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await settle(tester);
      // Suenan las tres partes: A (2 acordes), B (2) y A otra vez, cuatro golpes cada uno.
      final bpm = container.read(progressionsViewModelProvider).bpm;
      final strokes = {for (final x in audio.played.last) (x.at * bpm / 60).round()};
      expect(strokes.length, 6 * 4);
      expect(find.byKey(const Key('song-now')), findsOneWidget);
      expect(find.text(AppStrings.songNowPlaying(1, 3, 'A')), findsOneWidget);
      expect(tester.takeException(), isNull);
      // La canción sigue sonando en cada parte, hasta el final (A, B, A: 6 acordes
      // de un compás; a 80 BPM, 3 s cada uno).
      for (final (seconds, part, letter) in [(7, 2, 'B'), (6, 3, 'A')]) {
        for (var i = 0; i < seconds * 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.text(AppStrings.songNowPlaying(part, 3, letter)), findsOneWidget, reason: 'parte $part');
        expect(container.read(progressionsViewModelProvider).playingIndex, isNotNull, reason: 'parte $part');
      }
      await tester.tap(listen);
      await settle(tester);
    });

    testWidgets('a 360 dp ($code): cada acorde en el mástil, dentro de la escala', (tester) async {
      await open(tester, code);
      // I–V–vi–IV en C: cabe la mayor, y el primero que se ve es C.
      final hint = find.byKey(const Key('chord-on-neck-hint'));
      await tester.ensureVisible(hint);
      await settle(tester);
      expect(tester.widget<Text>(hint).data, contains('C (C E G)'));
      for (var i = 0; i < 4; i++) {
        final chip = find.byKey(Key('chord-on-neck-$i'));
        expect(tester.getRect(chip).right, lessThanOrEqualTo(360), reason: 'chip $i');
      }
      await tester.tap(find.byKey(const Key('chord-on-neck-1')));
      await settle(tester);
      expect(tester.widget<Text>(hint).data, contains('G (G B D)'));
      final neck = find.byKey(const ValueKey('chord-on-neck-V'));
      expect(neck, findsOneWidget);
      expect(tester.getRect(neck).right, lessThanOrEqualTo(360));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a 360 dp ($code): la lista se agrupa por familia y el blues trae sus 12 compases', (tester) async {
      await open(tester, code);
      await tester.tap(find.byKey(const Key('progression-pick')));
      await settle(tester);
      for (final kind in ProgressionKind.values) {
        final header = find.byKey(Key('progression-kind-${kind.name}'));
        await tester.scrollUntilVisible(header, 200, scrollable: find.byType(Scrollable).last);
        expect(tester.getRect(header).right, lessThanOrEqualTo(360), reason: kind.name);
      }
      final blues = find.byKey(const Key('progression-blues-12'));
      await tester.scrollUntilVisible(blues, 200, scrollable: find.byType(Scrollable).last);
      await tester.tap(blues);
      await settle(tester);
      for (var i = 0; i < 20 && find.text('C7').evaluate().isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
        await settle(tester);
      }
      expect(tester.takeException(), isNull);
      final name = progressions.firstWhere((p) => p.id == 'blues-12').name!.text;
      expect(find.textContaining(name), findsOneWidget);
      // En C: siete compases de C7, tres de F7 y dos de G7.
      expect(find.text('C7'), findsNWidgets(7));
    });

    testWidgets('a 360 dp ($code): «qué tocar encima» abre la escala en la tónica y atrás vuelve', (tester) async {
      await open(tester, code);
      final card = find.byKey(const Key('progression-play-over'));
      await tester.scrollUntilVisible(card, 300, scrollable: find.byType(Scrollable).first);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await settle(tester);
      expect(tester.getRect(card).right, lessThanOrEqualTo(360));
      final major = find.byKey(const Key('play-over-major'));
      expect(major, findsOneWidget);
      expect(find.byKey(const Key('play-over-pentatonic_major')), findsOneWidget);
      // I–V–vi–IV en C: el V es G B D.
      expect(tester.widget<Text>(find.byKey(const Key('play-over-arpeggio-V'))).data, startsWith('G: G B D'));
      await tester.ensureVisible(major);
      await tester.pump();
      await tester.tap(major);
      await settle(tester);
      expect(location(), '/scales/major');
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(location(), '/progressions');
    });
}
}
