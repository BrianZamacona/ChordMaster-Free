import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/chord_diagram.dart';
import '../../core/widgets/fingering_theory_card.dart';
import '../../domain/fingering_systems/fingering_systems_registry.dart';
import '../../models/chord.dart';
import 'chord_viewmodel.dart';
import 'fingering_selection.dart';

export 'fingering_selection.dart' show sharedShapeLabels;

/// Explorer screen showing CAGED positions, curated voicings, and inversions.
///
/// Cada digitación se puede marcar para el comparador (máx. 3).
class ChordExplorerScreen extends ConsumerStatefulWidget {
  const ChordExplorerScreen({super.key, required this.chordId});

  final String chordId;

  @override
  ConsumerState<ChordExplorerScreen> createState() =>
      _ChordExplorerScreenState();
}

class _ChordExplorerScreenState extends ConsumerState<ChordExplorerScreen> {
  /// En orden de selección; así se arman las columnas del comparador.
  final _selected = <FingeringRef>[];

  void _toggle(FingeringRef fingering) => setState(() {
        if (!_selected.remove(fingering) &&
            _selected.length < maxCompareSelection) {
          _selected.add(fingering);
        }
      });

  void _openCompare(Chord chord) {
    final encoded = Uri.encodeComponent(chord.name);
    final sel = _selected.map((r) => r.key).join(',');
    context.go('/chords/$encoded/compare?sel=$sel');
  }

  @override
  Widget build(BuildContext context) {
    final chordId = widget.chordId;
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
              sectionId: 'caged',
              items: chord.cagedPositions,
              selected: _selected,
              onToggle: _toggle,
            ),
            const SizedBox(height: 16),
            _ExplorerSection(
              title: AppStrings.curatedVoicings,
              sectionId: 'voicings',
              items: chord.voicings,
              selected: _selected,
              onToggle: _toggle,
            ),
            const SizedBox(height: 16),
            _ExplorerSection(
              title: AppStrings.triadInversions,
              sectionId: 'triadInversions',
              items: chord.triadInversions,
              selected: _selected,
              onToggle: _toggle,
            ),
            const SizedBox(height: 16),
            _ExplorerSection(
              title: AppStrings.advancedInversions,
              sectionId: 'advancedInversions',
              items: chord.advancedInversions,
              selected: _selected,
              onToggle: _toggle,
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
      bottomNavigationBar: chord.hasExplorerData
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: FilledButton.icon(
                  key: const Key('compare-bar-button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.chords,
                  ),
                  onPressed:
                      _selected.length >= 2 ? () => _openCompare(chord) : null,
                  icon: const Icon(Icons.compare_arrows),
                  label: Text(
                    '${AppStrings.compareButton} (${_selected.length})',
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _ExplorerSection extends StatelessWidget {
  const _ExplorerSection({
    required this.title,
    required this.sectionId,
    required this.items,
    required this.selected,
    required this.onToggle,
    this.header,
    this.labelSharedShapes = false,
  });

  final String title;
  final String sectionId;
  final List<ChordExplorerItem> items;
  final List<FingeringRef> selected;
  final ValueChanged<FingeringRef> onToggle;
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
              fingering: FingeringRef(sectionId, index),
              selected: selected,
              onToggle: onToggle,
            ),
            if (index != items.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ExplorerItemCard extends StatelessWidget {
  const _ExplorerItemCard({
    required this.item,
    required this.fingering,
    required this.selected,
    required this.onToggle,
    this.titleOverride,
  });

  final ChordExplorerItem item;
  final FingeringRef fingering;
  final List<FingeringRef> selected;
  final ValueChanged<FingeringRef> onToggle;
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
            _CompareCheckbox(
              fingering: fingering,
              selected: selected,
              onToggle: onToggle,
            ),
          ],
        ),
      );
}

class _CompareCheckbox extends StatelessWidget {
  const _CompareCheckbox({
    required this.fingering,
    required this.selected,
    required this.onToggle,
  });

  final FingeringRef fingering;
  final List<FingeringRef> selected;
  final ValueChanged<FingeringRef> onToggle;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected.contains(fingering);
    final enabled = isSelected || selected.length < maxCompareSelection;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          key: Key('compare-${fingering.key}'),
          value: isSelected,
          activeColor: AppColors.chords,
          onChanged: enabled ? (_) => onToggle(fingering) : null,
        ),
        Text(
          AppStrings.compareCheckbox,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: enabled ? null : AppColors.textSecondary,
              ),
        ),
      ],
    );
    return enabled
        ? row
        : Tooltip(message: AppStrings.compareMaxReached, child: row);
  }
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
