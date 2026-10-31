import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:m3e_buttons/m3e_buttons.dart';
import 'package:m3e_loading_indicator/m3e_loading_indicator.dart';
import 'package:m3e_segmented_list/m3e_segmented_list.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/services/file_saver/safe_file_saver.dart';
import 'package:nixsvg/services/svg_export_service.dart';
import 'package:nixsvg/services/vector_export_service.dart';
import 'package:remixicon/remixicon.dart';

/// Production-grade Material 3 Expressive Universal Export Dialog.
/// Supports universal export across all platforms (macOS, Windows, Linux, Web, Android, iOS)
/// with standard formats: .png, .jpeg, .svg, and .pdf.
class ExportDialog extends StatefulWidget {
  final String? svgContent;
  final List<VectorShape>? shapes;
  final Set<String>? selectedShapeIds;
  final Size? canvasSize;
  final String fileName;
  final ExportFormat initialFormat;
  final bool initialIncludeXml;
  final bool initialPrettyPrint;
  final double initialExportScale;

  const ExportDialog({
    super.key,
    this.svgContent,
    this.shapes,
    this.selectedShapeIds,
    this.canvasSize,
    required this.fileName,
    this.initialFormat = ExportFormat.png,
    this.initialIncludeXml = true,
    this.initialPrettyPrint = true,
    this.initialExportScale = 1.0,
  });

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  late ExportFormat _format;
  late SvgExportScope _scope;
  late double _exportScale;
  late bool _transparentBackground;
  late double _jpegQuality;
  late bool _includeXml;
  late bool _prettyPrint;
  late final TextEditingController _nameController;

  bool _isExporting = false;
  bool _showSvgCode = false;
  Uint8List? _previewBytes;
  bool _isLoadingPreview = false;
  String? _previewSvgCode;

