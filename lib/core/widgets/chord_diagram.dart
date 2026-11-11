import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/voicing/barre_detection.dart';
import '../../domain/voicing/fingering_metrics.dart';
import '../../ui/handedness.dart';
import '../../ui/theme.dart';

/// Traste base del diagrama cuando no se indica uno explícito.
///
/// Con cuerdas al aire y trastes ≤ 5 el diagrama parte del traste 1 (con nut).
int diagramBaseFret(List<int> fretPositions) {
  final fretted = fretPositions.where((f) => f > 0).toList(growable: false);
  if (fretted.isEmpty) return 1;
  final maxFret = fretted.reduce(math.max);
  if (fretPositions.contains(0) && maxFret <= 5) return 1;
  final minFret = fretted.reduce(math.min);
  return minFret > 1 ? minFret : 1;
}

/// Qué se escribe dentro de cada punto pisado.
enum DiagramDotLabel { finger, interval, note }

/// Filas bajo las cuerdas.
enum DiagramToneRow { none, intervals, intervalsAndNotes }

/// Diagrama de acorde que enseña: dedo dentro de cada punto, raíz con forma
/// propia (cuadrado), color por intervalo, cejilla dibujada y, opcionalmente,
/// el intervalo y la nota bajo cada cuerda.
///
/// Sin [root] se dibuja como antes (puntos del color de acento, sin intervalos).
class ChordDiagramWidget extends StatelessWidget {
  /// [fretPositions] y [fingerPositions] en el orden de chords.json
  /// (6ª → 1ª); `-1` = muteada, `0` = al aire.
  const ChordDiagramWidget({
    super.key,
    required this.fretPositions,
    required this.chordName,
    this.size = 200.0,
    this.showChordName = true,
    this.baseFret,
    this.fingerPositions,
    this.root,
    this.dotLabel = DiagramDotLabel.finger,
    this.toneRow = DiagramToneRow.none,
  }) : assert(
         fretPositions.length == 6,
         'fretPositions must have exactly 6 values',
       );

  final List<int> fretPositions;
  final String chordName;

  /// Ancho del diagrama; el alto depende de las filas que se muestren.
  final double size;
  final bool showChordName;
  final int? baseFret;
  final List<int>? fingerPositions;

  /// Raíz del acorde (con sostenidos); activa colores e intervalos.
  final String? root;
  final DiagramDotLabel dotLabel;
  final DiagramToneRow toneRow;

  @override
  Widget build(BuildContext context) {
    final tones = root == null
        ? null
        : stringTonesFromChordJson(jsonFrets: fretPositions, root: root!);
    final fingers = fingerPositions;
    final barre = fingers == null || fingers.length != 6
        ? null
        : barreFromChordJson(fretPositions, fingers);
    final layout = _DiagramLayout(
      width: size,
      showName: showChordName,
      toneRows: switch (toneRow) {
        DiagramToneRow.none => 0,
        DiagramToneRow.intervals => 1,
        DiagramToneRow.intervalsAndNotes => 2,
      },
      baseFret: baseFret ?? diagramBaseFret(fretPositions),
    );

    final mirrored = Handedness.of(context);
    return Semantics(
      label: _semanticLabel(tones),
      excludeSemantics: true,
      child: HandedFlip(
        child: CustomPaint(
          size: Size(size, layout.height),
          painter: _ChordDiagramPainter(
            mirrored: mirrored,
            layout: layout,
            fretPositions: fretPositions,
            fingerPositions: fingers,
            tones: tones,
            barre: barre,
            chordName: chordName,
            dotLabel: dotLabel,
            palette: context.palette,
          ),
        ),
      ),
    );
  }

  String _semanticLabel(List<StringTone?>? tones) {
    final parts = <String>[chordName];
    for (var s = 0; s < 6; s++) {
      final string = 6 - s;
      final fret = fretPositions[s];
      final tone = tones?[s];
      final what = switch (fret) {
        -1 => 'muteada',
        0 => 'al aire',
        _ =>
          'traste $fret'
              '${fingerPositions != null && fingerPositions![s] > 0 ? ', dedo ${fingerPositions![s]}' : ''}',
      };
      parts.add(
        'cuerda $string $what'
        '${tone == null ? '' : ', ${tone.note} (${tone.label})'}',
      );
    }
    return parts.join('; ');
  }
}

/// Medidas de un diagrama de [width] desde [baseFret] (para los tests): el
/// tamaño del número del dedo y dónde queda el centro de la rejilla.
@visibleForTesting
({double fingerFont, double gridCenter, double height, int frets})
chordDiagramMetrics(double width, {int baseFret = 1}) {
  final l = _DiagramLayout(
    width: width,
    showName: false,
    toneRows: 0,
    baseFret: baseFret,
  );
  return (
    fingerFont: l.fingerFontSize('1'),
    gridCenter: l.left + 2.5 * l.stringSpacing,
    height: l.height,
    frets: l.fretsShown,
  );
}

