import 'dart:async';

import 'package:chordmaster_free/domain/progressions/song.dart';
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
    expect((storage.progress['progressions_song'] as Map)['sections'], [hasLength(7)]);

    final again = _container(storage);
    final vm2 = again.read(progressionsViewModelProvider.notifier);
    await vm2.loaded;
    s = again.read(progressionsViewModelProvider);
    expect(s.custom.first, 'vi');
    expect(s.isCustom, isFalse); // abre en la progresión común por defecto
  });

  test('Mi progresión: 7ª, escala de base y grados de otra escala se guardan', () async {
    final storage = InMemoryStore();
    final container = _container(storage);
    final vm = container.read(progressionsViewModelProvider.notifier);
    await vm.loaded;

    vm
      ..setCustomMode(5)
      ..setCustomMode(9)
      ..setCustomSevenths(sevenths: true)
      ..addCustomDegree('i7')
      ..addCustomDegree('♭VIImaj7')
      ..addCustomDegree('Iø7');
    var s = container.read(progressionsViewModelProvider);
    expect(s.customMode, 5);
    expect(s.custom, ['i7', '♭VIImaj7']);
    expect([for (final d in s.progression.degrees) (d.semitones, d.type)], [(0, 'minor7'), (10, 'major7')]);
    await _settle();

    final again = _container(storage);
    final vm2 = again.read(progressionsViewModelProvider.notifier);
    await vm2.loaded;
    s = again.read(progressionsViewModelProvider);
    expect(s.customMode, 5);
    expect(s.customSevenths, isTrue);
    expect(s.custom, ['i7', '♭VIImaj7']);
  });

  test('Mi progresión: cada acorde con su duración, guardada', () async {
    final storage = InMemoryStore();
    final container = _container(storage);
    final vm = container.read(progressionsViewModelProvider.notifier);
    await vm.loaded;

    vm
      ..addCustomDegree('I')
      ..addCustomDegree('IV')
      ..addCustomDegree('V')
      ..setCustomBeats(1, 2)
      ..setCustomBeats(2, 3)
      ..setCustomBeats(9, 2);
    var s = container.read(progressionsViewModelProvider);
    expect(s.customBeats, [4, 2, 4]);
    expect(s.progression.beats, [4, 2, 4]);
    vm.removeCustomDegree(0);
    s = container.read(progressionsViewModelProvider);
    expect(s.custom, ['IV', 'V']);
    expect(s.customBeats, [2, 4]);
    await _settle();
    expect(storage.progress['progressions_song'], {
      'sections': [
        ['IV@2', 'V'],
      ],
      'order': [0],
    });

    final again = _container(storage);
    final vm2 = again.read(progressionsViewModelProvider.notifier);
    await vm2.loaded;
    s = again.read(progressionsViewModelProvider);
    expect(s.custom, ['IV', 'V']);
    expect(s.customBeats, [2, 4]);

    // Todos de un compás: la progresión suena como las de siempre.
    vm2.setCustomBeats(0, 4);
    expect(again.read(progressionsViewModelProvider).progression.beats, isNull);
  });

  test('Mi progresión: duplicar, copiar y pegar, sin pasar de 8', () async {
    final container = _container(InMemoryStore());
    final vm = container.read(progressionsViewModelProvider.notifier);
    await vm.loaded;
    ProgressionsState s() => container.read(progressionsViewModelProvider);

    vm
      ..addCustomDegree('I')
      ..addCustomDegree('V')
      ..setCustomBeats(1, 2)
      ..duplicateCustom(1);
    expect(s().custom, ['I', 'V', 'V']);
    expect(s().customBeats, [4, 2, 2]);
    vm.pasteCustom();
    expect(s().custom, hasLength(3)); // nada copiado todavía
    vm
      ..copyCustom(1)
      ..pasteCustom(after: 0);
    expect(s().custom, ['I', 'V', 'V', 'V']);
    expect(s().customBeats, [4, 2, 2, 2]);
    vm.copyCustom(0);
    for (var i = 0; i < 10; i++) {
      vm.pasteCustom();
    }
    expect(s().custom, hasLength(8));
    expect(s().custom.last, 'I');
    vm.duplicateCustom(0);
    expect(s().custom, hasLength(8));
  });

  test('Mis progresiones: guardar, abrir con su escala y duración, y borrar', () async {
    final storage = InMemoryStore();
    final container = _container(storage);
    final vm = container.read(progressionsViewModelProvider.notifier);
    await vm.loaded;

    expect(vm.saveCustomAs('Vacía'), isFalse);
    vm
      ..setCustomMode(5)
      ..addCustomDegree('i')
      ..addCustomDegree('♭VII')
      ..setCustomBeats(1, 2);
    expect(vm.saveCustomAs('  '), isFalse);
    expect(vm.saveCustomAs('Andaluza'), isTrue);
    vm
      ..clearCustom()
      ..setCustomMode(0)
      ..addCustomDegree('I');
    expect(vm.saveCustomAs('Sola'), isTrue);
    await _settle();

    final again = _container(storage);
    final vm2 = again.read(progressionsViewModelProvider.notifier);
    await vm2.loaded;
    var s = again.read(progressionsViewModelProvider);
    expect([for (final p in s.saved) p.name], ['Sola', 'Andaluza']);
    vm2.openSaved(1);
    s = again.read(progressionsViewModelProvider);
    expect((s.isCustom, s.customMode), (true, 5));
    expect(s.custom, ['i', '♭VII']);
    expect(s.customBeats, [4, 2]);
    vm2.deleteSaved(0);
    await _settle();
    expect(storage.progress['progressions_saved'], [
      {
        'name': 'Andaluza',
        'mode': 5,
        'sections': [
          ['i', '♭VII@2'],
        ],
        'order': [0],
      },
    ]);
  });

  test('lo de antes (una sola sección en progressions_custom) se abre como la sección A', () async {
    final storage = InMemoryStore(progress: {
      'progressions_custom': ['ii7', 'V7@2', 'Imaj7'],
    });
    final container = _container(storage);
    final vm = container.read(progressionsViewModelProvider.notifier);
    await vm.loaded;
    final s = container.read(progressionsViewModelProvider);
    expect(s.custom, ['ii7', 'V7', 'Imaj7']);
    expect(s.customBeats, [4, 2, 4]);
    expect(s.order, [0]);
    expect(s.hasSong, isFalse);
  });

  test('Mi progresión con secciones: editar, ordenar, quitar y guardar la canción', () async {
    final storage = InMemoryStore();
    final container = _container(storage);
    final vm = container.read(progressionsViewModelProvider.notifier);
    await vm.loaded;
    ProgressionsState s() => container.read(progressionsViewModelProvider);

    vm
      ..addCustomDegree('I')
      ..addCustomDegree('V')
      ..addSection();
    expect(s().section, 1);
    expect(s().order, [0, 1]);
    expect(s().custom, isEmpty);
    expect(s().hasSong, isTrue);
    vm
      ..addCustomDegree('IV')
      ..addPart(0)
      ..addPart(9);
    expect(s().order, [0, 1, 0]);
    // La sección que se edita es la que dibujan los diagramas.
    expect(s().progression.degrees.map((d) => d.numeral), ['IV']);
    vm.selectSection(0);
    expect(s().progression.degrees.map((d) => d.numeral), ['I', 'V']);

    for (var i = 0; i < 10; i++) {
      vm.addSection();
    }
    expect(s().sections, hasLength(songMaxSections));
    for (var i = 0; i < 10; i++) {
      vm.addPart(0);
    }
    expect(s().order, hasLength(songMaxParts));
    vm.removePart(0);
    expect(s().order, hasLength(songMaxParts - 1));

    // Quitar la B: sus partes se van y la C y la D pasan a ser B y C.
    vm.removeSection(1);
    expect(s().sections, hasLength(songMaxSections - 1));
    expect(s().order.contains(3), isFalse);

    // Se guarda sin las secciones vacías.
    expect(vm.saveCustomAs('Canción'), isTrue);
    final saved = s().saved.single;
    expect(saved.sections, [
      [(numeral: 'I', beats: 4), (numeral: 'V', beats: 4)],
    ]);
    expect(saved.order.toSet(), {0});
    await _settle();

    // Y se vuelve a abrir igual al volver a la app.
    final again = _container(storage);
    final vm2 = again.read(progressionsViewModelProvider.notifier);
    await vm2.loaded;
    expect(again.read(progressionsViewModelProvider).sections, s().sections);
    expect(again.read(progressionsViewModelProvider).order, s().order);
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
