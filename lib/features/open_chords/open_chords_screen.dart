import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../courses/course_progress.dart';
import '../courses/course_widgets.dart';
import 'open_chords_course_provider.dart';

/// Curso "Acordes abiertos – Parte 1": niveles en vertical con sus pasos y
/// resultados.
class OpenChordsScreen extends ConsumerWidget {
  const OpenChordsScreen({super.key});

  static String routeOf(String stepId) => '/learn/open-chords/$stepId';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levels = ref.watch(openChordsCourseProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.hubOpenChords)),
      body: levels == null
          ? const Center(child: CircularProgressIndicator())
          : CourseOverview(
              course: CourseId.openChords,
              intro: AppStrings.openChordsIntro,
              levels: levels,
              routeOf: routeOf,
            ),
    );
  }
}
