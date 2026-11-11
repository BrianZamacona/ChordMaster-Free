import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/theory/circle_of_fifths.dart';
import '../../domain/theory/circle_quiz.dart';
import '../../domain/theory/notes.dart';
import '../../ui/theme.dart';
import 'circle_harmony_viewmodel.dart';
import 'circle_quiz_viewmodel.dart';

/// Quiz del círculo: una pregunta, cuatro opciones y, al responder, por qué
/// (el paso del círculo que la explica) y la racha.
class CircleQuizScreen extends ConsumerWidget {
  const CircleQuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(circleQuizViewModelProvider);
    final vm = ref.read(circleQuizViewModelProvider.notifier);
    final q = state.question;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final key = pitchClassName(circleOrder[q.index]);
    final (prompt, label, why) = _describe(q, key);
    final right = state.isAnswered && q.isRight(state.selected!);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.circleQuizTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(AppStrings.circleQuizIntro, style: text.bodyMedium?.copyWith(color: p.textSecondary)),
          const SizedBox(height: 16),
          Text(prompt, key: const Key('circle-quiz-prompt'), style: text.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, c) in q.choices.indexed)
                SizedBox(
                  width: 150,
                  child: OutlinedButton.icon(
                    key: Key('circle-quiz-choice-$i'),
                    // Respondida: la correcta y la elegida mal, con ícono.
                    icon: !state.isAnswered
                        ? const SizedBox.shrink()
                        : c == q.answer
                            ? Icon(Icons.check_circle, color: p.success)
                            : c == state.selected
                                ? Icon(Icons.cancel, color: p.error)
                                : const SizedBox.shrink(),
                    label: Text(label(c), style: musicMono(fontSize: 16, fontWeight: FontWeight.w600)),
                    onPressed: state.isAnswered ? null : () => vm.answer(c),
                  ),
                ),
            ],
          ),
          if (state.isAnswered) ...[
            const SizedBox(height: 12),
            Text(
              right ? AppStrings.fretQuizRight : AppStrings.fretQuizWrong(label(q.answer)),
              key: const Key('circle-quiz-verdict'),
              style: text.titleSmall?.copyWith(color: right ? p.success : p.error),
            ),
            const SizedBox(height: 4),
            Text(why, key: const Key('circle-quiz-why'), style: text.bodySmall?.copyWith(color: p.textSecondary)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                key: const Key('circle-quiz-next'),
                icon: const Icon(Icons.arrow_forward),
                label: Text(AppStrings.fretQuizNext),
                onPressed: vm.next,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            AppStrings.fretQuizScore(state.correct, state.answered, state.streak, state.bestStreak),
            key: const Key('circle-quiz-score'),
            style: musicMono(fontSize: 13, color: p.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Pregunta, cómo se nombra cada opción y por qué la respuesta es esa.
(String, String Function(int), String) _describe(CircleQuestion q, String key) => switch (q) {
  DominantQuestion() => (
    AppStrings.circleQuizDominant(key),
    pitchClassName,
    AppStrings.circleQuizWhyDominant(key, pitchClassName(q.answer)),
  ),
  SignatureQuestion() => (
    AppStrings.circleQuizSignature(key),
    (int i) => keySignatureAt(i).short,
    AppStrings.circleQuizWhySignature(key, keySignatureAt(q.index).short),
  ),
  MissingChordQuestion(:final shown, :final chordChoices) => (
    AppStrings.circleQuizMissing(key, shown.map(circleChordName).join(' ')),
    (int i) => circleChordName(chordChoices[i]),
    AppStrings.circleQuizWhyMissing(chordChoices[q.answer].numeral),
  ),
};
