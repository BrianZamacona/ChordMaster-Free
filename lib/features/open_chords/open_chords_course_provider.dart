import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/courses/course.dart';
import '../../domain/open_chords/open_chords_course.dart';
import '../courses/course_shapes_provider.dart';

/// El curso armado con las digitaciones de `chords.json`; `null` mientras se
/// cargan los acordes.
final openChordsCourseProvider = NotifierProvider<
  CourseFromShapes<List<CourseLevel<OpenChordStep>>>,
  List<CourseLevel<OpenChordStep>>?
>(() => CourseFromShapes(openChordsCourseChords, buildOpenChordsCourse));
