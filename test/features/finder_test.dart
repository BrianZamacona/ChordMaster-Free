import 'dart:io';

import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/constants/chord_metadata.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/data/repository/scale_repository.dart';
import 'package:chordmaster_free/features/chords/chord_detail_screen.dart';
import 'package:chordmaster_free/features/finder/note_finder_screen.dart';
import 'package:chordmaster_free/features/home/home_screen.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:chordmaster_free/ui/scales/detail/scale_detail_screen.dart';
import 'package:chordmaster_free/ui/widgets/fret_grid_geometry.dart';
import 'package:chordmaster_free/ui/widgets/fretboard_diagram.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  /// Toca la cuerda [string] (1 = mi aguda) en el traste [fret] del mástil.
  Future<void> tapNote(WidgetTester tester, int string, int fret) async {
    final neck = find.byType(FretboardNeck);
    final box = tester.getRect(neck);
    final height = box.height - 12; // espacio de la barra de scroll
    final g = FretGridGeometry(
      width: box.width,
      height: height,
      startFret: 1,
      endFret: FretboardNeck.maxFret,
      fixedFretWidth: FretboardNeck.minFretWidth,
      maxNoteRadius: 14,
    );
    await tester.tapAt(box.topLeft + g.noteOffset(string, fret));
    await tester.pump();
  }

  int selectedTab(WidgetTester tester) =>
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

  String titleOf(WidgetTester tester, int i) => tester
      .widget<Text>(
        find.descendant(of: find.byKey(Key('finder-result-$i')), matching: find.byType(Text)).first,
      )
      .data!;

  for (final code in ['es', 'en']) {
    testWidgets('Inicio → Buscador: acordes y escalas por notas a 360 dp ($code)', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 2400);
      addTearDown(tester.view.reset);
      appRouter.go('/');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            keyValueStoreProvider.overrideWithValue(
              InMemoryStore(settings: {'localeCode': code}),
            ),
            scaleRepositoryProvider.overrideWithValue(ScaleRepository(bundle: _FileBundle())),
          ],
          child: const ChordMasterApp(),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
      await settle(tester);

      // Inicio lo abre.
      await tester.ensureVisible(find.text(AppStrings.moduleFinder));
      await tester.pump();
      await tester.tap(find.text(AppStrings.moduleFinder));
      await settle(tester);
      expect(find.byType(NoteFinderScreen), findsOneWidget);
      expect(selectedTab(tester), 0, reason: 'el buscador es de Inicio');
      for (var i = 0; i < 10 && find.byKey(const Key('finder-message')).evaluate().isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
        await tester.pump();
      }
      expect(find.text(AppStrings.finderPickTwo), findsOneWidget);

      // x32010 → C.
      for (final (s, f) in [(5, 3), (4, 2), (3, 0), (2, 1), (1, 0)]) {
        await tapNote(tester, s, f);
      }
      expect(find.text(AppStrings.finderNotes('C E G')), findsOneWidget);
      expect(titleOf(tester, 0), 'C');
      expect(find.text(chordTypeLabel('major')), findsWidgets);

      // La 6ª al aire pone la E en el bajo: C/E.
      await tapNote(tester, 6, 0);
      expect(titleOf(tester, 0), 'C/E');
      // Otra vez en el mismo lugar la apaga.
      await tapNote(tester, 6, 0);
      expect(titleOf(tester, 0), 'C');
      expect(tester.takeException(), isNull);

      // El resultado abre su ficha y atrás vuelve con las notas marcadas.
      await tester.tap(find.byKey(const Key('finder-result-0')));
      await settle(tester);
      expect(find.byType(ChordDetailScreen), findsOneWidget);
      expect(selectedTab(tester), 0);
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(find.text(AppStrings.finderNotes('C E G')), findsOneWidget);

      // Escalas: A C D E G → primero A pentatónica menor, exacta.
      await tester.tap(find.text(AppStrings.moduleScales));
      await settle(tester);
      expect(find.text(AppStrings.finderPickTwo), findsOneWidget);
      for (final (s, f) in [(5, 0), (5, 3), (4, 0), (4, 2), (3, 0)]) {
        await tapNote(tester, s, f);
      }
      final minorPentatonic = tr(es: 'A Pentatónica menor', en: 'A Minor Pentatonic');
      expect(titleOf(tester, 0), minorPentatonic);
      expect(find.text(AppStrings.finderExact), findsWidgets);
      expect(tester.takeException(), isNull);

      // Las notas de acordes siguen ahí al volver.
      await tester.tap(find.text(AppStrings.moduleChords).first);
      await settle(tester);
      expect(find.text(AppStrings.finderNotes('C E G')), findsOneWidget);
      await tester.tap(find.text(AppStrings.moduleScales));
      await settle(tester);

      await tester.tap(find.byKey(const Key('finder-result-0')));
      await settle(tester);
      expect(find.byType(ScaleDetailScreen), findsOneWidget);
      expect(selectedTab(tester), 0, reason: 'la ficha se abre sin salir de Inicio');

      // Atrás: a la ficha le sigue el buscador, y al buscador, Inicio.
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(find.byType(NoteFinderScreen), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(NoteFinderScreen), findsNothing);
    });
  }
}
