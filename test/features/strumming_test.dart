import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/audio/pluck_synth.dart';
import 'package:chordmaster_free/domain/courses/course.dart';
import 'package:chordmaster_free/domain/open_chords/chord_shape.dart';
import 'package:chordmaster_free/domain/strumming/strumming_course.dart';
import 'package:chordmaster_free/features/courses/course_progress.dart';
import 'package:chordmaster_free/features/lessons/lesson_widgets.dart';
import 'package:chordmaster_free/features/strumming/strumming_course_provider.dart';
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
  Future<void> playTab(List<StringSound> sounds, {required double seconds}) async =>
      played.add(sounds);

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
    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    // chords.json se decodifica en otro isolate: hace falta tiempo real.
    for (var i = 0; i < 5 && container.read(strummingCourseProvider) == null; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
      await settle(tester);
    }
    return (store, audio, container);
  }

  testWidgets('el mapa de Lecciones enlaza el curso con todos sus niveles y pasos', (tester) async {
    final (_, _, container) = await open(tester, '/learn/lessons', size: const Size(500, 20000));
    final node = find.byKey(const Key('unit-r_strumming_patterns_1'));
    await tester.ensureVisible(node);
    await tester.pump();
    await tester.tap(node);
    await settle(tester);
    for (var i = 0; i < 5 && container.read(strummingCourseProvider) == null; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
      await settle(tester);
    }
    expect(find.byKey(const Key('unit-title')), findsOneWidget);
    final levels = container.read(strummingCourseProvider)!;
    expect(levels, hasLength(12));
    for (var i = 0; i < levels.length; i++) {
      expect(find.byKey(Key('course-level-$i'), skipOffstage: false), findsOneWidget);
      for (final s in levels[i].steps) {
        expect(find.byKey(Key('course-step-${s.id}'), skipOffstage: false), findsOneWidget);
      }
    }
  });

  testWidgets('la teoría dibuja su patrón', (tester) async {
    await open(tester, '/learn/lessons/course/strumming/sp4_learn');
    final view = tester.widget<StrumPatternView>(find.byType(StrumPatternView));
    expect(view.pattern, strummingPatterns[3]);
    expect(find.byKey(const Key('course-read')), findsOneWidget);
  });

  testWidgets('practicar suena con el patrón de cada compás y guarda el tempo', (
    tester,
  ) async {
    final (store, audio, container) = await open(tester, '/learn/lessons/course/strumming/sp4_one');
    expect(find.byKey(const Key('strum-pattern')), findsOneWidget);
    final play = find.byKey(const Key('tab-play'));
    await tester.ensureVisible(play);
    await tester.pump();
    await tester.tap(play);
    await tester.pump();
    final step = courseSteps(container.read(strummingCourseProvider)!)
        .firstWhere((s) => s.id == 'sp4_one');
    // 4 compases de Em con el patrón 4: 3 golpes abajo (6 cuerdas) y 3 arriba.
    expect(
      audio.played.single,
      hasLength(step.slots.length * (3 * 6 + 3 * upStrumStrings)),
    );
    await tester.tap(play);
    await tester.pump();
    final clean = find.byKey(const Key('course-clean'));
    await tester.ensureVisible(clean);
    await tester.pump();
    await tester.tap(clean);
    await tester.pump();
    expect(store.progress[CourseId.strumming.keyBest], {'sp4_one': 60});
  });

  for (final code in ['es', 'en']) {
    testWidgets('a 360 dp ($code) el curso y cada paso sin desbordes', (tester) async {
      final (_, _, container) = await open(
        tester,
        '/learn/lessons/unit/r_strumming_patterns_1',
        code: code,
        size: const Size(360, 6000),
      );
      expect(tester.takeException(), isNull);
      for (final s in courseSteps(container.read(strummingCourseProvider)!)) {
        appRouter.go('/learn/lessons/course/strumming/${s.id}');
        await settle(tester);
        expect(tester.takeException(), isNull, reason: s.id);
      }
    });
  }
}
