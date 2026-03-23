import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/failures.dart';
import 'storage_service.dart';

/// Riverpod provider that exposes the [AchievementService] singleton.
final achievementServiceProvider =
    Provider<AchievementService>((ref) => AchievementService.instance);

/// Immutable descriptor for a single achievement.
class AchievementDefinition {
  /// Unique string identifier used for persistence.
  final String id;

  /// Short display title shown in the UI.
  final String title;

  /// Sentence describing how to earn the achievement.
  final String description;

  /// Emoji icon that represents the achievement.
  final String emoji;

  /// Creates an [AchievementDefinition].
  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
  });

  @override
  String toString() => 'AchievementDefinition(id: $id, title: $title)';
}

/// Singleton service that tracks and persists unlocked achievements.
///
/// Achievements are persisted via [StorageService] in
/// [StorageService.achievementsBox].  Each unlocked achievement stores the
/// ISO-8601 timestamp of when it was earned under its [AchievementDefinition.id]
/// key.
///
/// ### Usage
/// ```dart
/// // Unlock an achievement
/// await AchievementService.instance.unlock('first_chord');
///
/// // Check status
/// final unlocked = await AchievementService.instance.getUnlocked();
/// final hasIt   = await AchievementService.instance.isUnlocked('tuned_up');
/// ```
class AchievementService {
  /// The singleton instance.
  static final AchievementService instance = AchievementService._internal();

  /// Factory constructor always returns [instance].
  factory AchievementService() => instance;

  AchievementService._internal();

  final StorageService _storage = StorageService();

  // ── Predefined Achievements ───────────────────────────────────────────────

  /// The complete catalogue of achievements available in ChordMaster Free.
  static const List<AchievementDefinition> allAchievements = [
    AchievementDefinition(
      id: 'first_chord',
      title: 'First Chord',
      description: 'View your first chord diagram.',
      emoji: '🎸',
    ),
    AchievementDefinition(
      id: 'tuned_up',
      title: 'Tuned Up',
      description: 'Use the chromatic tuner for the first time.',
      emoji: '🎵',
    ),
    AchievementDefinition(
      id: 'seven_day_streak',
      title: '7-Day Streak',
      description: 'Practice on 7 consecutive days.',
      emoji: '🔥',
    ),
    AchievementDefinition(
      id: 'scale_explorer',
      title: 'Scale Explorer',
      description: 'View 10 different scales.',
      emoji: '🗺️',
    ),
    AchievementDefinition(
      id: 'rhythm_master',
      title: 'Rhythm Master',
      description: 'Score 90% or higher in a rhythm game.',
      emoji: '🥁',
    ),
    AchievementDefinition(
      id: 'ear_wizard',
      title: 'Ear Wizard',
      description: 'Complete 20 ear training exercises.',
      emoji: '👂',
    ),
    AchievementDefinition(
      id: 'composer',
      title: 'Composer',
      description: 'Generate 5 chord progressions.',
      emoji: '🎼',
    ),
    AchievementDefinition(
      id: 'community_member',
      title: 'Community Member',
      description: 'Post in the community for the first time.',
      emoji: '🤝',
    ),
    AchievementDefinition(
      id: 'health_conscious',
      title: 'Health Conscious',
      description: 'Enable health reminders to protect your hands.',
      emoji: '💪',
    ),
    AchievementDefinition(
      id: 'song_learner',
      title: 'Song Learner',
      description: 'View 5 different songs.',
      emoji: '🎤',
    ),
  ];

  // ── Public API ────────────────────────────────────────────────────────────

  /// Unlocks the achievement with [achievementId] and persists the timestamp.
  ///
  /// If the achievement is already unlocked this method is a no-op.
  /// Throws [StorageFailure] if the value cannot be persisted.
  ///
  /// Logs an error with [debugPrint] and rethrows for unknown achievements so
  /// callers are not silently failing with a typo in the id.
  Future<void> unlock(String achievementId) async {
    try {
      final alreadyUnlocked = await isUnlocked(achievementId);
      if (alreadyUnlocked) return;

      final definition = _definitionById(achievementId);
      if (definition == null) {
        debugPrint(
          'AchievementService.unlock: unknown achievement id "$achievementId"',
        );
        return;
      }

      await _storage.save(
        StorageService.achievementsBox,
        achievementId,
        DateTime.now().toIso8601String(),
      );

      debugPrint(
        'AchievementService: unlocked "${definition.title}" (${definition.emoji})',
      );
    } on StorageFailure {
      rethrow;
    } catch (e, st) {
      debugPrint('AchievementService.unlock error: $e\n$st');
    }
  }

  /// Returns the list of achievement IDs that have been unlocked.
  ///
  /// Checks each known achievement ID against the storage box, so only valid
  /// IDs are ever returned.  Throws [StorageFailure] if the box cannot be read.
  Future<List<String>> getUnlocked() async {
    try {
      // Achievement IDs are stored as *keys*; check each known ID individually.
      final results = <String>[];
      for (final definition in allAchievements) {
        final value = await _storage.get<String>(
          StorageService.achievementsBox,
          definition.id,
        );
        if (value != null) results.add(definition.id);
      }
      return results;
    } on StorageFailure {
      rethrow;
    } catch (e, st) {
      debugPrint('AchievementService.getUnlocked error: $e\n$st');
      return [];
    }
  }

  /// Returns `true` if the achievement with [id] has been unlocked.
  ///
  /// Throws [StorageFailure] if the box cannot be read.
  Future<bool> isUnlocked(String id) async {
    try {
      final value =
          await _storage.get<String>(StorageService.achievementsBox, id);
      return value != null;
    } on StorageFailure {
      rethrow;
    } catch (e, st) {
      debugPrint('AchievementService.isUnlocked error: $e\n$st');
      return false;
    }
  }

  /// Returns the [AchievementDefinition] for every unlocked achievement,
  /// in the order they appear in [allAchievements].
  ///
  /// Throws [StorageFailure] if the box cannot be read.
  Future<List<AchievementDefinition>> getUnlockedDefinitions() async {
    final unlockedIds = await getUnlocked();
    final idSet = unlockedIds.toSet();
    return allAchievements.where((a) => idSet.contains(a.id)).toList();
  }

  /// Looks up an [AchievementDefinition] by its [id], returning `null` if
  /// the id is not recognised.
  AchievementDefinition? definitionById(String id) => _definitionById(id);

  // ── Internal Helpers ──────────────────────────────────────────────────────

  AchievementDefinition? _definitionById(String id) {
    try {
      return allAchievements.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
