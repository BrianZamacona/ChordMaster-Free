import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/audio/pluck_synth.dart';
import 'package:chordmaster_free/domain/lessons/curriculum.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/tapping/tapping_course.dart';
import 'package:chordmaster_free/features/courses/course_progress.dart';
import 'package:chordmaster_free/services/audio_service.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_store.dart';

class _FakeAudio extends AudioService {
  _FakeAudio() : super.forTesting();

  final played = <List<StringSound>>[];

  @override
  Future<void> playTab(List<StringSound> sounds, {required double seconds}) async => played.add(sounds);

  @override
  Future<void> stopAll() async {}
}

void main() {
  tearDown(() => CurrentLanguage.value = AppLanguage.es);
  final unit = unitOfCourse(LessonCourse.tapping);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<(InMemoryStore, _FakeAudio)> open(
    WidgetTester tester,
    String location, {
    String code = 'es',
    Size size = const Size(500, 3000),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final store = InMemoryStore(settings: {'localeCode': code});
    final audio = _FakeAudio();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(store),
          audioServiceProvider.overrideWithValue(audio),
        ],
        child: const ChordMasterApp(),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    appRouter.go(location);
    await settle(tester);
    return (store, audio);
  }

  testWidgets('el nodo del mapa abre el curso con todos sus niveles y pasos', (tester) async {
    await open(tester, '/learn/lessons/unit/${unit.id}');
    expect(find.byKey(const Key('unit-title')), findsOneWidget);
    for (var i = 0; i < tappingCourse.length; i++) {
      expect(find.byKey(Key('course-level-$i'), skipOffstage: false), findsOneWidget);
      for (final s in tappingCourse[i].steps) {
        expect(find.byKey(Key('course-step-${s.id}'), skipOffstage: false), findsOneWidget);
      }
    }
    // Sin canciones: los resultados no dicen "0/0 canciones".
    final results = find.byKey(const Key('course-results'), skipOffstage: false);
    expect(results, findsOneWidget);
    expect(find.descendant(of: results, matching: find.text(AppStrings.courseSongsLabel), skipOffstage: false), findsNothing);
  });

  testWidgets('un ejercicio suena con sus taps y "Me salió limpio" guarda el tempo', (tester) async {
    final (store, audio) = await open(tester, '/learn/lessons/course/tapping/tp1_arpeggio');
    expect(find.text(AppStrings.tappingPlayerNote), findsOneWidget);
    final play = find.byKey(const Key('tab-play'));
    await tester.ensureVisible(play);
    await tester.pump();
    await tester.tap(play);
    await tester.pump();
    // Cada tap vuelve a hacer sonar la cuerda; pull-off y hammer-on, no.
    final step = tappingStepsById['tp1_arpeggio']!;
    final taps = step.tab.where((n) => n.technique == TabTechnique.tap).length;
    expect(audio.played.single, hasLength(taps));
    await tester.tap(play);
    await tester.pump();
    final clean = find.byKey(const Key('course-clean'));
    await tester.ensureVisible(clean);
    await tester.pump();
    await tester.tap(clean);
    await tester.pump();
    expect(store.progress[CourseId.tapping.keyBest], {'tp1_arpeggio': 60});
  });

  for (final code in ['es', 'en']) {
    testWidgets('a 360 dp ($code) el curso y cada paso sin desbordes', (tester) async {
      await open(tester, '/learn/lessons/unit/${unit.id}', code: code, size: const Size(360, 5000));
      expect(tester.takeException(), isNull);
      for (final id in tappingStepsById.keys) {
        appRouter.go('/learn/lessons/course/tapping/$id');
        await settle(tester);
        expect(tester.takeException(), isNull, reason: id);
      }
      // El mapa con el nodo nuevo, al final de líder.
      appRouter.go('/learn/lessons');
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.byKey(Key('unit-${unit.id}'), skipOffstage: false), findsOneWidget);
    });
  }
}
