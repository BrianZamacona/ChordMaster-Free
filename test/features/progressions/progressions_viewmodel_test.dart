import 'dart:async';

import 'package:chordmaster_free/features/progressions/progressions_viewmodel.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/in_memory_store.dart';

ProviderContainer _container(InMemoryStore storage) {
  final container = ProviderContainer(
    overrides: [keyValueStoreProvider.overrideWithValue(storage)],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('Mi progresión: grados válidos, máximo 8, se guarda y se recupera', () async {
    final storage = InMemoryStore();
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
    expect(storage.progress['progressions_custom'], hasLength(7));

    final again = _container(storage);
    final vm2 = again.read(progressionsViewModelProvider.notifier);
    await vm2.loaded;
    s = again.read(progressionsViewModelProvider);
    expect(s.custom.first, 'vi');
    expect(s.isCustom, isFalse); // abre en la progresión común por defecto
  });

  test('cuenta una vez por progresión distinta (id + tónica)', () async {
    final storage = InMemoryStore();
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
    expect(storage.progress['progressions_generated'], 3);
    expect(
      (storage.progress['progressions_seen'] as List).toSet(),
      {'v1-1@0', 'v1-2@0', 'v1-1@7'},
    );
  });

  test('lo ya visto persiste: no recuenta en una nueva sesión', () async {
    final storage = InMemoryStore(progress: {
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
    final storage = InMemoryStore(progress: {'progressions_generated': 3})
      ..gate = Completer<void>();
    final container = _container(storage);
    final vm = container.read(progressionsViewModelProvider.notifier)
      ..setProgression('v1-1');
    await _settle();
    // Aún cargando: no se escribió nada desde 0.
    expect(storage.progress['progressions_generated'], 3);

    storage.gate!.complete();
    await vm.loaded;
    await _settle();
    expect(container.read(progressionsViewModelProvider).progressionsGenerated, 4);
    expect(storage.progress['progressions_generated'], 4);
  });
}
