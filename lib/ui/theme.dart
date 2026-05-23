import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_colors.dart';

// ── Rock Elegant color seed ───────────────────────────────────────────────────

const _seedColor = AppColors.primary; // metallic red #C0392B

// ── Shared sub-themes ─────────────────────────────────────────────────────────

const _cardTheme = CardThemeData(
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  ),
);

const _elevatedButtonTheme = ElevatedButtonThemeData(
  style: ButtonStyle(
    shape: WidgetStatePropertyAll(StadiumBorder()),
    backgroundColor: WidgetStatePropertyAll(Color(0xFF8B0000)),
    foregroundColor: WidgetStatePropertyAll(Colors.white),
  ),
);

const _outlinedButtonTheme = OutlinedButtonThemeData(
  style: ButtonStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
);

const _filledButtonTheme = FilledButtonThemeData(
  style: ButtonStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
);

const _chipTheme = ChipThemeData(shape: StadiumBorder());

/// Builds the shared [TextTheme] with Oswald for display/headline and Inter for body.
TextTheme _buildTextTheme(TextTheme base) {
  final inter = GoogleFonts.interTextTheme(base);
  return inter.copyWith(
    displayLarge: GoogleFonts.oswald(textStyle: inter.displayLarge, fontWeight: FontWeight.bold),
    displayMedium: GoogleFonts.oswald(textStyle: inter.displayMedium, fontWeight: FontWeight.bold),
    displaySmall: GoogleFonts.oswald(textStyle: inter.displaySmall, fontWeight: FontWeight.bold),
    headlineLarge: GoogleFonts.oswald(textStyle: inter.headlineLarge, fontWeight: FontWeight.w700),
    headlineMedium: GoogleFonts.oswald(textStyle: inter.headlineMedium, fontWeight: FontWeight.w700),
    headlineSmall: GoogleFonts.oswald(textStyle: inter.headlineSmall, fontWeight: FontWeight.w600),
    titleLarge: GoogleFonts.oswald(textStyle: inter.titleLarge, fontWeight: FontWeight.w600),
  );
}

/// Light Material Design 3 theme for ChordMaster Free.
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
  textTheme: _buildTextTheme(ThemeData.light().textTheme),
  cardTheme: _cardTheme,
  elevatedButtonTheme: _elevatedButtonTheme,
  outlinedButtonTheme: _outlinedButtonTheme,
  filledButtonTheme: _filledButtonTheme,
  chipTheme: _chipTheme,
  navigationBarTheme: NavigationBarThemeData(
    indicatorColor: AppColors.primary.withAlpha(30),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: AppColors.primary);
      }
      return const IconThemeData(color: Color(0xFF5A5A5A));
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(color: AppColors.primary, fontSize: 12);
      }
      return const TextStyle(color: Color(0xFF5A5A5A), fontSize: 12);
    }),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    type: BottomNavigationBarType.fixed,
  ),
);

/// Dark Material Design 3 theme — Rock Elegant.
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.dark,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: const Color(0xFF2A2A2A),
    secondary: AppColors.secondary,
  ).copyWith(
    surface: AppColors.surface,
    surfaceContainer: AppColors.surface,
    surfaceContainerLow: const Color(0xFF111111),
    surfaceContainerHigh: const Color(0xFF222222),
    outline: AppColors.outline,
  ),
  scaffoldBackgroundColor: AppColors.background,
  textTheme: _buildTextTheme(ThemeData.dark().textTheme),
  cardTheme: const CardThemeData(
    elevation: 2,
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      side: BorderSide(color: AppColors.outline, width: 0.5),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    shape: Border(
      bottom: BorderSide(color: AppColors.primary),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: AppColors.surfaceDark,
    indicatorColor: AppColors.primary.withAlpha(60),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: AppColors.textPrimary);
      }
      return const IconThemeData(color: AppColors.textSecondary);
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(color: AppColors.textPrimary, fontSize: 12);
      }
      return const TextStyle(color: AppColors.textSecondary, fontSize: 12);
    }),
  ),
  elevatedButtonTheme: _elevatedButtonTheme,
  outlinedButtonTheme: _outlinedButtonTheme,
  filledButtonTheme: _filledButtonTheme,
  chipTheme: ChipThemeData(
    shape: const StadiumBorder(),
    backgroundColor: AppColors.surface,
    selectedColor: AppColors.primary.withAlpha(60),
    side: const BorderSide(color: AppColors.outline),
    labelStyle: const TextStyle(color: AppColors.textPrimary),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    type: BottomNavigationBarType.fixed,
    backgroundColor: AppColors.surfaceDark,
  ),
  dividerTheme: const DividerThemeData(color: AppColors.outline),
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
