import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/licks/licks.dart';
import 'package:chordmaster_free/domain/melodies/melody_course.dart';
import 'package:chordmaster_free/domain/practice/multi_day_challenges.dart';
import 'package:chordmaster_free/domain/practice/session_summary.dart';
import 'package:chordmaster_free/features/tuner/tuner_viewmodel.dart';
import 'package:chordmaster_free/services/audio_service.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/services/session_log.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_store.dart';
import '../support/play_along_fakes.dart';

void main() {
  final today = DateTime(2026, 11, 8, 10);
  setUp(() => SessionLog.now = () => today);
  tearDown(() {
    CurrentLanguage.value = AppLanguage.es;
    SessionLog.now = DateTime.now;
  });

  const odeKey = 'course:melodies:mo_first';

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<(InMemoryStore, FakeMic)> open(
    WidgetTester tester,
    String location, {
    String code = 'es',
    Size size = const Size(500, 3000),
    Map<String, Object?>? progress,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final store = InMemoryStore(settings: {'localeCode': code}, progress: progress);
    final mic = FakeMic();
    addTearDown(mic.windows.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(store),
          audioServiceProvider.overrideWithValue(FakeAudio()),
          pitchServiceProvider.overrideWithValue(mic),
        ],
        child: const ChordMasterApp(),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    appRouter.go(location);
    await settle(tester);
    return (store, mic);
  }

  /// Toca mo_first con el micrófono; con [wrongAt], una nota equivocada antes
  /// de esa.
  Future<void> playStep(WidgetTester tester, FakeMic mic, {int? wrongAt}) async {
    final tab = melodyStepsById['mo_first']!.tab;
    final button = find.byKey(const Key('tab-mic'));
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
    final played = [
      for (final (i, n) in tab.indexed) ...[
        if (i == wrongAt) TabNote(n.string, n.fret + 1),
        n,
      ],
    ];
    for (final w in micWindows(played, 80)) {
      mic.windows.add(w);
      await tester.pump();
    }
  }

  testWidgets('sin pasadas: lo explica, y Práctica de hoy lo enlaza', (tester) async {
    await open(tester, '/');
    final link = find.byKey(const Key('today-session'));
    await tester.ensureVisible(link);
    await tester.pump();
    expect(find.descendant(of: link, matching: find.text(AppStrings.todaySession(0))), findsOneWidget);
    await tester.tap(link);
    await settle(tester);
    expect(find.byKey(const Key('session-empty')), findsOneWidget);
  });

  testWidgets('una pasada con un error: va a "para repetir" con renglón y tempo, y lleva al paso', (
    tester,
  ) async {
    final (store, mic) = await open(tester, '/learn/lessons/course/melodies/mo_first');
    await playStep(tester, mic, wrongAt: 9);
    expect((store.progress[SessionLog.keyRuns]! as Map)['day'], dayKey(today));

    appRouter.go('/session');
    await settle(tester);
    expect(tester.widget<Text>(find.byKey(const Key('session-runs'))).data, '1');
    expect(tester.widget<Text>(find.byKey(const Key('session-clean'))).data, '0');
    final tile = find.byKey(const Key('session-repeat-$odeKey'));
    expect(
      find.descendant(of: tile, matching: find.text(AppStrings.sessionRepeatDetail(1, 1, 50))),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tile, matching: find.text(melodyStepsById['mo_first']!.title.text)),
      findsOneWidget,
    );
    await tester.tap(tile);
    await settle(tester);
    expect(find.byKey(const Key('course-title')), findsOneWidget);
  });

  testWidgets('limpia: pasa a "salió limpio" con su mejor tempo y el récord nuevo', (tester) async {
    final (store, mic) = await open(tester, '/learn/lessons/course/melodies/mo_first');
    await playStep(tester, mic, wrongAt: 9);
    await tester.pump(const Duration(seconds: 4));
    await playStep(tester, mic);

    expect((store.progress[SessionLog.keyRuns]! as Map)['runs'], hasLength(2));
    appRouter.go('/session');
    await settle(tester);
    expect(tester.widget<Text>(find.byKey(const Key('session-runs'))).data, '2');
    expect(tester.widget<Text>(find.byKey(const Key('session-records'))).data, '1');
    expect(find.byKey(const Key('session-repeat-$odeKey')), findsNothing);
    final tile = find.byKey(const Key('session-clean-$odeKey'));
    expect(
      find.descendant(
        of: tile,
        matching: find.text('${AppStrings.sessionBest(80)} · ${AppStrings.sessionNewRecord(80)}'),
      ),
      findsOneWidget,
    );
    appRouter.go('/');
    await settle(tester);
    expect(find.text(AppStrings.todaySession(2), skipOffstage: false), findsOneWidget);
  });

  testWidgets('las pasadas de otro día no cuentan', (tester) async {
    const old = PracticeRun(
      target: CourseStepTarget('melodies', 'mo_first'),
      mistakes: 1,
      bpm: 80,
      clean: false,
      lineToPractice: 0,
      tempo: 80,
    );
    await open(tester, '/session', progress: {
      SessionLog.keyRuns: {
        'day': dayKey(today.subtract(const Duration(days: 1))),
        'runs': [old.toJson()],
      },
    });
    expect(find.byKey(const Key('session-empty')), findsOneWidget);
  });

  testWidgets('las pasadas de hoy se leen al abrir la app', (tester) async {
    const run = PracticeRun(
      target: CourseStepTarget('melodies', 'mo_first'),
      mistakes: 2,
      bpm: 70,
      clean: false,
      lineToPractice: 1,
      tempo: 70,
    );
    await open(tester, '/session', progress: {
      SessionLog.keyRuns: {'day': dayKey(today), 'runs': [run.toJson()]},
    });
    expect(find.byKey(const Key('session-repeat-$odeKey')), findsOneWidget);
  });

  testWidgets('una pasada de un lick sale con su nombre y su estilo', (tester) async {
    const run = PracticeRun(
      target: LickTarget('folk_lick'),
      mistakes: 1,
      bpm: 70,
      clean: false,
      lineToPractice: 0,
      tempo: 75,
    );
    await open(tester, '/session', progress: {
      SessionLog.keyRuns: {'day': dayKey(today), 'runs': [run.toJson()]},
    });
    final row = find.byKey(const Key('session-repeat-lick:folk_lick'));
    expect(row, findsOneWidget);
    final lick = licksById['folk_lick']!;
    expect(find.descendant(of: row, matching: find.text(lick.title.text)), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text(lickStyleInfo(lick.style).title.text)), findsOneWidget);
  });

  for (final code in ['es', 'en']) {
    testWidgets('a 360 dp ($code) el resumen cabe', (tester) async {
      final runs = [
        const PracticeRun(
          target: CourseStepTarget('melodies', 'mf_part3'),
          mistakes: 12,
          bpm: 95,
          clean: false,
          lineToPractice: 3,
          tempo: 100,
        ),
        const PracticeRun(
          target: CourseStepTarget('melodies', 'mo_first'),
          mistakes: 0,
          bpm: 104,
          clean: true,
          lineToPractice: null,
          tempo: 100,
          newRecord: 100,
        ),
      ];
      await open(
        tester,
        '/session',
        code: code,
        size: const Size(360, 2000),
        progress: {
          SessionLog.keyRuns: {
            'day': dayKey(today),
            'runs': [for (final r in runs) r.toJson()],
          },
        },
      );
      expect(tester.takeException(), isNull);
      for (final key in [
        'session-repeat-course:melodies:mf_part3',
        'session-clean-$odeKey',
        'session-records',
      ]) {
        final rect = tester.getRect(find.byKey(Key(key)));
        expect(rect.left, greaterThanOrEqualTo(0), reason: key);
        expect(rect.right, lessThanOrEqualTo(360), reason: key);
      }
    });
  }
}
