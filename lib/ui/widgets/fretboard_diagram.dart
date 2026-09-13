import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../data/repository/scale_repository.dart';

class FretboardDiagram extends StatelessWidget {
  const FretboardDiagram({
    super.key,
    required this.pattern,
    this.rootColor = Colors.red,
    this.noteColor,
    this.height = 180,
  });

  final ResolvedPattern pattern;
  final Color rootColor;
  final Color? noteColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final startFret = pattern.startingFret;
    final endFret = pattern.endFret;
    final displayedFretCount = pattern.fretSpan;
    const stringCount = 6;

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final leftPad = 20.0;
          final top = 16.0;
          final fretWidth = (width - leftPad) / displayedFretCount;
          final stringSpacing = (height - top - 20) / (stringCount - 1);

          return Stack(
            children: [
              CustomPaint(
                size: Size(width, height),
                painter: _BoardPainter(
                  startFret: startFret,
                  endFret: endFret,
                  leftPad: leftPad,
                  top: top,
                  fretWidth: fretWidth,
                  stringSpacing: stringSpacing,
                  colorScheme: colorScheme,
                ),
              ),
              ...pattern.coordinates.map((coordinate) {
                final stringRow = coordinate.string - 1;
                final y = top + (stringRow * stringSpacing);
                final x = leftPad + ((coordinate.fret - startFret + 0.5) * fretWidth);
                return Positioned(
                  left: x - 10,
                  top: y - 10,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: coordinate.isRoot ? rootColor : (noteColor ?? colorScheme.primary),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      coordinate.interval,
                      style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  const _BoardPainter({
    required this.startFret,
    required this.endFret,
    required this.leftPad,
    required this.top,
    required this.fretWidth,
    required this.stringSpacing,
    required this.colorScheme,
  });

  final int startFret;
  final int endFret;
  final double leftPad;
  final double top;
  final double fretWidth;
  final double stringSpacing;
  final ColorScheme colorScheme;

  static const dotFrets = [3, 5, 7, 9, 15, 17, 19, 21];
  static const doubleDotFrets = [12, 24];

  @override
  void paint(Canvas canvas, Size size) {
    const stringLabels = ['e', 'B', 'G', 'D', 'A', 'E'];
    final boardRight = size.width;
    final boardBottom = top + 5 * stringSpacing;

    for (var i = 0; i < 6; i++) {
      final stringRow = i;
      final y = top + (stringRow * stringSpacing);
      final widthFactor = stringRow / (6 - 1);
      final strokeWidth = ui.lerpDouble(0.8, 2.4, widthFactor) ?? 1.2;
      final paint = Paint()
        ..color = colorScheme.onSurface.withAlpha(180)
        ..strokeWidth = strokeWidth;
      canvas.drawLine(Offset(leftPad, y), Offset(boardRight, y), paint);

      final tp = TextPainter(
        text: TextSpan(text: stringLabels[i], style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y - (tp.height / 2)));
    }

    for (var fret = startFret; fret <= endFret + 1; fret++) {
      final x = leftPad + ((fret - startFret) * fretWidth);
      final paint = Paint()
        ..color = colorScheme.outlineVariant
        ..strokeWidth = fret == 0 ? 2 : 1;
      canvas.drawLine(Offset(x, top - 8), Offset(x, boardBottom + 8), paint);
    }

    for (final fret in dotFrets) {
      if (fret < startFret || fret > endFret) continue;
      final x = leftPad + ((fret - startFret + 0.5) * fretWidth);
      final y = top + (2.5 * stringSpacing);
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = colorScheme.onSurfaceVariant.withAlpha(90));
    }

    for (final fret in doubleDotFrets) {
      if (fret < startFret || fret > endFret) continue;
      final x = leftPad + ((fret - startFret + 0.5) * fretWidth);
      canvas.drawCircle(Offset(x, top + (1.5 * stringSpacing)), 3, Paint()..color = colorScheme.onSurfaceVariant.withAlpha(90));
      canvas.drawCircle(Offset(x, top + (3.5 * stringSpacing)), 3, Paint()..color = colorScheme.onSurfaceVariant.withAlpha(90));
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) =>
      oldDelegate.startFret != startFret || oldDelegate.endFret != endFret;
}
