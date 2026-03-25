/// All user-facing strings for ChordMaster Free.
///
/// Using a single source of truth makes localisation straightforward and
/// guarantees consistent wording across the app.
class AppStrings {
  AppStrings._();

  // ── App ────────────────────────────────────────────────────────────────────

  /// Application display name.
  static const String appName = 'ChordMaster Free';

  /// Short tagline shown on the splash / home screen.
  static const String appTagline = 'Master music at your own pace';

  // ── Module Names ───────────────────────────────────────────────────────────

  /// Chord library module name.
  static const String moduleChords = 'Chords';

  /// Scales reference module name.
  static const String moduleScales = 'Scales';

  /// Chromatic tuner module name.
  static const String moduleTuner = 'Tuner';

  /// Metronome module name.
  static const String moduleMetronome = 'Metronome';

  /// Chord progressions module name.
  static const String moduleProgressions = 'Progressions';

  /// Ear training module name.
  static const String moduleEarTraining = 'Ear Training';

  /// Rhythm game module name.
  static const String moduleRhythmGame = 'Rhythm Game';

  /// Improvisation guide module name.
  static const String moduleImprovisation = 'Improvisation';

  /// Song library module name.
  static const String moduleSongs = 'Songs';

  /// Composition tools module name.
  static const String moduleComposition = 'Composition';

  /// Practice health / wellness module name.
  static const String moduleHealth = 'Practice Health';

  /// Community feed module name.
  static const String moduleCommunity = 'Community';

  /// Achievements module name.
  static const String moduleAchievements = 'Achievements';

  // ── Common Button Labels ───────────────────────────────────────────────────

  /// Generic play action.
  static const String play = 'Play';

  /// Generic stop action.
  static const String stop = 'Stop';

  /// Generic pause action.
  static const String pause = 'Pause';

  /// Generic resume action.
  static const String resume = 'Resume';

  /// Generic save action.
  static const String save = 'Save';

  /// Generic cancel action.
  static const String cancel = 'Cancel';

  /// Generic delete action.
  static const String delete = 'Delete';

  /// Generic edit action.
  static const String edit = 'Edit';

  /// Generic confirm action.
  static const String confirm = 'Confirm';

  /// Generic back action.
  static const String back = 'Back';

  /// Generic close action.
  static const String close = 'Close';

  /// Generic retry action.
  static const String retry = 'Retry';

  /// Generic reset action.
  static const String reset = 'Reset';

  /// Generic next action.
  static const String next = 'Next';

  /// Generic previous action.
  static const String previous = 'Previous';

  /// Generic submit action.
  static const String submit = 'Submit';

  /// Generate / create new content action.
  static const String generate = 'Generate';

  /// Analyze audio or content action.
  static const String analyze = 'Analyze';

  /// Share content action.
  static const String share = 'Share';

  /// Add to favourites action.
  static const String addFavourite = 'Add to Favourites';

  /// Remove from favourites action.
  static const String removeFavourite = 'Remove from Favourites';

  /// Request a system permission action.
  static const String grantPermission = 'Grant Permission';

  /// Open app settings action.
  static const String openSettings = 'Open Settings';

  /// Support the developer action (shown in donation prompts).
  static const String supportApp = 'Support ChordMaster ♥';

  /// Like / upvote action.
  static const String like = 'Like';

  /// Post a community entry.
  static const String post = 'Post';

  /// Start a new session / activity.
  static const String start = 'Start';

  /// Finish / complete a session.
  static const String finish = 'Finish';

  /// Tap-to-set BPM action.
  static const String tap = 'Tap';

  /// Increase value action.
  static const String increase = 'Increase';

  /// Decrease value action.
  static const String decrease = 'Decrease';

  /// View all items action.
  static const String viewAll = 'View All';

  /// Load more items action.
  static const String loadMore = 'Load More';

  // ── Tuner ─────────────────────────────────────────────────────────────────

  /// Label shown when a note is detected as in-tune.
  static const String inTune = 'In Tune';

  /// Label shown when note is slightly sharp.
  static const String sharp = 'Sharp';

  /// Label shown when note is slightly flat.
  static const String flat = 'Flat';

  /// Tuner listening state label.
  static const String listening = 'Listening…';

  /// Tuner idle state label.
  static const String tunerIdle = 'Play a note to begin';

  /// Cents label used near the deviation indicator.
  static const String cents = 'cents';

  // ── Metronome ─────────────────────────────────────────────────────────────

  /// BPM label.
  static const String bpm = 'BPM';

  /// Time signature label.
  static const String timeSignature = 'Time Signature';

  /// Beats per bar label.
  static const String beatsPerBar = 'Beats per bar';

  /// Subdivision label.
  static const String subdivision = 'Subdivision';

  // ── Chords ────────────────────────────────────────────────────────────────

  /// Root note selector label.
  static const String rootNote = 'Root Note';

  /// Chord type selector label.
  static const String chordType = 'Chord Type';

  /// Chord voicing label.
  static const String voicing = 'Voicing';

  /// Difficulty label.
  static const String difficulty = 'Difficulty';

  /// Fret positions label.
  static const String fretPositions = 'Fret Positions';

