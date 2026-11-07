import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/melodies/melody_course.dart';
import '../courses/course_progress.dart';
import '../courses/course_widgets.dart';

/// Curso de melodías: niveles en vertical con sus pasos y resultados.
class MelodiesScreen extends StatelessWidget {
  const MelodiesScreen({super.key});

  static String routeOf(String stepId) => '/learn/melodies/$stepId';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppStrings.hubMelodies)),
    body: CourseOverview(
      course: CourseId.melodies,
      intro: AppStrings.melodiesIntro,
      levels: melodyCourse,
      routeOf: routeOf,
    ),
  );
}
