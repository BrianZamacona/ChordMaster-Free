import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/features/chords/chord_explorer_screen.dart';
import 'package:chordmaster_free/features/chords/chord_viewmodel.dart';
import 'package:chordmaster_free/models/chord.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_store.dart';

class _OneChord extends ChordViewModel {
  _OneChord(this.chord);

  final Chord chord;

  @override
  ChordState build() => ChordState(allChords: [chord], filteredChords: [chord], isLoading: false);

  @override
  Chord? findByName(String name) => name.toLowerCase() == chord.name.toLowerCase() ? chord : null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  final json = (jsonDecode(File('assets/data/chords.json').readAsStringSync()) as List).cast<Map<String, dynamic>>();
  final cMajor = Chord.fromJson(json.firstWhere((c) => c['root'] == 'C' && c['type'] == 'major'));

  for (final code in ['es', 'en']) {
    testWidgets('a 360 dp ($code): las tríadas se agrupan por forma CAGED, sin casilla de comparar', (tester) async {
      CurrentLanguage.value = code == 'es' ? AppLanguage.es : AppLanguage.en;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 9000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            keyValueStoreProvider.overrideWithValue(InMemoryStore()),
            chordViewModelProvider.overrideWith(() => _OneChord(cMajor)),
          ],
          child: MaterialApp(
            theme: darkTheme,
            home: ChordExplorerScreen(chordId: Uri.encodeComponent(cMajor.name)),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      final toggle = find.byKey(const Key('triads-view'));
      expect(toggle, findsOneWidget);
      expect(tester.getRect(toggle).right, lessThanOrEqualTo(360));
      final compareBefore = find.byWidgetPredicate((w) => w is Checkbox).evaluate().length;
      await tester.tap(find.text(AppStrings.triadsByShape));
      await tester.pump();
      expect(tester.takeException(), isNull);
      // Las cinco formas de C, en orden, con sus trastes.
      for (final s in ['C', 'A', 'G', 'E', 'D']) {
        expect(find.byKey(Key('triads-shape-$s')), findsOneWidget, reason: s);
      }
      expect(
        tester.widget<Text>(find.byKey(const Key('triads-shape-A'))).data,
        AppStrings.triadsInShape('A', 3, 5),
      );
      // Por forma no se compara: hay menos casillas (solo las de las otras secciones).
      final compareAfter = find.byWidgetPredicate((w) => w is Checkbox).evaluate().length;
      expect(compareAfter, compareBefore - cMajor.triadInversions.length);
      await tester.tap(find.text(AppStrings.triadsByStrings));
      await tester.pump();
      expect(find.byKey(const Key('triads-shape-A')), findsNothing);
    });
  }
}
