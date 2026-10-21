import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nixsvg/providers/preferences_provider.dart';
import 'package:nixsvg/providers/theme_provider.dart';
import 'package:nixsvg/providers/workspace_settings_provider.dart';

/// Immutable model describing all application, canvas, and vector editor settings.
class AppSettingsState {
  final ThemeMode themeMode;
  final Color seedColor;
  final bool oledDark;
  final double uiScale;

  final bool snapToGrid;
  final double gridSpacing;
  final String gridStyle; // 'dots', 'lines', 'crosses'
  final bool smartGuides;
  final bool invertZoom;
  final Color? defaultCanvasBgColor;

  final double layersSidebarWidth;
  final double propertiesSidebarWidth;
  final bool? showLayers;
  final bool? showProperties;
  final String toolbarPosition; // 'bottom', 'top', 'floating'

  final double defaultStrokeWidth;
  final double defaultCornerRadius;
  final bool autoSwitchToSelect;

  final bool svgPrettyPrint;
  final bool svgIncludeXml;
  final double exportScale;

  const AppSettingsState({
    required this.themeMode,
    required this.seedColor,
    required this.oledDark,
    required this.uiScale,
    required this.snapToGrid,
    required this.gridSpacing,
    required this.gridStyle,
    required this.smartGuides,
    required this.invertZoom,
    this.defaultCanvasBgColor,
    required this.layersSidebarWidth,
    required this.propertiesSidebarWidth,
    this.showLayers,
    this.showProperties,
    required this.toolbarPosition,
    required this.defaultStrokeWidth,
    required this.defaultCornerRadius,
    required this.autoSwitchToSelect,
    required this.svgPrettyPrint,
    required this.svgIncludeXml,
    required this.exportScale,
  });

  AppSettingsState copyWith({
    ThemeMode? themeMode,
    Color? seedColor,
    bool? oledDark,
    double? uiScale,
    bool? snapToGrid,
    double? gridSpacing,
    String? gridStyle,
    bool? smartGuides,
    bool? invertZoom,
    Color? Function()? defaultCanvasBgColor,
    double? layersSidebarWidth,
    double? propertiesSidebarWidth,
    bool? Function()? showLayers,
    bool? Function()? showProperties,
    String? toolbarPosition,
    double? defaultStrokeWidth,
    double? defaultCornerRadius,
    bool? autoSwitchToSelect,
    bool? svgPrettyPrint,
    bool? svgIncludeXml,
    double? exportScale,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor ?? this.seedColor,
      oledDark: oledDark ?? this.oledDark,
      uiScale: uiScale ?? this.uiScale,
      snapToGrid: snapToGrid ?? this.snapToGrid,
      gridSpacing: gridSpacing ?? this.gridSpacing,
      gridStyle: gridStyle ?? this.gridStyle,
      smartGuides: smartGuides ?? this.smartGuides,
      invertZoom: invertZoom ?? this.invertZoom,
      defaultCanvasBgColor: defaultCanvasBgColor != null
          ? defaultCanvasBgColor()
          : this.defaultCanvasBgColor,
      layersSidebarWidth: layersSidebarWidth ?? this.layersSidebarWidth,
      propertiesSidebarWidth:
          propertiesSidebarWidth ?? this.propertiesSidebarWidth,
      showLayers: showLayers != null ? showLayers() : this.showLayers,
      showProperties:
          showProperties != null ? showProperties() : this.showProperties,
      toolbarPosition: toolbarPosition ?? this.toolbarPosition,
      defaultStrokeWidth: defaultStrokeWidth ?? this.defaultStrokeWidth,
      defaultCornerRadius: defaultCornerRadius ?? this.defaultCornerRadius,
      autoSwitchToSelect: autoSwitchToSelect ?? this.autoSwitchToSelect,
      svgPrettyPrint: svgPrettyPrint ?? this.svgPrettyPrint,
      svgIncludeXml: svgIncludeXml ?? this.svgIncludeXml,
      exportScale: exportScale ?? this.exportScale,
    );
  }
}

/// Riverpod [Notifier] that coordinates all app-level settings and synchronizes them with [PreferencesService].
class AppSettingsNotifier extends Notifier<AppSettingsState> {
  @override
  AppSettingsState build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return AppSettingsState(
      themeMode: prefs.getThemeMode(),
      seedColor: prefs.getSeedColor(),
      oledDark: prefs.getOledDark(),
      uiScale: prefs.getUiScale(),
      snapToGrid: prefs.getSnapToGrid(),
      gridSpacing: prefs.getGridSpacing(),
      gridStyle: prefs.getGridStyle(),
      smartGuides: prefs.getSmartGuides(),
      invertZoom: prefs.getInvertZoom(),
      defaultCanvasBgColor: prefs.getDefaultCanvasBgColor(),
      layersSidebarWidth: prefs.getLayersSidebarWidth(),
      propertiesSidebarWidth: prefs.getPropertiesSidebarWidth(),
      showLayers: prefs.getShowLayers(),
      showProperties: prefs.getShowProperties(),
      toolbarPosition: prefs.getToolbarPosition(),
      defaultStrokeWidth: prefs.getDefaultStrokeWidth(),
      defaultCornerRadius: prefs.getDefaultCornerRadius(),
      autoSwitchToSelect: prefs.getAutoSwitchToSelect(),
      svgPrettyPrint: prefs.getSvgPrettyPrint(),
      svgIncludeXml: prefs.getSvgIncludeXml(),
      exportScale: prefs.getExportScale(),
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    ref.read(preferencesServiceProvider).setThemeMode(mode);
    ref.read(themeProvider.notifier).setThemeMode(mode);
  }

