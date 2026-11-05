import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
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

/// Mástil completo (columna de afinación + trastes 1–24) con scroll horizontal.
///
/// La afinación y las notas al aire quedan fijas a la izquierda y los números
/// de traste, abajo, siempre a la vista. Con [highlighted], el resto de las
/// notas se atenúa; [focus] es el rango de trastes que se centra.
class FretboardNeck extends StatefulWidget {
  const FretboardNeck({
    super.key,
    required this.coordinates,
    this.highlighted,
    this.focus,
    this.label = FretboardLabel.interval,
  });

  /// Ancho mínimo de traste para que los intervalos se lean.
  static const minFretWidth = 52.0;
  static const maxFret = 24;

  /// Espacio bajo los números para la barra de scroll.
  static const _scrollbarGap = 12.0;

  final List<NoteCoordinate> coordinates;
  final Set<NoteCoordinate>? highlighted;
  final ({int start, int end})? focus;
  final FretboardLabel label;

  @override
  State<FretboardNeck> createState() => _FretboardNeckState();
}

class _FretboardNeckState extends State<FretboardNeck> {
  final _scroll = ScrollController();
  FretGridGeometry? _geometry;
  double? _viewport;

  @override
  void didUpdateWidget(FretboardNeck old) {
    super.didUpdateWidget(old);
    if (old.focus != widget.focus) {
      _centerAfterFrame(animate: !MediaQuery.disableAnimationsOf(context));
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _centerAfterFrame({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focus = widget.focus;
      final geometry = _geometry;
      final viewport = _viewport;
      if (!mounted || !_scroll.hasClients) return;
      if (focus == null || geometry == null || viewport == null) return;
      final target = geometry.scrollToCenter(focus.start, focus.end, viewport);
      if (animate) {
        _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scroll.jumpTo(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final height = constraints.maxHeight - FretboardNeck._scrollbarGap;
      final geometry = FretGridGeometry(
        width: constraints.maxWidth,
        height: height,
        startFret: 1,
        endFret: FretboardNeck.maxFret,
        fixedFretWidth: math.max(
          FretboardNeck.minFretWidth,
          (constraints.maxWidth - FretGridGeometry.openColumnWidth) /
              FretboardNeck.maxFret,
        ),
        maxNoteRadius: 14,
      );
      _geometry = geometry;
      // Al entrar y al girar el teléfono cambia el visor: se vuelve a centrar.
      if (_viewport != constraints.maxWidth) {
        _viewport = constraints.maxWidth;
        _centerAfterFrame(animate: false);
      }
      _BoardPainter painter(_BoardLayer layer) => _BoardPainter(
        geometry: geometry,
        coordinates: widget.coordinates,
        label: widget.label,
        links: const [],
        palette: context.palette,
        layer: layer,
        highlighted: widget.highlighted,
        numberEveryFret: true,
      );
      return Semantics(
        label: tr(
          es: 'Mástil completo, ${widget.coordinates.length} notas de la '
              'escala${widget.highlighted == null ? '' : ', ${widget.highlighted!.length} resaltadas'}',
          en: 'Whole neck, ${widget.coordinates.length} scale notes'
              '${widget.highlighted == null ? '' : ', ${widget.highlighted!.length} highlighted'}',
        ),
        child: Stack(
          children: [
            ScrollConfiguration(
              // Con ratón también se arrastra, como con el dedo.
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {...PointerDeviceKind.values},
              ),
              child: Scrollbar(
                controller: _scroll,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  key: const Key('neck-scroll'),
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(
                    bottom: FretboardNeck._scrollbarGap,
                  ),
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: Size(geometry.boardWidth, height),
                      painter: painter(_BoardLayer.frets),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              width: _BoardPainter.pinnedColumnWidth,
              height: height,
              child: CustomPaint(painter: painter(_BoardLayer.tuning)),
            ),
          ],
        ),
      );
    },
  );
}

/// Par de posiciones unidas por una línea en [FretboardDiagram].
typedef FretLink = (({int string, int fret}), ({int string, int fret}));

/// Qué parte dibuja el pintor: todo junto o, en el mástil con scroll, los
/// trastes por un lado y la columna fija de afinación por otro.
enum _BoardLayer { all, frets, tuning }

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.geometry,
    required this.coordinates,
    required this.label,
    required this.links,
    required this.palette,
    this.layer = _BoardLayer.all,
    this.highlighted,
    this.numberEveryFret = false,
  });

  /// Ancho de la columna fija: deja a la vista la cejuela de la capa de abajo.
  static const pinnedColumnWidth = FretGridGeometry.openColumnWidth - 1.5;

  final FretGridGeometry geometry;
  final List<NoteCoordinate> coordinates;
  final FretboardLabel label;
  final List<FretLink> links;
  final AppPalette palette;
  final _BoardLayer layer;
  final Set<NoteCoordinate>? highlighted;
  final bool numberEveryFret;

  bool _isDimmed(NoteCoordinate c) =>
      highlighted != null && !highlighted!.contains(c);

  /// Las atenuadas primero: las resaltadas quedan encima.
  Iterable<NoteCoordinate> _notes({required bool open}) => [
    for (final c in coordinates)
      if ((c.fret == 0) == open && _isDimmed(c)) c,
    for (final c in coordinates)
      if ((c.fret == 0) == open && !_isDimmed(c)) c,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (layer != _BoardLayer.tuning) _paintFrets(canvas);
    if (layer != _BoardLayer.frets) _paintTuning(canvas, size);
  }

  void _paintFrets(Canvas canvas) {
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
      _string(canvas, string, FretGridGeometry.stringStartX, g.boardWidth);
    }

    // Número del primer traste mostrado o de todos, bajo su celda.
    final lastNumbered = numberEveryFret ? g.lastFret : g.firstFret;
    for (var fret = g.firstFret; fret <= lastNumbered; fret++) {
      _text(
        canvas,
        '$fret',
        Offset(g.noteOffset(6, fret).dx, g.fretNumberY),
        size: numberEveryFret ? 11 : 10,
        color: palette.textSecondary,
      );
    }

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

    for (final c in _notes(open: false)) {
      _note(canvas, c);
    }
  }

