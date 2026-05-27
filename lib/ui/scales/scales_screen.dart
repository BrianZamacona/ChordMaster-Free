import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/scale_definition.dart';
import '../../data/repository/scale_repository.dart';

class ScalesScreen extends ConsumerWidget {
  const ScalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scalesAsync = ref.watch(allScalesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Escalas')),
      body: scalesAsync.when(
        data: (scales) {
          final diatonic = scales.where((s) => s.category == 'Diatónica').toList();
          final pentatonic = scales.where((s) => s.category == 'Pentatónica').toList();
          final symmetric = scales.where((s) => s.category == 'Simétrica').toList();
          final exotic = scales.where((s) => s.category == 'Exótica').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section(title: 'Diatónica', scales: diatonic),
              _Section(title: 'Pentatónica', scales: pentatonic),
              _Section(title: 'Simétrica', scales: symmetric),
              _Section(title: 'Exótica', scales: exotic),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
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
                title: Text(scale.name),
                subtitle: Text(scale.id),
                onTap: () => context.go('/scales/${scale.id}', extra: scale),
              ),
            )),
        const SizedBox(height: 12),
      ],
    );
  }
}
