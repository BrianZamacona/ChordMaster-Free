import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/storage_service.dart';

/// Immutable state for [HomeViewModel].
class HomeState {

  const HomeState({
    this.streak = 0,
    this.lastModule = '',
    this.dailyChallenge = '',
    this.recentAchievements = const [],
    this.isLoading = true,
  });
  /// Consecutive practice day count.
  final int streak;

  /// Route path of the last visited module.
  final String lastModule;

  /// Daily challenge description, seeded by day-of-year.
  final String dailyChallenge;

  /// List of recently unlocked achievement IDs.
  final List<String> recentAchievements;

  /// Whether state is being loaded.
  final bool isLoading;

  HomeState copyWith({
    int? streak,
    String? lastModule,
    String? dailyChallenge,
    List<String>? recentAchievements,
    bool? isLoading,
  }) => HomeState(
      streak: streak ?? this.streak,
      lastModule: lastModule ?? this.lastModule,
      dailyChallenge: dailyChallenge ?? this.dailyChallenge,
      recentAchievements: recentAchievements ?? this.recentAchievements,
      isLoading: isLoading ?? this.isLoading,
    );
}

/// Provider for [HomeViewModel].
final homeViewModelProvider =
    StateNotifierProvider<HomeViewModel, HomeState>(
  (ref) => HomeViewModel(ref.read(storageServiceProvider)),
);

/// Manages home screen state: streak, last module, daily challenge, achievements.
class HomeViewModel extends StateNotifier<HomeState> {
  HomeViewModel(this._storage) : super(const HomeState()) {
    loadData();
  }

  final StorageService _storage;

  static const _keyStreak = 'streak';
  static const _keyLastModule = 'lastModule';
  static const _keyRecentAchievements = 'recentAchievements';
  static const _keyLastPracticeDate = 'lastPracticeDate';

  static const List<String> _dailyChallenges = [
    'Learn a new chord today — try a Bm7!',
    'Practice scales for 10 minutes using the pentatonic minor.',
    'Play a I–IV–V progression in three different keys.',
    'Slow down a tricky lick to 60% speed and nail it.',
    'Learn one mode and name its characteristic note.',
    'Transcribe a short melody by ear.',
    'Practice alternate picking for 5 minutes on a single string.',
    'Learn an open G chord and a G barre chord.',
    'Play the blues scale in C from memory.',
    'Try a chord progression using a diminished chord.',
    'Learn the notes on the low E string up to the 12th fret.',
    'Practice a song you know at 120% speed.',
    'Identify three different chord types by ear in a song you like.',
    'Practice hammer-ons and pull-offs for 10 minutes.',
    'Learn two new chord voicings for A minor.',
    'Improvise freely over a drone note for 5 minutes.',
    'Learn the interval patterns of a major scale.',
    'Practice switching between C, G and D without stopping.',
    'Find three ways to play a G major chord on the fretboard.',
    'Learn a song intro using power chords.',
    'Play through the circle of fifths naming each key.',
    'Practice vibrato on each string for 2 minutes.',
    'Compose a 4-bar chord progression and play it repeatedly.',
    'Learn the dorian mode and compare it to natural minor.',
    'Practice palm muting on an E minor riff.',
    'Tune your guitar by ear using harmonics.',
    'Learn a diminished chord and where it resolves.',
    'Identify the tonic, subdominant and dominant in C major.',
    'Try playing a familiar song in a new key.',
    'Practice a chord progression with a suspended chord.',
    'Learn the Lydian mode and its raised 4th character.',
  ];

  /// Loads persisted data and calculates the daily challenge.
  Future<void> loadData() async {
    try {
      final streak = await _storage.get<int>(
            StorageService.userProgressBox, _keyStreak) ??
          0;
      final lastModule = await _storage.get<String>(
            StorageService.userProgressBox, _keyLastModule) ??
          '';
      final raw = await _storage.get<List>(
            StorageService.userProgressBox, _keyRecentAchievements) ??
          [];
      final recentAchievements = raw.cast<String>();

      // Update streak if practicing today
      final updatedStreak = await _updateStreak(streak);

      final dayOfYear = DateTime.now().difference(
            DateTime(DateTime.now().year),
          ).inDays %
          _dailyChallenges.length;
      final challenge = _dailyChallenges[dayOfYear];

      state = state.copyWith(
        streak: updatedStreak,
        lastModule: lastModule,
        dailyChallenge: challenge,
        recentAchievements: recentAchievements,
        isLoading: false,
      );
    } catch (e, st) {
      debugPrint('HomeViewModel.loadData error: $e\n$st');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Updates [lastModule] in state and persists the value.
  Future<void> updateLastModule(String route) async {
    try {
      state = state.copyWith(lastModule: route);
      await _storage.save(
          StorageService.userProgressBox, _keyLastModule, route);
    } catch (e, st) {
      debugPrint('HomeViewModel.updateLastModule error: $e\n$st');
    }
  }

  /// Increments streak if today is a new practice day.
  Future<int> _updateStreak(int currentStreak) async {
    try {
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final lastDate = await _storage.get<String>(
          StorageService.userProgressBox, _keyLastPracticeDate);
      if (lastDate == todayStr) return currentStreak;

      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      final newStreak =
          (lastDate == yesterdayStr) ? currentStreak + 1 : 1;

      await _storage.save(
          StorageService.userProgressBox, _keyLastPracticeDate, todayStr);
      await _storage.save(
          StorageService.userProgressBox, _keyStreak, newStreak);
      return newStreak;
    } catch (e, st) {
      debugPrint('HomeViewModel._updateStreak error: $e\n$st');
      return currentStreak;
    }
  }
}
