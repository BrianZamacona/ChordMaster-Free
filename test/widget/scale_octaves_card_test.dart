import 'package:chordmaster_free/ui/scales/detail/widgets/scale_theory_cards.dart';
import 'package:chordmaster_free/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('octavas: 8 formas, al elegir una cambia la explicación', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          body: ListView(children: const [ScaleOctavesCard(rootSemitone: 0)]),
        ),
      ),
    );

    expect(find.byKey(const Key('octaves-board')), findsOneWidget);
    for (var i = 0; i < 8; i++) {
      expect(find.byKey(Key('octave-shape-$i')), findsOneWidget);
    }
    String explanation() =>
        tester.widget<Text>(find.byKey(const Key('octave-shape-text'))).data!;
    expect(explanation(), contains('2 trastes hacia el cuerpo'));

    await tester.tap(find.byKey(const Key('octave-shape-7')));
    await tester.pump();
    expect(explanation(), contains('dos octavas'));
    expect(explanation(), contains('mismo traste'));
  });
}
