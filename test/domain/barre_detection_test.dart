import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/voicing/barre_detection.dart';
import 'package:chordmaster_free/domain/voicing/ergonomics.dart';
import 'package:chordmaster_free/domain/voicing/voicing_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

Barre? _detect(List<int> jsonFrets, List<int> jsonFingers) => detectBarre(
  VoicingAdapter.fromChordJson(jsonFrets),
  VoicingAdapter.fingersFromChordJson(jsonFingers),
);

void main() {
  final chords =
      (jsonDecode(File('assets/data/chords.json').readAsStringSync())
              as List<dynamic>)
          .cast<Map<String, dynamic>>();

  Map<String, dynamic> chord(String name) =>
      chords.firstWhere((c) => c['name'] == name);

  Map<String, dynamic> caged(String name, String title) =>
      (chord(name)['cagedPositions'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((p) => p['title'] == title);

  test('C abierto: sin cejilla', () {
    final c = chord('C Major');
    expect(c['fretPositions'], [-1, 3, 2, 0, 1, 0]);
    expect(
      _detect(
        (c['fretPositions'] as List<dynamic>).cast<int>(),
        (c['fingerPositions'] as List<dynamic>).cast<int>(),
      ),
      isNull,
    );
  });

  test('F mayor en 1ª posición: cejilla de 6 cuerdas en el traste 1', () {
    final f = chord('F Major');
    expect(f['fretPositions'], [1, 3, 3, 2, 1, 1]);
    final barre = _detect(
      (f['fretPositions'] as List<dynamic>).cast<int>(),
      (f['fingerPositions'] as List<dynamic>).cast<int>(),
    )!;
    expect(barre.fret, 1);
    expect(barreWidth(barre), 6);
    expect(barre.fromString, 5);
    expect(barre.endString, 0);
    expect(barreKind(barre), BarreKind.grande);
  });

  test('C Major forma A: gana el dedo 1 (traste 3, ancho 5) sobre el dedo 3', () {
    final a = caged('C Major', 'A Form');
    expect(a['fretPositions'], [-1, 3, 5, 5, 5, 3]);
    expect(a['fingerPositions'], [0, 1, 3, 3, 3, 1]);
    final barre = _detect(
      (a['fretPositions'] as List<dynamic>).cast<int>(),
      (a['fingerPositions'] as List<dynamic>).cast<int>(),
    )!;
    expect(barre.fret, 3);
    expect(barreWidth(barre), 5);
  });

  test('empate de ancho: gana el traste menor', () {
    // Dedo 1 en traste 2 (cuerdas 0-1) y dedo 2 en traste 4 (cuerdas 3-4).
    final barre = detectBarre([2, 2, null, 4, 4, null], [1, 1, 0, 2, 2, 0])!;
    expect(barre.fret, 2);
  });

  test('invariante en todo chords.json y conteo de cejillas', () {
    var total = 0;
    var mini = 0;
    var grande = 0;
    final impossible = <String>[];

    for (final c in chords) {
      final items = <Map<String, dynamic>>[
        c,
        for (final f in const [
          'cagedPositions',
          'voicings',
          'triadInversions',
          'advancedInversions',
        ])
          ...(c[f] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>(),
      ];
      for (final item in items) {
        total++;
        final frets = VoicingAdapter.fromChordJson(
          (item['fretPositions'] as List<dynamic>).cast<int>(),
        );
        final barre = detectBarre(
          frets,
          VoicingAdapter.fingersFromChordJson(
            (item['fingerPositions'] as List<dynamic>).cast<int>(),
          ),
        );
        if (barre == null) continue;
        if (barreKind(barre) == BarreKind.grande) {
          grande++;
        } else {
          mini++;
        }
        for (var s = barre.endString; s <= barre.fromString; s++) {
          final fret = frets[s];
          if (fret == null || fret < barre.fret) {
            impossible.add('${c['name']} ${item['fretPositions']}');
            break;
          }
        }
      }
    }

    // ignore: avoid_print
    print(
      'voicings: $total, con cejilla: ${mini + grande} '
      '(mini $mini, grande $grande), imposibles: ${impossible.length}',
    );
    expect(total, 1092);
    expect(mini, 358);
    expect(grande, 241);
    // Deuda de datos en chords.json (dedos repetidos con cuerdas muteadas, al aire
    // o más bajas entre medias); el conteo exacto evita que crezca en silencio.
    expect(impossible, hasLength(_knownImpossibleBarres), reason: '$impossible');
  });
}

const _knownImpossibleBarres = 27;
