import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/lessons/curriculum.dart';
import '../../domain/lessons/lesson.dart';
import '../../domain/lessons/lesson_path.dart';
import '../../ui/theme.dart';
import '../ear_training/ear_training_viewmodel.dart';
import '../rhythm_games/rhythm_game_viewmodel.dart';
import 'lesson_widgets.dart';
import 'lessons_viewmodel.dart';

/// Mapa de lecciones dibujado como un mástil: Fundamentos es una sola
/// cuerda con sus unidades; al terminarla se abre en dos (rítmica y líder),
/// cada una con sus unidades y, al final, su reto (un marcador de traste).
class LessonsScreen extends ConsumerWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lessonsViewModelProvider);
    final path = state.path;
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.lessonsTitle)),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _NextCard(next: path.next),
                const SizedBox(height: 16),
                Center(
                  child: _TrackTitle(
                    track: LessonTrack.foundations,
                    path: path,
                    active: true,
                  ),
                ),
                for (final unit in unitsOf(LessonTrack.foundations)) ...[
                  const _StringSegment(active: true),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: _UnitNode(unit: unit, path: path),
                    ),
                  ),
                ],
                _Fork(chosen: path.chosen, open: path.foundationsDone),
                Text(
                  path.foundationsDone
                      ? AppStrings.lessonsChoosePath
                      : AppStrings.lessonsChooseLater,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: p.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, track)
                        in [LessonTrack.rhythm, LessonTrack.lead].indexed) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: _TrackColumn(track: track, path: path)),
                    ],
                  ],
                ),
              ],
            ),
    );
  }
}

class _NextCard extends StatelessWidget {
  const _NextCard({required this.next});

  final Lesson? next;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final lesson = next;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: lesson == null
            ? Text(AppStrings.lessonsAllDone, style: text.bodyLarge)
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.lessonsContinue.toUpperCase(),
                          style: text.labelSmall?.copyWith(
                            color: p.textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(lesson.title.text, style: text.titleMedium),
                        Text(
                          '${lesson.unit.title.text} · '
                          '${AppStrings.lessonMinutes(lesson.minutes)}',
                          style: text.bodySmall?.copyWith(color: p.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    key: const Key('lessons-start-next'),
                    onPressed: () => context.go('/learn/lessons/${lesson.id}'),
                    child: Text(AppStrings.lessonsStart),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Una columna del camino: título (tocarlo lo elige), unidades y reto.
class _TrackColumn extends ConsumerWidget {
  const _TrackColumn({required this.track, required this.path});

  final LessonTrack track;
  final LessonPath path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = path.chosen == track;
    return Column(
      children: [
        Semantics(
          button: true,
          selected: active,
          hint: AppStrings.lessonsTapTrack,
          child: InkWell(
            key: Key('lessons-track-${track.name}'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => ref.read(lessonsViewModelProvider.notifier).choose(track),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: _TrackTitle(track: track, path: path, active: active),
            ),
          ),
        ),
        for (final unit in unitsOf(track)) ...[
          _StringSegment(active: active),
          _UnitNode(unit: unit, path: path),
        ],
        for (final challenge in challengesOf(track)) ...[
          _StringSegment(active: active),
          _ChallengeNode(challenge: challenge),
        ],
      ],
    );
  }
}

class _TrackTitle extends StatelessWidget {
  const _TrackTitle({
    required this.track,
    required this.path,
    required this.active,
  });

  final LessonTrack track;
  final LessonPath path;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (done, total) = path.progressOf(track);
    return Column(
      children: [
        Text(
          trackName(track),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: active ? p.accent : p.textSecondary,
              ),
        ),
        Text(
          AppStrings.lessonsProgress(done, total),
          style: musicMono(fontSize: 12, color: p.textSecondary),
        ),
      ],
    );
  }
}

/// Tramo de cuerda entre dos nodos, cruzado por un traste.
class _StringSegment extends StatelessWidget {
  const _StringSegment({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: 36,
      width: double.infinity,
      child: CustomPaint(
        painter: _StringPainter(
          string: active ? p.fretString : p.outline,
          fret: p.fretWire,
        ),
      ),
    );
  }
}

class _StringPainter extends CustomPainter {
  const _StringPainter({required this.string, required this.fret});

  final Color string;
  final Color fret;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    canvas
      ..drawLine(
        Offset(x - 14, size.height / 2),
        Offset(x + 14, size.height / 2),
        Paint()
          ..color = fret
          ..strokeWidth = 2,
      )
      ..drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = string
          ..strokeWidth = 3,
      );
  }

  @override
  bool shouldRepaint(_StringPainter old) =>
      old.string != string || old.fret != fret;
}

