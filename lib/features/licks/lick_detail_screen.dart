import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../data/repository/scale_repository.dart';
import '../../domain/guides/guides.dart';
import '../../domain/lessons/lesson.dart';
import '../../domain/licks/lick.dart';
import '../../domain/licks/lick_browse.dart';
import '../../domain/licks/lick_transpose.dart';
import '../../domain/licks/licks.dart';
import '../../domain/practice/play_along.dart';
import '../../domain/practice/session_summary.dart';
import '../../domain/theory/notes.dart';
import '../../services/session_log.dart';
import '../../ui/section_routes.dart';
import '../../ui/theme.dart';
import '../lessons/tab_player.dart';
import 'lick_texts.dart';
import 'licks_viewmodel.dart';

/// Una frase de la biblioteca: qué escuchar, su tablatura con ▶, bucle y
/// "Tocar yo" (el micrófono guarda el mejor tempo limpio), el estilo al que
/// pertenece y su escala en el diapasón.
class LickDetailScreen extends ConsumerWidget {
  const LickDetailScreen({super.key, required this.lickId});

  final String lickId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lick = licksById[lickId];
    if (lick == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.moduleLicks)),
        body: Center(child: Text(AppStrings.licksNoResults)),
      );
    }
    final state = ref.watch(licksViewModelProvider);
    final vm = ref.read(licksViewModelProvider.notifier);
    final bpm = state.tempoOf(lick.id);
    final root = state.rootOf(lick.id);
    // En otra tónica (transponer); si no se puede, la suya.
    final moved = transposedLick(lick, root);
    final notes = moved?.tab ?? lick.tab;
    final scale = moved?.scale ?? lick.scale;
    final record = state.records[lick.id];
    final style = lickStyleInfo(lick.style);
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    final favorite = state.favorites.contains(lick.id);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.moduleLicks),
        actions: [
          IconButton(
            key: const Key('lick-favorite'),
            tooltip: favorite ? AppStrings.licksFavoriteRemove : AppStrings.licksFavoriteAdd,
            isSelected: favorite,
            icon: const Icon(Icons.star_border),
            selectedIcon: Icon(Icons.star, color: p.accent),
            onPressed: () => vm.toggleFavorite(lick.id),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(lick.title.text, style: text.headlineSmall),
          const SizedBox(height: 4),
          Text(
            '${style.title.text} · ${lickKindLabel(lick.kind)} · ${guideLevelTitle(lick.level).text}',
            key: const Key('lick-meta'),
            style: text.labelMedium?.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: 12),
          Text(lick.aboutIn(scale.root).text, key: const Key('lick-about'), style: text.bodyLarge),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.licksScaleAt(lickScaleLabel(scale), bpm),
                    key: const Key('lick-scale'),
                    style: musicMono(fontSize: 13, color: p.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  _KeyPicker(lick: lick, root: scale.root, onChanged: (r) => vm.setRoot(lick.id, r)),
                  const SizedBox(height: 4),
                  _Speeds(lick: lick, bpm: bpm, onChanged: (b) => vm.setTempo(lick.id, b)),
                  const SizedBox(height: 8),
                  TabPlayer(
                    notes: notes,
                    bpm: bpm,
                    swing: lick.swing,
                    onPlayed: (r) => _played(context, ref, lick, r),
                    onBpmChanged: (b) => vm.setTempo(lick.id, b),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 18,
                        color: record == null ? p.textSecondary : p.success,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          record == null
                              ? AppStrings.techniqueNoRecord
                              : AppStrings.techniqueRecord(record),
                          key: const Key('lick-record'),
                          style: text.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.licksStyle, style: text.titleSmall),
                  const SizedBox(height: 6),
                  Text(style.title.text, style: text.labelLarge),
                  const SizedBox(height: 2),
                  Text(style.summary.text, style: text.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ScaleButton(scale: scale),
          const SizedBox(height: 12),
          _Neighbors(lick: lick),
        ],
      ),
    );
  }

  /// Tocada con el micrófono: va al resumen de la sesión y, si salió limpia,
  /// cuenta como práctica y, si supera el récord, se guarda y se avisa.
  Future<void> _played(BuildContext context, WidgetRef ref, Lick lick, PlayAlongResult r) async {
    final state = ref.read(licksViewModelProvider);
    final bpm = r.cleanBpm;
    final best = state.records[lick.id];
    final record = bpm != null && (best == null || bpm > best) ? bpm : null;
    unawaited(ref.read(sessionLogProvider.notifier).record(
      PracticeRun.from(LickTarget(lick.id), r, tempo: state.tempoOf(lick.id), newRecord: record),
    ));
    if (bpm == null) return;
    final saved = await ref.read(licksViewModelProvider.notifier).saveClean(lick.id, bpm);
    if (!saved || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(AppStrings.tabMicSaved(bpm))));
  }
}

