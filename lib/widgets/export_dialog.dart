import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:m3e_buttons/m3e_buttons.dart';
import 'package:m3e_segmented_list/m3e_segmented_list.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/services/svg_export_service.dart';
import 'package:remixicon/remixicon.dart';

/// Production-grade Material 3 Expressive SVG Export Dialog.
/// Provides Figma-exact export scope selection (Selection, Canvas Artboard, Artwork Bounds),
/// resolution scaling (1x, 2x, 3x), real-time dimensions feedback, and instant SVG preview.
class ExportDialog extends StatefulWidget {
  final String? svgContent;
  final List<VectorShape>? shapes;
  final Set<String>? selectedShapeIds;
  final Size? canvasSize;
  final String fileName;
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
    this.initialIncludeXml = true,
    this.initialPrettyPrint = true,
    this.initialExportScale = 1.0,
  });

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  late SvgExportScope _scope;
  late double _exportScale;
  late bool _includeXml;
  late bool _prettyPrint;

  @override
  void initState() {
    super.initState();
    _exportScale = widget.initialExportScale;
    _includeXml = widget.initialIncludeXml;
    _prettyPrint = widget.initialPrettyPrint;

    if (widget.selectedShapeIds != null &&
        widget.selectedShapeIds!.isNotEmpty) {
      _scope = SvgExportScope.selection;
    } else {
      _scope = SvgExportScope.canvas;
    }
  }

  String _computeSvgContent() {
    if (widget.shapes == null) {
      return widget.svgContent ?? '';
    }
    return SvgExportService.generateSvg(
      widget.shapes!,
      canvasSize: widget.canvasSize ?? const Size(3200, 2400),
      selectedShapeIds: widget.selectedShapeIds,
      scope: _scope,
      includeXmlHeader: _includeXml,
      prettyPrint: _prettyPrint,
      exportScale: _exportScale,
    );
  }

  Rect _computeScopeRect() {
    final shapes = widget.shapes ?? const <VectorShape>[];
    switch (_scope) {
      case SvgExportScope.selection:
        return SvgExportService.computeSelectionBounds(
          shapes,
          widget.selectedShapeIds ?? {},
        );
      case SvgExportScope.artwork:
        return SvgExportService.computeArtworkBounds(shapes);
      case SvgExportScope.canvas:
        final s = widget.canvasSize ?? const Size(3200, 2400);
        return Rect.fromLTWH(0, 0, s.width, s.height);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final svgCode = _computeSvgContent();
    final scopeRect = _computeScopeRect();
    final hasSelection =
        widget.selectedShapeIds != null && widget.selectedShapeIds!.isNotEmpty;
    final scaledW = (scopeRect.width * _exportScale).round();
    final scaledH = (scopeRect.height * _exportScale).round();

    return AlertDialog(
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.35 : 0.25,
          ),
          width: 0.8,
        ),
      ),
      titlePadding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(RemixIcons.code_line, color: colorScheme.primary, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Export SVG',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.fileName,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.shapes != null) ...[
              // Figma Export Scope Selector
              Row(
                children: [
                  Text(
                    'Export Scope:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
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
                      },
                      equalWidth: true,
                      gap: 2.0,
                      decoration: M3ESegmentedListDecoration(
                        outerRadius: 10.0,
                        innerRadius: 4.0,
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
                                    fontWeight:
                                        _scope == SvgExportScope.selection
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    color:
                                        _scope == SvgExportScope.selection
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
              const SizedBox(height: 10),

              // Export Scale & Specs Badges
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
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          RemixIcons.aspect_ratio_line,
                          size: 13,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$scaledW × $scaledH px',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      'ViewBox: ${scopeRect.left.round()} ${scopeRect.top.round()} ${scopeRect.width.round()} ${scopeRect.height.round()}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Scale Buttons (1x, 2x, 3x)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [1.0, 2.0, 3.0].map((scale) {
                      final isSelected = (_exportScale - scale).abs() < 0.05;
                      return Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: InkWell(
                          onTap: () => setState(() => _exportScale = scale),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
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
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // SVG Code Preview
            Container(
              height: 280,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(
                    alpha: isDark ? 0.3 : 0.2,
                  ),
                  width: 0.8,
                ),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  svgCode,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.9),
                    fontFamily: 'monospace',
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        M3EButton(
          onPressed: () => Navigator.of(context).pop(),
          style: M3EButtonStyle.text,
          child: Text(
            'Close',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        M3EButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: svgCode));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'SVG markup copied to clipboard!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
                backgroundColor: colorScheme.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
            Navigator.of(context).pop();
          },
          style: M3EButtonStyle.filled,
          size: M3EButtonSize.sm,
          icon: Icon(
            RemixIcons.file_copy_line,
            size: 16,
            color: colorScheme.onPrimary,
          ),
          label: Text(
            'Copy SVG Code',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
