import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/fingering_theory_card.dart';
import '../../../core/widgets/interval_legend.dart';
import '../../../core/widgets/selector_pill.dart';
import '../../../data/models/scale_definition.dart';
import '../../../domain/fingering_systems/fingering_systems_registry.dart';
import '../../../ui/widgets/fretboard_diagram.dart';
import '../../theme.dart';
import 'scale_detail_notifier.dart';
import 'widgets/pattern_tab_bar.dart';
import 'widgets/scale_info_panel.dart';

const _noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

/// Detalle de una escala: tónica y sistema arriba, posiciones completas
/// (nunca recortadas) y, bajo el diapasón, qué es el sistema y las notas.
class ScaleDetailScreen extends ConsumerWidget {
  const ScaleDetailScreen({super.key, required this.scale});

  final ScaleDefinition scale;

  String _systemName(String id) =>
      FingeringSystemsRegistry.theoryFor(id)?.name ??
      scale.systems.firstWhere((s) => s.id == id, orElse: () => FingeringSystem(id: id, name: id)).name;

  List<FingeringSystem> get _orderedSystems => [...scale.systems]..sort((a, b) {
      int rank(String id) {
        final i = FingeringSystemsRegistry.displayOrder.indexOf(id);
        return i < 0 ? FingeringSystemsRegistry.displayOrder.length : i;
      }

      return rank(a.id).compareTo(rank(b.id));
    });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scaleDetailProvider(scale));
    final notifier = ref.read(scaleDetailProvider(scale).notifier);
    final pattern = state.currentPattern;

    return Scaffold(
      appBar: AppBar(title: Text('${state.rootName} ${scale.name}')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SelectorPill(
                  key: const Key('scale-root'),
                  label: AppStrings.scaleTonic,
                  value: state.rootName,
                  onOpen: () => showNotePicker(
                    context,
                    title: AppStrings.scaleTonic,
                    selected: state.rootName,
                    onPicked: (note) {
                      if (note != null) notifier.changeRoot(_noteNames.indexOf(note));
                    },
                  ),
                ),
                SelectorPill(
                  key: const Key('scale-system'),
                  label: AppStrings.scaleSystem,
                  value: state.selectedSystemId == null
                      ? null
                      : _systemName(state.selectedSystemId!),
                  onOpen: () => _showSystemSheet(context, state.selectedSystemId, notifier.changeSystem),
                  onClear: () => notifier.changeSystem(null),
                ),
              ],
            ),
          ),
          PatternTabBar(
            patterns: state.visiblePatterns,
            selectedIndex: state.selectedPatternIndex,
            onSelected: notifier.selectPattern,
            isLoading: state.isLoading,
          ),
          const SizedBox(height: 12),
          if (pattern != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FretboardDiagram(pattern: pattern),
            ),
            const SizedBox(height: 8),
            IntervalLegend(
              labels: [
                for (final c in pattern.coordinates)
                  if (c.isRoot) '1' else c.interval,
              ],
            ),
            const SizedBox(height: 8),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                key: PageStorageKey('theory-${pattern.systemId}'),
                shape: const Border(),
                leading: Icon(Icons.lightbulb_outline, color: context.palette.accent),
                title: Text('${AppStrings.scaleHowItWorks} ${_systemName(pattern.systemId)}'),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [FingeringTheoryCard(systemId: pattern.systemId)],
              ),
            ),
          ] else if (state.isLoading)
            const _DiagramPlaceholder()
          else
            const _DiagramPlaceholder(message: AppStrings.scaleNoPositions),
          ScaleInfoPanel(
            scaleName: scale.name,
            category: scale.category,
            rootName: state.rootName,
            notes: state.scaleNoteNames,
            degrees: [for (final i in scale.intervals) intervalName(i)],
          ),
        ],
      ),
    );
  }

  void _showSystemSheet(
    BuildContext context,
    String? selected,
    ValueChanged<String?> onChanged,
  ) =>
      showSelectorSheet(
        context,
        title: AppStrings.scaleSystemTitle,
        builder: (sheet) {
          void pick(String? id) {
            onChanged(id);
            Navigator.of(sheet).pop();
          }

          final p = sheet.palette;
          return Column(
            children: [
              for (final s in _orderedSystems)
                Card(
                  color: s.id == selected ? p.accent.withValues(alpha: 0.18) : null,
                  child: ListTile(
                    title: Text(_systemName(s.id)),
                    subtitle: Text(
                      FingeringSystemsRegistry.theoryFor(s.id)?.shortExplanation ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: s.id == selected ? Icon(Icons.check, color: p.accent) : null,
                    onTap: () => pick(s.id),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => pick(null),
                  child: const Text(AppStrings.scaleAllSystems),
                ),
              ),
            ],
          );
        },
      );
}

class _DiagramPlaceholder extends StatelessWidget {
  const _DiagramPlaceholder({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 180,
        decoration: BoxDecoration(
          color: context.palette.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: message == null ? null : Text(message!),
      );
}