/// "Velocidad: 50 % · 75 % · 100 %": el tempo de la frase a esa fracción, de un
/// toque. Si el tempo se eligió a mano, ninguna queda marcada.
class _Speeds extends StatelessWidget {
  const _Speeds({required this.lick, required this.bpm, required this.onChanged});

  final Lick lick;
  final int bpm;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = lickSpeedOf(lick, bpm);
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(AppStrings.licksSpeed, style: Theme.of(context).textTheme.labelLarge),
        for (final s in lickSpeeds)
          ChoiceChip(
            key: Key('lick-speed-$s'),
            label: Text(AppStrings.licksSpeedPercent(s)),
            selected: current == s,
            onSelected: (_) => onChanged(lickTempoAt(lick, s)),
          ),
      ],
    );
  }
}

/// La frase anterior y la siguiente del mismo estilo; reemplaza esta pantalla
/// (atrás vuelve a la lista).
class _Neighbors extends StatelessWidget {
  const _Neighbors({required this.lick});

  final Lick lick;

  @override
  Widget build(BuildContext context) {
    final (:previous, :next) = lickNeighbors(lick);
    Widget button(Lick? other, {required bool forward}) => Expanded(
      child: other == null
          ? const SizedBox.shrink()
          : OutlinedButton(
              key: Key(forward ? 'lick-next' : 'lick-previous'),
              onPressed: () => context.pushReplacement(context.sectionPath('licks/${other.id}')),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: forward ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(forward ? '${AppStrings.licksNext} →' : '← ${AppStrings.licksPrevious}'),
                    Text(
                      other.title.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
    );
    return Row(
      children: [
        button(previous, forward: false),
        const SizedBox(width: 8),
        button(next, forward: true),
      ],
    );
  }
}

/// "Tonalidad: − E +": lleva la frase a la tónica anterior o siguiente en la
/// que cabe. Las frases con cuerdas al aire no se transponen y lo dicen.
class _KeyPicker extends StatelessWidget {
  const _KeyPicker({required this.lick, required this.root, required this.onChanged});

  final Lick lick;
  final int root;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final roots = transposableRoots(lick);
    if (roots.length < 2) {
      return Text(
        AppStrings.licksKeyFixed,
        key: const Key('lick-key-fixed'),
        style: text.bodySmall?.copyWith(color: context.palette.textSecondary),
      );
    }
    final i = roots.indexOf(root);
    return Row(
      children: [
        Text(AppStrings.licksKey, style: text.labelLarge),
        const SizedBox(width: 4),
        IconButton(
          key: const Key('lick-key-down'),
          tooltip: AppStrings.licksKeyDown,
          icon: const Icon(Icons.remove),
          onPressed: () => onChanged(roots[(i - 1) % roots.length]),
        ),
        SizedBox(
          width: 36,
          child: Text(
            pitchClassName(root),
            key: const Key('lick-key'),
            textAlign: TextAlign.center,
            style: musicMono(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          key: const Key('lick-key-up'),
          tooltip: AppStrings.licksKeyUp,
          icon: const Icon(Icons.add),
          onPressed: () => onChanged(roots[(i + 1) % roots.length]),
        ),
      ],
    );
  }
}

/// Abre la escala de la frase en el diapasón, en su tónica (la elegida, si se
/// transpuso).
class _ScaleButton extends ConsumerWidget {
  const _ScaleButton({required this.scale});

  final LessonScale scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definition = [
      ...?ref.watch(allScalesProvider).value,
      ...?ref.watch(allModesProvider).value,
    ].where((s) => s.id == scale.scaleId).firstOrNull;
    return OutlinedButton.icon(
      key: const Key('lick-open-scale'),
      icon: const Icon(Icons.linear_scale),
      label: Text(AppStrings.lessonOpenScale),
      onPressed: definition == null
          ? null
          : () => context.push(
                context.sectionPath('scales/${definition.id}?root=${scale.root}'),
                extra: definition,
              ),
    );
  }
}
