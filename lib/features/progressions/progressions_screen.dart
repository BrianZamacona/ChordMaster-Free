import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/chord_metadata.dart';
import '../../core/widgets/chord_diagram.dart';
import '../../core/widgets/feature_module_scaffold.dart';
import '../../core/widgets/selector_pill.dart';
import '../../domain/practice/technique_exercises.dart';
import '../../domain/progressions/progression_data.dart';
import '../../domain/strumming/strumming_course.dart';
import '../../domain/theory/harmony.dart';
import '../../domain/theory/notes.dart';
import '../../domain/voicing/barre_detection.dart';
import '../../ui/theme.dart';
import '../chords/chord_viewmodel.dart';
import '../chords/fingering_selection.dart';
import '../lessons/lesson_widgets.dart';
import 'progressions_viewmodel.dart';

/// Chord progressions screen.
class ProgressionsScreen extends StatelessWidget {
  /// Creates the [ProgressionsScreen].
  const ProgressionsScreen({super.key});

  @override
  Widget build(BuildContext context) => FeatureModuleScaffold(
    title: AppStrings.moduleProgressions,
    body: const ProgressionsContent(),
  );
}

/// Cuerpo de la pantalla, separado del scaffold para poder probarlo solo.
///
/// Arriba, tonalidad y progresión como botones con hoja; debajo, los acordes
/// en cuadrícula (nunca en una fila con scroll horizontal, que los cortaba).
class ProgressionsContent extends ConsumerWidget {
  const ProgressionsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progressionsViewModelProvider);
    final vm = ref.read(progressionsViewModelProvider.notifier);
    final plan = ref.watch(progressionPlanProvider);
    final current = state.progression;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SelectorPill(
              key: const Key('progression-key'),
              label: AppStrings.progressionKey,
              value: noteNames[state.tonic],
              onOpen: () => showNotePicker(
                context,
                title: AppStrings.progressionKeyTitle,
                selected: noteNames[state.tonic],
                onPicked: (note) {
                  if (note != null) vm.setTonic(noteIndex(note));
                },
              ),
            ),
            SelectorPill(
              key: const Key('progression-pick'),
              label: AppStrings.progressionLabel,
              value: state.isCustom
                  ? AppStrings.progressionCustom
                  : current.name?.text ?? _numerals(current),
              onOpen: () => _showProgressionSheet(
                context,
                tonic: state.tonic,
                selectedId: current.id,
                custom: state.custom,
                onPicked: vm.setProgression,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(AppStrings.modeStandard)),
            ButtonSegment(value: true, label: Text(AppStrings.modeBeginner)),
          ],
          selected: {state.beginner},
          onSelectionChanged: (s) => vm.setBeginner(beginner: s.first),
        ),
        const SizedBox(height: 16),
        if (state.isCustom) ...[
          _CustomBuilder(tonic: state.tonic, custom: state.custom),
          const SizedBox(height: 16),
        ],
        plan.when(
          data: (p) => p.problem != null
              ? _ProblemMessage(message: p.problem!)
              : _PlanView(plan: p, playingIndex: state.playingIndex),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ProblemMessage(
            message: '${AppStrings.progressionLoadError}: $e',
          ),
        ),
        if (current.degrees.isNotEmpty) ...[
          const SizedBox(height: 16),
          _WhyCard(progression: current, tonic: state.tonic),
        ],
      ],
    );
  }

  static String _chordIn(ProgressionDegree d, int tonic) => chordDisplayName(
    root: pitchClassName(tonic + d.semitones),
    type: d.type,
  );

  static String _numerals(Progression p) =>
      [for (final d in p.degrees) d.numeral].join('–');

  /// Los acordes en [tonic]; en las que tienen nombre (los blues), cada uno
  /// una vez.
  static String _chordsIn(Progression p, int tonic) {
    final chords = [for (final d in p.degrees) _chordIn(d, tonic)];
    return (p.name == null ? chords : chords.toSet().toList()).join(' · ');
  }

  static String _kindTitle(ProgressionKind k) => switch (k) {
    ProgressionKind.major => AppStrings.progressionKindMajor,
    ProgressionKind.blues => AppStrings.progressionKindBlues,
    ProgressionKind.minor => AppStrings.progressionKindMinor,
    ProgressionKind.modal => AppStrings.progressionKindModal,
  };

  void _showProgressionSheet(
    BuildContext context, {
    required int tonic,
    required String selectedId,
    required List<String> custom,
    required ValueChanged<String> onPicked,
  }) =>
      showSelectorSheet(
        context,
        title: AppStrings.progressionPickTitle,
        builder: (sheet) {
          final p = sheet.palette;
          final customSelected = selectedId == customProgressionId;
          return Column(
            children: [
              Card(
                color: customSelected ? p.accent.withValues(alpha: 0.18) : null,
                child: ListTile(
                  key: const Key('progression-custom'),
                  leading: Icon(Icons.edit_note, color: p.accent),
                  title: Text(AppStrings.progressionCustom),
                  subtitle: Text(
                    custom.isEmpty
                        ? AppStrings.progressionCustomSub
                        : custom.join('–'),
                  ),
                  trailing: customSelected
                      ? Icon(Icons.check, color: p.accent)
                      : null,
                  onTap: () {
                    onPicked(customProgressionId);
                    Navigator.of(sheet).pop();
                  },
                ),
              ),
              for (final kind in ProgressionKind.values) ...[
                Padding(
                  key: Key('progression-kind-${kind.name}'),
                  padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(_kindTitle(kind), style: Theme.of(sheet).textTheme.titleSmall),
                  ),
                ),
                for (final prog in progressions.where((p) => p.kind == kind))
                Card(
                  color: prog.id == selectedId
                      ? p.accent.withValues(alpha: 0.18)
                      : null,
                  child: ListTile(
                    key: Key('progression-${prog.id}'),
                    title: prog.name == null
                        ? Text(
                            _numerals(prog),
                            style: musicMono(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: p.textPrimary,
                            ),
                          )
                        : Text(prog.name!.text, style: Theme.of(sheet).textTheme.titleMedium),
                    subtitle: Text(_chordsIn(prog, tonic)),
                    trailing: prog.id == selectedId
                        ? Icon(Icons.check, color: p.accent)
                        : null,
                    onTap: () {
                      onPicked(prog.id);
                      Navigator.of(sheet).pop();
                    },
                  ),
                ),
              ],
            ],
          );
        },
      );
}

