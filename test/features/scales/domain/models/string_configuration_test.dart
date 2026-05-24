import 'package:chordmaster_free/features/scales/domain/models/string_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('standard6 maps string 1 to low E and string 6 to high E', () {
    const config = StringConfiguration.standard6;

    expect(config.openNoteForString(1), 'E');
    expect(config.openNoteForString(2), 'A');
    expect(config.openNoteForString(3), 'D');
    expect(config.openNoteForString(4), 'G');
    expect(config.openNoteForString(5), 'B');
    expect(config.openNoteForString(6), 'E');
  });

  test('openNoteForString applies per-string capo offsets', () {
    final config = StringConfiguration.standard6.copyWith(
      capoByString: const {1: 2, 2: 2, 3: 2, 4: 2, 5: 2, 6: 2},
    );

    expect(config.openNoteForString(1), 'F#');
    expect(config.openNoteForString(6), 'F#');
  });

  test('banjo preset exposes drone string metadata', () {
    const config = StringConfiguration.banjo5Drone;
    expect(config.stringCount, 5);
    expect(config.droneStrings.contains(5), isTrue);
  });
}
