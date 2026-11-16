import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/strumming/strum_pattern.dart';
import '../../ui/theme.dart';

/// Un patrón de arpegio (`arpeggioPatterns`), una celda por corchea: qué cuerda
/// suena (B = el bajo, B2 = el otro bajo, 3, 2 y 1) y el conteo debajo. Mismo
/// aspecto que `StrumPatternView`.
class ArpeggioPatternView extends StatelessWidget {
  const ArpeggioPatternView({super.key, required this.pattern});

  final String pattern;

  static String _label(String token) => switch (token) {
    'B' => 'B',
    'b' => 'B2',
    _ => token,
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final and = AppStrings.lessonStrumAnd;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final (i, token) in pattern.split('').indexed)
              Expanded(
                child: Container(
                  key: Key('arpeggio-cell-$i'),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: p.accent.withValues(alpha: token == 'B' || token == 'b' ? 0.24 : 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _label(token),
                        style: musicMono(fontSize: 16, fontWeight: FontWeight.w600, color: p.accent),
                      ),
                      Text(
                        strumCountAt(pattern, i, and),
                        style: musicMono(fontSize: 12, color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.arpeggioLegend,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: p.textSecondary),
        ),
      ],
    );
  }
}
