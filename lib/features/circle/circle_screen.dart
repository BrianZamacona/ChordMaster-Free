import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/chord_metadata.dart';
import '../../domain/theory/circle_of_fifths.dart';
import '../../domain/theory/harmony.dart';
import '../../domain/theory/notes.dart';
import '../../ui/theme.dart';
import '../chords/chord_viewmodel.dart';
import '../progressions/progressions_viewmodel.dart';
import 'circle_viewmodel.dart';
import 'circle_wheel.dart';

/// Círculo de quintas: la rueda arriba, fija, y debajo el panel de la
/// tonalidad que quedó en la ventana. La rueda no está dentro de una lista,
/// así un arrastre siempre la gira y nunca compite con el scroll.
class CircleScreen extends ConsumerWidget {
  const CircleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(circleViewModelProvider.select((s) => s.index));
    final tickEnabled = ref.watch(
      circleViewModelProvider.select((s) => s.tickEnabled),
    );
    final vm = ref.read(circleViewModelProvider.notifier);
    final wheel = CircleWheel(
      key: const Key('circle-wheel'),
      initialIndex: index,
      semanticLabel: AppStrings.circleKeySemantics(
        pitchClassName(circleOrder[index]),
        keySignatureAt(index).name.text,
      ),
      onIndexChanged: vm.select,
      onClick: vm.wheelClick,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.circleTitle),
        actions: [
          IconButton(
            key: const Key('circle-tick'),
            tooltip: tickEnabled
                ? AppStrings.circleTickOff
                : AppStrings.circleTickOn,
            icon: Icon(tickEnabled ? Icons.volume_up : Icons.volume_off),
            onPressed: vm.toggleTick,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Con la pantalla apaisada van lado a lado.
          if (constraints.maxWidth > constraints.maxHeight) {
            return Row(
              children: [
                SizedBox.square(dimension: constraints.maxHeight, child: wheel),
                const Expanded(child: _KeyPanel()),
              ],
            );
          }
          final side = math.min(
            constraints.maxWidth,
            constraints.maxHeight * 0.55,
          );
          return Column(
            children: [
              SizedBox(height: side, width: double.infinity, child: wheel),
              const Expanded(child: _KeyPanel()),
            ],
          );
        },
      ),
    );
  }
}

/// La tonalidad elegida: armadura, acordes y lo que se puede hacer con ella.
class _KeyPanel extends ConsumerWidget {
  const _KeyPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final index = ref.watch(circleViewModelProvider.select((s) => s.index));
    final playing = ref.watch(
      circleViewModelProvider.select((s) => s.playingStep),
    );
    final vm = ref.read(circleViewModelProvider.notifier);
    final tonic = circleOrder[index];
    final name = pitchClassName(tonic);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text(
          AppStrings.circleKeyTitle(
            name,
            pitchClassName(relativeMinorOf(tonic)),
          ),
          key: const Key('circle-key-title'),
          style: text.titleMedium,
        ),
        Text(
          keySignatureAt(index).name.text,
          key: const Key('circle-key-signature'),
          style: text.bodySmall?.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final chord in diatonicByDegree(tonic))
                _ChordRow(chord: chord),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('circle-cadence'),
          icon: Icon(playing == null ? Icons.play_arrow : Icons.stop),
          label: Text(
            playing == null
                ? AppStrings.circleListenCadence(cadenceLabel)
                : AppStrings.circlePlayingCadence(
                    cadenceDegrees[playing].numeral,
                    playing + 1,
                    cadenceDegrees.length,
                  ),
          ),
          onPressed: vm.listenCadence,
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.circleCadenceNote(cadence('V', 'I')!.text),
          style: text.bodySmall?.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('circle-to-progressions'),
          icon: const Icon(Icons.queue_music),
          label: Text(AppStrings.circleToProgressions(name)),
          onPressed: () {
            ref.read(progressionsViewModelProvider.notifier).setTonic(tonic);
            context.go('/learn/progressions');
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('circle-open-build'),
          icon: const Icon(Icons.stairs_outlined),
          label: Text(AppStrings.circleBuildTitle),
          onPressed: () => context.push('/learn/circle/build'),
        ),
      ],
    );
  }
}

/// Un acorde diatónico: tocarlo lo hace sonar; la flecha abre su ficha.
class _ChordRow extends ConsumerWidget {
  const _ChordRow({required this.chord});

  final WindowChord chord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    // Reconstruye al terminar de cargar la biblioteca.
    ref.watch(chordViewModelProvider.select((s) => s.allChords.length));
    final name = chordDisplayName(
      root: pitchClassName(chord.root),
      type: chord.type,
    );
    final data = ref.read(chordViewModelProvider.notifier).findByName(name);
    final function = harmonicFunctionName(harmonicFunction(chord.numeral)).text;
    return InkWell(
      key: Key('circle-chord-${chord.numeral}'),
      onTap: data == null
          ? null
          : () => ref
                .read(circleViewModelProvider.notifier)
                .playChord(data.fretPositions),
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                chord.numeral,
                style: musicMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: p.accent,
                ),
              ),
            ),
            SizedBox(width: 68, child: Text(name, style: text.titleSmall)),
            Expanded(
              child: Text(
                function,
                style: text.bodySmall?.copyWith(color: p.textSecondary),
              ),
            ),
            IconButton(
              key: Key('circle-chord-open-${chord.numeral}'),
              tooltip: AppStrings.circleOpenChord(name),
              icon: const Icon(Icons.chevron_right),
              onPressed: data == null
                  ? null
                  : () => context.push(
                      '/learn/chords/${Uri.encodeComponent(data.name)}',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
