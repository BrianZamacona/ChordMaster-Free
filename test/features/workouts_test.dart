import 'dart:io';

import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/data/repository/scale_repository.dart';
import 'package:chordmaster_free/domain/audio/pluck_synth.dart';
import 'package:chordmaster_free/domain/lessons/curriculum.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/practice/scale_workouts.dart';
import 'package:chordmaster_free/domain/practice/tab_playback.dart';
import 'package:chordmaster_free/features/lessons/lesson_tab.dart';
import 'package:chordmaster_free/features/lessons/tab_player.dart';
import 'package:chordmaster_free/features/workouts/workouts_screen.dart';
import 'package:chordmaster_free/services/audio_service.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:chordmaster_free/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_store.dart';

class _FileBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => throw UnimplementedError();

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      File(key).readAsStringSync();
}

/// Registra lo que se pidió sonar, sin reproducir nada.
class _FakeAudio extends AudioService {
  _FakeAudio() : super.forTesting();

  final played = <({List<NoteEvent> events, double seconds, double? ring})>[];
  int stops = 0;

  @override
  Future<void> playNotes(
    List<NoteEvent> events, {
    double seconds = 2.5,
    double? ring,
  }) async =>
      played.add((events: events, seconds: seconds, ring: ring));

  @override
  Future<void> stopAll() async => stops++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<_FakeAudio> open(
    WidgetTester tester,
    String location, {
    String code = 'es',
    Size size = const Size(500, 3200),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final audio = _FakeAudio();
    // El router es global: sin esto, abrir la misma ruta que el test anterior
    // no reconstruye la pantalla.
    appRouter.go('/');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(
            InMemoryStore(settings: {'localeCode': code}),
          ),
          audioServiceProvider.overrideWithValue(audio),
          // rootBundle guarda la lectura del primer test, atada a su zona de
          // tiempo falso: cada test lee el archivo por su cuenta.
          scaleRepositoryProvider.overrideWithValue(
            ScaleRepository(bundle: _FileBundle()),
          ),
        ],
        child: const ChordMasterApp(),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    appRouter.go(location);
    await settle(tester);
    // scales_master.json se lee de verdad: hace falta tiempo real.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    await settle(tester);
    return audio;
  }

  group('reproductor', () {
    const notes = [TabNote(1, 0), TabNote(1, 1), TabNote(1, 3)];

    Future<_FakeAudio> pumpPlayer(WidgetTester tester) async {
      final audio = _FakeAudio();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [audioServiceProvider.overrideWithValue(audio)],
          child: MaterialApp(
            theme: lightTheme,
            home: const Scaffold(
              body: Column(
                children: [
                  TabPlayer(key: Key('a'), notes: notes, bpm: 60),
                  TabPlayer(key: Key('b'), notes: notes, bpm: 120),
                ],
              ),
            ),
          ),
        ),
      );
      return audio;
    }

    LessonTabView tab(WidgetTester tester, String key) => tester.widget(
      find.descendant(of: find.byKey(Key(key)), matching: find.byType(LessonTabView)),
    );

