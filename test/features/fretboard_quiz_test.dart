import 'dart:math';

import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/theory/fretboard_mastery.dart';
import 'package:chordmaster_free/domain/theory/fretboard_quiz.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:chordmaster_free/features/fretboard_quiz/fretboard_mastery_map.dart';
import 'package:chordmaster_free/features/fretboard_quiz/fretboard_quiz_screen.dart';
import 'package:chordmaster_free/features/fretboard_quiz/fretboard_quiz_viewmodel.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:chordmaster_free/ui/widgets/fretboard_diagram.dart';
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
    Map<String, Object?> settings = const {},
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final store = InMemoryStore(settings: {'localeCode': code, ...settings});
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
        if (q is OctaveQuestion || q is FindNoteQuestion) {
          expect(find.byKey(const Key('fret-quiz-hint')), findsOneWidget);
        }
        final next = find.byKey(const Key('fret-quiz-next'));
        await tester.ensureVisible(next);
        await tester.pump();
        await tester.tap(next);
        await settle(tester);
      }
      expect(c.read(fretQuizViewModelProvider).streak, 20);
    });
  }

  testWidgets('la pregunta al revés: nada en el mástil hasta responder, luego la nota y por qué', (tester) async {
    final (_, c) = await open(tester);
    while (question(c) is! FindNoteQuestion) {
      c.read(fretQuizViewModelProvider.notifier).next();
      await tester.pump();
    }
    final q = question(c) as FindNoteQuestion;
    expect(
      tester.widget<Text>(find.byKey(const Key('fret-quiz-prompt'))).data,
      AppStrings.fretQuizFindNote(pitchClassName(q.note), q.string),
    );
    expect(tester.widget<FretboardNeck>(find.byType(FretboardNeck).first).coordinates, isEmpty);
    await tester.tap(choiceFor(c, q.answer));
    await tester.pump();
    final shown = tester.widget<FretboardNeck>(find.byType(FretboardNeck).first).coordinates.single;
    expect((shown.string, shown.fret, shown.note), (q.string, q.answer, pitchClassName(q.note)));
    expect(
      tester.widget<Text>(find.byKey(const Key('fret-quiz-hint'))).data,
      AppStrings.fretQuizFindNoteHint(
        pitchClassName(pitchClassAt((string: q.string, fret: 0))),
        q.answer,
        pitchClassName(q.note),
      ),
    );
  });

  for (final code in ['es', 'en']) {
    testWidgets('a 360 dp ($code): los filtros cambian la pregunta, se guardan y se resumen', (tester) async {
      final (store, c) = await open(tester, code: code, size: const Size(360, 800));
      await tester.tap(find.byKey(const Key('fret-quiz-filters')));
      await settle(tester);
      // Quedan solo la 6ª y la 5ª.
      for (final s in [1, 2, 3, 4]) {
        final chip = find.byKey(Key('fret-filter-string-$s'));
        expect(tester.getRect(chip).right, lessThanOrEqualTo(360));
        await tester.tap(chip);
        await tester.pump();
      }
      final naturals = find.byKey(const Key('fret-filter-naturals'));
      await tester.ensureVisible(naturals);
      await tester.pump();
      await tester.tap(naturals);
      await tester.pump();
      expect(tester.takeException(), isNull);
      const want = FretQuizFilter(strings: {6, 5}, naturalsOnly: true);
      expect(c.read(fretQuizViewModelProvider).filter, want);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      expect(FretQuizFilter.fromJson(store.settings[FretQuizViewModel.keyFilter]), want);
      await tester.tapAt(const Offset(180, 40));
      await settle(tester);
      expect(
        tester.widget<Text>(find.byKey(const Key('fret-quiz-filter-summary'))).data,
        AppStrings.fretQuizFilterSummary([6, 5], 0, 12, naturals: true),
      );
      for (var i = 0; i < 15; i++) {
        final q = question(c);
        switch (q) {
          case NameNoteQuestion(:final spot):
            expect([6, 5], contains(spot.string));
            expect(isNaturalNote(q.answer), isTrue);
          case FindNoteQuestion(:final string, :final note):
            expect([6, 5], contains(string));
            expect(isNaturalNote(note), isTrue);
          case OctaveQuestion():
            fail('la 6ª y la 5ª no forman ninguna octava');
        }
        c.read(fretQuizViewModelProvider.notifier).next();
        await tester.pump();
      }
    });
  }

  testWidgets('el filtro guardado se usa desde la primera pregunta', (tester) async {
    const saved = FretQuizFilter(strings: {3}, fromFret: 5, toFret: 9);
    final (_, c) = await open(tester, settings: {FretQuizViewModel.keyFilter: saved.toJson()});
    expect(c.read(fretQuizViewModelProvider).filter, saved);
    final q = question(c);
    final string = switch (q) {
      NameNoteQuestion(:final spot) => spot.string,
      FindNoteQuestion(:final string) => string,
      OctaveQuestion() => fail('con una sola cuerda no hay octavas'),
    };
    expect(string, 3);
  });

  for (final code in ['es', 'en']) {
    testWidgets('a 360 dp ($code): la ronda de 60 s cuenta puntos sin pausa y guarda el récord', (tester) async {
      final (store, c) = await open(tester, code: code);
      final start = find.byKey(const Key('fret-round-start'));
      expect(tester.getRect(start).right, lessThanOrEqualTo(360));
      await tester.tap(start);
      await tester.pump();
      expect(find.byKey(const Key('fret-round-left')), findsOneWidget);
      // Bien, bien, mal: la siguiente sale al responder, sin botón.
      for (final right in [true, true, false]) {
        final q = question(c);
        final pick = right ? q.answer : q.choices.firstWhere((x) => x != q.answer);
        final button = choiceFor(c, pick);
        await tester.ensureVisible(button);
        await tester.pump();
        await tester.tap(button);
        await tester.pump();
        expect(find.byKey(const Key('fret-quiz-next')), findsNothing);
        expect(question(c), isNot(same(q)));
        expect(find.byKey(const Key('fret-round-previous')), findsOneWidget);
      }
      expect(
        tester.widget<Text>(find.byKey(const Key('fret-round-score'))).data,
        AppStrings.fretRoundScore(2, 3),
      );
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 30));
      expect(tester.widget<Text>(find.byKey(const Key('fret-round-left'))).data, AppStrings.fretRoundLeft(30));
      await tester.pump(const Duration(seconds: 30));
      await tester.pump();
      expect(find.byKey(const Key('fret-round-result')), findsOneWidget);
      expect(find.text(AppStrings.fretRoundOver(2, 3)), findsOneWidget);
      expect(find.text(AppStrings.fretRoundNewRecord), findsOneWidget);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      expect(store.progress[FretQuizViewModel.keyBestRound], 2);
      expect(tester.takeException(), isNull);
      // Otra ronda empieza de cero; terminarla antes no cuenta para el récord.
      await tester.tap(find.byKey(const Key('fret-round-again')));
      await tester.pump();
      expect(c.read(fretQuizViewModelProvider).round!.left, 60);
      await tester.tap(find.byKey(const Key('fret-round-stop')));
      await tester.pump();
      expect(c.read(fretQuizViewModelProvider).round, isNull);
      expect(find.byKey(const Key('fret-round-result')), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const Key('fret-round-best'))).data,
        AppStrings.fretRoundBest(2),
      );
    });
  }

  testWidgets('durante la ronda no se cambian los filtros', (tester) async {
    final (_, c) = await open(tester);
    c.read(fretQuizViewModelProvider.notifier).startRound();
    await tester.pump();
    final filters = tester.widget<IconButton>(find.byKey(const Key('fret-quiz-filters')));
    expect(filters.onPressed, isNull);
    c.read(fretQuizViewModelProvider.notifier).stopRound();
    await tester.pump();
  });

  for (final code in ['es', 'en']) {
    testWidgets('a 360 × 780 dp ($code): en la ronda las cuatro opciones se ven sin desplazar', (tester) async {
      final (_, c) = await open(tester, code: code, size: const Size(360, 780));
      final bar = tester.getRect(find.byType(NavigationBar));
      for (var i = 0; i < 12; i++) {
        c.read(fretQuizViewModelProvider.notifier).startRound();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byKey(const Key('fret-quiz-filter-summary')), findsNothing);
        for (var k = 0; k < fretQuizChoices; k++) {
          expect(tester.getRect(find.byKey(Key('fret-choice-$k'))).bottom, lessThanOrEqualTo(bar.top), reason: '$i');
        }
        c.read(fretQuizViewModelProvider.notifier).stopRound();
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final code in ['es', 'en']) {
    testWidgets('a 360 dp ($code): un error queda débil en el mapa, se guarda y vuelve en el repaso', (tester) async {
      final (store, c) = await open(tester, code: code);
      final q = question(c);
      final spot = testedSpot(q);
      final wrong = q.choices.firstWhere((x) => x != q.answer);
      await tester.tap(choiceFor(c, wrong));
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      expect(FretMastery.fromJson(store.progress[FretQuizViewModel.keySpots]).of(spot), SpotMastery.weak);
      // El mapa lo muestra entre los débiles, con su nota.
      final map = find.byKey(const Key('fret-map'));
      await tester.ensureVisible(map);
      await tester.pump();
      expect(find.text(FretMasteryMap.levelLabel(SpotMastery.weak, 1)), findsOneWidget);
      final neck = tester.widget<FretboardNeck>(find.descendant(of: map, matching: find.byType(FretboardNeck)));
      expect([for (final n in neck.coordinates) (n.string, n.fret)], [(spot.string, spot.fret)]);
      // Centrado en ese lugar (la columna del aire siempre se ve).
      if (spot.fret > 0) expect(spot.fret, inInclusiveRange(neck.focus!.start, neck.focus!.end));
      expect(tester.getRect(find.byKey(const Key('fret-map-mastered'))).right, lessThanOrEqualTo(360));
      expect(tester.takeException(), isNull);
      // Vuelve en el repaso, con su aviso.
      var reviewed = false;
      for (var i = 0; i < 40 && !reviewed; i++) {
        c.read(fretQuizViewModelProvider.notifier).next();
        await tester.pump();
        reviewed = testedSpot(question(c)) == spot;
      }
      expect(reviewed, isTrue);
      expect(find.byKey(const Key('fret-quiz-review')), findsOneWidget);
    });
  }

  testWidgets('el registro guardado se lee al abrir', (tester) async {
    const spot = (string: 4, fret: 5);
    final saved = const FretMastery().record(spot, right: true).record(spot, right: true).record(spot, right: true);
    final store = InMemoryStore(progress: {FretQuizViewModel.keySpots: saved.toJson()});
    final container = ProviderContainer(overrides: [
      keyValueStoreProvider.overrideWithValue(store),
      fretQuizRandomProvider.overrideWithValue(Random(1)),
    ]);
    addTearDown(container.dispose);
    final sub = container.listen(fretQuizViewModelProvider, (_, _) {});
    addTearDown(sub.close);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    expect(container.read(fretQuizViewModelProvider).mastery.of(spot), SpotMastery.mastered);
  });
}
