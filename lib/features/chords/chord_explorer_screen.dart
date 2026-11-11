import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/chord_texts.dart';
import '../../core/widgets/chord_diagram.dart';
import '../../core/widgets/fingering_theory_card.dart';
import '../../domain/voicing/triads_by_shape.dart';
import '../../models/chord.dart';
import '../../ui/palette.dart';
import '../../ui/section_routes.dart';
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
    context.go(context.sectionPath('chords/$encoded/compare?sel=$sel'));
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
          title: Text(AppStrings.chordExplorer),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final chord = vm.findByName(decodedName);
    if (chord == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.chordExplorer),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ExplorerSection(
              title:
                  AppStrings.cagedPositions,
              header: const FingeringTheoryCard(systemId: 'caged'),
              labelSharedShapes: true,
              sectionId: 'caged',
              items: chord.cagedPositions,
              selected: _selected,
              onToggle: _toggle,
              root: chord.root,
            ),
            const SizedBox(height: 16),
            _ExplorerSection(
              title: AppStrings.curatedVoicings,
              sectionId: 'voicings',
              items: chord.voicings,
              selected: _selected,
              onToggle: _toggle,
              root: chord.root,
            ),
            const SizedBox(height: 16),
            _TriadsSection(
              chord: chord,
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
              root: chord.root,
            ),
            if (!chord.hasExplorerData)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  AppStrings.chordExplorerEmpty,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.palette.textSecondary,
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
                    backgroundColor: context.palette.accent,
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
    required this.root,
    this.header,
    this.labelSharedShapes = false,
  });

  final String root;

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
                color: context.palette.textSecondary,
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
              root: root,
            ),
            if (index != items.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

/// Las tríadas, por grupo de cuerdas (como vienen) o por la forma CAGED en la
/// que caen (`triadsByShape`).
class _TriadsSection extends StatefulWidget {
  const _TriadsSection({required this.chord, required this.selected, required this.onToggle});

  final Chord chord;
  final List<FingeringRef> selected;
  final ValueChanged<FingeringRef> onToggle;

  @override
  State<_TriadsSection> createState() => _TriadsSectionState();
}

class _TriadsSectionState extends State<_TriadsSection> {
  var _byShape = false;

  @override
  Widget build(BuildContext context) {
    final chord = widget.chord;
    final shapes = [
      for (final p in chord.cagedPositions)
        if (p.shape != null) (shape: p.shape!, frets: p.fretPositions),
    ];
    final canGroup = shapes.isNotEmpty && chord.triadInversions.isNotEmpty;
    final byStrings = _ExplorerSection(
      title: AppStrings.triadInversions,
      sectionId: 'triadInversions',
      items: chord.triadInversions,
      selected: widget.selected,
      onToggle: widget.onToggle,
      root: chord.root,
      header: canGroup ? _toggle() : null,
    );
    if (!canGroup || !_byShape) return byStrings;

    final triads = [for (final t in chord.triadInversions) t.fretPositions];
    final groups = triadsByShape(shapes, triads);
    final between = triadsBetweenShapes(shapes, triads);
    final text = Theme.of(context).textTheme;
    Widget card(ChordExplorerItem item, List<int> frets) => _ExplorerItemCard(
      item: ChordExplorerItem(
        title: item.title,
        fretPositions: frets,
        fingerPositions: item.fingerPositions,
        description: item.description,
      ),
      root: chord.root,
    );
    return _SectionCard(
      title: AppStrings.triadInversions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _toggle(),
          const SizedBox(height: 8),
          Text(AppStrings.triadsByShapeHint, style: text.bodySmall?.copyWith(color: context.palette.textSecondary)),
          for (final g in groups) ...[
            const SizedBox(height: 12),
            Text(
              AppStrings.triadsInShape(chordDataText(g.window.shape), g.window.lowest, g.window.highest),
              key: Key('triads-shape-${g.window.shape}'),
              style: text.titleSmall,
            ),
            const SizedBox(height: 6),
            if (g.triads.isEmpty)
              Text(AppStrings.triadsNoneInShape, style: text.bodySmall)
            else
              for (final t in g.triads) ...[
                card(chord.triadInversions[t.index], t.frets),
                const SizedBox(height: 8),
              ],
          ],
          if (between.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(AppStrings.triadsBetweenShapes, key: const Key('triads-between'), style: text.titleSmall),
            const SizedBox(height: 6),
            for (final i in between) ...[
              card(chord.triadInversions[i], chord.triadInversions[i].fretPositions),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  Widget _toggle() => SegmentedButton<bool>(
    key: const Key('triads-view'),
    showSelectedIcon: false,
    segments: [
      ButtonSegment(value: false, label: Text(AppStrings.triadsByStrings)),
      ButtonSegment(value: true, label: Text(AppStrings.triadsByShape)),
    ],
    selected: {_byShape},
    onSelectionChanged: (v) => setState(() => _byShape = v.first),
  );
}

class _ExplorerItemCard extends StatelessWidget {
  const _ExplorerItemCard({
    required this.item,
    required this.root,
    this.fingering,
    this.selected = const [],
    this.onToggle,
    this.titleOverride,
  });

  final String root;

  final ChordExplorerItem item;

  /// Sin ella, la tarjeta no se puede comparar (las tríadas corridas a su
  /// forma no son las de chords.json).
  final FingeringRef? fingering;
  final List<FingeringRef> selected;
  final ValueChanged<FingeringRef>? onToggle;
  final String? titleOverride;

  String _buildSubtitle() {
    final parts = <String>[];
    if (item.shape != null) {
      parts.add('${AppStrings.shapeLabel}: ${chordDataText(item.shape!)}');
    }
    if (item.description != null) {
      parts.add(chordDataText(item.description!));
    }
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.palette.accent.withValues(alpha: 0.31)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titleOverride ?? chordDataText(item.title),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (item.shape != null || item.description != null) ...[
              const SizedBox(height: 2),
              Text(
                _buildSubtitle(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.palette.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            Center(
              child: ChordDiagramWidget(
                chordName: item.title,
                fretPositions: item.fretPositions,
                fingerPositions: item.fingerPositions,
                root: root,
                toneRow: DiagramToneRow.intervalsAndNotes,
                baseFret: item.baseFret,
                showChordName: false,
                size: 150,
              ),
            ),
            if (fingering case final f?)
              _CompareCheckbox(
                fingering: f,
                selected: selected,
                onToggle: onToggle!,
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
          activeColor: context.palette.accent,
          onChanged: enabled ? (_) => onToggle(fingering) : null,
        ),
        Text(
          AppStrings.compareCheckbox,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: enabled ? null : context.palette.textSecondary,
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
                      color: context.palette.accent,
                    ),
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      );
}