  void _paintTuning(Canvas canvas, Size size) {
    final g = geometry;
    final pinned = layer == _BoardLayer.tuning;
    if (pinned) {
      // Tapa los trastes que pasan por debajo al hacer scroll.
      canvas
        ..drawRect(Offset.zero & size, Paint()..color = palette.background)
        ..drawLine(
          Offset(size.width, FretGridGeometry.top - 8),
          Offset(size.width, g.boardBottom + 8),
          Paint()
            ..color = palette.fretWire
            ..strokeWidth = 1,
        );
    }
    for (var string = 1; string <= 6; string++) {
      if (pinned) {
        _string(canvas, string, FretGridGeometry.stringStartX, size.width);
      }
      _text(
        canvas,
        tuningLabels[string - 1],
        Offset(FretGridGeometry.tuningLabelX, g.stringY(string)),
        size: 10,
        color: palette.textSecondary,
      );
    }
    for (final c in _notes(open: true)) {
      _note(canvas, c);
    }
  }

  void _string(Canvas canvas, int string, double fromX, double toX) {
    final y = geometry.stringY(string);
    canvas.drawLine(
      Offset(fromX, y),
      Offset(toX, y),
      Paint()
        ..color = palette.fretString
        ..strokeWidth = ui.lerpDouble(0.8, 2.4, (string - 1) / 5)!,
    );
  }

  void _note(Canvas canvas, NoteCoordinate c) {
    final g = geometry;
    final center = g.noteOffset(c.string, c.fret);
    final isOpen = c.fret == 0;
    final dimmed = _isDimmed(c);
    final r = isOpen ? g.openRadius : g.radius;
    final color = c.interval.isEmpty
        ? palette.accent
        : palette.intervalColor(c.isRoot ? '1' : c.interval);
    final shape = RRect.fromRectAndRadius(
      Rect.fromCircle(center: center, radius: r),
      Radius.circular(c.isRoot ? r * 0.3 : r),
    );
    // Fondo opaco: que la cuerda no cruce el texto de una nota atenuada.
    if (dimmed) canvas.drawRRect(shape, Paint()..color = palette.background);
    canvas.drawRRect(
      shape,
      Paint()..color = dimmed ? color.withValues(alpha: 0.22) : color,
    );
    if (isOpen) {
      // La cuerda al aire lleva anillo: se distingue también sin el color.
      canvas.drawRRect(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = dimmed
              ? palette.textPrimary.withValues(alpha: 0.3)
              : palette.textPrimary,
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
        color: dimmed ? palette.textSecondary : palette.onInterval,
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
      old.geometry.fretWidth != geometry.fretWidth ||
      old.geometry.startFret != geometry.startFret ||
      old.geometry.endFret != geometry.endFret ||
      old.layer != layer ||
      old.numberEveryFret != numberEveryFret ||
      old.label != label ||
      !identical(old.links, links) ||
      old.palette != palette ||
      !identical(old.highlighted, highlighted) ||
      !identical(old.coordinates, coordinates);
}
