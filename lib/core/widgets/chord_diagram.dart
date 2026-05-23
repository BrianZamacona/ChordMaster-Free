import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// A widget that renders a guitar chord diagram using a [CustomPainter].
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
    this.showChordName = true,
    this.baseFret,
  }) : assert(
          fretPositions.length == 6,
          'fretPositions must have exactly 6 values',
        );

  /// Fret positions for each string from low (E) to high (e).
  final List<int> fretPositions;

  /// The chord name displayed above the diagram when [showChordName] is true.
  final String chordName;

  /// The overall size of the diagram in logical pixels.
  final double size;

  /// Whether to render the chord name above the diagram.
  final bool showChordName;

  /// Optional explicit base fret for movable voicings.
  final int? baseFret;

  @override
  State<ChordDiagramWidget> createState() => _ChordDiagramWidgetState();
}

class _ChordDiagramWidgetState extends State<ChordDiagramWidget> {
  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: CustomPaint(
          key: ValueKey(
            '${widget.chordName}-${widget.fretPositions.join(',')}-${widget.showChordName}-${widget.baseFret}',
          ),
          size: Size(widget.size, widget.size * 1.25),
          painter: _ChordDiagramPainter(
            fretPositions: widget.fretPositions,
            chordName: widget.chordName,
            showChordName: widget.showChordName,
            baseFret: widget.baseFret,
            colorScheme: Theme.of(context).colorScheme,
          ),
        ),
      );
}

/// [CustomPainter] responsible for drawing the chord diagram.
class _ChordDiagramPainter extends CustomPainter {
  const _ChordDiagramPainter({
    required this.fretPositions,
    required this.chordName,
    required this.showChordName,
    required this.baseFret,
    required this.colorScheme,
  });

  final List<int> fretPositions;
  final String chordName;
  final bool showChordName;
  final int? baseFret;
  final ColorScheme colorScheme;

  static const int _fretsShown = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final topPadding = showChordName ? size.height * 0.18 : size.height * 0.11;
    final bottomPadding = size.height * 0.04;
    final leftPadding = size.width * 0.10;
    final rightPadding = size.width * 0.14;

    final diagramWidth = size.width - leftPadding - rightPadding;
    final diagramHeight = size.height - topPadding - bottomPadding;
    final stringSpacing = diagramWidth / 5;
    final fretSpacing = diagramHeight / _fretsShown;

    final positiveFrets = fretPositions.where((fret) => fret > 0).toList(growable: false);
    final detectedMinFret = positiveFrets.isEmpty
        ? 1
        : positiveFrets.reduce(math.min);
    final effectiveBaseFret = baseFret ?? (detectedMinFret > 1 ? detectedMinFret : 1);
    final fretOffset = effectiveBaseFret > 1 ? effectiveBaseFret - 1 : 0;

    if (showChordName) {
      _drawText(
        canvas,
        chordName,
        Offset(size.width / 2, size.height * 0.04),
        fontSize: size.width * 0.13,
        bold: true,
        align: TextAlign.center,
        centered: true,
      );
    }

    final nutPaint = Paint()
      ..color = colorScheme.onSurface
      ..strokeWidth = fretOffset == 0 ? fretSpacing * 0.22 : 2.0
      ..strokeCap = StrokeCap.square;

    final nutY = topPadding;

    if (fretOffset == 0) {
      canvas.drawLine(
        Offset(leftPadding, nutY),
        Offset(leftPadding + diagramWidth, nutY),
        nutPaint,
      );
    } else {
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
      );
    }

    final fretPaint = Paint()
      ..color = colorScheme.outline
      ..strokeWidth = 1.0;

    for (var fret = 1; fret <= _fretsShown; fret++) {
      final y = nutY + fret * fretSpacing;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(leftPadding + diagramWidth, y),
        fretPaint,
      );
    }

    final stringPaint = Paint()
      ..color = colorScheme.onSurface.withAlpha(190)
      ..strokeWidth = 1.2;

    for (var stringIndex = 0; stringIndex < 6; stringIndex++) {
      final x = leftPadding + stringIndex * stringSpacing;
      canvas.drawLine(
        Offset(x, nutY),
        Offset(x, nutY + _fretsShown * fretSpacing),
        stringPaint,
      );
    }

    final indicatorY = topPadding - fretSpacing * 0.55;

    for (var stringIndex = 0; stringIndex < 6; stringIndex++) {
      final x = leftPadding + stringIndex * stringSpacing;
      final fret = fretPositions[stringIndex];

      if (fret == 0) {
        final openPaint = Paint()
          ..color = colorScheme.onSurface
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(
          Offset(x, indicatorY),
          fretSpacing * 0.18,
          openPaint,
        );
      } else if (fret == -1) {
        _drawText(
          canvas,
          'X',
          Offset(x, indicatorY),
          fontSize: fretSpacing * 0.38,
          bold: true,
          color: AppColors.error,
          align: TextAlign.center,
          centered: true,
        );
      }
    }

    final dotPaint = Paint()
      ..color = AppColors.chords
      ..style = PaintingStyle.fill;

    final dotRadius = math.min(stringSpacing, fretSpacing) * 0.32;

    for (var stringIndex = 0; stringIndex < 6; stringIndex++) {
      final fret = fretPositions[stringIndex];
      if (fret <= 0) continue;

      final adjustedFret = fret - fretOffset;
      if (adjustedFret < 1 || adjustedFret > _fretsShown) continue;

      final x = leftPadding + stringIndex * stringSpacing;
      final y = nutY + (adjustedFret - 0.5) * fretSpacing;

      canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    double fontSize = 12.0,
    bool bold = false,
    Color? color,
    TextAlign align = TextAlign.left,
    bool centered = false,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color ?? colorScheme.onSurface,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout();

    final drawOffset = centered
        ? Offset(
            offset.dx - textPainter.width / 2,
            offset.dy - textPainter.height / 2,
          )
        : offset;

    textPainter.paint(canvas, drawOffset);
  }

  @override
  bool shouldRepaint(_ChordDiagramPainter oldDelegate) =>
      oldDelegate.chordName != chordName ||
      oldDelegate.showChordName != showChordName ||
      oldDelegate.baseFret != baseFret ||
      oldDelegate.colorScheme != colorScheme ||
      oldDelegate.fretPositions.toString() != fretPositions.toString();
}
