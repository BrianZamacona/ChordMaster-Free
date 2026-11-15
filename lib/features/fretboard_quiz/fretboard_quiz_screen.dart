import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../data/models/note_coordinate.dart';
import '../../domain/theory/fretboard_quiz.dart';
import '../../domain/theory/notes.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/fretboard_diagram.dart';
import 'fretboard_quiz_filter_sheet.dart';
import 'fretboard_quiz_viewmodel.dart';

/// Quiz del diapasón: el mástil marca un lugar y se elige entre cuatro
/// opciones (la nota, o el traste de su octava). Al responder se ve la
/// respuesta en el mástil, por qué, y la racha.
class FretQuizScreen extends ConsumerWidget {
  const FretQuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fretQuizViewModelProvider);
    final vm = ref.read(fretQuizViewModelProvider.notifier);
    final q = state.question;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final (prompt, label) = switch (q) {
      NameNoteQuestion(:final spot) => (
        AppStrings.fretQuizNameNote(spot.string, spot.fret),
        pitchClassName,
      ),
      FindNoteQuestion(:final note, :final string) => (
        AppStrings.fretQuizFindNote(pitchClassName(note), string),
        AppStrings.fretQuizFret,
      ),
      OctaveQuestion(:final from, :final to) => (
        AppStrings.fretQuizFindOctave(pitchClassName(pitchClassAt(from)), from.string, from.fret, to.string),
        AppStrings.fretQuizFret,
      ),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.hubFretboard),
        actions: [
          IconButton(
            key: const Key('fret-quiz-filters'),
            tooltip: AppStrings.fretQuizFilters,
            icon: const Icon(Icons.tune),
            onPressed: () => showFretQuizFilterSheet(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(AppStrings.fretQuizIntro, style: text.bodyMedium?.copyWith(color: p.textSecondary)),
          const SizedBox(height: 8),
          Text(
            AppStrings.fretQuizFilterSummary(
              [for (var s = 6; s >= 1; s--) if (state.filter.strings.contains(s)) s],
              state.filter.fromFret,
              state.filter.toFret,
              naturals: state.filter.naturalsOnly,
            ),
            key: const Key('fret-quiz-filter-summary'),
            style: musicMono(fontSize: 12, color: p.textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 230, child: _Neck(question: q, answered: state.isAnswered, prompt: prompt)),
          const SizedBox(height: 12),
          Text(prompt, key: const Key('fret-quiz-prompt'), style: text.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, c) in q.choices.indexed)
                _Choice(
                  key: Key('fret-choice-$i'),
                  label: label(c),
                  // Respondida: la correcta en verde y la elegida mal en rojo,
                  // con ícono (no solo color).
                  verdict: !state.isAnswered
                      ? null
                      : c == q.answer
                          ? true
                          : c == state.selected
                              ? false
                              : null,
                  onPressed: state.isAnswered ? null : () => vm.answer(c),
                ),
            ],
          ),
          if (state.isAnswered) ...[
            const SizedBox(height: 12),
            Text(
              q.isRight(state.selected!) ? AppStrings.fretQuizRight : AppStrings.fretQuizWrong(label(q.answer)),
              key: const Key('fret-quiz-verdict'),
              style: text.titleSmall?.copyWith(color: q.isRight(state.selected!) ? p.success : p.error),
            ),
            if (q case FindNoteQuestion(:final string, :final note, :final answer)) ...[
              const SizedBox(height: 4),
              Text(
                AppStrings.fretQuizFindNoteHint(
                  pitchClassName(pitchClassAt((string: string, fret: 0))),
                  answer,
                  pitchClassName(note),
                ),
                key: const Key('fret-quiz-hint'),
                style: text.bodySmall?.copyWith(color: p.textSecondary),
              ),
            ],
            if (q case OctaveQuestion(:final shape)) ...[
              const SizedBox(height: 4),
              Text(
                AppStrings.fretQuizOctaveHint(shape.fretShift, shape.octaves),
                key: const Key('fret-quiz-hint'),
                style: text.bodySmall?.copyWith(color: p.textSecondary),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                key: const Key('fret-quiz-next'),
                icon: const Icon(Icons.arrow_forward),
                label: Text(AppStrings.fretQuizNext),
                onPressed: vm.next,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            AppStrings.fretQuizScore(state.correct, state.answered, state.streak, state.bestStreak),
            key: const Key('fret-quiz-score'),
            style: musicMono(fontSize: 13, color: p.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// El mástil con lo que pregunta: la nota a nombrar ("?" hasta responder),
/// la nota a encontrar (vacío hasta responder) o la nota de partida (raíz,
/// cuadrada) y, al responder, su octava.
class _Neck extends StatelessWidget {
  const _Neck({required this.question, required this.answered, required this.prompt});

  final FretQuestion question;
  final bool answered;

  /// Lo que lee el lector de pantalla: la pregunta (sin la respuesta).
  final String prompt;

  @override
  Widget build(BuildContext context) {
    NoteCoordinate at(FretSpot s, {required bool root, required bool show}) => NoteCoordinate(
      string: s.string,
      fret: s.fret,
      isRoot: root,
      note: show ? pitchClassName(pitchClassAt(s)) : '?',
    );
    final spots = switch (question) {
      NameNoteQuestion(:final spot) => [at(spot, root: false, show: answered)],
      FindNoteQuestion(:final spot) => [if (answered) at(spot, root: false, show: true)],
      OctaveQuestion(:final from, :final to) => [
        at(from, root: true, show: true),
        if (answered) at(to, root: true, show: true),
      ],
    };
    final frets = [for (final s in spots) s.fret];
    return FretboardNeck(
      key: ValueKey(question),
      coordinates: spots,
      label: FretboardLabel.note,
      // Sin notas (la pregunta al revés, antes de responder), desde la cejuela.
      focus: frets.isEmpty
          ? null
          : (start: math.max(1, frets.reduce(math.min) - 1), end: math.max(4, frets.reduce(math.max) + 2)),
      semanticLabel: prompt,
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({super.key, required this.label, required this.verdict, required this.onPressed});

  final String label;

  /// `true` = la correcta, `false` = la elegida y equivocada, `null` = nada.
  final bool? verdict;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final icon = switch (verdict) {
      true => Icon(Icons.check_circle, color: p.success),
      false => Icon(Icons.cancel, color: p.error),
      null => null,
    };
    return SizedBox(
      width: 150,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon ?? const SizedBox.shrink(),
        label: Text(label, style: musicMono(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
