import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/i18n/tr.dart';
import '../../core/widgets/feature_module_scaffold.dart';
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

  static List<(String, String, String)> get _warmupExercises => [
    (
      '🤲',
      tr(es: 'Estirar los dedos', en: 'Finger stretches'),
      tr(
        es: 'Abre bien los dedos, aguanta 5 s y relaja. Repite 5 veces.',
        en: 'Spread fingers wide, hold 5 sec, relax. Repeat 5x.',
      ),
    ),
    (
      '✊',
      tr(es: 'Puño', en: 'Fist pump'),
      tr(
        es: 'Cierra el puño fuerte 3 s y ábrelo del todo. Repite 10 veces.',
        en: 'Clench fist tight, hold 3 sec, open wide. Repeat 10x.',
      ),
    ),
    (
      '🔄',
      tr(es: 'Círculos de muñeca', en: 'Wrist circles'),
      tr(
        es: 'Gira las muñecas en un sentido y luego en el otro, 10 veces cada uno.',
        en: 'Rotate wrists clockwise then counter-clockwise, 10x each.',
      ),
    ),
    (
      '💪',
      tr(es: 'Estirar el antebrazo', en: 'Forearm stretch'),
      tr(
        es: 'Extiende el brazo y tira suave de los dedos hacia atrás. 15 s por mano.',
        en: 'Extend arm, pull fingers back gently. Hold 15 sec per hand.',
      ),
    ),
    (
      '👐',
      tr(es: 'Caminata de piano', en: 'Piano walk'),
      tr(
        es: 'Toca el pulgar con cada dedo, uno a uno, con ambas manos. 3 rondas.',
        en: 'Tap each finger to thumb one-by-one, both hands, 3 rounds.',
      ),
    ),
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

    return FeatureModuleScaffold(
      title: AppStrings.moduleHealth,
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
                      AppStrings.practiceSession,
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
                            label: Text(AppStrings.start),
                          )
                        else
                          FilledButton.icon(
                            onPressed: vm.stopSession,
                            icon: const Icon(Icons.stop),
                            label: Text(AppStrings.stop),
                          ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: vm.resetSession,
                          icon: const Icon(Icons.refresh),
                          label: Text(AppStrings.reset),
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
                      AppStrings.breakReminders,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(AppStrings.enableReminders),
                      subtitle: Text(AppStrings.enableRemindersSub),
                      value: state.remindersEnabled,
                      onChanged: (v) => vm.toggleReminders(enabled: v),
                    ),
                    if (state.remindersEnabled) ...[
                      Text(AppStrings.remindEvery, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [15, 30, 45, 60]
                            .map((m) => ChoiceChip(
                                  label: Text('${m}m'),
                                  selected: state.reminderIntervalMinutes == m,
                                  onSelected: (_) => vm.setReminderInterval(m),
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
                      AppStrings.warmupExercises,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ..._warmupExercises.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.$1, style: const TextStyle(fontSize: 28)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
