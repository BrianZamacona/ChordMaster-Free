import 'package:chordmaster_free/features/scales/data/scale_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this._assets);

  final Map<String, String> _assets;

  @override
  Future<ByteData> load(String key) async {
    throw UnimplementedError('Binary asset loading not needed in this test');
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = _assets[key];
    if (value == null) {
      throw Exception('Missing asset: $key');
    }
    return value;
  }
}

void main() {
  group('ScaleRepository', () {
    test('loads and maps patterns from asset JSON list', () async {
      final bundle = _FakeAssetBundle({
        'assets/data/scale_patterns_coordinates.json':
            '[{"scale_name":"Major","root":"C","pattern_type":"CAGED","position_name":"Forma de A","starting_fret":2,"frets_span":4,"coordinates":[{"string":5,"fret":3,"interval":"1","note":"C","is_root":true,"finger":2}]}]'
      });

      final repository = ScaleRepository(bundle: bundle);
      final result = await repository.loadScalePatterns();

      expect(result, hasLength(1));
      expect(result.first.scaleName, 'Major');
      expect(result.first.coordinates.first.note, 'C');
    });

    test('supports root object with patterns key', () async {
      final bundle = _FakeAssetBundle({
        'assets/data/scale_patterns_coordinates.json':
            '{"patterns":[{"scale_name":"Major","root":"C","pattern_type":"CAGED","position_name":"Forma de A","starting_fret":2,"frets_span":4,"coordinates":[{"string":5,"fret":3,"interval":"1","note":"C","is_root":true,"finger":2}]}]}'
      });

      final repository = ScaleRepository(bundle: bundle);
      final result = await repository.loadScalePatterns();

      expect(result, hasLength(1));
      expect(result.first.positionName, 'Forma de A');
    });
  });
}
