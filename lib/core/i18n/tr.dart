/// Idioma de la interfaz (español o inglés) y la función [tr].
///
/// Dart puro (sin Flutter) para que también lo use el texto de teoría de
/// `lib/domain/`. Ambas versiones son parámetros obligatorios: un texto sin
/// traducción no compila.
library;

enum AppLanguage { es, en }

/// Idioma actual. Lo fija `ChordMasterApp` a partir de los ajustes; al
/// cambiarlo, la app reconstruye todo el árbol para que se relean los textos.
abstract final class CurrentLanguage {
  static AppLanguage value = AppLanguage.es;
}

/// `en` → inglés; cualquier otro código → español (idioma principal).
AppLanguage appLanguageFor(String code) =>
    code == 'en' ? AppLanguage.en : AppLanguage.es;

String tr({required String es, required String en}) =>
    CurrentLanguage.value == AppLanguage.en ? en : es;

/// Texto en ambos idiomas guardado como dato (teoría, guías...).
class LocalizedText {
  const LocalizedText({required this.es, required this.en});

  final String es;
  final String en;

  String get text => tr(es: es, en: en);

  @override
  String toString() => text;
}
