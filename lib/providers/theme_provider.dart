import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nixsvg/controllers/theme_controller.dart';
import 'package:nixsvg/providers/preferences_provider.dart';

/// Immutable state describing the application's active theme configuration.
class ThemeState {
  final Color seedColor;
  final ThemeMode themeMode;

  const ThemeState({
    required this.seedColor,
    required this.themeMode,
  });

  bool get isDarkMode => themeMode == ThemeMode.dark;

  ThemeState copyWith({
    Color? seedColor,
    ThemeMode? themeMode,
  }) {
    return ThemeState(
      seedColor: seedColor ?? this.seedColor,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

/// Riverpod [Notifier] that manages theme changes and persists them to [SharedPreferences].
class ThemeNotifier extends Notifier<ThemeState> {
  @override
  ThemeState build() {
    final prefs = ref.watch(preferencesServiceProvider);
    final initialSeed = prefs.getSeedColor();
    final initialMode = prefs.getThemeMode();

    // Sync legacy themeController instance
    themeController.syncFrom(seed: initialSeed, mode: initialMode);

    return ThemeState(
      seedColor: initialSeed,
      themeMode: initialMode,
    );
  }

  void setSeedColor(Color color) {
    if (state.seedColor != color) {
      state = state.copyWith(seedColor: color);
      ref.read(preferencesServiceProvider).setSeedColor(color);
      themeController.setSeedColor(color);
    }
  }

  void toggleThemeMode() {
    final nextMode = state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(nextMode);
  }

  void setThemeMode(ThemeMode mode) {
    if (state.themeMode != mode) {
      state = state.copyWith(themeMode: mode);
      ref.read(preferencesServiceProvider).setThemeMode(mode);
      themeController.setThemeMode(mode);
    }
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(ThemeNotifier.new);
