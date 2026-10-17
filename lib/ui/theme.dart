import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'palette.dart';

export 'palette.dart';

/// Títulos: Bricolage Grotesque. Texto: Atkinson Hyperlegible (pensada para
/// leerse sin esfuerzo). Las fuentes van empaquetadas en `assets/google_fonts/`,
/// así que no se descargan en tiempo de ejecución.
TextTheme _buildTextTheme(TextTheme base, AppPalette p) {
  final body = GoogleFonts.atkinsonHyperlegibleTextTheme(base).apply(
    bodyColor: p.textPrimary,
    displayColor: p.textPrimary,
  );
  TextStyle? display(TextStyle? s, FontWeight w) =>
      GoogleFonts.bricolageGrotesque(textStyle: s, fontWeight: w);
  return body.copyWith(
    displayLarge: display(body.displayLarge, FontWeight.w800),
    displayMedium: display(body.displayMedium, FontWeight.w800),
    displaySmall: display(body.displaySmall, FontWeight.w700),
    headlineLarge: display(body.headlineLarge, FontWeight.w700),
    headlineMedium: display(body.headlineMedium, FontWeight.w700),
    headlineSmall: display(body.headlineSmall, FontWeight.w700),
    titleLarge: display(body.titleLarge, FontWeight.w700),
    titleMedium: display(body.titleMedium, FontWeight.w700),
    titleSmall: display(body.titleSmall, FontWeight.w700),
  );
}

/// Estilo monoespaciado para notas, intervalos y trastes (IBM Plex Mono).
TextStyle musicMono({
  double? fontSize,
  FontWeight fontWeight = FontWeight.w400,
  Color? color,
}) =>
    GoogleFonts.ibmPlexMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );

ThemeData _buildTheme(AppPalette p, Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: p.accent,
    brightness: brightness,
  ).copyWith(
    primary: p.accent,
    onPrimary: p.onAccent,
    secondary: p.intervalThird,
    onSecondary: p.onInterval,
    // Selecciones (chips, pestañas): latón translúcido sobre la tarjeta, no
    // el melocotón que Material deriva de la semilla.
    primaryContainer: Color.alphaBlend(p.accent.withValues(alpha: 0.22), p.surface),
    onPrimaryContainer: p.textPrimary,
    secondaryContainer:
        Color.alphaBlend(p.accent.withValues(alpha: 0.22), p.surface),
    onSecondaryContainer: p.textPrimary,
    tertiary: p.intervalFifth,
    surface: p.surface,
    onSurface: p.textPrimary,
    onSurfaceVariant: p.textSecondary,
    surfaceContainerLowest: p.background,
    surfaceContainerLow: p.background,
    surfaceContainer: p.surface,
    surfaceContainerHigh: p.surfaceHigh,
    surfaceContainerHighest: p.surfaceHigh,
    outline: p.outline,
    outlineVariant: p.outline,
    error: p.error,
  );
  final text = _buildTextTheme(
    brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme,
    p,
  );
  const radius = BorderRadius.all(Radius.circular(14));
  final buttonStyle = ButtonStyle(
    shape: const WidgetStatePropertyAll(StadiumBorder()),
    textStyle: WidgetStatePropertyAll(text.labelLarge),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.background,
    textTheme: text,
    extensions: [p],
    cardTheme: CardThemeData(
      elevation: 0,
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: p.outline),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
      shape: Border(bottom: BorderSide(color: p.outline)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: buttonStyle.merge(
        FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          disabledBackgroundColor: p.surfaceHigh,
          disabledForegroundColor: p.textDisabled,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: buttonStyle.merge(
        ElevatedButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.onAccent,
          elevation: 0,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: buttonStyle.merge(
        OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          side: BorderSide(color: p.outline),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: p.accent),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      backgroundColor: p.surface,
      selectedColor: p.accent.withValues(alpha: 0.22),
      checkmarkColor: p.accent,
      side: BorderSide(color: p.outline),
      labelStyle: text.labelLarge?.copyWith(color: p.textPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      hintStyle: TextStyle(color: p.textSecondary),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: p.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: p.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: p.accent, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: p.accent.withValues(alpha: 0.22),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? p.accent
              : p.textSecondary,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.labelSmall?.copyWith(
          color: states.contains(WidgetState.selected)
              ? p.accent
              : p.textSecondary,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w400,
        ),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: p.surface,
      selectedItemColor: p.accent,
      unselectedItemColor: p.textSecondary,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.accent.withValues(alpha: 0.22)
              : p.surface,
        ),
        foregroundColor: WidgetStatePropertyAll(p.textPrimary),
        side: WidgetStatePropertyAll(BorderSide(color: p.outline)),
        textStyle: WidgetStatePropertyAll(text.labelLarge),
      ),
    ),
    drawerTheme: DrawerThemeData(backgroundColor: p.background),
    dividerTheme: DividerThemeData(color: p.outline),
    sliderTheme: SliderThemeData(
      activeTrackColor: p.accent,
      thumbColor: p.accent,
      inactiveTrackColor: p.outline,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.surfaceHigh,
      contentTextStyle: text.bodyMedium,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Tema claro: hueso y madera.
final ThemeData lightTheme = _buildTheme(AppPalette.light, Brightness.light);

/// Tema oscuro: palisandro y latón.
final ThemeData darkTheme = _buildTheme(AppPalette.dark, Brightness.dark);

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
