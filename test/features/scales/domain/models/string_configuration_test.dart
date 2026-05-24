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
}
