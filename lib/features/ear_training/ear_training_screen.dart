import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../models/interval_model.dart';
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
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.moduleEarTraining),
        actions: [
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Score / streak header
            Row(
              children: [
                _StatChip(
                    label: AppStrings.streak,
                    value: '${state.streak} 🔥'),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Total Done',
                  value: '${state.totalExercisesDone}',
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Accuracy',
                  value:
                      '${(state.accuracy * 100).toStringAsFixed(0)}%',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Interval display (shows the interval name as a visual cue
            // since no audio playback is available)
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 32, horizontal: 16),
                child: Column(
                  children: [
                    const Text(
                      '🎵',
                      style: TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.identifyInterval,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'C → ${_noteAtSemitone(state.currentInterval.semitones)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${state.currentInterval.semitones} semitone${state.currentInterval.semitones == 1 ? "" : "s"}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer
                            .withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Answer choices
            if (state.lastAnswerCorrect == null) ...[
              Text(
                'Choose the interval:',
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
                      ? Colors.green.withAlpha(40)
                      : Colors.red.withAlpha(40),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: state.lastAnswerCorrect!
                        ? Colors.green
                        : Colors.red,
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
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'It was: ${state.currentInterval.name} (${state.currentInterval.shortName})',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${state.currentInterval.sound}"',
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
                    '👂 Ear Wizard achievement unlocked!',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.amber),
                    textAlign: TextAlign.center,
                  ),
                ),
              FilledButton.icon(
                onPressed: vm.nextQuestion,
                icon: const Icon(Icons.arrow_forward),
                label: const Text(AppStrings.next),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _noteAtSemitone(int semitones) {
    const notes = [
      'C', 'C#', 'D', 'D#', 'E', 'F',
      'F#', 'G', 'G#', 'A', 'A#', 'B', 'C',
    ];
    return notes[semitones.clamp(0, 12)];
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            interval.name,
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
