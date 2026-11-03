import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/domain/lessons/curriculum.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
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
    Future<InMemoryStore> open(WidgetTester tester, String location) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(500, 1400);
      addTearDown(tester.view.reset);
      final store = InMemoryStore();
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

    testWidgets('la ruta muestra Fundamentos, los dos caminos y la siguiente', (
      tester,
    ) async {
      await open(tester, '/learn/lessons');
      expect(find.byKey(const Key('lessons-start-next')), findsOneWidget);
      expect(find.byKey(Key('lesson-${foundations.first}')), findsOneWidget);
      expect(find.byKey(const Key('lessons-track-rhythm')), findsOneWidget);
      expect(find.byKey(const Key('lessons-track-lead')), findsOneWidget);
    });

    testWidgets('al elegir líder se muestran sus lecciones', (tester) async {
      final store = await open(tester, '/learn/lessons');
      final firstLead = lessonsOf(LessonTrack.lead).first.id;
      final firstRhythm = lessonsOf(LessonTrack.rhythm).first.id;
      expect(find.byKey(Key('lesson-$firstLead')), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('lessons-track-lead')));
      await tester.tap(find.byKey(const Key('lessons-track-lead')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(store.progress[LessonsViewModel.keyTrack], 'lead');
      expect(find.byKey(Key('lesson-$firstLead')), findsOneWidget);
      expect(find.byKey(Key('lesson-$firstRhythm')), findsNothing);
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
}
