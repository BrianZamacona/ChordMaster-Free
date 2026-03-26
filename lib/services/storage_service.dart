import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/errors/failures.dart';

/// Riverpod provider that exposes the [StorageService] singleton.
final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());

/// Singleton service for all persistent key-value storage in ChordMaster Free.
///
/// Uses [Hive] as the underlying storage engine.  Each logical domain (user
/// progress, community posts, achievements, settings) has its own named box
/// so data stays organised and boxes can be cleared independently.
///
/// All methods throw a [StorageFailure] on error so callers can handle
/// storage problems uniformly via the sealed [Failure] hierarchy.
///
/// ### Initialisation
/// Call [openBoxes] once during app start-up (before using any other method):
/// +
/// ```dart
/// await StorageService().openBoxes();
/// ```
class StorageService {
  /// Box name for user learning progress data.
  static const String userProgressBox = 'userProgress';

  /// Box name for community post data.
  static const String communityPostsBox = 'communityPosts';

  /// Box name for unlocked achievement IDs.
  static const String achievementsBox = 'achievements';

  /// Box name for application settings.
  static const String settingsBox = 'settings';

  static const String _encKeyName = 'cmf_hive_encryption_key_v1';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // ── Box Lifecycle ─────────────────────────────────────────────────────────

  ///Opens all four Hive boxes.
  ///
  /// Safe to call multiple times; Hive silently returns already-open boxes.
  /// Throws [StorageFailure] if any box fails to open.
  Future<void> openBoxes() async {
    try {
      final enc = await _loadEncryptionContext();

      await _openBoxSecure(userProgressBox, enc);
      await _openBoxSecure(communityPostsBox, enc);
      await _openBoxSecure(achievementsBox, enc);
      await _openBoxSecure(settingsBox, enc);
    } catch (e, st) {
      throw StorageFailure(
        message: 'Failed to open Hive boxes: $e',
        stackTrace: st,
      );
    }
  }

  // ── CRUD Operations ───────────────────────────────────────────────────────

  /// Saves [value] under [key] in the named [box].
  ///
  /// Creates or overwrites the entry.  Throws [StorageFailure] on error.
  Future<void> save(String box, String key, dynamic value) async {
    try {
      final b = _box(box);
      await b.put(key, value);
    } catch (e, st) {
      throw StorageFailure(
        message: 'Failed to save key "$key" in box "$box": $e',
        stackTrace: st,
      );
    }
  }

  /// Retrieves the value stored under [key] in the named [box], cast to [T].
  ///
  /// Returns `null` when the key does not exist or the stored value is not
  /// assignable to [T].  Throws [StorageFailure] on unexpected errors.
  Future<T?> get<T>(String box, String key) async {
    try {
      final b = _box(box);
      final value = b.get(key);
      if (value is T) return value;
      return null;
    } catch (e, st) {
      throw StorageFailure(
        message: 'Failed to get key "$key" from box "$box": $e',
        stackTrace: st,
      );
    }
  }

  /// Returns all values stored in the named [box] as an untyped list.
  ///
  /// Returns an empty list when the box is empty.  Throws [StorageFailure]
  /// on error.
  Future<List<dynamic>> getAll(String box) async {
    try {
      final b = _box(box);
      return b.values.toList();
    } catch (e, st) {
      throw StorageFailure(
        message: 'Failed to get all values from box "$box": $e',
        stackTrace: st,
      );
    }
  }

  /// Deletes the entry identified by [key] from the named [box].
  ///
  /// Silently succeeds if the key does not exist.  Throws [StorageFailure]
  /// on error.
  Future<void> delete(String box, String key) async {
    try {
      final b = _box(box);
      await b.delete(key);
    } catch (e, st) {
      throw StorageFailure(
        message: 'Failed to delete key "$key" from box "$box": $e',
        stackTrace: st,
      );
    }
  }

  /// Removes all entries from the named [box].
  ///
  /// Throws [StorageFailure] on error.
  Future<void> clear(String box) async {
    try {
      final b = _box(box);
      await b.clear();
    } catch (e, st) {
      throw StorageFailure(
        message: 'Failed to clear box "$box": $e',
        stackTrace: st,
      );
    }
  }

  // ── Internal Helpers ──────────────────────────────────────────────────────

  /// Returns the open [Box] with the given [name].
  ///
  /// Throws [StorageFailure] when the box has not been opened yet.
  Box<dynamic> _box(String name) {
    if (!Hive.isBoxOpen(name)) {
      throw StorageFailure(
        message: 'Box "$name" is not open. Call openBoxes() first.',
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
    await _secureStorage.write(key: _encKeyName, value: base64Encode(key));
    return _EncryptionContext(
      cipher: HiveAesCipher(key),
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
