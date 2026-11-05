import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../data/models/note_coordinate.dart';
import '../../data/repository/scale_repository.dart';
import '../../domain/theory/circle_of_fifths.dart';
import '../../domain/theory/notes.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/fretboard_diagram.dart';
import 'circle_build_ring.dart';

/// "¿Cómo se arma?": por qué las tonalidades están en ese orden. Desde C, cada
/// paso busca la quinta y cambia una sola nota, mientras el círculo se llena.
/// Cambia sin animación, así que respeta "reducir movimiento" solo.
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
    final previousScale = step.previousScale;
    final tonicName = pitchClassName(step.tonic);
    final isLast = _current == _steps.length - 1;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.circleBuildTitle)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              children: [
                Text(
                  circleBuildRule.text,
                  style: text.bodyMedium?.copyWith(color: p.textSecondary),
                ),
                const SizedBox(height: 12),
                CircleBuildRing(step: step),
                const SizedBox(height: 8),
                Text(
                  AppStrings.circleBuildProgress(_current + 1, _steps.length),
                  key: const Key('circle-build-progress'),
                  textAlign: TextAlign.center,
                  style: musicMono(fontSize: 12, color: p.textSecondary),
                ),
                const SizedBox(height: 12),
                if (previousScale != null) ...[
                  _StepCard(
                    title: AppStrings.circleBuildFindFifth(
                      pitchClassName(step.previousTonic!),
                    ),
                    children: [
                      _ScaleRow(
                        notes: previousScale,
                        marked: {previousScale[0], previousScale[4]},
                      ),
                      Text(
                        step.fifthText!.text,
                        key: const Key('circle-build-fifth'),
                        style: text.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                _StepCard(
                  title: previousScale == null
                      ? AppStrings.circleBuildNotesOf(tonicName)
                      : AppStrings.circleBuildChangeOne,
                  children: [
                    _ScaleRow(
                      notes: step.scale,
                      marked: {?step.raisedTo},
                      raised: step.raisedTo,
                    ),
                    Text(
                      step.changeText.text,
                      key: const Key('circle-build-change'),
                      style: text.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (isLast) ...[
                  _StepCard(
                    title: AppStrings.circleBuildClosingTitle,
                    children: [
                      Text(
                        circleBuildClosing.text,
                        key: const Key('circle-build-closing'),
                        style: text.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                _StepCard(
                  title: step.previousTonic == null
                      ? AppStrings.circleBuildNeckStart(tonicName)
                      : AppStrings.circleBuildNeck(
                          pitchClassName(step.previousTonic!),
                          tonicName,
                        ),
                  children: [
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
                    Text(
                      fifthShapeRule.text,
                      style: text.bodySmall?.copyWith(color: p.textSecondary),
                    ),
                  ],
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
                    onPressed: isLast
                        ? () => Navigator.of(context).maybePop()
                        : () => setState(() => _current++),
                    child: Text(
                      isLast
                          ? AppStrings.circleBuildToWheel
                          : AppStrings.circleBuildNext,
                    ),
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

class _StepCard extends StatelessWidget {
  const _StepCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          ...children,
        ],
      ),
    ),
  );
}

/// Las 7 notas de una escala con su grado debajo. Lo marcado se distingue
/// también sin el color: va en negrita y la nota que sube lleva "↑".
class _ScaleRow extends StatelessWidget {
  const _ScaleRow({required this.notes, required this.marked, this.raised});

  final List<int> notes;
  final Set<int> marked;
  final int? raised;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      spacing: 4,
      children: [
        for (final (i, note) in notes.indexed)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: marked.contains(note) ? p.accent : p.surfaceHigh,
                border: Border.all(
                  color: marked.contains(note) ? p.accent : p.outline,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    pitchClassName(note),
                    style: musicMono(
                      fontSize: 13,
                      fontWeight: marked.contains(note)
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: marked.contains(note)
                          ? p.onAccent
                          : p.textPrimary,
                    ),
                  ),
                  Text(
                    note == raised ? '↑' : '${i + 1}',
                    style: musicMono(
                      fontSize: 11,
                      color: marked.contains(note)
                          ? p.onAccent
                          : p.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
