import 'package:flutter/material.dart';

/// Model describing a curated theme accent color preset.
class ThemePreset {
  final String name;
  final Color color;

  const ThemePreset({required this.name, required this.color});
}

/// Legacy ThemeController to ensure backward compatibility with widgets
/// while harmonizing with Riverpod's [themeProvider].
class ThemeController extends ChangeNotifier {
  Color _seedColor = const Color(0xFF6366F1); // Default Indigo
  ThemeMode _themeMode = ThemeMode.dark;

  Color get seedColor => _seedColor;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  static const List<ThemePreset> presets = [
    ThemePreset(name: 'Indigo', color: Color(0xFF6366F1)),
    ThemePreset(name: 'Emerald', color: Color(0xFF10B981)),
    ThemePreset(name: 'Blue', color: Color(0xFF3B82F6)),
    ThemePreset(name: 'Violet', color: Color(0xFF8B5CF6)),
    ThemePreset(name: 'Pink', color: Color(0xFFEC4899)),
    ThemePreset(name: 'Amber', color: Color(0xFFF59E0B)),
    ThemePreset(name: 'Cyan', color: Color(0xFF06B6D4)),
    ThemePreset(name: 'Rose', color: Color(0xFFF43F5E)),
  ];

  static const List<Color> themePresets = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFFF59E0B), // Amber
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF43F5E), // Rose
  ];

  /// Returns the human-readable display name for a given seed [color].
  static String getColorName(Color color) {
    final argb = color.toARGB32();
    for (final preset in presets) {
      if (preset.color.toARGB32() == argb) {
        return preset.name;
      }
    }
    // Check known color aliases
    if (argb == const Color(0xFF0EA5E9).toARGB32()) return 'Sky';
    if (argb == const Color(0xFFE11D48).toARGB32()) return 'Rose';
    if (argb == Colors.indigo.toARGB32()) return 'Indigo';
    if (argb == Colors.blue.toARGB32()) return 'Blue';
    if (argb == Colors.green.toARGB32()) return 'Emerald';
    if (argb == Colors.amber.toARGB32()) return 'Amber';
    if (argb == Colors.pink.toARGB32()) return 'Pink';
    if (argb == Colors.red.toARGB32()) return 'Rose';
    return 'Custom';
  }

  /// Returns the human-readable display name for a given [ThemeMode].
  static String getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void syncFrom({required Color seed, required ThemeMode mode}) {
    bool changed = false;
    if (_seedColor != seed) {
      _seedColor = seed;
      changed = true;
    }
    if (_themeMode != mode) {
      _themeMode = mode;
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  void setSeedColor(Color color) {
    if (_seedColor != color) {
      _seedColor = color;
      notifyListeners();
    }
  }

  void toggleThemeMode() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }
}

final themeController = ThemeController();
