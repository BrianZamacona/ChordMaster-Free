import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/features/lessons/lesson_tab.dart';
import 'package:chordmaster_free/features/lessons/lesson_widgets.dart';
import 'package:chordmaster_free/features/lessons/tab_player.dart';
import 'package:chordmaster_free/services/audio_service.dart';
import 'package:chordmaster_free/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/play_along_fakes.dart';

/// Un renglón con todas las marcas: púa, ligados, slide, bend y release,
/// vibrato, PM, nota muerta y silencio, con ritmo propio.
const _all = [
  TabNote(3, 5, pick: PickStroke.down, length: tabSixteenth),
  TabNote(3, 7, technique: TabTechnique.hammerOn, length: tabSixteenth),
  TabNote(3, 5, technique: TabTechnique.pullOff),
  TabNote(2, 8, technique: TabTechnique.bend, bend: 2),
  TabNote(2, 8, technique: TabTechnique.release),
  TabNote(2, 5, technique: TabTechnique.slide),
  TabNote(6, 0, technique: TabTechnique.palmMute, pick: PickStroke.up),
  TabNote(6, 0, technique: TabTechnique.dead),
  TabNote.rest(tabEighth),
  TabNote(1, 5, technique: TabTechnique.vibrato, length: tabQuarter),
];

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(360, 800);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: lightTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  for (final language in AppLanguage.values) {
    group('a 360 dp en ${language.name}', () {
      setUp(() => CurrentLanguage.value = language);

      testWidgets('todas las marcas caben, con su explicación y el conteo', (tester) async {
        await _pump(tester, const LessonTabView(notes: _all, showFingers: true));
        expect(tester.takeException(), isNull);
        final line = tester.getRect(find.byKey(const Key('lesson-tab-line-0')));
        expect(line.left, greaterThanOrEqualTo(0));
        expect(line.right, lessThanOrEqualTo(360));
        // Las dos filas extra: arriba (púa y PM) y el conteo.
        expect(line.height, greaterThan(14 * 5 + 16 + 14 + 14 - 1));
        final legend = find.byKey(const Key('lesson-tab-legend'));
        for (final text in [
          AppStrings.tabLegendRest,
          AppStrings.tabLegendHammerOn,
          AppStrings.tabLegendPullOff,
          AppStrings.tabLegendSlide,
          AppStrings.tabLegendBend,
          AppStrings.tabLegendRelease,
          AppStrings.tabLegendVibrato,
          AppStrings.tabLegendPalmMute,
          AppStrings.tabLegendDead,
          AppStrings.tabLegendPick,
        ]) {
          expect(find.descendant(of: legend, matching: find.text(text)), findsOneWidget);
        }
        expect(tester.getRect(legend).right, lessThanOrEqualTo(360));
      });

      testWidgets('una tablatura de corcheas sin técnicas queda como antes', (tester) async {
        await _pump(tester, const LessonTabView(notes: [TabNote(1, 0), TabNote(1, 3)]));
        expect(find.byKey(const Key('lesson-tab-legend')), findsNothing);
        final line = tester.getRect(find.byKey(const Key('lesson-tab-line-0')));
        expect(line.height, 14 * 5 + 16);
      });

      testWidgets('el bend va junto a su traste: no agrega una fila arriba', (tester) async {
        // Arriba quedaba encima de la línea de la cuerda vecina (visto en el
        // emulador): ahora va al lado del número, sobre la misma línea.
        await _pump(
          tester,
          const LessonTabView(notes: [TabNote(1, 5), TabNote(3, 7, technique: TabTechnique.bend, bend: 2)]),
        );
        expect(tester.getRect(find.byKey(const Key('lesson-tab-line-0'))).height, 14 * 5 + 16);
        expect(tester.takeException(), isNull);
      });

      testWidgets('el lector de pantalla oye la técnica y el silencio', (tester) async {
        final handle = tester.ensureSemantics();
        await _pump(
          tester,
          const LessonTabView(
            notes: [TabNote(2, 8, technique: TabTechnique.bend, bend: 2), TabNote.rest(tabEighth)],
          ),
        );
        expect(find.bySemanticsLabel(RegExp(RegExp.escape(AppStrings.tabSpokenBend(2)))), findsWidgets);
        expect(find.bySemanticsLabel(RegExp(RegExp.escape(AppStrings.lessonTabRest))), findsWidgets);
        handle.dispose();
      });

      testWidgets('con ritmo propio no dice "en corcheas"; suena con sus ligados', (tester) async {
        final audio = FakeAudio();
        Future<void> player(List<TabNote> notes) => _pump(
          tester,
          ProviderScope(
            overrides: [audioServiceProvider.overrideWithValue(audio)],
            child: TabPlayer(notes: notes, bpm: 80),
          ),
        );
        await player(_all);
        expect(find.text(AppStrings.tabAtBpmRhythm(80)), findsOneWidget);
        await tester.tap(find.byKey(const Key('tab-play')));
        await tester.pump();
        // Diez notas: el silencio no suena y cada ligado sigue en su cuerda.
        expect(audio.played.single, hasLength(5));
        await tester.tap(find.byKey(const Key('tab-play')));
        await tester.pump();
        await player(const [TabNote(1, 0), TabNote(1, 3)]);
        expect(find.text(AppStrings.tabAtBpm(80)), findsOneWidget);
      });

      testWidgets('el rasgueo apagado lleva su x y se explica', (tester) async {
        await _pump(tester, const StrumPatternView(pattern: 'DuduDUdU'));
        expect(tester.takeException(), isNull);
        expect(find.text('x↓'), findsNWidgets(2));
        expect(find.text('x↑'), findsNWidgets(2));
        expect(find.textContaining(AppStrings.lessonStrumMutedHint), findsOneWidget);
        expect(tester.getRect(find.byKey(const Key('strum-cell-7'))).right, lessThanOrEqualTo(360));
      });
    });
  }
}