  void setSeedColor(Color color) {
    state = state.copyWith(seedColor: color);
    ref.read(preferencesServiceProvider).setSeedColor(color);
    ref.read(themeProvider.notifier).setSeedColor(color);
  }

  void setOledDark(bool value) {
    state = state.copyWith(oledDark: value);
    ref.read(preferencesServiceProvider).setOledDark(value);
  }

  void setUiScale(double scale) {
    state = state.copyWith(uiScale: scale);
    ref.read(preferencesServiceProvider).setUiScale(scale);
  }

  void setSnapToGrid(bool value) {
    state = state.copyWith(snapToGrid: value);
    ref.read(preferencesServiceProvider).setSnapToGrid(value);
    ref.read(workspaceSettingsProvider.notifier).setSnapToGrid(value);
  }

  void setGridSpacing(double spacing) {
    state = state.copyWith(gridSpacing: spacing);
    ref.read(preferencesServiceProvider).setGridSpacing(spacing);
    ref.read(workspaceSettingsProvider.notifier).setGridSpacing(spacing);
  }

  void setGridStyle(String style) {
    state = state.copyWith(gridStyle: style);
    ref.read(preferencesServiceProvider).setGridStyle(style);
  }

  void setSmartGuides(bool value) {
    state = state.copyWith(smartGuides: value);
    ref.read(preferencesServiceProvider).setSmartGuides(value);
  }

  void setInvertZoom(bool value) {
    state = state.copyWith(invertZoom: value);
    ref.read(preferencesServiceProvider).setInvertZoom(value);
  }

  void setDefaultCanvasBgColor(Color? color) {
    state = state.copyWith(defaultCanvasBgColor: () => color);
    ref.read(preferencesServiceProvider).setDefaultCanvasBgColor(color);
  }

  void setLayersSidebarWidth(double width) {
    state = state.copyWith(layersSidebarWidth: width);
    ref.read(preferencesServiceProvider).setLayersSidebarWidth(width);
    ref.read(workspaceSettingsProvider.notifier).setLayersSidebarWidth(width);
  }

  void setPropertiesSidebarWidth(double width) {
    state = state.copyWith(propertiesSidebarWidth: width);
    ref.read(preferencesServiceProvider).setPropertiesSidebarWidth(width);
    ref
        .read(workspaceSettingsProvider.notifier)
        .setPropertiesSidebarWidth(width);
  }

  void setShowLayers(bool? show) {
    state = state.copyWith(showLayers: () => show);
    ref.read(preferencesServiceProvider).setShowLayers(show);
    if (show != null) {
      ref.read(workspaceSettingsProvider.notifier).toggleLayersPanel(show);
    }
  }

  void setShowProperties(bool? show) {
    state = state.copyWith(showProperties: () => show);
    ref.read(preferencesServiceProvider).setShowProperties(show);
    if (show != null) {
      ref.read(workspaceSettingsProvider.notifier).togglePropertiesPanel(show);
    }
  }

  void setToolbarPosition(String pos) {
    state = state.copyWith(toolbarPosition: pos);
    ref.read(preferencesServiceProvider).setToolbarPosition(pos);
  }

  void setDefaultStrokeWidth(double width) {
    state = state.copyWith(defaultStrokeWidth: width);
    ref.read(preferencesServiceProvider).setDefaultStrokeWidth(width);
  }

  void setDefaultCornerRadius(double radius) {
    state = state.copyWith(defaultCornerRadius: radius);
    ref.read(preferencesServiceProvider).setDefaultCornerRadius(radius);
  }

  void setAutoSwitchToSelect(bool value) {
    state = state.copyWith(autoSwitchToSelect: value);
    ref.read(preferencesServiceProvider).setAutoSwitchToSelect(value);
  }

  void setSvgPrettyPrint(bool value) {
    state = state.copyWith(svgPrettyPrint: value);
    ref.read(preferencesServiceProvider).setSvgPrettyPrint(value);
  }

  void setSvgIncludeXml(bool value) {
    state = state.copyWith(svgIncludeXml: value);
    ref.read(preferencesServiceProvider).setSvgIncludeXml(value);
  }

  void setExportScale(double scale) {
    state = state.copyWith(exportScale: scale);
    ref.read(preferencesServiceProvider).setExportScale(scale);
  }

  Future<void> resetAllToDefaults() async {
    await ref.read(preferencesServiceProvider).resetAllToDefaults();
    ref.invalidateSelf();
    ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
    ref.read(themeProvider.notifier).setSeedColor(const Color(0xFF6366F1));
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettingsState>(
      AppSettingsNotifier.new,
    );
