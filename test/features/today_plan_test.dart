import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/lessons/curriculum.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/practice/daily_plan.dart';
import 'package:chordmaster_free/domain/practice/multi_day_challenges.dart';
import 'package:chordmaster_free/features/lessons/lesson_unit_screen.dart';
import 'package:chordmaster_free/features/technique/technique_screen.dart';
import 'package:chordmaster_free/features/workouts/workouts_screen.dart';
import 'package:chordmaster_free/services/activity_log.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_store.dart';

void main() {
  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  final today = dayKey(DateTime.now());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> open(
    WidgetTester tester, {
    String code = 'es',
    Size size = const Size(500, 2400),
    Map<String, Object?>? progress,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(
            InMemoryStore(settings: {'localeCode': code}, progress: progress),
          ),
        ],
        child: const ChordMasterApp(),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    appRouter.go('/');
    await settle(tester);
  }

  String progressText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('today-plan-progress'))).data!;

  testWidgets('sin práctica: el primer curso de Fundamentos, 0 de 3', (tester) async {
    await open(tester);
    expect(find.byKey(const Key('today-plan')), findsOneWidget);
    expect(progressText(tester), AppStrings.lessonsProgress(0, 3));
    final first = unitOfCourse(LessonCourse.basics);
    expect(
      find.descendant(
        of: find.byKey(const Key('today-lesson')),
        matching: find.text(AppStrings.guideOpenLesson(first.title.text)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('cuenta lo anotado hoy', (tester) async {
    await open(tester, progress: {
      ActivityLog.keyDays: {'lessons': [today], 'technique': [today]},
    });
    expect(progressText(tester), AppStrings.lessonsProgress(2, 3));
  });

  testWidgets('con los tres pasos dice "¡Listo por hoy!"', (tester) async {
    await open(tester, progress: {
      ActivityLog.keyDays: {
        for (final a in dailyPlanActivities) a.name: [today],
      },
    });
    expect(progressText(tester), AppStrings.todayPlanDone);
  });

  testWidgets('cada paso abre su módulo', (tester) async {
    for (final (key, screen) in [
      ('today-lesson', LessonUnitScreen),
      ('today-workout', WorkoutsScreen),
      ('today-technique', TechniqueScreen),
    ]) {
      await open(tester);
      await tester.tap(find.byKey(Key(key)));
      await settle(tester);
      expect(find.byType(screen), findsOneWidget, reason: key);
    }
  });

  testWidgets('la rutina del día abre su escala y tónica', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('today-workout')));
    await settle(tester);
    final scale = dailyWorkoutScale(DateTime.now());
    final screen = tester.widget<WorkoutsScreen>(find.byType(WorkoutsScreen));
    expect(screen.scaleId, scale.scaleId);
    expect(screen.root, scale.root);
  });

  for (final code in ['es', 'en']) {
    testWidgets('a 360 dp ($code) sin desbordes', (tester) async {
      await open(tester, code: code, size: const Size(360, 1600));
      expect(tester.takeException(), isNull);
    });
  }
}
