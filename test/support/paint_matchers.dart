import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// El lienzo dibuja la cejuela: la única línea de grosor 3.
PaintPattern get paintsNut => paints
  ..something(
    (method, args) =>
        method == #drawLine && (args[2] as Paint).strokeWidth == 3,
  );

/// Cuántos anillos de cuerda al aire (rectángulos con borde) hay en [render].
int openRingCount(RenderObject render) {
  var rings = 0;
  expect(
    render,
    paints
      ..everything((method, args) {
        if (method == #drawRRect &&
            (args[1] as Paint).style == PaintingStyle.stroke) {
          rings++;
        }
        return true;
      }),
  );
  return rings;
}
