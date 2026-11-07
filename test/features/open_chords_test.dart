import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/audio/pluck_synth.dart';
import 'package:chordmaster_free/domain/courses/course.dart';
import 'package:chordmaster_free/features/courses/course_progress.dart';
import 'package:chordmaster_free/features/courses/course_widgets.dart';
import 'package:chordmaster_free/features/open_chords/open_chords_course_provider.dart';
import 'package:chordmaster_free/features/open_chords/open_chords_screen.dart';
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

  Future<(InMemoryStore, _FakeAudio, ProviderContainer)> open(
    WidgetTester tester,
    String location, {
    String code = 'es',
    Size size = const Size(500, 4000),
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
    // chords.json se decodifica en otro isolate: hace falta tiempo real.
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    await settle(tester);
    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    return (store, audio, container);
  }

  testWidgets('Aprender enlaza el curso con todos sus niveles y pasos', (tester) async {
    final (_, _, container) = await open(tester, '/learn', size: const Size(500, 20000));
    await tester.tap(find.text(AppStrings.hubOpenChords));
    await settle(tester);
    // chords.json se decodifica en otro isolate: hace falta tiempo real.
    for (var i = 0; i < 5 && container.read(openChordsCourseProvider) == null; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
      await settle(tester);
    }
    expect(find.byType(OpenChordsScreen), findsOneWidget);
    final levels = container.read(openChordsCourseProvider)!;
    expect(levels, hasLength(11));
    for (var i = 0; i < levels.length; i++) {
      expect(find.byKey(Key('course-level-$i'), skipOffstage: false), findsOneWidget);
      for (final s in levels[i].steps) {
        expect(find.byKey(Key('course-step-${s.id}'), skipOffstage: false), findsOneWidget);
      }
    }
    expect(find.byKey(const Key('course-results'), skipOffstage: false), findsOneWidget);
  });

  testWidgets('las estrellas guardadas se ven en el curso', (tester) async {
    await open(tester, '/learn/open-chords', progress: {
      CourseId.openChords.keyBest: {'oc_em_full': 100},
    });
    final stars = tester.widget<CourseStars>(find.byKey(const Key('course-stars-oc_em_full')));
    expect(stars.stars, 3);
  });

  testWidgets('"Solo el dedo medio": diagrama a medio armar y un golpe por pulso', (
    tester,
  ) async {
    final (store, audio, container) = await open(tester, '/learn/open-chords/oc_em_f1');
    expect(find.byKey(const Key('course-diagram-0')), findsOneWidget);
    final play = find.byKey(const Key('tab-play'));
    await tester.ensureVisible(play);
    await tester.pump();
    await tester.tap(play);
    await tester.pump();
    final step = courseSteps(container.read(openChordsCourseProvider)!)
        .firstWhere((s) => s.id == 'oc_em_f1');
    // 4 compases de 4 pulsos, un golpe por pulso con las cuerdas que suenan.
    expect(audio.played.single, hasLength(16 * step.slots.first.midi.length));
    await tester.tap(play);
    await tester.pump();
    final clean = find.byKey(const Key('course-clean'));
    await tester.ensureVisible(clean);
    await tester.pump();
    await tester.tap(clean);
    await tester.pump();
    expect(store.progress[CourseId.openChords.keyBest], {'oc_em_f1': 60});
  });

  testWidgets('una canción muestra sus compases', (tester) async {
    await open(tester, '/learn/open-chords/oc_song_skip_to_my_lou');
    expect(find.byKey(const Key('strum-chart')), findsOneWidget);
    expect(find.byKey(const Key('strum-slot-7')), findsOneWidget);
    expect(find.text('Tradicional (EE. UU., s. XIX)'), findsWidgets);
  });

  testWidgets('la teoría se marca como leída y "Siguiente paso" avanza', (tester) async {
    final (store, _, _) = await open(tester, '/learn/open-chords/oc_em_howto');
    await tester.tap(find.byKey(const Key('course-read')));
    await tester.pump();
    expect(store.progress[CourseId.openChords.keyRead], ['oc_em_howto']);
    final next = find.byKey(const Key('course-next'));
    await tester.ensureVisible(next);
    await tester.pump();
    await tester.tap(next);
    await settle(tester);
    expect(
      tester.widget<Text>(find.byKey(const Key('course-title'))).data,
      'Solo el dedo medio',
    );
  });

  for (final code in ['es', 'en']) {
    testWidgets('a 360 dp ($code) el curso y cada paso sin desbordes', (tester) async {
      final (_, _, container) = await open(
        tester,
        '/learn/open-chords',
        code: code,
        size: const Size(360, 6000),
      );
      expect(tester.takeException(), isNull);
      for (final s in courseSteps(container.read(openChordsCourseProvider)!)) {
        appRouter.go('/learn/open-chords/${s.id}');
        await settle(tester);
        expect(tester.takeException(), isNull, reason: s.id);
      }
    });
  }
}
