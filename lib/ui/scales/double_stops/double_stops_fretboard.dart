import 'package:flutter/material.dart';

import '../../../domain/theory/double_stops.dart';
import 'double_stops_layout.dart';

const _romanNumerals = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];

String degreeNumeral(int? degree) =>
    degree == null ? '' : _romanNumerals[degree - 1];

/// Blanco sobre el rojo de la raíz; `onPrimary` sobre el color de las notas intervalo.
// ignore: avoid_positional_boolean_parameters
Color noteTextColor(bool isRoot, ColorScheme colorScheme) =>
    isRoot ? Colors.white : colorScheme.onPrimary;

/// Diapasón con las parejas de un par de cuerdas; notas y líneas se pintan en
/// un mismo lienzo con las coordenadas de [noteOffset].
class DoubleStopFretboard extends StatelessWidget {
  const DoubleStopFretboard({
    super.key,
    required this.pairs,
    required this.range,
    this.height = 170,
  });

  final List<DoubleStopPair> pairs;
  final FretRange range;
  final double height;

  int get fretCount => range.end - range.start + 1;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: LayoutBuilder(
      builder: (context, constraints) => CustomPaint(
        size: Size(constraints.maxWidth, height),
        painter: DoubleStopPainter(
          pairs: pairs,
          startFret: range.start,
          fretCount: fretCount,
          colorScheme: Theme.of(context).colorScheme,
        ),
      ),
    ),
  );
}

class DoubleStopPainter extends CustomPainter {
  const DoubleStopPainter({
    required this.pairs,
    required this.startFret,
    required this.fretCount,
    required this.colorScheme,
  });

  final List<DoubleStopPair> pairs;
  final int startFret;
  final int fretCount;
  final ColorScheme colorScheme;

  static const _dotFrets = [3, 5, 7, 9, 15, 17, 19, 21];

  void _text(Canvas canvas, String text, Offset center, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const stringNames = ['e', 'B', 'G', 'D', 'A', 'E'];
    Offset at(int s, int f) =>
        noteOffset(s, f, size, startFret: startFret, fretCount: fretCount);

    final fretWidth = (size.width - fretboardLeftPad) / fretCount;
    final top = at(0, startFret).dy;
    final bottom = at(5, startFret).dy;

    final stringPaint = Paint()..color = colorScheme.onSurface.withAlpha(180);
    for (var s = 0; s < 6; s++) {
      final y = at(s, startFret).dy;
      canvas.drawLine(
        Offset(fretboardLeftPad, y),
        Offset(size.width, y),
        stringPaint..strokeWidth = 0.8 + 1.6 * s / 5,
      );
      _text(
        canvas,
        stringNames[s],
        Offset(8, y),
        TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
      );
    }

    final fretPaint = Paint()..color = colorScheme.outlineVariant;
    for (var i = 0; i <= fretCount; i++) {
      final x = fretboardLeftPad + i * fretWidth;
      canvas.drawLine(Offset(x, top - 8), Offset(x, bottom + 8), fretPaint);
    }
    for (var f = startFret; f < startFret + fretCount; f++) {
      final x = at(0, f).dx;
      if (_dotFrets.contains(f) || f == 12 || f == 24) {
        canvas.drawCircle(
          Offset(x, (top + bottom) / 2),
          3,
          Paint()..color = colorScheme.onSurfaceVariant.withAlpha(90),
        );
      }
      _text(
        canvas,
        '$f',
        Offset(x, bottom + 16),
        TextStyle(fontSize: 8, color: colorScheme.onSurfaceVariant),
      );
    }

    final linePaint = Paint()
      ..color = colorScheme.tertiary
      ..strokeWidth = 2;
    final segments = doubleStopSegments(
      pairs,
      size,
      startFret: startFret,
      fretCount: fretCount,
    );
    for (final seg in segments) {
      canvas.drawLine(seg.from, seg.to, linePaint);
      _text(
        canvas,
        degreeNumeral(seg.pair.degree),
        segmentLabelOffset(seg.from, seg.to),
        TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: colorScheme.tertiary,
        ),
      );
    }

    final drawn = <(int, int)>{};
    for (final seg in segments) {
      for (final (mark, isRoot) in [
        (seg.pair.root, true),
        (seg.pair.interval, false),
      ]) {
        if (!drawn.add((mark.stringIndex, mark.fret))) continue;
        final center = at(mark.stringIndex, mark.fret);
        canvas.drawCircle(
          center,
          10,
          Paint()..color = isRoot ? Colors.red : colorScheme.primary,
        );
        _text(
          canvas,
          mark.note,
          center,
          TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: noteTextColor(isRoot, colorScheme),
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant DoubleStopPainter old) =>
      old.pairs != pairs ||
      old.startFret != startFret ||
      old.fretCount != fretCount;
}
