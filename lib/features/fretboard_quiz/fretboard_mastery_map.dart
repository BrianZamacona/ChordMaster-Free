import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../data/models/note_coordinate.dart';
import '../../domain/theory/fretboard_mastery.dart';
import '../../domain/theory/fretboard_quiz.dart';
import '../../domain/theory/notes.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/fretboard_diagram.dart';
import 'fretboard_quiz_viewmodel.dart';

/// El mapa de lo dominado: se elige un estado (débiles, en camino,
/// dominados) y el mástil muestra sus lugares con el nombre de la nota. El
/// estado se dice con texto, no con color.
class FretMasteryMap extends ConsumerStatefulWidget {
  const FretMasteryMap({super.key});

  /// Los estados que se pueden ver, en orden.
  static const levels = [SpotMastery.weak, SpotMastery.learning, SpotMastery.mastered];

  /// El nombre de [level] con cuántos lugares tiene.
  static String levelLabel(SpotMastery level, int count) => switch (level) {
    SpotMastery.weak => AppStrings.fretMapWeak(count),
    SpotMastery.learning => AppStrings.fretMapLearning(count),
    SpotMastery.mastered => AppStrings.fretMapMastered(count),
    SpotMastery.unexplored => AppStrings.fretMapUnexplored(count, 6 * (fretQuizMaxFret + 1)),
  };

  @override
  ConsumerState<FretMasteryMap> createState() => _FretMasteryMapState();
}

class _FretMasteryMapState extends ConsumerState<FretMasteryMap> {
  SpotMastery _level = SpotMastery.weak;

  @override
  Widget build(BuildContext context) {
    final mastery = ref.watch(fretQuizViewModelProvider.select((s) => s.mastery));
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final shown = mastery.spotsAt(_level);
    final unexplored = mastery.spotsAt(SpotMastery.unexplored).length;
    const total = 6 * (fretQuizMaxFret + 1);

    return Column(
      key: const Key('fret-map'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.fretMapTitle, style: text.titleMedium),
        const SizedBox(height: 4),
        Text(AppStrings.fretMapIntro, style: text.bodySmall?.copyWith(color: p.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final level in FretMasteryMap.levels)
              ChoiceChip(
                key: Key('fret-map-${level.name}'),
                label: Text(FretMasteryMap.levelLabel(level, mastery.spotsAt(level).length)),
                selected: _level == level,
                onSelected: (_) => setState(() => _level = level),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: FretboardNeck(
            key: ValueKey(_level),
            coordinates: [
              for (final s in shown)
                NoteCoordinate(string: s.string, fret: s.fret, isRoot: false, note: pitchClassName(pitchClassAt(s))),
            ],
            label: FretboardLabel.note,
            // Centrado en lo que se muestra (con todo el mástil, en el medio).
            focus: shown.isEmpty
                ? null
                : (
                    start: math.max(1, shown.map((s) => s.fret).reduce(math.min) - 1),
                    end: math.max(4, shown.map((s) => s.fret).reduce(math.max) + 1),
                  ),
            semanticLabel: FretMasteryMap.levelLabel(_level, shown.length),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          shown.isEmpty ? AppStrings.fretMapNone : AppStrings.fretMapUnexplored(unexplored, total),
          key: const Key('fret-map-note'),
          style: text.bodySmall?.copyWith(color: p.textSecondary),
        ),
      ],
    );
  }
}
