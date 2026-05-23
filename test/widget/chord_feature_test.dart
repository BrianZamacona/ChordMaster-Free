import 'package:chordmaster_free/core/widgets/chord_diagram.dart';
import 'package:chordmaster_free/features/chords/chord_detail_screen.dart';
import 'package:chordmaster_free/features/chords/chord_explorer_screen.dart';
import 'package:chordmaster_free/features/chords/chord_library_screen.dart';
import 'package:chordmaster_free/features/chords/chord_viewmodel.dart';
import 'package:chordmaster_free/models/chord.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeChordViewModel extends ChordViewModel {
  _FakeChordViewModel(this._chords);

  final List<Chord> _chords;

  @override
  ChordState build() => ChordState(
        allChords: _chords,
        filteredChords: _chords,
        isLoading: false,
      );

  @override
  void search(String query) {
    final normalized = query.trim().toLowerCase();
    final filtered = normalized.isEmpty
        ? _chords
        : _chords
            .where((chord) {
              final fields = <String>[
                chord.name,
                chord.displayName ?? '',
                ...chord.aliases,
                ...chord.tags,
              ];
              return fields.any(
                (field) => field.toLowerCase().contains(normalized),
              );
            })
            .toList(growable: false);

    state = state.copyWith(searchQuery: query, filteredChords: filtered);
  }

  @override
  Chord? findByName(String name) {
    final normalized = name.toLowerCase();
    for (final chord in _chords) {
      if (chord.name.toLowerCase() == normalized) return chord;
      if ((chord.displayName ?? '').toLowerCase() == normalized) return chord;
    }
    return null;
  }

  @override
  List<Chord> relatedByRoot(Chord chord) => _chords
      .where((candidate) => candidate.root == chord.root && candidate.name != chord.name)
      .toList(growable: false);

  @override
  List<Chord> relatedByTags(Chord chord, {int limit = 8}) {
    final tags = chord.tags.toSet();
    return _chords
        .where((candidate) => candidate.name != chord.name)
        .where((candidate) => candidate.tags.any(tags.contains))
        .take(limit)
        .toList(growable: false);
  }
}

final _testChords = <Chord>[
  const Chord(
    name: 'C Major',
    root: 'C',
    type: 'major',
    intervals: [0, 4, 7],
    fretPositions: [-1, 3, 2, 0, 1, 0],
    fingerPositions: [0, 3, 2, 0, 1, 0],
    tags: ['jazz'],
    cagedPositions: [
      ChordExplorerItem(
        title: 'C Form',
        shape: 'C',
        description: 'Classic open C shape',
        fretPositions: [-1, 3, 2, 0, 1, 0],
        fingerPositions: [0, 3, 2, 0, 1, 0],
      ),
    ],
    voicings: [
      ChordExplorerItem(
        title: 'Shell 6-4-3',
        description: 'Compact shell voicing',
        fretPositions: [8, -1, 10, 9, -1, -1],
        fingerPositions: [1, 0, 3, 2, 0, 0],
      ),
    ],
    triadInversions: [
      ChordExplorerItem(
        title: 'Root Position',
        description: 'Triad root position',
        fretPositions: [-1, 3, 2, 0, 1, -1],
        fingerPositions: [0, 3, 2, 0, 1, 0],
      ),
    ],
    advancedInversions: [
      ChordExplorerItem(
        title: 'Drop-2 Root',
        description: 'Advanced inversion',
        fretPositions: [8, 7, 9, 9, 8, -1],
        fingerPositions: [2, 1, 4, 3, 1, 0],
      ),
    ],
  ),
  const Chord(
    name: 'C 7#9',
    root: 'C',
    type: 'dominant7Sharp9',
    intervals: [0, 4, 7, 10, 15],
    fretPositions: [-1, 3, 2, 3, 4, -1],
    fingerPositions: [0, 1, 2, 3, 4, 0],
    displayName: 'C7#9',
    aliases: ['Hendrix Chord'],
    tags: ['blues', 'jazz'],
    description: 'Altered dominant color famous in Hendrix, blues, and fusion.',
  ),
];

Widget _wrapWithFakeChords(Widget child) => ProviderScope(
      overrides: [
        chordViewModelProvider.overrideWith(
          () => _FakeChordViewModel(_testChords),
        ),
      ],
      child: MaterialApp(home: child),
    );

void main() {
  testWidgets('chord library exposes category filters and hides diagram titles',
      (tester) async {
    await tester.pumpWidget(_wrapWithFakeChords(const ChordLibraryScreen()));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Jazz'), findsOneWidget);
    expect(find.text('Blues'), findsOneWidget);

    final diagram = tester.widget<ChordDiagramWidget>(
      find.byType(ChordDiagramWidget).first,
    );
    expect(diagram.showChordName, isFalse);

    await tester.enterText(find.byType(TextField), 'hendrix');
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('C7#9'), findsOneWidget);
  });

  testWidgets('chord detail shows aliases and category chips for Hendrix voicings',
      (tester) async {
    await tester.pumpWidget(
      _wrapWithFakeChords(
        ChordDetailScreen(
          chordId: Uri.encodeComponent('C 7#9'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Hendrix Chord'), findsWidgets);
    expect(find.text('Blues'), findsOneWidget);
    expect(find.text('Jazz'), findsOneWidget);

    final diagram = tester.widget<ChordDiagramWidget>(
      find.byType(ChordDiagramWidget).first,
    );
    expect(diagram.showChordName, isFalse);
  });

  testWidgets('chord explorer renders CAGED and inversion sections', (tester) async {
    await tester.pumpWidget(
      _wrapWithFakeChords(
        ChordExplorerScreen(
          chordId: Uri.encodeComponent('C Major'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

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
