import 'package:flutter/material.dart';
import 'package:m3e_buttons/m3e_buttons.dart';
import 'package:nixsvg/models/device_preset.dart';
import 'package:remixicon/remixicon.dart';

enum DevicePresetAction {
  createProject,
  insertOnCanvas,
  @Deprecated('Replaced by pure frames without templates')
  insertTemplateOnCanvas,
  @Deprecated('Artboard has been removed in favor of infinite canvas')
  setAsArtboard,
}

class DevicePresetResult {
  final DevicePreset preset;
  final DevicePresetAction action;

  const DevicePresetResult({required this.preset, required this.action});

  bool get withTemplate => false;
}

/// Material 3 Expressive Mobile Device Frames Modal Dialog.
class DevicePresetsDialog extends StatefulWidget {
  final bool isWorkspaceMode;
  final ValueChanged<DevicePresetResult>? onPresetSelected;

  const DevicePresetsDialog({
    super.key,
    this.isWorkspaceMode = false,
    this.onPresetSelected,
  });

  static Future<DevicePresetResult?> show(
    BuildContext context, {
    bool isWorkspaceMode = false,
  }) {
    return showDialog<DevicePresetResult>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) =>
          DevicePresetsDialog(isWorkspaceMode: isWorkspaceMode),
    );
  }

  @override
  State<DevicePresetsDialog> createState() => _DevicePresetsDialogState();
}

