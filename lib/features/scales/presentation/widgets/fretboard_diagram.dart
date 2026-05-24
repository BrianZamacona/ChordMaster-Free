import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/scale_pattern.dart';

/// Paints a fretboard using strict precomputed coordinates only.
class FretboardDiagram extends StatelessWidget {
  const FretboardDiagram({
    super.key,
    required this.pattern,
    this.rootColor = Colors.red,
    this.noteColor,
    this.height = 180,
  });

  /// Pattern containing the exact diagram coordinates.
  final ScalePattern pattern;

  /// Marker color for tonic/root notes.
  final Color rootColor;

  /// Marker color for non-root notes. Defaults to theme primary color.
  final Color? noteColor;

  /// Fixed widget height for stable diagram layout.
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _FretboardDiagramPainter(
            pattern: pattern,
            rootColor: rootColor,
            noteColor: noteColor ?? Theme.of(context).colorScheme.primary,
            colorScheme: Theme.of(context).colorScheme,
          ),
        ),
      );
}

class _FretboardDiagramPainter extends CustomPainter {
  const _FretboardDiagramPainter({
    required this.pattern,
    required this.rootColor,
    required this.noteColor,
    required this.colorScheme,
  });

  static const _stringCount = 6;

  final ScalePattern pattern;
  final Color rootColor;
  final Color noteColor;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 16.0;
    const rightPadding = 16.0;
    const top = 20.0;
    const bottomPadding = 16.0;

    final right = size.width - rightPadding;
    final bottom = size.height - bottomPadding;
    final width = right - left;
    final height = bottom - top;

    final stringSpacing = width / (_stringCount - 1);
    final fretSpacing = height / pattern.fretsSpan;

    final fretLinePaint = Paint()
      ..color = colorScheme.outline.withAlpha(220)
      ..strokeWidth = 1;

    for (var fret = 0; fret <= pattern.fretsSpan; fret++) {
      final y = top + (fret * fretSpacing);
      canvas.drawLine(Offset(left, y), Offset(right, y), fretLinePaint);
    }

    final stringPaint = Paint()
      ..color = colorScheme.onSurface.withAlpha(180)
      ..strokeWidth = 1.2;

    for (var stringIndex = 0; stringIndex < _stringCount; stringIndex++) {
      final x = left + (stringIndex * stringSpacing);
      canvas.drawLine(Offset(x, top), Offset(x, bottom), stringPaint);
    }

    _drawText(
      canvas,
      '${pattern.startingFret} fr',
      Offset(right + 4, top - 6),
      colorScheme.onSurfaceVariant,
    );

    final markerRadius = math.min(stringSpacing, fretSpacing) * 0.24;

    for (final coordinate in pattern.coordinates) {
      final fretOffset = coordinate.fret - pattern.startingFret;
      if (fretOffset < 0 || fretOffset >= pattern.fretsSpan) {
        continue;
      }

      final stringIndex = 6 - coordinate.string;
      if (stringIndex < 0 || stringIndex >= _stringCount) {
        continue;
      }

      final x = left + (stringIndex * stringSpacing);
      final y = top + ((fretOffset + 0.5) * fretSpacing);

      final markerPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = coordinate.isRoot ? rootColor : noteColor;

      canvas.drawCircle(Offset(x, y), markerRadius, markerPaint);
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _FretboardDiagramPainter oldDelegate) =>
      oldDelegate.pattern != pattern ||
      oldDelegate.rootColor != rootColor ||
      oldDelegate.noteColor != noteColor ||
      oldDelegate.colorScheme != colorScheme;
}
