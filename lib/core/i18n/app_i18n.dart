import 'package:flutter/widgets.dart';

enum TranslationQuality { gold, machineAssisted }

class SupportedLanguage {
  const SupportedLanguage({
    required this.locale,
    required this.quality,
    required this.displayName,
  });

  final Locale locale;
  final TranslationQuality quality;
  final String displayName;
}

class AppI18n {
  AppI18n._();

  static const fallbackLocale = Locale('en');
  static const baseLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  static const supportedLanguages = <SupportedLanguage>[
    SupportedLanguage(
      locale: Locale('en'),
      quality: TranslationQuality.gold,
      displayName: 'English',
    ),
    SupportedLanguage(
      locale: Locale('es'),
      quality: TranslationQuality.gold,
      displayName: 'Español',
    ),
    SupportedLanguage(
      locale: Locale('pt'),
      quality: TranslationQuality.machineAssisted,
      displayName: 'Português',
    ),
    SupportedLanguage(
      locale: Locale('de'),
      quality: TranslationQuality.machineAssisted,
      displayName: 'Deutsch',
    ),
    SupportedLanguage(
      locale: Locale('ru'),
      quality: TranslationQuality.machineAssisted,
      displayName: 'Русский',
    ),
    SupportedLanguage(
      locale: Locale('zh'),
      quality: TranslationQuality.machineAssisted,
      displayName: '中文',
    ),
    SupportedLanguage(
      locale: Locale('ja'),
      quality: TranslationQuality.machineAssisted,
      displayName: '日本語',
    ),
    SupportedLanguage(
      locale: Locale('fr'),
      quality: TranslationQuality.machineAssisted,
      displayName: 'Français',
    ),
    SupportedLanguage(
      locale: Locale('it'),
      quality: TranslationQuality.machineAssisted,
      displayName: 'Italiano',
    ),
  ];

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
    Locale('de'),
    Locale('ru'),
    Locale('zh'),
    Locale('ja'),
    Locale('fr'),
    Locale('it'),
  ];

  static bool isSupported(Locale locale) => supportedLocales
      .any((supported) => supported.languageCode == locale.languageCode);
}
