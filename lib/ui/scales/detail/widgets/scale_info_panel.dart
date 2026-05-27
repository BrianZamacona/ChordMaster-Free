import 'package:flutter/material.dart';

class ScaleInfoPanel extends StatelessWidget {
  const ScaleInfoPanel({
    super.key,
    required this.scaleName,
    required this.category,
    required this.rootName,
    required this.notes,
    required this.rangeLabel,
  });

  final String scaleName;
  final String category;
  final String rootName;
  final List<String> notes;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$rootName $scaleName', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(category, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: notes.map((n) => _NotePill(note: n)).toList(growable: false),
            ),
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.straighten, label: 'Rango', value: rangeLabel),
          ],
        ),
      ),
    );
  }
}

class _NotePill extends StatelessWidget {
  const _NotePill({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(note, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(width: 6),
        Expanded(child: Text(value, style: Theme.of(context).textTheme.labelSmall)),
      ],
    );
  }
}