/// Medidas del diagrama, compartidas por el widget (tamaño) y el painter.
class _DiagramLayout {
  _DiagramLayout({
    required this.width,
    required this.showName,
    required this.toneRows,
    required this.baseFret,
  });

  /// Por debajo de este ancho (miniaturas del mapa y de la unidad) los puntos
  /// crecen para que el número del dedo se lea, y se muestran 4 trastes en vez
  /// de 5 para que el diagrama no crezca de alto.
  static const compactWidth = 100.0;

  int get fretsShown => compact ? 4 : 5;

  final double width;
  final bool showName;
  final int toneRows;
  final int baseFret;

  bool get compact => width < compactWidth;

  /// Desde la cejuela no hay número de traste a la izquierda: los márgenes
  /// son iguales y la rejilla queda centrada.
  double get left => fretOffset == 0 ? right : width * 0.16;
  double get right => width * (compact ? 0.06 : 0.08);

  /// Radio de un punto pisado y tamaño del número que lleva dentro.
  double get dotRadius => stringSpacing * (compact ? 0.47 : 0.36);
  double fingerFontSize(String label) =>
      dotRadius * (label.length > 1 ? 0.95 : (compact ? 1.4 : 1.15));
  double get stringSpacing => (width - left - right) / 5;
  double get fretSpacing => stringSpacing * 1.2;
  double get nameHeight => showName ? width * 0.16 : 0;
  double get indicatorHeight => stringSpacing * 0.9;
  double get gridTop => nameHeight + indicatorHeight;
  double get gridHeight => fretSpacing * fretsShown;
  double get toneRowHeight => stringSpacing * 0.62;
  double get height =>
      gridTop + gridHeight + toneRows * toneRowHeight + stringSpacing * 0.25;

  /// Cuántos trastes se desplaza la rejilla (0 = desde la cejuela).
  int get fretOffset => baseFret > 1 ? baseFret - 1 : 0;

  /// Única función de coordenadas: centro de la nota de la cuerda [jsonString]
  /// (0 = 6ª) en el traste [fret]. El traste 0 cae en la fila de indicadores.
  Offset noteOffset(int jsonString, int fret) {
    final x = left + jsonString * stringSpacing;
    if (fret <= 0) return Offset(x, nameHeight + indicatorHeight * 0.45);
    return Offset(x, gridTop + (fret - fretOffset - 0.5) * fretSpacing);
  }

  /// Centro de la fila de tonos [row] (0 = intervalos, 1 = notas).
  Offset toneOffset(int jsonString, int row) => Offset(
    left + jsonString * stringSpacing,
    gridTop + gridHeight + (row + 0.6) * toneRowHeight,
  );
}

class _ChordDiagramPainter extends CustomPainter {
  _ChordDiagramPainter({
    required this.layout,
    required this.fretPositions,
    required this.fingerPositions,
    required this.tones,
    required this.barre,
    required this.chordName,
    required this.dotLabel,
    required this.palette,
    this.mirrored = false,
  });

  /// Modo zurdo: el lienzo llega espejado y los textos se enderezan.
  final bool mirrored;

  final _DiagramLayout layout;
  final List<int> fretPositions;
  final List<int>? fingerPositions;
  final List<StringTone?>? tones;
  final JsonBarre? barre;
  final String chordName;
  final DiagramDotLabel dotLabel;
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final l = layout;
    final gridLeft = l.left;
    final gridRight = l.left + 5 * l.stringSpacing;
    final gridBottom = l.gridTop + l.gridHeight;

    if (l.showName) {
      _text(
        canvas,
        chordName,
        Offset(size.width / 2, l.nameHeight * 0.45),
        size: l.width * 0.1,
        weight: FontWeight.w600,
        color: palette.textPrimary,
      );
    }

    // Cejuela (gruesa) o línea fina con el número de traste a la izquierda.
    final atNut = l.fretOffset == 0;
    canvas.drawLine(
      Offset(gridLeft, l.gridTop),
      Offset(gridRight, l.gridTop),
      Paint()
        ..color = atNut ? palette.nut : palette.fretWire
        ..strokeWidth = atNut ? l.stringSpacing * 0.16 : 1.5
        ..strokeCap = StrokeCap.round,
    );
    if (!atNut) {
      _text(
        canvas,
        '${l.baseFret}',
        Offset(
          gridLeft - l.stringSpacing * 0.6,
          l.noteOffset(0, l.baseFret).dy,
        ),
        size: l.stringSpacing * 0.42,
        weight: FontWeight.w600,
        color: palette.textSecondary,
      );
    }

