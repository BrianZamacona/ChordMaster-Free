import 'package:flutter/foundation.dart';

/// Centralised logging utility for ChordMaster Free.
///
/// In debug builds, messages are forwarded to [debugPrint].
/// In release builds, the logger is silent — no stack traces or internal data
/// are exposed (OWASP A09 — Logging / Monitoring).
///
/// ### Usage
/// ```dart
/// AppLogger.error('StorageService', 'Failed to open box', error, stackTrace);
/// AppLogger.info('AchievementService', 'Unlocked first_chord');
/// ```
class AppLogger {
  AppLogger._();

  /// Logs a debug-level message (debug builds only).
  static void debug(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  /// Logs an informational message (debug builds only).
  static void info(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[INFO][$tag] $message');
    }
  }

  /// Logs an error with optional [error] and [stackTrace] (debug builds only).
  ///
  /// In release builds this is a no-op, preventing internal stack traces from
  /// being exposed via system logs.
  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR][$tag] $message${error != null ? ': $error' : ''}');
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }
  }
}
