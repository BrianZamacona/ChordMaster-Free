import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Returns [child] wrapped in a [TweenAnimationBuilder] that fades it in
/// from opacity `0` to `1` over [duration].
Widget fadeIn(
  Widget child, {
  Duration duration = const Duration(milliseconds: 400),
}) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: 1),
    duration: duration,
    builder: (context, value, builtChild) => Opacity(opacity: value, child: builtChild),
    child: child,
  );

/// Returns [child] wrapped in a [TweenAnimationBuilder] that slides it up
/// from 24 logical pixels below its final position while simultaneously
/// fading it in, over [duration].
Widget slideUpFade(
  Widget child, {
  Duration duration = const Duration(milliseconds: 500),
}) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: 1),
    duration: duration,
    curve: Curves.easeOut,
    builder: (context, value, builtChild) {
      final double offset = 24.0 * (1.0 - value);
      return Transform.translate(
        offset: Offset(0, offset),
        child: Opacity(opacity: value, child: builtChild),
      );
    },
    child: child,
  );

/// Returns [child] wrapped in a [TweenAnimationBuilder] that scales it in
/// from `0` to `1` with a slight fade, over [duration].
Widget scaleIn(
  Widget child, {
  Duration duration = const Duration(milliseconds: 350),
}) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: 1),
    duration: duration,
    curve: Curves.easeOutBack,
    builder: (context, value, builtChild) => Transform.scale(
        scale: value,
        child: Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: builtChild,
        ),
      ),
    child: child,
  );

/// Returns an [Animation] that produces a repeating scale pulse from `1.0`
/// to `1.08` using [Curves.easeInOut].
///
/// Pair with [ScaleTransition] to create a heartbeat-style pulse effect.
/// The [controller] must be a repeating [AnimationController].
Animation<double> pulseAnimation(AnimationController controller) => Tween<double>(begin: 1.0, end: 1.08).animate(
    CurvedAnimation(parent: controller, curve: Curves.easeInOut),
  );

/// Returns a list of 12 small animated coloured dots for a confetti effect.
///
/// Each dot uses [AnimatedBuilder] driven by [controller]'s value to animate
/// its position outward from the centre of a fixed-size [Stack].
///
/// Wrap the returned list in a [Stack] widget:
/// ```dart
/// Stack(
///   clipBehavior: Clip.none,
///   children: confettiParticles(controller),
/// )
/// ```
List<Widget> confettiParticles(AnimationController controller) {
  const int count = 12;
  const double containerSize = 120;
  const double dotSize = 8;
  const double radius = 50;

  return List<Widget>.generate(count, (index) {
    final double angle = (index / count) * 2 * math.pi;
    final Color color =
        Colors.primaries[index % Colors.primaries.length].shade400;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final double progress = controller.value;
        final double dx =
            containerSize / 2 + radius * progress * math.cos(angle) - dotSize / 2;
        final double dy =
            containerSize / 2 + radius * progress * math.sin(angle) - dotSize / 2;
        final double opacity = (1.0 - progress).clamp(0.0, 1.0);

        return Positioned(
          left: dx,
          top: dy,
          child: Opacity(
            opacity: opacity,
            child: child!,
          ),
        );
      },
      child: Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  });
}
