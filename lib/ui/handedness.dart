import 'package:flutter/widgets.dart';

/// Modo zurdo (decisión del usuario tras revisar las apps jam): el mástil y
/// los diagramas se ven como en una guitarra de zurdo, espejados de izquierda a
/// derecha. Los textos de adentro se vuelven a enderezar; la tablatura no
/// cambia (se lee igual con cualquier mano).
class Handedness extends InheritedWidget {
  const Handedness({super.key, required this.leftHanded, required super.child});

  final bool leftHanded;

  /// Si la app está en modo zurdo (sin [Handedness] arriba, diestro).
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Handedness>()?.leftHanded ??
      false;

  @override
  bool updateShouldNotify(Handedness old) => old.leftHanded != leftHanded;
}

/// Espeja [child] de izquierda a derecha en modo zurdo. Los toques y el
/// scroll pasan por la misma transformación, así que siguen cayendo donde se
/// ven; los textos que dibuje un pintor se enderezan con [paintUpright].
class HandedFlip extends StatelessWidget {
  const HandedFlip({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Handedness.of(context)
      ? Transform.flip(flipX: true, child: child)
      : child;
}

/// Pinta [painter] con su esquina en [topLeft]; si el lienzo está espejado
/// ([mirrored]), lo vuelve a voltear sobre su propio centro para que se lea.
void paintUpright(
  Canvas canvas,
  TextPainter painter,
  Offset topLeft, {
  required bool mirrored,
}) {
  if (!mirrored) {
    painter.paint(canvas, topLeft);
    return;
  }
  final centerX = topLeft.dx + painter.width / 2;
  canvas
    ..save()
    ..translate(centerX, 0)
    ..scale(-1, 1)
    ..translate(-centerX, 0);
  painter.paint(canvas, topLeft);
  canvas.restore();
}
