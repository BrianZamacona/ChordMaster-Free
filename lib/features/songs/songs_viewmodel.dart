import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/song.dart';
import '../../services/achievement_service.dart';
import '../../services/storage_service.dart';

/// Hardcoded song catalogue for ChordMaster Free.
const List<Song> _catalogue = [
  Song(
    id: 'knocking-on-heavens-door',
    title: "Knockin' on Heaven's Door",
    artist: 'Bob Dylan',
    genre: 'Rock / Country',
    chordProgression: ['G', 'D', 'Am7', 'G', 'D', 'C'],
    strummingPattern: 'D DU UDU',
    tempo: 72,
    timeSignature: '4/4',
    notes:
        'Great beginner song. Focus on smooth chord transitions between G and D.',
  ),
  Song(
    id: 'wonderwall',
    title: 'Wonderwall',
    artist: 'Oasis',
    genre: 'Britpop / Rock',
    chordProgression: ['Em7', 'G', 'Dsus4', 'A7sus4'],
    strummingPattern: 'DDU UDU',
    tempo: 87,
    timeSignature: '4/4',
    difficulty: 2,
    notes:
        'Use a capo on the 2nd fret. The strumming pattern is the key challenge.',
  ),
  Song(
    id: 'hotel-california',
    title: 'Hotel California',
    artist: 'Eagles',
    genre: 'Rock',
    chordProgression: ['Bm', 'F#', 'A', 'E', 'G', 'D', 'Em', 'F#'],
    strummingPattern: 'DU DU DU',
    tempo: 75,
    timeSignature: '4/4',
    difficulty: 4,
    notes: 'Iconic intro fingerpicking. Master the barre chord transitions.',
  ),
  Song(
    id: 'house-of-the-rising-sun',
    title: 'House of the Rising Sun',
    artist: 'The Animals',
    genre: 'Folk / Blues',
    chordProgression: ['Am', 'C', 'D', 'F', 'Am', 'E', 'Am', 'E'],
    strummingPattern: 'Fingerpick (arpeggio)',
    tempo: 98,
    timeSignature: '6/8',
    difficulty: 3,
    notes: 'Arpeggio picking pattern: bass note + 2 treble notes per beat.',
  ),
  Song(
    id: 'let-it-be',
    title: 'Let It Be',
    artist: 'The Beatles',
    genre: 'Rock / Pop',
    chordProgression: ['C', 'G', 'Am', 'F'],
    strummingPattern: 'D DU DU',
    tempo: 75,
    timeSignature: '4/4',
    notes: 'Classic I-V-vi-IV progression in C major. Perfect for beginners.',
  ),
  Song(
    id: 'wish-you-were-here',
    title: 'Wish You Were Here',
    artist: 'Pink Floyd',
    genre: 'Rock',
    chordProgression: ['G', 'Em', 'Am', 'Em', 'G'],
    strummingPattern: 'Fingerpick',
    tempo: 62,
    timeSignature: '4/4',
    difficulty: 3,
    notes:
        'Intro uses fingerpicking. Great for developing right-hand technique.',
  ),
  Song(
    id: 'brown-eyed-girl',
    title: 'Brown Eyed Girl',
    artist: 'Van Morrison',
    genre: 'Rock / Pop',
    chordProgression: ['G', 'C', 'G', 'D'],
    strummingPattern: 'DDU UDU',
    tempo: 150,
    timeSignature: '4/4',
    difficulty: 2,
    notes:
        'Upbeat strumming required. Practice at 120 BPM before going full speed.',
  ),
  Song(
    id: 'stairway-to-heaven',
    title: 'Stairway to Heaven',
    artist: 'Led Zeppelin',
    genre: 'Rock',
    chordProgression: ['Am', 'G#', 'C', 'G', 'Fmaj7', 'G', 'Am'],
    strummingPattern: 'Fingerpick + strum',
    tempo: 78,
    timeSignature: '4/4',
    difficulty: 5,
    notes: 'Iconic fingerpicking intro. Transitions to a full rock ending.',
  ),
  Song(
    id: 'country-roads',
    title: 'Take Me Home, Country Roads',
    artist: 'John Denver',
    genre: 'Country / Folk',
    chordProgression: ['G', 'Em', 'D', 'C'],
    strummingPattern: 'D DU DU',
    tempo: 82,
    timeSignature: '4/4',
    notes:
        'Capo 2nd fret to play in the original key. Simple, friendly chord shapes.',
  ),
  Song(
    id: 'smells-like-teen-spirit',
    title: 'Smells Like Teen Spirit',
    artist: 'Nirvana',
    genre: 'Grunge / Rock',
    chordProgression: ['F', 'Bb', 'Ab', 'Db'],
    strummingPattern: 'Power chord DDUUDU',
    tempo: 117,
    timeSignature: '4/4',
    difficulty: 3,
    notes:
        'Power chords with palm muting. Iconic riff uses F5, Bb5, Ab5, Db5.',
  ),
];

