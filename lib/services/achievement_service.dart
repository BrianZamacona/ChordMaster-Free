import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/failures.dart';
import '../core/i18n/tr.dart';
import 'storage_service.dart';

/// Riverpod provider that exposes the [AchievementService] singleton.
final achievementServiceProvider =
    Provider<AchievementService>((ref) => AchievementService.instance);

/// Immutable descriptor for a single achievement.
class AchievementDefinition {

  /// Creates an [AchievementDefinition].
  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
  });
  /// Unique string identifier used for persistence.
  final String id;

  /// Short display title shown in the UI.
  final LocalizedText title;

  /// Sentence describing how to earn the achievement.
  final LocalizedText description;

  /// Emoji icon that represents the achievement.
  final String emoji;

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

  /// Factory constructor always returns [instance].
  factory AchievementService() => instance;

  AchievementService._internal();
  /// The singleton instance.
  static final AchievementService instance = AchievementService._internal();

  final StorageService _storage = StorageService();

  // ── Predefined Achievements ───────────────────────────────────────────────

  /// The complete catalogue of achievements available in ChordMaster Free.
  static const List<AchievementDefinition> allAchievements = [
    AchievementDefinition(
      id: 'first_chord',
      title: LocalizedText(es: 'Primer acorde', en: 'First Chord'),
      description: LocalizedText(
        es: 'Mira tu primer diagrama de acorde.',
        en: 'View your first chord diagram.',
      ),
      emoji: '🎸',
    ),
    AchievementDefinition(
      id: 'tuned_up',
      title: LocalizedText(es: 'Afinado', en: 'Tuned Up'),
      description: LocalizedText(
        es: 'Usa el afinador cromático por primera vez.',
        en: 'Use the chromatic tuner for the first time.',
      ),
      emoji: '🎵',
    ),
    AchievementDefinition(
      id: 'seven_day_streak',
      title: LocalizedText(es: 'Racha de 7 días', en: '7-Day Streak'),
      description: LocalizedText(
        es: 'Practica 7 días seguidos.',
        en: 'Practice on 7 consecutive days.',
      ),
      emoji: '🔥',
    ),
    AchievementDefinition(
      id: 'scale_explorer',
      title: LocalizedText(es: 'Explorador de escalas', en: 'Scale Explorer'),
      description: LocalizedText(
        es: 'Mira 10 escalas distintas.',
        en: 'View 10 different scales.',
      ),
      emoji: '🗺️',
    ),
    AchievementDefinition(
      id: 'rhythm_master',
      title: LocalizedText(es: 'Maestro del ritmo', en: 'Rhythm Master'),
      description: LocalizedText(
        es: 'Logra 90% o más en un juego de ritmo.',
        en: 'Score 90% or higher in a rhythm game.',
      ),
      emoji: '🥁',
    ),
    AchievementDefinition(
      id: 'ear_wizard',
      title: LocalizedText(es: 'Oído mágico', en: 'Ear Wizard'),
      description: LocalizedText(
        es: 'Completa 20 ejercicios de oído.',
        en: 'Complete 20 ear training exercises.',
      ),
      emoji: '👂',
    ),
    AchievementDefinition(
      id: 'composer',
      title: LocalizedText(es: 'Compositor', en: 'Composer'),
      description: LocalizedText(
        es: 'Genera 5 progresiones de acordes.',
        en: 'Generate 5 chord progressions.',
      ),
      emoji: '🎼',
    ),
    AchievementDefinition(
      id: 'health_conscious',
      title: LocalizedText(es: 'Manos sanas', en: 'Health Conscious'),
      description: LocalizedText(
        es: 'Activa los recordatorios para cuidar tus manos.',
        en: 'Enable health reminders to protect your hands.',
      ),
      emoji: '💪',
    ),
    AchievementDefinition(
      id: 'song_learner',
      title: LocalizedText(es: 'Aprendiz de canciones', en: 'Song Learner'),
      description: LocalizedText(
        es: 'Mira 5 canciones distintas.',
        en: 'View 5 different songs.',
      ),
      emoji: '🎤',
    ),
  ];

  // ── Public API ────────────────────────────────────────────────────────────

  /// Anota [value] en la lista de vistos de [key] (sin repetir) y, al llegar a
  /// [goal] distintos, desbloquea [achievementId]. Devuelve cuántos van.
  Future<int> recordDistinct({
    required StorageService storage,
    required String key,
    required String value,
    required int goal,
    required String achievementId,
  }) async {
    final int count;
    try {
      final seen = {
        ...?(await storage.get<List<dynamic>>(StorageService.userProgressBox, key))
            ?.whereType<String>(),
      };
      if (seen.add(value)) {
        await storage.save(StorageService.userProgressBox, key, seen.toList());
      }
      count = seen.length;
    } catch (e, st) {
      debugPrint('AchievementService.recordDistinct error ($key): $e\n$st');
      return 0;
    }
    // Un fallo al guardar el logro no debe perder el conteo.
    if (count >= goal) {
      try {
        await unlock(achievementId);
      } catch (e, st) {
        debugPrint('AchievementService.recordDistinct unlock error: $e\n$st');
      }
    }
    return count;
  }

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
