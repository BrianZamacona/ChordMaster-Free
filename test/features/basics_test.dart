import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/audio/pluck_synth.dart';
import 'package:chordmaster_free/domain/melodies/basics_course.dart';
import 'package:chordmaster_free/domain/melodies/melody_course.dart';
import 'package:chordmaster_free/features/courses/course_progress.dart';
import 'package:chordmaster_free/features/courses/course_widgets.dart';
import 'package:chordmaster_free/services/audio_service.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_store.dart';

class _FakeAudio extends AudioService {
  _FakeAudio() : super.forTesting();

  final played = <List<NoteEvent>>[];

  @override
  Future<void> playNotes(
    List<NoteEvent> events, {
    double seconds = 2.5,
    double? ring,
  }) async =>
      played.add(events);

  @override
  Future<void> stopAll() async {}
}

void main() {
  tearDown(() => CurrentLanguage.value = AppLanguage.es);

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
    Map<String, Object?>? progress,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final store = InMemoryStore(settings: {'localeCode': code}, progress: progress);
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

  testWidgets('el mapa de Lecciones enlaza el curso con todos sus niveles y pasos', (tester) async {
    await open(tester, '/learn/lessons', size: const Size(500, 20000));
    final node = find.byKey(const Key('unit-f_basics'));
    await tester.ensureVisible(node);
    await tester.pump();
    await tester.tap(node);
    await settle(tester);
    expect(find.byKey(const Key('unit-title')), findsOneWidget);
    for (var i = 0; i < basicsCourse.length; i++) {
      expect(find.byKey(Key('course-level-$i'), skipOffstage: false), findsOneWidget);
      for (final s in basicsCourse[i].steps) {
        expect(find.byKey(Key('course-step-${s.id}'), skipOffstage: false), findsOneWidget);
      }
    }
    expect(find.byKey(const Key('course-results'), skipOffstage: false), findsOneWidget);
  });

  testWidgets('las estrellas guardadas se ven en el curso', (tester) async {
    await open(tester, '/learn/lessons/unit/f_basics', progress: {
      CourseId.basics.keyBest: {'b_open': 85},
    });
    final stars = tester.widget<CourseStars>(
      find.byKey(const Key('course-stars-b_open')),
    );
    expect(stars.stars, 2);
  });

  testWidgets('una canción suena entera y "Me salió limpio" da su estrella', (
    tester,
  ) async {
    final (store, audio) = await open(tester, '/learn/lessons/course/basics/b_open');
    // Sin récord empieza en el tempo de la primera estrella.
    expect(
      tester.widget<Text>(find.byKey(const Key('course-bpm'))).data,
      AppStrings.techniqueBpm(60),
    );
    final play = find.byKey(const Key('tab-play'));
    await tester.ensureVisible(play);
    await tester.pump();
    await tester.tap(play);
    await tester.pump();
    final step = basicsStepsById['b_open']!;
    expect(audio.played.single, hasLength(step.pitches.length));
    expect(audio.played.single.first.midi, pitchMidi(step.pitches.first));
    await tester.tap(play);
    await tester.pump();
    final clean = find.byKey(const Key('course-clean'));
    await tester.ensureVisible(clean);
    await tester.pump();
    await tester.tap(clean);
    await tester.pump();
    expect(store.progress[CourseId.basics.keyBest], {'b_open': 60});
    expect(
      tester.widget<CourseStars>(find.byKey(const Key('course-step-stars'))).stars,
      1,
    );
  });

  testWidgets('la teoría se marca como leída', (tester) async {
    final (store, _) = await open(tester, '/learn/lessons/course/basics/b_meet');
    await tester.tap(find.byKey(const Key('course-read')));
    await tester.pump();
    expect(store.progress[CourseId.basics.keyRead], ['b_meet']);
    expect(find.text(AppStrings.courseUnread), findsOneWidget);
  });

  testWidgets('"Siguiente paso" reemplaza y atrás vuelve al curso', (tester) async {
    await open(tester, '/learn/lessons/unit/f_basics');
    await tester.tap(find.byKey(const Key('course-step-b_meet')));
    await settle(tester);
    final next = find.byKey(const Key('course-next'));
    await tester.ensureVisible(next);
    await tester.pump();
    await tester.tap(next);
    await settle(tester);
    expect(
      tester.widget<Text>(find.byKey(const Key('course-title'))).data,
      basicsStepsById['b_tune']!.title.text,
    );
    appRouter.pop();
    await settle(tester);
    expect(find.byKey(const Key('unit-title')), findsOneWidget);
  });

  for (final code in ['es', 'en']) {
    testWidgets('a 360 dp ($code) el curso y cada paso sin desbordes', (tester) async {
      await open(tester, '/learn/lessons/unit/f_basics', code: code, size: const Size(360, 5000));
      expect(tester.takeException(), isNull);
      for (final id in basicsStepsById.keys) {
        appRouter.go('/learn/lessons/course/basics/$id');
        await settle(tester);
        expect(tester.takeException(), isNull, reason: id);
      }
    });
  }
}
