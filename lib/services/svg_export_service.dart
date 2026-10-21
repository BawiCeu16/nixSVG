import 'dart:ui';

import 'package:nixsvg/models/vector_shape.dart';

/// Scope of vector SVG export.
enum SvgExportScope {
  /// Export only the currently selected shapes with tight bounding box viewBox.
  selection,

  /// Export all visible artwork tightly fitted to their combined bounding box.
  artwork,

  /// Export the entire canvas / artboard frame (0, 0, width, height).
  canvas,
}

/// Service that serializes vector shape collections to scalable vector graphics (SVG) markup.
class SvgExportService {
  /// Computes the collective bounding box enclosing all visible shapes.
  static Rect computeArtworkBounds(List<VectorShape> shapes) {
    final visible = shapes.where((s) => s.isVisible).toList();
    if (visible.isEmpty) return const Rect.fromLTWH(0, 0, 100, 100);
    Rect b = visible.first.getBoundingBox();
    for (int i = 1; i < visible.length; i++) {
      b = b.expandToInclude(visible[i].getBoundingBox());
    }
    return b;
  }

  /// Computes the collective bounding box enclosing currently selected shapes.
  static Rect computeSelectionBounds(
    List<VectorShape> shapes,
    Set<String> selectedIds,
  ) {
    final selected = shapes
        .where((s) => s.isVisible && selectedIds.contains(s.id))
        .toList();
    if (selected.isEmpty) return computeArtworkBounds(shapes);
    Rect b = selected.first.getBoundingBox();
    for (int i = 1; i < selected.length; i++) {
      b = b.expandToInclude(selected[i].getBoundingBox());
    }
    return b;
  }

  /// Generates SVG markup for [shapes] with custom scope, dimensions, and viewBox.
  static String generateSvg(
    List<VectorShape> shapes, {
    Size canvasSize = const Size(1920, 1080),
    Rect? exportBounds,
    Set<String>? selectedShapeIds,
    SvgExportScope scope = SvgExportScope.canvas,
    bool includeXmlHeader = true,
    bool prettyPrint = true,
    double exportScale = 1.0,
  }) {
    final List<VectorShape> exportShapes;
    if (scope == SvgExportScope.selection &&
        selectedShapeIds != null &&
        selectedShapeIds.isNotEmpty) {
      exportShapes = shapes
          .where((s) => s.isVisible && selectedShapeIds.contains(s.id))
          .toList();
    } else {
      exportShapes = shapes.where((s) => s.isVisible).toList();
    }

    final Rect effectiveRect;
    if (exportBounds != null) {
      effectiveRect = exportBounds;
    } else {
      switch (scope) {
        case SvgExportScope.selection:
          effectiveRect = computeSelectionBounds(
            shapes,
            selectedShapeIds ?? {},
          );
          break;
        case SvgExportScope.artwork:
          effectiveRect = computeArtworkBounds(shapes);
          break;
        case SvgExportScope.canvas:
          effectiveRect = Rect.fromLTWH(
            0,
            0,
            canvasSize.width,
            canvasSize.height,
          );
          break;
      }
    }

    final effectiveWidth = (effectiveRect.width * exportScale).toInt();
    final effectiveHeight = (effectiveRect.height * exportScale).toInt();
    final minX = effectiveRect.left.round();
    final minY = effectiveRect.top.round();
    final viewBoxW = effectiveRect.width.round();
    final viewBoxH = effectiveRect.height.round();

    final buffer = StringBuffer();
    final newline = prettyPrint ? '\n' : '';
    final indent = prettyPrint ? '  ' : '';

    if (includeXmlHeader) {
      buffer.write(
        '<?xml version="1.0" encoding="UTF-8" standalone="no"?>$newline',
      );
    }
    buffer.write(
      '<svg xmlns="http://www.w3.org/2000/svg" width="$effectiveWidth" height="$effectiveHeight" viewBox="$minX $minY $viewBoxW $viewBoxH">$newline',
    );

    final defsBuffer = StringBuffer();
    for (final shape in exportShapes) {
      final defs = shape.toSvgDefs();
      if (defs.isNotEmpty) {
        defsBuffer.write(defs);
      }
    }

    if (defsBuffer.isNotEmpty) {
      buffer.write('$indent<defs>$newline');
      buffer.write(defsBuffer.toString());
      buffer.write('$indent</defs>$newline');
    }

    for (final shape in exportShapes) {
      final elementSvg = shape.toSvgElement();
      if (elementSvg.isNotEmpty) {
        buffer.write('$elementSvg$newline');
      }
    }

    buffer.write('</svg>');

    return buffer.toString();
  }
}
