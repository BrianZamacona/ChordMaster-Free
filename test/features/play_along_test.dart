import 'dart:async';
import 'dart:typed_data';

import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/errors/failures.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/audio/pitch_detection.dart';
import 'package:chordmaster_free/domain/audio/pluck_synth.dart';
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

class _FakeAudio extends AudioService {
  _FakeAudio() : super.forTesting();

  int stops = 0;

  @override
  Future<void> playNotes(List<NoteEvent> events, {double seconds = 2.5, double? ring}) async {}

  @override
  Future<void> stopAll() async => stops++;
}

/// Un micrófono de mentira: las ventanas las pone el test.
class _FakeMic extends PitchService {
  _FakeMic({this.deny = false}) : super.forTesting();

  final bool deny;
  bool listening = false;
  // Lo cierra cada test con addTearDown.
  // ignore: close_sinks
  final windows = StreamController<MicWindow>.broadcast();

  @override
  Stream<MicWindow> get windowStream => windows.stream;

  @override
  Future<void> startListening() async {
    if (deny) throw const PermissionFailure(message: 'denied');
    listening = true;
  }

  @override
  Future<void> stopListening() async => listening = false;
}

/// Las ventanas que daría el micrófono con [tab] tocada a [bpm] (cada nota se
/// corta con la siguiente), como las arma [PitchService].
List<MicWindow> _windows(List<TabNote> tab, int bpm) {
  final step = tabStepSeconds(bpm);
  final audio = renderNotes(
    [for (final (i, n) in tab.indexed) (midi: tabMidi(n), at: 0.3 + i * step)],
    seconds: 0.3 + tab.length * step + 0.6,
    ring: step,
  );
  final half = decimateByTwo(audio);
  const size = 2048;
  return [
    for (var start = 0; start + size <= half.length; start += PitchService.hop)
      (
        samples: Float64List.sublistView(half, start, start + size),
        at: (start + size) / PitchService.sampleRate,
      ),
  ];
}

void main() {
  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<(InMemoryStore, _FakeMic, _FakeAudio)> open(
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
    final mic = _FakeMic(deny: deny);
    addTearDown(mic.windows.close);
    final audio = _FakeAudio();
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

  Future<void> feed(WidgetTester tester, _FakeMic mic, List<MicWindow> windows) async {
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

    await feed(tester, mic, _windows(step.tab, 80));
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
    for (final w in _windows([tab[0], wrong, ...tab.skip(1)], 80)) {
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
    await feed(tester, mic, _windows(notes, 100));
    expect(
      tester.widget<Text>(find.byKey(const Key('technique-record-chromatic'))).data,
      startsWith(AppStrings.techniqueRecord(100)),
    );
    expect(store.progress['technique_best_bpm'], {'chromatic': 100});
  });

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
      await feed(tester, mic, _windows([tab[0], TabNote(tab[1].string, tab[1].fret + 1)], 80));
      expect(tester.takeException(), isNull);
      for (final key in ['tab-play', 'tab-mic', 'tab-mic-status', 'tab-mic-wrong']) {
        final rect = tester.getRect(find.byKey(Key(key)));
        expect(rect.left, greaterThanOrEqualTo(0), reason: key);
        expect(rect.right, lessThanOrEqualTo(360), reason: key);
      }
    });
  }
}
