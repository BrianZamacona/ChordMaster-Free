import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/chord_diagram.dart';
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
              title: AppStrings.cagedPositions,
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

class _ExplorerSection extends StatelessWidget {
  const _ExplorerSection({required this.title, required this.items});

  final String title;
  final List<ChordExplorerItem> items;

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

    return _SectionCard(
      title: title,
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _ExplorerItemCard(item: items[index]),
            if (index != items.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ExplorerItemCard extends StatelessWidget {
  const _ExplorerItemCard({required this.item});

  final ChordExplorerItem item;

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
          border: Border.all(color: AppColors.chords.withValues(alpha: 80 / 255)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
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
