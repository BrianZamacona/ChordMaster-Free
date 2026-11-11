import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_i18n.dart';
import '../../services/key_value_store.dart';

/// Immutable state for [SettingsViewModel].
class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.localeCode = 'es',
    this.leftHanded = false,
  });

  /// Modo zurdo: el mástil y los diagramas se ven espejados.
  final bool leftHanded;

  /// The currently selected [ThemeMode].
  final ThemeMode themeMode;
  final String localeCode;

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? localeCode,
    bool? leftHanded,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        localeCode: localeCode ?? this.localeCode,
        leftHanded: leftHanded ?? this.leftHanded,
      );
}

/// Provider for [SettingsViewModel].
final settingsViewModelProvider =
    NotifierProvider<SettingsViewModel, SettingsState>(
        SettingsViewModel.new);

/// Manages persisted app settings such as [ThemeMode].
class SettingsViewModel extends Notifier<SettingsState> {
  static const _keyThemeMode = 'themeMode';
  static const _keyLocaleCode = 'localeCode';
  static const _keyLeftHanded = 'leftHanded';

  @override
  SettingsState build() {
    _loadSettings();
    return SettingsState(localeCode: AppI18n.defaultLocaleCode());
  }

  Future<void> _loadSettings() async {
    try {
      final storage = ref.read(keyValueStoreProvider);
      final raw = await storage.get<String>(
            StorageBoxes.settings, _keyThemeMode) ??
          'system';
      final stored = await storage.get<String>(
          StorageBoxes.settings, _keyLocaleCode);
      final localeCode =
          stored == null ? state.localeCode : AppI18n.normalize(stored);
      final leftHanded = await storage.get<bool>(StorageBoxes.settings, _keyLeftHanded) ?? false;
      state = state.copyWith(
        themeMode: _parseThemeMode(raw),
        localeCode: localeCode,
        leftHanded: leftHanded,
      );
    } catch (e, st) {
      debugPrint('SettingsViewModel._loadSettings error: $e\n$st');
    }
  }

  Future<void> setLocaleCode(String localeCode) async {
    try {
      state = state.copyWith(localeCode: localeCode);
      final storage = ref.read(keyValueStoreProvider);
      await storage.save(
        StorageBoxes.settings,
        _keyLocaleCode,
        localeCode,
      );
    } catch (e, st) {
      debugPrint('SettingsViewModel.setLocaleCode error: $e\n$st');
    }
  }

  /// Guarda y aplica el modo zurdo.
  Future<void> setLeftHanded({required bool leftHanded}) async {
    try {
      state = state.copyWith(leftHanded: leftHanded);
      await ref.read(keyValueStoreProvider).save(StorageBoxes.settings, _keyLeftHanded, leftHanded);
    } catch (e, st) {
      debugPrint('SettingsViewModel.setLeftHanded error: $e\n$st');
    }
  }

  /// Persists and applies the given [ThemeMode].
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      state = state.copyWith(themeMode: mode);
      final storage = ref.read(keyValueStoreProvider);
      await storage.save(
          StorageBoxes.settings, _keyThemeMode, _serializeThemeMode(mode));
    } catch (e, st) {
      debugPrint('SettingsViewModel.setThemeMode error: $e\n$st');
    }
  }

  static ThemeMode _parseThemeMode(String raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _serializeThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
