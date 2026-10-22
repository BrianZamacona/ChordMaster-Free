import 'dart:async';

import 'package:chordmaster_free/services/key_value_store.dart';

/// [KeyValueStore] en memoria para tests, separado por caja como Hive.
///
/// [progress] es la caja de progreso (la que más se revisa); [gate] retrasa
/// las lecturas para simular un disco lento.
class InMemoryStore implements KeyValueStore {
  InMemoryStore({Map<String, Object?>? progress, Map<String, Object?>? settings})
      : _boxes = {
          StorageBoxes.userProgress: {...?progress},
          StorageBoxes.settings: {...?settings},
        };

  final Map<String, Map<String, Object?>> _boxes;
  Completer<void>? gate;

  Map<String, Object?> box(String name) => _boxes.putIfAbsent(name, () => {});
  Map<String, Object?> get progress => box(StorageBoxes.userProgress);
  Map<String, Object?> get settings => box(StorageBoxes.settings);
  Map<String, Object?> get achievements => box(StorageBoxes.achievements);

  @override
  Future<void> save(String box, String key, Object? value) async =>
      this.box(box)[key] = value;

  @override
  Future<T?> get<T>(String box, String key) async {
    await gate?.future;
    final value = this.box(box)[key];
    return value is T ? value : null;
  }

  @override
  Future<void> delete(String box, String key) async => this.box(box).remove(key);

  @override
  Future<void> clear(String box) async => this.box(box).clear();
}
