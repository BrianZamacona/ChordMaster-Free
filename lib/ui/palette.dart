import 'package:flutter/material.dart';

/// Paleta Palisandro: palisandro (fondos), latón (acento) y bronce (cuerdas).
///
/// Única fuente de color de la interfaz. Las pantallas leen `context.palette`
/// en vez de constantes, para que el modo claro y el oscuro sean coherentes.
/// Los colores por intervalo son la única codificación musical por color, y
/// siempre van acompañados de una etiqueta o una forma (nunca solo color).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.accent,
    required this.onAccent,
    required this.success,
    required this.warning,
    required this.error,
    required this.intervalRoot,
    required this.intervalThird,
    required this.intervalFifth,
    required this.intervalSeventh,
    required this.intervalTension,
    required this.onInterval,
    required this.fretString,
    required this.stringMuted,
    required this.fretWire,
    required this.nut,
  });

  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color outline;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;

  /// Latón: botones, selección y raíz.
  final Color accent;
  final Color onAccent;

  final Color success;
  final Color warning;
  final Color error;

  final Color intervalRoot;
  final Color intervalThird;
  final Color intervalFifth;
  final Color intervalSeventh;

  /// 2ª/9ª, 4ª/11ª, 6ª/13ª y alteraciones.
  final Color intervalTension;

  /// Texto (número de dedo) sobre un punto de intervalo.
  final Color onInterval;

  final Color fretString;

  /// Cuerda inactiva: apagada, pero visible sobre el fondo (≥ 3:1).
  final Color stringMuted;
  final Color fretWire;
  final Color nut;

  /// Color de una etiqueta de intervalo: de acordes (`R`, `b3`, `5`…) o de
  /// escalas (`1`, `b3`, `#5`…).
  Color intervalColor(String label) => switch (label) {
        'R' || '1' => intervalRoot,
        'b3' || '3' => intervalThird,
        'b5' || '5' || '#5' => intervalFifth,
        'b7' || '7' => intervalSeventh,
        _ => intervalTension,
      };

  static const dark = AppPalette(
    background: Color(0xFF1C1613),
    surface: Color(0xFF2A211C),
    surfaceHigh: Color(0xFF352A24),
    outline: Color(0xFF4A3C33),
    textPrimary: Color(0xFFF4ECE2),
    textSecondary: Color(0xFFB9AA9A),
    textDisabled: Color(0xFF7A6A5E),
    accent: Color(0xFFDDA748),
    onAccent: Color(0xFF1C1613),
    success: Color(0xFF7CC59A),
    warning: Color(0xFFE8B45A),
    error: Color(0xFFE5806A),
    intervalRoot: Color(0xFFDDA748),
    intervalThird: Color(0xFF6FB8A4),
    intervalFifth: Color(0xFFA3ACD0),
    intervalSeventh: Color(0xFFE08463),
    intervalTension: Color(0xFFC29BDB),
    onInterval: Color(0xFF1C1613),
    fretString: Color(0xFFCBBBA6),
    stringMuted: Color(0xFF7A6A5E),
    fretWire: Color(0xFF6E5D51),
    nut: Color(0xFFEADCC8),
  );

  static const light = AppPalette(
    background: Color(0xFFF3EFEA),
    surface: Color(0xFFFCFAF7),
    surfaceHigh: Color(0xFFEAE3DB),
    outline: Color(0xFFDDD3C8),
    textPrimary: Color(0xFF2A201B),
    textSecondary: Color(0xFF6B5D52),
    textDisabled: Color(0xFFA89A8E),
    accent: Color(0xFF8A5E12),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF2F7A55),
    warning: Color(0xFF9A6A00),
    error: Color(0xFFB0432C),
    intervalRoot: Color(0xFF8A5E12),
    intervalThird: Color(0xFF2B7A66),
    intervalFifth: Color(0xFF56619A),
    intervalSeventh: Color(0xFFB04E2B),
    intervalTension: Color(0xFF85579F),
    onInterval: Color(0xFFFFFFFF),
    fretString: Color(0xFF6B5D52),
    stringMuted: Color(0xFF94867A),
    fretWire: Color(0xFFCDBFB2),
    nut: Color(0xFF2A201B),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceHigh: l(surfaceHigh, other.surfaceHigh),
      outline: l(outline, other.outline),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textDisabled: l(textDisabled, other.textDisabled),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      error: l(error, other.error),
      intervalRoot: l(intervalRoot, other.intervalRoot),
      intervalThird: l(intervalThird, other.intervalThird),
      intervalFifth: l(intervalFifth, other.intervalFifth),
      intervalSeventh: l(intervalSeventh, other.intervalSeventh),
      intervalTension: l(intervalTension, other.intervalTension),
      onInterval: l(onInterval, other.onInterval),
      fretString: l(fretString, other.fretString),
      stringMuted: l(stringMuted, other.stringMuted),
      fretWire: l(fretWire, other.fretWire),
      nut: l(nut, other.nut),
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// Paleta del tema actual; cae en la oscura si el tema no la registra.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
