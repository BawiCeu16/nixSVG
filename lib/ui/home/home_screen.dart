import 'package:cross_file/cross_file.dart';
import 'package:nixsvg/services/file_import_service.dart';
import 'package:nixsvg/services/safe_file_picker.dart';
import 'package:nixsvg/widgets/nix_file_drop_zone.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_buttons/m3e_buttons.dart';
import 'package:nixsvg/controllers/theme_controller.dart';
import 'package:nixsvg/models/project_model.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/providers/project_provider.dart';
import 'package:nixsvg/providers/theme_provider.dart';
import 'package:nixsvg/ui/home/widgets/mini_project_preview.dart';
import 'package:nixsvg/ui/workspace/figma_workspace.dart';
import 'package:nixsvg/widgets/settings_dialog.dart';
import 'package:remixicon/remixicon.dart';

/// Material 3 Expressive startup Home Screen for nixSVG.
/// Shown on startup when no project file is opened recently or when a project was closed.
class HomeScreen extends ConsumerStatefulWidget {
  final ValueChanged<ProjectModel>? onOpenProject;

  const HomeScreen({super.key, this.onOpenProject});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final FocusNode _keyboardFocusNode = FocusNode(debugLabel: 'HomeScreenFocus');

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _handleOpenProject(ProjectModel project) {
    if (widget.onOpenProject != null) {
      widget.onOpenProject!(project);
    } else {
      ref.read(projectsProvider.notifier).openProject(project);
    }
  }

  void _handleCreateNew({
    String? name,
    Size? size,
    List<VectorShape>? shapes,
  }) async {
    final newProject = await ref
        .read(projectsProvider.notifier)
        .createNewProject(name: name, size: size, shapes: shapes);
    _handleOpenProject(newProject);
  }

