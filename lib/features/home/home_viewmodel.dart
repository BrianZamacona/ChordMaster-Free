import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/tr.dart';
import '../../services/storage_service.dart';

/// Immutable state for [HomeViewModel].
class HomeState {

  const HomeState({
    this.streak = 0,
    this.lastModule = '',
    this.dailyChallengeIndex = -1,
    this.recentAchievements = const [],
    this.isLoading = true,
  });
  /// Consecutive practice day count.
  final int streak;

  /// Route path of the last visited module.
  final String lastModule;

  /// Reto del día (índice en [dailyChallenges]), según el día del año;
  /// -1 = aún sin calcular. El texto se lee al construir, en el idioma actual.
  final int dailyChallengeIndex;

  String get dailyChallenge =>
      dailyChallengeIndex < 0 ? '' : dailyChallenges[dailyChallengeIndex].text;

  /// List of recently unlocked achievement IDs.
  final List<String> recentAchievements;

  /// Whether state is being loaded.
  final bool isLoading;

  HomeState copyWith({
    int? streak,
    String? lastModule,
    int? dailyChallengeIndex,
    List<String>? recentAchievements,
    bool? isLoading,
  }) => HomeState(
      streak: streak ?? this.streak,
      lastModule: lastModule ?? this.lastModule,
      dailyChallengeIndex: dailyChallengeIndex ?? this.dailyChallengeIndex,
      recentAchievements: recentAchievements ?? this.recentAchievements,
      isLoading: isLoading ?? this.isLoading,
    );
}

/// Provider for [HomeViewModel].
final homeViewModelProvider =
    NotifierProvider<HomeViewModel, HomeState>(HomeViewModel.new);

/// Manages home screen state: streak, last module, daily challenge, achievements.
class HomeViewModel extends Notifier<HomeState> {
  @override
  HomeState build() {
    loadData();
    return const HomeState();
  }

  static const _keyStreak = 'streak';
  static const _keyLastModule = 'lastModule';
  static const _keyRecentAchievements = 'recentAchievements';
  static const _keyLastPracticeDate = 'lastPracticeDate';



  /// Loads persisted data and calculates the daily challenge.
  Future<void> loadData() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final streak = await storage.get<int>(
            StorageService.userProgressBox, _keyStreak) ??
          0;
      final lastModule = await storage.get<String>(
            StorageService.userProgressBox, _keyLastModule) ??
          '';
      final raw = await storage.get<List>(
            StorageService.userProgressBox, _keyRecentAchievements) ??
          [];
      final recentAchievements = raw.cast<String>();

      // Update streak if practicing today
      final updatedStreak = await _updateStreak(streak);

      final dayOfYear = DateTime.now().difference(
            DateTime(DateTime.now().year),
          ).inDays %
          dailyChallenges.length;

      state = state.copyWith(
        streak: updatedStreak,
        lastModule: lastModule,
        dailyChallengeIndex: dayOfYear,
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
      final storage = ref.read(storageServiceProvider);
      state = state.copyWith(lastModule: route);
      await storage.save(
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
        final storage = ref.read(storageServiceProvider);
        final lastDate = await storage.get<String>(
          StorageService.userProgressBox, _keyLastPracticeDate);
      if (lastDate == todayStr) return currentStreak;

      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      final newStreak =
          (lastDate == yesterdayStr) ? currentStreak + 1 : 1;

        await storage.save(
          StorageService.userProgressBox, _keyLastPracticeDate, todayStr);
        await storage.save(
          StorageService.userProgressBox, _keyStreak, newStreak);
      return newStreak;
    } catch (e, st) {
      debugPrint('HomeViewModel._updateStreak error: $e\n$st');
      return currentStreak;
    }
  }
}

