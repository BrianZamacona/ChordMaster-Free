import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../data/repository/scale_repository.dart';
import '../../domain/guides/guides.dart';
import '../../domain/licks/lick.dart';
import '../../domain/licks/licks.dart';
import '../../domain/practice/play_along.dart';
import '../../domain/practice/session_summary.dart';
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
    final record = state.records[lick.id];
    final style = lickStyleInfo(lick.style);
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.moduleLicks)),
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
          Text(lick.about.text, style: text.bodyLarge),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.licksScaleAt(lickScaleLabel(lick.scale), bpm),
                    key: const Key('lick-scale'),
                    style: musicMono(fontSize: 13, color: p.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  TabPlayer(
                    notes: lick.tab,
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
          _ScaleButton(lick: lick),
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

/// Abre la escala de la frase en el diapasón, en su tónica.
class _ScaleButton extends ConsumerWidget {
  const _ScaleButton({required this.lick});

  final Lick lick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definition = [
      ...?ref.watch(allScalesProvider).value,
      ...?ref.watch(allModesProvider).value,
    ].where((s) => s.id == lick.scale.scaleId).firstOrNull;
    return OutlinedButton.icon(
      key: const Key('lick-open-scale'),
      icon: const Icon(Icons.linear_scale),
      label: Text(AppStrings.lessonOpenScale),
      onPressed: definition == null
          ? null
          : () => context.push(
                context.sectionPath('scales/${definition.id}?root=${lick.scale.root}'),
                extra: definition,
              ),
    );
  }
}
