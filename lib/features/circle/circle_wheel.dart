import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/theory/circle_of_fifths.dart';
import '../../domain/theory/notes.dart';
import '../../ui/theme.dart';

/// El círculo de quintas como una rueda que se gira con el dedo.
///
/// La rotación vive en un [AnimationController] que repinta solo el
/// [CustomPainter]; hacia afuera solo sale la tonalidad cuando cambia, así el
/// resto de la pantalla no se reconstruye en cada frame.
class CircleWheel extends StatefulWidget {
  const CircleWheel({
    super.key,
    required this.initialIndex,
    required this.semanticLabel,
    required this.onIndexChanged,
    this.onClick,
  });

  final int initialIndex;

  /// Tonalidad actual en palabras; se anuncia al cambiar.
  final String semanticLabel;
  final ValueChanged<int> onIndexChanged;

  /// Una tonalidad pasó por la ventana (además de la vibración).
  final VoidCallback? onClick;

  @override
  State<CircleWheel> createState() => CircleWheelState();
}

class CircleWheelState extends State<CircleWheel>
    with SingleTickerProviderStateMixin {
  /// Por debajo de esta velocidad (grados/s) no hay inercia: solo se acomoda.
  static const _minFlingVelocity = 40.0;

  /// Fricción de la inercia: fracción de velocidad que queda tras un segundo.
  static const _friction = 0.12;

  late final AnimationController _rotation;
  late double _lastRotation;
  late int _index;
  int? _goal;
  Offset _lastTouch = Offset.zero;
  double _size = 0;
  _WheelLabels? _labels;
  AppPalette? _labelsPalette;

  /// Rotación actual, en grados.
  @visibleForTesting
  double get rotation => _rotation.value;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _lastRotation = rotationForIndex(_index);
    _rotation = AnimationController.unbounded(vsync: this, value: _lastRotation)
      ..addListener(_onRotation);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final palette = context.palette;
    if (palette != _labelsPalette) {
      _labels?.dispose();
      _labels = _WheelLabels(palette);
      _labelsPalette = palette;
    }
  }

  @override
  void dispose() {
    _rotation.dispose();
    _labels?.dispose();
    super.dispose();
  }

  void _onRotation() {
    final value = _rotation.value;
    if (clicksBetween(_lastRotation, value) > 0) {
      HapticFeedback.selectionClick();
      widget.onClick?.call();
    }
    _lastRotation = value;
    final index = indexAtWindow(value);
    if (index != _index) {
      _index = index;
      widget.onIndexChanged(index);
    }
  }

  Offset _fromCenter(Offset local) => local - Offset(_size / 2, _size / 2);

  void _onPanDown(DragDownDetails details) {
    _rotation.stop();
    _goal = null;
    _lastTouch = _fromCenter(details.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final touch = _fromCenter(details.localPosition);
    _rotation.value += angleDelta(
      touchAngle(_lastTouch.dx, _lastTouch.dy),
      touchAngle(touch.dx, touch.dy),
    );
    _lastTouch = touch;
  }

  void _onPanEnd(DragEndDetails details) {
    final velocity = angularVelocity(
      _lastTouch.dx,
      _lastTouch.dy,
      details.velocity.pixelsPerSecond.dx,
      details.velocity.pixelsPerSecond.dy,
    );
    if (_reduceMotion || velocity.abs() < _minFlingVelocity) {
      _settle();
      return;
    }
    _rotation
        .animateWith(
          FrictionSimulation(
            _friction,
            _rotation.value,
            velocity,
            tolerance: const Tolerance(velocity: _minFlingVelocity),
          ),
        )
        .whenComplete(_settle);
  }

  /// Acomoda la rueda en la posición más cercana.
  void _settle() {
    if (!mounted) return;
    final target = snapRotation(_rotation.value);
    if (target == _rotation.value) return;
    if (_reduceMotion) {
      _rotation.value = target;
    } else {
      _rotation.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onTapUp(TapUpDetails details) {
    final touch = _fromCenter(details.localPosition);
    final radius = touch.distance;
    final g = _WheelGeometry(_size);
    if (radius < g.innerRadius || radius > g.outerRadius) return;
    goTo(indexAtTouch(touchAngle(touch.dx, touch.dy), _rotation.value));
  }

  /// Lleva [index] a la ventana por el camino más corto.
  void goTo(int index) {
    final wrapped = index % circleLength;
    _goal = wrapped;
    final target = rotationToward(_rotation.value, wrapped);
    if (_reduceMotion) {
      _rotation.stop();
      _rotation.value = target;
      return;
    }
    final steps = clicksBetween(_rotation.value, target);
    _rotation
        .animateTo(
          target,
          duration: Duration(milliseconds: 200 + 70 * steps),
          curve: Curves.easeInOutCubic,
        )
        .whenComplete(() => _goal = null);
  }

  /// Gira un paso; varios toques seguidos se acumulan.
  void _step(int delta) => goTo((_goal ?? _index) + delta);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      _size = math.min(constraints.maxWidth, constraints.maxHeight);
      return Center(
        child: SizedBox.square(
          dimension: _size,
          child: Stack(
            children: [
              Positioned.fill(
                child: Semantics(
                  liveRegion: true,
                  label: widget.semanticLabel,
                  hint: AppStrings.circleWheelHint,
                  onIncrease: () => _step(1),
                  onDecrease: () => _step(-1),
                  excludeSemantics: true,
                  child: GestureDetector(
                    key: const Key('circle-wheel-gestures'),
                    dragStartBehavior: DragStartBehavior.down,
                    onPanDown: _onPanDown,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    onPanCancel: _settle,
                    onTapUp: _onTapUp,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _WheelPainter(
                          rotation: _rotation,
                          labels: _labels!,
                          palette: context.palette,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                bottom: 0,
                child: IconButton(
                  key: const Key('circle-step-left'),
                  tooltip: AppStrings.circleStepLeft,
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _step(-1),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: IconButton(
                  key: const Key('circle-step-right'),
                  tooltip: AppStrings.circleStepRight,
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _step(1),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Medidas de la rueda y UNA función de coordenadas para todo lo que se dibuja.
class _WheelGeometry {
  const _WheelGeometry(this.size);

  /// Espacio exterior para los números romanos de la ventana.
  static const margin = 18.0;

  final double size;

  Offset get center => Offset(size / 2, size / 2);
  double get outerRadius => size / 2 - margin;
  double get middleRadius => outerRadius * 0.68;
  double get innerRadius => outerRadius * 0.40;

  /// Punto a [radius] del centro, en [degrees] horarios desde arriba.
  Offset point(double radius, double degrees) {
    final a = degrees * math.pi / 180;
    return center + Offset(math.sin(a) * radius, -math.cos(a) * radius);
  }

  /// Sector de anillo entre dos radios, centrado en [degrees] y de [span]°.
  Path sector(double from, double to, double degrees, double span) {
    final start = (degrees - span / 2 - 90) * math.pi / 180;
    final sweep = span * math.pi / 180;
    return Path()
      ..arcTo(Rect.fromCircle(center: center, radius: to), start, sweep, true)
      ..arcTo(
        Rect.fromCircle(center: center, radius: from),
        start + sweep,
        -sweep,
        false,
      )
      ..close();
  }
}

/// Textos ya medidos: un giro no vuelve a medirlos en cada frame.
class _WheelLabels {
  _WheelLabels(AppPalette p)
    : _painters = [],
      majors = [],
      signatures = [],
      minors = [],
      centerNames = [],
      centerSignatures = [],
      outerNumerals = [],
      innerNumerals = [] {
    TextPainter text(String s, double size, Color color, FontWeight weight) {
      final painter = TextPainter(
        text: TextSpan(
          text: s,
          style: musicMono(fontSize: size, fontWeight: weight, color: color),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      _painters.add(painter);
      return painter;
    }

    for (var i = 0; i < circleLength; i++) {
      final name = pitchClassName(circleOrder[i]);
      final signature = keySignatureAt(i).short;
      majors.add(text(name, 15, p.textPrimary, FontWeight.w600));
      signatures.add(text(signature, 11, p.textSecondary, FontWeight.w400));
      minors.add(
        text(
          '${pitchClassName(relativeMinorOf(circleOrder[i]))}m',
          12,
          p.textPrimary,
          FontWeight.w400,
        ),
      );
      centerNames.add(text(name, 26, p.accent, FontWeight.w600));
      centerSignatures.add(
        text(signature, 12, p.textSecondary, FontWeight.w400),
      );
    }
    // Cualquier tonalidad da los mismos números en la ventana.
    for (final chord in diatonicWindow(0)) {
      final label = text(chord.numeral, 11, p.accent, FontWeight.w600);
      switch (chord.place) {
        case WindowPlace.outerRing:
          outerNumerals.add((label, chord.offset));
        case WindowPlace.innerRing:
          innerNumerals.add((label, chord.offset));
        case WindowPlace.outside:
          _painters.remove(label);
          label.dispose();
      }
    }
  }

  final List<TextPainter> _painters;
  final List<TextPainter> majors;
  final List<TextPainter> signatures;
  final List<TextPainter> minors;
  final List<TextPainter> centerNames;
  final List<TextPainter> centerSignatures;

  /// Números romanos fijos de la ventana, con su paso desde el centro.
  final List<(TextPainter, int)> outerNumerals;
  final List<(TextPainter, int)> innerNumerals;

  void dispose() {
    for (final p in _painters) {
      p.dispose();
    }
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({
    required this.rotation,
    required this.labels,
    required this.palette,
  }) : super(repaint: rotation);

  final Animation<double> rotation;
  final _WheelLabels labels;
  final AppPalette palette;

  void _paintCentered(Canvas canvas, TextPainter text, Offset at) =>
      text.paint(canvas, at - Offset(text.width / 2, text.height / 2));

  @override
  void paint(Canvas canvas, Size size) {
    final g = _WheelGeometry(size.shortestSide);
    final angle = rotation.value;
    final center = g.center;

    // El disco: dos anillos y el hueco.
    canvas
      ..drawCircle(center, g.outerRadius, Paint()..color = palette.surface)
      ..drawCircle(center, g.middleRadius, Paint()..color = palette.surfaceHigh)
      ..drawCircle(center, g.innerRadius, Paint()..color = palette.background);

    // La ventana no gira: resalta los tres vecinos y, más, la tonalidad.
    const step = wheelStepDegrees;
    final window = Paint()..color = palette.accent.withValues(alpha: 0.16);
    final chosen = Paint()..color = palette.accent.withValues(alpha: 0.28);
    canvas
      ..drawPath(g.sector(g.innerRadius, g.outerRadius, 0, step * 3), window)
      ..drawPath(g.sector(g.innerRadius, g.outerRadius, 0, step), chosen);

    // Los separadores giran con el disco.
    final spoke = Paint()
      ..color = palette.outline
      ..strokeWidth = 1;
    for (var i = 0; i < circleLength; i++) {
      final a = angle + i * step + step / 2;
      canvas.drawLine(
        g.point(g.innerRadius, a),
        g.point(g.outerRadius, a),
        spoke,
      );
    }
    canvas.drawCircle(
      center,
      g.middleRadius,
      Paint()
        ..color = palette.outline
        ..style = PaintingStyle.stroke,
    );

    // Las etiquetas giran alrededor del centro, pero se leen siempre derechas.
    final majorRadius = (g.outerRadius + g.middleRadius) / 2;
    final minorRadius = (g.middleRadius + g.innerRadius) / 2;
    for (var i = 0; i < circleLength; i++) {
      final a = angle + i * step;
      final at = g.point(majorRadius, a);
      _paintCentered(canvas, labels.majors[i], at - const Offset(0, 7));
      _paintCentered(canvas, labels.signatures[i], at + const Offset(0, 9));
      _paintCentered(canvas, labels.minors[i], g.point(minorRadius, a));
    }

    // Marco de la ventana y sus números, encima de todo.
    canvas.drawPath(
      g.sector(g.innerRadius, g.outerRadius, 0, step * 3),
      Paint()
        ..color = palette.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (final (label, offset) in labels.outerNumerals) {
      _paintCentered(
        canvas,
        label,
        g.point(g.outerRadius + _WheelGeometry.margin / 2, offset * step),
      );
    }
    for (final (label, offset) in labels.innerNumerals) {
      _paintCentered(
        canvas,
        label,
        g.point(g.innerRadius - 9, offset * step * 1.1),
      );
    }

    // En el hueco, la tonalidad de la ventana.
    final index = indexAtWindow(angle);
    _paintCentered(
      canvas,
      labels.centerNames[index],
      center - const Offset(0, 2),
    );
    _paintCentered(
      canvas,
      labels.centerSignatures[index],
      center + const Offset(0, 19),
    );
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      !identical(old.labels, labels) || old.palette != palette;
}