/// Retos del día, uno por día del año (en bucle).
const dailyChallenges = <LocalizedText>[
  LocalizedText(
    es: 'Aprende un acorde nuevo hoy: ¡prueba Bm7!',
    en: 'Learn a new chord today — try a Bm7!',
  ),
  LocalizedText(
    es: 'Practica escalas 10 minutos con la pentatónica menor.',
    en: 'Practice scales for 10 minutes using the pentatonic minor.',
  ),
  LocalizedText(
    es: 'Toca una progresión I–IV–V en tres tonalidades distintas.',
    en: 'Play a I–IV–V progression in three different keys.',
  ),
  LocalizedText(
    es: 'Baja un lick difícil al 60% de velocidad y sácalo limpio.',
    en: 'Slow down a tricky lick to 60% speed and nail it.',
  ),
  LocalizedText(
    es: 'Aprende un modo y nombra su nota característica.',
    en: 'Learn one mode and name its characteristic note.',
  ),
  LocalizedText(
    es: 'Transcribe de oído una melodía corta.',
    en: 'Transcribe a short melody by ear.',
  ),
  LocalizedText(
    es: 'Practica púa alterna 5 minutos en una sola cuerda.',
    en: 'Practice alternate picking for 5 minutes on a single string.',
  ),
  LocalizedText(
    es: 'Aprende un G abierto y un G con cejilla.',
    en: 'Learn an open G chord and a G barre chord.',
  ),
  LocalizedText(
    es: 'Toca de memoria la escala blues en C.',
    en: 'Play the blues scale in C from memory.',
  ),
  LocalizedText(
    es: 'Prueba una progresión que use un acorde disminuido.',
    en: 'Try a chord progression using a diminished chord.',
  ),
  LocalizedText(
    es: 'Aprende las notas de la 6ª cuerda hasta el traste 12.',
    en: 'Learn the notes on the low E string up to the 12th fret.',
  ),
  LocalizedText(
    es: 'Toca una canción que ya sepas al 120% de velocidad.',
    en: 'Practice a song you know at 120% speed.',
  ),
  LocalizedText(
    es: 'Identifica de oído tres tipos de acorde en una canción que te guste.',
    en: 'Identify three different chord types by ear in a song you like.',
  ),
  LocalizedText(
    es: 'Practica hammer-ons y pull-offs durante 10 minutos.',
    en: 'Practice hammer-ons and pull-offs for 10 minutes.',
  ),
  LocalizedText(
    es: 'Aprende dos voicings nuevos de La menor.',
    en: 'Learn two new chord voicings for A minor.',
  ),
  LocalizedText(
    es: 'Improvisa libremente 5 minutos sobre una nota pedal.',
    en: 'Improvise freely over a drone note for 5 minutes.',
  ),
  LocalizedText(
    es: 'Aprende el patrón de intervalos de la escala mayor (T T S T T T S).',
    en: 'Learn the interval patterns of a major scale.',
  ),
  LocalizedText(
    es: 'Cambia entre C, G y D sin parar.',
    en: 'Practice switching between C, G and D without stopping.',
  ),
  LocalizedText(
    es: 'Encuentra tres formas de tocar G mayor en el diapasón.',
    en: 'Find three ways to play a G major chord on the fretboard.',
  ),
  LocalizedText(
    es: 'Aprende la intro de una canción con power chords.',
    en: 'Learn a song intro using power chords.',
  ),
  LocalizedText(
    es: 'Recorre el círculo de quintas nombrando cada tonalidad.',
    en: 'Play through the circle of fifths naming each key.',
  ),
  LocalizedText(
    es: 'Practica vibrato en cada cuerda durante 2 minutos.',
    en: 'Practice vibrato on each string for 2 minutes.',
  ),
  LocalizedText(
    es: 'Compón una progresión de 4 compases y tócala en bucle.',
    en: 'Compose a 4-bar chord progression and play it repeatedly.',
  ),
  LocalizedText(
    es: 'Aprende el modo dórico y compáralo con la menor natural.',
    en: 'Learn the dorian mode and compare it to natural minor.',
  ),
  LocalizedText(
    es: 'Practica palm muting en un riff en Mi menor.',
    en: 'Practice palm muting on an E minor riff.',
  ),
  LocalizedText(
    es: 'Afina la guitarra de oído usando armónicos.',
    en: 'Tune your guitar by ear using harmonics.',
  ),
  LocalizedText(
    es: 'Aprende un acorde disminuido y hacia dónde resuelve.',
    en: 'Learn a diminished chord and where it resolves.',
  ),
  LocalizedText(
    es: 'Identifica tónica, subdominante y dominante en C mayor.',
    en: 'Identify the tonic, subdominant and dominant in C major.',
  ),
  LocalizedText(
    es: 'Toca una canción conocida en otra tonalidad.',
    en: 'Try playing a familiar song in a new key.',
  ),
  LocalizedText(
    es: 'Practica una progresión con un acorde suspendido.',
    en: 'Practice a chord progression with a suspended chord.',
  ),
  LocalizedText(
    es: 'Aprende el modo lidio y el carácter de su 4ª aumentada.',
    en: 'Learn the Lydian mode and its raised 4th character.',
  ),
];
