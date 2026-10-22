import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_buttons/m3e_buttons.dart';
import 'package:m3e_card_list/m3e_card_list.dart';
import 'package:nixsvg/providers/app_settings_provider.dart';
import 'package:nixsvg/providers/project_provider.dart';
import 'package:nixsvg/theme/physics/m3e_physics_spring.dart';
import 'package:nixsvg/widgets/color_picker/nix_color_picker_presenter.dart';
import 'package:nixsvg/widgets/nix_slider.dart';
import 'package:remixicon/remixicon.dart';

/// Unified Material 3 Expressive Switch for nixSVG Studio settings and controls.
/// Features expressive thumb icons (check / close), color harmonization with M3 tokens,
/// and light haptic feedback on state toggling.
class M3ESwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? tooltip;

  const M3ESwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final switchWidget = Switch(
      value: value,
      onChanged: onChanged != null
          ? (val) {
              HapticFeedback.lightImpact();
              onChanged!(val);
            }
          : null,
      thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
        if (states.contains(WidgetState.selected)) {
          return Icon(
            RemixIcons.check_line,
            size: 14,
            color: colorScheme.onPrimary,
          );
        }
        return Icon(
          RemixIcons.close_line,
          size: 14,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        );
      }),
      activeTrackColor: colorScheme.primary,
      activeThumbColor: colorScheme.onPrimary,
      inactiveThumbColor: colorScheme.outline,
      inactiveTrackColor: colorScheme.surfaceContainerHighest,
      trackOutlineColor: WidgetStateProperty.resolveWith<Color?>(
        (states) => states.contains(WidgetState.selected)
            ? Colors.transparent
            : colorScheme.outline.withValues(alpha: 0.4),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: switchWidget);
    }
    return switchWidget;
  }
}

/// Shows the adaptive full-screen Material 3 Expressive Settings & Preferences Dialog.
Future<void> showAppSettingsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    useSafeArea: false,
    barrierDismissible: true,
    builder: (ctx) => const SettingsDialog(),
  );
}

/// Category tabs for application settings
enum SettingsCategory {
  appearance('Appearance', RemixIcons.palette_line),
  canvas('Canvas & Grid', RemixIcons.grid_line),
  workspace('Panels & Workspace', RemixIcons.layout_masonry_line),
  vectorTools('Vector Tools', RemixIcons.shape_line),
  exportFormat('Export & Formats', RemixIcons.download_2_line),
  storage('Projects & Storage', RemixIcons.hard_drive_2_line),
  about('About nixSVG', RemixIcons.information_line);

  final String label;
  final IconData icon;
  const SettingsCategory(this.label, this.icon);
}

