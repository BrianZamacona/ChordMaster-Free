import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/audio/pluck_synth.dart';
import 'package:chordmaster_free/domain/practice/technique_exercises.dart';
import 'package:chordmaster_free/features/technique/technique_screen.dart';
import 'package:chordmaster_free/features/technique/technique_viewmodel.dart';
import 'package:chordmaster_free/services/audio_service.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_store.dart';

/// Registra lo que se pidió sonar, sin reproducir nada.
class _FakeAudio extends AudioService {
  _FakeAudio() : super.forTesting();

  final played = <List<NoteEvent>>[];

  @override
  Future<void> playNotes(
    List<NoteEvent> events, {
    double seconds = 2.5,
    double? ring,
  }) async =>
      played.add(events);

  @override
  Future<void> stopAll() async {}
}

void main() {
  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<(InMemoryStore, _FakeAudio)> open(
    WidgetTester tester, {
    String code = 'es',
    Size size = const Size(500, 3000),
    Map<String, Object?>? progress,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final store = InMemoryStore(settings: {'localeCode': code}, progress: progress);
    final audio = _FakeAudio();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(store),
          audioServiceProvider.overrideWithValue(audio),
        ],
        child: const ChordMasterApp(),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    appRouter.go('/practice/technique');
    await settle(tester);
    return (store, audio);
  }

  testWidgets('Practicar enlaza Técnica', (tester) async {
    await open(tester);
    appRouter.go('/practice');
    await settle(tester);
    await tester.tap(find.text(AppStrings.hubTechnique));
    await settle(tester);
    expect(find.byType(TechniqueScreen), findsOneWidget);
  });

  testWidgets('los cuatro ejercicios, y Escuchar toca el que se ve', (tester) async {
    final (_, audio) = await open(tester);
    for (final e in TechniqueExercise.values) {
      expect(find.byKey(Key('technique-${e.name}'), skipOffstage: false), findsOneWidget);
    }
    final play = find.descendant(
      of: find.byKey(const Key('technique-chromatic')),
      matching: find.byKey(const Key('tab-play')),
    );
    await tester.tap(play);
    await tester.pump();
    expect(audio.played.single, hasLength(48));
    await tester.tap(play);
    await tester.pump();
  });

  testWidgets('el tempo sube y baja de 5 en 5', (tester) async {
    await open(tester);
    String bpm() => tester.widget<Text>(find.byKey(const Key('technique-bpm'))).data!;
    expect(bpm(), AppStrings.techniqueBpm(techniqueDefaultBpm));
    await tester.tap(find.byKey(const Key('technique-faster')));
    await tester.pump();
    expect(bpm(), AppStrings.techniqueBpm(techniqueDefaultBpm + 5));
    await tester.tap(find.byKey(const Key('technique-slower')));
    await tester.tap(find.byKey(const Key('technique-slower')));
    await tester.pump();
    expect(bpm(), AppStrings.techniqueBpm(techniqueDefaultBpm - 5));
  });

  testWidgets('"Me salió limpio" guarda el récord y propone 5 más', (tester) async {
    final (store, _) = await open(tester);
    await tester.tap(find.byKey(const Key('technique-faster')));
    await tester.pump();
    final clean = find.byKey(const Key('technique-clean-spider'));
    await tester.ensureVisible(clean);
    await tester.pump();
    await tester.tap(clean);
    await tester.pump();
    expect(store.progress[TechniqueViewModel.keyRecords], {'spider': 65});
    expect(
      find.text(
        '${AppStrings.techniqueRecord(65)} · ${AppStrings.techniqueTryNext(70)}',
      ),
      findsOneWidget,
    );
    // Al mismo tempo no hay nada que superar.
    expect(tester.widget<TextButton>(clean).onPressed, isNull);
  });

  testWidgets('lee los récords guardados', (tester) async {
    await open(tester, progress: {
      TechniqueViewModel.keyRecords: {'diagonal': 90},
    });
    expect(
      find.text(
        '${AppStrings.techniqueRecord(90)} · ${AppStrings.techniqueTryNext(95)}',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });

  testWidgets('cambiar el traste de inicio mueve la tablatura', (tester) async {
    final (_, audio) = await open(tester);
    await tester.tap(find.text('5').first);
    await tester.pump();
    final play = find.descendant(
      of: find.byKey(const Key('technique-chromatic')),
      matching: find.byKey(const Key('tab-play')),
    );
    await tester.tap(play);
    await tester.pump();
    // Primera nota: 6ª cuerda (mi grave, MIDI 40) en el traste 5 = La (45).
    expect(audio.played.single.first.midi, 45);
    await tester.tap(play);
    await tester.pump();
  });

  for (final code in ['es', 'en']) {
    testWidgets('a 360 dp ($code) sin desbordes', (tester) async {
      await open(tester, code: code, size: const Size(360, 4000), progress: {
        TechniqueViewModel.keyRecords: {'chromatic': 120},
      });
      expect(tester.takeException(), isNull);
    });
  }
}
