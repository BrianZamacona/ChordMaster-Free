import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/melodies/melody_course.dart';
import 'package:chordmaster_free/domain/practice/tab_playback.dart';
import 'package:chordmaster_free/domain/practice/technique_exercises.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:chordmaster_free/features/courses/course_progress.dart';
import 'package:chordmaster_free/features/tuner/tuner_viewmodel.dart';
import 'package:chordmaster_free/services/audio_service.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/services/pitch_service.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_store.dart';
import '../support/play_along_fakes.dart';

void main() {
  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<(InMemoryStore, FakeMic, FakeAudio)> open(
    WidgetTester tester,
    String location, {
    String code = 'es',
    Size size = const Size(500, 3000),
    bool deny = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final store = InMemoryStore(settings: {'localeCode': code});
    final mic = FakeMic(deny: deny);
    addTearDown(mic.windows.close);
    final audio = FakeAudio();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(store),
          audioServiceProvider.overrideWithValue(audio),
          pitchServiceProvider.overrideWithValue(mic),
        ],
        child: const ChordMasterApp(),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    appRouter.go(location);
    await settle(tester);
    return (store, mic, audio);
  }

  Future<void> tapMic(WidgetTester tester) async {
    final button = find.byKey(const Key('tab-mic'));
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
  }

  Future<void> feed(WidgetTester tester, FakeMic mic, List<MicWindow> windows) async {
    for (final w in windows) {
      mic.windows.add(w);
      await tester.pump();
    }
  }

  String status(WidgetTester tester) => tester
      .widgetList<Text>(
        find.descendant(
          of: find.byKey(const Key('tab-mic-status')),
          matching: find.byType(Text),
          matchRoot: true,
        ),
      )
      .map((t) => t.data)
      .join(' ');

  testWidgets('tocada limpia con el micrófono: guarda el tempo medido y da sus estrellas', (
    tester,
  ) async {
    final (store, mic, audio) = await open(tester, '/learn/lessons/course/melodies/mo_first');
    final step = melodyStepsById['mo_first']!;
    expect(status(tester), AppStrings.tabMicHint);

    await tapMic(tester);
    expect(mic.listening, isTrue);
    expect(audio.stops, greaterThan(0), reason: 'nada suena mientras escucha');
    expect(status(tester), AppStrings.tabMicProgress(1, step.tab.length));

    await feed(tester, mic, micWindows(step.tab, 80));
    expect(mic.listening, isFalse, reason: 'al terminar suelta el micrófono');
    expect(status(tester), AppStrings.tabMicClean(80));
    expect(find.text(AppStrings.tabMicSaved(80)), findsOneWidget);
    expect(store.progress[CourseId.melodies.keyBest], {'mo_first': 80});
    expect(
      tester.widget<Text>(find.byKey(const Key('course-bpm'))).data,
      AppStrings.techniqueBpm(100),
      reason: 'el tempo pasa al de la próxima estrella',
    );
  });

  testWidgets('una nota equivocada se nombra y no cuenta como limpia', (tester) async {
    final (store, mic, _) = await open(tester, '/learn/lessons/course/melodies/mo_first');
    final tab = melodyStepsById['mo_first']!.tab;
    final wrong = TabNote(tab[1].string, tab[1].fret + 1);
    await tapMic(tester);

    // Sonó la equivocada: se nombra mientras se espera la correcta.
    String? shown;
    for (final w in micWindows([tab[0], wrong, ...tab.skip(1)], 80)) {
      mic.windows.add(w);
      await tester.pump();
      final message = find.byKey(const Key('tab-mic-wrong'));
      if (shown == null && message.evaluate().isNotEmpty) {
        shown = tester.widget<Text>(message).data;
        expect(status(tester), contains(AppStrings.tabMicMistakes(1)));
      }
    }
    expect(
      shown,
      AppStrings.tabMicWrong(pitchName(tabMidi(wrong)), pitchName(tabMidi(tab[1]))),
    );
    expect(status(tester), AppStrings.tabMicWithMistakes(1));
    expect(store.progress[CourseId.melodies.keyBest], isNull);
  });

  testWidgets('sin permiso del micrófono lo dice', (tester) async {
    await open(tester, '/learn/lessons/course/melodies/mo_first', deny: true);
    await tapMic(tester);
    // La consulta del permiso va por un canal de la plataforma: tiempo real.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
    expect(status(tester), AppStrings.tabMicDenied);
  });

  testWidgets('"Detener" suelta el micrófono y vuelve al inicio', (tester) async {
    final (_, mic, _) = await open(tester, '/learn/lessons/course/melodies/mo_first');
    await tapMic(tester);
    expect(mic.listening, isTrue);
    await tapMic(tester);
    await tester.pump();
    expect(mic.listening, isFalse);
    expect(status(tester), AppStrings.tabMicHint);
  });

  testWidgets('salir del paso suelta el micrófono', (tester) async {
    final (_, mic, _) = await open(tester, '/learn/lessons/course/melodies/mo_first');
    await tapMic(tester);
    expect(mic.listening, isTrue);
    appRouter.go('/learn/lessons');
    await settle(tester);
    expect(mic.listening, isFalse);
  });

  testWidgets('Técnica: una pasada limpia con el micrófono es récord', (tester) async {
    final (store, mic, _) = await open(tester, '/practice/technique', size: const Size(500, 4000));
    final card = find.byKey(const Key('technique-chromatic'));
    final button = find.descendant(of: card, matching: find.byKey(const Key('tab-mic')));
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
    final notes = techniqueNotes(TechniqueExercise.chromatic, startFret: techniqueStartFrets.first);
    await feed(tester, mic, micWindows(notes, 100));
    expect(
      tester.widget<Text>(find.byKey(const Key('technique-record-chromatic'))).data,
      startsWith(AppStrings.techniqueRecord(100)),
    );
    expect(store.progress['technique_best_bpm'], {'chromatic': 100});
  });

  group('tramo, bucle y más lento', () {
    Future<void> tapKey(WidgetTester tester, String key) async {
      final f = find.byKey(Key(key));
      await tester.ensureVisible(f);
      await tester.pump();
      await tester.tap(f);
      await tester.pump();
    }

    testWidgets('un renglón suena solo: sus notas y nada más', (tester) async {
      final (_, _, audio) = await open(tester, '/learn/lessons/course/melodies/mo_ode');
      final tab = melodyStepsById['mo_ode']!.tab;
      expect(tabLineCount(tab.length), 4);
      for (var i = 0; i < 4; i++) {
        expect(find.byKey(Key('tab-line-$i')), findsOneWidget);
      }
      await tapKey(tester, 'tab-line-1');
      await tapKey(tester, 'tab-play');
      expect(audio.played.single.map((e) => e.midi), [for (final n in tab.sublist(8, 16)) tabMidi(n)]);
      await tapKey(tester, 'tab-play');
    });

    testWidgets('en bucle vuelve a sonar al terminar el tramo', (tester) async {
      final (_, _, audio) = await open(tester, '/learn/lessons/course/melodies/mo_first');
      await tapKey(tester, 'tab-line-1');
      await tapKey(tester, 'tab-loop');
      await tapKey(tester, 'tab-play');
      // El renglón 2 de mo_first tiene 2 notas: a 60 BPM, 1 s. El reloj del
      // reproductor es real.
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1100)));
      await tester.pump(const Duration(milliseconds: 40));
      expect(audio.played, hasLength(2));
      await tapKey(tester, 'tab-play');
    });

    testWidgets('un renglón tocado con el micrófono no da récord', (tester) async {
      final (store, mic, _) = await open(tester, '/learn/lessons/course/melodies/mo_ode');
      final tab = melodyStepsById['mo_ode']!.tab;
      await tapKey(tester, 'tab-line-1');
      await tapKey(tester, 'tab-mic');
      expect(status(tester), AppStrings.tabMicProgress(1, 8));
      await feed(tester, mic, micWindows(tab.sublist(8, 16), 80));
      // Con 8 notas la medida da 80 u 81.
      expect(status(tester), anyOf(AppStrings.tabMicClean(80), AppStrings.tabMicClean(81)));
      expect(find.byKey(const Key('tab-line-no-record')), findsOneWidget);
      expect(store.progress[CourseId.melodies.keyBest], isNull);
    });

    testWidgets('con errores propone repetir ese renglón más lento, y lo deja en bucle', (
      tester,
    ) async {
      final (_, mic, audio) = await open(tester, '/learn/lessons/course/melodies/mo_first');
      final tab = melodyStepsById['mo_first']!.tab;
      final wrong = TabNote(tab[9].string, tab[9].fret + 1);
      await tapKey(tester, 'tab-mic');
      await feed(tester, mic, micWindows([...tab.take(9), wrong, tab[9]], 80));
      final practice = find.byKey(const Key('tab-practice-line'));
      expect(find.descendant(of: practice, matching: find.text(AppStrings.tabPracticeLine(2, 50))),
          findsOneWidget);
      await tapKey(tester, 'tab-practice-line');
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(const Key('course-bpm'))).data,
        AppStrings.techniqueBpm(50),
      );
      expect(tester.widget<ChoiceChip>(find.byKey(const Key('tab-line-1'))).selected, isTrue);
      expect(tester.widget<FilterChip>(find.byKey(const Key('tab-loop'))).selected, isTrue);
      expect(audio.played.last.map((e) => e.midi), [for (final n in tab.sublist(8)) tabMidi(n)]);
      await tapKey(tester, 'tab-play');
    });

    testWidgets('en bucle con el micrófono vuelve a escuchar y cuenta las pasadas limpias', (
      tester,
    ) async {
      final (_, mic, _) = await open(tester, '/learn/lessons/course/melodies/mo_first');
      final tab = melodyStepsById['mo_first']!.tab;
      await tapKey(tester, 'tab-line-0');
      await tapKey(tester, 'tab-loop');
      await tapKey(tester, 'tab-mic');
      await feed(tester, mic, micWindows(tab.sublist(0, 8), 80));
      expect(find.text(AppStrings.tabCleanStreak(1)), findsOneWidget);
      expect(mic.listening, isFalse);
      await tester.pump(const Duration(milliseconds: 1600));
      expect(mic.listening, isTrue, reason: 'vuelve a escuchar solo');
      expect(status(tester), AppStrings.tabMicProgress(1, 8));
      await tapKey(tester, 'tab-mic');
    });

    testWidgets('Técnica: "más lento" baja el tempo del ejercicio', (tester) async {
      final (_, mic, _) = await open(tester, '/practice/technique', size: const Size(500, 4000));
      final card = find.byKey(const Key('technique-chromatic'));
      Finder inCard(String key) => find.descendant(of: card, matching: find.byKey(Key(key)));
      final notes = techniqueNotes(TechniqueExercise.chromatic, startFret: techniqueStartFrets.first);
      await tester.ensureVisible(inCard('tab-mic'));
      await tester.pump();
      await tester.tap(inCard('tab-mic'));
      await tester.pump();
      final wrong = TabNote(notes[0].string, notes[0].fret + 1);
      await feed(tester, mic, micWindows([wrong, ...notes], 100));
      await tester.ensureVisible(inCard('tab-practice-line'));
      await tester.pump();
      await tester.tap(inCard('tab-practice-line'));
      await tester.pump();
      expect(
        find.descendant(of: card, matching: find.text(AppStrings.tabAtBpm(techniqueDefaultBpm - 10))),
        findsOneWidget,
      );
      await tester.tap(inCard('tab-play'));
      await tester.pump();
    });
  });

  for (final code in ['es', 'en']) {
    testWidgets('a 360 dp ($code) el tramo, el bucle y "repite el renglón" caben', (tester) async {
      final (_, mic, _) = await open(
        tester,
        '/learn/lessons/course/melodies/mo_ode',
        code: code,
        size: const Size(360, 3000),
      );
      final tab = melodyStepsById['mo_ode']!.tab;
      final button = find.byKey(const Key('tab-mic'));
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
      final wrong = TabNote(tab[20].string, tab[20].fret + 1);
      await feed(tester, mic, micWindows([...tab.take(20), wrong, ...tab.skip(20)], 80));
      expect(tester.takeException(), isNull);
      for (final key in ['tab-sections', 'tab-loop', 'tab-line-3', 'tab-practice-line']) {
        final rect = tester.getRect(find.byKey(Key(key)));
        expect(rect.left, greaterThanOrEqualTo(0), reason: key);
        expect(rect.right, lessThanOrEqualTo(360), reason: key);
      }
    });
  }
  for (final code in ['es', 'en']) {
    testWidgets('a 360 dp ($code) los botones y el estado caben', (tester) async {
      final (_, mic, _) = await open(
        tester,
        '/learn/lessons/course/melodies/mo_first',
        code: code,
        size: const Size(360, 3000),
      );
      final tab = melodyStepsById['mo_first']!.tab;
      await tapMic(tester);
      await feed(tester, mic, micWindows([tab[0], TabNote(tab[1].string, tab[1].fret + 1)], 80));
      expect(tester.takeException(), isNull);
      for (final key in ['tab-play', 'tab-mic', 'tab-mic-status', 'tab-mic-wrong']) {
        final rect = tester.getRect(find.byKey(Key(key)));
        expect(rect.left, greaterThanOrEqualTo(0), reason: key);
        expect(rect.right, lessThanOrEqualTo(360), reason: key);
      }
    });
  }
}
