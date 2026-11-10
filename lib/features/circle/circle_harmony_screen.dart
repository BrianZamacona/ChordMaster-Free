import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/scale_names.dart';
import '../../data/repository/scale_repository.dart';
import '../../domain/theory/circle_harmony.dart';
import '../../domain/theory/circle_of_fifths.dart';
import '../../domain/theory/notes.dart';
import '../../ui/section_routes.dart';
import '../../ui/theme.dart';
import '../chords/chord_viewmodel.dart';
import 'circle_harmony_viewmodel.dart';
import 'circle_viewmodel.dart';

/// Fase 2 del círculo: lo que hay más allá de los siete acordes de la
/// tonalidad elegida en la rueda. Cuatro tarjetas: dominantes secundarias
/// (con la cadena y el ii–V–I), modular, intercambio modal y modos por
/// brillo. Todo sale de `circle_harmony.dart`.
class CircleHarmonyScreen extends ConsumerWidget {
  const CircleHarmonyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(circleViewModelProvider.select((s) => s.index));
    // Carga la biblioteca de acordes al abrir: los ▶ la necesitan.
    ref.watch(chordViewModelProvider.select((s) => s.allChords.length));
    final tonic = circleOrder[index];
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.circleHarmonyTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            AppStrings.circleHarmonyIntro(pitchClassName(tonic)),
            style: text.bodyMedium?.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: 8),
          _KeyPicker(
            key: const Key('harmony-key'),
            label: AppStrings.circleHarmonyKey,
            selected: tonic,
            keyPrefix: 'harmony-key',
            onSelected: (t) => ref.read(circleViewModelProvider.notifier).select(circleIndexOf(t)),
          ),
          const SizedBox(height: 12),
          _SecondaryCard(tonic: tonic),
          const SizedBox(height: 12),
          _ModulationCard(tonic: tonic),
          const SizedBox(height: 12),
          _BorrowCard(tonic: tonic),
          const SizedBox(height: 12),
          _ModesCard(tonic: tonic),
        ],
      ),
    );
  }
}

/// Las 12 tonalidades en el orden del círculo.
class _KeyPicker extends StatelessWidget {
  const _KeyPicker({
    super.key,
    required this.label,
    required this.selected,
    required this.keyPrefix,
    required this.onSelected,
  });

  final String label;
  final int selected;
  final String keyPrefix;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 4,
    runSpacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      for (final t in circleOrder)
        ChoiceChip(
          key: Key('$keyPrefix-$t'),
          label: Text(pitchClassName(t)),
          visualDensity: VisualDensity.compact,
          selected: t == selected,
          onSelected: (_) => onSelected(t),
        ),
    ],
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.sectionKey, required this.title, required this.children});

  final String sectionKey;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    key: Key(sectionKey),
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    ),
  );
}

/// Texto secundario.
Widget _note(BuildContext context, String text) => Text(
  text,
  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.palette.textSecondary),
);

/// Botón que hace sonar unos acordes.
class _PlayButton extends ConsumerWidget {
  const _PlayButton({super.key, required this.chords});

  final List<CircleChord> chords;

  @override
  Widget build(BuildContext context, WidgetRef ref) => OutlinedButton.icon(
    icon: const Icon(Icons.play_arrow),
    label: Text(AppStrings.circlePlayChords(chords.map(circleChordName).join(' – '))),
    onPressed: () => playCircleChords(ref, chords),
  );
}

class _SecondaryCard extends StatelessWidget {
  const _SecondaryCard({required this.tonic});

  final int tonic;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final chain = dominantChain(tonic);
    final twoFive = twoFiveOne(tonic);
    return _Section(
      sectionKey: 'harmony-secondary',
      title: AppStrings.circleSecondaryTitle,
      children: [
        _note(context, AppStrings.circleSecondaryIntro),
        const SizedBox(height: 6),
        for (final s in secondaryDominants(tonic))
          _ChordPairRow(
            key: Key('harmony-secondary-${s.target.numeral}'),
            label: 'V7/${s.target.numeral}',
            chords: [s.dominant, s.target],
          ),
        const Divider(),
        Text(AppStrings.circleChainTitle, style: Theme.of(context).textTheme.titleSmall),
        _note(context, AppStrings.circleChainIntro),
        const SizedBox(height: 4),
        Text(
          chain.map((c) => c.numeral).join(' – '),
          style: musicMono(fontSize: 13, color: p.accent, fontWeight: FontWeight.w600),
        ),
        _PlayButton(key: const Key('harmony-chain'), chords: chain),
        const Divider(),
        _note(context, AppStrings.circleTwoFiveOneIntro),
        _PlayButton(key: const Key('harmony-two-five-one'), chords: twoFive),
      ],
    );
  }
}

/// "V7/ii  A7 → Dm" con su ▶.
class _ChordPairRow extends ConsumerWidget {
  const _ChordPairRow({super.key, required this.label, required this.chords});

