import 'dart:async';

import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/courses/course.dart';
import 'package:chordmaster_free/domain/lessons/curriculum.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/lessons/lesson_path.dart';
import 'package:chordmaster_free/domain/lessons/unit_summary.dart';
import 'package:chordmaster_free/domain/melodies/basics_course.dart';
import 'package:chordmaster_free/domain/melodies/melody_course.dart';
import 'package:chordmaster_free/features/circle/circle_screen.dart';
import 'package:chordmaster_free/features/courses/course_progress.dart';
import 'package:chordmaster_free/features/lessons/lesson_tab.dart';
import 'package:chordmaster_free/features/lessons/lesson_widgets.dart';
import 'package:chordmaster_free/features/lessons/lessons_viewmodel.dart';
import 'package:chordmaster_free/features/progressions/progressions_screen.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:chordmaster_free/ui/scales/double_stops/double_stops_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_store.dart';

void main() {
  // La primera unidad de lecciones del mapa (Fundamentos son cursos).
  final lessonUnit = lessonUnits.firstWhere((u) => u.course == null);
  final first = [for (final l in lessonsOfUnit(lessonUnit)) l.id];

  /// Progreso guardado con los cursos de Fundamentos terminados (todas las
  /// estrellas y la teoría leída), salvo [except].
  Map<String, Object?> foundationsDone({String? except}) => {
    for (final (id, levels) in [
      (CourseId.basics, basicsCourse),
      (CourseId.melodies, melodyCourse),
    ]) ...{
      id.keyBest: {
        for (final s in courseSteps(levels))
          if (s.kind != CourseStepKind.theory && s.id != except) s.id: 100,
      },
      id.keyRead: [
        for (final s in courseSteps(levels))
          if (s.kind == CourseStepKind.theory && s.id != except) s.id,
      ],
    },
  };

  Future<ProviderContainer> containerWith(InMemoryStore store) async {
    final container = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    container
      ..read(lessonsViewModelProvider)
      ..read(foundationsDoneProvider);
    await Future<void>.delayed(Duration.zero);
    return container;
  }

  group('LessonsViewModel', () {
    test('lee lo guardado: terminadas y camino; lo primero es Fundamentos', () async {
      final store = InMemoryStore(progress: {
        LessonsViewModel.keyCompleted: [first.first],
        LessonsViewModel.keyTrack: 'lead',
      });
      final container = await containerWith(store);
      final state = container.read(lessonsViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.chosen, LessonTrack.lead);
      expect(state.completed, {first.first});
      expect(container.read(foundationsDoneProvider), isFalse);
      // Fundamentos son cursos: lo que toca es el primero.
      final next = LessonPath(completed: state.completed, chosen: state.chosen).next;
      expect(next, isA<NextCourse>());
      expect(next!.unit, unitOfCourse(LessonCourse.basics));
    });

    test('con Fundamentos terminado, el camino sigue por el elegido', () async {
      final container = await containerWith(InMemoryStore(progress: foundationsDone()));
      expect(container.read(foundationsDoneProvider), isTrue);
      final done = {
        LessonCourse.basics: (courseSteps(basicsCourse).length, courseSteps(basicsCourse).length),
        LessonCourse.melodies: (courseSteps(melodyCourse).length, courseSteps(melodyCourse).length),
      };
      final path = LessonPath(completed: const {}, chosen: LessonTrack.rhythm, courses: done);
      expect(path.next?.unit.track, LessonTrack.rhythm);
    });

    test('marcar y desmarcar guarda la lista', () async {
      final store = InMemoryStore();
      final container = await containerWith(store);
      final vm = container.read(lessonsViewModelProvider.notifier);

      await vm.toggleCompleted(first.first);
      expect(store.progress[LessonsViewModel.keyCompleted], [first.first]);

      await vm.toggleCompleted(first.first);
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
      expect(highlightedTrackOf(fresh.read(lessonsViewModelProvider), foundationsDone: fresh.read(foundationsDoneProvider)), isNull);

      final done = await containerWith(InMemoryStore(progress: foundationsDone()));
      expect(highlightedTrackOf(done.read(lessonsViewModelProvider), foundationsDone: done.read(foundationsDoneProvider)), LessonTrack.rhythm);

      final saved = await containerWith(
        InMemoryStore(progress: {LessonsViewModel.keyTrack: 'lead'}),
      );
      expect(highlightedTrackOf(saved.read(lessonsViewModelProvider), foundationsDone: saved.read(foundationsDoneProvider)), LessonTrack.lead);
    });

    test('tocar el camino por defecto antes de tiempo también lo elige', () async {
      final store = InMemoryStore();
      final container = await containerWith(store);

      await container
          .read(lessonsViewModelProvider.notifier)
          .choose(LessonTrack.rhythm);
      expect(store.progress[LessonsViewModel.keyTrack], 'rhythm');
      expect(highlightedTrackOf(container.read(lessonsViewModelProvider), foundationsDone: container.read(foundationsDoneProvider)), LessonTrack.rhythm);
    });

    testWidgets('terminar Fundamentos (su último paso) desbloquea su logro', (
      tester,
    ) async {
      final store = InMemoryStore(progress: foundationsDone(except: 'mf_part3'));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [keyValueStoreProvider.overrideWithValue(store)],
          child: const ChordMasterApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(store.achievements['foundations_done'], isNull);
      final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
      await container
          .read(courseProgressProvider(CourseId.melodies).notifier)
          .saveClean('mf_part3', 60);
      await tester.pump(const Duration(milliseconds: 300));
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
      final rhythm = challengesOf(LessonTrack.rhythm, level: 1).single;
      final rhythm2 = challengesOf(LessonTrack.rhythm, level: 2).single;
      final lead = challengesOf(LessonTrack.lead, level: 1).single;
      await open(
        tester,
        '/learn/lessons',
        progress: {'rhythm_game_best_score': rhythm.goal},
      );
      String status(LessonChallenge c) => tester
          .widget<Text>(
            find.byKey(Key('challenge-status-${c.id}'), skipOffstage: false),
          )
          .data!;
      expect(status(rhythm), AppStrings.challengePassed);
      // El del nivel 2 pide más: con el mismo récord, aún no.
      expect(
        status(rhythm2),
        AppStrings.challengeRhythmBest(rhythm.goal, rhythm2.goal),
      );
      expect(status(lead), AppStrings.challengeEarBest(0, lead.goal));
    });

    testWidgets('el nivel 2 aparece entre el reto del nivel 1 y sus unidades', (
      tester,
    ) async {
      await open(tester, '/learn/lessons');
      final header = find.byKey(const Key('lessons-level-2'), skipOffstage: false);
      expect(header, findsOneWidget);
      double top(Finder f) => tester.getRect(f).top;
      final challenge1 = find.byKey(
        Key('challenge-${challengesOf(LessonTrack.rhythm, level: 1).single.id}'),
        skipOffstage: false,
      );
      final firstLevel2 = find.byKey(
        Key('unit-${unitsOf(LessonTrack.rhythm, level: 2).first.id}'),
        skipOffstage: false,
      );
      expect(top(challenge1), lessThan(top(header)));
      expect(top(header), lessThan(top(firstLevel2)));
    });

    testWidgets('las cuerdas del mapa se dibujan al abrir y terminan completas', (
      tester,
    ) async {
      await open(tester, '/learn/lessons');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('la unidad muestra qué se aprende y empieza por la primera', (
      tester,
    ) async {
      final unit = unitsOf(LessonTrack.rhythm, level: 2).first;
      await open(tester, '/learn/lessons/unit/${unit.id}');
      expect(
        tester.widget<Text>(find.byKey(const Key('unit-summary'))).data,
        unit.summary.text,
      );
      final start = find.byKey(const Key('unit-start'));
      expect(
        find.descendant(of: start, matching: find.text(AppStrings.lessonsStart)),
        findsOneWidget,
      );
      await tester.tap(start);
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.text(lessonsOfUnit(unit).first.title.text), findsWidgets);
    });

    testWidgets('con lecciones hechas, la unidad sigue por la pendiente', (
      tester,
    ) async {
      final unit = lessonUnit;
      final lessons = lessonsOfUnit(unit);
      await open(
        tester,
        '/learn/lessons/unit/${unit.id}',
        progress: {LessonsViewModel.keyCompleted: [lessons.first.id]},
      );
      final start = find.byKey(const Key('unit-start'));
      expect(
        find.descendant(of: start, matching: find.text(AppStrings.lessonsResume)),
        findsOneWidget,
      );
      await tester.tap(start);
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.text(lessons[1].title.text), findsWidgets);
    });

    testWidgets('con la unidad terminada, el botón es para repasar', (tester) async {
      final unit = lessonUnit;
      await open(
        tester,
        '/learn/lessons/unit/${unit.id}',
        progress: {
          LessonsViewModel.keyCompleted: [for (final l in lessonsOfUnit(unit)) l.id],
        },
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('unit-start')),
          matching: find.text(AppStrings.lessonsReview),
        ),
        findsOneWidget,
      );
    });

    testWidgets('una lección con tablatura la dibuja en renglones de 8', (
      tester,
    ) async {
      final lesson = curriculum.reduce((a, b) => b.tab.length > a.tab.length ? b : a);
      expect(lesson.tab, isNotEmpty);
      await open(tester, '/learn/lessons/${lesson.id}');
      expect(find.byType(LessonTabView), findsOneWidget);
      final lines = (lesson.tab.length + 7) ~/ 8;
      expect(find.byKey(Key('lesson-tab-line-${lines - 1}'), skipOffstage: false), findsOneWidget);
      expect(find.byKey(Key('lesson-tab-line-$lines'), skipOffstage: false), findsNothing);
    });

    testWidgets('el rasgueo en 6/8 se cuenta de 1 a 6', (tester) async {
      await open(tester, '/learn/lessons/r14_six_eight');
      for (var i = 1; i <= 6; i++) {
        expect(find.text('$i'), findsWidgets);
      }
      expect(find.text(AppStrings.lessonStrumAnd), findsNothing);
    });

    for (final (lessonId, screen) in [
      ('l17_thirds', DoubleStopsScreen),
      ('l16_neighbor_keys', CircleScreen),
      ('r13_color_chords', ProgressionsScreen),
    ]) {
      testWidgets('$lessonId abre $screen y atrás vuelve a la lección', (
        tester,
      ) async {
        await open(tester, '/learn/lessons/$lessonId');
        final button = find.byKey(const Key('lesson-open-tool'));
        await tester.ensureVisible(button);
        await tester.pump();
        await tester.tap(button);
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 300));
        }
        expect(find.byType(screen), findsOneWidget);
        await tester.pageBack();
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 300));
        }
        expect(find.byType(screen), findsNothing);
        expect(find.byKey(const Key('lesson-toggle-done')), findsOneWidget);
      });
    }

    testWidgets('la unidad lista sus lecciones', (tester) async {
      final unit = lessonUnit;
      await open(tester, '/learn/lessons/unit/${unit.id}');
      for (final lesson in lessonsOfUnit(unit)) {
        expect(find.byKey(Key('lesson-${lesson.id}')), findsOneWidget);
      }
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('la unidad dice dónde está y qué practica cada lección', (
      tester,
    ) async {
      final unit = lessonUnit;
      await open(tester, '/learn/lessons/unit/${unit.id}');
      final (index, total) = UnitSummary(unit).position;
      expect(
        tester.widget<Text>(find.byKey(const Key('unit-eyebrow'))).data,
        endsWith(AppStrings.unitPosition(index, total)),
      );
      // Cada lección con acordes los muestra en su paso.
      for (final lesson in lessonsOfUnit(unit)) {
        if (lesson.chords.isEmpty) continue;
        expect(
          find.descendant(
            of: find.byKey(Key('lesson-${lesson.id}')),
            matching: find.text(AppStrings.lessonChordList(lesson.chords.join(' '))),
          ),
          findsOneWidget,
          reason: lesson.id,
        );
      }
      expect(find.byKey(const Key('unit-results'), skipOffstage: false), findsOneWidget);
    });

    testWidgets('la última unidad de un nivel termina en su reto', (tester) async {
      final unit = unitsOf(LessonTrack.rhythm, level: 1).last;
      final challenge = challengesOf(LessonTrack.rhythm, level: 1).single;
      await open(tester, '/learn/lessons/unit/${unit.id}');
      expect(
        find.byKey(Key('unit-challenge-${challenge.id}'), skipOffstage: false),
        findsOneWidget,
      );
      // Las demás no.
      await open(
        tester,
        '/learn/lessons/unit/${unitsOf(LessonTrack.rhythm, level: 1).first.id}',
      );
      expect(
        find.byKey(Key('unit-challenge-${challenge.id}'), skipOffstage: false),
        findsNothing,
      );
    });

    testWidgets('"Siguiente unidad" reemplaza a esta y atrás vuelve al mapa', (
      tester,
    ) async {
      final rhythm = unitsOf(LessonTrack.rhythm);
      final units = rhythm.sublist(rhythm.indexOf(lessonUnit));
      await open(tester, '/learn/lessons');
      unawaited(appRouter.push('/learn/lessons/unit/${units.first.id}'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      final next = find.byKey(const Key('unit-next'));
      await tester.ensureVisible(next);
      await tester.pump();
      await tester.tap(next);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(
        tester.widget<Text>(find.byKey(const Key('unit-title'))).data,
        units[1].title.text,
      );
      appRouter.pop();
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.byKey(const Key('unit-title')), findsNothing);
    });

    testWidgets('al final de un camino no hay siguiente unidad', (tester) async {
      await open(tester, '/learn/lessons/unit/${unitsOf(LessonTrack.lead).last.id}');
      expect(find.byKey(const Key('unit-end'), skipOffstage: false), findsOneWidget);
      expect(find.byKey(const Key('unit-next'), skipOffstage: false), findsNothing);
    });

    testWidgets('el detalle marca la lección como completada', (tester) async {
      final store = await open(tester, '/learn/lessons/${first.first}');
      final button = find.byKey(const Key('lesson-toggle-done'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump(const Duration(milliseconds: 300));
      expect(store.progress[LessonsViewModel.keyCompleted], [first.first]);
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

  test('los dos caminos tienen tantos retos por nivel (el mapa va por filas)', () {
    for (final level in levelsOf(LessonTrack.rhythm)) {
      expect(
        challengesOf(LessonTrack.rhythm, level: level).length,
        challengesOf(LessonTrack.lead, level: level).length,
      );
    }
  });

  test('tablatura: nombres de cuerda de la afinación, la 1ª en minúscula', () {
    expect(tabStringNames, ['e', 'B', 'G', 'D', 'A', 'E']);
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
        // Nivel por nivel, la fila i de un camino va a la altura de la del
        // otro; si un camino tiene más unidades, el otro deja la celda vacía.
        for (final level in levelsOf(LessonTrack.rhythm)) {
          final r = unitsOf(LessonTrack.rhythm, level: level);
          final l = unitsOf(LessonTrack.lead, level: level);
          for (var i = 0; i < r.length && i < l.length; i++) {
            expectAligned(Key('unit-${r[i].id}'), Key('unit-${l[i].id}'));
          }
        }
        expect(rhythm, isNotEmpty);
        expect(lead, isNotEmpty);
        for (final level in levelsOf(LessonTrack.rhythm)) {
          expectAligned(
            Key('challenge-${challengesOf(LessonTrack.rhythm, level: level).single.id}'),
            Key('challenge-${challengesOf(LessonTrack.lead, level: level).single.id}'),
          );
        }
      });

      testWidgets('ninguna lección se desborda, con tablatura o sin ella', (
        tester,
      ) async {
        await open(tester, '/learn/lessons');
        for (final lesson in curriculum) {
          appRouter.go('/learn/lessons/${lesson.id}');
          for (var i = 0; i < 3; i++) {
            await tester.pump(const Duration(milliseconds: 300));
          }
          expect(tester.takeException(), isNull, reason: lesson.id);
          if (lesson.tab.isNotEmpty) {
            final line = tester.getRect(find.byKey(const Key('lesson-tab-line-0')));
            expect(line.left, greaterThanOrEqualTo(0), reason: lesson.id);
            expect(line.right, lessThanOrEqualTo(360), reason: lesson.id);
          }
        }
      });

      testWidgets('el separador del nivel 2 cabe a lo ancho', (tester) async {
        await open(tester, '/learn/lessons');
        final header = tester.getRect(find.byKey(const Key('lessons-level-2')));
        expect(header.left, greaterThanOrEqualTo(0));
        expect(header.right, lessThanOrEqualTo(360));
        expect(tester.takeException(), isNull);
      });

      testWidgets('el rasgueo del mapa queda en una línea', (tester) async {
        await open(tester, '/learn/lessons');
        final units = unitsOf(LessonTrack.rhythm).where((u) => u.art is StrumArt);
        expect(units.length, greaterThan(1));
        for (final unit in units) {
          final cardFinder = find.byKey(Key('unit-${unit.id}'));
          final art = tester.getRect(
            find.descendant(
              of: cardFinder,
              matching: find.byKey(const Key('unit-art-strum')),
            ),
          );
          final card = tester.getRect(cardFinder);
          // Dibujo de 64 dp con letra de 0.3 × 64: dos líneas no caben en 30 dp.
          expect(art.height, lessThan(30), reason: unit.id);
          expect(card.left, lessThanOrEqualTo(art.left), reason: unit.id);
          expect(art.right, lessThanOrEqualTo(card.right), reason: unit.id);
        }
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
            // Un curso espera las digitaciones de chords.json (otro isolate).
            for (var i = 0; i < 5 && title.evaluate().isEmpty; i++) {
              await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
              await tester.pump(const Duration(milliseconds: 300));
            }
            final art = find.byType(UnitArtView).first;
            expect(
              tester.getRect(art).bottom,
              lessThanOrEqualTo(tester.getRect(title).top),
              reason: unit.id,
            );
            // 360 − 32 de la lista − 32 del relleno de la tarjeta.
            expect(tester.getSize(title).width, 296, reason: unit.id);
          }
        }
      });
    });
  }
}
