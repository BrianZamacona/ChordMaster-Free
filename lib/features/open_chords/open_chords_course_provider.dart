import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/courses/course.dart';
import '../../domain/open_chords/chord_shape.dart';
import '../../domain/open_chords/open_chords_course.dart';
import '../chords/chord_viewmodel.dart';

/// El curso armado con las digitaciones de `chords.json`; `null` mientras se
/// cargan los acordes.
final openChordsCourseProvider = Provider<List<CourseLevel<OpenChordStep>>?>((ref) {
  ref.watch(chordViewModelProvider.select((s) => s.allChords.length));
  final vm = ref.read(chordViewModelProvider.notifier);
  final shapes = <String, ChordShape>{};
  for (final name in openChordsCourseChords) {
    final chord = vm.findByName(name);
    if (chord == null) return null;
    shapes[name] = ChordShape(
      name: name,
      frets: chord.fretPositions,
      fingers: chord.fingerPositions,
    );
  }
  return buildOpenChordsCourse(shapes);
});
