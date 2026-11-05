import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/scale_names.dart';
import '../../../../core/widgets/selector_pill.dart';
import '../../../../data/models/scale_definition.dart';
import '../../../../data/repository/scale_repository.dart';
import '../../../../domain/fingering_systems/fingering_systems_registry.dart';
import '../../../theme.dart';

/// Lugar de un sistema al listarlos.
int _systemRank(String id) {
  final i = FingeringSystemsRegistry.displayOrder.indexOf(id);
  return i < 0 ? FingeringSystemsRegistry.displayOrder.length : i;
}

/// Nombre visible del sistema de una posición.
String patternSystemName(ResolvedPattern pattern) =>
    FingeringSystemsRegistry.theoryFor(pattern.systemId)?.name.text ??
    pattern.systemName;

/// Botón "Sistema": deja solo las posiciones de un sistema de digitación.
class SystemSelectorPill extends StatelessWidget {
  const SystemSelectorPill({
    super.key,
    required this.systems,
    required this.selectedId,
    required this.onChanged,
    this.maxLines,
  });

  final List<FingeringSystem> systems;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final int? maxLines;

  String _name(FingeringSystem system) =>
      FingeringSystemsRegistry.theoryFor(system.id)?.name.text ?? system.name;

  @override
  Widget build(BuildContext context) {
    final selected = selectedId;
    return SelectorPill(
      label: AppStrings.scaleSystem,
      value: selected == null
          ? null
          : _name(
              systems.firstWhere(
                (s) => s.id == selected,
                orElse: () => FingeringSystem(id: selected, name: selected),
              ),
            ),
      onOpen: () => _showSheet(context),
      onClear: () => onChanged(null),
      maxLines: maxLines,
    );
  }

  void _showSheet(BuildContext context) => showSelectorSheet(
    context,
    title: AppStrings.scaleSystemTitle,
    builder: (sheet) {
      void pick(String? id) {
        onChanged(id);
        Navigator.of(sheet).pop();
      }

      final p = sheet.palette;
      final ordered = [...systems]
        ..sort((a, b) => _systemRank(a.id).compareTo(_systemRank(b.id)));
      return Column(
        children: [
          for (final s in ordered)
            Card(
              color: s.id == selectedId ? p.accent.withValues(alpha: 0.18) : null,
              child: ListTile(
                title: Text(_name(s)),
                subtitle: Text(
                  FingeringSystemsRegistry.theoryFor(s.id)?.shortExplanation.text ??
                      '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: s.id == selectedId
                    ? Icon(Icons.check, color: p.accent)
                    : null,
                onTap: () => pick(s.id),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => pick(null),
              child: Text(AppStrings.scaleAllSystems),
            ),
          ),
        ],
      );
    },
  );
}

/// Botón "Digitación": abre la lista de posiciones y, con una elegida, muestra
/// su nombre y una ✕ que vuelve a todo el mástil.
class PatternSelectorPill extends StatelessWidget {
  const PatternSelectorPill({
    super.key,
    required this.patterns,
    required this.selectedIndex,
    required this.onSelected,
    this.maxLines,
  });

  final List<ResolvedPattern> patterns;
  final int? selectedIndex;
  final ValueChanged<int?> onSelected;
  final int? maxLines;

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
      maxLines: maxLines,
    );
  }

  /// Índices de [patterns] por sistema, en el orden de los sistemas y, dentro
  /// de cada uno, como los declara `scales_master.json`.
  Map<String, List<int>> get _bySystem {
    final groups = <String, List<int>>{};
    for (final (i, p) in patterns.indexed) {
      (groups[p.systemId] ??= []).add(i);
    }
    for (final indices in groups.values) {
      indices.sort(
        (a, b) => patterns[a].declaredOrder.compareTo(patterns[b].declaredOrder),
      );
    }
    final ordered = groups.keys.toList()
      ..sort((a, b) => _systemRank(a).compareTo(_systemRank(b)));
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
