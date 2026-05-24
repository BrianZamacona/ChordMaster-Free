import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/scale_pattern.dart';

/// Paints a horizontal fretboard diagram (strings = horizontal, frets = vertical).
class FretboardDiagram extends StatelessWidget {
  const FretboardDiagram({
    super.key,
    required this.pattern,
    this.rootColor = Colors.red,
    this.noteColor,
    this.height = 180,
  });

  final ScalePattern pattern;
  final Color rootColor;
  final Color? noteColor;
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
    // ─── Márgenes ────────────────────────────────────────────────────────────
    const left        = 40.0;  // espacio para etiqueta "X fr"
    const rightPad    = 16.0;
    const top         = 12.0;
    const bottomPad   = 12.0;

    final right  = size.width  - rightPad;
    final bottom = size.height - bottomPad;
    final w      = right  - left;   // ancho útil  → eje de trastes
    final h      = bottom - top;    // alto útil   → eje de cuerdas

    // ─── Espaciados ──────────────────────────────────────────────────────────
    final fretSpacing   = w / pattern.fretsSpan;          // horizontal
    final stringSpacing = h / (_stringCount - 1);         // vertical

    // ─── Pintura base ────────────────────────────────────────────────────────
    final fretPaint = Paint()
      ..color       = colorScheme.outline.withAlpha(220)
      ..strokeWidth = 1.2;

    final stringPaint = Paint()
      ..color       = colorScheme.onSurface.withAlpha(180)
      ..strokeWidth = 1.4;

    // Trastes: líneas VERTICALES
    for (var fret = 0; fret <= pattern.fretsSpan; fret++) {
      final x = left + (fret * fretSpacing);
      canvas.drawLine(Offset(x, top), Offset(x, bottom), fretPaint);
    }

    // Cuerdas: líneas HORIZONTALES (cuerda 1 = high e abajo, cuerda 6 = low E arriba)
    for (var s = 0; s < _stringCount; s++) {
      final y = top + (s * stringSpacing);
      canvas.drawLine(Offset(left, y), Offset(right, y), stringPaint);
    }

    // ─── Etiqueta de posición (ej. "5 fr") ───────────────────────────────────
    _drawText(
      canvas,
      '${pattern.startingFret} fr',
      Offset(2, top + h / 2 - 6),
      colorScheme.onSurfaceVariant,
    );

    // ─── Marcadores de nota ───────────────────────────────────────────────────
    final markerRadius = math.min(fretSpacing, stringSpacing) * 0.30;

    for (final coord in pattern.coordinates) {
      final fretOffset = coord.fret - pattern.startingFret;
      if (fretOffset < 0 || fretOffset >= pattern.fretsSpan) continue;

      // string 1 = high e → fila inferior (s = 5), string 6 = low E → fila superior (s = 0)
      final stringRow = _stringCount - coord.string;
      if (stringRow < 0 || stringRow >= _stringCount) continue;

      final x = left + ((fretOffset + 0.5) * fretSpacing);  // centro del traste
      final y = top  + (stringRow * stringSpacing);           // fila de cuerda

      final markerPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = coord.isRoot ? rootColor : noteColor;

      canvas.drawCircle(Offset(x, y), markerRadius, markerPaint);

      // Borde blanco para que resalte sobre la línea de cuerda
      canvas.drawCircle(
        Offset(x, y),
        markerRadius,
        Paint()
          ..style       = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color       = colorScheme.surface.withAlpha(180),
      );
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
  bool shouldRepaint(covariant _FretboardDiagramPainter old) =>
      old.pattern    != pattern    ||
      old.rootColor  != rootColor  ||
      old.noteColor  != noteColor  ||
      old.colorScheme != colorScheme;
}