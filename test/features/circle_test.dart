import 'dart:math' as math;

import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/constants/chord_metadata.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/theory/circle_of_fifths.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:chordmaster_free/features/chords/chord_detail_screen.dart';
import 'package:chordmaster_free/features/chords/chord_viewmodel.dart';
import 'package:chordmaster_free/features/circle/circle_build_ring.dart';
import 'package:chordmaster_free/features/circle/circle_build_screen.dart';
import 'package:chordmaster_free/features/circle/circle_viewmodel.dart';
import 'package:chordmaster_free/features/circle/circle_wheel.dart';
import 'package:chordmaster_free/features/progressions/progressions_viewmodel.dart';
import 'package:chordmaster_free/services/audio_service.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:chordmaster_free/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/chord_data.dart';
import '../support/in_memory_store.dart';

class _FakeAudio extends AudioService {
  _FakeAudio() : super.forTesting();

  final fingerings = <String>[];
  int ticks = 0;

  @override
  Future<void> playFingering(List<int> jsonFrets) async =>
      fingerings.add(jsonFrets.join(','));

  @override
  Future<void> playMetronomeTick({bool isAccent = false}) async => ticks++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('todos los acordes diatónicos existen en chords.json', () {
    final names = {
      for (final c in loadChordJson())
        chordDisplayName(
          root: c['root'] as String,
          type: c['type'] as String,
          explicitDisplayName: c['displayName'] as String?,
        ),
    };
    for (final tonic in circleOrder) {
      for (final chord in diatonicWindow(tonic)) {
        final name = chordDisplayName(
          root: pitchClassName(chord.root),
          type: chord.type,
        );
        expect(names, contains(name), reason: chord.numeral);
      }
    }
  });

