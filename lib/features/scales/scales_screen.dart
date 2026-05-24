import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/music_theory.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/widgets/donation_button.dart';
import '../../core/widgets/feature_module_scaffold.dart';
import '../../core/widgets/scale_fretboard_diagram.dart';
import '../../models/scale.dart';
import '../../services/audio_service.dart';
import '../../ui/animations.dart';
import 'data/models/scale_pattern.dart' as engine_pattern;
import 'domain/models/string_configuration.dart';
import 'modes_screen.dart';
import 'presentation/widgets/fretboard_diagram.dart' as new_diagram;
import 'scales_engine_providers.dart';
import 'scales_viewmodel.dart';

/// Scales reference screen with Scales / Modes / Exotic tabs.
class ScalesScreen extends ConsumerStatefulWidget {
  /// Creates the [ScalesScreen].
  const ScalesScreen({super.key});

  @override
  ConsumerState<ScalesScreen> createState() => _ScalesScreenState();
}

class _ScalesScreenState extends ConsumerState<ScalesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final cat = ScaleCategory.all[_tabController.index];
        ref.read(scalesViewModelProvider.notifier).filterByCategory(cat);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scalesViewModelProvider);

    return FeatureModuleScaffold(
      title: AppStrings.moduleScales,
      appBarBackgroundColor: AppColors.scales,
      appBarForegroundColor: Colors.white,
      appBarBottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: ScaleCategory.all.map((cat) => Tab(text: cat)).toList(),
      ),
      body: Column(
        children: [
          _RootNoteSelector(
            selectedRoot: state.selectedRoot,
            onSelected: ref.read(scalesViewModelProvider.notifier).filterByRoot,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _ScalesTabContent(category: ScaleCategory.scales),
                ModesScreen(),
                _ScalesTabContent(category: ScaleCategory.exotic),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RootNoteSelector extends StatelessWidget {
  const _RootNoteSelector({
    required this.selectedRoot,
    required this.onSelected,
  });

  final String selectedRoot;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.scales.withAlpha(20),
        height: 52,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: chromaticNotes.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, i) {
            final root = chromaticNotes[i];
            final isSelected = selectedRoot == root;
            return ChoiceChip(
              label: Text(root),
              selected: isSelected,
              selectedColor: AppColors.scales,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => onSelected(root),
            );
          },
        ),
      );
}

/// Renders the list of scales for a given category tab.
class _ScalesTabContent extends ConsumerWidget {
  const _ScalesTabContent({required this.category});

  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scalesViewModelProvider);
    final vm = ref.read(scalesViewModelProvider.notifier);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(
        child: Text(
          AppStrings.errorGeneric,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final scales = state.filteredScales;

    if (scales.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_off,
                size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              AppStrings.emptyScalesSearch,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: scales.length + 1,
      itemBuilder: (context, index) {
        if (index == scales.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: DonationButton()),
          );
        }
        final scale = scales[index];
        return slideUpFade(
          _ScaleCard(
            scale: scale,
            isSelected: state.selectedScale == scale,
            onTap: () => vm.selectScale(scale),
          ),
          duration: Duration(milliseconds: 150 + index * 30),
        );
      },
    );
  }
}

class _ScaleCard extends ConsumerWidget {
  const _ScaleCard({
    required this.scale,
    required this.isSelected,
    required this.onTap,
  });

