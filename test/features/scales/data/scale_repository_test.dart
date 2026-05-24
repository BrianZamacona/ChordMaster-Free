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
    late ScaleRepository repository;

    setUp(() {
      final bundle = _FakeAssetBundle({
        'assets/data/scales.json':
            '[{"name":"Major","root":"C","type":"major","intervals":[0,2,4,5,7,9,11]}]'
      });
      repository = ScaleRepository(bundle: bundle);
    });

    test('loadPatterns generates requested system patterns', () async {
      final result = await repository.loadPatterns(
        scaleName: 'major',
        root: 'C',
        system: 'CAGED',
      );

      expect(result, isNotEmpty);
      expect(result.first.patternType, 'CAGED');
      expect(result.first.coordinates, isNotEmpty);
    });

    test('loadAllSystems returns generated map for known scale', () async {
      final result = await repository.loadAllSystems(
        scaleName: 'major',
        root: 'C',
      );

      expect(result, isNotEmpty);
      expect(result['CAGED'], isNotEmpty);
      expect(result['Berklee'], isNotEmpty);
    });

    test('loadPositional returns a positional pattern', () async {
      final pattern = await repository.loadPositional(
        scaleName: 'major',
        root: 'C',
        startFret: 3,
      );

      expect(pattern, isNotNull);
      expect(pattern!.patternType, 'Posicional');
      expect(pattern.startingFret, 3);
    });
  });
}