/// Returns the full hardcoded song catalogue.
List<Song> get allSongs => _catalogue;

/// Looks up a song by [id]; returns null if not found.
Song? findSongById(String id) {
  try {
    return _catalogue.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
}

// ── State ───────────────────────────────────────────────────────────────────

/// Immutable state for [SongsViewModel].
class SongsState {
  const SongsState({
    this.searchQuery = '',
    this.viewedSongIds = const {},
    this.isLoading = true,
  });

  final String searchQuery;
  final Set<String> viewedSongIds;
  final bool isLoading;

  List<Song> get filteredSongs {
    if (searchQuery.isEmpty) return _catalogue;
    final q = searchQuery.toLowerCase();
    return _catalogue
        .where((s) =>
            s.title.toLowerCase().contains(q) ||
            s.artist.toLowerCase().contains(q) ||
            s.genre.toLowerCase().contains(q))
        .toList();
  }

  SongsState copyWith({
    String? searchQuery,
    Set<String>? viewedSongIds,
    bool? isLoading,
  }) =>
      SongsState(
        searchQuery: searchQuery ?? this.searchQuery,
        viewedSongIds: viewedSongIds ?? this.viewedSongIds,
        isLoading: isLoading ?? this.isLoading,
      );
}

// ── Provider ─────────────────────────────────────────────────────────────────

/// Provider for [SongsViewModel].
final songsViewModelProvider =
    NotifierProvider<SongsViewModel, SongsState>(SongsViewModel.new);

// ── ViewModel ─────────────────────────────────────────────────────────────────

/// Manages songs screen state: search, viewed tracking, achievement unlocking.
class SongsViewModel extends Notifier<SongsState> {
  static const _keyViewedSongs = 'viewed_songs_count';
  static const _keyViewedSongIds = 'viewed_song_ids';

  @override
  SongsState build() {
    _loadViewedSongs();
    return const SongsState();
  }

  Future<void> _loadViewedSongs() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final raw = await storage.get<List>(
            StorageService.userProgressBox, _keyViewedSongIds) ??
          [];
      final ids = raw.cast<String>().toSet();
      state = state.copyWith(viewedSongIds: ids, isLoading: false);
    } catch (e, st) {
      debugPrint('SongsViewModel._loadViewedSongs error: $e\n$st');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Updates the search query to filter songs.
  void search(String query) => state = state.copyWith(searchQuery: query);

  /// Marks a song as viewed and checks for the [song_learner] achievement.
  Future<void> markViewed(String songId) async {
    if (state.viewedSongIds.contains(songId)) return;

    final updated = {...state.viewedSongIds, songId};
    state = state.copyWith(viewedSongIds: updated);

    try {
      final storage = ref.read(storageServiceProvider);
      await storage.save(
        StorageService.userProgressBox,
        _keyViewedSongIds,
        updated.toList(),
      );
      await storage.save(
        StorageService.userProgressBox,
        _keyViewedSongs,
        updated.length,
      );
      if (updated.length >= 5) {
        await AchievementService.instance.unlock('song_learner');
      }
    } catch (e, st) {
      debugPrint('SongsViewModel.markViewed error: $e\n$st');
    }
  }
}
