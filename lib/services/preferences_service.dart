import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nixsvg/models/project_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for persisting and retrieving app configuration
/// and workspace preferences using [SharedPreferences].
class PreferencesService {
  final SharedPreferences? _prefs;
  final Map<String, Object> _inMemory = {};

  PreferencesService([this._prefs]);

  /// Synchronous in-memory fallback for testing or before async initialization.
  factory PreferencesService.fallback() => PreferencesService(null);

  static const String _keyThemeMode = 'nixsvg_theme_mode';
  static const String _keySeedColor = 'nixsvg_seed_color';
  static const String _keySnapToGrid = 'nixsvg_snap_to_grid';
  static const String _keyGridSpacing = 'nixsvg_grid_spacing';
  static const String _keyLayersWidth = 'nixsvg_layers_sidebar_width';
  static const String _keyPropertiesWidth = 'nixsvg_properties_sidebar_width';
  static const String _keyShowLayers = 'nixsvg_show_layers';
  static const String _keyShowProperties = 'nixsvg_show_properties';
  static const String _keyRecentProjects = 'nixsvg_recent_projects';
  static const String _keyActiveProjectId = 'nixsvg_active_project_id';
  static const String _keyHasActiveSession = 'nixsvg_has_active_session';

  /// Factory to asynchronously instantiate [PreferencesService].
  static Future<PreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  // --- Theme Mode ---
  ThemeMode getThemeMode() {
    final modeStr = _prefs != null
        ? _prefs.getString(_keyThemeMode)
        : _inMemory[_keyThemeMode] as String?;
    switch (modeStr) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark; // Default dark
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    String val;
    switch (mode) {
      case ThemeMode.light:
        val = 'light';
        break;
      case ThemeMode.dark:
        val = 'dark';
        break;
      case ThemeMode.system:
        val = 'system';
        break;
    }
    if (_prefs != null) {
      await _prefs.setString(_keyThemeMode, val);
    } else {
      _inMemory[_keyThemeMode] = val;
    }
  }

  // --- Seed Color ---
  Color getSeedColor() {
    final val = _prefs != null
        ? _prefs.getInt(_keySeedColor)
        : _inMemory[_keySeedColor] as int?;
    if (val != null) {
      return Color(val);
    }
    return const Color(0xFF6366F1); // Default Indigo
  }

  Future<void> setSeedColor(Color color) async {
    final val = color.toARGB32();
    if (_prefs != null) {
      await _prefs.setInt(_keySeedColor, val);
    } else {
      _inMemory[_keySeedColor] = val;
    }
  }

  // --- Snap to Grid ---
  bool getSnapToGrid() {
    if (_prefs != null) {
      return _prefs.getBool(_keySnapToGrid) ?? true;
    }
    return (_inMemory[_keySnapToGrid] as bool?) ?? true;
  }

  Future<void> setSnapToGrid(bool value) async {
    if (_prefs != null) {
      await _prefs.setBool(_keySnapToGrid, value);
    } else {
      _inMemory[_keySnapToGrid] = value;
    }
  }

  // --- Grid Spacing ---
  double getGridSpacing() {
    if (_prefs != null) {
      return _prefs.getDouble(_keyGridSpacing) ?? 40.0;
    }
    return (_inMemory[_keyGridSpacing] as double?) ?? 40.0;
  }

  Future<void> setGridSpacing(double spacing) async {
    if (_prefs != null) {
      await _prefs.setDouble(_keyGridSpacing, spacing);
    } else {
      _inMemory[_keyGridSpacing] = spacing;
    }
  }

  // --- Sidebar Widths ---
  double getLayersSidebarWidth() {
    if (_prefs != null) {
      return _prefs.getDouble(_keyLayersWidth) ?? 270.0;
    }
    return (_inMemory[_keyLayersWidth] as double?) ?? 270.0;
  }

  Future<void> setLayersSidebarWidth(double width) async {
    if (_prefs != null) {
      await _prefs.setDouble(_keyLayersWidth, width);
    } else {
      _inMemory[_keyLayersWidth] = width;
    }
  }

  double getPropertiesSidebarWidth() {
    if (_prefs != null) {
      return _prefs.getDouble(_keyPropertiesWidth) ?? 280.0;
    }
    return (_inMemory[_keyPropertiesWidth] as double?) ?? 280.0;
  }

