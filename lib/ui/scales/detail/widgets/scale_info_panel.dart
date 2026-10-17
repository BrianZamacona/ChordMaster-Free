import 'package:flutter/material.dart';

import '../../../theme.dart';

/// Notas de la escala con su grado (1, b3, 5…), coloreadas como en el
/// diapasón para que se lea qué nota es cada punto.
class ScaleInfoPanel extends StatelessWidget {
  const ScaleInfoPanel({
    super.key,
    required this.scaleName,
    required this.category,
    required this.rootName,
    required this.notes,
    required this.degrees,
  });

  final String scaleName;
  final String category;
  final String rootName;
  final List<String> notes;

  /// Paralelo a [notes]: etiqueta de intervalo de cada nota.
  final List<String> degrees;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$rootName $scaleName', style: theme.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(
              category,
              style: theme.textTheme.bodySmall?.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < notes.length; i++)
                  _NoteDegree(note: notes[i], degree: degrees[i]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteDegree extends StatelessWidget {
  const _NoteDegree({required this.note, required this.degree});

  final String note;
  final String degree;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = p.intervalColor(degree);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(note, style: musicMono(fontSize: 14, fontWeight: FontWeight.w600, color: p.textPrimary)),
          Text(degree, style: musicMono(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}
