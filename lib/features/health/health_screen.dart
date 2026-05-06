import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import 'health_viewmodel.dart';

/// Practice health and wellness screen.
class HealthScreen extends ConsumerWidget {
  /// Creates the [HealthScreen].
  const HealthScreen({super.key});

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static const _warmupExercises = [
    ('🤲', 'Finger stretches', 'Spread fingers wide, hold 5 sec, relax. Repeat 5x.'),
    ('✊', 'Fist pump', 'Clench fist tight, hold 3 sec, open wide. Repeat 10x.'),
    ('🔄', 'Wrist circles', 'Rotate wrists clockwise then counter-clockwise, 10x each.'),
    ('💪', 'Forearm stretch', 'Extend arm, pull fingers back gently. Hold 15 sec per hand.'),
    ('👐', 'Piano walk', 'Tap each finger to thumb one-by-one, both hands, 3 rounds.'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(healthViewModelProvider);
    final vm = ref.read(healthViewModelProvider.notifier);
    final theme = Theme.of(context);

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.moduleHealth)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Session Timer Card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      '⏱️ Practice Session',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _formatDuration(state.sessionSeconds),
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!state.isSessionActive)
                          FilledButton.icon(
                            onPressed: vm.startSession,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text(AppStrings.start),
                          )
                        else
                          FilledButton.icon(
                            onPressed: vm.stopSession,
                            icon: const Icon(Icons.stop),
                            label: const Text(AppStrings.stop),
                          ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: vm.resetSession,
                          icon: const Icon(Icons.refresh),
                          label: const Text(AppStrings.reset),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Break Reminders Card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔔 Break Reminders',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable reminders'),
                      subtitle: const Text('Get notified to rest your hands'),
                      value: state.remindersEnabled,
                      onChanged: vm.toggleReminders,
                    ),
                    if (state.remindersEnabled) ...[
                      Text('Remind every:',
                          style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [15, 30, 45, 60]
                            .map((m) => ChoiceChip(
                                  label: Text('${m}m'),
                                  selected:
                                      state.reminderIntervalMinutes == m,
                                  onSelected: (_) =>
                                      vm.setReminderInterval(m),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Warmup Exercises Card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🤸 Warm-up Exercises',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ..._warmupExercises.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.$1,
                                  style: const TextStyle(fontSize: 28)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.$2,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                    ),
                                    Text(e.$3,
                                        style: theme.textTheme.bodySmall),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Health tip card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: theme.colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.takeABreak,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.warmUpReminder,
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
