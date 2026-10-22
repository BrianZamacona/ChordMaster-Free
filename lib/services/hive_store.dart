import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/errors/failures.dart';
import 'key_value_store.dart';

/// Adaptador de [KeyValueStore] sobre Hive, cifrado con AES; la llave vive en
/// el almacén seguro del sistema (en web no hay cifrado).
///
/// Llamar a [open] una vez al arrancar, antes de cualquier otro método.
/// Todos los métodos lanzan [StorageFailure] si algo falla.
class HiveStore implements KeyValueStore {
  static const String _encKeyName = 'cmf_hive_encryption_key_v1';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // ── Box Lifecycle ─────────────────────────────────────────────────────────

  /// Abre todas las [StorageBoxes]. Se puede llamar más de una vez.
  Future<void> open() async {
    try {
      final enc = await _loadEncryptionContext();
      for (final box in StorageBoxes.all) {
        await _openBoxSecure(box, enc);
      }
    } catch (e, st) {
      throw StorageFailure(
        message: 'Failed to open Hive boxes: $e',
        stackTrace: st,
      );
    }
  }

  // ── CRUD Operations ───────────────────────────────────────────────────────

  @override
  Future<void> save(String box, String key, Object? value) =>
      _guard('save "$key" in "$box"', () => _box(box).put(key, value));

  @override
  Future<T?> get<T>(String box, String key) =>
      _guard('get "$key" from "$box"', () async {
        final value = _box(box).get(key);
        return value is T ? value : null;
      });

  @override
  Future<void> delete(String box, String key) =>
      _guard('delete "$key" from "$box"', () => _box(box).delete(key));

  @override
  Future<void> clear(String box) =>
      _guard('clear "$box"', () => _box(box).clear());

  // ── Internal Helpers ──────────────────────────────────────────────────────

  /// Ejecuta [op] y envuelve cualquier error en un [StorageFailure].
  Future<T> _guard<T>(String action, Future<T> Function() op) async {
    try {
      return await op();
    } on StorageFailure {
      rethrow;
    } catch (e, st) {
      throw StorageFailure(message: 'Failed to $action: $e', stackTrace: st);
    }
  }

  /// Returns the open [Box] with the given [name].
  ///
  /// Throws [StorageFailure] when the box has not been opened yet.
  Box<dynamic> _box(String name) {
    if (!Hive.isBoxOpen(name)) {
      throw StorageFailure(
        message: 'Box "$name" is not open. Call open() first.',
      );
    }
    return Hive.box<dynamic>(name);
  }

  Future<_EncryptionContext> _loadEncryptionContext() async {
    if (kIsWeb) {
      // Web does not support flutter_secure_storage; fall back to default Hive.
      return const _EncryptionContext(cipher: null, keyWasCreated: false);
    }

    final existing = await _secureStorage.read(key: _encKeyName);
    if (existing != null && existing.isNotEmpty) {
      final bytes = base64Decode(existing);
      if (bytes.length != 32) {
        throw const StorageFailure(
          message: 'Stored Hive encryption key has invalid length.',
        );
      }
      return _EncryptionContext(
        cipher: HiveAesCipher(bytes),
        keyWasCreated: false,
      );
    }

    final key = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    // Build the cipher immediately so `key` does not need to outlive this
    // scope; the raw bytes are no longer reachable once the cipher is created.
    final cipher = HiveAesCipher(key);
    await _secureStorage.write(key: _encKeyName, value: base64Encode(key));
    return _EncryptionContext(
      cipher: cipher,
      keyWasCreated: true,
    );
  }

  Future<void> _openBoxSecure(String name, _EncryptionContext enc) async {
    // Web keeps default (unencrypted) boxes because secure storage and
    // consistent key management are not available across browsers.
    if (enc.cipher == null) {
      await Hive.openBox<dynamic>(name);
      return;
    }

    try {
      await Hive.openBox<dynamic>(name, encryptionCipher: enc.cipher);
      return;
    } catch (_) {
      // If the key already existed, this indicates corruption/wrong key and
      // should not auto-migrate to avoid data loss.
      if (!enc.keyWasCreated) {
        rethrow;
      }
    }

    // One-time migration path: existing plaintext box -> encrypted box.
    if (!await Hive.boxExists(name)) {
      await Hive.openBox<dynamic>(name, encryptionCipher: enc.cipher);
      return;
    }

    final legacy = await Hive.openBox<dynamic>(name);
    final entries = Map<dynamic, dynamic>.from(legacy.toMap());
    await legacy.close();
    await Hive.deleteBoxFromDisk(name);

    final encrypted = await Hive.openBox<dynamic>(
      name,
      encryptionCipher: enc.cipher,
    );
    if (entries.isNotEmpty) {
      await encrypted.putAll(entries);
    }
  }
}

class _EncryptionContext {
  const _EncryptionContext({required this.cipher, required this.keyWasCreated});

  final HiveCipher? cipher;
  final bool keyWasCreated;
}
