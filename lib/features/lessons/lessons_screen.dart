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
/// cada una con sus unidades por nivel y, al cerrar cada nivel, su reto (un
/// marcador de traste). Al abrir, las cuerdas se dibujan de arriba abajo; con
/// "reducir movimiento" aparecen ya completas.
class LessonsScreen extends ConsumerStatefulWidget {
  const LessonsScreen({super.key});

  @override
  ConsumerState<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends ConsumerState<LessonsScreen>
    with SingleTickerProviderStateMixin {
  static const _revealDuration = Duration(milliseconds: 1400);

  late final _reveal = AnimationController(
    vsync: this,
    duration: _revealDuration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _reveal.value = 1;
    } else if (_reveal.isDismissed) {
      _reveal.forward();
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lessonsViewModelProvider);
    final path = state.path;
    final p = context.palette;
    var order = 0;
    Widget segment() =>
        _StringSegment(active: true, reveal: _revealAt(_reveal, order++));
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
                  segment(),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: _UnitNode(unit: unit, path: path),
                    ),
                  ),
                ],
                segment(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    path.foundationsDone
                        ? AppStrings.lessonsChoosePath
                        : AppStrings.lessonsChooseLater,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: p.textSecondary),
                  ),
                ),
                _Fork(
                  highlighted: state.highlightedTrack,
                  open: path.foundationsDone,
                ),
                _TrackRows(
                  highlighted: state.highlightedTrack,
                  path: path,
                  reveal: _reveal,
                  firstOrder: order,
                ),
              ],
            ),
    );
  }
}

/// Separación entre las columnas de los dos caminos.
const double _columnGap = 12;