class _DevicePresetsDialogState extends State<DevicePresetsDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DeviceBrand? _selectedBrand;
  String? _selectedSeries;

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
    super.dispose();
  }

  List<String> get _availableSeries {
    if (_selectedBrand != null) {
      return DevicePreset.getSeriesForBrand(_selectedBrand);
    }
    final seen = <String>{};
    final list = <String>[];
    for (final p in DevicePreset.allPresets) {
      if (seen.add(p.series)) {
        list.add(p.series);
      }
    }
    return list;
  }

  List<DevicePreset> get _filteredPresets {
    return DevicePreset.allPresets.where((preset) {
      if (_selectedBrand != null && preset.brand != _selectedBrand) {
        return false;
      }
      if (_selectedSeries != null && preset.series != _selectedSeries) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final matchName = preset.name.toLowerCase().contains(_searchQuery);
        final matchBrand = preset.brand.label.toLowerCase().contains(
          _searchQuery,
        );
        final matchSpec = preset.displaySpec.toLowerCase().contains(
          _searchQuery,
        );
        final matchDim = '${preset.width.toInt()}x${preset.height.toInt()}'
            .contains(_searchQuery);
        final matchSeries = preset.series.toLowerCase().contains(_searchQuery);
        return matchName || matchBrand || matchSpec || matchDim || matchSeries;
      }
      return true;
    }).toList();
  }

  void _selectPreset(DevicePreset preset, DevicePresetAction action) {
    final result = DevicePresetResult(preset: preset, action: action);
    if (widget.onPresetSelected != null) {
      widget.onPresetSelected!(result);
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 680;

    return Dialog(
      backgroundColor: colorScheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 32,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 960,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= HEADER =================
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      RemixIcons.smartphone_line,
                      size: 22,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              'Mobile Device Frames',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${DevicePreset.allPresets.length} Devices',
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Apple iPhones (12–18), Google Pixel (7–11), and Nothing Phone series',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      RemixIcons.close_line,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ================= FILTER & SEARCH BAR =================
              Row(
                children: [
                  // Brand Filter Segmented Pills
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'All Brands',
                            icon: RemixIcons.apps_line,
                            isSelected: _selectedBrand == null,
                            onTap: () => setState(() {
                              _selectedBrand = null;
                              _selectedSeries = null;
                            }),
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Apple (iPhone 12–18)',
                            icon: RemixIcons.apple_fill,
                            isSelected: _selectedBrand == DeviceBrand.apple,
                            onTap: () => setState(() {
                              _selectedBrand = DeviceBrand.apple;
                              _selectedSeries = null;
                            }),
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Google (Pixel 7–11)',
                            icon: RemixIcons.google_fill,
                            isSelected: _selectedBrand == DeviceBrand.google,
                            onTap: () => setState(() {
                              _selectedBrand = DeviceBrand.google;
                              _selectedSeries = null;
                            }),
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Nothing Phone (All)',
                            icon: RemixIcons.record_circle_line,
                            isSelected: _selectedBrand == DeviceBrand.nothing,
                            onTap: () => setState(() {
                              _selectedBrand = DeviceBrand.nothing;
                              _selectedSeries = null;
                            }),
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Search Box
                  SizedBox(
                    width: isCompact ? 140 : 220,
                    height: 38,
                    child: TextField(
                      controller: _searchController,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search device...',
                        hintStyle: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        prefixIcon: Icon(
                          RemixIcons.search_line,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ================= MODEL SERIES CHOOSER ROW =================
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          RemixIcons.smartphone_line,
                          size: 13,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Model Series',
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: _selectedBrand == null
                                ? 'All Series'
                                : 'All ${_selectedBrand!.label}',
                            icon: RemixIcons.apps_2_line,
                            isSelected: _selectedSeries == null,
                            onTap: () => setState(() => _selectedSeries = null),
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                          for (final series in _availableSeries) ...[
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              label: series,
                              icon: RemixIcons.smartphone_line,
                              isSelected: _selectedSeries == series,
                              onTap: () => setState(
                                () => _selectedSeries = series,
                              ),
                              colorScheme: colorScheme,
                              textTheme: textTheme,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ================= PRESETS GRID =================
              Expanded(
                child: _filteredPresets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              RemixIcons.device_line,
                              size: 48,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No devices matched "$_searchQuery"',
                              style: textTheme.titleSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isCompact
                              ? 1
                              : (screenWidth > 850 ? 3 : 2),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 144,
                        ),
                        itemCount: _filteredPresets.length,
                        itemBuilder: (context, index) {
                          final preset = _filteredPresets[index];
                          return _buildDeviceCard(
                            context: context,
                            preset: preset,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
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

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 12,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard({
    required BuildContext context,
    required DevicePreset preset,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    final brandColor = switch (preset.brand) {
      DeviceBrand.apple => const Color(0xFF007AFF),
      DeviceBrand.google => const Color(0xFF4285F4),
      DeviceBrand.nothing => const Color(0xFFEA2027),
    };

    final brandIcon = switch (preset.brand) {
      DeviceBrand.apple => RemixIcons.apple_fill,
      DeviceBrand.google => RemixIcons.google_fill,
      DeviceBrand.nothing => RemixIcons.record_circle_line,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device Header Row (Brand Badge & Dimension Tag)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(brandIcon, size: 11, color: brandColor),
                    const SizedBox(width: 4),
                    Text(
                      preset.brand.label,
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: brandColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${preset.width.toInt()} × ${preset.height.toInt()} pt',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Device Name & Spec
          Text(
            preset.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${preset.screenDiagonal} • Radius: ${preset.cornerRadius.toInt()}px • Bezel: ${preset.frameThickness}px',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),

          // Actions Row - Only Frame insertion (no templates or artboard size buttons)
          SizedBox(
            width: double.infinity,
            child: widget.isWorkspaceMode
                ? M3EButton.icon(
                    onPressed: () => _selectPreset(
                      preset,
                      DevicePresetAction.insertOnCanvas,
                    ),
                    style: M3EButtonStyle.tonal,
                    size: M3EButtonSize.sm,
                    icon: const Icon(RemixIcons.add_line, size: 14),
                    label: const Text(
                      'Insert Frame',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : M3EButton.icon(
                    onPressed: () =>
                        _selectPreset(preset, DevicePresetAction.createProject),
                    style: M3EButtonStyle.filled,
                    size: M3EButtonSize.sm,
                    icon: const Icon(RemixIcons.add_line, size: 14),
                    label: const Text(
                      'Use Frame',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
