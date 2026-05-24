import 'package:chordmaster_free/features/scales/domain/services/roman_progression_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('transpose resolves roman progression in major scale', () {
    const service = RomanProgressionService();

    final notes = service.transpose(
      root: 'C',
      scaleIntervals: const [0, 2, 4, 5, 7, 9, 11],
      degrees: const ['I', 'vi', 'IV', 'V'],
    );

    expect(notes, ['C', 'A', 'F', 'G']);
  });
}
