import 'package:flutter/material.dart';

import '../../domain/theory/position_brackets.dart';
import '../handedness.dart';
import '../theme.dart';
import 'fret_grid_geometry.dart';

/// Las llaves de posición bajo el mástil, con la misma geometría que los
/// trastes ([FretGridGeometry]), así quedan justo bajo su tramo y se desplazan
/// con él. La elegida va más gruesa, en latón y con el nombre en negrita: la
/// forma y el peso dicen cuál es, no solo el color.
class PositionBracketStrip extends StatelessWidget {
  const PositionBracketStrip({
    super.key,
    required this.geometry,
    required this.brackets,
    required this.labels,
    this.selected,
    this.onTap,
  });

  /// Alto de cada fila de llaves.
  static const rowHeight = 16.0;

  /// Alto que ocupan [brackets].
  static double heightFor(List<PositionBracket> brackets) => bracketRows(brackets) * rowHeight;

  final FretGridGeometry geometry;
  final List<PositionBracket> brackets;

  /// El nombre de cada forma, por su índice.
  final List<String> labels;

  /// El índice de la forma elegida.
  final int? selected;
  final ValueChanged<int>? onTap;

  /// Extremos de [b] en el lienzo: del alambre de antes de su primer traste al
  /// de su último (desde la cuerda al aire si empieza en el 0).
  static (double, double) span(FretGridGeometry g, PositionBracket b) => (
    b.start == 0 ? FretGridGeometry.openNoteX - 8 : g.fretLineX(b.start - 1) + 3,
    g.fretLineX(b.end) - 3,
  );

  /// La llave bajo el punto [p], o `null`.
  int? indexAt(Offset p) {
    final row = (p.dy / rowHeight).floor();
    for (final b in brackets) {
      final (left, right) = span(geometry, b);
      if (b.row == row && p.dx >= left && p.dx <= right) return b.index;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final size = Size(geometry.boardWidth, heightFor(brackets));
    final paint = CustomPaint(
      size: size,
      painter: _BracketPainter(
        geometry: geometry,
        brackets: brackets,
        labels: labels,
        selected: selected,
        palette: context.palette,
        mirrored: Handedness.of(context),
      ),
    );
    final tap = onTap;
    if (tap == null) return paint;
    return GestureDetector(
      key: const Key('neck-brackets'),
      behavior: HitTestBehavior.opaque,
      onTapUp: (d) {
        if (indexAt(d.localPosition) case final index?) tap(index);
      },
      child: paint,
    );
  }
}

class _BracketPainter extends CustomPainter {
  _BracketPainter({
    required this.geometry,
    required this.brackets,
    required this.labels,
    required this.selected,
    required this.palette,
    required this.mirrored,
  });

  final FretGridGeometry geometry;
  final List<PositionBracket> brackets;
  final List<String> labels;
  final int? selected;
  final AppPalette palette;
  final bool mirrored;

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in brackets) {
      final chosen = b.index == selected;
      final color = chosen ? palette.accent : palette.textSecondary;
      final (left, right) = PositionBracketStrip.span(geometry, b);
      final top = b.row * PositionBracketStrip.rowHeight + 2;
      final line = top + 7;
      final pen = Paint()
        ..color = color
        ..strokeWidth = chosen ? 2.5 : 1.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final text = TextPainter(
        text: TextSpan(
          text: labels[b.index],
          style: musicMono(
            fontSize: 10,
            fontWeight: chosen ? FontWeight.w600 : FontWeight.w400,
            color: chosen ? palette.textPrimary : palette.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: (right - left - 16).clamp(0, double.infinity));
      final middle = (left + right) / 2;
      final gapLeft = middle - text.width / 2 - 4;
      final gapRight = middle + text.width / 2 + 4;
      // ⌐ ¬ hacia arriba en los extremos y la línea cortada por el nombre.
      canvas
        ..drawLine(Offset(left, top), Offset(left, line), pen)
        ..drawLine(Offset(right, top), Offset(right, line), pen)
        ..drawLine(Offset(left, line), Offset(gapLeft, line), pen)
        ..drawLine(Offset(gapRight, line), Offset(right, line), pen);
      paintUpright(canvas, text, Offset(middle - text.width / 2, line - text.height / 2), mirrored: mirrored);
    }
  }

  @override
  bool shouldRepaint(_BracketPainter old) =>
      old.brackets != brackets ||
      old.labels != labels ||
      old.selected != selected ||
      old.palette != palette ||
      old.mirrored != mirrored ||
      old.geometry.fretWidth != geometry.fretWidth;
}
