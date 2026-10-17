import 'package:flutter/material.dart';

import '../../domain/fingering_systems/fingering_systems_registry.dart';

/// Explanation of a fingering system, read from [FingeringSystemsRegistry].
class FingeringTheoryCard extends StatelessWidget {
  const FingeringTheoryCard({super.key, required this.systemId});

  final String systemId;

  @override
  Widget build(BuildContext context) {
    final theory = FingeringSystemsRegistry.theoryFor(systemId);
    if (theory == null) return const SizedBox.shrink();
    final style = Theme.of(context).textTheme.bodySmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          theory.name,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(theory.shortExplanation, style: style),
        if (theory.shapeOrder.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Orden: ${theory.shapeOrder.join(' - ')}', style: style),
        ],
        const SizedBox(height: 4),
        Text(theory.howShapesConnect, style: style),
      ],
    );
  }
}
