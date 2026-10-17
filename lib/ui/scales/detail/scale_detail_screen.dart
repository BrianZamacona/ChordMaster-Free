import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/fingering_theory_card.dart';
import '../../../data/models/scale_definition.dart';
import '../../../domain/fingering_systems/fingering_systems_registry.dart';
import '../../../ui/widgets/fretboard_diagram.dart';
import 'scale_detail_notifier.dart';
import 'widgets/fret_range_slider.dart';
import 'widgets/pattern_tab_bar.dart';
import 'widgets/root_picker.dart';
import 'widgets/scale_info_panel.dart';

class ScaleDetailScreen extends ConsumerWidget {
  const ScaleDetailScreen({super.key, required this.scale});

  final ScaleDefinition scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scaleDetailProvider(scale));
    final notifier = ref.read(scaleDetailProvider(scale).notifier);

    return Scaffold(
      appBar: AppBar(title: _AppBarTitle(scale: scale, root: state.rootName)),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          RootPicker(selected: state.rootSemitone, onChanged: notifier.changeRoot),
          _StringCountToggle(value: state.stringCount, onChanged: notifier.changeStringCount),
          _SystemFilterRow(
            systems: scale.systems,
            selectedSystemId: state.selectedSystemId,
            onChanged: notifier.changeSystem,
          ),
          if (state.selectedSystemId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: FingeringTheoryCard(systemId: state.selectedSystemId!),
            ),
          FretRangeSlider(
            startFret: state.startFret,
            endFret: state.endFret,
            maxFret: 24,
            onChanged: notifier.changeRange,
          ),
          PatternTabBar(
            patterns: state.visiblePatterns,
            selectedIndex: state.selectedPatternIndex,
            onSelected: notifier.selectPattern,
            isLoading: state.isLoading,
          ),
          const SizedBox(height: 8),
          if (state.currentPattern != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FretboardDiagram(pattern: state.currentPattern!),
            )
          else if (state.isLoading)
            const _DiagramSkeleton()
          else
            const _EmptyDiagram(),
          ScaleInfoPanel(
            scaleName: scale.name,
            category: scale.category,
            rootName: state.rootName,
            notes: state.scaleNoteNames,
            rangeLabel: '${state.startFret} — ${state.endFret}',
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({required this.scale, required this.root});

  final ScaleDefinition scale;
  final String root;

  @override
  Widget build(BuildContext context) => Text('$root ${scale.name}');
}

class _StringCountToggle extends StatelessWidget {
  const _StringCountToggle({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 6, label: Text('6 cuerdas')),
          ButtonSegment(value: 7, label: Text('7 cuerdas')),
        ],
        selected: {value},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
}

class _SystemFilterRow extends StatelessWidget {
  const _SystemFilterRow({
    required this.systems,
    required this.selectedSystemId,
    required this.onChanged,
  });

  final List<FingeringSystem> systems;
  final String? selectedSystemId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final ordered = [...systems]..sort((a, b) {
        int rank(String id) {
          final i = FingeringSystemsRegistry.displayOrder.indexOf(id);
          return i < 0 ? FingeringSystemsRegistry.displayOrder.length : i;
        }

        return rank(a.id).compareTo(rank(b.id));
      });
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _SystemChip(label: 'Todos', selected: selectedSystemId == null, onTap: () => onChanged(null)),
          ...ordered.map(
            (s) => _SystemChip(
              label: FingeringSystemsRegistry.theoryFor(s.id)?.name ?? s.name,
              selected: selectedSystemId == s.id,
              onTap: () => onChanged(s.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemChip extends StatelessWidget {
  const _SystemChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: cs.primaryContainer,
      ),
    );
  }
}

class _DiagramSkeleton extends StatelessWidget {
  const _DiagramSkeleton();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 180,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
      );
}

class _EmptyDiagram extends StatelessWidget {
  const _EmptyDiagram();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 180,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Text('Sin patrón para este rango'),
      );
}
