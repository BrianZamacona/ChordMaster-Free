import 'package:chordmaster_free/features/scales/domain/services/direct_harmonization_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('harmonizeTriads builds diatonic triads for major scale', () {
    const service = DirectHarmonizationService();

    final result = service.harmonizeTriads(
      root: 'C',
      scaleIntervals: const [0, 2, 4, 5, 7, 9, 11],
    );

    expect(result, hasLength(7));
    expect(result.first.degree, 'I');
    expect(result.first.chord, 'C');
    expect(result[1].chord, 'Dm');
    expect(result[6].quality, 'diminished');
  });
}
