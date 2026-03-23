import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Shared sub-themes ─────────────────────────────────────────────────────────

const _cardTheme = CardTheme(
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  ),
);

const _elevatedButtonTheme = ElevatedButtonThemeData(
  style: ButtonStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
);

const _outlinedButtonTheme = OutlinedButtonThemeData(
  style: ButtonStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
);

const _filledButtonTheme = FilledButtonThemeData(
  style: ButtonStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
);

const _chipTheme = ChipThemeData(shape: StadiumBorder());

/// Light Material Design 3 theme for ChordMaster Free.
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6200EE)),
  textTheme: GoogleFonts.interTextTheme(),
  cardTheme: _cardTheme,
  elevatedButtonTheme: _elevatedButtonTheme,
  outlinedButtonTheme: _outlinedButtonTheme,
  filledButtonTheme: _filledButtonTheme,
  chipTheme: _chipTheme,
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    type: BottomNavigationBarType.fixed,
  ),
);

/// Dark Material Design 3 theme for ChordMaster Free.
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF6200EE),
    brightness: Brightness.dark,
  ),
  textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
  cardTheme: _cardTheme,
  elevatedButtonTheme: _elevatedButtonTheme,
  outlinedButtonTheme: _outlinedButtonTheme,
  filledButtonTheme: _filledButtonTheme,
  chipTheme: _chipTheme,
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    type: BottomNavigationBarType.fixed,
  ),
);

/// Convenience text style accessors on [BuildContext].
extension AppTextStyles on BuildContext {
  /// Returns [TextTheme.displayLarge] from the current theme.
  TextStyle get displayLarge => Theme.of(this).textTheme.displayLarge!;

  /// Returns [TextTheme.headlineMedium] from the current theme.
  TextStyle get headlineMedium => Theme.of(this).textTheme.headlineMedium!;

  /// Returns [TextTheme.titleLarge] from the current theme.
  TextStyle get titleLarge => Theme.of(this).textTheme.titleLarge!;

  /// Returns [TextTheme.bodyMedium] from the current theme.
  TextStyle get bodyMedium => Theme.of(this).textTheme.bodyMedium!;

  /// Returns [TextTheme.labelSmall] from the current theme.
  TextStyle get labelSmall => Theme.of(this).textTheme.labelSmall!;
}