  @override
  void initState() {
    super.initState();
    _format = widget.initialFormat;
    _exportScale = widget.initialExportScale;
    _transparentBackground = true;
    _jpegQuality = 0.90;
    _includeXml = widget.initialIncludeXml;
    _prettyPrint = widget.initialPrettyPrint;

    if (widget.selectedShapeIds != null &&
        widget.selectedShapeIds!.isNotEmpty) {
      _scope = SvgExportScope.selection;
    } else {
      _scope = SvgExportScope.canvas;
    }

    // Extract base name without extension
    final cleaned = widget.fileName.replaceAll(
      RegExp(r'\.(svg|png|jpeg|jpg|pdf)$', caseSensitive: false),
      '',
    );
    _nameController = TextEditingController(
      text: cleaned.isEmpty ? 'artwork' : cleaned,
    );

    _updatePreview();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Rect _computeScopeRect() {
    final shapes = widget.shapes ?? const <VectorShape>[];
    return VectorExportService.computeExportScopeRect(
      shapes: shapes,
      scope: _scope,
      selectedShapeIds: widget.selectedShapeIds,
      canvasSize: widget.canvasSize ?? const Size(1920, 1080),
    );
  }

  Future<void> _updatePreview() async {
    if (!mounted) return;
    setState(() => _isLoadingPreview = true);

    try {
      final shapes = widget.shapes ?? const <VectorShape>[];
      if (_format == ExportFormat.svg) {
        _previewSvgCode = SvgExportService.generateSvg(
          shapes,
          canvasSize: widget.canvasSize ?? const Size(1920, 1080),
          selectedShapeIds: widget.selectedShapeIds,
          scope: _scope,
          includeXmlHeader: _includeXml,
          prettyPrint: _prettyPrint,
          exportScale: _exportScale,
        );
      }

      // Generate a fast preview thumbnail (1x scale for rapid rendering)
      if (shapes.isNotEmpty) {
        final bytes = await VectorExportService.exportToBytes(
          shapes: shapes,
          format: ExportFormat.png,
          canvasSize: widget.canvasSize ?? const Size(1920, 1080),
          selectedShapeIds: widget.selectedShapeIds,
          scope: _scope,
          exportScale: 1.0,
          transparentBackground: _format == ExportFormat.jpeg
              ? false
              : _transparentBackground,
          backgroundColor: Colors.white,
          colorScheme: Theme.of(context).colorScheme,
        );
        if (mounted) {
          setState(() {
            _previewBytes = bytes;
            _isLoadingPreview = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingPreview = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPreview = false);
      }
    }
  }

  Future<void> _handleExport() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final shapes = widget.shapes ?? const <VectorShape>[];
      final colorScheme = Theme.of(context).colorScheme;

      final bytes = await VectorExportService.exportToBytes(
        shapes: shapes,
        format: _format,
        canvasSize: widget.canvasSize ?? const Size(1920, 1080),
        selectedShapeIds: widget.selectedShapeIds,
        scope: _scope,
        exportScale: _exportScale,
        transparentBackground: _transparentBackground,
        backgroundColor: Colors.white,
        jpegQuality: _jpegQuality,
        includeXmlHeader: _includeXml,
        prettyPrint: _prettyPrint,
        colorScheme: colorScheme,
      );

      var baseName = _nameController.text.trim();
      baseName = baseName.replaceAll(
        RegExp(r'\.(svg|png|jpeg|jpg|pdf)$', caseSensitive: false),
        '',
      );
      if (baseName.isEmpty) baseName = 'artwork';
      final fullFileName = '$baseName.${_format.extension}';

      final savedPath = await saveFileToDisk(
        fileName: fullFileName,
        bytes: bytes,
        mimeType: _format.mimeType,
      );

      if (!mounted) return;

      setState(() => _isExporting = false);

      if (savedPath != null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  RemixIcons.checkbox_circle_line,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Exported successfully: $fullFileName',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _copySvgCode() {
    final code =
        _previewSvgCode ??
        SvgExportService.generateSvg(
          widget.shapes ?? const <VectorShape>[],
          canvasSize: widget.canvasSize ?? const Size(1920, 1080),
          selectedShapeIds: widget.selectedShapeIds,
          scope: _scope,
          includeXmlHeader: _includeXml,
          prettyPrint: _prettyPrint,
          exportScale: _exportScale,
        );

    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('SVG markup copied to clipboard!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final scopeRect = _computeScopeRect();
    final hasSelection =
        widget.selectedShapeIds != null && widget.selectedShapeIds!.isNotEmpty;
    final scaledW = (scopeRect.width * _exportScale).round();
    final scaledH = (scopeRect.height * _exportScale).round();

    return AlertDialog(
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.35 : 0.25,
          ),
          width: 0.8,
        ),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              RemixIcons.file_download_line,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Quick Export',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Live preview & format options',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 760,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 640;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 12,
                    child: SingleChildScrollView(
                      child: _buildConfigForm(
                        theme: theme,
                        colorScheme: colorScheme,
                        scopeRect: scopeRect,
                        hasSelection: hasSelection,
                        scaledW: scaledW,
                        scaledH: scaledH,
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 11,
                    child: _buildPreviewCard(
                      theme: theme,
                      colorScheme: colorScheme,
                      scaledW: scaledW,
                      scaledH: scaledH,
                    ),
                  ),
                ],
              );
            } else {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildConfigForm(
                      theme: theme,
                      colorScheme: colorScheme,
                      scopeRect: scopeRect,
                      hasSelection: hasSelection,
                      scaledW: scaledW,
                      scaledH: scaledH,
                    ),
                    const SizedBox(height: 14),
                    _buildPreviewCard(
                      theme: theme,
                      colorScheme: colorScheme,
                      scaledW: scaledW,
                      scaledH: scaledH,
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
      actions: [
        M3EButton(
          onPressed: () => Navigator.of(context).pop(),
          style: M3EButtonStyle.text,
          child: Text(
            'Cancel',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (_format == ExportFormat.svg)
          M3EButton.icon(
            onPressed: _copySvgCode,
            style: M3EButtonStyle.tonal,
            size: M3EButtonSize.sm,
            icon: Icon(
              RemixIcons.file_copy_line,
              size: 15,
              color: colorScheme.onSurface,
            ),
            label: Text(
              'Copy SVG',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (_isExporting)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(100.0),
              ),
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: M3ELoadingIndicator(
                      color: colorScheme.onPrimary,
                      constraints: const BoxConstraints.tightFor(
                        width: 18,
                        height: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Exporting...",
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (!_isExporting)
          M3ESplitButton<ExportFormat>(
            style: M3EButtonStyle.filled,
            size: M3EButtonSize.sm,
            shape: M3EButtonShape.round,
            leadingIcon: _isExporting
                ? RemixIcons.loader_4_line
                : RemixIcons.download_2_line,
            label: _isExporting ? 'Exporting...' : 'Export ${_format.label}',
            selectedValue: _format,
            leadingTooltip: 'Export current artwork as ${_format.label}',
            trailingTooltip: 'More Formats',
            decoration: M3ESplitButtonDecoration.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            items: const [
              M3ESplitButtonItem(
                value: ExportFormat.png,
                child: Text('Export PNG (.png)'),
              ),
              M3ESplitButtonItem(
                value: ExportFormat.jpeg,
                child: Text('Export JPEG (.jpeg)'),
              ),
              M3ESplitButtonItem(
                value: ExportFormat.svg,
                child: Text('Export SVG (.svg)'),
              ),
              M3ESplitButtonItem(
                value: ExportFormat.pdf,
                child: Text('Export PDF (.pdf)'),
              ),
            ],
            onPressed: _isExporting ? null : _handleExport,
            onSelected: (val) {
              setState(() => _format = val);
              _updatePreview();
            },
          ),
      ],
    );
  }

  Widget _buildConfigForm({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required Rect scopeRect,
    required bool hasSelection,
    required int scaledW,
    required int scaledH,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // File Name
        Text(
          'File Name',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: 0.8,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          child: TextField(
            controller: _nameController,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              suffixText: '.${_format.extension}',
              suffixStyle: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Format selector
        Text(
          'Format',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: ExportFormat.values.map((format) {
            final isSelected = _format == format;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: InkWell(
                  onTap: () {
                    setState(() => _format = format);
                    _updatePreview();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.3,
                              ),
                              width: 0.8,
                            ),
                    ),
                    child: Text(
                      format.name.toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // Scope selector
        if (widget.shapes != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Export Scope:',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: M3ESegmentedRow(
                  onTap: (index) {
                    setState(() {
                      if (hasSelection) {
                        switch (index) {
                          case 0:
                            _scope = SvgExportScope.selection;
                            break;
                          case 1:
                            _scope = SvgExportScope.canvas;
                            break;
                          case 2:
                            _scope = SvgExportScope.artwork;
                            break;
                        }
                      } else {
                        switch (index) {
                          case 0:
                            _scope = SvgExportScope.canvas;
                            break;
                          case 1:
                            _scope = SvgExportScope.artwork;
                            break;
                        }
                      }
                    });
                    _updatePreview();
                  },
                  equalWidth: true,
                  gap: 2.0,
                  decoration: M3ESegmentedListDecoration(
                    outerRadius: 8.0,
                    innerRadius: 8.0,
                    pressedRadius: 8.0,
                    pressedScale: 1.0,
                    border: BorderSide.none,
                    elevation: 0.0,
                    gap: 2.0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    color: colorScheme.surfaceContainerHighest,
                    hoverColor: colorScheme.surfaceContainerHighest,
                  ),
                  children: hasSelection
                      ? [
                          Center(
                            child: Text(
                              'Selection (${widget.selectedShapeIds!.length})',
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: _scope == SvgExportScope.selection
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _scope == SvgExportScope.selection
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              'Canvas',
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: _scope == SvgExportScope.canvas
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _scope == SvgExportScope.canvas
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              'Artwork',
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: _scope == SvgExportScope.artwork
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _scope == SvgExportScope.artwork
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ]
                      : [
                          Center(
                            child: Text(
                              'Canvas (${(widget.canvasSize?.width ?? 3200).toInt()}×${(widget.canvasSize?.height ?? 2400).toInt()})',
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: _scope == SvgExportScope.canvas
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _scope == SvgExportScope.canvas
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              'Artwork Bounds',
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: _scope == SvgExportScope.artwork
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _scope == SvgExportScope.artwork
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                ),
              ),
            ],
          ),
        ],

        // Scale Buttons (1x, 2x, 3x, 4x)
        const SizedBox(height: 14),
        Row(
          children: [
            Text(
              'Scale:',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            ...[1.0, 2.0, 3.0, 4.0].map((scale) {
              final isSelected = (_exportScale - scale).abs() < 0.05;
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: InkWell(
                  onTap: () {
                    setState(() => _exportScale = scale);
                    if (_format == ExportFormat.svg) {
                      _updatePreview();
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${scale.toInt()}x',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),

        // Format specific settings
        if (_format == ExportFormat.jpeg) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Quality (${(_jpegQuality * 100).round()}%)',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
            ],
          ),
          Slider(
            value: _jpegQuality,
            min: 0.1,
            max: 1.0,
            divisions: 18,
            activeColor: colorScheme.primary,
            onChanged: (val) => setState(() => _jpegQuality = val),
          ),
        ],

        if (_format == ExportFormat.svg) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              InkWell(
                onTap: () {
                  setState(() => _includeXml = !_includeXml);
                  _updatePreview();
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _includeXml,
                        onChanged: (val) {
                          setState(() => _includeXml = val ?? true);
                          _updatePreview();
                        },
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'XML Header',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              InkWell(
                onTap: () {
                  setState(() => _prettyPrint = !_prettyPrint);
                  _updatePreview();
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _prettyPrint,
                        onChanged: (val) {
                          setState(() => _prettyPrint = val ?? true);
                          _updatePreview();
                        },
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Pretty Print',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],

        if (_format == ExportFormat.png) ...[
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              setState(() => _transparentBackground = !_transparentBackground);
              _updatePreview();
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _transparentBackground,
                    onChanged: (val) {
                      setState(() => _transparentBackground = val ?? true);
                      _updatePreview();
                    },
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Transparent Background',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewCard({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required int scaledW,
    required int scaledH,
  }) {
    return Container(
      height: 310,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          // Preview Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(13),
              ),
            ),
            child: Row(
              children: [
                Icon(RemixIcons.eye_line, size: 13, color: colorScheme.primary),
                const SizedBox(width: 5),
                Text(
                  'Live Preview',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                if (_format == ExportFormat.svg)
                  InkWell(
                    onTap: () => setState(() => _showSvgCode = !_showSvgCode),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _showSvgCode
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            RemixIcons.code_s_slash_line,
                            size: 10,
                            color: _showSvgCode
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Code',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _showSvgCode
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$scaledW × $scaledH',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Preview Content
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(13),
              ),
              child: _isLoadingPreview
                  ? Center(
                      child: SizedBox(
                        child: M3ELoadingIndicator(color: colorScheme.primary),
                      ),
                    )
                  : (_format == ExportFormat.svg && _showSvgCode)
                  ? Container(
                      padding: const EdgeInsets.all(10),
                      color: colorScheme.surfaceContainerLowest,
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _previewSvgCode ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: colorScheme.onSurface,
                            height: 1.4,
                          ),
                        ),
                      ),
                    )
                  : _previewBytes != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_transparentBackground &&
                            _format == ExportFormat.png)
                          CustomPaint(painter: _CheckerboardPainter()),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.memory(
                            _previewBytes!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Text(
                        'Generating Preview...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter that renders subtle 8x8 checkerboard pattern behind transparent PNG preview.
class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const squareSize = 10.0;
    final paint1 = Paint()..color = const Color(0xFF1E1E1E);
    final paint2 = Paint()..color = const Color(0xFF282828);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint1);

    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        final isEven =
            ((x / squareSize).floor() + (y / squareSize).floor()) % 2 == 0;
        if (isEven) {
          canvas.drawRect(Rect.fromLTWH(x, y, squareSize, squareSize), paint2);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
