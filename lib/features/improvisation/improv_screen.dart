import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/music_theory.dart';

/// Improvisation guide screen.
class ImprovScreen extends ConsumerStatefulWidget {
  /// Creates the [ImprovScreen].
  const ImprovScreen({super.key});

  @override
  ConsumerState<ImprovScreen> createState() => _ImprovScreenState();
}

class _ImprovScreenState extends ConsumerState<ImprovScreen> {
  String _selectedRoot = 'C';
  String _selectedScale = 'pentatonicMinor';

  static const _scaleOptions = [
    ('pentatonicMinor', 'Pentatonic Minor'),
    ('pentatonicMajor', 'Pentatonic Major'),
    ('blues', 'Blues Scale'),
    ('naturalMinor', 'Natural Minor'),
    ('major', 'Major'),
    ('dorian', 'Dorian'),
    ('mixolydian', 'Mixolydian'),
  ];

  static const _scaleGuides = <String, _ScaleGuide>{
    'pentatonicMinor': _ScaleGuide(
      bestOver: 'Major, Minor, Dominant 7th chords',
      genres: 'Rock, Blues, R&B',
      patterns: [
        'Box 1 (root on 6th string): classic starting position',
        'Diagonal "highway" run: connect all 5 positions',
        'String bend on ♭7 → root: core blues move',
      ],
      licks: [
        'Bend on b7 → root: e.g. 8b10 on B-string in Am',
        'Triplet hammer-on: 5h7-5h7-5h7 on G-string',
        'Slide from ♭3 to 3 for a bluesy touch',
      ],
    ),
    'pentatonicMajor': _ScaleGuide(
      bestOver: 'Major, Major 7th, Dominant 7th',
      genres: 'Country, Pop, Folk',
      patterns: [
        'Root position up the neck, single string',
        'Chord tone targeting on beat 1',
        'String skipping for melodic interest',
      ],
      licks: [
        'Country bend: 9 → 10 on B-string in G major',
        'Descending run from high root to low root',
        'Double-stop 3rd harmony on top two strings',
      ],
    ),
    'blues': _ScaleGuide(
      bestOver: 'Dominant 7th (I, IV, V in blues)',
      genres: 'Blues, Jazz, Rock',
      patterns: [
        'Minor pentatonic + ♭5 (blue note)',
        'Chromatic approach from ♭5 → 5',
        'Turnaround: I → VII → ♭VII → VI',
      ],
      licks: [
        'Classic turnaround lick in E blues',
        'B.B. King "butterfly" vibrato on ♭3',
        'Call-and-response phrase using ♭5 as tension',
      ],
    ),
    'naturalMinor': _ScaleGuide(
      bestOver: 'Minor, Minor 7th, Minor 9th chords',
      genres: 'Metal, Classic Rock, Neoclassical',
      patterns: [
        '3-notes-per-string patterns for speed',
        'Descending sequence from root',
        'Sequence in 3rds across all strings',
      ],
      licks: [
        'Dio-style descending minor run on top 3 strings',
        'Ascending 3rd sequence: 1-3-2-4-3-5...',
        'VI → VII → i resolve for dramatic finish',
      ],
    ),
    'major': _ScaleGuide(
      bestOver: 'Major, Major 7th, Major 9th',
      genres: 'Jazz, Pop, Classical',
      patterns: [
        'Play over chord tones (1, 3, 5, 7)',
        'Target the 3rd and 7th on strong beats',
        'Diatonic 3rds sequence ascending',
      ],
      licks: [
        'Ascending diatonic thirds: clean and melodic',
        'Bach-style chromatic passing tones',
        'End phrases on the major 7th for colour',
      ],
    ),
    'dorian': _ScaleGuide(
      bestOver: 'Minor 7th, Minor 9th, m11 chords',
      genres: 'Jazz, Funk, Fusion',
      patterns: [
        'Minor pentatonic + major 6th (characteristic note)',
        'Compare with natural minor: only ♮6 differs',
        'Carlos Santana "dorian groove" approach',
      ],
      licks: [
        'Emphasise the major 6th for characteristic dorian sound',
        'Minor pentatonic box + major 6th approach note',
        'Dorian vamp: im7 → IV7 back-and-forth',
      ],
    ),
    'mixolydian': _ScaleGuide(
      bestOver: 'Dominant 7th, 9th chords',
      genres: 'Blues Rock, Country, Jazz',
      patterns: [
        'Major scale with ♭7 (characteristic note)',
        'Target the ♭7 on downbeats for bluesy feel',
        'Country twang: slide into ♭7 then resolve to root',
      ],
      licks: [
        'George Harrison-style: descend through ♭7 to 5',
        'Mixo riff: root → maj2 → maj3 → ♭7 → root',
        'Bend from ♭7 to root for tension/release',
      ],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final guide = _scaleGuides[_selectedScale];

    // Build the displayed scale notes
    final rootIndex = chromaticNotes.indexOf(_selectedRoot);
    final formula = scaleFormulas[_selectedScale] ??
        modeFormulas[_selectedScale] ??
        const <int>[];
    final scaleNotes = rootIndex == -1
        ? <String>[]
        : formula
            .map((s) => chromaticNotes[(rootIndex + s) % 12])
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.moduleImprovisation)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Root note selector
            Text('Root Note', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: chromaticNotes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final note = chromaticNotes[i];
                  return ChoiceChip(
                    label: Text(note),
                    selected: _selectedRoot == note,
                    onSelected: (_) => setState(() => _selectedRoot = note),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Scale selector
            Text('Scale / Mode', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedScale,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              items: _scaleOptions
                  .map((opt) => DropdownMenuItem(
                        value: opt.$1,
                        child: Text(opt.$2),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedScale = v);
              },
            ),
            const SizedBox(height: 20),

            // Scale notes display
            if (scaleNotes.isNotEmpty)
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_selectedRoot ${_scaleOptions.firstWhere((o) => o.$1 == _selectedScale, orElse: () => (_selectedScale, _selectedScale)).$2}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: scaleNotes
                            .map((n) => Chip(
                                  label: Text(n,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  backgroundColor: theme.colorScheme.primary,
                                  labelStyle: TextStyle(
                                      color:
                                          theme.colorScheme.onPrimary),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Guide
            if (guide != null) ...[
              _GuideCard(
                title: '🎯 Best Over',
                content: guide.bestOver,
              ),
              const SizedBox(height: 10),
              _GuideCard(
                title: '🎵 Common Genres',
                content: guide.genres,
              ),
              const SizedBox(height: 10),
              _ListGuideCard(
                title: '🔄 Patterns',
                items: guide.patterns,
              ),
              const SizedBox(height: 10),
              _ListGuideCard(
                title: '🎸 Lick Ideas',
                items: guide.licks,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScaleGuide {
  const _ScaleGuide({
    required this.bestOver,
    required this.genres,
    required this.patterns,
    required this.licks,
  });
  final String bestOver;
  final String genres;
  final List<String> patterns;
  final List<String> licks;
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.title, required this.content});
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(content, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _ListGuideCard extends StatelessWidget {
  const _ListGuideCard({required this.title, required this.items});
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16)),
                      Expanded(
                          child: Text(item,
                              style: theme.textTheme.bodySmall)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
