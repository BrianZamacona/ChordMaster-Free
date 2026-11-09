import 'dart:math';

import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/theory/fretboard_quiz.dart';
import 'package:chordmaster_free/features/fretboard_quiz/fretboard_quiz_screen.dart';
import 'package:chordmaster_free/features/fretboard_quiz/fretboard_quiz_viewmodel.dart';
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

  Future<(InMemoryStore, ProviderContainer)> open(
    WidgetTester tester, {
    String code = 'es',
    Size size = const Size(360, 1600),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final store = InMemoryStore(settings: {'localeCode': code});
    appRouter.go('/');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(store),
          fretQuizRandomProvider.overrideWithValue(Random(3)),
        ],
        child: const ChordMasterApp(),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    appRouter.go('/practice/fretboard');
    await settle(tester);
    final container = ProviderScope.containerOf(tester.element(find.byType(FretQuizScreen)));
    return (store, container);
  }

  FretQuestion question(ProviderContainer c) => c.read(fretQuizViewModelProvider).question;

  Finder choiceFor(ProviderContainer c, int value) {
    final i = question(c).choices.indexOf(value);
    return find.byKey(Key('fret-choice-$i'));
  }

  testWidgets('Practicar lo enlaza', (tester) async {
    await open(tester);
    appRouter.go('/practice');
    await settle(tester);
    expect(find.text(AppStrings.hubFretboard), findsOneWidget);
  });

  testWidgets('acertar suma racha, guarda la mejor y anota el día', (tester) async {
    final (store, c) = await open(tester);
    final q = question(c);
    await tester.tap(choiceFor(c, q.answer));
    await tester.pump();
    expect(find.text(AppStrings.fretQuizRight), findsOneWidget);
    expect(c.read(fretQuizViewModelProvider).streak, 1);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    expect(store.progress[FretQuizViewModel.keyBestStreak], 1);
    expect(store.progress['activity_days'], isNotNull);
    await tester.tap(find.byKey(const Key('fret-quiz-next')));
    await tester.pump();
    expect(c.read(fretQuizViewModelProvider).isAnswered, isFalse);
  });

  testWidgets('equivocarse corta la racha y dice cuál era', (tester) async {
    final (_, c) = await open(tester);
    final q = question(c);
    final wrong = q.choices.firstWhere((x) => x != q.answer);
    await tester.tap(choiceFor(c, wrong));
    await tester.pump();
    expect(find.byKey(const Key('fret-quiz-verdict')), findsOneWidget);
    expect(c.read(fretQuizViewModelProvider).streak, 0);
    // Responder otra vez no cuenta.
    await tester.tap(choiceFor(c, q.answer));
    await tester.pump();
    expect(c.read(fretQuizViewModelProvider).answered, 1);
  });

  for (final code in ['es', 'en']) {
    testWidgets('a 360 dp ($code) 20 preguntas sin desbordes', (tester) async {
      final (_, c) = await open(tester, code: code);
      for (var i = 0; i < 20; i++) {
        final q = question(c);
        final button = choiceFor(c, q.answer);
        await tester.ensureVisible(button);
        await tester.pump();
        expect(tester.getRect(button).right, lessThanOrEqualTo(360));
        await tester.tap(button);
        await tester.pump();
        expect(tester.takeException(), isNull);
        if (q is OctaveQuestion) expect(find.byKey(const Key('fret-quiz-hint')), findsOneWidget);
        final next = find.byKey(const Key('fret-quiz-next'));
        await tester.ensureVisible(next);
        await tester.pump();
        await tester.tap(next);
        await settle(tester);
      }
      expect(c.read(fretQuizViewModelProvider).streak, 20);
    });
  }
}
