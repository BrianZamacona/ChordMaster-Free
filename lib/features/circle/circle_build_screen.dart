import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../data/models/note_coordinate.dart';
import '../../data/repository/scale_repository.dart';
import '../../domain/theory/circle_of_fifths.dart';
import '../../domain/theory/notes.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/fretboard_diagram.dart';

/// "¿Cómo se arma?": el círculo paso a paso desde C, sumando quintas. Cada
/// paso cambia sin animación, así que respeta "reducir movimiento" solo.
class CircleBuildScreen extends StatefulWidget {
  const CircleBuildScreen({super.key});

  @override
  State<CircleBuildScreen> createState() => _CircleBuildScreenState();
}

class _CircleBuildScreenState extends State<CircleBuildScreen> {
  final _steps = circleConstruction();
  int _current = 0;

  /// Los números de cuerda de [NoteCoordinate] son 1 = mi aguda; los del
  /// dominio, índice 0 = mi aguda.
  ResolvedPattern _patternFor(CircleStep step) {
    final previous = step.previousTonic;
    final notes = <NoteCoordinate>[];
    final links = fifthOnNeck(previous ?? step.tonic);
    if (previous != null) {
      notes
        ..add(
          NoteCoordinate(
            string: links.string + 1,
            fret: links.fret,
            isRoot: false,
            note: pitchClassName(previous),
          ),
        )
        ..add(
          NoteCoordinate(
            string: links.nextString + 1,
            fret: links.nextFret,
            isRoot: true,
            note: pitchClassName(step.tonic),
          ),
        );
    } else {
      notes.add(
        NoteCoordinate(
          string: links.string + 1,
          fret: links.fret,
          isRoot: true,
          note: pitchClassName(step.tonic),
        ),
      );
    }
    final start = links.fret == 0 ? 0 : links.fret - 1;
    return ResolvedPattern(
      scaleId: '',
      scaleName: '',
      systemId: '',
      systemName: '',
      positionId: '',
      positionName: '',
      startingFret: start,
      endFret: start + 4,
      coordinates: notes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final step = _steps[_current];
    final pattern = _patternFor(step);
    final reached = {for (final s in _steps.take(_current + 1)) s.number};
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.circleBuildTitle)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              children: [
                Text(
                  AppStrings.circleBuildProgress(_current + 1, _steps.length),
                  key: const Key('circle-build-progress'),
                  style: musicMono(fontSize: 12, color: p.textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in _steps.take(circleLength))
                      _KeyChip(
                        label: pitchClassName(s.tonic),
                        reached: reached.contains(s.number),
                        isCurrent: s.number == _current % circleLength,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  step.explanation.text,
                  key: const Key('circle-build-text'),
                  style: text.bodyLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.previousTonic == null
                              ? AppStrings.circleBuildNeckStart(
                                  pitchClassName(step.tonic),
                                )
                              : AppStrings.circleBuildNeck,
                          style: text.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        FretboardDiagram(
                          key: ValueKey('circle-build-neck-$_current'),
                          pattern: pattern,
                          height: 150,
                          label: FretboardLabel.note,
                          links: pattern.coordinates.length == 2
                              ? [
                                  (
                                    (
                                      string: pattern.coordinates[0].string,
                                      fret: pattern.coordinates[0].fret,
                                    ),
                                    (
                                      string: pattern.coordinates[1].string,
                                      fret: pattern.coordinates[1].fret,
                                    ),
                                  ),
                                ]
                              : const [],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          fifthShapeRule.text,
                          style: text.bodySmall?.copyWith(
                            color: p.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Fijos abajo: un texto largo no los aleja del dedo.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('circle-build-previous'),
                    onPressed: _current == 0
                        ? null
                        : () => setState(() => _current--),
                    child: Text(AppStrings.circleBuildPrevious),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('circle-build-next'),
                    onPressed: _current == _steps.length - 1
                        ? null
                        : () => setState(() => _current++),
                    child: Text(AppStrings.circleBuildNext),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyChip extends StatelessWidget {
  const _KeyChip({
    required this.label,
    required this.reached,
    required this.isCurrent,
  });

  final String label;
  final bool reached;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: isCurrent ? p.accent : p.surfaceHigh,
        border: Border.all(color: reached ? p.accent : p.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        reached ? label : '·',
        textAlign: TextAlign.center,
        style: musicMono(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isCurrent ? p.onAccent : p.textPrimary,
        ),
      ),
    );
  }
}
