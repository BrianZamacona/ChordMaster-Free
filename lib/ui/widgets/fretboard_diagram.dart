import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/i18n/tr.dart';

import '../../data/models/note_coordinate.dart';
import '../../data/repository/scale_repository.dart';
import '../theme.dart';

/// Qué se escribe dentro de cada nota del diapasón de escala.
enum FretboardLabel { interval, note }

/// Diapasón de una posición de escala: 1ª cuerda arriba (como una tablatura),
/// raíz cuadrada y cada grado con el color de su intervalo.
///
/// Diapasón, notas y etiquetas salen de una sola función de coordenadas
/// ([_BoardGeometry.noteOffset]) en un solo [CustomPainter].
class FretboardDiagram extends StatelessWidget {
  const FretboardDiagram({
    super.key,
    required this.pattern,
    this.height = 180,
    this.label = FretboardLabel.interval,
  });

  final ResolvedPattern pattern;
  final double height;
  final FretboardLabel label;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) => Semantics(
            label: tr(
              es: 'Posición entre los trastes ${pattern.startingFret} y '
                  '${pattern.endFret}, ${pattern.coordinates.length} notas',
              en: 'Position between frets ${pattern.startingFret} and '
                  '${pattern.endFret}, ${pattern.coordinates.length} notes',
            ),
            excludeSemantics: true,
            child: CustomPaint(
              size: Size(constraints.maxWidth, height),
              painter: _BoardPainter(
                geometry: _BoardGeometry(
                  width: constraints.maxWidth,
                  height: height,
                  startFret: pattern.startingFret,
                  fretCount: pattern.fretSpan,
                ),
                endFret: pattern.endFret,
                coordinates: pattern.coordinates,
                label: label,
                palette: context.palette,
              ),
            ),
          ),
        ),
      );
}

class _BoardGeometry {
  const _BoardGeometry({
    required this.width,
    required this.height,
    required this.startFret,
    required this.fretCount,
  });

  static const leftPad = 22.0;
  static const top = 16.0;
  static const bottom = 20.0;

  final double width;
  final double height;
  final int startFret;
  final int fretCount;

  double get fretWidth => (width - leftPad) / fretCount;
  double get stringSpacing => (height - top - bottom) / 5;
  double get radius => math.min(11, math.min(fretWidth, stringSpacing) * 0.42);

  /// Centro de la nota de la cuerda [string] (1 = mi aguda) en el traste [fret].
  Offset noteOffset(int string, int fret) => Offset(
        fretLineX(fret) + fretWidth / 2,
        top + (string - 1) * stringSpacing,
      );

  /// Línea vertical a la izquierda del traste [fret].
  double fretLineX(int fret) => leftPad + (fret - startFret) * fretWidth;
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.geometry,
    required this.endFret,
    required this.coordinates,
    required this.label,
    required this.palette,
  });

  final _BoardGeometry geometry;
  final int endFret;
  final List<NoteCoordinate> coordinates;
  final FretboardLabel label;
  final AppPalette palette;

  static const _dotFrets = [3, 5, 7, 9, 15, 17, 19, 21];
  static const _doubleDotFrets = [12, 24];
  static const _stringNames = ['e', 'B', 'G', 'D', 'A', 'E'];

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    final boardBottom = _BoardGeometry.top + 5 * g.stringSpacing;

    // Marcadores del mástil, detrás de todo.
    final inlay = Paint()..color = palette.outline;
    for (final fret in _dotFrets) {
      if (fret < g.startFret || fret > endFret) continue;
      final c = g.noteOffset(1, fret);
      canvas.drawCircle(
        Offset(c.dx, _BoardGeometry.top + 2.5 * g.stringSpacing),
        3.5,
        inlay,
      );
    }
    for (final fret in _doubleDotFrets) {
      if (fret < g.startFret || fret > endFret) continue;
      final x = g.noteOffset(1, fret).dx;
      canvas
        ..drawCircle(Offset(x, _BoardGeometry.top + 1.5 * g.stringSpacing), 3.5, inlay)
        ..drawCircle(Offset(x, _BoardGeometry.top + 3.5 * g.stringSpacing), 3.5, inlay);
    }

    for (var fret = g.startFret; fret <= endFret + 1; fret++) {
      final x = g.fretLineX(fret);
      canvas.drawLine(
        Offset(x, _BoardGeometry.top - 8),
        Offset(x, boardBottom + 8),
        Paint()
          ..color = fret == 0 ? palette.nut : palette.fretWire
          ..strokeWidth = fret == 0 ? 3 : 1,
      );
    }

    for (var string = 1; string <= 6; string++) {
      final y = g.noteOffset(string, g.startFret).dy;
      canvas.drawLine(
        Offset(_BoardGeometry.leftPad, y),
        Offset(size.width, y),
        Paint()
          ..color = palette.fretString
          ..strokeWidth = ui.lerpDouble(0.8, 2.4, (string - 1) / 5)!,
      );
      _text(
        canvas,
        _stringNames[string - 1],
        Offset(8, y),
        size: 10,
        color: palette.textSecondary,
      );
    }

    // Número del primer traste mostrado, bajo el diapasón.
    _text(
      canvas,
      '${g.startFret}',
      Offset(g.noteOffset(6, g.startFret).dx, boardBottom + 14),
      size: 10,
      color: palette.textSecondary,
    );

    final r = g.radius;
    for (final c in coordinates) {
      final center = g.noteOffset(c.string, c.fret);
      final color = c.interval.isEmpty
          ? palette.accent
          : palette.intervalColor(c.isRoot ? '1' : c.interval);
      final fill = Paint()..color = color;
      if (c.isRoot) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCircle(center: center, radius: r),
            Radius.circular(r * 0.3),
          ),
          fill,
        );
      } else {
        canvas.drawCircle(center, r, fill);
      }
      final text = label == FretboardLabel.note ? c.note : c.interval;
      if (text.isNotEmpty) {
        _text(
          canvas,
          text,
          center,
          size: r * (text.length > 1 ? 0.85 : 1.0),
          weight: FontWeight.w600,
          color: palette.onInterval,
        );
      }
    }
  }

  void _text(
    Canvas canvas,
    String text,
    Offset center, {
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w400,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: musicMono(fontSize: size, fontWeight: weight, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(_BoardPainter old) =>
      old.geometry.width != geometry.width ||
      old.geometry.height != geometry.height ||
      old.geometry.startFret != geometry.startFret ||
      old.endFret != endFret ||
      old.label != label ||
      old.palette != palette ||
      !identical(old.coordinates, coordinates);
}
