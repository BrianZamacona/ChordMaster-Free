/// Sealed failure hierarchy for ChordMaster Free.
///
/// All domain-level errors are represented as [Failure] subclasses rather
/// than raw exceptions, making error handling exhaustive and explicit.
sealed class Failure implements Exception {

  /// Creates a [Failure] with the given [message] and optional [stackTrace].
  const Failure({required this.message, this.stackTrace});
  /// Human-readable description of the failure.
  final String message;

  /// Optional Dart [StackTrace] captured at the failure site.
  final StackTrace? stackTrace;
}

/// Failure originating from the audio engine or audio session management.
final class AudioFailure extends Failure {
  /// Creates an [AudioFailure].
  const AudioFailure({required super.message, super.stackTrace});

  @override
  String toString() =>
      'AudioFailure: $message'
      '${stackTrace != null ? '\n$stackTrace' : ''}';
}

/// Failure caused by a denied or unavailable system permission.
final class PermissionFailure extends Failure {
  /// Creates a [PermissionFailure].
  const PermissionFailure({required super.message, super.stackTrace});

  @override
  String toString() =>
      'PermissionFailure: $message'
      '${stackTrace != null ? '\n$stackTrace' : ''}';
}

/// Failure arising from reading or writing persistent storage (Hive, prefs).
final class StorageFailure extends Failure {
  /// Creates a [StorageFailure].
  const StorageFailure({required super.message, super.stackTrace});

  @override
  String toString() =>
      'StorageFailure: $message'
      '${stackTrace != null ? '\n$stackTrace' : ''}';
}

/// Failure caused by invalid or unexpected data during JSON / Hive parsing.
final class ParseFailure extends Failure {
  /// Creates a [ParseFailure].
  const ParseFailure({required super.message, super.stackTrace});

  @override
  String toString() =>
      'ParseFailure: $message'
      '${stackTrace != null ? '\n$stackTrace' : ''}';
}
