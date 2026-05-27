import 'package:chordmaster_free/data/repository/scale_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this._assets);

  final Map<String, String> _assets;

  @override
  Future<ByteData> load(String key) async => throw UnimplementedError();

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = _assets[key];
    if (value == null) throw Exception('Missing asset: $key');
    return value;
  }
}

void main() {
  test('getVisiblePatterns returns resolved pattern in viewport', () async {
    final json = '''
{
  "scales": [
    {
      "id": "major",
      "name": "Major",
      "category": "Diatónica",
      "intervals": [0,2,4,5,7,9,11],
      "systems": [{"id":"caged","name":"CAGED"}],
      "positions": [
        {
          "id":"p1",
          "name":"Patrón 1",
          "system_id":"caged",
          "starting_fret":0,
          "fret_span":4,
          "coordinates":[{"string":1,"fret_offset":0,"is_root":true,"interval":"1"}]
        }
      ]
    }
  ],
  "modes": []
}
''';

    final repository = ScaleRepository(
      bundle: _FakeAssetBundle({'assets/data/scales_master.json': json}),
    );

    final patterns = await repository.getVisiblePatterns(
      scaleId: 'major',
      rootSemitone: 0,
      startFret: 0,
      endFret: 12,
      stringCount: 6,
    );

    expect(patterns, hasLength(1));
    expect(patterns.first.coordinates.first.fret, 0);
  });
}