  Future<void> _handleOpenFile() async {
    try {
      ensureFilePickerInitialized();
      final result = await SafeFilePicker.pickFiles(
        context: context,
        allowedExtensions: FileImportService.supportedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final rawBytes = file.bytes;
        if (rawBytes != null) {
          final imported = await FileImportService.importFileFromBytes(
            fileName: file.name,
            bytes: rawBytes,
          );

          if (imported.isSuccess) {
            if (imported.project != null) {
              _handleOpenProject(imported.project!);
              return;
            }

            if (imported.shapes.isNotEmpty) {
              final cleanName = file.name.replaceAll(
                RegExp(r'\.(svg|json|nixsvg|png|jpg|jpeg|webp|gif)$', caseSensitive: false),
                '',
              );
              Size canvasSize = const Size(1920, 1080);
              if (imported.type == ImportedFileType.image) {
                final img = imported.shapes.first;
                canvasSize = Size(img.rect.width, img.rect.height);
              }

              final project = ProjectModel.createNew(
                name: cleanName.isEmpty ? 'Imported Design' : cleanName,
                size: canvasSize,
                shapes: imported.shapes,
              );
              _handleOpenProject(project);
              return;
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not open file: $e')));
      }
    }
  }

  /// Handles drag-and-drop file import when files are dropped onto the HomeScreen.
  Future<void> _handleFilesDropped(
    List<XFile> files,
    Offset localDropPosition,
  ) async {
    if (files.isEmpty) return;

    try {
      final results = await FileImportService.importDropItems(files);

      for (final result in results) {
        if (!result.isSuccess) continue;

        // If a full project file was dropped, open it
        if (result.project != null) {
          _handleOpenProject(result.project!);
          return;
        }

        // If vector shapes or raster images were dropped, initialize a new project
        if (result.shapes.isNotEmpty) {
          final cleanName = result.fileName.replaceAll(
            RegExp(r'\.(svg|json|nixsvg|png|jpg|jpeg|webp|gif)$', caseSensitive: false),
            '',
          );

          Size projectCanvasSize = const Size(1920, 1080);
          if (result.type == ImportedFileType.image) {
            final imgShape = result.shapes.first;
            projectCanvasSize = Size(imgShape.rect.width, imgShape.rect.height);
          }

          final project = ProjectModel.createNew(
            name: cleanName.isEmpty ? 'Imported Design' : cleanName,
            size: projectCanvasSize,
            shapes: result.shapes,
          );
          _handleOpenProject(project);
          return;
        }
      }
    } catch (e) {
      debugPrint('HomeScreen: Error handling dropped files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open dropped file: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final isCtrlOrMeta =
          HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;
      if (isCtrlOrMeta) {
        if (event.logicalKey == LogicalKeyboardKey.keyN) {
          _handleCreateNew();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyO) {
          _handleOpenFile();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.comma) {
          showAppSettingsDialog(context);
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final themeState = ref.watch(themeProvider);
    final projectsState = ref.watch(projectsProvider);
    final isDark = themeState.isDarkMode;

    final allRecents = projectsState.recentProjects;
    final filteredRecents = _searchQuery.isEmpty
        ? allRecents
        : allRecents
              .where((p) => p.name.toLowerCase().contains(_searchQuery))
              .toList();

    final unclosedProject = projectsState.hasActiveSession
        ? projectsState.activeProject
        : null;

    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: NixFileDropZone(
          onFilesDropped: _handleFilesDropped,
          title: 'Drop files to open or start a new project',
          subtitle:
              'Drop any SVG, PNG, JPG, WEBP, or JSON project file to begin editing',
          child: Column(
          children: [
            // ================= TOP MAC-STYLE HEADER BAR =================
            _buildTopBar(context, colorScheme, textTheme, themeState, isDark),

            // ================= MAIN SCROLLABLE CONTENT =================
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 720;
                  final double horizontalPadding = isCompact ? 16.0 : 36.0;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 24.0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth >= 1920
                              ? 1800
                              : (constraints.maxWidth >= 1440 ? 1400 : 1200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Resume Unclosed Active Session Card (if unclosed file detected)
                            if (unclosedProject != null) ...[
                              _buildResumeBanner(
                                context,
                                colorScheme,
                                textTheme,
                                unclosedProject,
                              ),
                              const SizedBox(height: 28),
                            ],

                            // 2. Quick Start / Templates Grid
                            _buildQuickStartSection(
                              context,
                              colorScheme,
                              textTheme,
                              isCompact,
                            ),
                            const SizedBox(height: 32),

                            // 3. Recent Projects Header & Filter
                            _buildRecentProjectsHeader(
                              context,
                              colorScheme,
                              textTheme,
                              allRecents.length,
                            ),
                            const SizedBox(height: 16),

                            // 4. Recent Projects Grid or Empty State
                            if (filteredRecents.isEmpty)
                              _buildEmptyState(
                                context,
                                colorScheme,
                                textTheme,
                                isSearching: _searchQuery.isNotEmpty,
                              )
                            else
                              _buildRecentProjectsGrid(
                                context,
                                colorScheme,
                                textTheme,
                                filteredRecents,
                                isCompact,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  // --- Top Mac-Style Unified Navigation Bar ---
  Widget _buildTopBar(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    ThemeState themeState,
    bool isDark,
  ) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withValues(
          alpha: isDark ? 0.75 : 0.88,
        ),
      ),
      child: Row(
        children: [
          // NixSVG Logo with Gradient Container
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              RemixIcons.shapes_line,
              color: colorScheme.onPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'nixSVG',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Studio',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Spacer(),

          // Search Box (Desktop / Tablet) using Flutter native SearchBar
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: SizedBox(
                height: 38,
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search projects...',
                  hintStyle: WidgetStatePropertyAll(
                    textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  textStyle: WidgetStatePropertyAll(
                    textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  leading: Icon(
                    RemixIcons.search_line,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          RemixIcons.close_circle_line,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () => _searchController.clear(),
                      ),
                  ],
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(
                    colorScheme.surfaceContainerHigh,
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(19),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                    ),
                  ),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Theme Color Picker Menu
          PopupMenuButton<Color>(
            tooltip:
                'Theme Accent: ${ThemeController.getColorName(themeState.seedColor)}',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide.none,
            ),
            color: colorScheme.surfaceContainerHigh,
            icon: SizedBox(
              width: 24,
              height: 24,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    RemixIcons.palette_line,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: themeState.seedColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surfaceContainerHigh,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            onSelected: (color) {
              ref.read(themeProvider.notifier).setSeedColor(color);
            },
            itemBuilder: (context) {
              return ThemeController.presets.map((preset) {
                final color = preset.color;
                final isSelected =
                    themeState.seedColor.toARGB32() == color.toARGB32();
                return PopupMenuItem<Color>(
                  value: color,
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.onSurface
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        preset.name,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),

          // Dark/Light Theme Mode Toggle
          IconButton(
            tooltip: themeState.isDarkMode
                ? 'Switch to Light Mode'
                : 'Switch to Dark Mode',
            icon: Icon(
              themeState.isDarkMode
                  ? RemixIcons.sun_line
                  : RemixIcons.moon_line,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: () => ref.read(themeProvider.notifier).toggleThemeMode(),
          ),

          // Settings & Preferences
          IconButton(
            tooltip: 'Settings & Preferences (Ctrl+,)',
            icon: Icon(
              RemixIcons.settings_3_line,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: () => showAppSettingsDialog(context),
          ),

          const SizedBox(width: 8),

          // Primary "New Project" Button
          Tooltip(
            message: 'Create New Vector File',
            child: M3EButton.icon(
              onPressed: () => _handleCreateNew(),
              style: M3EButtonStyle.filled,
              size: M3EButtonSize.sm,
              icon: Icon(
                RemixIcons.add_line,
                size: 16,
                color: colorScheme.onPrimary,
              ),
              label: Text(
                'New File',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Resume Unclosed Active Session Card ---
  Widget _buildResumeBanner(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    ProjectModel project,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              RemixIcons.sparkling_line,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Active Session Left Open',
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Unclosed',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${project.name} • ${project.shapes.length} layers • Edited ${_formatTimeAgo(project.lastModified)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          M3EButton(
            onPressed: () =>
                ref.read(projectsProvider.notifier).closeActiveProject(),
            style: M3EButtonStyle.text,
            size: M3EButtonSize.sm,
            child: Text(
              'Dismiss',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          M3EButton.icon(
            onPressed: () => _handleOpenProject(project),
            style: M3EButtonStyle.filled,
            size: M3EButtonSize.sm,
            icon: Icon(
              RemixIcons.play_circle_line,
              size: 16,
              color: colorScheme.onPrimary,
            ),
            label: Text(
              'Resume Project',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Quick Start & Design Presets ---
  Widget _buildQuickStartSection(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isCompact,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Start a New Design',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _buildActionCard(
              context: context,
              icon: RemixIcons.file_add_line,
              iconColor: colorScheme.primary,
              title: 'Blank Canvas',
              subtitle: 'Custom infinite vector canvas',
              onTap: () => _handleCreateNew(name: 'Untitled Design'),
            ),
            _buildActionCard(
              context: context,
              icon: RemixIcons.folder_open_line,
              iconColor: const Color(0xFFF59E0B),
              title: 'Open File...',
              subtitle: 'Import SVG, JSON, or artwork',
              onTap: _handleOpenFile,
            ),
            _buildActionCard(
              context: context,
              icon: RemixIcons.palette_line,
              iconColor: const Color(0xFF10B981),
              title: 'Sample Artwork',
              subtitle: 'Demo cards, star & graphics',
              onTap: () {
                final sample = ProjectModel.sampleProject();
                _handleOpenProject(sample);
              },
            ),
            _buildActionCard(
              context: context,
              icon: RemixIcons.computer_line,
              iconColor: const Color(0xFF38BDF8),
              title: 'HD Artboard',
              subtitle: '1920 × 1080 standard display',
              onTap: () => _handleCreateNew(
                name: 'HD Artboard',
                size: const Size(1920, 1080),
              ),
            ),
            _buildActionCard(
              context: context,
              icon: RemixIcons.apps_line,
              iconColor: const Color(0xFFEC4899),
              title: 'Square / Icon',
              subtitle: '512 × 512 app icon canvas',
              onTap: () => _handleCreateNew(
                name: 'App Icon',
                size: const Size(512, 512),
              ),
            ),
            _buildActionCard(
              context: context,
              icon: RemixIcons.smartphone_line,
              iconColor: const Color(0xFF8B5CF6),
              title: 'Mobile Screen',
              subtitle: '390 × 844 phone screen frame',
              onTap: () => _handleCreateNew(
                name: 'Mobile UI',
                size: const Size(390, 844),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return _HomeScreenActionCard(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
    );
  }

  // --- Recent Projects Header ---
  Widget _buildRecentProjectsHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    int count,
  ) {
    return Row(
      children: [
        Text(
          'Recent Projects',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Spacer(),
        if (count > 0)
          M3EButton.icon(
            onPressed: () {
              ref.read(projectsProvider.notifier).clearRecentProjects();
            },
            style: M3EButtonStyle.text,
            size: M3EButtonSize.sm,
            icon: Icon(
              RemixIcons.delete_bin_line,
              size: 14,
              color: colorScheme.outline,
            ),
            label: Text(
              'Clear Recents',
              style: textTheme.labelMedium?.copyWith(color: colorScheme.outline),
            ),
          ),
      ],
    );
  }

  // --- Recent Projects Grid ---
  Widget _buildRecentProjectsGrid(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    List<ProjectModel> projects,
    bool isCompact,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 260).floor().clamp(1, 8);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.15,
          ),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return _buildProjectCard(context, colorScheme, textTheme, project);
          },
        );
      },
    );
  }

  Widget _buildProjectCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    ProjectModel project,
  ) {
    return _HomeScreenProjectCard(
      project: project,
      onTap: () => _handleOpenProject(project),
      onDuplicate: () =>
          ref.read(projectsProvider.notifier).duplicateProject(project.id),
      onRename: () => _showRenameDialog(context, project),
      onDelete: () =>
          ref.read(projectsProvider.notifier).deleteProject(project.id),
    );
  }

  void _showRenameDialog(BuildContext context, ProjectModel project) {
    final controller = TextEditingController(text: project.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Project Name'),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              ref
                  .read(projectsProvider.notifier)
                  .renameProject(project.id, val.trim());
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          M3EButton(
            onPressed: () => Navigator.pop(ctx),
            style: M3EButtonStyle.text,
            size: M3EButtonSize.sm,
            child: const Text('Cancel'),
          ),
          M3EButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(projectsProvider.notifier)
                    .renameProject(project.id, controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            style: M3EButtonStyle.filled,
            size: M3EButtonSize.sm,
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  // --- Empty State View ---
  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required bool isSearching,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              isSearching ? RemixIcons.search_line : RemixIcons.shapes_line,
              color: colorScheme.onSurfaceVariant,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching
                ? 'No matching projects found'
                : 'No recent projects yet',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearching ? 'Try a different keyword or create a new design.' : 'Create your first vector design or open an SVG file to get started.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          M3EButton.icon(
            onPressed: () => _handleCreateNew(),
            style: M3EButtonStyle.tonal,
            size: M3EButtonSize.sm,
            icon: Icon(
              RemixIcons.add_line,
              size: 16,
              color: colorScheme.primary,
            ),
            label: Text(
              'Create New Design',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

/// Material 3 Expressive Action Card for template presets and quick actions.
class _HomeScreenActionCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeScreenActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_HomeScreenActionCard> createState() => _HomeScreenActionCardState();
}

class _HomeScreenActionCardState extends State<_HomeScreenActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? -3.0 : 0.0, 0),
          width: 184,
          height: 132,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered
                ? colorScheme.surfaceContainerHigh.withValues(
                    alpha: isDark ? 0.85 : 0.95,
                  )
                : colorScheme.surfaceContainerHighest.withValues(
                    alpha: isDark ? 0.35 : 0.45,
                  ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.iconColor.withValues(alpha: 0.25),
                          widget.iconColor.withValues(alpha: 0.10),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(widget.icon, color: widget.iconColor, size: 20),
                  ),
                  AnimatedOpacity(
                    opacity: _isHovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      RemixIcons.arrow_right_s_line,
                      size: 16,
                      color: widget.iconColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.1,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.8,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Material 3 Expressive Project Card with miniature preview and options menu.
class _HomeScreenProjectCard extends StatefulWidget {
  final ProjectModel project;
  final VoidCallback onTap;
  final VoidCallback onDuplicate;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _HomeScreenProjectCard({
    required this.project,
    required this.onTap,
    required this.onDuplicate,
    required this.onRename,
    required this.onDelete,
  });

  @override
  State<_HomeScreenProjectCard> createState() => _HomeScreenProjectCardState();
}

class _HomeScreenProjectCardState extends State<_HomeScreenProjectCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? -2.5 : 0.0, 0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(
              alpha: isDark ? 0.35 : 0.45,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Miniature Vector Preview Area
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer.withValues(
                      alpha: isDark ? 0.5 : 0.3,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: MiniProjectPreview(shapes: widget.project.shapes),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: AnimatedOpacity(
                          opacity: _isHovered ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 150),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surface.withValues(
                                alpha: 0.88,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'OPEN',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Card Footer with Title and Options
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.project.name,
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.project.shapes.length} layers • ${_HomeScreenState._formatTimeAgo(widget.project.lastModified)}',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Project Actions Context Menu
                    PopupMenuButton<String>(
                      tooltip: 'Project Options',
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      color: colorScheme.surfaceContainerHigh,
                      icon: Icon(
                        RemixIcons.more_2_line,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onSelected: (action) {
                        switch (action) {
                          case 'open':
                            widget.onTap();
                            break;
                          case 'duplicate':
                            widget.onDuplicate();
                            break;
                          case 'rename':
                            widget.onRename();
                            break;
                          case 'delete':
                            widget.onDelete();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'open',
                          child: Row(
                            children: [
                              Icon(RemixIcons.external_link_line, size: 16),
                              SizedBox(width: 8),
                              Text('Open'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(RemixIcons.file_copy_line, size: 16),
                              SizedBox(width: 8),
                              Text('Duplicate'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              Icon(RemixIcons.edit_line, size: 16),
                              SizedBox(width: 8),
                              Text('Rename'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                RemixIcons.delete_bin_line,
                                size: 16,
                                color: colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Remove',
                                style: TextStyle(color: colorScheme.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