  final String label;
  final List<CircleChord> chords;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: musicMono(fontSize: 13, color: p.accent, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(
            AppStrings.circleSecondaryRow(circleChordName(chords.first), circleChordName(chords.last)),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        IconButton(
          tooltip: AppStrings.circlePlayChords(chords.map(circleChordName).join(' – ')),
          icon: const Icon(Icons.play_arrow),
          onPressed: () => playCircleChords(ref, chords),
        ),
      ],
    );
  }
}

class _ModulationCard extends ConsumerWidget {
  const _ModulationCard({required this.tonic});

  final int tonic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final to = ref.watch(modulationTargetProvider) ?? dominantOf(tonic);
    final m = modulation(tonic, to);
    final from = pitchClassName(tonic);
    final target = pitchClassName(to);
    return _Section(
      sectionKey: 'harmony-modulation',
      title: AppStrings.circleModulationTitle,
      children: [
        _note(context, AppStrings.circleModulationIntro(from)),
        const SizedBox(height: 6),
        _KeyPicker(
          label: AppStrings.circleModulationTo,
          selected: to,
          keyPrefix: 'harmony-to',
          onSelected: ref.read(modulationTargetProvider.notifier).choose,
        ),
        const SizedBox(height: 8),
        Text(AppStrings.circleModulationSteps(m.steps), key: const Key('harmony-steps')),
        Text(
          AppStrings.circleModulationCommon(m.commonNotes.length, m.commonNotes.map(pitchClassName).join(' ')),
          key: const Key('harmony-common'),
        ),
        const SizedBox(height: 6),
        if (m.pivots.isEmpty)
          _note(context, AppStrings.circleModulationNoPivot)
        else ...[
          Text(AppStrings.circleModulationPivots, style: Theme.of(context).textTheme.titleSmall),
          for (final pivot in m.pivots)
            Text(
              AppStrings.circlePivotRow(
                circleChordName((numeral: pivot.numeralInFrom, root: pivot.root, type: pivot.type)),
                pivot.numeralInFrom,
                from,
                pivot.numeralInTo,
                target,
              ),
              key: Key('harmony-pivot-${pivot.numeralInFrom}'),
            ),
          const SizedBox(height: 4),
          // I de la tonalidad de partida, el pivote, V7 e I de la nueva.
          _PlayButton(
            key: const Key('harmony-modulate'),
            chords: [
              (numeral: 'I', root: tonic, type: 'major'),
              (numeral: m.pivots.last.numeralInFrom, root: m.pivots.last.root, type: m.pivots.last.type),
              (numeral: 'V7', root: dominantOf(to), type: 'dominant7'),
              (numeral: 'I', root: to, type: 'major'),
            ],
          ),
        ],
      ],
    );
  }
}

class _BorrowCard extends StatelessWidget {
  const _BorrowCard({required this.tonic});

  final int tonic;

  @override
  Widget build(BuildContext context) {
    final borrowed = borrowedChords(tonic);
    final home = (numeral: 'I', root: tonic, type: 'major');
    return _Section(
      sectionKey: 'harmony-borrow',
      title: AppStrings.circleBorrowTitle,
      children: [
        _note(
          context,
          AppStrings.circleBorrowIntro(pitchClassName(tonic), keySignatureAt(parallelMinorIndex(tonic)).short),
        ),
        const SizedBox(height: 6),
        for (final c in borrowed)
          _ChordPairRow(key: Key('harmony-borrow-${c.numeral}'), label: c.numeral, chords: [c, home]),
        const SizedBox(height: 4),
        _PlayButton(key: const Key('harmony-borrow-play'), chords: [home, borrowed[1], borrowed[2], home]),
      ],
    );
  }
}

class _ModesCard extends ConsumerWidget {
  const _ModesCard({required this.tonic});

  final int tonic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final modes = [...?ref.watch(allModesProvider).value];
    return _Section(
      sectionKey: 'harmony-modes',
      title: AppStrings.circleModesTitle,
      children: [
        _note(context, AppStrings.circleModesIntro),
        const SizedBox(height: 4),
        for (final m in modesByBrightness(tonic))
          ListTile(
            key: Key('harmony-mode-${m.modeId}'),
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text('${pitchClassName(tonic)} ${scaleDisplayName(m.modeId, m.intervals)}'),
            subtitle: Text(
              AppStrings.circleModeRow(pitchClassName(m.parent), AppStrings.circleStepsShort(m.steps), m.changed),
              style: musicMono(fontSize: 12, color: p.textSecondary),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: switch (modes.where((d) => d.id == m.modeId).firstOrNull) {
              null => null,
              final definition => () => context.push(
                context.sectionPath('scales/${definition.id}?root=$tonic'),
                extra: definition,
              ),
            },
          ),
      ],
    );
  }
}
