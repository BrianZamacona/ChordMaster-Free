import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/chord_diagram.dart';
import '../../domain/voicing/barre_detection.dart';
import '../../domain/voicing/fingering_metrics.dart';
import '../../models/chord.dart';
import 'chord_viewmodel.dart';
import 'fingering_selection.dart';

/// Compara 2–3 digitaciones de un acorde elegidas en el explorador (`sel=`).
class ChordCompareScreen extends ConsumerWidget {
  const ChordCompareScreen({super.key, required this.chordId, this.selection});

  final String chordId;

  /// Valor crudo de `sel=`, p. ej. `caged:0,voicings:2`.
  final String? selection;

  static const _wideBreakpoint = 700.0;
  static const _maxWidth = 900.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chordViewModelProvider);
    final appBar = AppBar(
      title: const Text(AppStrings.compareTitle),
      backgroundColor: AppColors.chords,
      foregroundColor: Colors.white,
    );

    if (state.isLoading) {
      return Scaffold(
        appBar: appBar,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final chord = ref
        .read(chordViewModelProvider.notifier)
        .findByName(Uri.decodeComponent(chordId));
    final refs = chord == null
        ? const <FingeringRef>[]
        : parseFingeringSelection(selection, chord);
    if (chord == null || refs.length < 2) {
      return Scaffold(appBar: appBar, body: const _EmptyCompare());
    }

    final metrics = [
      for (final r in refs)
        () {
          final item = sectionItems(chord, r.section)[r.index];
          return analyzeFingering(
            jsonFrets: item.fretPositions,
            jsonFingers: item.fingerPositions,
            root: chord.root,
            intervals: chord.intervals,
          );
        }(),
    ];
    final best = _BestByMetric(metrics);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${chord.displayName ?? chord.name} • ${AppStrings.compareTitle}',
        ),
        backgroundColor: AppColors.chords,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _wideBreakpoint;
          final columns = [
            for (var i = 0; i < refs.length; i++)
              _CompareColumn(
                chord: chord,
                fingering: refs[i],
                metrics: metrics[i],
                column: i,
                best: best,
              ),
          ];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < columns.length; i++) ...[
                            if (i > 0) const SizedBox(width: 12),
                            Expanded(child: columns[i]),
                          ],
                        ],
                      )
                    else
                      for (var i = 0; i < columns.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        columns[i],
                      ],
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.compareCostNote,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Columnas con el mejor (menor) valor por métrica, vía [bestIndices].
class _BestByMetric {
  _BestByMetric(List<FingeringMetrics> m)
      : cost = bestIndices([for (final x in m) x.ergonomicCost]),
        fingers = bestIndices([for (final x in m) x.fingers]),
        span = bestIndices([for (final x in m) x.fretSpan]),
        muted = bestIndices([for (final x in m) x.mutedStrings]);

  final Set<int> cost;
  final Set<int> fingers;
  final Set<int> span;
  final Set<int> muted;
}

class _EmptyCompare extends StatelessWidget {
  const _EmptyCompare();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.compare_arrows,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.compareEmpty,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                key: const Key('compare-back'),
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text(AppStrings.compareBack),
              ),
            ],
          ),
        ),
      );
}

class _CompareColumn extends StatelessWidget {
  const _CompareColumn({
    required this.chord,
    required this.fingering,
    required this.metrics,
    required this.column,
    required this.best,
  });

  final Chord chord;
  final FingeringRef fingering;
  final FingeringMetrics metrics;
  final int column;
  final _BestByMetric best;

  String _barreText() {
    final barre = metrics.barre;
    if (barre == null) return AppStrings.barreNone;
    final kind = barreKind(barre) == BarreKind.grande ? 'grande' : 'mini';
    return '$kind ${AppStrings.fretWord} ${barre.fret}';
  }

  @override
  Widget build(BuildContext context) {
    final item = sectionItems(chord, fingering.section)[fingering.index];
    final m = metrics;
    final notes = [
      for (var i = 0; i < m.toneNotes.length; i++)
        '${m.toneNotes[i]} (${m.toneLabels[i]})',
    ].join(' · ');
    final cost = m.ergonomicCost;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fingeringTitle(chord, fingering),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              [
                sectionTitle(fingering.section),
                if (item.shape != null) '${AppStrings.shapeLabel}: ${item.shape}',
              ].join(' • '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
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
            const SizedBox(height: 8),
            _MetricRow(
              id: 'cost',
              column: column,
              label: AppStrings.metricCost,
              value: cost == null ? '∞' : cost.toStringAsFixed(2),
              isBest: best.cost.contains(column),
            ),
            _MetricRow(
              id: 'fingers',
              column: column,
              label: AppStrings.metricFingers,
              value: '${m.fingers}',
              isBest: best.fingers.contains(column),
            ),
            _MetricRow(
              id: 'barre',
              column: column,
              label: AppStrings.metricBarre,
              value: _barreText(),
            ),
            _MetricRow(
              id: 'position',
              column: column,
              label: AppStrings.metricPosition,
              value: m.lowestFret == 0
                  ? AppStrings.openPosition
                  : '${AppStrings.fretWord} ${m.lowestFret}',
            ),
            _MetricRow(
              id: 'span',
              column: column,
              label: AppStrings.metricSpan,
              value: '${m.fretSpan} ${AppStrings.fretsWord}',
              isBest: best.span.contains(column),
            ),
            _MetricRow(
              id: 'muted',
              column: column,
              label: AppStrings.metricMuted,
              value: '${m.mutedStrings}',
              isBest: best.muted.contains(column),
            ),
            _MetricRow(
              id: 'bass',
              column: column,
              label: AppStrings.metricBass,
              value: m.bassNote,
            ),
            _MetricRow(
              id: 'inversion',
              column: column,
              label: AppStrings.metricInversion,
              value: m.inversion,
            ),
            _MetricRow(
              id: 'notes',
              column: column,
              label: AppStrings.metricNotes,
              value: notes,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.id,
    required this.column,
    required this.label,
    required this.value,
    this.isBest = false,
  });

  final String id;
  final int column;
  final String label;
  final String value;

  /// Se marca con ícono y negrita, nunca solo con color.
  final bool isBest;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Row(
              children: [
                if (isBest) ...[
                  Icon(
                    Icons.star,
                    key: Key('best-$id-$column'),
                    size: 14,
                    color: AppColors.chords,
                    semanticLabel: AppStrings.compareBest,
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    value,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: isBest ? FontWeight.bold : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
