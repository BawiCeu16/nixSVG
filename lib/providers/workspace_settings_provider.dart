import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nixsvg/providers/preferences_provider.dart';

class WorkspaceSettingsState {
  final bool snapToGrid;
  final double gridSpacing;
  final double layersSidebarWidth;
  final double propertiesSidebarWidth;
  final bool? isLayersPanelOpen;
  final bool? isPropertiesPanelOpen;
  final String fileName;

  const WorkspaceSettingsState({
    required this.snapToGrid,
    required this.gridSpacing,
    required this.layersSidebarWidth,
    required this.propertiesSidebarWidth,
    this.isLayersPanelOpen,
    this.isPropertiesPanelOpen,
    this.fileName = 'nix_vector_design',
  });

  WorkspaceSettingsState copyWith({
    bool? snapToGrid,
    double? gridSpacing,
    double? layersSidebarWidth,
    double? propertiesSidebarWidth,
    bool? Function()? isLayersPanelOpen,
    bool? Function()? isPropertiesPanelOpen,
    String? fileName,
  }) {
    return WorkspaceSettingsState(
      snapToGrid: snapToGrid ?? this.snapToGrid,
      gridSpacing: gridSpacing ?? this.gridSpacing,
      layersSidebarWidth: layersSidebarWidth ?? this.layersSidebarWidth,
      propertiesSidebarWidth:
          propertiesSidebarWidth ?? this.propertiesSidebarWidth,
      isLayersPanelOpen: isLayersPanelOpen != null
          ? isLayersPanelOpen()
          : this.isLayersPanelOpen,
      isPropertiesPanelOpen: isPropertiesPanelOpen != null
          ? isPropertiesPanelOpen()
          : this.isPropertiesPanelOpen,
      fileName: fileName ?? this.fileName,
    );
  }
}

class WorkspaceSettingsNotifier extends Notifier<WorkspaceSettingsState> {
  @override
  WorkspaceSettingsState build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return WorkspaceSettingsState(
      snapToGrid: prefs.getSnapToGrid(),
      gridSpacing: prefs.getGridSpacing(),
      layersSidebarWidth: prefs.getLayersSidebarWidth(),
      propertiesSidebarWidth: prefs.getPropertiesSidebarWidth(),
      isLayersPanelOpen: prefs.getShowLayers(),
      isPropertiesPanelOpen: prefs.getShowProperties(),
    );
  }

  void setSnapToGrid(bool value) {
    state = state.copyWith(snapToGrid: value);
    ref.read(preferencesServiceProvider).setSnapToGrid(value);
  }

  void setGridSpacing(double spacing) {
    state = state.copyWith(gridSpacing: spacing);
    ref.read(preferencesServiceProvider).setGridSpacing(spacing);
  }

  void setLayersSidebarWidth(double width) {
    state = state.copyWith(layersSidebarWidth: width);
    ref.read(preferencesServiceProvider).setLayersSidebarWidth(width);
  }

  void setPropertiesSidebarWidth(double width) {
    state = state.copyWith(propertiesSidebarWidth: width);
    ref.read(preferencesServiceProvider).setPropertiesSidebarWidth(width);
  }

  void toggleLayersPanel(bool value) {
    state = state.copyWith(isLayersPanelOpen: () => value);
    ref.read(preferencesServiceProvider).setShowLayers(value);
  }

  void togglePropertiesPanel(bool value) {
    state = state.copyWith(isPropertiesPanelOpen: () => value);
    ref.read(preferencesServiceProvider).setShowProperties(value);
  }

  void setFileName(String name) {
    state = state.copyWith(fileName: name);
  }
}

final workspaceSettingsProvider =
    NotifierProvider<WorkspaceSettingsNotifier, WorkspaceSettingsState>(
      WorkspaceSettingsNotifier.new,
    );
