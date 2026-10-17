import 'package:chordmaster_free/domain/voicing/ergonomics.dart';
import 'package:chordmaster_free/domain/voicing/voicing_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_decoding.dart';

void main() {
  test('coincide con el golden del sandbox TS (400 casos)', () {
    final cases = (loadGolden('ergonomics') as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(cases, hasLength(400));

    var finite = 0;
    for (var i = 0; i < cases.length; i++) {
      final c = cases[i];
      final cost = calculateErgonomicCost(
        decodeVoicing(c['voicing'] as Map<String, dynamic>),
        decodeErgonomicOptions(c['options'] as Map<String, dynamic>),
      );
      final expected = decodeCost(c['cost']);
      if (expected.isFinite) {
        finite++;
        expect(cost, closeTo(expected, 1e-9), reason: 'caso $i');
      } else {
        expect(cost, double.infinity, reason: 'caso $i');
      }
    }
    expect(finite, greaterThanOrEqualTo(167));
  });

  test('isOpenPosition: cuerda al aire y nada más allá del traste 4', () {
    bool open(List<int> json) =>
        isOpenPosition(VoicingAdapter.fromChordJson(json));
    expect(open([-1, 3, 2, 0, 1, 0]), isTrue); // C
    expect(open([3, 2, 0, 0, 0, 3]), isTrue); // G
    expect(open([-1, 3, 5, 5, 5, 3]), isFalse); // C con cejilla
    expect(open([1, 3, 3, 2, 1, 1]), isFalse); // F, sin cuerdas al aire
    expect(open([-1, -1, 0, 9, 8, 8]), isFalse); // al aire pero arriba
  });

  test('el adaptador invierte 6ª→1ª y convierte -1 en null', () {
    expect(
      VoicingAdapter.fromChordJson([-1, 3, 2, 0, 1, 0]),
      [0, 1, 0, 2, 3, null],
    );
  });

  test('un costo individual 0 no se trata como ausente', () {
    expect(
      calculateErgonomicCost(
        decodeVoicing({
          'fretPositions': ['x', 'x', 4, 4, 0, 4],
        }),
      ),
      0,
    );
  });
}
