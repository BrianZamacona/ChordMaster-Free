import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/music_theory.dart';
import '../../core/widgets/chord_diagram.dart';
import '../../core/widgets/donation_button.dart';
import '../../models/chord.dart';
import '../../services/achievement_service.dart';
import '../../services/audio_service.dart';
import '../../ui/animations.dart';
import 'chord_viewmodel.dart';

/// Detail screen for a single chord identified by [chordId] (URL-encoded name).
class ChordDetailScreen extends ConsumerStatefulWidget {
  /// Creates a [ChordDetailScreen] for the chord with [chordId].
  const ChordDetailScreen({super.key, required this.chordId});

  /// URL-encoded chord name from path parameter `:id`.
  final String chordId;

  @override
  ConsumerState<ChordDetailScreen> createState() => _ChordDetailScreenState();
}

class _ChordDetailScreenState extends ConsumerState<ChordDetailScreen> {
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    unawaited(_unlockFirstChordAchievement());
  }

  Future<void> _unlockFirstChordAchievement() async {
    try {
      await AchievementService.instance.unlock('first_chord');
    } catch (e) {
      debugPrint('ChordDetailScreen: achievement unlock error: $e');
    }
  }

  Future<void> _playChord(Chord chord) async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    try {
      if (chord.audioFile != null) {
        await AudioService.instance.playNote(chord.audioFile!);
      } else {
        // Synthesise by playing root note file if it exists
        final rootFile =
            'assets/audio/notes/${chord.root.replaceAll('#', 's')}4.mp3';
        await AudioService.instance.playNote(rootFile);
      }
    } catch (e) {
      debugPrint('ChordDetailScreen._playChord error: $e');
    } finally {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chordState = ref.watch(chordViewModelProvider);
    final vm = ref.read(chordViewModelProvider.notifier);
    final decodedName = Uri.decodeComponent(widget.chordId);

    if (chordState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(decodedName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final chord = vm.findByName(decodedName);

    if (chord == null) {
      return Scaffold(
        appBar: AppBar(title: Text(decodedName)),
        body: Center(
          child: Text(
            AppStrings.errorGeneric,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    final relatedChords = vm.relatedByRoot(chord);
    final formulaText = _buildFormulaText(chord);

    return Scaffold(
      appBar: AppBar(
        title: Text(chord.name),
        backgroundColor: AppColors.chords,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            slideUpFade(
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chord.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          chordQualityDisplayNames[chord.type] ?? chord.type,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.chords,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        _DifficultyRow(difficulty: chord.difficulty),
                      ],
                    ),
                  ),
                  _PlayButton(
                    isPlaying: _isPlaying,
                    onTap: () => _playChord(chord),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Chord Diagram ────────────────────────────────────────────────
            Center(
              child: scaleIn(
                ChordDiagramWidget(
                  chordName: chord.name,
                  fretPositions: chord.fretPositions,
                  size: 200,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Formula ──────────────────────────────────────────────────────
            fadeIn(
              _SectionCard(
                title: 'Chord Formula',
                child: Text(
                  formulaText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Fret Positions ───────────────────────────────────────────────
            fadeIn(
              _SectionCard(
                title: AppStrings.fretPositions,
                child: _FretPositionRow(
                  fretPositions: chord.fretPositions,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Related Chords ───────────────────────────────────────────────
            if (relatedChords.isNotEmpty)
              fadeIn(
                _SectionCard(
                  title: '${chord.root} Related Chords',
                  child: SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: relatedChords.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final related = relatedChords[i];
                        return _RelatedChordChip(
                          chord: related,
                          onTap: () {
                            final encoded =
                                Uri.encodeComponent(related.name);
                            context.go('/chords/$encoded');
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // ── Related Scales ───────────────────────────────────────────────
            fadeIn(
              _SectionCard(
                title: AppStrings.relatedChords,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _relatedScales(chord)
                      .map(
                        (s) => ActionChip(
                          label: Text(s, style: const TextStyle(fontSize: 12)),
                          onPressed: () => context.go('/scales'),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Center(child: DonationButton()),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _buildFormulaText(Chord chord) {
    return chord.intervals
        .map((i) => intervalNames[i] ?? '$i semitones')
        .join(' — ');
  }

  List<String> _relatedScales(Chord chord) {
    final scales = <String>[];
    if (chord.type == 'major' || chord.type == 'dominant7') {
      scales.addAll([
        '${chord.root} Major',
        '${chord.root} Pentatonic Major',
        '${chord.root} Mixolydian',
      ]);
    } else if (chord.type.contains('minor')) {
      scales.addAll([
        '${chord.root} Natural Minor',
        '${chord.root} Pentatonic Minor',
        '${chord.root} Blues',
        '${chord.root} Dorian',
      ]);
    } else if (chord.type == 'diminished') {
      scales.addAll(['${chord.root} Locrian', '${chord.root} Harmonic Minor']);
    } else {
      scales.addAll(['${chord.root} Major', '${chord.root} Natural Minor']);
    }
    return scales;
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.isPlaying, required this.onTap});

  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isPlaying ? AppColors.chords.withAlpha(150) : AppColors.chords,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.chords.withAlpha(80),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.volume_up : Icons.play_arrow,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}

class _DifficultyRow extends StatelessWidget {
  const _DifficultyRow({required this.difficulty});

  final int difficulty;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${AppStrings.difficulty}: ',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        ...List.generate(
          5,
          (i) => Icon(
            i < difficulty ? Icons.star : Icons.star_border,
            size: 14,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.chords,
                  ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _FretPositionRow extends StatelessWidget {
  const _FretPositionRow({required this.fretPositions});

  final List<int> fretPositions;

  static const _stringLabels = ['E', 'A', 'D', 'G', 'B', 'e'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (i) {
        final fret = fretPositions[i];
        final label = fret == -1
            ? 'X'
            : fret == 0
                ? 'O'
                : '$fret';
        return Column(
          children: [
            Text(
              _stringLabels[i],
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: fret == -1
                    ? AppColors.error.withAlpha(40)
                    : fret == 0
                        ? AppColors.success.withAlpha(40)
                        : AppColors.chords.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: fret == -1
                      ? AppColors.error
                      : fret == 0
                          ? AppColors.success
                          : AppColors.chords,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _RelatedChordChip extends StatelessWidget {
  const _RelatedChordChip({required this.chord, required this.onTap});

  final Chord chord;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.chords.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.chords.withAlpha(80)),
        ),
        child: Text(
          chord.name,
          style: const TextStyle(
            color: AppColors.chords,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
