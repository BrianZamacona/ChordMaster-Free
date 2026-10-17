import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/chord_diagram.dart';
import '../../core/widgets/fingering_theory_card.dart';
import '../../domain/fingering_systems/fingering_systems_registry.dart';
import '../../models/chord.dart';
import 'chord_viewmodel.dart';

/// Explorer screen showing CAGED positions, curated voicings, and inversions.
class ChordExplorerScreen extends ConsumerWidget {
  const ChordExplorerScreen({super.key, required this.chordId});

  final String chordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chordViewModelProvider);
    final vm = ref.read(chordViewModelProvider.notifier);
    final decodedName = Uri.decodeComponent(chordId);

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.chordExplorer),
          backgroundColor: AppColors.chords,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final chord = vm.findByName(decodedName);
    if (chord == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.chordExplorer),
          backgroundColor: AppColors.chords,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(
            AppStrings.errorGeneric,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${chord.displayName ?? chord.name} • ${AppStrings.chordExplorer}',
        ),
        backgroundColor: AppColors.chords,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ExplorerSection(
              title:
                  '${FingeringSystemsRegistry.theoryFor('caged')?.name ?? 'CAGED'} Positions',
              header: const FingeringTheoryCard(systemId: 'caged'),
              labelSharedShapes: true,
              items: chord.cagedPositions,
            ),
            const SizedBox(height: 16),
            _ExplorerSection(
              title: AppStrings.curatedVoicings,
              items: chord.voicings,
            ),
            const SizedBox(height: 16),
            _ExplorerSection(
              title: AppStrings.triadInversions,
              items: chord.triadInversions,
            ),
            const SizedBox(height: 16),
            _ExplorerSection(
              title: AppStrings.advancedInversions,
              items: chord.advancedInversions,
            ),
            if (!chord.hasExplorerData)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  AppStrings.chordExplorerEmpty,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Etiquetas "G (usa la digitación E)" por índice, para formas con
/// `fretPositions` idénticos; la última forma del grupo es la de referencia.
@visibleForTesting
Map<int, String> sharedShapeLabels(List<ChordExplorerItem> items) {
  final groups = <String, List<int>>{};
  for (var i = 0; i < items.length; i++) {
    groups.putIfAbsent(items[i].fretPositions.join(','), () => []).add(i);
  }
  String name(ChordExplorerItem item) => item.shape ?? item.title;
  return {
    for (final group in groups.values)
      if (group.length > 1)
        for (final i in group.take(group.length - 1))
          i: '${name(items[i])} (usa la digitación ${name(items[group.last])})',
  };
}

class _ExplorerSection extends StatelessWidget {
  const _ExplorerSection({
    required this.title,
    required this.items,
    this.header,
    this.labelSharedShapes = false,
  });

  final String title;
  final List<ChordExplorerItem> items;
  final Widget? header;
  final bool labelSharedShapes;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _SectionCard(
        title: title,
        child: Text(
          AppStrings.noDataAvailable,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );
    }

    final sharedLabels =
        labelSharedShapes ? sharedShapeLabels(items) : const <int, String>{};
    return _SectionCard(
      title: title,
      child: Column(
        children: [
          if (header != null) ...[header!, const SizedBox(height: 12)],
          for (var index = 0; index < items.length; index++) ...[
            _ExplorerItemCard(
              item: items[index],
              titleOverride: sharedLabels[index],
            ),
            if (index != items.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ExplorerItemCard extends StatelessWidget {
  const _ExplorerItemCard({required this.item, this.titleOverride});

  final ChordExplorerItem item;
  final String? titleOverride;

  String _buildSubtitle() {
    final parts = <String>[];
    if (item.shape != null) {
      parts.add('${AppStrings.shapeLabel}: ${item.shape}');
    }
    if (item.description != null) {
      parts.add(item.description!);
    }
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.chords.withValues(alpha: 0.31)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titleOverride ?? item.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (item.shape != null || item.description != null) ...[
              const SizedBox(height: 2),
              Text(
                _buildSubtitle(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            Center(
              child: ChordDiagramWidget(
                chordName: item.title,
                fretPositions: item.fretPositions,
                baseFret: item.baseFret,
                showChordName: false,
                size: 140,
              ),
            ),
          ],
        ),
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.chords,
                    ),
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      );
}
