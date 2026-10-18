import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/core/widgets/chord_diagram.dart';
import 'package:chordmaster_free/features/chords/chord_detail_screen.dart';
import 'package:chordmaster_free/features/chords/chord_viewmodel.dart';
import 'package:chordmaster_free/models/chord.dart';
import 'package:chordmaster_free/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Fake extends ChordViewModel {
  _Fake(this.chords);

  final List<Chord> chords;

  @override
  ChordState build() => ChordState(allChords: chords, filteredChords: chords, isLoading: false);

  @override
  Chord? findByName(String name) => chords.where((c) => c.name == name).firstOrNull;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final chords = [
    for (final c in jsonDecode(File('assets/data/chords.json').readAsStringSync()) as List<dynamic>)
      Chord.fromJson(c as Map<String, dynamic>),
  ];

  testWidgets('detalle de C: elegir E en el bajo muestra C/E con 0-3-2-0-1-0 primero', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [chordViewModelProvider.overrideWith(() => _Fake(chords))],
        child: MaterialApp(
          theme: lightTheme,
          home: ChordDetailScreen(chordId: Uri.encodeComponent('C Major')),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    // 11 bajos posibles: todas las notas menos la raíz.
    expect(find.byKey(const Key('slash-bass-C')), findsNothing);
    final e = find.byKey(const Key('slash-bass-E'));
    await tester.ensureVisible(e);
    await tester.tap(e);
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.widget<Text>(find.byKey(const Key('slash-name'))).data, 'C/E');
    final first = tester.widget<ChordDiagramWidget>(find.byKey(const Key('slash-voicing-0')));
    expect(first.fretPositions, [0, 3, 2, 0, 1, 0]);
    expect(first.fingerPositions, [0, 3, 2, 0, 1, 0]);
  });
}
