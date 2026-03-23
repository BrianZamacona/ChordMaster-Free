import 'package:flutter/material.dart';

/// Central color palette for ChordMaster Free.
///
/// All colors are `static const` so they can be used in const constructors
/// and are resolved at compile time.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────

  /// Primary brand color used for the main action elements.
  static const Color primary = Color(0xFF6200EE);

  /// Secondary / accent color used for highlights and call-to-action badges.
  static const Color secondary = Color(0xFFFFC107);

  // ── Background & Surface ───────────────────────────────────────────────────

  /// Dark scaffold background color.
  static const Color background = Color(0xFF121212);

  /// Surface color for cards and bottom sheets.
  static const Color surface = Color(0xFF1E1E2E);

  /// Divider and outline color.
  static const Color outline = Color(0xFF3A3A5C);

  // ── Text ───────────────────────────────────────────────────────────────────

  /// Primary text color on dark surfaces.
  static const Color textPrimary = Color(0xFFE8E8F0);

  /// Secondary / muted text color.
  static const Color textSecondary = Color(0xFF9898B8);

  /// Disabled / hint text color.
  static const Color textDisabled = Color(0xFF5A5A7A);

  // ── Semantic ───────────────────────────────────────────────────────────────

  /// Success state (e.g. in-tune indicator).
  static const Color success = Color(0xFF4CAF50);

  /// Warning state (e.g. slightly out-of-tune).
  static const Color warning = Color(0xFFFF9800);

  /// Error state (e.g. far out-of-tune, validation error).
  static const Color error = Color(0xFFF44336);

  /// Informational highlight.
  static const Color info = Color(0xFF2196F3);

  // ── Module Colors ──────────────────────────────────────────────────────────

  /// Chords module color.
  static const Color chords = Colors.indigo;

  /// Scales module color.
  static const Color scales = Colors.teal;

  /// Tuner module color.
  static const Color tuner = Colors.cyan;

  /// Metronome module color.
  static const Color metronome = Colors.orange;

  /// Progressions module color.
  static const Color progressions = Colors.purple;

  /// Ear training module color.
  static const Color earTraining = Colors.pink;

  /// Rhythm game module color.
  static const Color rhythmGame = Colors.red;

  /// Improvisation module color.
  static const Color improvisation = Colors.green;

  /// Songs module color.
  static const Color songs = Colors.blue;

  /// Composition module color.
  static const Color composition = Colors.deepPurple;

  /// Health / practice wellness module color.
  static const Color health = Colors.lightGreen;

  /// Community module color.
  static const Color community = Colors.amber;

  /// Achievements module color.
  static const Color achievements = Colors.yellow;

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
  static const Color fretDotOpen = Color(0xFF80FFFFFF);

  /// Muted string indicator color.
  static const Color fretDotMuted = error;
}
