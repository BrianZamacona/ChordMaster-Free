import 'package:flutter/material.dart';

import '../../domain/theory/notes.dart';
import '../../ui/theme.dart';
import '../constants/app_strings.dart';

/// Botón compacto de selección: "Etiqueta ▾" o, con valor, "Etiqueta: valor".
///
/// Con [onClear] el valor activo muestra una ✕ que lo quita; sin él (p. ej. la
/// tónica, que siempre tiene valor) muestra la flecha.
class SelectorPill extends StatelessWidget {
  const SelectorPill({
    super.key,
    required this.label,
    required this.value,
    required this.onOpen,
    this.onClear,
    this.compact = false,
  });

  final String label;
  final String? value;
  final VoidCallback onOpen;
  final VoidCallback? onClear;

  /// Para barras de altura fija: con valor muestra solo el valor (el lector de
  /// pantalla sigue oyendo la etiqueta) y una línea, cortada con "…" si no cabe.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final active = value != null;
    final clearable = active && onClear != null;
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
              Flexible(
                child: Text(
                  active && compact ? value! : (active ? '$label: $value' : label),
                  semanticsLabel: active ? '$label: $value' : label,
                  maxLines: compact ? 1 : null,
                  overflow: compact ? TextOverflow.ellipsis : null,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      ),
                ),
              ),
              const SizedBox(width: 2),
              if (clearable)
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

/// Hoja inferior con título, por encima de la barra del shell.
Future<void> showSelectorSheet(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext sheetContext) builder,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
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
                builder(sheetContext),
              ],
            ),
          ),
        ),
      ),
    );

/// Hoja con las 12 notas en una cuadrícula de 6 × 2. Llama a [onPicked] con
/// la nota elegida, o con `null` si [noneLabel] está y se pulsa ese botón.
Future<void> showNotePicker(
  BuildContext context, {
  required String title,
  required String? selected,
  required ValueChanged<String?> onPicked,
  String? noneLabel,
}) =>
    showSelectorSheet(
      context,
      title: title,
      builder: (sheet) {
        void pick(String? note) {
          onPicked(note);
          Navigator.of(sheet).pop();
        }

        return Column(
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
                for (final note in noteNames)
                  _NoteKey(
                    note: note,
                    selected: note == selected,
                    onTap: () => pick(note),
                  ),
              ],
            ),
            if (noneLabel != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => pick(null),
                child: Text(noneLabel),
              ),
            ],
          ],
        );
      },
    );

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
