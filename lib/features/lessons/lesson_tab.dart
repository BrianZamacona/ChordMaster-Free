import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/lessons/lesson.dart';
import '../../domain/practice/tab_notation.dart';
import '../../domain/practice/tab_playback.dart';
import '../../domain/theory/notes.dart';
import '../../ui/theme.dart';

/// Nombre de cada cuerda en la tablatura, de la 1ª (arriba, minúscula como es
/// costumbre) a la 6ª. Sale de la afinación, no de una lista aparte.
List<String> get tabStringNames => [
  for (final (i, midi) in standardOpenStringMidi.indexed)
    if (i == 0) pitchClassName(midi).toLowerCase() else pitchClassName(midi),
];

/// Tablatura de una lección: seis líneas (la 1ª cuerda arriba) y el traste de
/// cada nota, de izquierda a derecha, en renglones de [tabNotesPerLine].
///
/// Las marcas siguen la escritura de siempre: h, p, / \ y r entre la nota y
/// la anterior; b con los tonos y ~ junto a la nota; x = nota muerta; arriba, la
/// púa (⊓ V) y PM. Un silencio es una barrita entre la 3ª y la 4ª cuerda. Si
/// la tablatura trae ritmo propio ([tabHasRhythm]), debajo va el conteo
/// ("1 e y a") y, con [showFingers], el dedo de cada nota ([tabFingers]) si la
/// regla de un dedo por traste alcanza. Debajo se explican solo las marcas
/// que aparecen.
class LessonTabView extends StatelessWidget {
  const LessonTabView({
    super.key,
    required this.notes,
    this.swing = TabSwing.none,
    this.highlight,
    this.playedFrom = 0,
    this.played = 0,
    this.focusLine,
    this.showFingers = false,
  });

  final List<TabNote> notes;

  /// Con swing, el conteo lleva ritmo aunque todas sean corcheas.
  final TabSwing swing;

  /// Muestra el dedo de cada nota (si la mano no se mueve).
  final bool showFingers;

  /// Nota que está sonando o que toca tocar (índice en [notes]); va resaltada.
  final int? highlight;

  /// Las notas de [playedFrom] a [played] (sin incluirla) ya salieron bien al
  /// tocar con el micrófono: van en verde y subrayadas.
  final int playedFrom;
  final int played;

