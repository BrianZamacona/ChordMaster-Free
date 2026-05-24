import 'dart:math' as math;
import 'dart:ui' as ui;

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
    this.viewportStartFret,
    this.viewportEndFret,
  }) : assert(
          viewportStartFret == null ||
              viewportEndFret == null ||
              viewportStartFret <= viewportEndFret,
          'viewportStartFret must be <= viewportEndFret',
        );

  /// Pattern containing the exact diagram coordinates.
  final ScalePattern pattern;

  /// Marker color for tonic/root notes.
  final Color rootColor;

  /// Marker color for non-root notes. Defaults to theme primary color.
  final Color? noteColor;

  /// Fixed widget height for stable diagram layout.
  final double height;

  /// Optional absolute fret where the viewport begins (inclusive).
  final int? viewportStartFret;

  /// Optional absolute fret where the viewport ends (inclusive).
  final int? viewportEndFret;

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
            viewportStartFret: viewportStartFret,
            viewportEndFret: viewportEndFret,
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
    required this.viewportStartFret,
    required this.viewportEndFret,
  });

  static const _minimumStringCount = 6;

  final ScalePattern pattern;
  final Color rootColor;
  final Color noteColor;
  final ColorScheme colorScheme;
  final int? viewportStartFret;
  final int? viewportEndFret;

  @override
  void paint(Canvas canvas, Size size) {
    final maxPatternString = pattern.coordinates.isEmpty
        ? _minimumStringCount
        : pattern.coordinates
            .map((coordinate) => coordinate.string)
            .reduce(math.max);
    final stringCount = math.max(_minimumStringCount, maxPatternString);

    final defaultStart = pattern.startingFret;
    final defaultEnd = pattern.startingFret + pattern.fretsSpan - 1;
    final startFret = viewportStartFret ?? defaultStart;
    final endFret = viewportEndFret ?? defaultEnd;
    final displayedFretCount = math.max(1, (endFret - startFret) + 1);

    const left = 16.0;
    const rightPadding = 16.0;
    const top = 16.0;
    const fretLabelArea = 24.0;
    const bottomPadding = 8.0;
    final right = size.width - rightPadding;
    final bottom = size.height - bottomPadding - fretLabelArea;
    final boardWidth = right - left;
    final boardHeight = bottom - top;

    final stringSpacing = stringCount <= 1 ? 0.0 : boardHeight / (stringCount - 1);
    final fretSpacing = boardWidth / displayedFretCount;

    final fretLinePaint = Paint()
      ..color = colorScheme.outline.withAlpha(220)
      ..strokeWidth = 1;

    final nutIncluded = startFret <= 0 && endFret >= 0;
    final nutPaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    for (var line = 0; line <= displayedFretCount; line++) {
      final fret = startFret + line;
      final x = left + (line * fretSpacing);
      final paint = nutIncluded && fret == 0 ? nutPaint : fretLinePaint;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }

    for (var stringIndex = 0; stringIndex < stringCount; stringIndex++) {
      final y = top + (stringIndex * stringSpacing);
      final widthFactor = stringCount <= 1 ? 0.0 : stringIndex / (stringCount - 1);
      final stringPaint = Paint()
        ..color = colorScheme.onSurface.withAlpha(180)
        ..strokeWidth = ui.lerpDouble(1.2, 2.0, widthFactor) ?? 1.2;
      canvas.drawLine(Offset(left, y), Offset(right, y), stringPaint);
    }

    final fretLabelStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurfaceVariant,
      letterSpacing: 0.2,
    );
    for (var fret = startFret; fret <= endFret; fret++) {
      final x = left + ((fret - startFret + 0.5) * fretSpacing);
      _drawCenteredText(
        canvas,
        '$fret',
        Offset(x, bottom + 10),
        fretLabelStyle,
      );
    }

    final markerRadius = math.min(stringSpacing, fretSpacing) * 0.24;
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(left, top, right, bottom));

    for (final coordinate in pattern.coordinates) {
      if (coordinate.fret < startFret || coordinate.fret > endFret) {
        continue;
      }

      final stringIndex = coordinate.string - 1;
      if (stringIndex < 0 || stringIndex >= stringCount) {
        continue;
      }

      final x = left + ((coordinate.fret - startFret + 0.5) * fretSpacing);
      final y = top + (stringIndex * stringSpacing);

      final markerPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = coordinate.isRoot ? rootColor : noteColor;

      canvas.drawCircle(Offset(x, y), markerRadius, markerPaint);
      if (coordinate.note.isNotEmpty) {
        _drawText(
          canvas,
          coordinate.note,
          Offset(x - markerRadius * 0.6, y - markerRadius * 0.5),
          coordinate.isRoot ? Colors.white : Colors.white,
          fontSize: markerRadius * 0.85,
        );
      }
    }
    canvas.restore();
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color,
      {double fontSize = 10}) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy),
    );
  }

  @override
  bool shouldRepaint(covariant _FretboardDiagramPainter oldDelegate) =>
      oldDelegate.pattern != pattern ||
      oldDelegate.rootColor != rootColor ||
      oldDelegate.noteColor != noteColor ||
      oldDelegate.colorScheme != colorScheme ||
      oldDelegate.viewportStartFret != viewportStartFret ||
      oldDelegate.viewportEndFret != viewportEndFret;
}
