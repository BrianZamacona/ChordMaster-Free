import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/lessons/lesson.dart';
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
/// cada nota, de izquierda a derecha, en renglones de [tabNotesPerLine]. Con
/// [showFingers], debajo va el dedo de cada nota ([tabFingers]) si la regla de
/// un dedo por traste alcanza.
class LessonTabView extends StatelessWidget {
  const LessonTabView({
    super.key,
    required this.notes,
    this.highlight,
    this.playedFrom = 0,
    this.played = 0,
    this.focusLine,
    this.showFingers = false,
  });

  final List<TabNote> notes;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: AppStrings.lessonTabLabel(
            [
              for (final (i, n) in notes.indexed)
                AppStrings.lessonTabNote(n.string, n.fret, finger: fingers?[i]),
            ].join(', '),
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
                    height: _TabPainter.height + (fingers == null ? 0 : _TabPainter.fingerRow),
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _TabPainter(
                        notes: line,
                        palette: p,
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
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: p.textSecondary),
        ),
      ],
    );
  }
}

class _TabPainter extends CustomPainter {
  const _TabPainter({
    required this.notes,
    required this.palette,
    this.highlight,
    this.playedFrom = 0,
    this.played = 0,
    this.fingers,
  });

  static const lineGap = 14.0;

  /// Alto de la fila de dedos, debajo de la 6ª cuerda.
  static const fingerRow = 16.0;
  static const top = 8.0;
  static const height = top * 2 + lineGap * 5;
  static const labelWidth = 18.0;

  final List<TabNote> notes;
  final AppPalette palette;

  /// Índice dentro de este renglón de la nota que suena.
  final int? highlight;

  /// Notas de este renglón ya tocadas bien: de [playedFrom] a [played].
  final int playedFrom;
  final int played;

  /// Dedo de cada nota de este renglón (`null` = al aire), o sin fila.
  final List<int?>? fingers;

  double _y(int string) => top + (string - 1) * lineGap;

  /// Centro de la nota [index]: todas las columnas del mismo ancho.
  double _x(int index, double width) {
    final cell = (width - labelWidth) / tabNotesPerLine;
    return labelWidth + cell * (index + 0.5);
  }

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
      final center = Offset(_x(i, size.width), _y(n.string));
      final playing = i == highlight;
      final done = !playing && i >= playedFrom && i < played;
      // Un hueco en la línea para que el número se lea; la nota que suena va
      // sobre el acento, y además más grande (no solo por color).
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: playing ? 22 : 18,
            height: playing ? 17 : 13,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = playing ? palette.accent : palette.surface,
      );
      _text(
        canvas,
        '${n.fret}',
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
      // El dedo, debajo de la 6ª cuerda, en la columna de su nota.
      if (fingers?[i] case final finger?) {
        _text(
          canvas,
          '$finger',
          Offset(_x(i, size.width), _y(6) + fingerRow - 2),
          playing ? palette.accent : palette.textSecondary,
          11,
          bold: playing,
        );
      }
    }
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
      old.palette != palette ||
      old.highlight != highlight ||
      old.playedFrom != playedFrom ||
      old.played != played ||
      !listEquals(old.fingers, fingers);
}
