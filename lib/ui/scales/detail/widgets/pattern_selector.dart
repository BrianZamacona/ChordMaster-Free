import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/scale_names.dart';
import '../../../../core/widgets/selector_pill.dart';
import '../../../../data/repository/scale_repository.dart';
import '../../../../domain/fingering_systems/fingering_systems_registry.dart';
import '../../../theme.dart';

/// Nombre visible del sistema de una posición.
String patternSystemName(ResolvedPattern pattern) =>
    FingeringSystemsRegistry.theoryFor(pattern.systemId)?.name.text ??
    pattern.systemName;

/// Botón "Digitación": abre la lista de posiciones y, con una elegida, muestra
/// su nombre y una ✕ que vuelve a todo el mástil.
class PatternSelectorPill extends StatelessWidget {
  const PatternSelectorPill({
    super.key,
    required this.patterns,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<ResolvedPattern> patterns;
  final int? selectedIndex;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final index = selectedIndex;
    return SelectorPill(
      label: AppStrings.scaleFingering,
      value: index == null
          ? null
          : positionDisplayName(patterns[index].positionName),
      onOpen: () => _showSheet(context),
      onClear: () => onSelected(null),
    );
  }

  /// Índices de [patterns] por sistema, en el orden de los sistemas.
  Map<String, List<int>> get _bySystem {
    final groups = <String, List<int>>{};
    for (final (i, p) in patterns.indexed) {
      (groups[p.systemId] ??= []).add(i);
    }
    int rank(String id) {
      final i = FingeringSystemsRegistry.displayOrder.indexOf(id);
      return i < 0 ? FingeringSystemsRegistry.displayOrder.length : i;
    }

    final ordered = groups.keys.toList()
      ..sort((a, b) => rank(a).compareTo(rank(b)));
    return {for (final id in ordered) id: groups[id]!};
  }

  void _showSheet(BuildContext context) => showSelectorSheet(
    context,
    title: AppStrings.scaleFingeringTitle,
    builder: (sheet) {
      void pick(int? index) {
        onSelected(index);
        Navigator.of(sheet).pop();
      }

      final p = sheet.palette;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PatternRow(
            key: const Key('pattern-whole-neck'),
            title: AppStrings.scaleWholeNeck,
            selected: selectedIndex == null,
            onTap: () => pick(null),
          ),
          for (final MapEntry(key: _, value: indices) in _bySystem.entries) ...[
            const SizedBox(height: 12),
            Text(
              patternSystemName(patterns[indices.first]),
              style: Theme.of(
                sheet,
              ).textTheme.titleSmall?.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: 4),
            for (final i in indices)
              _PatternRow(
                key: Key('pattern-$i'),
                title: positionDisplayName(patterns[i].positionName),
                subtitle: AppStrings.scaleFretRange(
                  patterns[i].startingFret,
                  patterns[i].endFret,
                ),
                selected: i == selectedIndex,
                onTap: () => pick(i),
              ),
          ],
        ],
      );
    },
  );
}

class _PatternRow extends StatelessWidget {
  const _PatternRow({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Card(
      color: selected ? p.accent.withValues(alpha: 0.18) : null,
      child: ListTile(
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: selected ? Icon(Icons.check, color: p.accent) : null,
        selected: selected,
        onTap: onTap,
      ),
    );
  }
}
