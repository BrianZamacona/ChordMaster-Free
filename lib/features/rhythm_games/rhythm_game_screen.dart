import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import 'rhythm_game_viewmodel.dart';

/// Rhythm game screen.
class RhythmGameScreen extends ConsumerWidget {
  /// Creates the [RhythmGameScreen].
  const RhythmGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rhythmGameViewModelProvider);
    final vm = ref.read(rhythmGameViewModelProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.moduleRhythmGame)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // BPM control
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '${state.bpm}',
                      style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold),
                    ),
                    Text(AppStrings.bpm,
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Slider(
                      value: state.bpm.toDouble(),
                      min: 20,
                      max: 220,
                      divisions: 200,
                      label: '${state.bpm}',
                      onChanged: state.isRunning
                          ? null
                          : (v) => vm.setBpm(v.round()),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: state.isRunning
                              ? null
                              : () => vm.setBpm(state.bpm - 5),
                          icon: const Icon(Icons.remove),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: state.isRunning
                              ? null
                              : () => vm.setBpm(state.bpm + 5),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Beat visualiser
            AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              height: 80,
              decoration: BoxDecoration(
                color: state.isBeatActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: state.isBeatActive
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withAlpha(120),
                          blurRadius: 16,
                          spreadRadius: 4,
                        )
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  state.isRunning
                      ? (state.isBeatActive ? '●' : '○')
                      : '○',
                  style: TextStyle(
                    fontSize: 40,
                    color: state.isBeatActive
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface.withAlpha(100),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Start / Stop
            Row(
              children: [
                Expanded(
                  child: state.isRunning
                      ? FilledButton.icon(
                          onPressed: vm.stop,
                          icon: const Icon(Icons.stop),
                          label: const Text(AppStrings.stop),
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.red),
                        )
                      : FilledButton.icon(
                          onPressed: vm.start,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text(AppStrings.start),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tap button
            SizedBox(
              height: 80,
              child: ElevatedButton(
                onPressed: state.isRunning ? vm.tap : null,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  backgroundColor: theme.colorScheme.secondaryContainer,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.touch_app, size: 32),
                    Text(AppStrings.tap,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Score display
            if (state.isRunning || state.tapResults.isNotEmpty)
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ScoreItem(
                          label: 'Taps',
                          value: '${state.tapsCount}'),
                      _ScoreItem(
                          label: 'Accuracy',
                          value: '${state.accuracy}%',
                          highlight: state.accuracy >= 90),
                      _ScoreItem(
                          label: 'Best',
                          value: '${state.bestScore}%'),
                    ],
                  ),
                ),
              ),

            if (!state.isRunning && state.tapResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              if (state.accuracy >= 90)
                Text(
                  '🥁 Rhythm Master achievement unlocked!',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.amber),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 8),
              Text(
                'Last ${state.tapResults.take(5).length} taps:',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                children: state.tapResults
                    .take(10)
                    .map((r) => Chip(
                          label: Text(
                            r.offsetMs >= 0
                                ? '+${r.offsetMs}ms'
                                : '${r.offsetMs}ms',
                            style: TextStyle(
                              fontSize: 11,
                              color: r.isAccurate
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          backgroundColor: r.isAccurate
                              ? Colors.green.withAlpha(30)
                              : Colors.red.withAlpha(30),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreItem extends StatelessWidget {
  const _ScoreItem(
      {required this.label, required this.value, this.highlight = false});
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: highlight ? Colors.green : null,
          ),
        ),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
