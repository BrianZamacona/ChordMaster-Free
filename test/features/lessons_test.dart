import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/lessons/curriculum.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/features/lessons/lesson_widgets.dart';
import 'package:chordmaster_free/features/lessons/lessons_viewmodel.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_store.dart';

void main() {
  final foundations = [for (final l in lessonsOf(LessonTrack.foundations)) l.id];

  Future<ProviderContainer> containerWith(InMemoryStore store) async {
    final container = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    container.read(lessonsViewModelProvider);
    await Future<void>.delayed(Duration.zero);
    return container;
  }

  group('LessonsViewModel', () {
    test('lee lo guardado: terminadas y camino', () async {
      final store = InMemoryStore(progress: {
        LessonsViewModel.keyCompleted: [foundations.first],
        LessonsViewModel.keyTrack: 'lead',
      });
      final state = (await containerWith(store)).read(lessonsViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.chosen, LessonTrack.lead);
      expect(state.path.completed, {foundations.first});
      expect(state.path.next?.id, foundations[1]);
    });

    test('marcar y desmarcar guarda la lista', () async {
      final store = InMemoryStore();
      final container = await containerWith(store);
      final vm = container.read(lessonsViewModelProvider.notifier);

      await vm.toggleCompleted(foundations.first);
      expect(store.progress[LessonsViewModel.keyCompleted], [foundations.first]);

      await vm.toggleCompleted(foundations.first);
      expect(store.progress[LessonsViewModel.keyCompleted], isEmpty);
    });

    test('elegir camino se guarda; Fundamentos no es un camino elegible', () async {
      final store = InMemoryStore();
      final container = await containerWith(store);
      final vm = container.read(lessonsViewModelProvider.notifier);

      await vm.choose(LessonTrack.lead);
      expect(store.progress[LessonsViewModel.keyTrack], 'lead');
      await vm.choose(LessonTrack.foundations);
      expect(container.read(lessonsViewModelProvider).chosen, LessonTrack.lead);
    });

    test('el mapa no resalta un camino hasta que toque decidir', () async {
      final fresh = await containerWith(InMemoryStore());
      expect(fresh.read(lessonsViewModelProvider).highlightedTrack, isNull);

      final done = await containerWith(
        InMemoryStore(progress: {LessonsViewModel.keyCompleted: foundations}),
      );
      expect(
        done.read(lessonsViewModelProvider).highlightedTrack,
        LessonTrack.rhythm,
      );

      final saved = await containerWith(
        InMemoryStore(progress: {LessonsViewModel.keyTrack: 'lead'}),
      );
      expect(
        saved.read(lessonsViewModelProvider).highlightedTrack,
        LessonTrack.lead,
      );
    });

    test('tocar el camino por defecto antes de tiempo también lo elige', () async {
      final store = InMemoryStore();
      final container = await containerWith(store);

      await container
          .read(lessonsViewModelProvider.notifier)
          .choose(LessonTrack.rhythm);
      expect(store.progress[LessonsViewModel.keyTrack], 'rhythm');
      expect(
        container.read(lessonsViewModelProvider).highlightedTrack,
        LessonTrack.rhythm,
      );
    });

    test('terminar Fundamentos desbloquea su logro', () async {
      final store = InMemoryStore(progress: {
        LessonsViewModel.keyCompleted: foundations.sublist(1),
      });
      final container = await containerWith(store);
      expect(store.achievements['foundations_done'], isNull);

      await container
          .read(lessonsViewModelProvider.notifier)
          .toggleCompleted(foundations.first);
      expect(store.achievements['foundations_done'], isA<String>());
    });
  });

  group('pantallas', () {
    Future<InMemoryStore> open(
      WidgetTester tester,
      String location, {
      Map<String, Object?>? progress,
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(500, 3200);
      addTearDown(tester.view.reset);
      final store = InMemoryStore(progress: progress);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [keyValueStoreProvider.overrideWithValue(store)],
          child: const ChordMasterApp(),
        ),
      );
      appRouter.go(location);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      return store;
    }

    testWidgets('el mapa muestra las unidades, los dos caminos y sus retos', (
      tester,
    ) async {
      await open(tester, '/learn/lessons');
      expect(find.byKey(const Key('lessons-start-next')), findsOneWidget);
      for (final track in LessonTrack.values) {
        for (final unit in unitsOf(track)) {
          expect(find.byKey(Key('unit-${unit.id}'), skipOffstage: false), findsOneWidget);
        }
      }
      for (final c in challenges) {
        expect(find.byKey(Key('challenge-${c.id}'), skipOffstage: false), findsOneWidget);
      }
      expect(find.byKey(const Key('lessons-track-rhythm')), findsOneWidget);
      expect(find.byKey(const Key('lessons-track-lead')), findsOneWidget);
    });

    testWidgets('tocar el título de líder lo elige', (tester) async {
      final store = await open(tester, '/learn/lessons');
      await tester.ensureVisible(find.byKey(const Key('lessons-track-lead')));
      await tester.tap(find.byKey(const Key('lessons-track-lead')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(store.progress[LessonsViewModel.keyTrack], 'lead');
    });

    testWidgets('el reto rítmico se supera con el récord del juego de ritmo', (
      tester,
    ) async {
      final rhythm = challengesOf(LessonTrack.rhythm).single;
      final lead = challengesOf(LessonTrack.lead).single;
      await open(
        tester,
        '/learn/lessons',
        progress: {'rhythm_game_best_score': rhythm.goal},
      );
      final rhythmStatus = tester.widget<Text>(
        find.byKey(Key('challenge-status-${rhythm.id}'), skipOffstage: false),
      );
      final leadStatus = tester.widget<Text>(
        find.byKey(Key('challenge-status-${lead.id}'), skipOffstage: false),
      );
      expect(rhythmStatus.data, AppStrings.challengePassed);
      expect(leadStatus.data, AppStrings.challengeEarBest(0, lead.goal));
    });

    testWidgets('la unidad lista sus lecciones', (tester) async {
      final unit = unitsOf(LessonTrack.foundations).first;
      await open(tester, '/learn/lessons/unit/${unit.id}');
      for (final lesson in lessonsOfUnit(unit)) {
        expect(find.byKey(Key('lesson-${lesson.id}')), findsOneWidget);
      }
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('el detalle marca la lección como completada', (tester) async {
      final store = await open(tester, '/learn/lessons/${foundations.first}');
      final button = find.byKey(const Key('lesson-toggle-done'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump(const Duration(milliseconds: 300));
      expect(store.progress[LessonsViewModel.keyCompleted], [foundations.first]);
    });

    testWidgets('los acordes de la lección enlazan a la biblioteca', (tester) async {
      await open(tester, '/learn/lessons/f3_em_am');
      // chords.json se decodifica en otro isolate: hace falta tiempo real.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 2)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('lesson-chord-Em')), findsOneWidget);
      expect(find.byKey(const Key('lesson-chord-Am')), findsOneWidget);
    });

    testWidgets('una lección que no existe muestra un aviso', (tester) async {
      await open(tester, '/learn/lessons/no_existe');
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byKey(const Key('lesson-toggle-done')), findsNothing);
    });
  });

  test('los dos caminos tienen tantas unidades como retos (el mapa va por filas)', () {
    expect(
      unitsOf(LessonTrack.rhythm).length,
      unitsOf(LessonTrack.lead).length,
    );
    expect(
      challengesOf(LessonTrack.rhythm).length,
      challengesOf(LessonTrack.lead).length,
    );
  });

  // Un desborde hace fallar estos tests; lo demás se comprueba midiendo.
  for (final code in ['es', 'en']) {
    group('a 360 dp ($code)', () {
      Future<void> open(WidgetTester tester, String location) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 3200);
        addTearDown(tester.view.reset);
        addTearDown(() => CurrentLanguage.value = AppLanguage.es);
        final store = InMemoryStore(settings: {'localeCode': code});
        await tester.pumpWidget(
          ProviderScope(
            overrides: [keyValueStoreProvider.overrideWithValue(store)],
            child: const ChordMasterApp(),
          ),
        );
        // chords.json se decodifica en otro isolate: hace falta tiempo real.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 2)),
        );
        appRouter.go(location);
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 300));
        }
        expect(CurrentLanguage.value, appLanguageFor(code));
      }

      testWidgets('el mapa alinea los dos caminos fila por fila', (tester) async {
        await open(tester, '/learn/lessons');
        final rhythm = unitsOf(LessonTrack.rhythm);
        final lead = unitsOf(LessonTrack.lead);
        void expectAligned(Key a, Key b) {
          final ra = tester.getRect(find.byKey(a));
          final rb = tester.getRect(find.byKey(b));
          expect(ra.top, rb.top);
          expect(ra.height, rb.height);
        }

        expectAligned(
          const Key('lessons-track-rhythm'),
          const Key('lessons-track-lead'),
        );
        for (var i = 0; i < rhythm.length; i++) {
          expectAligned(Key('unit-${rhythm[i].id}'), Key('unit-${lead[i].id}'));
        }
        expectAligned(
          Key('challenge-${challengesOf(LessonTrack.rhythm).single.id}'),
          Key('challenge-${challengesOf(LessonTrack.lead).single.id}'),
        );
      });

      testWidgets('el rasgueo del mapa queda en una línea', (tester) async {
        await open(tester, '/learn/lessons');
        final art = tester.getRect(find.byKey(const Key('unit-art-strum')));
        final unit = unitsOf(LessonTrack.rhythm)
            .firstWhere((u) => u.art is StrumArt);
        final card = tester.getRect(find.byKey(Key('unit-${unit.id}')));
        // Dibujo de 64 dp con letra de 0.3 × 64: dos líneas no caben en 30 dp.
        expect(art.height, lessThan(30));
        expect(card.left, lessThanOrEqualTo(art.left));
        expect(art.right, lessThanOrEqualTo(card.right));
      });

      testWidgets('el reto muestra récord y meta en dos líneas', (tester) async {
        await open(tester, '/learn/lessons');
        for (final c in challenges) {
          final status = tester.widget<Text>(
            find.byKey(Key('challenge-status-${c.id}')),
          );
          expect('\n'.allMatches(status.data!).length, 1);
        }
      });

      testWidgets('toda unidad muestra su título debajo del dibujo y a todo lo ancho', (
        tester,
      ) async {
        await open(tester, '/learn/lessons');
        for (final track in LessonTrack.values) {
          for (final unit in unitsOf(track)) {
            appRouter.go('/learn/lessons/unit/${unit.id}');
            for (var i = 0; i < 5; i++) {
              await tester.pump(const Duration(milliseconds: 300));
            }
            final title = find.byKey(const Key('unit-title'));
            final art = find.byType(UnitArtView).last;
            expect(
              tester.getRect(art).bottom,
              lessThanOrEqualTo(tester.getRect(title).top),
              reason: unit.id,
            );
            // 360 − 32 de la lista − 8 de margen − 32 del relleno de la tarjeta.
            expect(tester.getSize(title).width, 288, reason: unit.id);
          }
        }
      });
    });
  }
}
