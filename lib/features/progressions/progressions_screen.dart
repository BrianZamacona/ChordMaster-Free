import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/widgets/chord_diagram.dart';
import '../../core/widgets/feature_module_scaffold.dart';
import '../../domain/progressions/progression_data.dart';
import '../../domain/theory/double_stops.dart' show noteNames;
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
class ProgressionsContent extends ConsumerWidget {
  const ProgressionsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progressionsViewModelProvider);
    final vm = ref.read(progressionsViewModelProvider.notifier);
    final plan = ref.watch(progressionPlanProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.key, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < 12; i++)
                ChoiceChip(
                  label: Text(noteNames[i]),
                  selected: state.tonic == i,
                  onSelected: (_) => vm.setTonic(i),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final p in progressions)
                ChoiceChip(
                  label: Text(p.label),
                  selected: state.progressionId == p.id,
                  onSelected: (_) => vm.setProgression(p.id),
                ),
            ],
          ),
          const SizedBox(height: 20),
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
      ),
    );
  }
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
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final step in plan.steps) ...[
          if (step.transition != null)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: ProgressionTransitionChip(transition: step.transition!),
            ),
          _StepCard(step: step),
        ],
      ],
    ),
  );
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});

  final ProgressionStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chord = step.voicing.chord;
    return Column(
      children: [
        Text(
          step.numeral,
          style: theme.textTheme.labelLarge?.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
        Text(
          chord.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        ChordDiagramWidget(
          chordName: chord.name,
          fretPositions: step.voicing.jsonFrets,
          showChordName: false,
          size: 110,
        ),
      ],
    );
  }
}

/// Chip con el salto de trastes y las notas comunes entre dos acordes.
class ProgressionTransitionChip extends StatelessWidget {
  const ProgressionTransitionChip({super.key, required this.transition});

  final ProgressionTransition transition;

  @override
  Widget build(BuildContext context) {
    final shift = transition.fretShift;
    final common = transition.commonNotes;
    return Tooltip(
      message: 'Costo de transición: ${transition.cost}',
      child: Chip(
        visualDensity: VisualDensity.compact,
        label: Text(
          'salto $shift ${shift == 1 ? 'traste' : 'trastes'} · '
          '$common ${common == 1 ? 'nota común' : 'notas comunes'}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}
