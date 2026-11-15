import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/theory/fretboard_quiz.dart';
import '../../domain/theory/fretboard_round.dart';
import '../../ui/theme.dart';
import 'fretboard_quiz_screen.dart';
import 'fretboard_quiz_viewmodel.dart';

/// La ronda con reloj: el botón para empezarla (con el récord), el reloj y
/// los puntos mientras corre, y el resultado al terminar.
class FretRoundPanel extends ConsumerWidget {
  const FretRoundPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fretQuizViewModelProvider);
    final vm = ref.read(fretQuizViewModelProvider.notifier);
    final round = state.round;
    if (round != null) return _Running(round: round, onStop: vm.stopRound);
    final last = state.lastRound;
    if (last != null) {
      return _Result(
        round: last,
        record: state.lastRoundRecord,
        best: state.bestRound,
        onAgain: vm.startRound,
        onClose: vm.dismissRoundResult,
      );
    }
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        FilledButton.tonalIcon(
          key: const Key('fret-round-start'),
          icon: const Icon(Icons.timer_outlined),
          label: Text(AppStrings.fretRoundStart),
          onPressed: vm.startRound,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            state.bestRound > 0 ? AppStrings.fretRoundBest(state.bestRound) : AppStrings.fretRoundStartSub,
            key: const Key('fret-round-best'),
            style: text.bodySmall?.copyWith(color: p.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _Running extends StatelessWidget {
  const _Running({required this.round, required this.onStop});

  final FretRound round;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timer_outlined, color: p.textSecondary, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                AppStrings.fretRoundLeft(round.left),
                key: const Key('fret-round-left'),
                style: text.titleMedium,
              ),
            ),
            TextButton(key: const Key('fret-round-stop'), onPressed: onStop, child: Text(AppStrings.fretRoundStop)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: round.left / fretRoundSeconds),
        const SizedBox(height: 6),
        Text(
          AppStrings.fretRoundScore(round.score, round.answered),
          key: const Key('fret-round-score'),
          style: musicMono(fontSize: 13, color: p.textSecondary),
        ),
      ],
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.round,
    required this.record,
    required this.best,
    required this.onAgain,
    required this.onClose,
  });

  final FretRound round;
  final bool record;
  final int best;
  final VoidCallback onAgain;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Card(
      key: const Key('fret-round-result'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.fretRoundOver(round.score, round.answered), style: text.titleSmall),
            const SizedBox(height: 4),
            Text(
              record ? AppStrings.fretRoundNewRecord : AppStrings.fretRoundBest(best),
              key: const Key('fret-round-record'),
              style: text.bodyMedium?.copyWith(color: record ? p.success : p.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: const Key('fret-round-again'),
                  icon: const Icon(Icons.replay),
                  label: Text(AppStrings.fretRoundAgain),
                  onPressed: onAgain,
                ),
                TextButton(
                  key: const Key('fret-round-close'),
                  onPressed: onClose,
                  child: Text(AppStrings.fretRoundClose),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Si la respuesta anterior de la ronda estuvo bien (con ícono, no solo
/// color), mientras ya se ve la siguiente pregunta.
class FretRoundPrevious extends StatelessWidget {
  const FretRoundPrevious({super.key, required this.previous});

  final ({FretQuestion question, int choice}) previous;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final right = previous.question.isRight(previous.choice);
    final label = fretChoiceLabel(previous.question);
    return Row(
      key: const Key('fret-round-previous'),
      children: [
        Icon(right ? Icons.check_circle : Icons.cancel, color: right ? p.success : p.error, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            right ? AppStrings.fretQuizRight : AppStrings.fretQuizWrong(label(previous.question.answer)),
            style: text.bodyMedium?.copyWith(color: right ? p.success : p.error),
          ),
        ),
      ],
    );
  }
}
