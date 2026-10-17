import 'package:chordmaster_free/domain/voicing/voice_leading.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_decoding.dart';

void main() {
  final golden = loadGolden('voice_leading') as Map<String, dynamic>;

  test('costos de transición coinciden con el golden (200 casos)', () {
    final pairs = (golden['pairs'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(pairs, hasLength(200));
    for (var i = 0; i < pairs.length; i++) {
      final p = pairs[i];
      final cost = calculateVoiceLeadingCost(
        decodeVoiceLeadingVoicing(p['previous'] as Map<String, dynamic>),
        decodeVoiceLeadingVoicing(p['next'] as Map<String, dynamic>),
        decodeVoiceLeadingOptions(p['options'] as Map<String, dynamic>),
      );
      final expected = decodeCost(p['cost']);
      if (expected.isFinite) {
        expect(cost, closeTo(expected, 1e-9), reason: 'par $i');
      } else {
        expect(cost, double.infinity, reason: 'par $i');
      }
    }
  });

  test('caminos óptimos coinciden con el golden (40 casos)', () {
    final paths = (golden['paths'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(paths, hasLength(40));
    for (var i = 0; i < paths.length; i++) {
      final layers = [
        for (final layer in paths[i]['layers'] as List<dynamic>)
          [
            for (final v in layer as List<dynamic>)
              decodeVoiceLeadingVoicing(v as Map<String, dynamic>),
          ],
      ];
      final path = findOptimalProgressionPath(layers);
      final indices = [
        for (var l = 0; l < path.length; l++) layers[l].indexOf(path[l]),
      ];
      expect(
        indices,
        (paths[i]['expectedIndices'] as List<dynamic>).cast<int>(),
        reason: 'camino $i',
      );
    }
  });

  test('capas vacías o sin candidatos válidos devuelven camino vacío', () {
    const bad = VoiceLeadingVoicing(
      fretPositions: [null, null, null, null, null, null],
      anchorFret: 0,
      individualCost: double.infinity,
    );
    expect(findOptimalProgressionPath<VoiceLeadingVoicing>([]), isEmpty);
    expect(
      findOptimalProgressionPath<VoiceLeadingVoicing>([
        [bad],
        [bad],
      ]),
      isEmpty,
    );
  });
}
