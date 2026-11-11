import 'dart:math';

import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/theory/circle_quiz.dart';
import 'package:chordmaster_free/features/circle/circle_quiz_screen.dart';
import 'package:chordmaster_free/features/circle/circle_quiz_viewmodel.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_store.dart';

void main() {
  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<(InMemoryStore, ProviderContainer)> open(WidgetTester tester, {String code = 'es'}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 1400);
    addTearDown(tester.view.reset);
    final store = InMemoryStore(settings: {'localeCode': code});
    appRouter.go('/');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(store),
          circleQuizRandomProvider.overrideWithValue(Random(5)),
        ],
        child: const ChordMasterApp(),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    appRouter.go('/circle');
    await settle(tester);
    final button = find.byKey(const Key('circle-open-quiz'));
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await settle(tester);
    final container = ProviderScope.containerOf(tester.element(find.byType(CircleQuizScreen)));
    return (store, container);
  }

  CircleQuestion question(ProviderContainer c) => c.read(circleQuizViewModelProvider).question;

  Future<void> answer(WidgetTester tester, ProviderContainer c, {required bool right}) async {
    final q = question(c);
    final value = right ? q.answer : q.choices.firstWhere((x) => x != q.answer);
    final button = find.byKey(Key('circle-quiz-choice-${q.choices.indexOf(value)}'));
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
  }

  Future<void> next(WidgetTester tester) async {
    final button = find.byKey(const Key('circle-quiz-next'));
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await settle(tester);
  }

  testWidgets('10 seguidas: guarda la racha, anota el día y da el logro', (tester) async {
    final (store, c) = await open(tester);
    for (var i = 0; i < circleQuizAchievementStreak; i++) {
      await answer(tester, c, right: true);
      expect(find.text(AppStrings.fretQuizRight), findsOneWidget);
      expect(find.byKey(const Key('circle-quiz-why')), findsOneWidget);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await next(tester);
    }
    expect(store.progress[CircleQuizViewModel.keyBestStreak], circleQuizAchievementStreak);
    expect(store.achievements, contains(CircleQuizViewModel.achievementId));
    expect(store.progress['activity_days'], isNotNull);
  });

  testWidgets('equivocarse corta la racha y dice cuál era', (tester) async {
    final (_, c) = await open(tester);
    await answer(tester, c, right: true);
    await next(tester);
    await answer(tester, c, right: false);
    expect(find.byKey(const Key('circle-quiz-verdict')), findsOneWidget);
    expect(c.read(circleQuizViewModelProvider).streak, 0);
    expect(c.read(circleQuizViewModelProvider).bestStreak, 1);
  });

  for (final code in ['es', 'en']) {
    testWidgets('a 360 dp ($code) 30 preguntas sin desbordes', (tester) async {
      final (_, c) = await open(tester, code: code);
      for (var i = 0; i < 30; i++) {
        await answer(tester, c, right: i.isEven);
        expect(tester.takeException(), isNull);
        for (var k = 0; k < circleQuizChoices; k++) {
          expect(tester.getRect(find.byKey(Key('circle-quiz-choice-$k'))).right, lessThanOrEqualTo(360));
        }
        await next(tester);
      }
    });
  }
}
