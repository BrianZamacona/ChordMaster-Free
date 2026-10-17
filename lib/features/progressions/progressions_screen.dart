import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/chord_metadata.dart';
import '../../core/widgets/chord_diagram.dart';
import '../../core/widgets/feature_module_scaffold.dart';
import '../../core/widgets/selector_pill.dart';
import '../../domain/progressions/progression_data.dart';
import '../../domain/theory/double_stops.dart' show noteNames;
import '../../domain/voicing/barre_detection.dart';
import '../../ui/theme.dart';
import 'progressions_viewmodel.dart';

/// Chord progressions screen.
class ProgressionsScreen extends StatelessWidget {
  /// Creates the [ProgressionsScreen].
  const ProgressionsScreen({super.key});

  @override
  Widget build(BuildContext context) => const FeatureModuleScaffold(
    title: AppStrings.moduleProgressions,
    body: ProgressionsContent(),
  );
}

/// Cuerpo de la pantalla, separado del scaffold para poder probarlo solo.
///
/// Arriba, tonalidad y progresión como botones con hoja; debajo, los acordes
/// en cuadrícula (nunca en una fila con scroll horizontal, que los cortaba).
class ProgressionsContent extends ConsumerWidget {
  const ProgressionsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progressionsViewModelProvider);
    final vm = ref.read(progressionsViewModelProvider.notifier);
    final plan = ref.watch(progressionPlanProvider);
    final current = progressions.firstWhere(
      (p) => p.id == state.progressionId,
      orElse: () => progressions.first,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SelectorPill(
              key: const Key('progression-key'),
              label: AppStrings.progressionKey,
              value: noteNames[state.tonic],
              onOpen: () => showNotePicker(
                context,
                title: AppStrings.progressionKeyTitle,
                selected: noteNames[state.tonic],
                onPicked: (note) {
                  if (note != null) vm.setTonic(noteNames.indexOf(note));
                },
              ),
            ),
            SelectorPill(
              key: const Key('progression-pick'),
              label: AppStrings.progressionLabel,
              value: _numerals(current),
              onOpen: () => _showProgressionSheet(
                context,
                tonic: state.tonic,
                selectedId: current.id,
                onPicked: vm.setProgression,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text(AppStrings.modeStandard)),
            ButtonSegment(value: true, label: Text(AppStrings.modeBeginner)),
          ],
          selected: {state.beginner},
          onSelectionChanged: (s) => vm.setBeginner(beginner: s.first),
        ),
        const SizedBox(height: 16),
        plan.when(
          data: (p) => p.problem != null
              ? _ProblemMessage(message: p.problem!)
              : _PlanView(plan: p),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ProblemMessage(
            message: 'No se pudieron cargar los acordes: $e',
          ),
        ),
      ],
    );
  }

  static String _numerals(Progression p) =>
      [for (final d in p.degrees) d.numeral].join('–');

  static String _chordsIn(Progression p, int tonic) => [
        for (final d in p.degrees)
          chordDisplayName(
            root: noteNames[(tonic + d.semitones) % 12],
            type: d.type,
          ),
      ].join(' · ');

  void _showProgressionSheet(
    BuildContext context, {
    required int tonic,
    required String selectedId,
    required ValueChanged<String> onPicked,
  }) =>
      showSelectorSheet(
        context,
        title: AppStrings.progressionPickTitle,
        builder: (sheet) {
          final p = sheet.palette;
          return Column(
            children: [
              for (final prog in progressions)
                Card(
                  color: prog.id == selectedId
                      ? p.accent.withValues(alpha: 0.18)
                      : null,
                  child: ListTile(
                    key: Key('progression-${prog.id}'),
                    title: Text(
                      _numerals(prog),
                      style: musicMono(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                      ),
                    ),
                    subtitle: Text(_chordsIn(prog, tonic)),
                    trailing: prog.id == selectedId
                        ? Icon(Icons.check, color: p.accent)
                        : null,
                    onTap: () {
                      onPicked(prog.id);
                      Navigator.of(sheet).pop();
                    },
                  ),
                ),
            ],
          );
        },
      );
}

class _ProblemMessage extends StatelessWidget {
  const _ProblemMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(message, key: const Key('progression-problem')),
    ),
  );
}

class _PlanView extends StatelessWidget {
  const _PlanView({required this.plan});

  final ProgressionPlan plan;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 12.0;
      final columns = constraints.maxWidth >= 640 ? 4 : 2;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final step in plan.steps)
            SizedBox(width: width, child: _StepCard(step: step)),
        ],
      );
    },
  );
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});

  final ProgressionStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final chord = step.voicing.chord;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    step.numeral,
                    style: musicMono(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: p.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      chord.name,
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ChordDiagramWidget(
                chordName: chord.name,
                fretPositions: step.voicing.jsonFrets,
                fingerPositions: step.voicing.jsonFingers,
                root: chord.root,
                toneRow: DiagramToneRow.intervals,
                showChordName: false,
                size: constraints.maxWidth.clamp(100, 170).toDouble(),
              ),
              // Solo el modo principiante calcula `barre`; en estándar es null y no hay chip.
              if (step.voicing.barre case final barre?)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Chip(
                    key: const Key('barre-chip'),
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      barreKind(barre) == BarreKind.grande
                          ? '${AppStrings.barreFret} ${barre.fret} · ${AppStrings.barreLarge}'
                          : '${AppStrings.barreFret} ${barre.fret}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ),
              if (step.transition case final t?) ...[
                const SizedBox(height: 6),
                ProgressionTransitionChip(transition: t),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Cómo se llega a este acorde desde el anterior: salto de traste y notas
/// que se mantienen.
class ProgressionTransitionChip extends StatelessWidget {
  const ProgressionTransitionChip({super.key, required this.transition});

  final ProgressionTransition transition;

  @override
  Widget build(BuildContext context) {
    final shift = transition.fretShift;
    final common = transition.commonNotes;
    final p = context.palette;
    final jump = shift == 0
        ? AppStrings.transitionNoJump
        : '${AppStrings.transitionJump} $shift ${shift == 1 ? AppStrings.fretWord : AppStrings.fretsWord}';
    final shared = common == 1
        ? '1 ${AppStrings.transitionCommonOne}'
        : '$common ${AppStrings.transitionCommonMany}';
    return Tooltip(
      message: '${AppStrings.transitionCost}: ${transition.cost}',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.subdirectory_arrow_right, size: 14, color: p.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$jump · $shared',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: p.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