  Future<void> setPropertiesSidebarWidth(double width) async {
    if (_prefs != null) {
      await _prefs.setDouble(_keyPropertiesWidth, width);
    } else {
      _inMemory[_keyPropertiesWidth] = width;
    }
  }

  // --- Panel Visibility (null indicates default responsive behavior) ---
  bool? getShowLayers() {
    if (_prefs != null) {
      return _prefs.containsKey(_keyShowLayers)
          ? _prefs.getBool(_keyShowLayers)
          : null;
    }
    return _inMemory[_keyShowLayers] as bool?;
  }

  Future<void> setShowLayers(bool? show) async {
    if (_prefs != null) {
      if (show == null) {
        await _prefs.remove(_keyShowLayers);
      } else {
        await _prefs.setBool(_keyShowLayers, show);
      }
    } else {
      if (show == null) {
        _inMemory.remove(_keyShowLayers);
      } else {
        _inMemory[_keyShowLayers] = show;
      }
    }
  }

  bool? getShowProperties() {
    if (_prefs != null) {
      return _prefs.containsKey(_keyShowProperties)
          ? _prefs.getBool(_keyShowProperties)
          : null;
    }
    return _inMemory[_keyShowProperties] as bool?;
  }

  Future<void> setShowProperties(bool? show) async {
    if (_prefs != null) {
      if (show == null) {
        await _prefs.remove(_keyShowProperties);
      } else {
        await _prefs.setBool(_keyShowProperties, show);
      }
    } else {
      if (show == null) {
        _inMemory.remove(_keyShowProperties);
      } else {
        _inMemory[_keyShowProperties] = show;
      }
    }
  }

  // --- Active Session & Projects ---
  bool getHasActiveSession() {
    if (_prefs != null) {
      return _prefs.getBool(_keyHasActiveSession) ?? false;
    }
    // For unit/widget tests in fallback mode, default to true unless specified
    return (_inMemory[_keyHasActiveSession] as bool?) ?? true;
  }

  Future<void> setHasActiveSession(bool value) async {
    if (_prefs != null) {
      await _prefs.setBool(_keyHasActiveSession, value);
    } else {
      _inMemory[_keyHasActiveSession] = value;
    }
  }

  String? getActiveProjectId() {
    if (_prefs != null) {
      return _prefs.getString(_keyActiveProjectId);
    }
    return _inMemory[_keyActiveProjectId] as String?;
  }

  Future<void> setActiveProjectId(String? id) async {
    if (_prefs != null) {
      if (id == null) {
        await _prefs.remove(_keyActiveProjectId);
      } else {
        await _prefs.setString(_keyActiveProjectId, id);
      }
    } else {
      if (id == null) {
        _inMemory.remove(_keyActiveProjectId);
      } else {
        _inMemory[_keyActiveProjectId] = id;
      }
    }
  }

  List<ProjectModel> getRecentProjects() {
    List<String>? rawList;
    if (_prefs != null) {
      rawList = _prefs.getStringList(_keyRecentProjects);
    } else {
      rawList = _inMemory[_keyRecentProjects] as List<String>?;
    }

    if (rawList == null || rawList.isEmpty) {
      return [];
    }

    final list = <ProjectModel>[];
    for (final jsonStr in rawList) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        list.add(ProjectModel.fromJson(map));
      } catch (_) {}
    }
    list.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return list;
  }

  Future<void> saveRecentProject(ProjectModel project) async {
    final list = getRecentProjects();
    final index = list.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      list[index] = project;
    } else {
      list.insert(0, project);
    }
    list.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    if (list.length > 25) {
      list.removeRange(25, list.length);
    }

    final rawList = list.map((p) => jsonEncode(p.toJson())).toList();
    if (_prefs != null) {
      await _prefs.setStringList(_keyRecentProjects, rawList);
    } else {
      _inMemory[_keyRecentProjects] = rawList;
    }
  }

  Future<void> deleteRecentProject(String id) async {
    final list = getRecentProjects();
    list.removeWhere((p) => p.id == id);
    final rawList = list.map((p) => jsonEncode(p.toJson())).toList();
    if (_prefs != null) {
      await _prefs.setStringList(_keyRecentProjects, rawList);
    } else {
      _inMemory[_keyRecentProjects] = rawList;
    }
  }

  Future<void> clearRecentProjects() async {
    if (_prefs != null) {
      await _prefs.remove(_keyRecentProjects);
    } else {
      _inMemory.remove(_keyRecentProjects);
    }
  }
}
