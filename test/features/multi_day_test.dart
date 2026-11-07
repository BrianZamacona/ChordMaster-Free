import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/practice/multi_day_challenges.dart';
import 'package:chordmaster_free/features/challenges/multi_day_screen.dart';
import 'package:chordmaster_free/services/activity_log.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_store.dart';

void main() {
  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  String daysAgo(int n) {
    final now = DateTime.now();
    return dayKey(DateTime(now.year, now.month, now.day - n));
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<InMemoryStore> open(
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [keyValueStoreProvider.overrideWithValue(store)],
        child: const ChordMasterApp(),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    appRouter.go(location);
    await settle(tester);
    return store;
  }

  String status(WidgetTester tester, String id) =>
      tester.widget<Text>(find.byKey(Key('multi-day-status-$id'))).data!;

  testWidgets('Practicar enlaza los retos de la semana', (tester) async {
    await open(tester, '/practice');
    await tester.tap(find.text(AppStrings.hubMultiDay));
    await settle(tester);
    expect(find.byType(MultiDayChallengesScreen), findsOneWidget);
    for (final c in multiDayChallenges) {
      expect(find.byKey(Key('multi-day-${c.id}'), skipOffstage: false), findsOneWidget);
    }
  });

  testWidgets('lee los días guardados', (tester) async {
    await open(
      tester,
      '/practice/challenges',
      progress: {
        ActivityLog.keyDays: {
          'technique': [daysAgo(0), daysAgo(2), daysAgo(9)],
          'ear': [daysAgo(1)],
        },
      },
    );
    // Técnica: dos días en la semana (el de hace 9 no cuenta).
    expect(status(tester, 'md_steel_fingers'), '2/5');
    // Racha de cualquier práctica: hoy, ayer y anteayer.
    expect(status(tester, 'md_steady_week'), '3/7');
    expect(find.text(AppStrings.multiDayPassed(0, multiDayChallenges.length)), findsOneWidget);
  });

  testWidgets('con la meta cumplida dice "Superado"', (tester) async {
    await open(
      tester,
      '/practice/challenges',
      progress: {
        ActivityLog.keyDays: {
          'lessons': [daysAgo(0), daysAgo(3), daysAgo(5)],
        },
      },
    );
    expect(status(tester, 'md_step_a_day'), AppStrings.challengePassed);
  });

  testWidgets('guardar un tempo limpio en Técnica cuenta el día', (tester) async {
    final store = await open(tester, '/practice/technique');
    final clean = find.byKey(const Key('technique-clean-chromatic'));
    await tester.ensureVisible(clean);
    await tester.pump();
    await tester.tap(clean);
    await tester.pump();
    final saved = store.progress[ActivityLog.keyDays]! as Map;
    expect(saved['technique'], [daysAgo(0)]);
    appRouter.go('/practice/challenges');
    await settle(tester);
    expect(status(tester, 'md_steel_fingers'), '1/5');
  });

  testWidgets('terminar una lección cuenta el día', (
    tester,
  ) async {
    final store = await open(tester, '/learn/lessons/f3_em_am');
    final button = find.byKey(const Key('lesson-toggle-done'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 300));
    final saved = store.progress[ActivityLog.keyDays]! as Map;
    expect(saved['lessons'], [daysAgo(0)]);
  });

  for (final code in ['es', 'en']) {
    testWidgets('a 360 dp ($code) sin desbordes', (tester) async {
      await open(
        tester,
        '/practice/challenges',
        code: code,
        size: const Size(360, 3200),
        progress: {
          ActivityLog.keyDays: {
            'workouts': [for (var i = 0; i < 7; i++) daysAgo(i)],
          },
        },
      );
      expect(tester.takeException(), isNull);
    });
  }
}
