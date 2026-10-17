import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/progressions/progression_data.dart';
import 'package:chordmaster_free/domain/theory/harmony.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Progression prog(List<String> numerals) => Progression('t', '', numerals);

  test('funciones: I iii vi reposo; ii IV preparación; V vii° tensión', () {
    expect(majorDegreeNumerals, ['I', 'ii', 'iii', 'IV', 'V', 'vi', 'vii°']);
    expect(
      [for (final n in majorDegreeNumerals) harmonicFunction(n)],
      [
        HarmonicFunction.tonic,
        HarmonicFunction.subdominant,
        HarmonicFunction.tonic,
        HarmonicFunction.subdominant,
        HarmonicFunction.dominant,
        HarmonicFunction.tonic,
        HarmonicFunction.dominant,
      ],
    );
    for (final n in majorDegreeNumerals) {
      expect(degreeRole(n).es, startsWith('$n:'));
      expect(degreeRole(n).en, startsWith('$n:'));
    }
  });

  test('tríadas por grado en C: notas correctas (vii° disminuido)', () {
    final degrees = prog(majorDegreeNumerals).degrees;
    expect(degreeTriad(degrees[0], 0), {0, 4, 7}); // C E G
    expect(degreeTriad(degrees[1], 0), {2, 5, 9}); // D F A
    expect(degreeTriad(degrees[6], 0), {11, 2, 5}); // B D F
    expect(degreeTriad(degrees[4], 7), {2, 6, 9}); // V de G: D F# A
  });

  test('notas comunes: I–vi y I–iii comparten dos, I–IV una, IV–V ninguna', () {
    final d = {for (final x in prog(majorDegreeNumerals).degrees) x.numeral: x};
    expect(commonTones(d['I']!, d['vi']!, 0), ['C', 'E']);
    expect(commonTones(d['I']!, d['iii']!, 0), ['E', 'G']);
    expect(commonTones(d['I']!, d['IV']!, 0), ['C']);
    expect(commonTones(d['IV']!, d['V']!, 0), isEmpty);
  });

  test('cadencias: auténtica, plagal y rota', () {
    expect(cadence('V', 'I')!.es, contains('auténtica'));
    expect(cadence('vii°', 'I')!.es, contains('auténtica'));
    expect(cadence('IV', 'I')!.es, contains('plagal'));
    expect(cadence('V', 'vi')!.en, contains('deceptive'));
    expect(cadence('I', 'V'), isNull);
  });

  test('I–V–vi–IV: recorrido, cadencia rota y plagal al repetir', () {
    final lines = explainProgression(prog(['I', 'V', 'vi', 'IV']), 0);
    final es = [for (final l in lines) l.es];
    expect(es.first,
        'Recorrido: I (reposo) → V (tensión) → vi (reposo) → IV (preparación).');
    expect(es, contains(startsWith('V → vi: cadencia rota')));
    expect(es, contains(startsWith('IV → I (al repetir): cadencia plagal')));
    expect(es, contains('I → V: comparten la nota G; por eso el cambio suena unido.'));
    expect(es.where((l) => l.contains('semicadencia')), isEmpty);
  });

  test('I–IV–V termina en semicadencia y resuelve V → I al repetir', () {
    final lines = explainProgression(prog(['I', 'IV', 'V']), 2);
    final en = [for (final l in lines) l.en];
    expect(en, contains(startsWith('V → I (on repeat): authentic cadence')));
    expect(en, contains(startsWith('It ends on V (half cadence)')));
    // D–G comparten D.
    expect(en, contains('I → IV: they share D, which is why the change sounds connected.'));
  });

  test('progresión vacía o de un acorde: sin errores', () {
    expect(explainProgression(prog([]), 0), isEmpty);
    expect(explainProgression(prog(['I']), 0), hasLength(1));
  });

  test('LocalizedText sigue al idioma actual', () {
    addTearDown(() => CurrentLanguage.value = AppLanguage.es);
    CurrentLanguage.value = AppLanguage.en;
    expect(harmonicFunctionName(HarmonicFunction.dominant).text, 'tension');
  });
}