  /// El renglón que se practica suelto; los demás se ven atenuados.
  final int? focusLine;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final lines = [
      for (var i = 0; i < notes.length; i += tabNotesPerLine)
        notes.sublist(i, math.min(i + tabNotesPerLine, notes.length)),
    ];
    final all = showFingers ? tabFingers(notes) : null;
    final fingers = all != null && all.any((f) => f != null) ? all : null;
    final positions = tabPositions(notes);
    final layout = _TabLayout(
      top: notes.any((n) => n.pick != null || n.technique == TabTechnique.palmMute),
      count: tabHasRhythm(notes, swing: swing),
      fingers: fingers != null,
    );
    final count = (
      e: AppStrings.tabCountE,
      and: AppStrings.lessonStrumAnd,
      a: AppStrings.tabCountA,
    );
    final marks = tabMarksIn(notes);
    final secondary = Theme.of(context).textTheme.bodySmall?.copyWith(color: p.textSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: AppStrings.lessonTabLabel(
            [for (final (i, n) in notes.indexed) _spoken(n, fingers?[i])].join(', '),
          ),
          excludeSemantics: true,
          child: Column(
            children: [
              for (final (i, line) in lines.indexed) ...[
                if (i > 0) const SizedBox(height: 8),
                Opacity(
                  opacity: focusLine == null || focusLine == i ? 1 : 0.35,
                  child: SizedBox(
                    key: Key('lesson-tab-line-$i'),
                    height: layout.height,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _TabPainter(
                        notes: line,
                        previous: i == 0 ? null : notes[i * tabNotesPerLine - 1],
                        layout: layout,
                        palette: p,
                        counts: layout.count
                            ? [
                                for (final pos in positions.sublist(
                                  i * tabNotesPerLine,
                                  i * tabNotesPerLine + line.length,
                                ))
                                  tabCountAt(pos, e: count.e, and: count.and, a: count.a),
                              ]
                            : null,
                        highlight: highlight == null
                            ? null
                            : highlight! - i * tabNotesPerLine,
                        playedFrom: playedFrom - i * tabNotesPerLine,
                        played: played - i * tabNotesPerLine,
                        fingers: fingers?.sublist(
                          i * tabNotesPerLine,
                          math.min((i + 1) * tabNotesPerLine, notes.length),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          fingers == null
              ? AppStrings.lessonTabHint
              : '${AppStrings.lessonTabHint} ${AppStrings.lessonTabFingersHint}',
          key: const Key('lesson-tab-hint'),
          style: secondary,
        ),
        if (marks.isNotEmpty) ...[
          const SizedBox(height: 4),
          Column(
            key: const Key('lesson-tab-legend'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final m in TabMark.values)
                if (marks.contains(m)) Text(_legend(m), style: secondary),
            ],
          ),
        ],
      ],
    );
  }
}

/// La nota en palabras (lector de pantalla).
String _spoken(TabNote n, int? finger) {
  if (n.isRest) return AppStrings.lessonTabRest;
  final technique = switch (n.technique) {
    TabTechnique.none => null,
    TabTechnique.hammerOn => AppStrings.tabSpokenHammerOn,
    TabTechnique.pullOff => AppStrings.tabSpokenPullOff,
    TabTechnique.slide => AppStrings.tabSpokenSlide,
    TabTechnique.bend => AppStrings.tabSpokenBend(n.bend),
    TabTechnique.release => AppStrings.tabSpokenRelease,
    TabTechnique.vibrato => AppStrings.tabSpokenVibrato,
    TabTechnique.palmMute => AppStrings.tabSpokenPalmMute,
    TabTechnique.dead => AppStrings.tabSpokenDead,
  };
  final pick = switch (n.pick) {
    null => null,
    PickStroke.down => AppStrings.tabSpokenDown,
    PickStroke.up => AppStrings.tabSpokenUp,
  };
  return [
    AppStrings.lessonTabNote(n.string, n.fret, finger: finger),
    ?technique,
    ?pick,
  ].join(' ');
}

String _legend(TabMark m) => switch (m) {
  TabMark.rest => AppStrings.tabLegendRest,
  TabMark.hammerOn => AppStrings.tabLegendHammerOn,
  TabMark.pullOff => AppStrings.tabLegendPullOff,
  TabMark.slide => AppStrings.tabLegendSlide,
  TabMark.bend => AppStrings.tabLegendBend,
  TabMark.release => AppStrings.tabLegendRelease,
  TabMark.vibrato => AppStrings.tabLegendVibrato,
  TabMark.palmMute => AppStrings.tabLegendPalmMute,
  TabMark.dead => AppStrings.tabLegendDead,
  TabMark.pick => AppStrings.tabLegendPick,
};

/// Qué filas lleva cada renglón: arriba (púa y PM), las seis cuerdas,
/// el conteo y los dedos. Todos los renglones de una tablatura, iguales.
@immutable
class _TabLayout {
  const _TabLayout({required this.top, required this.count, required this.fingers});

  final bool top;
  final bool count;
  final bool fingers;

  static const lineGap = 14.0;
  static const margin = 8.0;
  static const topRow = 14.0;
  static const countRow = 14.0;
  static const fingerRow = 16.0;

  double get firstString => (top ? topRow : 0) + margin;
  double get lastString => firstString + lineGap * 5;
  double get countY => lastString + margin + countRow / 2;
  double get fingerY => lastString + (count ? countRow : 0) + fingerRow - 2;

  double get height =>
      lastString + margin + (count ? countRow : 0) + (fingers ? fingerRow : 0);

  @override
  bool operator ==(Object other) =>
      other is _TabLayout && other.top == top && other.count == count && other.fingers == fingers;

  @override
  int get hashCode => Object.hash(top, count, fingers);
}

class _TabPainter extends CustomPainter {
  const _TabPainter({
    required this.notes,
    required this.layout,
    required this.palette,
    this.previous,
    this.counts,
    this.highlight,
    this.playedFrom = 0,
    this.played = 0,
    this.fingers,
  });

  static const labelWidth = 18.0;

  final List<TabNote> notes;
  final _TabLayout layout;
  final AppPalette palette;

  /// La última nota del renglón anterior (para un ligado al empezar este).
  final TabNote? previous;

  /// Conteo de cada nota de este renglón, o sin fila.
  final List<String>? counts;

  /// Índice dentro de este renglón de la nota que suena.
  final int? highlight;

  /// Notas de este renglón ya tocadas bien: de [playedFrom] a [played].
  final int playedFrom;
  final int played;

  /// Dedo de cada nota de este renglón (`null` = al aire), o sin fila.
  final List<int?>? fingers;

  double _y(int string) => layout.firstString + (string - 1) * _TabLayout.lineGap;

  double _cell(double width) => (width - labelWidth) / tabNotesPerLine;

  /// Centro de la nota [index]: todas las columnas del mismo ancho.
  double _x(int index, double width) => labelWidth + _cell(width) * (index + 0.5);

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = palette.fretString
      ..strokeWidth = 1;
    for (final (i, name) in tabStringNames.indexed) {
      final y = _y(i + 1);
      canvas.drawLine(Offset(labelWidth, y), Offset(size.width, y), line);
      _text(canvas, name, Offset(labelWidth / 2, y), palette.textSecondary, 11);
    }
    for (final (i, n) in notes.indexed) {
      final x = _x(i, size.width);
      final playing = i == highlight;
      final done = !playing && i >= playedFrom && i < played;
      if (n.isRest) {
        _rest(canvas, x, playing);
      } else {
        _note(canvas, n, x, playing: playing, done: done);
        _marks(canvas, n, i == 0 ? previous : notes[i - 1], x, size.width, playing);
      }
      if (counts?[i] case final count?) {
        _text(
          canvas,
          count,
          Offset(x, layout.countY),
          playing ? palette.accent : palette.textSecondary,
          11,
          bold: playing || !count.contains(RegExp('[a-z&]')),
        );
      }
      // El dedo, debajo de todo, en la columna de su nota.
      if (fingers?[i] case final finger?) {
        _text(
          canvas,
          '$finger',
          Offset(x, layout.fingerY),
          playing ? palette.accent : palette.textSecondary,
          11,
          bold: playing,
        );
      }
    }
  }

  /// El número del traste (x en una nota muerta) sobre un hueco en la línea;
  /// la que suena va sobre el acento y más grande (no solo por color).
  void _note(Canvas canvas, TabNote n, double x, {required bool playing, required bool done}) {
    final center = Offset(x, _y(n.string));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: playing ? 22 : 18, height: playing ? 17 : 13),
        const Radius.circular(4),
      ),
      Paint()..color = playing ? palette.accent : palette.surface,
    );
    _text(
      canvas,
      n.technique == TabTechnique.dead ? 'x' : '${n.fret}',
      center,
      playing ? palette.onAccent : (done ? palette.success : palette.textPrimary),
      playing ? 15 : 13,
      bold: true,
    );
    if (done) {
      // Hecha: además del color, una raya debajo (no solo color).
      canvas.drawLine(
        center + const Offset(-6, 8),
        center + const Offset(6, 8),
        Paint()
          ..color = palette.success
          ..strokeWidth = 2,
      );
    }
  }

  /// Silencio: una barrita entre la 3ª y la 4ª cuerda.
  void _rest(Canvas canvas, double x, bool playing) {
    final y = (_y(3) + _y(4)) / 2;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(x, y), width: 12, height: 5),
      Paint()..color = playing ? palette.accent : palette.textSecondary,
    );
  }

  void _marks(Canvas canvas, TabNote n, TabNote? before, double x, double width, bool playing) {
    final color = playing ? palette.accent : palette.textSecondary;
    final y = _y(n.string);
    // Ligados: la letra entre las dos notas, justo encima de la cuerda.
    if (n.technique.legato) {
      final letter = switch (n.technique) {
        TabTechnique.hammerOn => 'h',
        TabTechnique.pullOff => 'p',
        TabTechnique.release => 'r',
        _ => before != null && n.fret < before.fret ? r'\' : '/',
      };
      _text(canvas, letter, Offset(x - _cell(width) / 2, y - 7), color, 11, bold: true);
    }
    const top = _TabLayout.topRow / 2 + 2;
    switch (n.technique) {
      case TabTechnique.bend:
        // Al lado del traste, sobre un hueco en la línea (como el número).
        final text = 'b${AppStrings.tabBendAmount(n.bend)}';
        final label = Offset(x + 10 + 3.25 * text.length, y);
        canvas.drawRect(
          Rect.fromCenter(center: label, width: 6.5 * text.length + 2, height: 11),
          Paint()..color = palette.surface,
        );
        _text(canvas, text, label, color, 10, bold: true);
      case TabTechnique.vibrato:
        _text(canvas, '~', Offset(x + 13, y), color, 13, bold: true);
      case TabTechnique.palmMute:
        _text(canvas, 'PM', Offset(n.pick == null ? x : x - 7, top), color, 9, bold: true);
      default:
    }
    if (n.pick case final pick?) {
      _pick(canvas, pick, Offset(n.technique == TabTechnique.palmMute ? x + 9 : x, top), color);
    }
  }

  /// ⊓ abajo y V arriba, dibujados (la fuente no los trae).
  void _pick(Canvas canvas, PickStroke pick, Offset c, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final path = Path();
    if (pick == PickStroke.down) {
      path
        ..moveTo(c.dx - 4, c.dy + 4)
        ..lineTo(c.dx - 4, c.dy - 3)
        ..lineTo(c.dx + 4, c.dy - 3)
        ..lineTo(c.dx + 4, c.dy + 4);
    } else {
      path
        ..moveTo(c.dx - 4, c.dy - 4)
        ..lineTo(c.dx, c.dy + 4)
        ..lineTo(c.dx + 4, c.dy - 4);
    }
    canvas.drawPath(path, paint);
  }

  void _text(
    Canvas canvas,
    String text,
    Offset center,
    Color color,
    double size, {
    bool bold = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: musicMono(
          fontSize: size,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(_TabPainter old) =>
      !identical(old.notes, notes) ||
      old.previous != previous ||
      old.layout != layout ||
      old.palette != palette ||
      old.highlight != highlight ||
      old.playedFrom != playedFrom ||
      old.played != played ||
      !listEquals(old.counts, counts) ||
      !listEquals(old.fingers, fingers);
}
