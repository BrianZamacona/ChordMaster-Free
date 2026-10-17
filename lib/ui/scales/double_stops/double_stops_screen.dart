import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  FretRange get range => upperRange ? const FretRange(13, 24) : const FretRange(0, 12);

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
  }) => DoubleStopsControls(
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
    appBar: AppBar(title: const Text('Double stops diatónicos')),
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Tónica', style: theme.textTheme.titleSmall),
        Wrap(
          spacing: 6,
          children: [
            for (var i = 0; i < 12; i++)
              ChoiceChip(
                label: Text(noteNames[i]),
                selected: c.tonic == i,
                onSelected: (_) => notifier.setTonic(i),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Intervalo', style: theme.textTheme.titleSmall),
        Wrap(
          spacing: 6,
          children: [
            for (final i in DiatonicDoubleStopInterval.values)
              ChoiceChip(
                label: Text(i.label),
                selected: c.interval == i,
                onSelected: (_) => notifier.setInterval(i),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Patrón de cuerdas', style: theme.textTheme.titleSmall),
        Wrap(
          spacing: 6,
          children: [
            for (final p in DoubleStopStringPattern.values)
              ChoiceChip(
                label: Text(p == DoubleStopStringPattern.adjacent ? 'adjacent' : 'skip-one'),
                selected: c.effectivePattern == p,
                onSelected: (_) => notifier.setPattern(p),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Rango de trastes', style: theme.textTheme.titleSmall),
        Wrap(
          spacing: 6,
          children: [
            ChoiceChip(
              label: const Text('0–12'),
              selected: !c.upperRange,
              onSelected: (_) => notifier.setUpperRange(upper: false),
            ),
            ChoiceChip(
              label: const Text('13–24'),
              selected: c.upperRange,
              onSelected: (_) => notifier.setUpperRange(upper: true),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final group in groups) _GroupSection(group: group, range: c.range),
      ],
    );
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({required this.group, required this.range});

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
              DoubleStopFretboard(pairs: group.pairs, range: range),
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
