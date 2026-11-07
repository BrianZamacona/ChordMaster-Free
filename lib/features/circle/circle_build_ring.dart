import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/theory/circle_of_fifths.dart';
import '../../domain/theory/notes.dart';
import '../../ui/theme.dart';

/// Centro del nodo [index] del círculo: C arriba y en el sentido del reloj.
Offset ringNodeOffset(int index, Offset center, double radius) {
  final angle = index * wheelStepDegrees * math.pi / 180;
  return center + Offset(math.sin(angle), -math.cos(angle)) * radius;
}

/// El círculo a medio armar: las tonalidades alcanzadas llevan su nombre y una
/// línea une cada una con la siguiente; en el centro, la tonalidad actual.
class CircleBuildRing extends StatelessWidget {
  const CircleBuildRing({super.key, required this.step});

  static const maxSize = 200.0;

  final CircleStep step;

  @override
  Widget build(BuildContext context) => Center(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, maxSize);
        return Semantics(
          label: AppStrings.circleBuildRingLabel(
            math.min(step.number + 1, circleLength),
            pitchClassName(step.tonic),
            step.signature.short,
          ),
          excludeSemantics: true,
          child: CustomPaint(
            size: Size.square(side),
            painter: _RingPainter(step: step, palette: context.palette),
          ),
        );
      },
    ),
  );
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.step, required this.palette});

  static const _nodeRadius = 17.0;

  final CircleStep step;
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - _nodeRadius - 1;
    Offset node(int i) => ringNodeOffset(i, center, radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = palette.outline,
    );

    final path = Paint()
      ..color = palette.accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var n = 1; n <= step.number; n++) {
      canvas.drawLine(node(n - 1), node(n % circleLength), path);
    }

    final current = step.number % circleLength;
    for (var i = 0; i < circleLength; i++) {
      final reached = i <= step.number;
      final isCurrent = i == current;
      final c = node(i);
      canvas
        ..drawCircle(
          c,
          _nodeRadius,
          Paint()..color = isCurrent ? palette.accent : palette.surfaceHigh,
        )
        ..drawCircle(
          c,
          _nodeRadius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = reached ? 2 : 1
            ..color = reached ? palette.accent : palette.outline,
        );
      if (reached) {
        _text(
          canvas,
          pitchClassName(circleOrder[i]),
          c,
          size: 13,
          weight: FontWeight.w600,
          color: isCurrent ? palette.onAccent : palette.textPrimary,
        );
      }
    }

    _text(
      canvas,
      pitchClassName(step.tonic),
      center - const Offset(0, 12),
      size: 34,
      weight: FontWeight.w600,
      color: palette.accent,
    );
    _text(
      canvas,
      step.signature.short,
      center + const Offset(0, 20),
      size: 15,
      color: palette.textSecondary,
    );
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
  bool shouldRepaint(_RingPainter old) =>
      old.step.number != step.number || old.palette != palette;
}
