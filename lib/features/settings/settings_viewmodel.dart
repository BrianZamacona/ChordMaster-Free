import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/storage_service.dart';

/// Immutable state for [SettingsViewModel].
class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.localeCode = 'en',
  });

  /// The currently selected [ThemeMode].
  final ThemeMode themeMode;
  final String localeCode;

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? localeCode,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        localeCode: localeCode ?? this.localeCode,
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

  @override
  SettingsState build() {
    _loadSettings();
    return const SettingsState();
  }

  Future<void> _loadSettings() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final raw = await storage.get<String>(
            StorageService.settingsBox, _keyThemeMode) ??
          'system';
      final localeCode = await storage.get<String>(
            StorageService.settingsBox, _keyLocaleCode) ??
          'en';
      state = state.copyWith(
        themeMode: _parseThemeMode(raw),
        localeCode: localeCode,
      );
    } catch (e, st) {
      debugPrint('SettingsViewModel._loadSettings error: $e\n$st');
    }
  }

  Future<void> setLocaleCode(String localeCode) async {
    try {
      state = state.copyWith(localeCode: localeCode);
      final storage = ref.read(storageServiceProvider);
      await storage.save(
        StorageService.settingsBox,
        _keyLocaleCode,
        localeCode,
      );
    } catch (e, st) {
      debugPrint('SettingsViewModel.setLocaleCode error: $e\n$st');
    }
  }

  /// Persists and applies the given [ThemeMode].
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      state = state.copyWith(themeMode: mode);
      final storage = ref.read(storageServiceProvider);
      await storage.save(
          StorageService.settingsBox, _keyThemeMode, _serializeThemeMode(mode));
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
