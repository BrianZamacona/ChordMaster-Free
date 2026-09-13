import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

class FretRangeSlider extends StatelessWidget {
  const FretRangeSlider({
    super.key,
    required this.startFret,
    required this.endFret,
    required this.maxFret,
    required this.onChanged,
  });

  final int startFret;
  final int endFret;
  final int maxFret;
  final void Function(int start, int end) onChanged;

  static const _minSpan = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Row(
            children: [
              Icon(Icons.tune, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('Rango del diapasón', style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  'Traste  $startFret — $endFret',
                  key: ValueKey('$startFret-$endFret'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
            trackHeight: 4,
            activeTrackColor: cs.primary,
            inactiveTrackColor: cs.surfaceContainerHighest,
            thumbColor: cs.primary,
            overlayColor: cs.primary.withAlpha(30),
          ),
          child: RangeSlider(
            values: RangeValues(startFret.toDouble(), endFret.toDouble()),
            min: 0,
            max: maxFret.toDouble(),
            divisions: maxFret,
            labels: RangeLabels('$startFret', '$endFret'),
            onChanged: (v) {
              final s = v.start.round();
              final e = v.end.round();
              if (e - s >= _minSpan) onChanged(s, e);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final f in _markers(maxFret))
                Text(
                  '$f',
                  style: TextStyle(
                    fontSize: 9,
                    color: cs.onSurfaceVariant.withAlpha(130),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<int> _markers(int max) {
    final step = (max ~/ 6).clamp(1, max);
    final m = <int>[0];
    for (var i = step; i < max; i += step) m.add(i);
    if (m.last != max) m.add(max);
    return m;
  }
}
