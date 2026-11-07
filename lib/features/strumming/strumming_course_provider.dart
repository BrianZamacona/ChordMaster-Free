import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/courses/course.dart';
import '../../domain/strumming/strumming_course.dart';
import '../courses/course_shapes_provider.dart';

/// El curso de rasgueos con las digitaciones de `chords.json`; `null` mientras
/// se cargan los acordes.
final strummingCourseProvider = NotifierProvider<
  CourseFromShapes<List<CourseLevel<StrumStep>>>,
  List<CourseLevel<StrumStep>>?
>(() => CourseFromShapes(strummingCourseChords, buildStrummingCourse));
