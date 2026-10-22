import 'dart:io';

import 'package:chordmaster_free/data/repository/chord_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sirve chords.json desde el disco y cuenta cuántas veces se lee.
class _CountingBundle extends CachingAssetBundle {
  int loads = 0;

  @override
  Future<ByteData> load(String key) async {
    loads++;
    final bytes = File(key).readAsBytesSync();
    return ByteData.sublistView(bytes);
  }
}

void main() {
  test('lee chords.json una sola vez para las dos vistas', () async {
    final bundle = _CountingBundle();
    final repo = ChordRepository(bundle: bundle);

    final (chords, fingerings, again) =
        await (repo.chords(), repo.fingerings(), repo.chords()).wait;

    expect(bundle.loads, 1);
    expect(chords, hasLength(288));
    expect(identical(chords, again), isTrue);
    expect([for (final f in fingerings) f.name],
        [for (final c in chords) c.name]);
  });
}