class _ProblemMessage extends StatelessWidget {
  const _ProblemMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(message, key: const Key('progression-problem')),
    ),
  );
}

/// Tempo (de 5 en 5) y bucle de la escucha.
class _ListenOptions extends ConsumerWidget {
  const _ListenOptions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progressionsViewModelProvider);
    final vm = ref.read(progressionsViewModelProvider.notifier);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 4,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(AppStrings.progressionTempo, style: text.labelLarge),
            IconButton(
              key: const Key('progression-bpm-down'),
              tooltip: AppStrings.progressionSlower,
              onPressed: state.bpm > techniqueMinBpm ? () => vm.setBpm(state.bpm - techniqueBpmStep) : null,
              icon: const Icon(Icons.remove),
            ),
            Text(
              AppStrings.progressionBpm(state.bpm),
              key: const Key('progression-bpm'),
              style: musicMono(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            IconButton(
              key: const Key('progression-bpm-up'),
              tooltip: AppStrings.progressionFaster,
              onPressed: state.bpm < techniqueMaxBpm ? () => vm.setBpm(state.bpm + techniqueBpmStep) : null,
              icon: const Icon(Icons.add),
            ),
            const SizedBox(width: 4),
            FilterChip(
              key: const Key('progression-loop'),
              avatar: Icon(Icons.repeat, size: 18, color: context.palette.textPrimary),
              label: Text(AppStrings.tabLoop),
              selected: state.loop,
              showCheckmark: false,
              onSelected: (v) => vm.setLoop(loop: v),
            ),
          ],
        ),
        if (state.progression.feel == ProgressionFeel.straight) ...[
          Wrap(
            key: const Key('progression-patterns'),
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(AppStrings.progressionStrum, style: text.labelLarge),
              for (var i = 0; i < strummingPatterns.length; i++)
                ChoiceChip(
                  key: Key('progression-pattern-$i'),
                  label: Text('${i + 1}', semanticsLabel: patternName(i).text),
                  selected: state.pattern == i,
                  onSelected: (_) => vm.setPattern(i),
                ),
            ],
          ),
          const SizedBox(height: 6),
          StrumPatternView(key: const Key('progression-pattern-view'), pattern: strummingPatterns[state.pattern]),
          const SizedBox(height: 6),
        ],
        Text(
          state.progression.feel == ProgressionFeel.triplet
              ? AppStrings.progressionBarPerChordTriplet
              : state.pattern == 0
              ? AppStrings.progressionBarPerChord
              : AppStrings.progressionBarPerChordPattern(state.pattern + 1),
          style: text.bodySmall?.copyWith(color: context.palette.textSecondary),
        ),
      ],
    );
  }
}

