import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/i18n/tr.dart';

import '../../data/models/note_coordinate.dart';
import '../../data/repository/scale_repository.dart';
import '../theme.dart';
import 'fret_grid_geometry.dart';

/// Qué se escribe dentro de cada nota del diapasón de escala.
enum FretboardLabel { interval, note }

/// Diapasón de una posición de escala: 1ª cuerda arriba (como una tablatura),
/// raíz cuadrada y cada grado con el color de su intervalo. La afinación
/// siempre se ve a la izquierda, y ahí van las cuerdas al aire, con un anillo.
///
/// Diapasón, notas y etiquetas salen de una sola función de coordenadas
/// ([FretGridGeometry.noteOffset]) en un solo [CustomPainter].
class FretboardDiagram extends StatelessWidget {
  const FretboardDiagram({
    super.key,
    required this.pattern,
    this.height = 180,
    this.label = FretboardLabel.interval,
    this.links = const [],
  });

  final ResolvedPattern pattern;
  final double height;
  final FretboardLabel label;

  /// Líneas entre pares de notas (cuerda 1 = mi aguda, traste), p. ej. una
  /// nota y su octava. Se dibujan debajo de las notas.
  final List<FretLink> links;

  @override
  Widget build(BuildContext context) {
    final open = pattern.coordinates.where((c) => c.fret == 0).length;
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) => Semantics(
          label: tr(
            es: 'Posición entre los trastes ${pattern.startingFret} y '
                '${pattern.endFret}, ${pattern.coordinates.length} notas'
                '${open > 0 ? ', $open al aire' : ''}',
            en: 'Position between frets ${pattern.startingFret} and '
                '${pattern.endFret}, ${pattern.coordinates.length} notes'
                '${open > 0 ? ', $open open' : ''}',
          ),
          excludeSemantics: true,
          child: CustomPaint(
            size: Size(constraints.maxWidth, height),
            painter: _BoardPainter(
              geometry: FretGridGeometry(
                width: constraints.maxWidth,
                height: height,
                startFret: pattern.startingFret,
                endFret: pattern.endFret,
              ),
              coordinates: pattern.coordinates,
              label: label,
              links: links,
              palette: context.palette,
            ),
          ),
        ),
      ),
    );
  }
}

/// Par de posiciones unidas por una línea en [FretboardDiagram].
typedef FretLink = (({int string, int fret}), ({int string, int fret}));

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.geometry,
    required this.coordinates,
    required this.label,
    required this.links,
    required this.palette,
  });

  final FretGridGeometry geometry;
  final List<NoteCoordinate> coordinates;
  final FretboardLabel label;
  final List<FretLink> links;
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    const boardTop = FretGridGeometry.top;

    // Marcadores del mástil, detrás de todo.
    final inlay = Paint()..color = palette.outline;
    for (final fret in inlayFrets) {
      if (fret < g.firstFret || fret > g.lastFret) continue;
      canvas.drawCircle(
        Offset(g.noteOffset(1, fret).dx, boardTop + 2.5 * g.stringSpacing),
        3.5,
        inlay,
      );
    }
    for (final fret in doubleInlayFrets) {
      if (fret < g.firstFret || fret > g.lastFret) continue;
      final x = g.noteOffset(1, fret).dx;
      canvas
        ..drawCircle(Offset(x, boardTop + 1.5 * g.stringSpacing), 3.5, inlay)
        ..drawCircle(Offset(x, boardTop + 3.5 * g.stringSpacing), 3.5, inlay);
    }

    // El primer alambre es la cejuela solo si la celda de al lado es el traste 1.
    for (var wire = g.firstFret - 1; wire <= g.lastFret; wire++) {
      final x = g.fretLineX(wire);
      final isNut = wire == 0;
      canvas.drawLine(
        Offset(x, boardTop - 8),
        Offset(x, g.boardBottom + 8),
        Paint()
          ..color = isNut ? palette.nut : palette.fretWire
          ..strokeWidth = isNut ? 3 : 1,
      );
    }

    for (var string = 1; string <= 6; string++) {
      final y = g.stringY(string);
      canvas.drawLine(
        Offset(FretGridGeometry.stringStartX, y),
        Offset(g.boardWidth, y),
        Paint()
          ..color = palette.fretString
          ..strokeWidth = ui.lerpDouble(0.8, 2.4, (string - 1) / 5)!,
      );
      _text(
        canvas,
        tuningLabels[string - 1],
        Offset(FretGridGeometry.tuningLabelX, y),
        size: 10,
        color: palette.textSecondary,
      );
    }

    // Número del primer traste mostrado, bajo su celda.
    _text(
      canvas,
      '${g.firstFret}',
      Offset(g.noteOffset(6, g.firstFret).dx, g.boardBottom + 14),
      size: 10,
      color: palette.textSecondary,
    );

    final link = Paint()
      ..color = palette.accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final (a, b) in links) {
      canvas.drawLine(
        g.noteOffset(a.string, a.fret),
        g.noteOffset(b.string, b.fret),
        link,
      );
    }

    for (final c in coordinates) {
      _note(canvas, c);
    }
  }

  void _note(Canvas canvas, NoteCoordinate c) {
    final g = geometry;
    final center = g.noteOffset(c.string, c.fret);
    final isOpen = c.fret == 0;
    final r = isOpen ? g.openRadius : g.radius;
    final color = c.interval.isEmpty
        ? palette.accent
        : palette.intervalColor(c.isRoot ? '1' : c.interval);
    final shape = RRect.fromRectAndRadius(
      Rect.fromCircle(center: center, radius: r),
      Radius.circular(c.isRoot ? r * 0.3 : r),
    );
    canvas.drawRRect(shape, Paint()..color = color);
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
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_BoardPainter old) =>
      old.geometry.width != geometry.width ||
      old.geometry.height != geometry.height ||
      old.geometry.startFret != geometry.startFret ||
      old.geometry.endFret != geometry.endFret ||
      old.label != label ||
      !identical(old.links, links) ||
      old.palette != palette ||
      !identical(old.coordinates, coordinates);
}
