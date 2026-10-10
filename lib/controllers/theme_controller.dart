import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  Color _seedColor = const Color(0xFF6366F1); // Default Indigo
  ThemeMode _themeMode = ThemeMode.dark;

  Color get seedColor => _seedColor;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

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

  void setSeedColor(Color color) {
    if (_seedColor != color) {
      _seedColor = color;
      notifyListeners();
    }
  }

  void toggleThemeMode() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
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
