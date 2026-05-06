import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/song.dart';
import 'songs_viewmodel.dart';

/// Detail screen for a single song.
class SongDetailScreen extends ConsumerStatefulWidget {
  /// Creates a [SongDetailScreen] for [songId].
  const SongDetailScreen({super.key, required this.songId});

  /// The identifier of the song to display.
  final String songId;

  @override
  ConsumerState<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends ConsumerState<SongDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(songsViewModelProvider.notifier).markViewed(widget.songId);
    });
  }

  static const _difficultyLabels = [
    '',
    'Beginner',
    'Easy',
    'Intermediate',
    'Advanced',
    'Expert',
  ];

  @override
  Widget build(BuildContext context) {
    final song = findSongById(widget.songId);
    final theme = Theme.of(context);

    if (song == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Song')),
        body: const Center(child: Text('Song not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(song.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('🎵', style: TextStyle(fontSize: 48)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            song.artist,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song.genre,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Info row
            Row(
              children: [
                _InfoChip(label: '${song.tempo} BPM', icon: Icons.timer),
                const SizedBox(width: 8),
                _InfoChip(
                    label: song.timeSignature,
                    icon: Icons.music_note),
                const SizedBox(width: 8),
                _InfoChip(
                    label: _difficultyLabels[song.difficulty.clamp(1, 5)],
                    icon: Icons.bar_chart),
              ],
            ),
            const SizedBox(height: 16),

            // Chord Progression
            _SectionCard(
              title: '🎸 Chord Progression',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: song.chordProgression
                    .map((chord) => Chip(
                          label: Text(
                            chord,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: theme.colorScheme.primaryContainer,
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Strumming Pattern
            _SectionCard(
              title: '🎼 Strumming Pattern',
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  song.strummingPattern,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Practice Notes
            if (song.notes.isNotEmpty)
              _SectionCard(
                title: '📝 Practice Notes',
                child: Text(song.notes, style: theme.textTheme.bodyMedium),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
