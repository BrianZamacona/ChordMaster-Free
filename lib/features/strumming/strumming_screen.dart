import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../courses/course_progress.dart';
import '../courses/course_widgets.dart';
import 'strumming_course_provider.dart';

/// Curso "Patrones de rasgueo – Parte 1": niveles en vertical con sus pasos y
/// resultados.
class StrummingScreen extends ConsumerWidget {
  const StrummingScreen({super.key});

  static String routeOf(String stepId) => '/learn/strumming/$stepId';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levels = ref.watch(strummingCourseProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.hubStrumming)),
      body: levels == null
          ? const Center(child: CircularProgressIndicator())
          : CourseOverview(
              course: CourseId.strumming,
              intro: AppStrings.strummingIntro,
              levels: levels,
              routeOf: routeOf,
            ),
    );
  }
}
