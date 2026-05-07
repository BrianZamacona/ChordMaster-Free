import 'package:chordmaster_free/core/widgets/chord_diagram.dart';
import 'package:chordmaster_free/features/chords/chord_detail_screen.dart';
import 'package:chordmaster_free/features/chords/chord_explorer_screen.dart';
import 'package:chordmaster_free/features/chords/chord_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('chord library exposes category filters and hides diagram titles',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ChordLibraryScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Jazz'), findsOneWidget);
    expect(find.text('Blues'), findsOneWidget);

    final diagram = tester.widget<ChordDiagramWidget>(
      find.byType(ChordDiagramWidget).first,
    );
    expect(diagram.showChordName, isFalse);

    await tester.enterText(find.byType(TextField), 'hendrix');
    await tester.pumpAndSettle();

    expect(find.text('C7#9'), findsOneWidget);
  });

  testWidgets('chord detail shows aliases and category chips for Hendrix voicings',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ChordDetailScreen(
            chordId: Uri.encodeComponent('C 7#9'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Hendrix Chord'), findsOneWidget);
    expect(find.text('Blues'), findsOneWidget);
    expect(find.text('Jazz'), findsOneWidget);

    final diagram = tester.widget<ChordDiagramWidget>(
      find.byType(ChordDiagramWidget).first,
    );
    expect(diagram.showChordName, isFalse);
  });

  testWidgets('chord explorer renders CAGED and inversion sections', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ChordExplorerScreen(
            chordId: Uri.encodeComponent('C Major'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('CAGED Positions'), findsOneWidget);
    expect(find.text('Voicings'), findsOneWidget);
    expect(find.text('Triad Inversions'), findsOneWidget);
    expect(find.text('Advanced Inversions'), findsOneWidget);
    expect(find.text('C Form'), findsOneWidget);
    expect(find.text('Shell 6-4-3'), findsOneWidget);
    expect(find.text('Root Position'), findsWidgets);
    expect(find.byType(ChordDiagramWidget), findsWidgets);
  });
}