  final Scale scale;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notes = _computeNotes(scale);
    final intervalLabels =
        scale.intervals.map((i) => intervalNames[i] ?? '$i').toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isSelected
            ? const BorderSide(color: AppColors.scales, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scale.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          scale.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _PlayScaleButton(scale: scale, notes: notes),
                ],
              ),
              const SizedBox(height: 10),
              // Notes chips
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: notes
                    .map(
                      (n) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.scales.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          n,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.scales,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (isSelected) ...[
                const SizedBox(height: 10),
                const Divider(),
                // Interval chips
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: intervalLabels
                      .map(
                        (l) => Chip(
                          label: Text(l, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.commonUsage,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  scale.commonUsage,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                _FingeringSection(
                  title: 'Block Fingering',
                  patterns: scale.blockFingerings,
                ),
                const SizedBox(height: 8),
                _FingeringSection(
                  title: '3 Notes Per String (3NPS)',
                  patterns: scale.threeNotePerStringFingerings,
                ),
                const SizedBox(height: 8),
                _FingeringSection(
                  title: 'CAGED / Popular Shapes',
                  patterns: scale.cagedFingerings,
                ),
                if (scale.blockFingerings.isEmpty &&
                    scale.threeNotePerStringFingerings.isEmpty &&
                    scale.cagedFingerings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 2, bottom: 8),
                    child: _PatternValidationNotice(),
                  ),
                const SizedBox(height: 8),
                _HarmonizedChordsSection(scale: scale),
                const SizedBox(height: 12),
                _GeneratedPatternsSection(scale: scale),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<String> _computeNotes(Scale scale) {
    final rootIdx = chromaticNotes.indexOf(scale.root);
    if (rootIdx == -1) return [];
    return scale.intervals
        .map((i) => chromaticNotes[(rootIdx + i) % 12])
        .toList();
  }
}

class _PlayScaleButton extends StatefulWidget {
  const _PlayScaleButton({required this.scale, required this.notes});

  final Scale scale;
  final List<String> notes;

  @override
  State<_PlayScaleButton> createState() => _PlayScaleButtonState();
}

class _PlayScaleButtonState extends State<_PlayScaleButton> {
  bool _isPlaying = false;

  Future<void> _play() async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    try {
      for (final note in widget.notes) {
        final file = 'assets/audio/notes/${note.replaceAll('#', 's')}4.mp3';
        await AudioService.instance.playNote(file);
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    } catch (e) {
      debugPrint('_PlayScaleButton._play error: $e');
    } finally {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(
          _isPlaying ? Icons.volume_up : Icons.play_circle_outline,
          color: AppColors.scales,
          size: 28,
        ),
        tooltip: AppStrings.play,
        onPressed: _play,
      );
}

class _FingeringSection extends StatelessWidget {
  const _FingeringSection({
    required this.title,
    required this.patterns,
  });

  final String title;
  final List<ScaleFingering> patterns;

  @override
  Widget build(BuildContext context) {
    if (patterns.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        ...patterns.map(
          (pattern) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pattern.name,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (pattern.description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        pattern.description!,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  const SizedBox(height: 8),
                  ScaleFretboardDiagram(
                    pattern: pattern,
                    accentColor: AppColors.scales,
                  ),
                  ...pattern.positions
                      .where((line) => !line.contains('string:'))
                      .map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            line,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PatternValidationNotice extends StatelessWidget {
  const _PatternValidationNotice();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withAlpha(140),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        context.l10n.t('scalesValidationNotice'),
        style: textTheme.labelSmall?.copyWith(
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HarmonizedChordsSection extends StatelessWidget {
  const _HarmonizedChordsSection({required this.scale});

  final Scale scale;

  @override
  Widget build(BuildContext context) {
    if (scale.harmonizedChords.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Harmonized Chords (tap for diagram)',
          style: theme.textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: scale.harmonizedChords
              .map(
                (entry) => ActionChip(
                  label: Text('${entry.degree} ${entry.chord}'),
                  onPressed: () {
                    final encoded = Uri.encodeComponent(entry.chord);
                    context.push('/chords/$encoded');
                  },
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

// ── Generated Patterns Section ────────────────────────────────────────────────

/// Shows algorithmically generated fretboard shapes for the selected scale.
///
/// Uses the new domain engine (domain pipeline) in parallel with the legacy
/// fingering sections, without replacing or modifying them.
class _GeneratedPatternsSection extends ConsumerStatefulWidget {
  const _GeneratedPatternsSection({required this.scale});

  final Scale scale;

  @override
  ConsumerState<_GeneratedPatternsSection> createState() =>
      _GeneratedPatternsSectionState();
}

class _GeneratedPatternsSectionState
    extends ConsumerState<_GeneratedPatternsSection> {
  new_diagram.FretboardLabelMode _labelMode = new_diagram.FretboardLabelMode.note;

  List<int> _openMidiFor(StringConfiguration tuning) {
    switch (tuning.id) {
      case 'dropD':
        return const [38, 45, 50, 55, 59, 64];
      case 'standard7':
        return const [35, 40, 45, 50, 55, 59, 64];
      case 'standard8':
        return const [30, 35, 40, 45, 50, 55, 59, 64];
      case 'banjo5Drone':
        return const [43, 50, 55, 59, 62];
      case 'standard6':
      default:
        return const [40, 45, 50, 55, 59, 64];
    }
  }

  void _triggerCellAudio(new_diagram.FretboardCellPayload payload) {
    final fallback = '${payload.note}4';
    final withOctave = payload.noteWithOctave ?? fallback;
    final file = 'assets/audio/notes/${withOctave.replaceAll('#', 's')}.mp3';
    unawaited(AudioService.instance.playNote(file));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scalesViewModelProvider);
    final vm = ref.read(scalesViewModelProvider.notifier);
    final strategyNames =
        ref.watch(fingeringStrategiesProvider).keys.toList(growable: false);
    final tuningPresets = ref.watch(stringConfigPresetsProvider);
    final filteredTunings = tuningPresets
        .where((t) => t.stringCount == state.engineStringCount)
        .toList(growable: false);
    final selectedTuningId = filteredTunings.any((t) => t.id == state.selectedTuningId)
        ? state.selectedTuningId
        : (filteredTunings.isNotEmpty ? filteredTunings.first.id : null);
    final selectedTuning = selectedTuningId == null
        ? null
        : filteredTunings.firstWhere((t) => t.id == selectedTuningId);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ─────────────────────────────────────────────────
        Row(
          children: [
            Text(
              'Generated Pattern',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            // Starting fret stepper
            _FretStepper(
              value: state.engineStartingFret,
              onDecrement: () {
                final next = (state.engineStartingFret - 1).clamp(0, 20);
                vm.selectStartingFret(next);
              },
              onIncrement: () {
                final next = (state.engineStartingFret + 1).clamp(0, 20);
                vm.selectStartingFret(next);
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        // ── Strategy selector ──────────────────────────────────────────────
        SizedBox(
          height: 30,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: strategyNames.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final name = strategyNames[i];
              final isSelected = state.selectedStrategyName == name;
              return ChoiceChip(
                label: Text(
                  name,
                  style: const TextStyle(fontSize: 10),
                ),
                selected: isSelected,
                selectedColor: AppColors.scales,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6),
                visualDensity: VisualDensity.compact,
                onSelected: (_) => vm.selectStrategy(name),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Strings'),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: state.engineStringCount,
              items: const [5, 6, 7, 8]
                  .map(
                    (count) => DropdownMenuItem<int>(
                      value: count,
                      child: Text('$count'),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) vm.selectStringCount(value);
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedTuningId,
                hint: const Text('Tuning'),
                items: filteredTunings
                    .map(
                      (tuning) => DropdownMenuItem<String>(
                        value: tuning.id,
                        child: Text(
                          tuning.displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: filteredTunings.isEmpty
                    ? null
                    : (value) {
                        if (value != null) vm.selectTuning(value);
                      },
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              'Label',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 8),
            DropdownButton<new_diagram.FretboardLabelMode>(
              value: _labelMode,
              items: const [
                DropdownMenuItem(
                  value: new_diagram.FretboardLabelMode.note,
                  child: Text('Nota'),
                ),
                DropdownMenuItem(
                  value: new_diagram.FretboardLabelMode.interval,
                  child: Text('Intervalo'),
                ),
                DropdownMenuItem(
                  value: new_diagram.FretboardLabelMode.finger,
                  child: Text('Digitación'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _labelMode = value);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        // ── Diagram or empty notice ────────────────────────────────────────
        _GeneratedDiagramCard(
          patterns: state.generatedPatterns,
          labelMode: _labelMode,
          tuningOpenNotes: selectedTuning?.openNotes ??
              const ['E', 'A', 'D', 'G', 'B', 'E'],
          tuningOpenMidi: selectedTuning == null ? null : _openMidiFor(selectedTuning),
          viewportStartFret: state.engineStartingFret,
          viewportEndFret: state.engineStartingFret + state.engineMaxFretSpan,
          onActiveCellTriggered: _triggerCellAudio,
        ),
      ],
    );
  }
}

/// Compact stepper for the engine starting fret.
class _FretStepper extends StatelessWidget {
  const _FretStepper({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Fret',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 24,
          height: 24,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.remove, size: 14),
            onPressed: onDecrement,
          ),
        ),
        SizedBox(
          width: 22,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(
          width: 24,
          height: 24,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.add, size: 14),
            onPressed: onIncrement,
          ),
        ),
      ],
    );
  }
}

/// Renders the generated [engine_pattern.ScalePattern] list.
class _GeneratedDiagramCard extends StatelessWidget {
  const _GeneratedDiagramCard({
    required this.patterns,
    required this.labelMode,
    required this.tuningOpenNotes,
    required this.tuningOpenMidi,
    required this.viewportStartFret,
    required this.viewportEndFret,
    required this.onActiveCellTriggered,
  });

  final List<engine_pattern.ScalePattern> patterns;
  final new_diagram.FretboardLabelMode labelMode;
  final List<String> tuningOpenNotes;
  final List<int>? tuningOpenMidi;
  final int viewportStartFret;
  final int viewportEndFret;
  final ValueChanged<new_diagram.FretboardCellPayload> onActiveCellTriggered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (patterns.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Text(
          'No pattern available for these settings.',
          style: theme.textTheme.labelSmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      );
    }

    return Column(
      children: patterns
          .map(
            (pattern) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${pattern.root} ${pattern.scaleName} · ${pattern.patternType}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          pattern.positionName,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    new_diagram.FretboardDiagram(
                      pattern: pattern,
                      rootColor: AppColors.scales,
                      noteColor: AppColors.scales.withAlpha(180),
                      labelMode: labelMode,
                      tuningOpenNotes: tuningOpenNotes,
                      tuningOpenMidi: tuningOpenMidi,
                      viewportStartFret: viewportStartFret,
                      viewportEndFret: viewportEndFret,
                      onActiveCellTriggered: onActiveCellTriggered,
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