/// Donde la cuerda de Fundamentos se abre en dos. La rama elegida va en el
/// color de cuerda; la otra, apagada.
class _Fork extends StatelessWidget {
  const _Fork({required this.chosen, required this.open});

  final LessonTrack chosen;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: CustomPaint(
        painter: _ForkPainter(
          trunk: p.fretString,
          left: chosen == LessonTrack.rhythm ? p.fretString : p.outline,
          right: chosen == LessonTrack.lead ? p.fretString : p.outline,
          knot: open ? p.accent : p.outline,
        ),
      ),
    );
  }
}

class _ForkPainter extends CustomPainter {
  const _ForkPainter({
    required this.trunk,
    required this.left,
    required this.right,
    required this.knot,
  });

  final Color trunk;
  final Color left;
  final Color right;
  final Color knot;

  @override
  void paint(Canvas canvas, Size size) {
    // Las columnas de abajo están separadas 12 px: sus centros quedan en
    // (ancho − 12) / 4 y en el simétrico.
    final mid = size.width / 2;
    final colCenter = (size.width - 12) / 4;
    final knotY = size.height * 0.3;
    Path branch(double toX) => Path()
      ..moveTo(mid, knotY)
      ..cubicTo(mid, size.height * 0.75, toX, size.height * 0.5, toX, size.height);
    Paint stroke(Color c) => Paint()
      ..color = c
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas
      ..drawLine(Offset(mid, 0), Offset(mid, knotY), stroke(trunk))
      ..drawPath(branch(colCenter), stroke(left))
      ..drawPath(branch(size.width - colCenter), stroke(right))
      ..drawCircle(Offset(mid, knotY), 6, Paint()..color = knot);
  }

  @override
  bool shouldRepaint(_ForkPainter old) =>
      old.trunk != trunk ||
      old.left != left ||
      old.right != right ||
      old.knot != knot;
}

/// Nodo de una unidad: su dibujo, el título y el avance.
class _UnitNode extends StatelessWidget {
  const _UnitNode({required this.unit, required this.path});

  final LessonUnit unit;
  final LessonPath path;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final lessons = lessonsOfUnit(unit);
    final done = lessons.where(path.isDone).length;
    final complete = done == lessons.length;
    final isCurrent = lessons.contains(path.next);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isCurrent ? p.accent : (complete ? p.success : p.outline),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: InkWell(
        key: Key('unit-${unit.id}'),
        onTap: () => context.go('/learn/lessons/unit/${unit.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
          child: Column(
            children: [
              UnitArtView(art: unit.art),
              const SizedBox(height: 8),
              Text(
                unit.title.text,
                textAlign: TextAlign.center,
                style: text.titleSmall,
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: done / lessons.length,
                color: complete ? p.success : p.accent,
                backgroundColor: p.surfaceHigh,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (complete) ...[
                    Icon(Icons.check, size: 14, color: p.success),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    AppStrings.lessonsProgress(done, lessons.length),
                    style: musicMono(fontSize: 12, color: p.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reto al final de un camino, marcado con el doble punto del traste 12.
/// Lee el récord del módulo de práctica y se supera solo.
class _ChallengeNode extends ConsumerWidget {
  const _ChallengeNode({required this.challenge});

  final LessonChallenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final (best, route, label) = switch (challenge.kind) {
      ChallengeKind.rhythmAccuracy => (
          ref.watch(rhythmGameViewModelProvider.select((s) => s.bestScore)),
          '/practice/rhythm',
          AppStrings.challengeRhythmBest,
        ),
      ChallengeKind.earStreak => (
          ref.watch(earTrainingViewModelProvider.select((s) => s.bestStreak)),
          '/practice/ear-training',
          AppStrings.challengeEarBest,
        ),
    };
    final passed = challenge.isPassed(best);
    final inlay = passed ? p.success : p.accent;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: inlay, width: 2),
      ),
      child: InkWell(
        key: Key('challenge-${challenge.id}'),
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 2; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: inlay,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                challenge.title.text,
                textAlign: TextAlign.center,
                style: text.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                challenge.body.text,
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: 6),
              Text(
                passed ? AppStrings.challengePassed : label(best, challenge.goal),
                key: Key('challenge-status-${challenge.id}'),
                textAlign: TextAlign.center,
                style: musicMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: passed ? p.success : p.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
