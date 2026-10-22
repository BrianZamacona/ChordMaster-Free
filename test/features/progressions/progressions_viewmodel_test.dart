import 'dart:async';

import 'package:chordmaster_free/features/progressions/progressions_viewmodel.dart';
import 'package:chordmaster_free/services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Storage en memoria; `gate` retrasa las lecturas para simular Hive lento.
class _MemoryStorage implements StorageService {
  _MemoryStorage([Map<String, dynamic>? initial]) : data = {...?initial};

  final Map<String, dynamic> data;
  Completer<void>? gate;

  @override
  Future<void> openBoxes() async {}

  @override
  Future<void> save(String box, String key, dynamic value) async =>
      data[key] = value;

  @override
  Future<T?> get<T>(String box, String key) async {
    await gate?.future;
    final value = data[key];
    return value is T ? value : null;
  }


  @override
  Future<void> delete(String box, String key) async => data.remove(key);

  @override
  Future<void> clear(String box) async => data.clear();
}

ProviderContainer _container(_MemoryStorage storage) {
  final container = ProviderContainer(
    overrides: [storageServiceProvider.overrideWithValue(storage)],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('Mi progresión: grados válidos, máximo 8, se guarda y se recupera', () async {
    final storage = _MemoryStorage();
    final container = _container(storage);
    final vm = container.read(progressionsViewModelProvider.notifier);
    await vm.loaded;

    vm
      ..addCustomDegree('I')
      ..addCustomDegree('X')
      ..addCustomDegree('vi');
    var s = container.read(progressionsViewModelProvider);
    expect(s.isCustom, isTrue);
    expect(s.custom, ['I', 'vi']);
    expect(s.progression.degrees.map((d) => d.type), ['major', 'minor']);

    for (var i = 0; i < 10; i++) {
      vm.addCustomDegree('IV');
    }
    expect(container.read(progressionsViewModelProvider).custom, hasLength(8));
    vm.removeCustomDegree(0);
    await _settle();
    expect(storage.data['progressions_custom'], hasLength(7));

    final again = _container(storage);
    final vm2 = again.read(progressionsViewModelProvider.notifier);
    await vm2.loaded;
    s = again.read(progressionsViewModelProvider);
    expect(s.custom.first, 'vi');
    expect(s.isCustom, isFalse); // abre en la progresión común por defecto
  });

  test('cuenta una vez por progresión distinta (id + tónica)', () async {
    final storage = _MemoryStorage();
    final container = _container(storage);
    final vm = container.read(progressionsViewModelProvider.notifier);
    await vm.loaded;

    vm
      ..setProgression('v1-1')
      ..setProgression('v1-1')
      ..setProgression('v1-2')
      ..setProgression('v1-1');
    await _settle();
    expect(container.read(progressionsViewModelProvider).progressionsGenerated, 2);

    vm
      ..setTonic(7)
      ..setTonic(7);
    await _settle();
    expect(container.read(progressionsViewModelProvider).progressionsGenerated, 3);
    expect(storage.data['progressions_generated'], 3);
    expect(
      (storage.data['progressions_seen'] as List).toSet(),
      {'v1-1@0', 'v1-2@0', 'v1-1@7'},
    );
  });

  test('lo ya visto persiste: no recuenta en una nueva sesión', () async {
    final storage = _MemoryStorage({
      'progressions_generated': 4,
      'progressions_seen': ['v1-1@0'],
    });
    final container = _container(storage);
    final vm = container.read(progressionsViewModelProvider.notifier);
    await vm.loaded;
    expect(container.read(progressionsViewModelProvider).progressionsGenerated, 4);

    vm.setProgression('v1-1');
    await _settle();
    expect(container.read(progressionsViewModelProvider).progressionsGenerated, 4);
  });

  test('un cambio antes de terminar la carga no se pierde ni pisa lo guardado', () async {
    final storage = _MemoryStorage({'progressions_generated': 3})
      ..gate = Completer<void>();
    final container = _container(storage);
    final vm = container.read(progressionsViewModelProvider.notifier)
      ..setProgression('v1-1');
    await _settle();
    // Aún cargando: no se escribió nada desde 0.
    expect(storage.data['progressions_generated'], 3);

    storage.gate!.complete();
    await vm.loaded;
    await _settle();
    expect(container.read(progressionsViewModelProvider).progressionsGenerated, 4);
    expect(storage.data['progressions_generated'], 4);
  });
}
