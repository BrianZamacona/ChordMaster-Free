import 'dart:ui' show Locale, PlatformDispatcher;

class SupportedLanguage {
  const SupportedLanguage({required this.locale, required this.displayName});

  final Locale locale;
  final String displayName;
}

/// Idiomas con traducción completa (ver `tr.dart`).
class AppI18n {
  AppI18n._();

  static const supportedLanguages = <SupportedLanguage>[
    SupportedLanguage(locale: Locale('es'), displayName: 'Español'),
    SupportedLanguage(locale: Locale('en'), displayName: 'English'),
  ];

  static const supportedLocales = <Locale>[Locale('es'), Locale('en')];

  /// Idioma inicial si el usuario no eligió uno: el del teléfono si es
  /// inglés; en cualquier otro caso, español.
  static String defaultLocaleCode([Locale? device]) =>
      (device ?? PlatformDispatcher.instance.locale).languageCode == 'en'
      ? 'en'
      : 'es';

  /// Normaliza un código guardado (versiones viejas ofrecían pt, de...).
  static String normalize(String code) => code == 'en' ? 'en' : 'es';
}
