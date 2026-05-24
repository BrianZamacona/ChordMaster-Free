import 'package:chordmaster_free/features/scales/domain/services/reverse_harmonization_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matchScalesForChord finds strict and tolerant matches', () {
    const service = ReverseHarmonizationService();

    final result = service.matchScalesForChord(const [0, 4, 7]);

    expect(result.strictMatches, isNotEmpty);
    expect(result.tolerantMatches, isNotEmpty);
    expect(result.tolerantMatches.contains('major'), isTrue);
  });
}
