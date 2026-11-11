import 'package:flutter/material.dart';

import '../../../domain/theory/double_stops.dart';
import '../../handedness.dart';
import '../../theme.dart';
import '../../widgets/fret_grid_geometry.dart';
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

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: LayoutBuilder(
      builder: (context, constraints) => HandedFlip(
        child: CustomPaint(
          size: Size(constraints.maxWidth, height),
          painter: DoubleStopPainter(
            pairs: pairs,
            startFret: range.start,
            endFret: range.end,
            tonic: tonic,
            palette: context.palette,
            mirrored: Handedness.of(context),
          ),
        ),
      ),
    ),
  );
}

class DoubleStopPainter extends CustomPainter {
  const DoubleStopPainter({
    required this.pairs,
    required this.startFret,
    required this.endFret,
    required this.tonic,
    required this.palette,
    this.mirrored = false,
  });

  /// Modo zurdo: el lienzo llega espejado y los textos se enderezan.
  final bool mirrored;

  final List<DoubleStopPair> pairs;
  final int startFret;
  final int endFret;
  final String tonic;
  final AppPalette palette;

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
    paintUpright(
      canvas,
      tp,
      center - Offset(tp.width / 2, tp.height / 2),
      mirrored: mirrored,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final grid = doubleStopGrid(size, startFret: startFret, endFret: endFret);
    Offset at(int s, int f) =>
        noteOffset(s, f, size, startFret: startFret, endFret: endFret);

    final top = at(0, startFret).dy;
    final bottom = at(5, startFret).dy;

    // Las notas llevan su nombre: en una cuerda al aire ya dice la afinación, y
    // escribirla otra vez al lado la duplicaría.
    final named = {
      for (final pair in pairs)
        for (final mark in [pair.root, pair.interval])
          if (mark.fret == 0) mark.stringIndex,
    };
    final stringPaint = Paint()..color = palette.fretString;
    for (var s = 0; s < 6; s++) {
      final y = at(s, startFret).dy;
      canvas.drawLine(
        Offset(FretGridGeometry.stringStartX, y),
        Offset(size.width, y),
        stringPaint..strokeWidth = 0.8 + 1.6 * s / 5,
      );
      if (named.contains(s)) continue;
      _text(
        canvas,
        tuningLabels[s],
        Offset(FretGridGeometry.tuningLabelX, y),
        TextStyle(fontSize: 10, color: palette.textSecondary),
      );
    }

    // El primer alambre es la cejuela solo si la celda de al lado es el traste 1.
    for (var wire = grid.firstFret - 1; wire <= grid.lastFret; wire++) {
      final x = grid.fretLineX(wire);
      final isNut = wire == 0;
      canvas.drawLine(
        Offset(x, top - 8),
        Offset(x, bottom + 8),
        Paint()
          ..color = isNut ? palette.nut : palette.fretWire
          ..strokeWidth = isNut ? 3 : 1,
      );
    }
    final inlay = Paint()..color = palette.outline;
    for (var f = grid.firstFret; f <= grid.lastFret; f++) {
      final x = at(0, f).dx;
      if (inlayFrets.contains(f)) {
        canvas.drawCircle(Offset(x, (top + bottom) / 2), 3, inlay);
      } else if (doubleInlayFrets.contains(f)) {
        canvas
          ..drawCircle(Offset(x, top + 1.5 * grid.stringSpacing), 3, inlay)
          ..drawCircle(Offset(x, top + 3.5 * grid.stringSpacing), 3, inlay);
      }
      _text(
        canvas,
        '$f',
        Offset(x, grid.fretNumberY),
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
      endFret: endFret,
    );
    for (final seg in segments) {
      canvas.drawLine(seg.from, seg.to, linePaint);
      _text(
        canvas,
        degreeNumeral(seg.pair.degree),
        segmentLabelOffset(
          seg.from,
          seg.to,
          bottom - at(4, startFret).dy,
          nutX: grid.hasNut ? grid.nutX : null,
        ),
        TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
      );
    }

    final drawn = <(int, int)>{};
    for (final seg in segments) {
      for (final mark in [seg.pair.root, seg.pair.interval]) {
        if (!drawn.add((mark.stringIndex, mark.fret))) continue;
        final center = at(mark.stringIndex, mark.fret);
        final degree = degreeInMajorKey(mark.note, tonic);
        final isOpen = mark.fret == 0;
        final r = isOpen ? grid.openRadius : 10.0;
        final shape = RRect.fromRectAndRadius(
          Rect.fromCircle(center: center, radius: r),
          Radius.circular(degree == '1' ? r * 0.3 : r),
        );
        canvas.drawRRect(shape, Paint()..color = palette.intervalColor(degree));
        if (isOpen) {
          // La cuerda al aire lleva anillo: se distingue también sin el color.
          canvas.drawRRect(
            shape,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = palette.textPrimary,
          );
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
      old.endFret != endFret ||
      old.tonic != tonic ||
      old.palette != palette ||
      old.mirrored != mirrored;
}
