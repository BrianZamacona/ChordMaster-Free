import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/lessons/lesson.dart';
import '../../domain/theory/notes.dart';
import '../../ui/theme.dart';

/// Notas por renglón: a 360 dp caben sin apretarse.
const tabNotesPerLine = 8;

/// Nombre de cada cuerda en la tablatura, de la 1ª (arriba, minúscula como es
/// costumbre) a la 6ª. Sale de la afinación, no de una lista aparte.
List<String> get tabStringNames => [
  for (final (i, midi) in standardOpenStringMidi.indexed)
    if (i == 0) pitchClassName(midi).toLowerCase() else pitchClassName(midi),
];

/// Tablatura de una lección: seis líneas (la 1ª cuerda arriba) y el traste de
/// cada nota, de izquierda a derecha, en renglones de [tabNotesPerLine].
class LessonTabView extends StatelessWidget {
  const LessonTabView({super.key, required this.notes, this.highlight});

  final List<TabNote> notes;

  /// Nota que está sonando (índice en [notes]); va resaltada.
  final int? highlight;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final lines = [
      for (var i = 0; i < notes.length; i += tabNotesPerLine)
        notes.sublist(i, math.min(i + tabNotesPerLine, notes.length)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: AppStrings.lessonTabLabel(
            [for (final n in notes) AppStrings.lessonTabNote(n.string, n.fret)]
                .join(', '),
          ),
          excludeSemantics: true,
          child: Column(
            children: [
              for (final (i, line) in lines.indexed) ...[
                if (i > 0) const SizedBox(height: 8),
                SizedBox(
                  key: Key('lesson-tab-line-$i'),
                  height: _TabPainter.height,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _TabPainter(
                      notes: line,
                      palette: p,
                      highlight: highlight == null
                          ? null
                          : highlight! - i * tabNotesPerLine,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.lessonTabHint,
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
  });

  static const lineGap = 14.0;
  static const top = 8.0;
  static const height = top * 2 + lineGap * 5;
  static const labelWidth = 18.0;

  final List<TabNote> notes;
  final AppPalette palette;

  /// Índice dentro de este renglón de la nota que suena.
  final int? highlight;

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
      // Un hueco en la línea para que el número se lea.
      final playing = i == highlight;
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
        playing ? palette.onAccent : palette.textPrimary,
        playing ? 15 : 13,
        bold: true,
      );
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
      old.highlight != highlight;
}
