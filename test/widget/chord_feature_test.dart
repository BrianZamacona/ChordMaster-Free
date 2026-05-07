import 'package:chordmaster_free/core/widgets/chord_diagram.dart';
import 'package:chordmaster_free/features/chords/chord_detail_screen.dart';
import 'package:chordmaster_free/features/chords/chord_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('chord library exposes category filters and hides painter titles',
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
}
