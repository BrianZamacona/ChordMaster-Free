import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/interval_texts.dart';
import '../../core/widgets/feature_module_scaffold.dart';
import '../../models/interval_model.dart';
import '../../ui/palette.dart';
import 'ear_training_viewmodel.dart';

/// Ear training screen.
class EarTrainingScreen extends ConsumerWidget {
  /// Creates the [EarTrainingScreen].
  const EarTrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(earTrainingViewModelProvider);
    final vm = ref.read(earTrainingViewModelProvider.notifier);
    final theme = Theme.of(context);

    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return FeatureModuleScaffold(
      title: AppStrings.moduleEarTraining,
      appBarActions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              '${AppStrings.score}: ${state.correctAnswers}/${state.totalAnswered}',
              style: theme.textTheme.labelLarge,
            ),
          ),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Score / streak header
            Row(
              children: [
                _StatChip(
                    label: AppStrings.streak, value: '${state.streak} 🔥'),
                const SizedBox(width: 8),
                _StatChip(
                  label: AppStrings.statTotal,
                  value: '${state.totalExercisesDone}',
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: AppStrings.statAccuracy,
                  value: '${(state.accuracy * 100).toStringAsFixed(0)}%',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Se escucha; la respuesta (notas y semitonos) solo aparece al
            // contestar.
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      AppStrings.identifyInterval,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const Key('ear-play'),
                      onPressed: vm.play,
                      icon: const Icon(Icons.volume_up),
                      label: Text(AppStrings.earListen),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<bool>(
                      key: const Key('ear-mode'),
                      segments: [
                        ButtonSegment(value: false, label: Text(AppStrings.earMelodic)),
                        ButtonSegment(value: true, label: Text(AppStrings.earHarmonic)),
                      ],
                      selected: {state.harmonic},
                      onSelectionChanged: (s) => vm.setHarmonic(harmonic: s.first),
                    ),
                    if (state.lastAnswerCorrect != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${vm.displayRootNote} → ${vm.displayIntervalNote} · '
                        '${AppStrings.semitonesCount(state.currentInterval.semitones)}',
                        key: const Key('ear-reveal'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Answer choices
            if (state.lastAnswerCorrect == null) ...[
              Text(
                AppStrings.chooseInterval,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.5,
                  children: state.choices
                      .map((interval) => _ChoiceButton(
                            interval: interval,
                            onTap: () => vm.answer(interval),
                          ))
                      .toList(),
                ),
              ),
            ] else ...[
              // Result display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: state.lastAnswerCorrect!
                      ? context.palette.success.withAlpha(40)
                      : context.palette.error.withAlpha(40),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: state.lastAnswerCorrect! ? context.palette.success : context.palette.error,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      state.lastAnswerCorrect!
                          ? '✅ ${AppStrings.correct}'
                          : '❌ ${AppStrings.incorrect}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: state.lastAnswerCorrect!
                            ? context.palette.success
                            : context.palette.error,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.itWas(
                        intervalLongName(
                          state.currentInterval.semitones,
                          fallback: state.currentInterval.name,
                        ),
                        state.currentInterval.shortName,
                      ),
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${intervalSound(state.currentInterval.semitones, fallback: state.currentInterval.sound)}"',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (state.totalExercisesDone >= 20)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    AppStrings.earWizardUnlocked,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: context.palette.accent),
                    textAlign: TextAlign.center,
                  ),
                ),
              FilledButton.icon(
                onPressed: vm.nextQuestion,
                icon: const Icon(Icons.arrow_forward),
                label: Text(AppStrings.next),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(value,
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSecondaryContainer)),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({required this.interval, required this.onTap});
  final IntervalModel interval;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            intervalLongName(interval.semitones, fallback: interval.name),
            style: theme.textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            interval.shortName,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
