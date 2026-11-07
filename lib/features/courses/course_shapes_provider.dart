import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/open_chords/chord_shape.dart';
import '../chords/chord_viewmodel.dart';

/// Las digitaciones principales de `chords.json` de los acordes [names], por
/// nombre; `null` mientras se cargan los acordes.
Map<String, ChordShape>? chordShapesFrom(ChordViewModel vm, List<String> names) {
  final shapes = <String, ChordShape>{};
  for (final name in names) {
    final chord = vm.findByName(name);
    if (chord == null) return null;
    shapes[name] = ChordShape(
      name: name,
      frets: chord.fretPositions,
      fingers: chord.fingerPositions,
    );
  }
  return shapes;
}

/// Un curso armado con digitaciones de `chords.json`. Se arma de nuevo cuando
/// cargan los acordes (`ref.listen`), no al dibujar: así un proveedor que
/// depende de él no se recalcula en cadena cuando una pestaña oculta vuelve.
class CourseFromShapes<T> extends Notifier<T?> {
  CourseFromShapes(this.names, this.make);

  final List<String> names;
  final T Function(Map<String, ChordShape> shapes) make;

  @override
  T? build() {
    ref.listen(
      chordViewModelProvider.select((s) => s.allChords.length),
      (_, _) => state = _build(),
    );
    return _build();
  }

  T? _build() {
    final shapes = chordShapesFrom(ref.read(chordViewModelProvider.notifier), names);
    return shapes == null ? null : make(shapes);
  }
}
