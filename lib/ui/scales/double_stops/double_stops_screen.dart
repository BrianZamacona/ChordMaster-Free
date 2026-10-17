import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/interval_legend.dart';
import '../../../core/widgets/selector_pill.dart';
import '../../../domain/theory/double_stops.dart';
import 'double_stops_fretboard.dart';

class DoubleStopsControls {
  const DoubleStopsControls({
    this.tonic = 0,
    this.interval = DiatonicDoubleStopInterval.third,
    this.pattern,
    this.upperRange = false,
  });

  final int tonic;
  final DiatonicDoubleStopInterval interval;

  /// `null` = patrón por defecto del intervalo.
  final DoubleStopStringPattern? pattern;
  final bool upperRange;

  FretRange get range =>
      upperRange ? const FretRange(13, 24) : const FretRange(0, 12);

  DoubleStopStringPattern get effectivePattern =>
      pattern ??
      (interval.index >= DiatonicDoubleStopInterval.sixth.index
          ? DoubleStopStringPattern.skipOne
          : DoubleStopStringPattern.adjacent);

  DoubleStopsControls copyWith({
    int? tonic,
    DiatonicDoubleStopInterval? interval,
    DoubleStopStringPattern? pattern,
    bool clearPattern = false,
    bool? upperRange,
  }) =>
      DoubleStopsControls(
        tonic: tonic ?? this.tonic,
        interval: interval ?? this.interval,
        pattern: clearPattern ? null : pattern ?? this.pattern,
        upperRange: upperRange ?? this.upperRange,
      );
}

class DoubleStopsNotifier extends Notifier<DoubleStopsControls> {
  @override
  DoubleStopsControls build() => const DoubleStopsControls();

  void setTonic(int tonic) => state = state.copyWith(tonic: tonic);
  void setInterval(DiatonicDoubleStopInterval i) =>
      state = state.copyWith(interval: i, clearPattern: true);
  void setPattern(DoubleStopStringPattern p) =>
      state = state.copyWith(pattern: p);
  void setUpperRange({required bool upper}) =>
      state = state.copyWith(upperRange: upper);
}

final doubleStopsControlsProvider =
    NotifierProvider<DoubleStopsNotifier, DoubleStopsControls>(
  DoubleStopsNotifier.new,
);

class DoubleStopsScreen extends ConsumerWidget {
  const DoubleStopsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: Text(AppStrings.dsTitle)),
        body: const DoubleStopsContent(),
      );
}

class DoubleStopsContent extends ConsumerWidget {
  const DoubleStopsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(doubleStopsControlsProvider);
    final notifier = ref.read(doubleStopsControlsProvider.notifier);
    final groups = findDiatonicDoubleStopPairs(
      noteNames[c.tonic],
      c.interval,
      c.range,
      c.effectivePattern,
    );
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SelectorPill(
                key: const Key('ds-tonic'),
                label: AppStrings.scaleTonic,
                value: noteNames[c.tonic],
                onOpen: () => showNotePicker(
                  context,
                  title: AppStrings.scaleTonic,
                  selected: noteNames[c.tonic],
                  onPicked: (note) {
                    if (note != null) notifier.setTonic(noteNames.indexOf(note));
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(AppStrings.dsInterval, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            SegmentedButton<DiatonicDoubleStopInterval>(
              showSelectedIcon: false,
              segments: [
                for (final i in DiatonicDoubleStopInterval.values)
                  ButtonSegment(value: i, label: Text('${i.index + 2}ª')),
              ],
              selected: {c.interval},
              onSelectionChanged: (v) => notifier.setInterval(v.first),
            ),
            const SizedBox(height: 12),
            SegmentedButton<DoubleStopStringPattern>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: DoubleStopStringPattern.adjacent,
                  label: Text(AppStrings.dsAdjacent),
                ),
                ButtonSegment(
                  value: DoubleStopStringPattern.skipOne,
                  label: Text(AppStrings.dsSkipOne),
                ),
              ],
              selected: {c.effectivePattern},
              onSelectionChanged: (v) => notifier.setPattern(v.first),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(AppStrings.dsLowRange)),
                ButtonSegment(value: true, label: Text(AppStrings.dsHighRange)),
              ],
              selected: {c.upperRange},
              onSelectionChanged: (v) => notifier.setUpperRange(upper: v.first),
            ),
            const SizedBox(height: 16),
            for (final group in groups)
              _GroupSection(group: group, range: c.range, tonic: noteNames[c.tonic]),
          ],
        ),
      ),
    );
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({
    required this.group,
    required this.range,
    required this.tonic,
  });

  final String tonic;

  final DoubleStopGroup group;
  final FretRange range;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (companion, base) = group.stringPair;
    final qualityByDegree = <int, String>{
      for (final p in group.pairs)
        if (p.degree != null) p.degree!: p.quality,
    };
    final degrees = qualityByDegree.keys.toList()..sort();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cuerdas ${companion + 1} y ${base + 1} · ${group.pairs.length} parejas',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (group.pairs.isEmpty)
              const Text('Sin parejas en este rango.')
            else ...[
              DoubleStopFretboard(
                pairs: group.pairs,
                range: range,
                tonic: tonic,
              ),
              const SizedBox(height: 4),
              IntervalLegend(
                labels: [
                  for (final pair in group.pairs)
                    for (final mark in [pair.root, pair.interval])
                      degreeInMajorKey(mark.note, tonic),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 12,
                children: [
                  for (final d in degrees)
                    Text(
                      '${degreeNumeral(d)}: ${qualityByDegree[d]}',
                      style: theme.textTheme.labelSmall,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
