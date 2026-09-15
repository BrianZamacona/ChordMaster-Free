import 'package:flutter/material.dart';

import '../../../../data/repository/scale_repository.dart';

class PatternTabBar extends StatelessWidget {
  const PatternTabBar({
    super.key,
    required this.patterns,
    required this.selectedIndex,
    required this.onSelected,
    required this.isLoading,
  });

  final List<ResolvedPattern> patterns;
  final int selectedIndex;
  final void Function(int) onSelected;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (isLoading) {
      return const SizedBox(height: 40, child: Center(child: LinearProgressIndicator()));
    }

    if (patterns.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 15, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sin patrones en este rango — desliza para ampliar',
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Text(
            '${patterns.length} patrón${patterns.length > 1 ? "es" : ""} disponible${patterns.length > 1 ? "s" : ""}',
            style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: patterns.length,
            itemBuilder: (_, i) {
              final p = patterns[i];
              final active = i == selectedIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: active ? cs.secondaryContainer : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: active
                        ? Border.all(color: cs.secondary, width: 1.5)
                        : Border.all(color: cs.outlineVariant, width: 0.5),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => onSelected(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (active) ...[
                            Icon(Icons.graphic_eq_rounded, size: 13, color: cs.onSecondaryContainer),
                            const SizedBox(width: 4),
                          ],
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.positionName,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                  color: active ? cs.onSecondaryContainer : cs.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                p.systemName,
                                style: TextStyle(
                                  fontSize: 8,
                                  color: active
                                      ? cs.onSecondaryContainer.withAlpha(180)
                                      : cs.onSurfaceVariant.withAlpha(150),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
