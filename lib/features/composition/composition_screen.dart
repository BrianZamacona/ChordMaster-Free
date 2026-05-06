import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import 'composition_viewmodel.dart';

/// Composition tools screen.
class CompositionScreen extends ConsumerWidget {
  /// Creates the [CompositionScreen].
  const CompositionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(compositionViewModelProvider);
    final vm = ref.read(compositionViewModelProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.moduleComposition),
        actions: [
          if (state.chords.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: AppStrings.share,
              onPressed: () async {
                await Clipboard.setData(
                    ClipboardData(text: state.asText));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Progression copied to clipboard!')),
                );
              },
            ),
          if (state.chords.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.play_circle_outline),
              tooltip: AppStrings.play,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Would play: ${state.asText}')),
                );
              },
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Chord palette
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('Add Chords',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: compositionChordPalette
                  .map((chord) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                        child: ActionChip(
                          label: Text(chord,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          backgroundColor:
                              theme.colorScheme.primaryContainer,
                          onPressed: () => vm.addChord(chord),
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Current composition header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text('Composition',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                if (state.chords.isNotEmpty)
                  TextButton.icon(
                    onPressed: vm.clearChords,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Clear'),
                  ),
              ],
            ),
          ),

          // Reorderable chord list
          Expanded(
            child: state.chords.isEmpty
                ? Center(
                    child: Text(
                      'Tap chords above to build your progression',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withAlpha(120)),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: state.chords.length,
                    onReorder: vm.reorderChords,
                    itemBuilder: (context, i) {
                      final chord = state.chords[i];
                      return Card(
                        key: ValueKey('chord_${i}_$chord'),
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.primaryContainer,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                color:
                                    theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            chord,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20),
                                onPressed: () => vm.removeChord(i),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.drag_handle),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom bar
          if (state.chords.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                border: Border(
                    top: BorderSide(
                        color: theme.colorScheme.outline.withAlpha(80))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    state.asText,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(180)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () async {
                      await vm.saveComposition();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Composition saved! 🎼')),
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text(AppStrings.save),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
