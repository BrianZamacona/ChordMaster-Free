import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/chord_metadata.dart';
import '../../core/widgets/selector_pill.dart';
import '../../domain/theory/chord_families.dart';
import '../../ui/theme.dart';

/// Fila de filtros de la biblioteca: Raíz, Tipo y Estilo, cada uno abre una
/// hoja inferior. Un filtro activo se muestra en su botón y se quita con la ✕.
class ChordFilterBar extends StatelessWidget {
  const ChordFilterBar({
    super.key,
    required this.root,
    required this.type,
    required this.tag,
    required this.availableTypes,
    required this.availableTags,
    required this.onRoot,
    required this.onType,
    required this.onTag,
  });

  final String? root;
  final String? type;
  final String? tag;

  /// Tipos presentes en los datos, en el orden de `orderedChordTypes`.
  final List<String> availableTypes;
  final List<String> availableTags;
  final ValueChanged<String?> onRoot;
  final ValueChanged<String?> onType;
  final ValueChanged<String?> onTag;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            SelectorPill(
              key: const Key('filter-root'),
              label: AppStrings.filterRoot,
              value: root,
              onOpen: () => showNotePicker(
                context,
                title: AppStrings.filterRootTitle,
                selected: root,
                onPicked: onRoot,
                noneLabel: AppStrings.filterAllRoots,
              ),
              onClear: () => onRoot(null),
            ),
            const SizedBox(width: 8),
            SelectorPill(
              key: const Key('filter-type'),
              label: AppStrings.filterType,
              value: type == null ? null : chordTypeLabel(type!),
              onOpen: () => _showTypeSheet(context),
              onClear: () => onType(null),
            ),
            const SizedBox(width: 8),
            SelectorPill(
              key: const Key('filter-tag'),
              label: AppStrings.filterStyle,
              value: tag == null ? null : chordTagLabel(tag!),
              onOpen: () => _showTagSheet(context),
              onClear: () => onTag(null),
            ),
          ],
        ),
      );

  void _pick(BuildContext sheetContext, ValueChanged<String?> onPick, String? v) {
    onPick(v);
    Navigator.of(sheetContext).pop();
  }

  void _showTypeSheet(BuildContext context) => showSelectorSheet(
        context,
        title: AppStrings.filterTypeTitle,
        builder: (sheet) {
          final text = Theme.of(sheet).textTheme;
          final p = sheet.palette;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final family in ChordFamily.values)
                if (availableTypes.any((t) => chordFamilyByType[t] == family)) ...[
                  Text(_familyName(family), style: text.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    _familyHint(family),
                    style: text.bodySmall?.copyWith(color: p.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in availableTypes)
                        if (chordFamilyByType[t] == family)
                          ChoiceChip(
                            label: Text(chordTypeLabel(t)),
                            selected: t == type,
                            onSelected: (_) => _pick(sheet, onType, t),
                          ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _pick(sheet, onType, null),
                  child: Text(AppStrings.filterAllTypes),
                ),
              ),
            ],
          );
        },
      );

  void _showTagSheet(BuildContext context) => showSelectorSheet(
        context,
        title: AppStrings.filterStyleTitle,
        builder: (sheet) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in availableTags)
                  ChoiceChip(
                    label: Text(chordTagLabel(t)),
                    selected: t == tag,
                    onSelected: (_) => _pick(sheet, onTag, t),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _pick(sheet, onTag, null),
              child: Text(AppStrings.filterAllStyles),
            ),
          ],
        ),
      );

  static String _familyName(ChordFamily f) => switch (f) {
        ChordFamily.triads => AppStrings.familyTriads,
        ChordFamily.sixthsAndSevenths => AppStrings.familySevenths,
        ChordFamily.extended => AppStrings.familyExtended,
        ChordFamily.altered => AppStrings.familyAltered,
      };

  static String _familyHint(ChordFamily f) => switch (f) {
        ChordFamily.triads => AppStrings.familyTriadsHint,
        ChordFamily.sixthsAndSevenths => AppStrings.familySeventhsHint,
        ChordFamily.extended => AppStrings.familyExtendedHint,
        ChordFamily.altered => AppStrings.familyAlteredHint,
      };
}
