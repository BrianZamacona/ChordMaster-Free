import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/widgets/selector_pill.dart';
import '../../domain/theory/fretboard_quiz.dart';
import '../../domain/theory/notes.dart';
import '../../ui/theme.dart';
import 'fretboard_quiz_viewmodel.dart';

/// Abre la hoja de "Qué practicar": cuerdas, tramo de trastes y solo notas
/// naturales. Cada cambio se aplica al momento (pregunta nueva dentro).
Future<void> showFretQuizFilterSheet(BuildContext context) => showSelectorSheet(
  context,
  title: AppStrings.fretQuizFilters,
  builder: (_) => const FretQuizFilterPanel(),
);

/// Lo que va dentro de la hoja.
class FretQuizFilterPanel extends ConsumerStatefulWidget {
  const FretQuizFilterPanel({super.key});

  @override
  ConsumerState<FretQuizFilterPanel> createState() => _FretQuizFilterPanelState();
}

class _FretQuizFilterPanelState extends ConsumerState<FretQuizFilterPanel> {
  /// El tramo mientras se arrastra; se aplica al soltar.
  RangeValues? _dragging;

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(fretQuizViewModelProvider.select((s) => s.filter));
    final vm = ref.read(fretQuizViewModelProvider.notifier);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final range = _dragging ?? RangeValues(filter.fromFret.toDouble(), filter.toFret.toDouble());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.fretQuizStrings, style: text.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var s = 6; s >= 1; s--)
              FilterChip(
                key: Key('fret-filter-string-$s'),
                label: Text(
                  '$s · ${pitchClassName(standardOpenStringMidi[s - 1] % 12)}',
                  style: musicMono(fontSize: 14),
                ),
                selected: filter.strings.contains(s),
                // La última cuerda elegida no se puede quitar.
                onSelected: filter.strings.length == 1 && filter.strings.contains(s)
                    ? null
                    : (on) => vm.setFilter(
                        filter.copyWith(strings: on ? {...filter.strings, s} : ({...filter.strings}..remove(s))),
                      ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          AppStrings.fretQuizFrets(range.start.round(), range.end.round()),
          key: const Key('fret-filter-frets'),
          style: text.titleSmall,
        ),
        RangeSlider(
          key: const Key('fret-filter-range'),
          values: range,
          max: fretQuizMaxFret.toDouble(),
          divisions: fretQuizMaxFret,
          labels: RangeLabels('${range.start.round()}', '${range.end.round()}'),
          onChanged: (v) {
            if (v.end.round() - v.start.round() < fretQuizMinSpan) return;
            setState(() => _dragging = v);
          },
          onChangeEnd: (v) {
            final from = v.start.round();
            final to = v.end.round();
            setState(() => _dragging = null);
            if (to - from >= fretQuizMinSpan) vm.setFilter(filter.copyWith(fromFret: from, toFret: to));
          },
        ),
        Text(AppStrings.fretQuizFretsHint, style: text.bodySmall?.copyWith(color: p.textSecondary)),
        const SizedBox(height: 12),
        SwitchListTile(
          key: const Key('fret-filter-naturals'),
          contentPadding: EdgeInsets.zero,
          title: Text(AppStrings.fretQuizNaturals),
          subtitle: Text(AppStrings.fretQuizNaturalsSub),
          value: filter.naturalsOnly,
          onChanged: (on) => vm.setFilter(filter.copyWith(naturalsOnly: on)),
        ),
        if (!fretQuizHasOctaves(filter)) ...[
          const SizedBox(height: 8),
          Text(
            AppStrings.fretQuizNoOctaves,
            key: const Key('fret-filter-no-octaves'),
            style: text.bodySmall?.copyWith(color: p.textSecondary),
          ),
        ],
        const SizedBox(height: 12),
        // Siempre en su lugar (apagado sin filtro): así la hoja no salta.
        TextButton.icon(
          key: const Key('fret-filter-reset'),
          icon: const Icon(Icons.restart_alt),
          label: Text(AppStrings.fretQuizAllFilters),
          onPressed: filter.isAll ? null : () => vm.setFilter(const FretQuizFilter()),
        ),
      ],
    );
  }
}