    final fretPaint = Paint()
      ..color = palette.fretWire
      ..strokeWidth = 1.2;
    for (var f = 1; f <= l.fretsShown; f++) {
      final y = l.gridTop + f * l.fretSpacing;
      canvas.drawLine(Offset(gridLeft, y), Offset(gridRight, y), fretPaint);
    }

    // Cuerdas: la 6ª (índice 0) es la más gruesa.
    for (var s = 0; s < 6; s++) {
      final x = l.noteOffset(s, 1).dx;
      canvas.drawLine(
        Offset(x, l.gridTop),
        Offset(x, gridBottom),
        Paint()
          ..color = palette.fretString
          ..strokeWidth = 0.9 + (5 - s) * 0.22,
      );
    }

    final r = l.dotRadius;

    // Cejilla detrás de los puntos.
    final b = barre;
    if (b != null && _visible(b.fret)) {
      final from = l.noteOffset(b.lowString, b.fret);
      final to = l.noteOffset(b.highString, b.fret);
      canvas.drawRRect(
        RRect.fromLTRBR(
          from.dx - r,
          from.dy - r * 0.62,
          to.dx + r,
          to.dy + r * 0.62,
          Radius.circular(r),
        ),
        Paint()..color = palette.textSecondary.withValues(alpha: 0.45),
      );
    }

    for (var s = 0; s < 6; s++) {
      final fret = fretPositions[s];
      final tone = tones?[s];
      final color = tone == null
          ? palette.accent
          : palette.intervalColor(tone.label);
      final c = l.noteOffset(s, fret);

      if (fret < 0) {
        final d = r * 0.5;
        final xPaint = Paint()
          ..color = palette.textSecondary
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round;
        canvas
          ..drawLine(c - Offset(d, d), c + Offset(d, d), xPaint)
          ..drawLine(c + Offset(-d, d), c + Offset(d, -d), xPaint);
        continue;
      }
      if (fret == 0) {
        canvas.drawCircle(
          c,
          r * 0.62,
          Paint()
            ..color = tones == null ? palette.textSecondary : color
            ..style = PaintingStyle.stroke
            ..strokeWidth = tone?.isRoot ?? false ? 2.6 : 1.6,
        );
        continue;
      }
      if (!_visible(fret)) continue;

      final fill = Paint()..color = color;
      if (tone?.isRoot ?? false) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCircle(center: c, radius: r),
            Radius.circular(r * 0.3),
          ),
          fill,
        );
      } else {
        canvas.drawCircle(c, r, fill);
      }

      final inside = switch (dotLabel) {
        DiagramDotLabel.finger => _finger(s),
        DiagramDotLabel.interval => tone?.label,
        DiagramDotLabel.note => tone?.note,
      };
      if (inside != null) {
        _text(
          canvas,
          inside,
          c,
          size: l.fingerFontSize(inside),
          weight: FontWeight.w600,
          color: tones == null ? palette.onAccent : palette.onInterval,
        );
      }
    }

    // Filas de intervalos y notas.
    if (tones != null) {
      for (var s = 0; s < 6; s++) {
        final tone = tones![s];
        if (tone == null) continue;
        if (l.toneRows >= 1) {
          _text(
            canvas,
            tone.label,
            l.toneOffset(s, 0),
            size: l.stringSpacing * 0.42,
            weight: FontWeight.w600,
            color: palette.intervalColor(tone.label),
          );
        }
        if (l.toneRows >= 2) {
          _text(
            canvas,
            tone.note,
            l.toneOffset(s, 1),
            size: l.stringSpacing * 0.38,
            color: palette.textSecondary,
          );
        }
      }
    }
  }

  bool _visible(int fret) {
    final rel = fret - layout.fretOffset;
    return rel >= 1 && rel <= layout.fretsShown;
  }

  String? _finger(int jsonString) {
    final f = fingerPositions;
    if (f == null || f.length != 6 || f[jsonString] <= 0) return null;
    return '${f[jsonString]}';
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
    paintUpright(
      canvas,
      painter,
      center - Offset(painter.width / 2, painter.height / 2),
      mirrored: mirrored,
    );
  }

  @override
  bool shouldRepaint(_ChordDiagramPainter old) =>
      old.mirrored != mirrored ||
      old.chordName != chordName ||
      old.dotLabel != dotLabel ||
      old.palette != palette ||
      old.layout.width != layout.width ||
      old.layout.toneRows != layout.toneRows ||
      old.layout.baseFret != layout.baseFret ||
      old.layout.showName != layout.showName ||
      old.fretPositions.join() != fretPositions.join() ||
      old.fingerPositions?.join() != fingerPositions?.join() ||
      old.tones?.map((t) => t?.label).join() !=
          tones?.map((t) => t?.label).join();
}
