import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A widget that renders a guitar chord diagram using a [CustomPainter].
///
/// Displays 6 strings, fret lines, a nut, finger positions as filled circles
/// with note names, and indicators for open/muted strings.
///
/// Example:
/// ```dart
/// ChordDiagramWidget(
///   chordName: 'Am',
///   fretPositions: [0, 0, 2, 2, 1, 0],
/// )
/// ```
class ChordDiagramWidget extends StatefulWidget {
  /// Creates a [ChordDiagramWidget].
  ///
  /// [fretPositions] must contain exactly 6 values where:
  /// - `-1` means the string is muted (X)
  /// - `0` means the string is open (O)
  /// - `1–22` means a fretted position
  const ChordDiagramWidget({
    super.key,
    required this.fretPositions,
    required this.chordName,
    this.size = 200.0,
  }) : assert(
         fretPositions.length == 6,
         'fretPositions must have exactly 6 values',
       );

  /// Fret positions for each string from low (E) to high (e).
  ///
  /// Values: `-1` = muted, `0` = open, `1–22` = fret number.
  final List<int> fretPositions;

  /// The chord name displayed above the diagram.
  final String chordName;

  /// The overall size of the diagram in logical pixels.
  final double size;

  @override
  State<ChordDiagramWidget> createState() => _ChordDiagramWidgetState();
}

class _ChordDiagramWidgetState extends State<ChordDiagramWidget> {
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: CustomPaint(
        key: ValueKey('${widget.chordName}-${widget.fretPositions.join(',')}'),
        size: Size(widget.size, widget.size * 1.25),
        painter: _ChordDiagramPainter(
          fretPositions: widget.fretPositions,
          chordName: widget.chordName,
        ),
      ),
    );
  }
}

/// [CustomPainter] responsible for drawing the chord diagram.
class _ChordDiagramPainter extends CustomPainter {
  const _ChordDiagramPainter({
    required this.fretPositions,
    required this.chordName,
  });

  final List<int> fretPositions;
  final String chordName;

  static const List<String> _stringNames = ['E', 'A', 'D', 'G', 'B', 'e'];
  static const int _fretsShown = 5;

  @override
  void paint(Canvas canvas, Size size) {
    // Layout constants
    final double topPadding = size.height * 0.18; // space for chord name + open/muted
    final double bottomPadding = size.height * 0.04;
    final double leftPadding = size.width * 0.10;
    final double rightPadding = size.width * 0.14; // space for fret number

    final double diagramWidth = size.width - leftPadding - rightPadding;
    final double diagramHeight = size.height - topPadding - bottomPadding;

    final double stringSpacing = diagramWidth / 5; // 6 strings = 5 gaps
    final double fretSpacing = diagramHeight / _fretsShown;

    // Determine fret offset (for barre chords)
    final int minFret = fretPositions
        .where((f) => f > 0)
        .fold(99, math.min);
    final int fretOffset = (minFret > 1 && minFret != 99) ? minFret - 1 : 0;

    // ── Chord name ─────────────────────────────────────────────────────────
    _drawText(
      canvas,
      chordName,
      Offset(size.width / 2, size.height * 0.04),
      fontSize: size.width * 0.13,
      bold: true,
      align: TextAlign.center,
    );

    // ── Nut or fret position indicator ─────────────────────────────────────
    final Paint nutPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = fretOffset == 0 ? fretSpacing * 0.22 : 2.0
      ..strokeCap = StrokeCap.square;

    final double nutY = topPadding;

    if (fretOffset == 0) {
      // Thick nut
      canvas.drawLine(
        Offset(leftPadding, nutY),
        Offset(leftPadding + diagramWidth, nutY),
        nutPaint,
      );
    } else {
      // Thin top line (no nut) + fret position label
      nutPaint.strokeWidth = 1.5;
      canvas.drawLine(
        Offset(leftPadding, nutY),
        Offset(leftPadding + diagramWidth, nutY),
        nutPaint,
      );
      _drawText(
        canvas,
        '${fretOffset + 1}fr',
        Offset(
          leftPadding + diagramWidth + size.width * 0.03,
          nutY + fretSpacing * 0.25,
        ),
        fontSize: size.width * 0.08,
        bold: false,
        color: Colors.black87,
      );
    }

    // ── Fret lines ──────────────────────────────────────────────────────────
    final Paint fretPaint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 1.0;

    for (int f = 1; f <= _fretsShown; f++) {
      final double y = nutY + f * fretSpacing;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(leftPadding + diagramWidth, y),
        fretPaint,
      );
    }

    // ── String lines ────────────────────────────────────────────────────────
    final Paint stringPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.2;

    for (int s = 0; s < 6; s++) {
      final double x = leftPadding + s * stringSpacing;
      canvas.drawLine(
        Offset(x, nutY),
        Offset(x, nutY + _fretsShown * fretSpacing),
        stringPaint,
      );
    }

    // ── Open / muted indicators above nut ──────────────────────────────────
    final double indicatorY = topPadding - fretSpacing * 0.55;

    for (int s = 0; s < 6; s++) {
      final double x = leftPadding + s * stringSpacing;
      final int fret = fretPositions[s];

      if (fret == 0) {
        // Open circle
        final Paint openPaint = Paint()
          ..color = Colors.black87
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(
          Offset(x, indicatorY),
          fretSpacing * 0.18,
          openPaint,
        );
      } else if (fret == -1) {
        // Muted X
        _drawText(
          canvas,
          'X',
          Offset(x, indicatorY),
          fontSize: fretSpacing * 0.38,
          bold: true,
          color: Colors.red,
          align: TextAlign.center,
          centered: true,
        );
      }
    }

    // ── Finger dots ─────────────────────────────────────────────────────────
    final Paint dotPaint = Paint()
      ..color = const Color(0xFF6200EE)
      ..style = PaintingStyle.fill;

    final double dotRadius = math.min(stringSpacing, fretSpacing) * 0.32;

    for (int s = 0; s < 6; s++) {
      final int fret = fretPositions[s];
      if (fret <= 0) continue;

      final int adjustedFret = fret - fretOffset;
      if (adjustedFret < 1 || adjustedFret > _fretsShown) continue;

      final double x = leftPadding + s * stringSpacing;
      final double y = nutY + (adjustedFret - 0.5) * fretSpacing;

      canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);

      // Note name inside circle
      _drawText(
        canvas,
        _stringNames[s],
        Offset(x, y),
        fontSize: dotRadius * 1.1,
        bold: true,
        color: Colors.white,
        align: TextAlign.center,
        centered: true,
      );
    }
  }

  /// Draws [text] at [offset] using a [TextPainter].
  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    double fontSize = 12.0,
    bool bold = false,
    Color color = Colors.black87,
    TextAlign align = TextAlign.left,
    bool centered = false,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout();

    final Offset drawOffset = centered
        ? Offset(
            offset.dx - textPainter.width / 2,
            offset.dy - textPainter.height / 2,
          )
        : offset;

    textPainter.paint(canvas, drawOffset);
  }

  @override
  bool shouldRepaint(_ChordDiagramPainter oldDelegate) {
    return oldDelegate.chordName != chordName ||
        oldDelegate.fretPositions.toString() != fretPositions.toString();
  }
}
