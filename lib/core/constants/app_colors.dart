import 'package:flutter/material.dart';

/// Central color palette for ChordMaster Free — Rock Elegant dark theme.
///
/// All colors are `static const` so they can be used in const constructors
/// and are resolved at compile time.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────

  /// Primary brand color — metallic red accent.
  static const Color primary = Color(0xFFC0392B);

  /// Secondary / accent color used for highlights, badges and streaks (amber/gold).
  static const Color secondary = Color(0xFFF39C12);

  // ── Background & Surface ───────────────────────────────────────────────────

  /// Dark scaffold background — near-black.
  static const Color background = Color(0xFF0D0D0D);

  /// Surface color for cards and bottom sheets.
  static const Color surface = Color(0xFF1A1A1A);

  /// Divider and outline color.
  static const Color outline = Color(0xFF2A2A2A);

  // ── Text ───────────────────────────────────────────────────────────────────

  /// Primary text color on dark surfaces.
  static const Color textPrimary = Color(0xFFF0F0F0);

  /// Secondary / muted text color.
  static const Color textSecondary = Color(0xFF888888);

  /// Disabled / hint text color.
  static const Color textDisabled = Color(0xFF4A4A4A);

  // ── Semantic ───────────────────────────────────────────────────────────────

  /// Success state (e.g. in-tune indicator).
  static const Color success = Color(0xFF4CAF50);

  /// Warning state (e.g. slightly out-of-tune).
  static const Color warning = Color(0xFFFF9800);

  /// Error state (e.g. far out-of-tune, validation error).
  static const Color error = Color(0xFFF44336);

  /// Informational highlight.
  static const Color info = Color(0xFF2196F3);

  // ── Module Colors — Rock Dark Accents ──────────────────────────────────────
  // Each module uses a distinct muted-but-visible accent for its left border.

  /// Chords module color.
  static const Color chords = Color(0xFF5C6BC0); // muted indigo

  /// Scales module color.
  static const Color scales = Color(0xFF26A69A); // muted teal

  /// Tuner module color.
  static const Color tuner = Color(0xFF00ACC1); // muted cyan

  /// Metronome module color.
  static const Color metronome = Color(0xFFEF6C00); // muted orange

  /// Progressions module color.
  static const Color progressions = Color(0xFF7E57C2); // muted purple

  /// Ear training module color.
  static const Color earTraining = Color(0xFFEC407A); // muted pink

  /// Rhythm game module color.
  static const Color rhythmGame = Color(0xFFE53935); // muted red

  /// Improvisation module color.
  static const Color improvisation = Color(0xFF43A047); // muted green

  /// Songs module color.
  static const Color songs = Color(0xFF1E88E5); // muted blue

  /// Composition module color.
  static const Color composition = Color(0xFF5E35B1); // muted deep-purple

  /// Health / practice wellness module color.
  static const Color health = Color(0xFF66BB6A); // muted light-green

  /// Community module color.
  static const Color community = Color(0xFFFFB300); // muted amber

  /// Achievements module color.
  static const Color achievements = Color(0xFFFDD835); // muted yellow

  // ── Tuner Needle ──────────────────────────────────────────────────────────

  /// Tuner needle color when the note is in tune.
  static const Color tunerInTune = success;

  /// Tuner needle color when the note is slightly sharp/flat.
  static const Color tunerClose = warning;

  /// Tuner needle color when the note is far off.
  static const Color tunerOff = error;

  // ── Fretboard ─────────────────────────────────────────────────────────────

  /// Fretboard wood color.
  static const Color fretboardWood = Color(0xFF5D4037);

  /// Fret wire color.
  static const Color fretWire = Color(0xFFBDBDBD);

  /// Pressed fret dot fill color.
  static const Color fretDotFill = primary;

  /// Open string indicator color.
  static const Color fretDotOpen = Color(0x80FFFFFF);

  /// Muted string indicator color.
  static const Color fretDotMuted = error;
}