/// Adaptive Full-Screen Settings Dialog with authentic macOS & Material 3 Expressive styling,
/// responsive two-pane navigation, real-time search filter, and comprehensive app settings.
class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  SettingsCategory _selectedCategory = SettingsCategory.appearance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final FocusNode _focusNode = FocusNode();

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
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
        }
      },
      child: Dialog.fullscreen(
        backgroundColor: colorScheme.surface,
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;
                final isCompact = constraints.maxWidth < 600;
                return Column(
                  children: [
                    // Unified Glassmorphic Header Bar
                    _buildHeader(
                      context,
                      colorScheme,
                      isDark,
                      notifier,
                      isWide,
                      isCompact,
                    ),

                    // Main Workbench Content (Responsive 2-pane on wide screens)
                    Expanded(
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Left Category Navigation Sidebar
                                SizedBox(
                                  width: 260,
                                  child: _buildNavigationSidebar(
                                    context,
                                    colorScheme,
                                    isDark,
                                  ),
                                ),
                                // Vertical Divider
                                VerticalDivider(
                                  width: 1,
                                  thickness: 1,
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                                // Right Scrollable Settings Body
                                Expanded(
                                  child: _buildSettingsBody(
                                    context,
                                    colorScheme,
                                    settings,
                                    notifier,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _buildCompactCategoryTabs(context, colorScheme),
                                const Divider(height: 1),
                                Expanded(
                                  child: _buildSettingsBody(
                                    context,
                                    colorScheme,
                                    settings,
                                    notifier,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Header with Search and Actions
  // --------------------------------------------------------------------------

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
    AppSettingsNotifier notifier,
    bool isWide,
    bool isCompact,
  ) {
    final theme = Theme.of(context);
    return Container(
      height: 46,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withValues(
          alpha: isDark ? 0.75 : 0.88,
        ),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Material 3 Expressive Close Button with physics spring feedback
          M3PhysicsPressable(
            tooltip: 'Close Settings (Esc)',
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: EdgeInsets.all(isCompact ? 4 : 5),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  width: 1.0,
                ),
              ),
              child: Icon(
                RemixIcons.close_line,
                size: isCompact ? 14 : 16,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(width: isCompact ? 6 : 10),

          // Title with app badge
          if (!isCompact) ...[
            Text(
              'Settings & Preferences',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.2),
            ),
            const SizedBox(width: 14),
            const Spacer(),
          ] else ...[
            Text(
              'Settings',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
          ],

          // Search Field using Flutter native SearchBar
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isCompact ? 180 : 420),
              child: SizedBox(
                height: 30,
                child: SearchBar(
                  controller: _searchController,
                  hintText: isCompact
                      ? 'Search...'
                      : 'Search settings, canvas, shortcuts...',
                  hintStyle: WidgetStatePropertyAll(
                    Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                  textStyle: WidgetStatePropertyAll(
                    Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurface),
                  ),
                  leading: Icon(
                    RemixIcons.search_line,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  trailing: [
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          RemixIcons.close_circle_line,
                          size: 14,
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
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.35,
                        ),
                        width: 1.0,
                      ),
                    ),
                  ),
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: isCompact ? 6 : 10),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(width: isCompact ? 6 : 16),

          // Reset Defaults Button
          if (!isCompact)
            M3EButton.icon(
              onPressed: () => _confirmResetDefaults(context, notifier),
              style: M3EButtonStyle.text,
              size: M3EButtonSize.sm,
              icon: Icon(
                RemixIcons.restart_line,
                size: 15,
                color: colorScheme.error,
              ),
              label: Text(
                'Reset Defaults',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Reset Defaults',
              icon: Icon(
                RemixIcons.restart_line,
                size: 16,
                color: colorScheme.error,
              ),
              onPressed: () => _confirmResetDefaults(context, notifier),
            ),
          SizedBox(width: isCompact ? 4 : 8),

          // Done Button
          M3EButton(
            onPressed: () => Navigator.of(context).pop(),
            style: M3EButtonStyle.filled,
            size: M3EButtonSize.sm,
            child: const Text(
              'Done',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Left Sidebar Category Navigation (Desktop / Wide)
  // --------------------------------------------------------------------------

  Widget _buildNavigationSidebar(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    return Container(
      color: colorScheme.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: SettingsCategory.values.map((cat) {
                final isSelected =
                    _selectedCategory == cat && _searchQuery.isEmpty;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                        if (_searchQuery.isNotEmpty) {
                          _searchController.clear();
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primaryContainer.withValues(
                                alpha: isDark ? 0.35 : 0.6,
                              )
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.3)
                              : Colors.transparent,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            cat.icon,
                            size: 16,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cat.label,
                              style: isSelected
                                  ? theme.textTheme.labelLarge?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    )
                                  : theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Compact Category Tabs (Mobile / Narrow)
  // --------------------------------------------------------------------------

  Widget _buildCompactCategoryTabs(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    final theme = Theme.of(context);
    return Container(
      height: 48,
      color: colorScheme.surfaceContainerLowest,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: SettingsCategory.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = SettingsCategory.values[i];
          final isSelected = _selectedCategory == cat && _searchQuery.isEmpty;
          return ChoiceChip(
            selected: isSelected,
            showCheckmark: false,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(cat.icon, size: 14),
                const SizedBox(width: 6),
                Text(cat.label, style: theme.textTheme.labelMedium),
              ],
            ),
            onSelected: (val) {
              if (val) {
                setState(() {
                  _selectedCategory = cat;
                  if (_searchQuery.isNotEmpty) _searchController.clear();
                });
              }
            },
          );
        },
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Settings Body Content
  // --------------------------------------------------------------------------

  Widget _buildSettingsBody(
    BuildContext context,
    ColorScheme colorScheme,
    AppSettingsState settings,
    AppSettingsNotifier notifier,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_searchQuery.isNotEmpty) ...[
                Text(
                  'Search Results for "$_searchQuery"',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ..._buildSearchResults(
                  context,
                  colorScheme,
                  settings,
                  notifier,
                ),
              ] else ...[
                switch (_selectedCategory) {
                  SettingsCategory.appearance => _buildAppearanceSection(
                    context,
                    colorScheme,
                    settings,
                    notifier,
                  ),
                  SettingsCategory.canvas => _buildCanvasSection(
                    context,
                    colorScheme,
                    settings,
                    notifier,
                  ),
                  SettingsCategory.workspace => _buildWorkspaceSection(
                    context,
                    colorScheme,
                    settings,
                    notifier,
                  ),
                  SettingsCategory.vectorTools => _buildVectorToolsSection(
                    context,
                    colorScheme,
                    settings,
                    notifier,
                  ),
                  SettingsCategory.exportFormat => _buildExportSection(
                    context,
                    colorScheme,
                    settings,
                    notifier,
                  ),
                  SettingsCategory.storage => _buildStorageSection(
                    context,
                    colorScheme,
                    settings,
                    notifier,
                  ),
                  SettingsCategory.about => _buildAboutSection(
                    context,
                    colorScheme,
                  ),
                },
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Section 1: Appearance & Theme
  // --------------------------------------------------------------------------

  Widget _buildAppearanceSection(
    BuildContext context,
    ColorScheme colorScheme,
    AppSettingsState settings,
    AppSettingsNotifier notifier,
  ) {
    final seedColors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF10B981), // Emerald
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEC4899), // Pink
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFF43F5E), // Rose
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Appearance & Styling',
          'Configure theme mode, dynamic seed colors, and visual contrast',
        ),
        const SizedBox(height: 16),

        _buildCard(
          colorScheme,
          children: [
            // Theme Mode Selector
            _buildSettingRow(
              icon: RemixIcons.contrast_line,
              colorScheme: colorScheme,
              title: 'Theme Mode',
              subtitle: 'Select between Light mode, Dark mode, or follow Operating System settings',
              trailing: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(RemixIcons.sun_line, size: 15),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(RemixIcons.moon_line, size: 15),
                    label: Text('Dark'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(RemixIcons.computer_line, size: 15),
                    label: Text('System'),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (set) => notifier.setThemeMode(set.first),
              ),
            ),
            const Divider(height: 1),

            // Seed Accent Color Palette
            _buildSettingRow(
              icon: RemixIcons.palette_line,
              colorScheme: colorScheme,
              title: 'Dynamic Accent Color',
              subtitle: 'Material 3 Expressive color harmonization seed for active highlights',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...seedColors.map((col) {
                    final isSelected =
                        col.toARGB32() == settings.seedColor.toARGB32();
                    return GestureDetector(
                      onTap: () => notifier.setSeedColor(col),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: col,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: 2.2,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: col.withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  // Custom Color Picker button
                  IconButton.filledTonal(
                    onPressed: () {
                      showNixColorPicker(
                        context: context,
                        initialColor: settings.seedColor,
                        title: 'Select Accent Color',
                        onColorChanged: (c) => notifier.setSeedColor(c),
                      );
                    },
                    icon: const Icon(RemixIcons.add_line, size: 16),
                    tooltip: 'Custom Color',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // OLED Pure Black Mode
            _buildSettingRow(
              icon: RemixIcons.flashlight_line,
              colorScheme: colorScheme,
              title: 'OLED High Contrast',
              subtitle: 'Uses ultra-deep pitch black backgrounds for maximum contrast and battery efficiency',
              trailing: M3ESwitch(
                value: settings.oledDark,
                onChanged: notifier.setOledDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Section 2: Canvas & Grid
  // --------------------------------------------------------------------------

  Widget _buildCanvasSection(
    BuildContext context,
    ColorScheme colorScheme,
    AppSettingsState settings,
    AppSettingsNotifier notifier,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Canvas & Grid Settings',
          'Precision snapping, guideline overlays, grid style, and zoom behavior',
        ),
        const SizedBox(height: 16),

        _buildCard(
          colorScheme,
          children: [
            // Snap to Grid
            _buildSettingRow(
              icon: RemixIcons.focus_3_line,
              colorScheme: colorScheme,
              title: 'Snap to Grid',
              subtitle: 'Automatically aligns vector anchor points and shapes to the nearest grid step',
              trailing: M3ESwitch(
                value: settings.snapToGrid,
                onChanged: notifier.setSnapToGrid,
              ),
            ),
            const Divider(height: 1),

            // Grid Style Selector
            _buildSettingRow(
              icon: RemixIcons.grid_fill,
              colorScheme: colorScheme,
              title: 'Grid Style',
              subtitle: 'Render canvas guidelines as precision dot matrix or continuous grid lines',
              trailing: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'dots',
                    icon: Icon(RemixIcons.checkbox_blank_circle_line, size: 14),
                    label: Text('Dots'),
                  ),
                  ButtonSegment(
                    value: 'lines',
                    icon: Icon(RemixIcons.grid_line, size: 14),
                    label: Text('Lines'),
                  ),
                ],
                selected: {settings.gridStyle},
                onSelectionChanged: (set) => notifier.setGridStyle(set.first),
              ),
            ),
            const Divider(height: 1),

            // Grid Spacing Slider
            _buildSettingRow(
              icon: RemixIcons.ruler_line,
              colorScheme: colorScheme,
              title: 'Grid Step Spacing',
              subtitle:
                  'Distance in logical pixels between grid points (${settings.gridSpacing.toInt()} px)',
              trailing: SizedBox(
                width: 230,
                child: Row(
                  children: [
                    Expanded(
                      child: NixSlider(
                        value: settings.gridSpacing,
                        min: 10,
                        max: 100,
                        divisions: 18,
                        onChanged: notifier.setGridSpacing,
                      ),
                    ),
                    SizedBox(
                      width: 46,
                      child: Text(
                        '${settings.gridSpacing.toInt()}px',
                        textAlign: TextAlign.end,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // Smart Alignment Guidelines
            _buildSettingRow(
              icon: RemixIcons.guide_line,
              colorScheme: colorScheme,
              title: 'Smart Alignment Guides',
              subtitle: 'Shows magenta dynamic alignment guidelines when snapping to neighboring shapes',
              trailing: M3ESwitch(
                value: settings.smartGuides,
                onChanged: notifier.setSmartGuides,
              ),
            ),
            const Divider(height: 1),

            // Invert Zoom Direction
            _buildSettingRow(
              icon: RemixIcons.zoom_in_line,
              colorScheme: colorScheme,
              title: 'Invert Mouse Wheel Zoom',
              subtitle: 'Reverse the scroll wheel zoom direction to match standard trackpad pinch',
              trailing: M3ESwitch(
                value: settings.invertZoom,
                onChanged: notifier.setInvertZoom,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Section 3: Panels & Workspace Layout
  // --------------------------------------------------------------------------

  Widget _buildWorkspaceSection(
    BuildContext context,
    ColorScheme colorScheme,
    AppSettingsState settings,
    AppSettingsNotifier notifier,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Panels & Layout',
          'Default sidebar widths, panel toggles, and floating toolbar placement',
        ),
        const SizedBox(height: 16),

        _buildCard(
          colorScheme,
          children: [
            // Layers Sidebar Width
            _buildSettingRow(
              icon: RemixIcons.stack_line,
              colorScheme: colorScheme,
              title: 'Layers Sidebar Width',
              subtitle:
                  'Default dock width for the left layers hierarchy tree (${settings.layersSidebarWidth.toInt()} px)',
              trailing: SizedBox(
                width: 230,
                child: Row(
                  children: [
                    Expanded(
                      child: NixSlider(
                        value: settings.layersSidebarWidth,
                        min: 180,
                        max: 380,
                        divisions: 20,
                        onChanged: notifier.setLayersSidebarWidth,
                      ),
                    ),
                    SizedBox(
                      width: 46,
                      child: Text(
                        '${settings.layersSidebarWidth.toInt()}px',
                        textAlign: TextAlign.end,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // Properties Sidebar Width
            _buildSettingRow(
              icon: RemixIcons.equalizer_line,
              colorScheme: colorScheme,
              title: 'Properties Inspector Width',
              subtitle:
                  'Default dock width for the right property inspector panel (${settings.propertiesSidebarWidth.toInt()} px)',
              trailing: SizedBox(
                width: 230,
                child: Row(
                  children: [
                    Expanded(
                      child: NixSlider(
                        value: settings.propertiesSidebarWidth,
                        min: 200,
                        max: 420,
                        divisions: 22,
                        onChanged: notifier.setPropertiesSidebarWidth,
                      ),
                    ),
                    SizedBox(
                      width: 46,
                      child: Text(
                        '${settings.propertiesSidebarWidth.toInt()}px',
                        textAlign: TextAlign.end,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // Floating Toolbar Position
            _buildSettingRow(
              icon: RemixIcons.layout_bottom_line,
              colorScheme: colorScheme,
              title: 'Floating Toolbar Position',
              subtitle: 'Docking anchor for the main shape and vector creation toolbar',
              trailing: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'bottom',
                    icon: Icon(RemixIcons.layout_bottom_line, size: 14),
                    label: Text('Bottom'),
                  ),
                  ButtonSegment(
                    value: 'top',
                    icon: Icon(RemixIcons.layout_top_line, size: 14),
                    label: Text('Top'),
                  ),
                ],
                selected: {settings.toolbarPosition},
                onSelectionChanged: (set) =>
                    notifier.setToolbarPosition(set.first),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Section 4: Vector Tools
  // --------------------------------------------------------------------------

  Widget _buildVectorToolsSection(
    BuildContext context,
    ColorScheme colorScheme,
    AppSettingsState settings,
    AppSettingsNotifier notifier,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Vector Tools & Editing Experience',
          'Defaults for newly created shapes, stroke widths, and tool switching',
        ),
        const SizedBox(height: 16),

        _buildCard(
          colorScheme,
          children: [
            // Default Stroke Width
            _buildSettingRow(
              icon: RemixIcons.pencil_ruler_2_line,
              colorScheme: colorScheme,
              title: 'Default Stroke Width',
              subtitle:
                  'Initial outline thickness assigned to newly drawn paths and shapes (${settings.defaultStrokeWidth.toStringAsFixed(1)} px)',
              trailing: SizedBox(
                width: 230,
                child: Row(
                  children: [
                    Expanded(
                      child: NixSlider(
                        value: settings.defaultStrokeWidth,
                        min: 0.5,
                        max: 12.0,
                        divisions: 23,
                        onChanged: notifier.setDefaultStrokeWidth,
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '${settings.defaultStrokeWidth.toStringAsFixed(1)}px',
                        textAlign: TextAlign.end,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // Default Corner Radius
            _buildSettingRow(
              icon: RemixIcons.shape_line,
              colorScheme: colorScheme,
              title: 'Default Corner Radius',
              subtitle:
                  'Initial rounded border curvature applied to new rounded rectangles (${settings.defaultCornerRadius.toInt()} px)',
              trailing: SizedBox(
                width: 230,
                child: Row(
                  children: [
                    Expanded(
                      child: NixSlider(
                        value: settings.defaultCornerRadius,
                        min: 0,
                        max: 32,
                        divisions: 16,
                        onChanged: notifier.setDefaultCornerRadius,
                      ),
                    ),
                    SizedBox(
                      width: 46,
                      child: Text(
                        '${settings.defaultCornerRadius.toInt()}px',
                        textAlign: TextAlign.end,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // Auto switch to select tool
            _buildSettingRow(
              icon: RemixIcons.cursor_line,
              colorScheme: colorScheme,
              title: 'Auto-Switch to Select Tool',
              subtitle: 'Automatically revert to the pointer selection tool after finishing drawing a shape',
              trailing: M3ESwitch(
                value: settings.autoSwitchToSelect,
                onChanged: notifier.setAutoSwitchToSelect,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Section 5: Export & File Formats
  // --------------------------------------------------------------------------

  Widget _buildExportSection(
    BuildContext context,
    ColorScheme colorScheme,
    AppSettingsState settings,
    AppSettingsNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Export & Formats',
          'SVG formatting indentation, XML metadata, and default export resolutions',
        ),
        const SizedBox(height: 16),

        _buildCard(
          colorScheme,
          children: [
            // SVG Pretty Print
            _buildSettingRow(
              icon: RemixIcons.code_s_slash_line,
              colorScheme: colorScheme,
              title: 'SVG Pretty-Printing',
              subtitle: 'Format exported SVG source with clean 2-space indentation and line breaks for readability',
              trailing: M3ESwitch(
                value: settings.svgPrettyPrint,
                onChanged: notifier.setSvgPrettyPrint,
              ),
            ),
            const Divider(height: 1),

            // XML Prologue
            _buildSettingRow(
              icon: RemixIcons.file_code_line,
              colorScheme: colorScheme,
              title: 'Include XML Prolog Header',
              subtitle: 'Prepend standard <?xml version="1.0" encoding="UTF-8"?> header to SVG documents',
              trailing: M3ESwitch(
                value: settings.svgIncludeXml,
                onChanged: notifier.setSvgIncludeXml,
              ),
            ),
            const Divider(height: 1),

            // Default Export Scale
            _buildSettingRow(
              icon: RemixIcons.aspect_ratio_line,
              colorScheme: colorScheme,
              title: 'Default Raster Scale Multiplier',
              subtitle:
                  'Pixel density multiplier for PNG/raster snapshots (${settings.exportScale.toInt()}x Retina)',
              trailing: SegmentedButton<double>(
                segments: const [
                  ButtonSegment(
                    value: 1.0,
                    label: Text('1x'),
                  ),
                  ButtonSegment(
                    value: 2.0,
                    label: Text('2x'),
                  ),
                  ButtonSegment(
                    value: 3.0,
                    label: Text('3x'),
                  ),
                ],
                selected: {settings.exportScale},
                onSelectionChanged: (set) => notifier.setExportScale(set.first),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Section 6: Projects & Storage
  // --------------------------------------------------------------------------

  Widget _buildStorageSection(
    BuildContext context,
    ColorScheme colorScheme,
    AppSettingsState settings,
    AppSettingsNotifier notifier,
  ) {
    final projectsState = ref.watch(projectsProvider);
    final count = projectsState.recentProjects.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Projects & Storage',
          'Manage local cache, project history, and full configuration backup',
        ),
        const SizedBox(height: 16),

        _buildCard(
          colorScheme,
          children: [
            // Recent Projects
            _buildSettingRow(
              icon: RemixIcons.folder_open_line,
              colorScheme: colorScheme,
              title: 'Recent Projects Cache',
              subtitle:
                  '$count saved project files stored locally in device storage',
              trailing: M3EButton(
                onPressed: count > 0
                    ? () => _confirmClearProjects(context)
                    : null,
                style: M3EButtonStyle.outlined,
                size: M3EButtonSize.sm,
                child: Text(
                  'Clear Recent ($count)',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ),
            const Divider(height: 1),

            // Copy Settings JSON
            _buildSettingRow(
              icon: RemixIcons.file_copy_line,
              colorScheme: colorScheme,
              title: 'Export Settings Configuration',
              subtitle: 'Copy complete app configuration to clipboard as JSON for backup or sync',
              trailing: M3EButton.icon(
                onPressed: () {
                  final jsonMap = settings;
                  Clipboard.setData(
                    ClipboardData(
                      text:
                          '// nixSVG Studio Settings Backup\n${jsonMap.toString()}',
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Settings exported to clipboard!'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: M3EButtonStyle.tonal,
                size: M3EButtonSize.sm,
                icon: const Icon(RemixIcons.clipboard_line, size: 14),
                label: const Text('Export JSON'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Section 7: About nixSVG
  // --------------------------------------------------------------------------

  Widget _buildAboutSection(BuildContext context, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'About nixSVG',
          'Application details, architecture, and technology stack',
        ),
        const SizedBox(height: 16),

        _buildCard(
          colorScheme,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.tertiary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      RemixIcons.shapes_line,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'nixSVG Studio',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version 1.0.0 (Material 3 Expressive & macOS Studio)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _buildSettingRow(
              icon: RemixIcons.code_box_line,
              colorScheme: colorScheme,
              title: 'Design Philosophy',
              subtitle: 'Solid foundation, fluid macOS-inspired aesthetics, 60fps vector graphics, and pure Material 3 Expressive styling',
              trailing: const SizedBox.shrink(),
            ),
            const Divider(height: 1),
            _buildSettingRow(
              icon: RemixIcons.shield_check_line,
              colorScheme: colorScheme,
              title: 'Privacy & Security',
              subtitle: '100% offline, client-side vector studio. Your artwork and designs never leave your local device.',
              trailing: const SizedBox.shrink(),
            ),
          ],
        ),

        const SizedBox(height: 8),
        Consumer(
          builder: (context, ref, _) {
            final notifier = ref.read(appSettingsProvider.notifier);
            return TextButton.icon(
              onPressed: () => _confirmResetDefaults(context, notifier),
              icon: const Icon(RemixIcons.restart_line, size: 15),
              label: const Text('Reset Defaults'),
            );
          },
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Search Filtering
  // --------------------------------------------------------------------------

  List<Widget> _buildSearchResults(
    BuildContext context,
    ColorScheme colorScheme,
    AppSettingsState settings,
    AppSettingsNotifier notifier,
  ) {
    final query = _searchQuery;
    final results = <Widget>[];

    // Check each category for matching items
    final appearanceItems = [
      'theme mode light dark system',
      'accent seed color palette',
      'oled high contrast dark',
    ];
    if (appearanceItems.any((s) => s.contains(query))) {
      results.add(
        _buildAppearanceSection(context, colorScheme, settings, notifier),
      );
      results.add(const SizedBox(height: 24));
    }

    final canvasItems = [
      'snap to grid spacing',
      'grid style dots lines',
      'smart alignment guidelines',
      'invert mouse wheel zoom',
    ];
    if (canvasItems.any((s) => s.contains(query))) {
      results.add(
        _buildCanvasSection(context, colorScheme, settings, notifier),
      );
      results.add(const SizedBox(height: 24));
    }

    final workspaceItems = [
      'layers sidebar width',
      'properties sidebar width inspector',
      'floating toolbar position',
    ];
    if (workspaceItems.any((s) => s.contains(query))) {
      results.add(
        _buildWorkspaceSection(context, colorScheme, settings, notifier),
      );
      results.add(const SizedBox(height: 24));
    }

    final vectorItems = [
      'default stroke width',
      'default corner radius',
      'auto-switch to select tool',
    ];
    if (vectorItems.any((s) => s.contains(query))) {
      results.add(
        _buildVectorToolsSection(context, colorScheme, settings, notifier),
      );
      results.add(const SizedBox(height: 24));
    }

    final exportItems = [
      'svg pretty-printing',
      'xml prolog header',
      'raster scale multiplier 1x 2x',
    ];
    if (exportItems.any((s) => s.contains(query))) {
      results.add(
        _buildExportSection(context, colorScheme, settings, notifier),
      );
      results.add(const SizedBox(height: 24));
    }

    if (results.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                Icon(
                  RemixIcons.search_line,
                  size: 40,
                  color: colorScheme.outlineVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'No settings found for "$_searchQuery"',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                M3EButton(
                  onPressed: () => _searchController.clear(),
                  style: M3EButtonStyle.text,
                  child: const Text('Clear Search Filter'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return results;
  }

  // --------------------------------------------------------------------------
  // Helper UI Builders
  // --------------------------------------------------------------------------

  Widget _buildSectionHeader(String title, String description) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(ColorScheme colorScheme, {required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final validChildren = children.where((c) => c is! Divider).toList();

    return M3ECardColumn(
      outerRadius: 16.0,
      innerRadius: 4.0,
      gap: 3.0,
      color: colorScheme.surfaceContainerHigh.withValues(
        alpha: isDark ? 0.7 : 0.9,
      ),
      border: BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        width: 0.8,
      ),
      padding: EdgeInsets.zero,
      children: validChildren,
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required ColorScheme colorScheme,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final isNarrow = constraints.maxWidth < 460;
        final isSwitchOnly = trailing is Switch || trailing is M3ESwitch || trailing is Checkbox;

        VoidCallback? onTileTap;
        if (trailing is M3ESwitch) {
          final m3e = trailing;
          if (m3e.onChanged != null) {
            onTileTap = () => m3e.onChanged!(!m3e.value);
          }
        } else if (trailing is Switch) {
          final sw = trailing;
          if (sw.onChanged != null) {
            onTileTap = () => sw.onChanged!(!sw.value);
          }
        }

        final iconContainer = Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.8,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: colorScheme.primary),
        );

        final titleAndSubtitle = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.25,
                ),
              ),
            ],
          ],
        );

        Widget content;
        if (isNarrow && !isSwitchOnly) {
          content = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    iconContainer,
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: Text(
                      subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: trailing,
                  ),
                ),
              ],
            ),
          );
        } else {
          content = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                iconContainer,
                const SizedBox(width: 12),
                Expanded(child: titleAndSubtitle),
                const SizedBox(width: 14),
                trailing,
              ],
            ),
          );
        }

        if (onTileTap != null) {
          return InkWell(
            onTap: onTileTap,
            child: content,
          );
        }

        return content;
      },
    );
  }

  void _confirmResetDefaults(
    BuildContext context,
    AppSettingsNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(RemixIcons.error_warning_line, color: Colors.amber),
            SizedBox(width: 8),
            Text('Reset All Settings?'),
          ],
        ),
        content: const Text(
          'This will restore all theme, grid, workspace, vector tool, and export preferences back to their factory defaults. Your artwork projects will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(ctx).pop();
              await notifier.resetAllToDefaults();
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('All settings restored to factory defaults'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Reset All'),
          ),
        ],
      ),
    );
  }

  void _confirmClearProjects(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Recent Projects?'),
        content: const Text(
          'This will clear the recent projects list from the cache. Your saved file files on disk will remain untouched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(projectsProvider.notifier).clearRecentProjects();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
