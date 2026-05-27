import 'package:flutter/material.dart';

class RootPicker extends StatelessWidget {
  const RootPicker({super.key, required this.selected, required this.onChanged});

  static const _roots = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

  final int selected;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SizedBox(
      height: 44,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 12,
        itemBuilder: (_, i) {
          final active = i == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 6, top: 6, bottom: 6),
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 36,
                decoration: BoxDecoration(
                  color: active ? cs.primary : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: active
                      ? [BoxShadow(color: cs.primary.withAlpha(80), blurRadius: 6, offset: const Offset(0, 2))]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  _roots[i],
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: active ? cs.onPrimary : cs.onSurfaceVariant,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                    fontSize: _roots[i].length > 1 ? 9 : 11,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
