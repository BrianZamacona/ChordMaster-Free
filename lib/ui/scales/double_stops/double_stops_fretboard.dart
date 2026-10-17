import 'package:flutter/material.dart';

import '../../../domain/theory/double_stops.dart';
import '../../theme.dart';
import 'double_stops_layout.dart';

const _romanNumerals = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];

String degreeNumeral(int? degree) =>
    degree == null ? '' : _romanNumerals[degree - 1];

/// Diapasón con las parejas de un par de cuerdas; notas y líneas se pintan en
/// un mismo lienzo con las coordenadas de [noteOffset].
///
/// Cada nota toma el color de su grado en la tonalidad [tonic] (no de su
/// papel en la pareja), así una nota se ve igual en todas las parejas; la
/// tónica es cuadrada.
class DoubleStopFretboard extends StatelessWidget {
  const DoubleStopFretboard({
    super.key,
    required this.pairs,
    required this.range,
    required this.tonic,
    this.height = 170,
  });

  final List<DoubleStopPair> pairs;
  final FretRange range;

  /// Tónica con sostenidos (`C`, `F#`…).
  final String tonic;
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
          tonic: tonic,
          palette: context.palette,
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
    required this.tonic,
    required this.palette,
  });

  final List<DoubleStopPair> pairs;
  final int startFret;
  final int fretCount;
  final String tonic;
  final AppPalette palette;

  static const _dotFrets = [3, 5, 7, 9, 15, 17, 19, 21];

  void _text(Canvas canvas, String text, Offset center, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: musicMono(
          fontSize: style.fontSize,
          fontWeight: style.fontWeight ?? FontWeight.w400,
          color: style.color,
        ),
      ),
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

    final stringPaint = Paint()..color = palette.fretString;
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
        TextStyle(fontSize: 10, color: palette.textSecondary),
      );
    }

    final fretPaint = Paint()..color = palette.fretWire;
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
          Paint()..color = palette.outline,
        );
      }
      _text(
        canvas,
        '$f',
        Offset(x, bottom + 16),
        TextStyle(fontSize: 8, color: palette.textSecondary),
      );
    }

    final linePaint = Paint()
      ..color = palette.textSecondary
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
          fontWeight: FontWeight.w600,
          color: palette.textSecondary,
        ),
      );
    }

    final drawn = <(int, int)>{};
    for (final seg in segments) {
      for (final mark in [seg.pair.root, seg.pair.interval]) {
        if (!drawn.add((mark.stringIndex, mark.fret))) continue;
        final center = at(mark.stringIndex, mark.fret);
        final degree = degreeInMajorKey(mark.note, tonic);
        final fill = Paint()..color = palette.intervalColor(degree);
        if (degree == '1') {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCircle(center: center, radius: 10),
              const Radius.circular(3),
            ),
            fill,
          );
        } else {
          canvas.drawCircle(center, 10, fill);
        }
        _text(
          canvas,
          mark.note,
          center,
          TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: palette.onInterval,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant DoubleStopPainter old) =>
      old.pairs != pairs ||
      old.startFret != startFret ||
      old.fretCount != fretCount ||
      old.tonic != tonic ||
      old.palette != palette;
}
