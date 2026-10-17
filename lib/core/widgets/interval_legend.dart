import 'package:flutter/material.dart';

import '../../ui/theme.dart';
import '../constants/app_strings.dart';

/// Leyenda de los colores de intervalo de un diagrama.
///
/// Solo muestra las familias presentes en [labels] (de acordes: `R`, `b3`…;
/// de escalas: `1`, `#5`…), con la misma forma que en el diagrama:
/// la raíz cuadrada, el resto redondas.
class IntervalLegend extends StatelessWidget {
  const IntervalLegend({super.key, required this.labels});

  final Iterable<String> labels;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final present = labels.toSet();
    bool has(Set<String> family) => present.any(family.contains);
    final entries = [
      if (has({'R', '1'})) (AppStrings.legendRoot, p.intervalRoot, true),
      if (has({'b3', '3'})) (AppStrings.legendThird, p.intervalThird, false),
      if (has({'b5', '5', '#5'}))
        (AppStrings.legendFifth, p.intervalFifth, false),
      if (has({'b7', '7'})) (AppStrings.legendSeventh, p.intervalSeventh, false),
      if (has({'b2', '2', '4', 'b6', '6'}))
        (AppStrings.legendTension, p.intervalTension, false),
    ];
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: p.textSecondary,
        );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final (label, color, square) in entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: square ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: square ? BorderRadius.circular(3) : null,
                ),
              ),
              const SizedBox(width: 6),
              Text(label, style: style),
            ],
          ),
      ],
    );
  }
}