  group('rueda sola', () {
    Future<GlobalKey<CircleWheelState>> pumpWheel(
      WidgetTester tester, {
      List<int>? changes,
      bool reduceMotion = false,
      int initial = 0,
    }) async {
      final key = GlobalKey<CircleWheelState>();
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(360, 780),
              disableAnimations: reduceMotion,
            ),
            child: Scaffold(
              body: SizedBox.square(
                dimension: 360,
                child: CircleWheel(
                  key: key,
                  initialIndex: initial,
                  semanticLabel: 'etiqueta',
                  onIndexChanged: (i) => changes?.add(i),
                ),
              ),
            ),
          ),
        ),
      );
      return key;
    }

    Finder gestures() => find.byKey(const Key('circle-wheel-gestures'));

    Offset rightEdge(WidgetTester tester) =>
        tester.getCenter(gestures()) + const Offset(120, 0);

    bool aligned(double rotation) => rotation % wheelStepDegrees == 0;

    testWidgets(
      'un arrastre lento cambia la tonalidad y queda en múltiplo de 30°',
      (tester) async {
        final changes = <int>[];
        final key = await pumpWheel(tester, changes: changes);
        // Del borde derecho hacia abajo: giro horario de unos 45°.
        await tester.timedDragFrom(
          rightEdge(tester),
          const Offset(-20, 120),
          const Duration(seconds: 2),
        );
        await tester.pumpAndSettle();
        final rotation = key.currentState!.rotation;
        expect(aligned(rotation), isTrue, reason: '$rotation');
        expect(rotation, greaterThan(0));
        expect(changes, isNotEmpty);
        expect(changes.last, indexAtWindow(rotation));
      },
    );

    testWidgets('un fling sigue girando con inercia y se alinea al detenerse', (
      tester,
    ) async {
      final changes = <int>[];
      final key = await pumpWheel(tester, changes: changes);
      await tester.flingFrom(rightEdge(tester), const Offset(0, 100), 1500);
      await tester.pump(const Duration(milliseconds: 50));
      final justAfter = key.currentState!.rotation;
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        key.currentState!.rotation,
        greaterThan(justAfter),
        reason: 'inercia',
      );
      await tester.pumpAndSettle();
      final rotation = key.currentState!.rotation;
      expect(aligned(rotation), isTrue, reason: '$rotation');
      expect(changes.last, indexAtWindow(rotation));
    });

    testWidgets('vibra una vez por cada tonalidad que pasa', (tester) async {
      final vibrations = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            vibrations.add(call.arguments as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final key = await pumpWheel(tester);
      await tester.tap(find.byKey(const Key('circle-step-right')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('circle-step-right')));
      await tester.pumpAndSettle();
      expect(indexAtWindow(key.currentState!.rotation), 2);
      expect(vibrations, hasLength(2));
      expect(vibrations.toSet(), {'HapticFeedbackType.selectionClick'});
    });

    testWidgets('tocar una tonalidad la trae por el camino más corto', (
      tester,
    ) async {
      final key = await pumpWheel(tester);
      final center = tester.getCenter(gestures());
      // Arriba a la izquierda, en el anillo exterior: F, la posición 11.
      const radius = (360 / 2 - 18) * 0.84;
      const a = -30 * math.pi / 180;
      await tester.tapAt(
        center + Offset(radius * math.sin(a), -radius * math.cos(a)),
      );
      await tester.pumpAndSettle();
      expect(key.currentState!.rotation, 30, reason: 'un paso, no once');
    });

    testWidgets('los botones cruzan 11 → 0 sin dar la vuelta', (tester) async {
      final key = await pumpWheel(tester, initial: 11);
      expect(key.currentState!.rotation, rotationForIndex(11));
      await tester.tap(find.byKey(const Key('circle-step-right')));
      await tester.pumpAndSettle();
      expect(key.currentState!.rotation, rotationForIndex(11) - 30);
      expect(indexAtWindow(key.currentState!.rotation), 0);
    });

    testWidgets('con "reducir movimiento" no hay inercia: salta directo', (
      tester,
    ) async {
      final key = await pumpWheel(tester, reduceMotion: true);
      await tester.flingFrom(rightEdge(tester), const Offset(0, 100), 1500);
      await tester.pump();
      final rotation = key.currentState!.rotation;
      expect(aligned(rotation), isTrue, reason: '$rotation');
      await tester.pump(const Duration(milliseconds: 300));
      expect(key.currentState!.rotation, rotation, reason: 'no sigue girando');

      await tester.tap(find.byKey(const Key('circle-step-right')));
      await tester.pump();
      expect(
        key.currentState!.rotation,
        rotation - 30,
        reason: 'sin transición',
      );
    });
  });

  group('pantalla', () {
    Future<(_FakeAudio, ProviderContainer)> open(
      WidgetTester tester,
      String location, {
      String code = 'es',
      Size size = const Size(360, 1400),
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      addTearDown(() => CurrentLanguage.value = AppLanguage.es);
      final audio = _FakeAudio();
      final container = ProviderContainer(
        overrides: [
          keyValueStoreProvider.overrideWithValue(
            InMemoryStore(settings: {'localeCode': code}),
          ),
          audioServiceProvider.overrideWithValue(audio),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ChordMasterApp(),
        ),
      );
      appRouter.go(location);
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      // chords.json se decodifica en otro isolate: hace falta tiempo real.
      for (var i = 0; i < 40; i++) {
        if (container.read(chordViewModelProvider).allChords.isNotEmpty) break;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)),
        );
      }
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      return (audio, container);
    }

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    String textOf(WidgetTester tester, String key) =>
        tester.widget<Text>(find.byKey(Key(key))).data!;

    testWidgets('el hub lleva a la ruta, con barra inferior y atrás', (
      tester,
    ) async {
      await open(tester, '/learn');
      expect(find.text(AppStrings.hubCircleSub), findsOneWidget);
      await tester.tap(find.text(AppStrings.hubCircleSub));
      await settle(tester);
      expect(find.byKey(const Key('circle-wheel')), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(find.byKey(const Key('circle-wheel')), findsNothing);
      expect(find.text(AppStrings.hubCircleSub), findsOneWidget);
    });

    testWidgets('cambiar de tonalidad actualiza el panel', (tester) async {
      await open(tester, '/learn/circle');
      expect(textOf(tester, 'circle-key-title'), startsWith('C mayor'));
      expect(textOf(tester, 'circle-key-signature'), 'sin alteraciones');
      await tester.tap(find.byKey(const Key('circle-step-right')));
      await settle(tester);
      expect(textOf(tester, 'circle-key-title'), 'G mayor · relativa Em');
      expect(textOf(tester, 'circle-key-signature'), '1 sostenido');
      expect(find.text('Am'), findsOneWidget, reason: 'el ii de G');
      expect(find.text('F#dim'), findsOneWidget, reason: 'el vii° de G');
    });

    testWidgets('anuncia la tonalidad al cambiar', (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester, '/learn/circle');
      await tester.tap(find.byKey(const Key('circle-step-right')));
      await settle(tester);
      expect(find.bySemanticsLabel('G mayor, 1 sostenido'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('cada acorde suena al tocarlo y su flecha abre la ficha', (
      tester,
    ) async {
      final (audio, _) = await open(tester, '/learn/circle');
      await tester.tap(find.byKey(const Key('circle-chord-IV')));
      await tester.pump();
      expect(audio.fingerings, hasLength(1));
      await tester.tap(find.byKey(const Key('circle-chord-open-V')));
      await settle(tester);
      final detail = tester.widget<ChordDetailScreen>(
        find.byType(ChordDetailScreen),
      );
      expect(detail.chordId, 'G Major');
      await tester.tap(find.byType(BackButton).last);
      await settle(tester);
      expect(find.byKey(const Key('circle-wheel')), findsOneWidget);
    });

    testWidgets('"Escuchar cadencia" toca I – IV – V – I', (tester) async {
      final (audio, _) = await open(tester, '/learn/circle');
      await tester.tap(find.byKey(const Key('circle-cadence')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 2)),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      expect(audio.fingerings, hasLength(4));
      expect(audio.fingerings.first, audio.fingerings.last, reason: 'I y I');
    });

    testWidgets('el enlace lleva a Progresiones con la tonalidad elegida', (
      tester,
    ) async {
      final (_, container) = await open(tester, '/learn/circle');
      await tester.tap(find.byKey(const Key('circle-step-right')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('circle-step-right')));
      await settle(tester);
      await tester.ensureVisible(
        find.byKey(const Key('circle-to-progressions')),
      );
      await tester.tap(find.byKey(const Key('circle-to-progressions')));
      await settle(tester);
      expect(
        container.read(progressionsViewModelProvider).tonic,
        noteIndex('D'),
      );
      expect(
        appRouter.routerDelegate.currentConfiguration.uri.path,
        '/learn/progressions',
      );
    });

    testWidgets('el tic de la rueda es opcional y se recuerda', (tester) async {
      final (audio, container) = await open(tester, '/learn/circle');
      await tester.tap(find.byKey(const Key('circle-step-right')));
      await settle(tester);
      expect(audio.ticks, 0, reason: 'apagado por defecto');
      await tester.tap(find.byKey(const Key('circle-tick')));
      await settle(tester);
      expect(container.read(circleViewModelProvider).tickEnabled, isTrue);
      await tester.tap(find.byKey(const Key('circle-step-right')));
      await settle(tester);
      expect(audio.ticks, 1);
      expect(
        await container
            .read(keyValueStoreProvider)
            .get<bool>(StorageBoxes.settings, CircleViewModel.keyTick),
        isTrue,
      );
    });

    testWidgets('"¿Cómo se arma?" avanza, retrocede y termina en la rueda', (
      tester,
    ) async {
      await open(tester, '/learn/circle/build');
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      final previous = find.byKey(const Key('circle-build-previous'));
      final next = find.byKey(const Key('circle-build-next'));
      expect(tester.widget<OutlinedButton>(previous).onPressed, isNull);
      expect(find.text(circleBuildRule.text), findsOneWidget);
      final steps = circleConstruction();
      expect(textOf(tester, 'circle-build-change'), steps[0].changeText.text);
      expect(find.byKey(const Key('circle-build-fifth')), findsNothing);
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pump();
      expect(textOf(tester, 'circle-build-change'), steps[1].changeText.text);
      expect(textOf(tester, 'circle-build-fifth'), steps[1].fifthText!.text);
      expect(textOf(tester, 'circle-build-progress'), 'Paso 2 de 13');
      await tester.tap(previous);
      await tester.pump();
      expect(textOf(tester, 'circle-build-change'), steps[0].changeText.text);
      for (var i = 0; i < 12; i++) {
        await tester.tap(next);
        await tester.pump();
      }
      expect(textOf(tester, 'circle-build-change'), steps[12].changeText.text);
      expect(textOf(tester, 'circle-build-closing'), circleBuildClosing.text);
      expect(find.text(AppStrings.circleBuildToWheel), findsOneWidget);
      await tester.tap(next);
      await settle(tester);
      expect(find.byType(CircleBuildScreen), findsNothing);
    });

    test('el anillo pone C arriba y sube en el sentido del reloj', () {
      const center = Offset(100, 100);
      final top = ringNodeOffset(0, center, 80);
      expect(top.dx, closeTo(100, 1e-9));
      expect(top.dy, closeTo(20, 1e-9));
      final right = ringNodeOffset(3, center, 80);
      expect(right.dx, closeTo(180, 1e-9));
      expect(right.dy, closeTo(100, 1e-9));
      final bottom = ringNodeOffset(6, center, 80);
      expect(bottom.dy, closeTo(180, 1e-9));
    });

    for (final code in ['es', 'en']) {
      testWidgets('cabe a 360 × 780 en $code, en cada tonalidad', (
        tester,
      ) async {
        // Un desborde hace fallar el test.
        await open(
          tester,
          '/learn/circle',
          code: code,
          size: const Size(360, 780),
        );
        for (var i = 0; i < 12; i++) {
          await tester.tap(find.byKey(const Key('circle-step-right')));
          await settle(tester);
          expect(tester.takeException(), isNull, reason: 'posición ${i + 1}');
        }
      });

      testWidgets('los 13 pasos caben a 360 dp en $code', (tester) async {
        await open(
          tester,
          '/learn/circle/build',
          code: code,
          size: const Size(360, 1200),
        );
        for (var i = 0; i < 12; i++) {
          await tester.tap(find.byKey(const Key('circle-build-next')));
          await tester.pump();
          expect(tester.takeException(), isNull, reason: 'paso ${i + 2}');
        }
      });
    }
  });
}
