import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/chord_metadata.dart';
import '../../core/constants/interval_texts.dart';
import '../../core/constants/music_theory.dart';
import '../../core/constants/scale_names.dart';
import '../../core/widgets/chord_diagram.dart';
import '../../core/widgets/donation_button.dart';
import '../../core/widgets/interval_legend.dart';
import '../../data/models/scale_definition.dart';
import '../../data/repository/scale_repository.dart';
import '../../domain/theory/double_stops.dart' show noteNames;
import '../../domain/theory/scale_insights.dart';
import '../../domain/voicing/fingering_metrics.dart';
import '../../models/chord.dart';
import '../../services/achievement_service.dart';
import '../../services/audio_service.dart';
import '../../ui/animations.dart';
import '../../ui/palette.dart';
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
  DiagramDotLabel _dotLabel = DiagramDotLabel.finger;

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
        final rootFile = 'assets/audio/notes/${chord.root.replaceAll('#', 's')}4.mp3';
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

    final displayName = chordDisplayName(
      root: chord.root,
      type: chord.type,
      explicitDisplayName: chord.displayName,
    );
    final aliases = chordAliases(chord.type, chord.aliases);
    final tags = chordTags(chord.type, chord.tags);
    final description = chordDescription(chord.type, chord.description);
    final relatedChords = vm.relatedByRoot(chord).take(10).toList(growable: false);
    final styleMatches = vm.relatedByTags(chord);
    final formulaText = _buildFormulaText(chord);

    return Scaffold(
      appBar: AppBar(
        title: Text(displayName),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: AppStrings.chordExplorer,
            onPressed: () {
              final encoded = Uri.encodeComponent(chord.name);
              context.go('/learn/chords/$encoded/explorer');
            },
            icon: const Icon(Icons.explore_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            slideUpFade(
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          chordTypeLabel(chord.type),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: context.palette.accent,
                              ),
                        ),
                        if (aliases.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            aliases.join(' • '),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: context.palette.textSecondary,
                                ),
                          ),
                        ],
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
            Center(
              child: SegmentedButton<DiagramDotLabel>(
                key: const Key('diagram-label-toggle'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: DiagramDotLabel.finger,
                    label: Text(AppStrings.showFingers),
                  ),
                  ButtonSegment(
                    value: DiagramDotLabel.interval,
                    label: Text(AppStrings.showIntervals),
                  ),
                  ButtonSegment(
                    value: DiagramDotLabel.note,
                    label: Text(AppStrings.showNotes),
                  ),
                ],
                selected: {_dotLabel},
                onSelectionChanged: (s) => setState(() => _dotLabel = s.first),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: scaleIn(
                ChordDiagramWidget(
                  chordName: chord.name,
                  fretPositions: chord.fretPositions,
                  fingerPositions: chord.fingerPositions,
                  root: chord.root,
                  dotLabel: _dotLabel,
                  toneRow: DiagramToneRow.intervalsAndNotes,
                  baseFret: chord.baseFret,
                  showChordName: false,
                  size: 230,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: IntervalLegend(
                labels: [
                  for (final t in stringTonesFromChordJson(
                    jsonFrets: chord.fretPositions,
                    root: chord.root,
                  ))
                    if (t != null) t.label,
                ],
              ),
            ),
            const SizedBox(height: 24),
            fadeIn(
              _SectionCard(
                title: AppStrings.chordCategory,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .map(
                        (tag) => Chip(
                          label: Text(chordTagLabel(tag)),
                          backgroundColor: context.palette.accent.withAlpha(35),
                          side: BorderSide(color: context.palette.accent.withAlpha(90)),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            if (aliases.isNotEmpty) ...[
              const SizedBox(height: 12),
              fadeIn(
                _SectionCard(
                  title: AppStrings.chordAliases,
                  child: Text(
                    aliases.join(', '),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
            if (description != null) ...[
              const SizedBox(height: 12),
              fadeIn(
                _SectionCard(
                  title: AppStrings.chordDescription,
                  child: Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            fadeIn(
              _SectionCard(
                title: AppStrings.chordFormula,
                child: Text(
                  formulaText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 12),
            fadeIn(
              _SectionCard(
                title: AppStrings.fretPositions,
                child: _FretPositionRow(
                  fretPositions: chord.fretPositions,
                ),
              ),
            ),
            if (relatedChords.isNotEmpty) ...[
              const SizedBox(height: 12),
              fadeIn(
                _SectionCard(
                  title: AppStrings.relatedChordsOf(chord.root),
                  child: SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: relatedChords.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final related = relatedChords[index];
                        return _RelatedChordChip(
                          label: chordDisplayName(
                            root: related.root,
                            type: related.type,
                            explicitDisplayName: related.displayName,
                          ),
                          onTap: () {
                            final encoded = Uri.encodeComponent(related.name);
                            context.go('/learn/chords/$encoded');
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
            if (styleMatches.isNotEmpty) ...[
              const SizedBox(height: 12),
              fadeIn(
                _SectionCard(
                  title: AppStrings.styleMatches,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: styleMatches
                        .map(
                          (related) => _InlineChordChip(
                            label: chordDisplayName(
                              root: related.root,
                              type: related.type,
                              explicitDisplayName: related.displayName,
                            ),
                            onTap: () {
                              final encoded = Uri.encodeComponent(related.name);
                              context.go('/learn/chords/$encoded');
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            fadeIn(
              _SectionCard(
                title: AppStrings.relatedScales,
                child: _RelatedScales(chord: chord),
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
    final symbols = chord.intervals
        .map((interval) => intervalSymbols[interval] ?? '$interval semitones')
        .join(' • ');
    final names = chord.intervals
        .map((i) => i == 0 ? AppStrings.legendRoot : intervalLongName(i))
        .join(' — ');
    return '$symbols\n$names';
  }
}

/// Escalas que contienen todas las notas del acorde (regla de
/// [scalesForChord]); cada una abre su detalle en la raíz del acorde.
class _RelatedScales extends ConsumerWidget {
  const _RelatedScales({required this.chord});

  final Chord chord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = [
      ...?ref.watch(allScalesProvider).value,
      ...?ref.watch(allModesProvider).value,
    ];
    final byId = {for (final s in all) s.id: s};
    final ids = scalesForChord(chord.intervals, {
      for (final s in all) s.id: s.intervals,
    });
    final root = noteNames.indexOf(chord.root);
    if (ids.isEmpty) {
      return Text(AppStrings.relatedScalesNone, style: Theme.of(context).textTheme.bodySmall);
    }
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final id in ids)
          ActionChip(
            key: Key('related-scale-$id'),
            label: Text(
              '${chord.root} ${_name(byId[id]!)}',
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: () => context.go(
              '/learn/scales/$id?root=${root < 0 ? 0 : root}',
              extra: byId[id],
            ),
          ),
      ],
    );
  }

  static String _name(ScaleDefinition s) =>
      scaleDisplayName(s.id, s.intervals, fallback: s.name);
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.isPlaying, required this.onTap});

  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: isPlaying ? context.palette.accent.withAlpha(150) : context.palette.accent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: context.palette.accent.withAlpha(80),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            isPlaying ? Icons.volume_up : Icons.play_arrow,
            color: context.palette.onAccent,
            size: 32,
          ),
        ),
      );
}

class _DifficultyRow extends StatelessWidget {
  const _DifficultyRow({required this.difficulty});

  final int difficulty;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${AppStrings.difficulty}: ',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          ...List.generate(
            5,
            (index) => Icon(
              index < difficulty ? Icons.star : Icons.star_border,
              size: 14,
              color: context.palette.accent,
            ),
          ),
        ],
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.palette.accent,
                    ),
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      );
}

class _FretPositionRow extends StatelessWidget {
  const _FretPositionRow({required this.fretPositions});

  final List<int> fretPositions;

  static const _stringLabels = ['E', 'A', 'D', 'G', 'B', 'e'];

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (index) {
          final fret = fretPositions[index];
          final label = fret == -1
              ? 'X'
              : fret == 0
                  ? 'O'
                  : '$fret';
          return Column(
            children: [
              Text(
                _stringLabels[index],
                style: TextStyle(fontSize: 11, color: context.palette.textSecondary),
              ),
              const SizedBox(height: 4),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: fret == -1
                      ? context.palette.error.withAlpha(40)
                      : fret == 0
                          ? context.palette.success.withAlpha(40)
                          : context.palette.accent.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: fret == -1
                        ? context.palette.error
                        : fret == 0
                            ? context.palette.success
                            : context.palette.accent,
                  ),
                ),
              ),
            ],
          );
        }),
      );
}

class _RelatedChordChip extends StatelessWidget {
  const _RelatedChordChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.palette.accent.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.palette.accent.withAlpha(80)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: context.palette.accent,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      );
}

class _InlineChordChip extends StatelessWidget {
  const _InlineChordChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
        label: Text(label),
        onPressed: onTap,
        backgroundColor: context.palette.accent.withAlpha(25),
        side: BorderSide(color: context.palette.accent.withAlpha(70)),
      );
}
