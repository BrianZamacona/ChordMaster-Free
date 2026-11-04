import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/lessons/curriculum.dart';
import '../../ui/theme.dart';
import 'lesson_widgets.dart';
import 'lessons_viewmodel.dart';

/// Una unidad del mapa: su dibujo, el avance y sus lecciones.
class LessonUnitScreen extends ConsumerWidget {
  const LessonUnitScreen({super.key, required this.unitId});

  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = unitsById[unitId];
    if (unit == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.lessonsTitle)),
        body: Center(child: Text(AppStrings.unitNotFound)),
      );
    }
    final path = ref.watch(lessonsViewModelProvider.select((s) => s.path));
    final lessons = lessonsOfUnit(unit);
    final done = lessons.where(path.isDone).length;
    final next = path.next;
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(unit.title.text)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  UnitArtView(art: unit.art, size: 88),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trackName(unit.track),
                          style: text.labelMedium
                              ?.copyWith(color: p.textSecondary),
                        ),
                        Text(unit.title.text, style: text.titleLarge),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: done / lessons.length,
                          color: p.accent,
                          backgroundColor: p.surfaceHigh,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.lessonsProgress(done, lessons.length),
                          style: musicMono(fontSize: 12, color: p.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final lesson in lessons)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: LessonTile(
                lesson: lesson,
                done: path.isDone(lesson),
                isNext: lesson == next,
              ),
            ),
        ],
      ),
    );
  }
}
