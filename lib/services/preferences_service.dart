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

  static const String _keyGridStyle = 'nixsvg_grid_style';
  static const String _keyDefaultCanvasBg = 'nixsvg_default_canvas_bg';
  static const String _keySmartGuides = 'nixsvg_smart_guides';
  static const String _keyInvertZoom = 'nixsvg_invert_zoom';
  static const String _keyDefaultStrokeWidth = 'nixsvg_default_stroke_width';
  static const String _keyDefaultCornerRadius = 'nixsvg_default_corner_radius';
  static const String _keyAutoSwitchToSelect = 'nixsvg_auto_switch_to_select';
  static const String _keySvgPrettyPrint = 'nixsvg_svg_pretty_print';
  static const String _keySvgIncludeXml = 'nixsvg_svg_include_xml';
  static const String _keyExportScale = 'nixsvg_export_scale';
  static const String _keyToolbarPosition = 'nixsvg_toolbar_position';
  static const String _keyOledDark = 'nixsvg_oled_dark';
  static const String _keyUiScale = 'nixsvg_ui_scale';

  // --- Grid Style (dots, lines, crosses) ---
  String getGridStyle() {
    if (_prefs != null) {
      return _prefs.getString(_keyGridStyle) ?? 'dots';
    }
    return (_inMemory[_keyGridStyle] as String?) ?? 'dots';
  }

  Future<void> setGridStyle(String style) async {
    if (_prefs != null) {
      await _prefs.setString(_keyGridStyle, style);
    } else {
      _inMemory[_keyGridStyle] = style;
    }
  }

  // --- Default Canvas Background Color ---
  Color? getDefaultCanvasBgColor() {
    final val = _prefs != null
        ? _prefs.getInt(_keyDefaultCanvasBg)
        : _inMemory[_keyDefaultCanvasBg] as int?;
    return val != null ? Color(val) : null;
  }

  Future<void> setDefaultCanvasBgColor(Color? color) async {
    if (color == null) {
      if (_prefs != null) {
        await _prefs.remove(_keyDefaultCanvasBg);
      } else {
        _inMemory.remove(_keyDefaultCanvasBg);
      }
    } else {
      final val = color.toARGB32();
      if (_prefs != null) {
        await _prefs.setInt(_keyDefaultCanvasBg, val);
      } else {
        _inMemory[_keyDefaultCanvasBg] = val;
      }
    }
  }

  // --- Smart Alignment Guides ---
  bool getSmartGuides() {
    if (_prefs != null) {
      return _prefs.getBool(_keySmartGuides) ?? true;
    }
    return (_inMemory[_keySmartGuides] as bool?) ?? true;
  }

  Future<void> setSmartGuides(bool value) async {
    if (_prefs != null) {
      await _prefs.setBool(_keySmartGuides, value);
    } else {
      _inMemory[_keySmartGuides] = value;
    }
  }

  // --- Invert Wheel Zoom ---
  bool getInvertZoom() {
    if (_prefs != null) {
      return _prefs.getBool(_keyInvertZoom) ?? false;
    }
    return (_inMemory[_keyInvertZoom] as bool?) ?? false;
  }

  Future<void> setInvertZoom(bool value) async {
    if (_prefs != null) {
      await _prefs.setBool(_keyInvertZoom, value);
    } else {
      _inMemory[_keyInvertZoom] = value;
    }
  }

  // --- Default Stroke Width ---
  double getDefaultStrokeWidth() {
    if (_prefs != null) {
      return _prefs.getDouble(_keyDefaultStrokeWidth) ?? 2.0;
    }
    return (_inMemory[_keyDefaultStrokeWidth] as double?) ?? 2.0;
  }

  Future<void> setDefaultStrokeWidth(double width) async {
    if (_prefs != null) {
      await _prefs.setDouble(_keyDefaultStrokeWidth, width);
    } else {
      _inMemory[_keyDefaultStrokeWidth] = width;
    }
  }

  // --- Default Corner Radius ---
  double getDefaultCornerRadius() {
    if (_prefs != null) {
      return _prefs.getDouble(_keyDefaultCornerRadius) ?? 8.0;
    }
    return (_inMemory[_keyDefaultCornerRadius] as double?) ?? 8.0;
  }

  Future<void> setDefaultCornerRadius(double radius) async {
    if (_prefs != null) {
      await _prefs.setDouble(_keyDefaultCornerRadius, radius);
    } else {
      _inMemory[_keyDefaultCornerRadius] = radius;
    }
  }

  // --- Auto Switch to Select after drawing ---
  bool getAutoSwitchToSelect() {
    if (_prefs != null) {
      return _prefs.getBool(_keyAutoSwitchToSelect) ?? false;
    }
    return (_inMemory[_keyAutoSwitchToSelect] as bool?) ?? false;
  }

  Future<void> setAutoSwitchToSelect(bool value) async {
    if (_prefs != null) {
      await _prefs.setBool(_keyAutoSwitchToSelect, value);
    } else {
      _inMemory[_keyAutoSwitchToSelect] = value;
    }
  }

  // --- SVG Pretty Print ---
  bool getSvgPrettyPrint() {
    if (_prefs != null) {
      return _prefs.getBool(_keySvgPrettyPrint) ?? true;
    }
    return (_inMemory[_keySvgPrettyPrint] as bool?) ?? true;
  }

  Future<void> setSvgPrettyPrint(bool value) async {
    if (_prefs != null) {
      await _prefs.setBool(_keySvgPrettyPrint, value);
    } else {
      _inMemory[_keySvgPrettyPrint] = value;
    }
  }

  // --- SVG Include XML Prolog ---
  bool getSvgIncludeXml() {
    if (_prefs != null) {
      return _prefs.getBool(_keySvgIncludeXml) ?? true;
    }
    return (_inMemory[_keySvgIncludeXml] as bool?) ?? true;
  }

  Future<void> setSvgIncludeXml(bool value) async {
    if (_prefs != null) {
      await _prefs.setBool(_keySvgIncludeXml, value);
    } else {
      _inMemory[_keySvgIncludeXml] = value;
    }
  }

  // --- Export Scale ---
  double getExportScale() {
    if (_prefs != null) {
      return _prefs.getDouble(_keyExportScale) ?? 2.0;
    }
    return (_inMemory[_keyExportScale] as double?) ?? 2.0;
  }

  Future<void> setExportScale(double scale) async {
    if (_prefs != null) {
      await _prefs.setDouble(_keyExportScale, scale);
    } else {
      _inMemory[_keyExportScale] = scale;
    }
  }

  // --- Floating Toolbar Position (bottom, top, floating) ---
  String getToolbarPosition() {
    if (_prefs != null) {
      return _prefs.getString(_keyToolbarPosition) ?? 'bottom';
    }
    return (_inMemory[_keyToolbarPosition] as String?) ?? 'bottom';
  }

  Future<void> setToolbarPosition(String pos) async {
    if (_prefs != null) {
      await _prefs.setString(_keyToolbarPosition, pos);
    } else {
      _inMemory[_keyToolbarPosition] = pos;
    }
  }

  // --- OLED Dark Mode ---
  bool getOledDark() {
    if (_prefs != null) {
      return _prefs.getBool(_keyOledDark) ?? false;
    }
    return (_inMemory[_keyOledDark] as bool?) ?? false;
  }

  Future<void> setOledDark(bool value) async {
    if (_prefs != null) {
      await _prefs.setBool(_keyOledDark, value);
    } else {
      _inMemory[_keyOledDark] = value;
    }
  }

  // --- UI Scale ---
  double getUiScale() {
    if (_prefs != null) {
      return _prefs.getDouble(_keyUiScale) ?? 1.0;
    }
    return (_inMemory[_keyUiScale] as double?) ?? 1.0;
  }

  Future<void> setUiScale(double scale) async {
    if (_prefs != null) {
      await _prefs.setDouble(_keyUiScale, scale);
    } else {
      _inMemory[_keyUiScale] = scale;
    }
  }

  // --- Reset All Preferences to Defaults ---
  Future<void> resetAllToDefaults() async {
    await setThemeMode(ThemeMode.dark);
    await setSeedColor(const Color(0xFF6366F1));
    await setSnapToGrid(true);
    await setGridSpacing(40.0);
    await setGridStyle('dots');
    await setDefaultCanvasBgColor(null);
    await setSmartGuides(true);
    await setInvertZoom(false);
    await setLayersSidebarWidth(270.0);
    await setPropertiesSidebarWidth(280.0);
    await setShowLayers(null);
    await setShowProperties(null);
    await setDefaultStrokeWidth(2.0);
    await setDefaultCornerRadius(8.0);
    await setAutoSwitchToSelect(false);
    await setSvgPrettyPrint(true);
    await setSvgIncludeXml(true);
    await setExportScale(2.0);
    await setToolbarPosition('bottom');
    await setOledDark(false);
    await setUiScale(1.0);
  }

  // --- Export / Import Settings ---
  Map<String, dynamic> exportSettingsMap() {
    return {
      'themeMode': getThemeMode().name,
      'seedColor': getSeedColor().toARGB32(),
      'snapToGrid': getSnapToGrid(),
      'gridSpacing': getGridSpacing(),
      'gridStyle': getGridStyle(),
      'smartGuides': getSmartGuides(),
      'invertZoom': getInvertZoom(),
      'layersSidebarWidth': getLayersSidebarWidth(),
      'propertiesSidebarWidth': getPropertiesSidebarWidth(),
      'defaultStrokeWidth': getDefaultStrokeWidth(),
      'defaultCornerRadius': getDefaultCornerRadius(),
      'autoSwitchToSelect': getAutoSwitchToSelect(),
      'svgPrettyPrint': getSvgPrettyPrint(),
      'svgIncludeXml': getSvgIncludeXml(),
      'exportScale': getExportScale(),
      'toolbarPosition': getToolbarPosition(),
      'oledDark': getOledDark(),
      'uiScale': getUiScale(),
    };
  }

  Future<void> importSettingsMap(Map<String, dynamic> map) async {
    if (map['themeMode'] is String) {
      final modeStr = map['themeMode'] as String;
      final mode = ThemeMode.values.firstWhere(
        (m) => m.name == modeStr,
        orElse: () => ThemeMode.dark,
      );
      await setThemeMode(mode);
    }
    if (map['seedColor'] is int) {
      await setSeedColor(Color(map['seedColor'] as int));
    }
    if (map['snapToGrid'] is bool) {
      await setSnapToGrid(map['snapToGrid'] as bool);
    }
    if (map['gridSpacing'] is num) {
      await setGridSpacing((map['gridSpacing'] as num).toDouble());
    }
    if (map['gridStyle'] is String) {
      await setGridStyle(map['gridStyle'] as String);
    }
    if (map['smartGuides'] is bool) {
      await setSmartGuides(map['smartGuides'] as bool);
    }
    if (map['invertZoom'] is bool) {
      await setInvertZoom(map['invertZoom'] as bool);
    }
    if (map['layersSidebarWidth'] is num) {
      await setLayersSidebarWidth(
        (map['layersSidebarWidth'] as num).toDouble(),
      );
    }
    if (map['propertiesSidebarWidth'] is num) {
      await setPropertiesSidebarWidth(
        (map['propertiesSidebarWidth'] as num).toDouble(),
      );
    }
    if (map['defaultStrokeWidth'] is num) {
      await setDefaultStrokeWidth(
        (map['defaultStrokeWidth'] as num).toDouble(),
      );
    }
    if (map['defaultCornerRadius'] is num) {
      await setDefaultCornerRadius(
        (map['defaultCornerRadius'] as num).toDouble(),
      );
    }
    if (map['autoSwitchToSelect'] is bool) {
      await setAutoSwitchToSelect(map['autoSwitchToSelect'] as bool);
    }
    if (map['svgPrettyPrint'] is bool) {
      await setSvgPrettyPrint(map['svgPrettyPrint'] as bool);
    }
    if (map['svgIncludeXml'] is bool) {
      await setSvgIncludeXml(map['svgIncludeXml'] as bool);
    }
    if (map['exportScale'] is num) {
      await setExportScale((map['exportScale'] as num).toDouble());
    }
    if (map['toolbarPosition'] is String) {
      await setToolbarPosition(map['toolbarPosition'] as String);
    }
    if (map['oledDark'] is bool) {
      await setOledDark(map['oledDark'] as bool);
    }
    if (map['uiScale'] is num) {
      await setUiScale((map['uiScale'] as num).toDouble());
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
