import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../data/models/scale_pattern.dart';

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

  final ScalePattern pattern;
  final Color rootColor;
  final Color? noteColor;
  final double height;
  final int? viewportStartFret;
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
            .map((c) => c.string)
            .reduce(math.max);
    final stringCount = math.max(_minimumStringCount, maxPatternString);

    final defaultStart = pattern.startingFret;
    final defaultEnd = pattern.startingFret + pattern.fretsSpan - 1;
    final startFret = viewportStartFret ?? defaultStart;
    final endFret = viewportEndFret ?? defaultEnd;
    final displayedFretCount = math.max(1, (endFret - startFret) + 1);

    // ─── Márgenes ────────────────────────────────────────────────────────────
    const left = 48.0;       // espacio para etiquetas de cuerda
    const rightPad = 16.0;
    const top = 16.0;
    const fretLabelArea = 24.0;
    const bottomPad = 8.0;

    final right = size.width - rightPad;
    final bottom = size.height - bottomPad - fretLabelArea;
    final boardWidth = right - left;
    final boardHeight = bottom - top;

    final stringSpacing =
        stringCount <= 1 ? 0.0 : boardHeight / (stringCount - 1);
    final fretSpacing = boardWidth / displayedFretCount;

    // ─── Marcadores de posición (dots) ───────────────────────────────────────
    const dotFrets = [3, 5, 7, 9, 12, 15, 17, 19, 21];
    const doubleDotFrets = [12, 24];
    final dotPaint = Paint()
      ..color = colorScheme.onSurfaceVariant.withAlpha(50)
      ..style = PaintingStyle.fill;

    for (final dotFret in dotFrets) {
      if (dotFret < startFret || dotFret > endFret) continue;
      final x = left + ((dotFret - startFret + 0.5) * fretSpacing);
      if (doubleDotFrets.contains(dotFret)) {
        canvas.drawCircle(
            Offset(x, top + stringSpacing * 1.5), 4, dotPaint);
        canvas.drawCircle(
            Offset(x, top + stringSpacing * 3.5), 4, dotPaint);
      } else {
        canvas.drawCircle(
            Offset(x, top + stringSpacing * 2.5), 4, dotPaint);
      }
    }

    // ─── Líneas de traste (verticales) ───────────────────────────────────────
    final fretLinePaint = Paint()
      ..color = colorScheme.outline.withAlpha(180)
      ..strokeWidth = 1.0;

    final nutPaint = Paint()
      ..color = colorScheme.onSurface.withAlpha(220)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    for (var line = 0; line <= displayedFretCount; line++) {
      final fret = startFret + line;
      final x = left + (line * fretSpacing);
      final paint = (startFret <= 0 && fret == 0) ? nutPaint : fretLinePaint;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }

    // ─── Cuerdas (horizontales) con grosor variable ───────────────────────────
    for (var si = 0; si < stringCount; si++) {
      final y = top + (si * stringSpacing);
      // cuerda 0 = low E (más gruesa), cuerda 5 = high e (más fina)
      final widthFactor =
          stringCount <= 1 ? 0.0 : si / (stringCount - 1);
      final stringPaint = Paint()
        ..color = colorScheme.onSurface.withAlpha(180)
        ..strokeWidth = ui.lerpDouble(2.0, 0.8, widthFactor) ?? 1.4;
      canvas.drawLine(Offset(left, y), Offset(right, y), stringPaint);
    }

    // ─── Etiquetas de cuerda (izquierda) ─────────────────────────────────────
    const stringLabels = ['E', 'A', 'D', 'G', 'B', 'e'];
    final labelStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurfaceVariant,
    );
    for (var si = 0; si < stringCount && si < stringLabels.length; si++) {
      final y = top + (si * stringSpacing);
      _drawCenteredText(
        canvas,
        stringLabels[si],
        Offset(left - 16, y - 5),
        labelStyle,
      );
    }

    // ─── Etiquetas de traste (abajo) ─────────────────────────────────────────
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
        Offset(x, bottom + 8),
        fretLabelStyle,
      );
    }

    // ─── Marcadores de nota ───────────────────────────────────────────────────
    final markerRadius = math.min(stringSpacing, fretSpacing) * 0.28;

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(left, top, right, bottom));

    for (final coordinate in pattern.coordinates) {
      if (coordinate.fret < startFret || coordinate.fret > endFret) continue;

      final stringIndex = coordinate.string - 1;
      if (stringIndex < 0 || stringIndex >= stringCount) continue;

      final x = left + ((coordinate.fret - startFret + 0.5) * fretSpacing);
      final y = top + (stringIndex * stringSpacing);

      // Sombra
      canvas.drawCircle(
        Offset(x + 0.5, y + 1),
        markerRadius,
        Paint()..color = Colors.black.withAlpha(60),
      );

      // Relleno principal  ← CORRECCIÓN: coordinate.isRoot (no coord.isRoot)
      final markerPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = coordinate.isRoot ? rootColor : noteColor;
      canvas.drawCircle(Offset(x, y), markerRadius, markerPaint);

      // Borde sutil
      canvas.drawCircle(
        Offset(x, y),
        markerRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = Colors.white.withAlpha(60),
      );

      // Texto dentro del marcador
      if (coordinate.note.isNotEmpty) {
        _drawCenteredText(
          canvas,
          coordinate.note,
          Offset(x, y - markerRadius * 0.45),
          TextStyle(
            fontSize: (markerRadius * 0.9).clamp(7.0, 13.0),
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        );
      }
    }

    canvas.restore();
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
  bool shouldRepaint(covariant _FretboardDiagramPainter old) =>
      old.pattern != pattern ||
      old.rootColor != rootColor ||
      old.noteColor != noteColor ||
      old.colorScheme != colorScheme ||
      old.viewportStartFret != viewportStartFret ||
      old.viewportEndFret != viewportEndFret;
}