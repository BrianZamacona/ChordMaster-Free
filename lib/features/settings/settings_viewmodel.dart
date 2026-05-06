import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/storage_service.dart';

/// Immutable state for [SettingsViewModel].
class SettingsState {
  const SettingsState({this.themeMode = ThemeMode.system});

  /// The currently selected [ThemeMode].
  final ThemeMode themeMode;

  SettingsState copyWith({ThemeMode? themeMode}) =>
      SettingsState(themeMode: themeMode ?? this.themeMode);
}

/// Provider for [SettingsViewModel].
final settingsViewModelProvider =
    NotifierProvider<SettingsViewModel, SettingsState>(
        SettingsViewModel.new);

/// Manages persisted app settings such as [ThemeMode].
class SettingsViewModel extends Notifier<SettingsState> {
  static const _keyThemeMode = 'themeMode';

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
      state = state.copyWith(themeMode: _parseThemeMode(raw));
    } catch (e, st) {
      debugPrint('SettingsViewModel._loadSettings error: $e\n$st');
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
