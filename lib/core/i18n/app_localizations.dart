import 'package:flutter/widgets.dart';

import 'app_i18n.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  factory AppLocalizations.of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      AppLocalizations(AppI18n.fallbackLocale);

  static final Map<String, Map<String, String>> _strings = {
    'en': {
      'home': 'Home',
      'more': 'More',
      'practice': 'Practice',
      'createTrack': 'Create & Track',
      'darkModeSubtitle': 'Auto/Manual',
      'language': 'Language',
      'scalesValidationNotice':
          'Patterns are temporarily hidden until validated source-of-truth data is approved.',
    },
    'es': {
      'home': 'Inicio',
      'more': 'Más',
      'practice': 'Práctica',
      'createTrack': 'Crear y seguimiento',
      'darkModeSubtitle': 'Auto/Manual',
      'language': 'Idioma',
      'scalesValidationNotice':
          'Los patrones están ocultos temporalmente hasta aprobar datos validados de fuente única.',
    },
  };

  String t(String key) {
    final current = _strings[locale.languageCode];
    if (current != null && current.containsKey(key)) {
      return current[key]!;
    }
    return _strings[AppI18n.fallbackLocale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppI18n.isSupported(locale);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
