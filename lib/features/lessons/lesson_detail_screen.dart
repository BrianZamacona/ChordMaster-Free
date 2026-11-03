import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/widgets/chord_diagram.dart';
import '../../data/repository/scale_repository.dart';
import '../../domain/lessons/curriculum.dart';
import '../../domain/lessons/lesson.dart';
import '../../ui/theme.dart';
import '../chords/chord_viewmodel.dart';
import '../metronome/metronome_viewmodel.dart';
import 'lessons_viewmodel.dart';

/// Una lección: explicación, pasos, acordes, rasgueo y accesos a la escala o
/// a la herramienta que usa.
class LessonDetailScreen extends ConsumerWidget {
  const LessonDetailScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lesson = lessonsById[lessonId];
    if (lesson == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.lessonsTitle)),
        body: Center(child: Text(AppStrings.lessonNotFound)),
      );
    }
    final done = ref.watch(
      lessonsViewModelProvider.select((s) => s.path.completed.contains(lesson.id)),
    );
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final trackName = switch (lesson.track) {
      LessonTrack.foundations => AppStrings.trackFoundations,
      LessonTrack.rhythm => AppStrings.trackRhythm,
      LessonTrack.lead => AppStrings.trackLead,
    };

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title.text)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            '$trackName · ${lesson.unit.text} · '
            '${AppStrings.lessonMinutes(lesson.minutes)}',
            style: text.labelMedium?.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(lesson.body.text, style: text.bodyLarge),
          const SizedBox(height: 16),
          _Section(
            title: AppStrings.lessonSteps,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, step) in lesson.steps.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${i + 1}.',
                            style: musicMono(
                              fontWeight: FontWeight.w600,
                              color: p.accent,
                            ),
                          ),
                        ),
                        Expanded(child: Text(step.text, style: text.bodyMedium)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (lesson.strumPattern case final pattern?) ...[
            const SizedBox(height: 12),
            _Section(
              title: AppStrings.lessonStrum,
              child: _StrumPattern(pattern: pattern),
            ),
          ],
          if (lesson.chords.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Section(
              title: AppStrings.lessonChords,
              child: _LessonChords(names: lesson.chords),
            ),
          ],
          const SizedBox(height: 16),
          if (lesson.scale case final scale?)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ScaleButton(scale: scale),
            ),
          if (lesson.tool case final tool?)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton.icon(
                key: const Key('lesson-open-tool'),
                icon: Icon(
                  tool == LessonTool.tuner ? Icons.tune : Icons.av_timer,
                ),
                label: Text(
                  tool == LessonTool.tuner
                      ? AppStrings.lessonOpenTuner
                      : AppStrings.lessonOpenMetronome(lesson.bpm),
                ),
                onPressed: () {
                  if (tool == LessonTool.metronome && lesson.bpm != null) {
                    ref
                        .read(metronomeViewModelProvider.notifier)
                        .setBpm(lesson.bpm!);
                  }
                  context.go(
                    tool == LessonTool.tuner ? '/tools/tuner' : '/tools/metronome',
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          _ToggleDoneButton(
            done: done,
            onPressed: () => ref
                .read(lessonsViewModelProvider.notifier)
                .toggleCompleted(lesson.id),
          ),
        ],
      ),
    );
  }
}

/// Completada: botón con borde para deshacer; pendiente: botón lleno.
class _ToggleDoneButton extends StatelessWidget {
  const _ToggleDoneButton({required this.done, required this.onPressed});

  final bool done;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const key = Key('lesson-toggle-done');
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(done ? AppStrings.lessonMarkPending : AppStrings.lessonMarkDone),
    );
    return done
        ? OutlinedButton(key: key, onPressed: onPressed, child: child)
        : FilledButton(key: key, onPressed: onPressed, child: child);
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      );
}

/// Una celda por corchea: flecha y conteo ("1 y 2 y…").
class _StrumPattern extends StatelessWidget {
  const _StrumPattern({required this.pattern});

  final String pattern;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final and = AppStrings.lessonStrumAnd;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final (i, stroke) in pattern.split('').indexed)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: stroke == ' '
                        ? p.surfaceHigh
                        : p.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        switch (stroke) {
                          'D' => '↓',
                          'U' => '↑',
                          _ => '—',
                        },
                        style: musicMono(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: stroke == ' ' ? p.textSecondary : p.accent,
                        ),
                      ),
                      Text(
                        i.isEven ? '${i ~/ 2 + 1}' : and,
                        style: musicMono(fontSize: 12, color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.lessonStrumHint,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: p.textSecondary),
        ),
      ],
    );
  }
}

/// Diagramas de los acordes de la lección; cada uno abre su ficha.
class _LessonChords extends ConsumerWidget {
  const _LessonChords({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reconstruye al terminar de cargar la biblioteca.
    ref.watch(chordViewModelProvider.select((s) => s.allChords.length));
    final vm = ref.read(chordViewModelProvider.notifier);
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final name in names)
              if (vm.findByName(name) case final chord?)
                InkWell(
                  key: Key('lesson-chord-$name'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.push(
                    '/learn/chords/${Uri.encodeComponent(chord.name)}',
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      children: [
                        Text(name, style: Theme.of(context).textTheme.titleMedium),
                        ChordDiagramWidget(
                          chordName: chord.name,
                          fretPositions: chord.fretPositions,
                          fingerPositions: chord.fingerPositions,
                          root: chord.root,
                          baseFret: chord.baseFret,
                          size: 110,
                          showChordName: false,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Chip(key: Key('lesson-chord-$name'), label: Text(name)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.lessonChordsHint,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: p.textSecondary),
        ),
      ],
    );
  }
}

/// Abre el detalle de la escala en la tónica de la lección.
class _ScaleButton extends ConsumerWidget {
  const _ScaleButton({required this.scale});

  final LessonScale scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definition = ref.watch(allScalesProvider).value?.where(
          (s) => s.id == scale.scaleId,
        ).firstOrNull;
    return OutlinedButton.icon(
      key: const Key('lesson-open-scale'),
      icon: const Icon(Icons.linear_scale),
      label: Text(AppStrings.lessonOpenScale),
      onPressed: definition == null
          ? null
          : () => context.push(
                '/learn/scales/${definition.id}?root=${scale.root}',
                extra: definition,
              ),
    );
  }
}
