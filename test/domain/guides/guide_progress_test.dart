import 'package:chordmaster_free/domain/guides/guide_progress.dart';
import 'package:chordmaster_free/domain/guides/guides.dart';
import 'package:chordmaster_free/domain/lessons/curriculum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Una guía con un capítulo de lección y otro que no lo es.
  final mixed = guides.firstWhere(
    (g) =>
        g.chapters.any((c) => c.target is LessonLink) &&
        g.chapters.any((c) => c.target is! LessonLink),
  );
  final lessonIndex = mixed.chapters.indexWhere((c) => c.target is LessonLink);
  final otherIndex = mixed.chapters.indexWhere((c) => c.target is! LessonLink);
  final lessonId = (mixed.chapters[lessonIndex].target as LessonLink).lessonId;

  /// Las guías [gs] completas: sus lecciones terminadas y el resto marcado.
  GuideProgress finished(Iterable<Guide> gs) => GuideProgress(
    checked: {
      for (final g in gs)
        for (var i = 0; i < g.chapters.length; i++) chapterKey(g, i),
    },
    lessonsCompleted: {
      for (final g in gs)
        for (final c in g.chapters)
          if (c.target case LessonLink(:final lessonId)) lessonId,
    },
  );

  group('minutos', () {
    test('un capítulo de lección dura lo que dice la lección', () {
      expect(
        chapterMinutes(LessonLink(lessonId)),
        lessonsById[lessonId]!.minutes,
      );
    });

    test('la guía suma sus capítulos y ninguna pasa de una hora', () {
      for (final g in guides) {
        final sum = g.chapters.fold(0, (s, c) => s + chapterMinutes(c.target));
        expect(guideMinutes(g), sum, reason: g.id);
        expect(guideMinutes(g), inInclusiveRange(5, 60), reason: g.id);
      }
    });
  });

  group('capítulos hechos', () {
    test('el de lección sigue a la lección, no a la marca', () {
      final marked = GuideProgress(checked: {chapterKey(mixed, lessonIndex)});
      expect(marked.isDone(mixed, lessonIndex), isFalse);
      final learned = GuideProgress(lessonsCompleted: {lessonId});
      expect(learned.isDone(mixed, lessonIndex), isTrue);
    });

    test('el resto se marca a mano', () {
      final progress = GuideProgress(checked: {chapterKey(mixed, otherIndex)});
      expect(progress.isDone(mixed, otherIndex), isTrue);
      expect(progress.doneCount(mixed), 1);
      expect(progress.isStarted(mixed), isTrue);
      expect(progress.inProgress(), [mixed]);
    });

    test('nada hecho: no está empezada y el siguiente es el primero', () {
      const progress = GuideProgress();
      expect(progress.isStarted(mixed), isFalse);
      expect(progress.nextChapter(mixed), 0);
      expect(progress.inProgress(), isEmpty);
    });

    test('todo hecho: terminada, sin capítulo siguiente ni en curso', () {
      final progress = finished([mixed]);
      expect(progress.isFinished(mixed), isTrue);
      expect(progress.isStarted(mixed), isFalse);
      expect(progress.nextChapter(mixed), isNull);
    });
  });

  group('siguiente guía', () {
    test('sin progreso, la siguiente de la fila', () {
      for (final c in GuideCategory.values) {
        final row = guidesIn(c);
        for (var i = 0; i < row.length - 1; i++) {
          expect(const GuideProgress().nextGuide(row[i]), row[i + 1]);
        }
      }
    });

    test('al final de la fila salta a la siguiente fila', () {
      final row = guidesIn(GuideCategory.values.first);
      final next = const GuideProgress().nextGuide(row.last);
      expect(next, guidesIn(GuideCategory.values[1]).first);
    });

    test('salta las terminadas', () {
      final row = guidesIn(GuideCategory.values.first);
      final progress = finished([row[1]]);
      expect(progress.nextGuide(row[0]), row[2]);
    });

    test('con todo terminado no hay siguiente', () {
      expect(finished(guides).nextGuide(guides.first), isNull);
    });
  });
}
