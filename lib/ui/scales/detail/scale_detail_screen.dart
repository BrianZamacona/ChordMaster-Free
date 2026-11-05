import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/scale_names.dart';
import '../../../core/widgets/fingering_theory_card.dart';
import '../../../core/widgets/interval_legend.dart';
import '../../../core/widgets/selector_pill.dart';
import '../../../data/models/scale_definition.dart';
import '../../../domain/fingering_systems/fingering_systems_registry.dart';
import '../../../domain/theory/intervals.dart';
import '../../../domain/theory/notes.dart';
import '../../../ui/widgets/fretboard_diagram.dart';
import '../../theme.dart';
import 'scale_detail_notifier.dart';
import 'scale_fretboard_fullscreen.dart';
import 'widgets/pattern_selector.dart';
import 'widgets/scale_info_panel.dart';
import 'widgets/scale_theory_cards.dart';

/// Detalle de una escala: tónica y sistema arriba, posiciones completas
/// (nunca recortadas) y, bajo el diapasón, qué es el sistema y las notas.
class ScaleDetailScreen extends ConsumerWidget {
  const ScaleDetailScreen({super.key, required this.scale, this.initialRoot = 0});

  final ScaleDefinition scale;

  /// Tónica con la que abre (semitono, C = 0); p. ej. desde un acorde.
  final int initialRoot;

  String get _scaleName =>
      scaleDisplayName(scale.id, scale.intervals, fallback: scale.name);

  String _systemName(String id) =>
      FingeringSystemsRegistry.theoryFor(id)?.name.text ??
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
    final args = (scale: scale, root: initialRoot);
    final state = ref.watch(scaleDetailProvider(args));
    final notifier = ref.read(scaleDetailProvider(args).notifier);
    final pattern = state.currentPattern;

    return Scaffold(
      appBar: AppBar(title: Text('${state.rootName} $_scaleName')),
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
                      if (note != null) notifier.changeRoot(noteIndex(note));
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
                PatternSelectorPill(
                  key: const Key('scale-pattern'),
                  patterns: state.visiblePatterns,
                  selectedIndex: state.hasSelectedPattern
                      ? state.selectedPatternIndex
                      : null,
                  onSelected: notifier.selectPattern,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (pattern != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FretboardDiagram(pattern: pattern),
            ),
            _PatternContext(
              state: state,
              notifier: notifier,
              onExpand: () => openScaleFretboardFullscreen(context, args),
            ),
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
                title: Text(AppStrings.scaleHowItWorks(_systemName(pattern.systemId))),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [FingeringTheoryCard(systemId: pattern.systemId)],
              ),
            ),
          ] else if (state.isLoading)
            const _DiagramPlaceholder()
          else
            _DiagramPlaceholder(message: AppStrings.scaleNoPositions),
          ScaleInfoPanel(
            scaleName: _scaleName,
            category: scaleCategoryName(scale.category),
            rootName: state.rootName,
            notes: state.scaleNoteNames,
            degrees: scaleDegreeLabels(scale.intervals),
          ),
          ScaleWhyCard(
            intervals: scale.intervals,
            rootSemitone: noteIndex(state.rootName),
          ),
          ScaleHarmonyCard(
            intervals: scale.intervals,
            rootSemitone: noteIndex(state.rootName),
          ),
          ScaleOctavesCard(rootSemitone: noteIndex(state.rootName)),
          ScaleImproviseCard(
            scaleId: scale.id,
            intervals: scale.intervals,
            rootName: state.rootName,
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
                      FingeringSystemsRegistry.theoryFor(s.id)?.shortExplanation.text ?? '',
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
                  child: Text(AppStrings.scaleAllSystems),
                ),
              ),
            ],
          );
        },
      );
}

/// Bajo el diapasón: qué posición muestra, ‹ › si hay una elegida y, en la
/// esquina derecha, el botón de ampliar (fuera del lienzo, para no tapar notas).
class _PatternContext extends StatelessWidget {
  const _PatternContext({
    required this.state,
    required this.notifier,
    required this.onExpand,
  });

  final ScaleDetailState state;
  final ScaleDetailNotifier notifier;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final pattern = state.currentPattern!;
    final name = positionDisplayName(pattern.positionName);
    final style = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: context.palette.textSecondary);
    final expand = IconButton(
      key: const Key('scale-expand'),
      icon: const Icon(Icons.fullscreen),
      tooltip: AppStrings.scaleExpandBoard,
      onPressed: onExpand,
    );
    if (!state.hasSelectedPattern) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.scalePreviewHint(name),
                key: const Key('scale-pattern-context'),
                style: style,
              ),
            ),
            expand,
          ],
        ),
      );
    }
    final index = state.selectedPatternIndex!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
      child: Row(
        children: [
          IconButton(
            key: const Key('scale-pattern-previous'),
            icon: const Icon(Icons.chevron_left),
            tooltip: AppStrings.scalePreviousPattern,
            onPressed: index > 0
                ? () => notifier.selectPattern(index - 1)
                : null,
          ),
          Expanded(
            child: Text(
              AppStrings.scalePatternContext(
                name,
                patternSystemName(pattern),
                pattern.startingFret,
                pattern.endFret,
              ),
              key: const Key('scale-pattern-context'),
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          IconButton(
            key: const Key('scale-pattern-next'),
            icon: const Icon(Icons.chevron_right),
            tooltip: AppStrings.scaleNextPattern,
            onPressed: index < state.visiblePatterns.length - 1
                ? () => notifier.selectPattern(index + 1)
                : null,
          ),
          expand,
        ],
      ),
    );
  }
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
