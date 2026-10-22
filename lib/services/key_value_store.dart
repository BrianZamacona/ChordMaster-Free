import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cajas de datos de la app; cada una se abre y se borra por separado.
abstract final class StorageBoxes {
  /// Progreso: rachas, récords, vistos, la progresión guardada.
  static const userProgress = 'userProgress';

  /// Logros desbloqueados (clave = id, valor = fecha ISO-8601).
  static const achievements = 'achievements';

  /// Ajustes: idioma, tema, avisos de pausa.
  static const settings = 'settings';

  static const all = [userProgress, achievements, settings];
}

/// Puerto de persistencia clave-valor por cajas.
///
/// La app depende solo de esta interfaz: `HiveStore` es el adaptador real
/// (cifrado) y los tests usan uno en memoria. Los errores de E/S llegan como
/// `StorageFailure`.
abstract interface class KeyValueStore {
  /// Guarda [value] en [key] (crea o reemplaza).
  Future<void> save(String box, String key, Object? value);

  /// Valor de [key], o `null` si no existe o no es un [T].
  Future<T?> get<T>(String box, String key);

  /// Borra [key]; no falla si no existe.
  Future<void> delete(String box, String key);

  /// Vacía la caja [box].
  Future<void> clear(String box);
}

/// El almacén de la app. `main` lo sustituye por el `HiveStore` ya abierto;
/// los tests, por uno en memoria.
final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => throw UnimplementedError(
    'keyValueStoreProvider se inyecta en main() (o en el test)',
  ),
);
