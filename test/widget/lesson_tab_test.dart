import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/features/lessons/lesson_tab.dart';
import 'package:chordmaster_free/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  Future<void> pump(
    WidgetTester tester,
    List<TabNote> notes, {
    bool showFingers = true,
    double width = 360,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 800);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: LessonTabView(notes: notes, showFingers: showFingers),
          ),
        ),
      ),
    );
  }

  String hint(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('lesson-tab-hint'))).data!;

  double lineHeight(WidgetTester tester) =>
      tester.getSize(find.byKey(const Key('lesson-tab-line-0'))).height;

  const firstPosition = [TabNote(1, 0), TabNote(1, 1), TabNote(1, 3), TabNote(2, 2)];

  testWidgets('con un dedo por traste: fila de dedos y su explicación', (tester) async {
    await pump(tester, firstPosition);
    expect(hint(tester), contains(AppStrings.lessonTabFingersHint));
    final withFingers = lineHeight(tester);
    await pump(tester, firstPosition, showFingers: false);
    expect(hint(tester), AppStrings.lessonTabHint);
    expect(withFingers, greaterThan(lineHeight(tester)));
  });

  testWidgets('el lector de pantalla dice el dedo de cada nota pisada', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, firstPosition);
    final label = find.bySemanticsLabel(RegExp(RegExp.escape(AppStrings.lessonTabNote(1, 3, finger: 3))));
    expect(label, findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('${RegExp.escape(AppStrings.lessonTabNote(1, 0))}(,|\$)')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('si la mano se mueve (más de cuatro trastes), no hay fila', (tester) async {
    await pump(tester, const [TabNote(1, 1), TabNote(1, 7)]);
    expect(hint(tester), AppStrings.lessonTabHint);
  });

  testWidgets('todo al aire: no hay fila', (tester) async {
    await pump(tester, const [TabNote(1, 0), TabNote(2, 0)]);
    expect(hint(tester), AppStrings.lessonTabHint);
  });

  for (final lang in AppLanguage.values) {
    testWidgets('a 360 dp (${lang.name}) ocho notas con dedos caben', (tester) async {
      CurrentLanguage.value = lang;
      await pump(tester, const [
        TabNote(6, 5), TabNote(6, 6), TabNote(6, 7), TabNote(6, 8), //
        TabNote(5, 5), TabNote(5, 6), TabNote(5, 7), TabNote(5, 8),
      ]);
      expect(tester.takeException(), isNull);
      expect(hint(tester), contains(AppStrings.lessonTabFingersHint));
      expect(tester.getRect(find.byKey(const Key('lesson-tab-line-0'))).right, lessThanOrEqualTo(360));
    });
  }
}
