import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/scale_names.dart';
import '../../data/models/scale_definition.dart';
import '../../data/repository/scale_repository.dart';
import '../../domain/theory/scale_insights.dart';

/// Escalas por categoría, los modos de la mayor y el acceso a double stops.
class ScalesScreen extends ConsumerWidget {
  const ScalesScreen({super.key});

  static const _categories = ['Diatónica', 'Pentatónica', 'Simétrica', 'Exótica'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scalesAsync = ref.watch(allScalesProvider);
    final modes = ref.watch(allModesProvider).value ?? const <ScaleDefinition>[];

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.moduleScales)),
      body: scalesAsync.when(
        data: (scales) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.straighten),
                title: Text(AppStrings.dsTitle),
                subtitle: Text(AppStrings.dsSub),
                onTap: () => context.go('/learn/scales/double-stops'),
              ),
            ),
            const SizedBox(height: 8),
            for (final c in _categories)
              _Section(
                title: scaleCategoryName(c),
                scales: [for (final s in scales) if (s.category == c) s],
              ),
            _Section(title: AppStrings.scaleModes, scales: modes),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${AppStrings.errorGeneric}\n$e')),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.scales});

  final String title;
  final List<ScaleDefinition> scales;

  @override
  Widget build(BuildContext context) {
    if (scales.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...scales.map((scale) => Card(
              child: ListTile(
                key: Key('scale-${scale.id}'),
                title: Text(scaleDisplayName(scale.id, scale.intervals, fallback: scale.name)),
                subtitle: Text(
                  '${scale.intervals.length} ${AppStrings.scaleNotesCount} · '
                  '${stepPatternLabel(scale.intervals)}',
                ),
                onTap: () => context.go('/learn/scales/${scale.id}', extra: scale),
              ),
            )),
        const SizedBox(height: 12),
      ],
    );
  }
}
