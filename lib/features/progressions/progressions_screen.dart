import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/music_theory.dart';
import '../../core/widgets/feature_module_scaffold.dart';
import '../../models/progression.dart';
import 'progressions_viewmodel.dart';

/// Chord progressions screen.
class ProgressionsScreen extends ConsumerWidget {
  /// Creates the [ProgressionsScreen].
  const ProgressionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progressionsViewModelProvider);
    final vm = ref.read(progressionsViewModelProvider.notifier);
    final theme = Theme.of(context);

    return FeatureModuleScaffold(
      title: AppStrings.moduleProgressions,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.key, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: chromaticNotes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final note = chromaticNotes[i];
                  final sel = state.selectedKey == note;
                  return ChoiceChip(
                    label: Text(note),
                    selected: sel,
                    onSelected: (_) => vm.setKey(note),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Major')),
                    selected: state.isMajor,
                    onSelected: (_) => vm.setMajor(isMajor: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Minor')),
                    selected: !state.isMajor,
                    onSelected: (_) => vm.setMajor(isMajor: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: vm.generate,
              icon: const Icon(Icons.auto_awesome),
              label: const Text(AppStrings.generate),
            ),
            if (state.progressionsGenerated >= 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '🎼 Composer achievement unlocked!',
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: Colors.amber),
                  textAlign: TextAlign.center,
                ),
              ),
            if (state.generatedProgressions.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Progressions in ${state.selectedKey} '
                '${state.isMajor ? "Major" : "Minor"}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...state.generatedProgressions
                  .map((p) => _ProgressionCard(progression: p)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressionCard extends StatelessWidget {
  const _ProgressionCard({required this.progression});
  final Progression progression;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    progression.name,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(progression.style,
                      style: theme.textTheme.labelSmall),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: progression.numerals
                  .map((n) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          n,
                          style: theme.textTheme.labelMedium
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: progression.chords
                  .map((c) => Chip(
                        label: Text(
                          c,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: theme.colorScheme.primaryContainer,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