class _PlanView extends ConsumerWidget {
  const _PlanView({required this.plan, required this.playingIndex});

  final ProgressionPlan plan;
  final int? playingIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 12.0;
      final columns = constraints.maxWidth >= 640 ? 4 : 2;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plan.steps.isNotEmpty) ...[
            FilledButton.tonalIcon(
              key: const Key('progression-listen'),
              onPressed: () =>
                  ref.read(progressionsViewModelProvider.notifier).listen(plan),
              icon: Icon(playingIndex == null ? Icons.play_arrow : Icons.stop),
              label: Text(
                playingIndex == null
                    ? AppStrings.progressionListen
                    : AppStrings.progressionStop,
              ),
            ),
            const SizedBox(height: 4),
            const _ListenOptions(),
            const SizedBox(height: 8),
          ],
          Text(
            AppStrings.progressionTapHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final (i, step) in plan.steps.indexed)
                SizedBox(
                  width: width,
                  child: _StepCard(index: i, step: step, playing: playingIndex == i),
                ),
            ],
          ),
        ],
      );
    },
  );
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.index, required this.step, this.playing = false});

  final int index;
  final ProgressionStep step;

  /// Es el acorde que suena al escuchar la progresión.
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final chord = step.voicing.chord;
    return Card(
      key: Key('step-$index'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: playing ? p.accent.withValues(alpha: 0.16) : null,
      shape: step.chosen || playing
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: p.accent, width: playing ? 2.5 : 1.5),
            )
          : null,
      child: InkWell(
        onTap: () => _showPositionsSheet(context, index, step),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          child: LayoutBuilder(
            builder: (context, constraints) => Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      step.numeral,
                      style: musicMono(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: p.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      // Cifrado internacional (C, Am, G7), no el id en inglés.
                      child: Text(
                        chordDisplayName(root: chord.root, type: chord.type),
                        key: Key('step-name-$index'),
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ChordDiagramWidget(
                  chordName: chord.name,
                  fretPositions: step.voicing.jsonFrets,
                  fingerPositions: step.voicing.jsonFingers,
                  root: chord.root,
                  toneRow: DiagramToneRow.intervals,
                  showChordName: false,
                  size: constraints.maxWidth.clamp(100, 170).toDouble(),
                ),
                // Solo el modo principiante calcula `barre`; en estándar es null y no hay chip.
                if (step.voicing.barre case final barre?)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Chip(
                      key: const Key('barre-chip'),
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        barreKind(barre) == BarreKind.grande
                            ? '${AppStrings.barreFret} ${barre.fret} · ${AppStrings.barreLarge}'
                            : '${AppStrings.barreFret} ${barre.fret}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ),
                if (step.chosen)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      AppStrings.progressionChosen,
                      key: Key('step-chosen-$index'),
                      style: theme.textTheme.labelSmall?.copyWith(color: p.accent),
                    ),
                  ),
                if (step.transition case final t?) ...[
                  const SizedBox(height: 6),
                  ProgressionTransitionChip(transition: t),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Glosario: todas las posiciones del acorde (principal, CAGED, voicings,
/// tríadas e inversiones). Tocar una la usa en la progresión.
void _showPositionsSheet(BuildContext context, int index, ProgressionStep step) {
  final name = step.voicing.chord.name;
  showSelectorSheet(
    context,
    title: AppStrings.progressionPositionsOf(
      chordDisplayName(root: step.voicing.chord.root, type: step.voicing.chord.type),
    ),
    builder: (sheet) => Consumer(
      builder: (sheet, ref, _) {
        final vm = ref.read(progressionsViewModelProvider.notifier);
        final loading = ref.watch(chordViewModelProvider.select((s) => s.isLoading));
        final chord = loading
            ? null
            : ref.read(chordViewModelProvider.notifier).findByName(name);
        if (chord == null) {
          return loading
              ? const Center(child: CircularProgressIndicator())
              : Text(AppStrings.errorGeneric);
        }
        final p = sheet.palette;
        final text = Theme.of(sheet).textTheme;
        final current = step.voicing.jsonFrets.join(',');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (step.chosen)
              OutlinedButton.icon(
                key: const Key('reset-fingering'),
                onPressed: () {
                  vm.resetFingering(index);
                  Navigator.of(sheet).pop();
                },
                icon: const Icon(Icons.restart_alt, size: 18),
                label: Text(AppStrings.progressionResetFingering),
              ),
            for (final section in compareSections)
              if (sectionItems(chord, section).isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(sectionTitle(section), style: text.titleSmall?.copyWith(color: p.accent)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (i, item) in sectionItems(chord, section).indexed)
                      Card(
                        key: Key('glossary-$section-$i'),
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        shape: item.fretPositions.join(',') == current
                            ? RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: p.accent, width: 2),
                              )
                            : null,
                        child: InkWell(
                          onTap: () {
                            vm.chooseFingering(
                              index,
                              (frets: item.fretPositions, fingers: item.fingerPositions),
                            );
                            Navigator.of(sheet).pop();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: SizedBox(
                              width: 112,
                              child: Column(
                                children: [
                                  Text(
                                    fingeringTitle(chord, FingeringRef(section, i)),
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.labelSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  ChordDiagramWidget(
                                    chordName: item.title,
                                    fretPositions: item.fretPositions,
                                    fingerPositions: item.fingerPositions,
                                    root: chord.root,
                                    baseFret: item.baseFret,
                                    showChordName: false,
                                    size: 104,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
          ],
        );
      },
    ),
  );
}

/// Cómo se llega a este acorde desde el anterior: salto de traste y notas
/// que se mantienen.
class ProgressionTransitionChip extends StatelessWidget {
  const ProgressionTransitionChip({super.key, required this.transition});

  final ProgressionTransition transition;

  @override
  Widget build(BuildContext context) {
    final shift = transition.fretShift;
    final common = transition.commonNotes;
    final p = context.palette;
    final jump = shift == 0
        ? AppStrings.transitionNoJump
        : '${AppStrings.transitionJump} $shift ${shift == 1 ? AppStrings.fretWord : AppStrings.fretsWord}';
    final shared = common == 1
        ? '1 ${AppStrings.transitionCommonOne}'
        : '$common ${AppStrings.transitionCommonMany}';
    return Tooltip(
      message: '${AppStrings.transitionCost}: ${transition.cost}',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.subdirectory_arrow_right, size: 14, color: p.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$jump · $shared',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: p.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Mi progresión": se arma tocando grados de la tonalidad (antes era el
/// módulo Componer, con nombres de acorde sueltos y sin teoría).
class _CustomBuilder extends ConsumerWidget {
  const _CustomBuilder({required this.tonic, required this.custom});

  final int tonic;
  final List<String> custom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(progressionsViewModelProvider.notifier);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final degrees = Progression('all', '', majorDegreeNumerals).degrees;
    final full = custom.length >= customProgressionMax;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.progressionCustomHint, style: text.bodySmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final d in degrees)
                  Tooltip(
                    message: degreeRole(d.numeral).text,
                    child: ActionChip(
                      key: Key('add-degree-${d.numeral}'),
                      label: Text(
                        '${d.numeral} · ${ProgressionsContent._chordIn(d, tonic)}',
                        style: musicMono(fontSize: 13, color: p.textPrimary),
                      ),
                      onPressed: full ? null : () => vm.addCustomDegree(d.numeral),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.progressionCustomCount(custom.length, customProgressionMax),
                    style: text.labelMedium?.copyWith(color: p.textSecondary),
                  ),
                ),
                if (custom.isNotEmpty)
                  TextButton.icon(
                    key: const Key('custom-clear'),
                    onPressed: vm.clearCustom,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(AppStrings.filterClearAll),
                  ),
              ],
            ),
            if (custom.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < custom.length; i++)
                    InputChip(
                      key: Key('custom-$i'),
                      label: Text(custom[i], style: musicMono(fontSize: 13, color: p.textPrimary)),
                      onDeleted: () => vm.removeCustomDegree(i),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// "¿Por qué suena así?": teoría generada por reglas (`domain/theory/harmony`).
class _WhyCard extends StatelessWidget {
  const _WhyCard({required this.progression, required this.tonic});

  final Progression progression;
  final int tonic;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final numerals = {for (final d in progression.degrees) d.numeral};
    final lines = explainProgression(progression, tonic);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: const Key('progression-why'),
        initiallyExpanded: true,
        shape: const Border(),
        leading: Icon(Icons.lightbulb_outline, color: p.accent),
        title: Text(AppStrings.whyTitle),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(l.text, style: text.bodyMedium),
            ),
          const SizedBox(height: 6),
          for (final n in allDegreeNumerals)
            if (numerals.contains(n))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  degreeRole(n).text,
                  style: text.bodySmall?.copyWith(color: p.textSecondary),
                ),
              ),
        ],
      ),
    );
  }
}