/// Tramo [order] de la cuerda: cada uno empieza un poco después del anterior.
Animation<double> _revealAt(Animation<double> parent, int order) {
  final start = (order * 0.06).clamp(0.0, 0.8);
  return CurvedAnimation(
    parent: parent,
    curve: Interval(start, start + 0.2, curve: Curves.easeOut),
  );
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

/// Los dos caminos, fila por fila y nivel por nivel: cada fila tiene un nodo
/// de cada camino a la misma altura, y cada nivel cierra con un reto. Un test
/// exige que, en cada nivel, ambos tengan tantas unidades como retos.
class _TrackRows extends StatelessWidget {
  const _TrackRows({
    required this.highlighted,
    required this.path,
    required this.reveal,
    required this.firstOrder,
  });

  final LessonTrack? highlighted;
  final LessonPath path;
  final Animation<double> reveal;

  /// Orden de dibujo del primer tramo de estas filas.
  final int firstOrder;

  /// Una fila con una celda por camino, ambas de la altura de la mayor.
  Widget _row(Widget Function(LessonTrack track) cell) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: cell(LessonTrack.rhythm)),
            const SizedBox(width: _columnGap),
            Expanded(child: cell(LessonTrack.lead)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    var order = firstOrder;
    Widget segments() {
      final animation = _revealAt(reveal, order++);
      return _row(
        (track) => _StringSegment(
          active: track == highlighted,
          reveal: animation,
        ),
      );
    }

    return Column(
      children: [
        _row(
          (track) => _TrackHeader(
            track: track,
            path: path,
            active: track == highlighted,
          ),
        ),
        for (final level in levelsOf(LessonTrack.rhythm)) ...[
          if (level > 1) ...[segments(), _LevelHeader(level: level)],
          for (var i = 0;
              i < unitsOf(LessonTrack.rhythm, level: level).length;
              i++) ...[
            segments(),
            _row(
              (track) => _UnitNode(
                unit: unitsOf(track, level: level)[i],
                path: path,
              ),
            ),
          ],
          for (var i = 0;
              i < challengesOf(LessonTrack.rhythm, level: level).length;
              i++) ...[
            segments(),
            _row(
              (track) => _ChallengeNode(
                challenge: challengesOf(track, level: level)[i],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// Separa los niveles de los dos caminos, a todo lo ancho.
class _LevelHeader extends StatelessWidget {
  const _LevelHeader({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      key: Key('lessons-level-$level'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: p.outline)),
          Flexible(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Text(
                    AppStrings.lessonsLevel(level),
                    style: text.titleMedium?.copyWith(color: p.accent),
                  ),
                  Text(
                    AppStrings.lessonsLevelHint,
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(color: p.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: Divider(color: p.outline)),
        ],
      ),
    );
  }
}

/// Título de un camino en su columna; tocarlo lo elige.
class _TrackHeader extends ConsumerWidget {
  const _TrackHeader({
    required this.track,
    required this.path,
    required this.active,
  });

  final LessonTrack track;
  final LessonPath path;
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Semantics(
        button: true,
        selected: active,
        hint: AppStrings.lessonsTapTrack,
        child: InkWell(
          key: Key('lessons-track-${track.name}'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => ref.read(lessonsViewModelProvider.notifier).choose(track),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: _TrackTitle(
              track: track,
              path: path,
              active: active,
              compact: true,
            ),
          ),
        ),
      );
}

class _TrackTitle extends StatelessWidget {
  const _TrackTitle({
    required this.track,
    required this.path,
    required this.active,
    this.compact = false,
  });

  final LessonTrack track;
  final LessonPath path;
  final bool active;

  /// Título más pequeño, para que quepa en media pantalla.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final (done, total) = path.progressOf(track);
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          trackName(track),
          textAlign: TextAlign.center,
          style: (compact ? text.titleMedium : text.titleLarge)?.copyWith(
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

/// Tramo de cuerda entre dos nodos, cruzado por un traste. [reveal] va de 0
/// a 1 mientras la cuerda se dibuja hacia abajo.
class _StringSegment extends StatelessWidget {
  const _StringSegment({required this.active, required this.reveal});

  final bool active;
  final Animation<double> reveal;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: 36,
      width: double.infinity,
      child: CustomPaint(
        painter: _StringPainter(
          string: active ? p.fretString : p.stringMuted,
          fret: p.fretWire,
          reveal: reveal,
        ),
      ),
    );
  }
}

class _StringPainter extends CustomPainter {
  _StringPainter({
    required this.string,
    required this.fret,
    required this.reveal,
  }) : super(repaint: reveal);

  final Color string;
  final Color fret;
  final Animation<double> reveal;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final t = reveal.value;
    if (t <= 0) return;
    canvas
      ..drawLine(
        Offset(x - 40 * t, size.height / 2),
        Offset(x + 40 * t, size.height / 2),
        Paint()
          ..color = fret
          ..strokeWidth = 1.5,
      )
      ..drawLine(
        Offset(x, 0),
        Offset(x, size.height * t),
        Paint()
          ..color = string
          ..strokeWidth = 3,
      );
  }

  @override
  bool shouldRepaint(_StringPainter old) =>
      old.string != string || old.fret != fret || old.reveal != reveal;
}

/// Donde la cuerda de Fundamentos se abre en dos. La rama resaltada va en el
/// color de cuerda; la otra, apagada.
class _Fork extends StatelessWidget {
  const _Fork({required this.highlighted, required this.open});

  final LessonTrack? highlighted;
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
          left: highlighted == LessonTrack.rhythm ? p.fretString : p.stringMuted,
          right: highlighted == LessonTrack.lead ? p.fretString : p.stringMuted,
          knot: open ? p.accent : p.stringMuted,
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
    // Los centros de las columnas de abajo quedan en (ancho − separación) / 4
    // y en el simétrico.
    final mid = size.width / 2;
    final colCenter = (size.width - _columnGap) / 4;
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
      // Sin margen: la cuerda llega hasta el borde de la tarjeta.
      margin: EdgeInsets.zero,
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
          // En una fila más alta, el avance queda abajo, alineado con el vecino.
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UnitArtView(art: unit.art),
                  const SizedBox(height: 8),
                  Text(
                    unit.title.text,
                    textAlign: TextAlign.center,
                    style: text.titleSmall,
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
      margin: EdgeInsets.zero,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
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
                ],
              ),
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
