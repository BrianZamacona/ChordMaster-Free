import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // ── Box Lifecycle ─────────────────────────────────────────────────────────

  /// Opens all four Hive boxes.
  ///
  /// Safe to call multiple times; Hive silently returns already-open boxes.
  /// Throws [StorageFailure] if any box fails to open.
  Future<void> openBoxes() async {
    try {
      await Future.wait([
        Hive.openBox<dynamic>(userProgressBox),
        Hive.openBox<dynamic>(communityPostsBox),
        Hive.openBox<dynamic>(achievementsBox),
        Hive.openBox<dynamic>(settingsBox),
      ]);
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
}
