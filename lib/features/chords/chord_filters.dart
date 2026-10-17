import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/chord_metadata.dart';
import '../../core/constants/music_theory.dart';
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
            _FilterButton(
              key: const Key('filter-root'),
              label: AppStrings.filterRoot,
              value: root,
              onOpen: () => _showRootSheet(context),
              onClear: () => onRoot(null),
            ),
            const SizedBox(width: 8),
            _FilterButton(
              key: const Key('filter-type'),
              label: AppStrings.filterType,
              value: type == null ? null : chordTypeLabel(type!),
              onOpen: () => _showTypeSheet(context),
              onClear: () => onType(null),
            ),
            const SizedBox(width: 8),
            _FilterButton(
              key: const Key('filter-tag'),
              label: AppStrings.filterStyle,
              value: tag == null ? null : chordTagLabel(tag!),
              onOpen: () => _showTagSheet(context),
              onClear: () => onTag(null),
            ),
          ],
        ),
      );

  Future<void> _sheet(
    BuildContext context,
    String title,
    Widget Function(BuildContext sheetContext) body,
  ) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        // Por encima de la barra inferior del shell.
        useRootNavigator: true,
        builder: (sheetContext) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(sheetContext).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  body(sheetContext),
                ],
              ),
            ),
          ),
        ),
      );

  void _pick(BuildContext sheetContext, ValueChanged<String?> onPick, String? v) {
    onPick(v);
    Navigator.of(sheetContext).pop();
  }

  void _showRootSheet(BuildContext context) => _sheet(
        context,
        AppStrings.filterRootTitle,
        (sheet) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView.count(
              crossAxisCount: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.1,
              children: [
                for (final note in chromaticNotes)
                  _NoteKey(
                    note: note,
                    selected: note == root,
                    onTap: () => _pick(sheet, onRoot, note),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _pick(sheet, onRoot, null),
              child: const Text(AppStrings.filterAllRoots),
            ),
          ],
        ),
      );

  void _showTypeSheet(BuildContext context) => _sheet(
        context,
        AppStrings.filterTypeTitle,
        (sheet) {
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
                  child: const Text(AppStrings.filterAllTypes),
                ),
              ),
            ],
          );
        },
      );

  void _showTagSheet(BuildContext context) => _sheet(
        context,
        AppStrings.filterStyleTitle,
        (sheet) => Column(
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
              child: const Text(AppStrings.filterAllStyles),
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

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    super.key,
    required this.label,
    required this.value,
    required this.onOpen,
    required this.onClear,
  });

  final String label;
  final String? value;
  final VoidCallback onOpen;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final active = value != null;
    return Material(
      color: active ? p.accent.withValues(alpha: 0.18) : p.surface,
      shape: StadiumBorder(side: BorderSide(color: active ? p.accent : p.outline)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                active ? '$label: $value' : label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    ),
              ),
              const SizedBox(width: 2),
              if (active)
                InkResponse(
                  onTap: onClear,
                  radius: 16,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      semanticLabel: '${AppStrings.filterClear} $label',
                    ),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.expand_more, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteKey extends StatelessWidget {
  const _NoteKey({
    required this.note,
    required this.selected,
    required this.onTap,
  });

  final String note;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final sharp = note.contains('#');
    return Material(
      color: selected ? p.accent : (sharp ? p.background : p.surfaceHigh),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: selected ? p.accent : p.outline),
      ),
      child: InkWell(
        key: Key('root-$note'),
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Center(
          child: Text(
            note,
            style: musicMono(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: selected ? p.onAccent : p.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
