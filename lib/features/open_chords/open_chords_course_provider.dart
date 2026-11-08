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

/// La Parte 2 (Am, E y A, con los de la Parte 1); `null` mientras cargan.
final openChords2CourseProvider = NotifierProvider<
  CourseFromShapes<List<CourseLevel<OpenChordStep>>>,
  List<CourseLevel<OpenChordStep>>?
>(() => CourseFromShapes(openChordsPart2.chords, buildOpenChordsCourse2));