    Finder play(String key) => find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byKey(const Key('tab-play')),
    );

    testWidgets('▶ toca la tablatura entera y marca cada nota a su tiempo', (
      tester,
    ) async {
      final audio = await pumpPlayer(tester);
      await tester.tap(play('a'));
      await tester.pump();
      expect(audio.played.single.events, tabEvents(notes, bpm: 60));
      expect(audio.played.single.ring, tabNoteRingSeconds);
      expect(tab(tester, 'a').highlight, 0);
      // Los instantes los da el reloj real del reproductor.
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
      await tester.pump(const Duration(milliseconds: 40));
      expect(tab(tester, 'a').highlight, 1);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1100)));
      await tester.pump(const Duration(milliseconds: 40));
      expect(tab(tester, 'a').highlight, isNull);
    });

    testWidgets('detener corta el audio y quita la marca', (tester) async {
      final audio = await pumpPlayer(tester);
      await tester.tap(play('a'));
      await tester.pump();
      await tester.tap(play('a'));
      await tester.pump();
      expect(audio.stops, 1);
      expect(tab(tester, 'a').highlight, isNull);
    });

    testWidgets('empezar otra tablatura detiene la anterior', (tester) async {
      final audio = await pumpPlayer(tester);
      await tester.tap(play('a'));
      await tester.pump();
      await tester.tap(play('b'));
      await tester.pump();
      expect(audio.played, hasLength(2));
      expect(tab(tester, 'a').highlight, isNull);
      expect(tab(tester, 'b').highlight, 0);
      await tester.tap(play('b'));
      await tester.pump();
    });
  });

  group('rutinas', () {
    testWidgets('Practicar enlaza las rutinas', (tester) async {
      await open(tester, '/practice');
      expect(find.text(AppStrings.hubWorkouts), findsOneWidget);
    });

    testWidgets('C mayor, principiante: 3NPS, la subida con 18 notas', (
      tester,
    ) async {
      await open(tester, '/practice/workouts');
      expect(find.byType(WorkoutsScreen), findsOneWidget);
      expect(find.byKey(const Key('workout-upDown')), findsOneWidget);
      expect(find.text(AppStrings.workoutsNoteCount(18)), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('workouts-position'))).data,
        contains('3NPS'),
      );
    });

    testWidgets('cada nivel muestra sus patrones', (tester) async {
      await open(tester, '/practice/workouts');
      for (final level in WorkoutLevel.values) {
        await tester.tap(find.text(workoutLevelName(level).text));
        await tester.pump();
        for (final pattern in WorkoutPattern.values) {
          expect(
            find.byKey(Key('workout-${pattern.name}'), skipOffstage: false),
            workoutPatterns[level]!.contains(pattern) ? findsOneWidget : findsNothing,
            reason: '${level.name} ${pattern.name}',
          );
        }
      }
    });

    testWidgets('"Agregar la bajada" suma la vuelta y se puede quitar', (
      tester,
    ) async {
      final audio = await open(tester, '/practice/workouts');
      await tester.tap(find.text(workoutLevelName(WorkoutLevel.advanced).text));
      await tester.pump();
      String count() => tester
          .widget<Text>(find.byKey(const Key('workout-count-groupsOf4')))
          .data!;
      expect(count(), AppStrings.workoutsNoteCount(60));
      final toggle = find.byKey(const Key('workout-down-groupsOf4'));
      await tester.ensureVisible(toggle);
      await tester.pump();
      await tester.tap(toggle);
      await tester.pump();
      expect(count(), AppStrings.workoutsNoteCount(120));
      // Lo que suena es lo que se ve.
      final play = find.descendant(
        of: find.byKey(const Key('workout-groupsOf4')),
        matching: find.byKey(const Key('tab-play')),
      );
      await tester.ensureVisible(play);
      await tester.pump();
      await tester.tap(play);
      await tester.pump();
      expect(audio.played.single.events, hasLength(120));
      await tester.tap(play);
      await tester.pump();
      await tester.ensureVisible(toggle);
      await tester.pump();
      await tester.tap(toggle);
      await tester.pump();
      expect(count(), AppStrings.workoutsNoteCount(60));
    });

    testWidgets('‹ › cambian de posición', (tester) async {
      await open(tester, '/practice/workouts');
      String position() =>
          tester.widget<Text>(find.byKey(const Key('workouts-position'))).data!;
      final first = position();
      expect(
        tester.widget<IconButton>(find.byKey(const Key('workouts-previous'))).onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const Key('workouts-next')));
      await tester.pump();
      expect(position(), isNot(first));
    });

    testWidgets('pentatónica desde una guía: abre en la caja, en su tónica', (
      tester,
    ) async {
      await open(tester, '/practice/workouts?scale=pentatonic_minor&root=9');
      expect(
        tester.widget<Text>(find.byKey(const Key('workouts-position'))).data,
        contains('2NPS'),
      );
      expect(find.text('${AppStrings.scaleTonic}: A'), findsOneWidget);
    });

    testWidgets('cambiar de escala recarga las posiciones', (tester) async {
      await open(tester, '/practice/workouts');
      await tester.tap(find.byKey(const Key('workouts-scale')));
      await settle(tester);
      final option = find.byKey(const Key('workouts-scale-blues_minor'));
      await tester.ensureVisible(option);
      await tester.tap(option);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await settle(tester);
      expect(
        tester.widget<Text>(find.byKey(const Key('workouts-position'))).data,
        contains('2NPS'),
      );
    });

    testWidgets('▶ en una rutina toca sus notas al tempo del nivel', (tester) async {
      final audio = await open(tester, '/practice/workouts');
      await tester.tap(find.byKey(const Key('tab-play')).first);
      await tester.pump();
      final events = audio.played.single.events;
      expect(events, hasLength(18));
      expect(
        events[1].at - events[0].at,
        closeTo(tabStepSeconds(workoutBpm[WorkoutLevel.beginner]!), 1e-9),
      );
      await tester.tap(find.byKey(const Key('tab-play')).first);
      await tester.pump();
    });

    testWidgets('la lección con tablatura también se escucha', (tester) async {
      final lesson = curriculum.firstWhere((l) => l.tab.isNotEmpty);
      final audio = await open(tester, '/learn/lessons/${lesson.id}');
      final button = find.byKey(const Key('tab-play'));
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
      expect(audio.played.single.events, hasLength(lesson.tab.length));
      await tester.tap(button);
      await tester.pump();
    });
  });

  for (final code in ['es', 'en']) {
    testWidgets('a 360 dp ($code): las rutinas caben en todos los niveles', (
      tester,
    ) async {
      await open(tester, '/practice/workouts', code: code, size: const Size(360, 3200));
      for (final level in WorkoutLevel.values) {
        await tester.tap(find.text(workoutLevelName(level).text));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: level.name);
      }
      final line = tester.getRect(find.byKey(const Key('lesson-tab-line-0')).first);
      expect(line.right, lessThanOrEqualTo(360));
    });
  }
}
