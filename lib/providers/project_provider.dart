import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nixsvg/models/project_model.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/providers/preferences_provider.dart';

/// State of all project management in nixSVG including recent projects list
/// and currently active design project.
class ProjectsState {
  final List<ProjectModel> recentProjects;
  final ProjectModel? activeProject;
  final bool hasActiveSession;

  const ProjectsState({
    required this.recentProjects,
    this.activeProject,
    required this.hasActiveSession,
  });

  ProjectsState copyWith({
    List<ProjectModel>? recentProjects,
    ProjectModel? activeProject,
    bool clearActiveProject = false,
    bool? hasActiveSession,
  }) {
    return ProjectsState(
      recentProjects: recentProjects ?? this.recentProjects,
      activeProject:
          clearActiveProject ? null : (activeProject ?? this.activeProject),
      hasActiveSession: hasActiveSession ?? this.hasActiveSession,
    );
  }
}

class ProjectsNotifier extends Notifier<ProjectsState> {
  @override
  ProjectsState build() {
    final prefs = ref.watch(preferencesServiceProvider);
    final recents = prefs.getRecentProjects();
    final hasActive = prefs.getHasActiveSession();
    final activeId = prefs.getActiveProjectId();

    ProjectModel? active;
    if (hasActive && activeId != null) {
      active = recents.cast<ProjectModel?>().firstWhere(
            (p) => p?.id == activeId,
            orElse: () => null,
          );
    }

    return ProjectsState(
      recentProjects: recents,
      activeProject: active,
      hasActiveSession: hasActive,
    );
  }

  /// Opens an existing project or sample artwork.
  Future<void> openProject(ProjectModel project) async {
    final prefs = ref.read(preferencesServiceProvider);
    final updated = project.copyWith(lastModified: DateTime.now());
    await prefs.saveRecentProject(updated);
    await prefs.setActiveProjectId(updated.id);
    await prefs.setHasActiveSession(true);

    state = state.copyWith(
      recentProjects: prefs.getRecentProjects(),
      activeProject: updated,
      hasActiveSession: true,
    );
  }

  /// Creates and opens a new design canvas.
  Future<ProjectModel> createNewProject({
    String? name,
    Size? size,
    List<VectorShape>? shapes,
  }) async {
    final newProject = ProjectModel.createNew(
      name: name,
      size: size,
      shapes: shapes,
    );
    await openProject(newProject);
    return newProject;
  }

  /// Updates and persists changes to the current active project.
  Future<void> updateActiveProject(ProjectModel updated) async {
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.saveRecentProject(updated);
    state = state.copyWith(
      recentProjects: prefs.getRecentProjects(),
      activeProject: updated,
    );
  }

  /// Closes the active project and returns to the Home Screen.
  Future<void> closeActiveProject() async {
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setActiveProjectId(null);
    await prefs.setHasActiveSession(false);

    state = state.copyWith(
      clearActiveProject: true,
      hasActiveSession: false,
    );
  }

  /// Duplicates a project in recent projects list.
  Future<void> duplicateProject(String id) async {
    final target = state.recentProjects.cast<ProjectModel?>().firstWhere(
          (p) => p?.id == id,
          orElse: () => null,
        );
    if (target == null) return;

    final copy = target.copyWith(
      id: 'proj-${DateTime.now().millisecondsSinceEpoch}',
      name: '${target.name} Copy',
      lastModified: DateTime.now(),
      createdAt: DateTime.now(),
    );
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.saveRecentProject(copy);
    state = state.copyWith(recentProjects: prefs.getRecentProjects());
  }

  /// Renames a recent project.
  Future<void> renameProject(String id, String newName) async {
    final target = state.recentProjects.cast<ProjectModel?>().firstWhere(
          (p) => p?.id == id,
          orElse: () => null,
        );
    if (target == null) return;

    final updated = target.copyWith(
      name: newName,
      lastModified: DateTime.now(),
    );
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.saveRecentProject(updated);

    ProjectModel? updatedActive = state.activeProject;
    if (state.activeProject?.id == id) {
      updatedActive = updated;
    }

    state = state.copyWith(
      recentProjects: prefs.getRecentProjects(),
      activeProject: updatedActive,
    );
  }

  /// Deletes a project from recents.
  Future<void> deleteProject(String id) async {
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.deleteRecentProject(id);
    final isDeletingActive = state.activeProject?.id == id;
    if (isDeletingActive) {
      await prefs.setActiveProjectId(null);
      await prefs.setHasActiveSession(false);
    }
    state = state.copyWith(
      recentProjects: prefs.getRecentProjects(),
      clearActiveProject: isDeletingActive,
      hasActiveSession: isDeletingActive ? false : state.hasActiveSession,
    );
  }

  /// Clears all recent projects from storage and state.
  Future<void> clearRecentProjects() async {
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.clearRecentProjects();
    state = state.copyWith(recentProjects: []);
  }
}

final projectsProvider =
    NotifierProvider<ProjectsNotifier, ProjectsState>(ProjectsNotifier.new);
