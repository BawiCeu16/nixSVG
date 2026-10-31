import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/painters/vector_canvas_painter.dart';
import 'package:nixsvg/services/svg_export_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Supported universal export formats.
enum ExportFormat {
  png('PNG', 'png', 'image/png', 'Raster image with alpha transparency'),
  jpeg('JPEG', 'jpeg', 'image/jpeg', 'Compressed photographic image'),
  svg('SVG', 'svg', 'image/svg+xml', 'Scalable vector graphics markup'),
  pdf('PDF', 'pdf', 'application/pdf', 'Portable document format');

  final String label;
  final String extension;
  final String mimeType;
  final String description;

  const ExportFormat(
    this.label,
    this.extension,
    this.mimeType,
    this.description,
  );
}

/// Comprehensive vector and raster export service for nixSVG.
/// Supports rendering vector shapes into SVG, PNG, JPEG, and PDF formats
/// with precise bounding-box scopes, multi-scale resolution, and cross-platform output.
class VectorExportService {
  const VectorExportService._();

  /// Computes the effective export bounds according to the chosen [scope].
  static Rect computeExportScopeRect({
    required List<VectorShape> shapes,
    required SvgExportScope scope,
    Set<String>? selectedShapeIds,
    Size canvasSize = const Size(1920, 1080),
  }) {
    switch (scope) {
      case SvgExportScope.selection:
        return SvgExportService.computeSelectionBounds(
          shapes,
          selectedShapeIds ?? const <String>{},
        );
      case SvgExportScope.artwork:
        return SvgExportService.computeArtworkBounds(shapes);
      case SvgExportScope.canvas:
        return Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height);
    }
  }

  /// Exports [shapes] into standard binary or markup bytes according to [format].
  static Future<Uint8List> exportToBytes({
    required List<VectorShape> shapes,
    required ExportFormat format,
    Size canvasSize = const Size(1920, 1080),
    Rect? exportBounds,
    Set<String>? selectedShapeIds,
    SvgExportScope scope = SvgExportScope.canvas,
    double exportScale = 1.0,
    bool transparentBackground = true,
    Color? backgroundColor,
    double jpegQuality = 0.90,
    bool includeXmlHeader = true,
    bool prettyPrint = true,
    ColorScheme? colorScheme,
  }) async {
    // 1. SVG Format: direct vector XML serialization
    if (format == ExportFormat.svg) {
      final svgString = SvgExportService.generateSvg(
        shapes,
        canvasSize: canvasSize,
        exportBounds: exportBounds,
        selectedShapeIds: selectedShapeIds,
        scope: scope,
        includeXmlHeader: includeXmlHeader,
        prettyPrint: prettyPrint,
        exportScale: exportScale,
      );
      return Uint8List.fromList(utf8.encode(svgString));
    }

    // 2. Compute bounds for rasterization
    final effectiveRect =
        exportBounds ??
        computeExportScopeRect(
          shapes: shapes,
          selectedShapeIds: selectedShapeIds,
          scope: scope,
          canvasSize: canvasSize,
        );

    final pixelWidth = (effectiveRect.width * exportScale).round().clamp(
      1,
      16384,
    );
    final pixelHeight = (effectiveRect.height * exportScale).round().clamp(
      1,
      16384,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, pixelWidth.toDouble(), pixelHeight.toDouble()),
    );

    // Apply background color if requested (or required by JPEG)
    final isOpaque = !transparentBackground || format == ExportFormat.jpeg;
    if (isOpaque) {
      final bg = backgroundColor ?? Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, pixelWidth.toDouble(), pixelHeight.toDouble()),
        Paint()..color = bg,
      );
    }

    // Transform canvas coordinate space to align with the export rect and scale
    canvas.scale(exportScale, exportScale);
    canvas.translate(-effectiveRect.left, -effectiveRect.top);

    // Filter shapes based on export scope
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

    final painter = VectorCanvasPainter(
      shapes: exportShapes,
      selectedShapeIds: const {},
      currentMode: EditorMode.select,
      colorScheme: colorScheme ?? const ColorScheme.light(),
      visibleRect: effectiveRect.inflate(200.0),
    );
    painter.paint(canvas, Size(effectiveRect.width, effectiveRect.height));

    final picture = recorder.endRecording();
    final image = await picture.toImage(pixelWidth, pixelHeight);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to rasterize canvas vector shapes to image.');
    }
    final pngBytes = byteData.buffer.asUint8List();

    // 3. PNG Format
    if (format == ExportFormat.png) {
      return pngBytes;
    }

    // 4. JPEG Format
    if (format == ExportFormat.jpeg) {
      final decoded = img.decodePng(pngBytes);
      if (decoded == null) {
        throw Exception('Failed to decode raster image for JPEG conversion.');
      }
      final quality = (jpegQuality.clamp(0.1, 1.0) * 100).toInt();
      final jpgBytes = Uint8List.fromList(
        img.encodeJpg(decoded, quality: quality),
      );
      return jpgBytes;
    }

    // 5. PDF Format
    if (format == ExportFormat.pdf) {
      final doc = pw.Document(
        title: 'nixSVG Export',
        author: 'nixSVG',
        creator: 'nixSVG Vector Design Studio',
      );

      final pageFormat = PdfPageFormat(
        effectiveRect.width,
        effectiveRect.height,
        marginAll: 0,
      );

      final pwImage = pw.MemoryImage(pngBytes);

      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Image(pwImage, fit: pw.BoxFit.contain),
            );
          },
        ),
      );

      final pdfBytes = await doc.save();
      return pdfBytes;
    }

    throw UnsupportedError('Unsupported export format: $format');
  }
}
