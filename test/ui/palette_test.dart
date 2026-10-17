import 'package:chordmaster_free/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contraste WCAG entre dos colores opacos.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // google_fonts lee las fuentes empaquetadas del AssetManifest.
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final (name, p) in [
    ('oscura', AppPalette.dark),
    ('clara', AppPalette.light),
  ]) {
    group('paleta $name', () {
      test('texto legible (≥ 4.5:1) sobre fondo y tarjeta', () {
        for (final bg in [p.background, p.surface]) {
          expect(_contrast(p.textPrimary, bg), greaterThanOrEqualTo(4.5));
          expect(_contrast(p.textSecondary, bg), greaterThanOrEqualTo(4.5));
          expect(_contrast(p.accent, bg), greaterThanOrEqualTo(4.5));
        }
        expect(_contrast(p.onAccent, p.accent), greaterThanOrEqualTo(4.5));
      });

      test('intervalos legibles sobre la tarjeta y con su número de dedo', () {
        for (final c in [
          p.intervalRoot,
          p.intervalThird,
          p.intervalFifth,
          p.intervalSeventh,
          p.intervalTension,
        ]) {
          expect(_contrast(c, p.surface), greaterThanOrEqualTo(3.0));
          expect(_contrast(p.onInterval, c), greaterThanOrEqualTo(4.5));
        }
      });

      test('cada etiqueta de intervalo cae en su familia', () {
        expect(p.intervalColor('R'), p.intervalRoot);
        expect(p.intervalColor('b3'), p.intervalThird);
        expect(p.intervalColor('3'), p.intervalThird);
        expect(p.intervalColor('5'), p.intervalFifth);
        expect(p.intervalColor('b5'), p.intervalFifth);
        expect(p.intervalColor('b7'), p.intervalSeventh);
        expect(p.intervalColor('7'), p.intervalSeventh);
        for (final t in ['b2', '2', '4', 'b6', '6']) {
          expect(p.intervalColor(t), p.intervalTension, reason: t);
        }
      });
    });
  }

  test('los temas registran su paleta', () {
    expect(darkTheme.extension<AppPalette>(), AppPalette.dark);
    expect(lightTheme.extension<AppPalette>(), AppPalette.light);
    expect(darkTheme.colorScheme.primary, AppPalette.dark.accent);
    expect(lightTheme.colorScheme.primary, AppPalette.light.accent);
  });
}