  // ── Scales ────────────────────────────────────────────────────────────────

  /// Scale type selector label.
  static const String scaleType = 'Scale Type';

  /// Related chords label.
  static const String relatedChords = 'Related Chords';

  /// Common usage description label.
  static const String commonUsage = 'Common Usage';

  // ── Progressions ──────────────────────────────────────────────────────────

  /// Key selector label.
  static const String key = 'Key';

  /// Major / minor toggle label.
  static const String majorMinor = 'Major / Minor';

  /// Style selector label.
  static const String style = 'Style';

  /// Roman numeral analysis label.
  static const String numeralAnalysis = 'Numeral Analysis';

  // ── Ear Training ──────────────────────────────────────────────────────────

  /// Prompt asking the user to identify the heard interval.
  static const String identifyInterval = 'What interval did you hear?';

  /// Prompt asking the user to identify the heard chord.
  static const String identifyChord = 'What chord did you hear?';

  /// Correct answer feedback.
  static const String correct = 'Correct!';

  /// Incorrect answer feedback.
  static const String incorrect = 'Incorrect';

  /// Score label.
  static const String score = 'Score';

  /// Streak label.
  static const String streak = 'Streak';

  /// Round label.
  static const String round = 'Round';

  // ── Songs ─────────────────────────────────────────────────────────────────

  /// Song title label.
  static const String title = 'Title';

  /// Artist label.
  static const String artist = 'Artist';

  /// Genre label.
  static const String genre = 'Genre';

  /// Tempo (BPM) label.
  static const String tempo = 'Tempo';

  /// Notes label.
  static const String notes = 'Notes';

  /// Strumming pattern label.
  static const String strummingPattern = 'Strumming Pattern';

  // ── Community ─────────────────────────────────────────────────────────────

  /// Placeholder for a new community post text field.
  static const String writePostHint = 'Share something with the community…';

  /// Post character limit hint.
  static const String postCharacterLimit = '500 characters max';

  /// Tags input hint.
  static const String tagsHint = 'Add tags (e.g. beginner, jazz)';

  /// Author label.
  static const String author = 'Author';

  /// No posts placeholder.
  static const String noPostsYet = 'No posts yet. Be the first!';

  // ── Achievements ──────────────────────────────────────────────────────────

  /// Achievement unlocked notification title.
  static const String achievementUnlocked = 'Achievement Unlocked!';

  /// Label for locked achievements.
  static const String locked = 'Locked';

  /// Label for unlocked achievements.
  static const String unlocked = 'Unlocked';

  // ── Health / Practice ─────────────────────────────────────────────────────

  /// Practice session duration label.
  static const String sessionDuration = 'Session Duration';

  /// Break reminder message.
  static const String takeABreak = 'Time for a short break — rest your hands!';

  /// Warm-up reminder message.
  static const String warmUpReminder = 'Remember to warm up before playing.';

  // ── Placeholder Texts ─────────────────────────────────────────────────────

  /// Search bar hint.
  static const String searchHint = 'Search…';

  /// Empty state message for chord search.
  static const String emptyChordsSearch = 'No chords match your search.';

  /// Empty state message for scale search.
  static const String emptyScalesSearch = 'No scales match your search.';

  /// Empty state message for song search.
  static const String emptySongsSearch = 'No songs match your search.';

  /// Generic empty list message.
  static const String emptyList = 'Nothing here yet.';

  // ── Error Messages ────────────────────────────────────────────────────────

  /// Generic unexpected error.
  static const String errorGeneric = 'Something went wrong. Please try again.';

  /// Audio engine error.
  static const String errorAudio = 'Audio playback failed. Check your device settings.';

  /// Microphone permission denied error.
  static const String errorMicPermission =
      'Microphone permission is required for this feature.';

  /// Storage read error.
  static const String errorStorage = 'Could not load saved data.';

  /// Storage write error.
  static const String errorStorageWrite = 'Could not save data. Please try again.';

  /// JSON parse error.
  static const String errorParse = 'Data format error. Please reinstall the app.';

  /// Network unavailable error.
  static const String errorNetwork = 'No internet connection.';

  /// Input validation: field is required.
  static const String errorFieldRequired = 'This field is required.';

  /// Input validation: content exceeds maximum length.
  static const String errorContentTooLong = 'Content exceeds the maximum allowed length.';

  /// Input validation: invalid BPM range.
  static const String errorInvalidBpm = 'BPM must be between 20 and 300.';

  /// Input validation: invalid difficulty range.
  static const String errorInvalidDifficulty = 'Difficulty must be between 1 and 5.';

  // ── Permissions ───────────────────────────────────────────────────────────

  /// Title for microphone permission rationale dialog.
  static const String permissionMicTitle = 'Microphone Access Needed';

  /// Body text for microphone permission rationale dialog.
  static const String permissionMicBody =
      'ChordMaster needs microphone access to power the tuner and '
      'rhythm game features. Please grant access to continue.';

  /// Message shown when permission is permanently denied.
  static const String permissionPermanentlyDenied =
      'Permission permanently denied. Please enable it in your device settings.';
}
