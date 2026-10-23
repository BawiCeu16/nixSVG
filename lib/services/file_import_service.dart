import 'dart:convert';
import 'dart:ui' as ui;
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nixsvg/models/project_model.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/services/svg_import_service.dart';

/// The recognized file format after import.
enum ImportedFileType {
  svg,
  image,
  project,
  unknown,
}

/// The result of an imported file containing parsed vector shapes or project model.
class ImportedFileResult {
  final String fileName;
  final ImportedFileType type;
  final List<VectorShape> shapes;
  final ProjectModel? project;
  final bool isSuccess;
  final String? errorMessage;

  const ImportedFileResult({
    required this.fileName,
    required this.type,
    this.shapes = const [],
    this.project,
    this.isSuccess = true,
    this.errorMessage,
  });

  factory ImportedFileResult.failure({
    required String fileName,
    required String errorMessage,
  }) {
    return ImportedFileResult(
      fileName: fileName,
      type: ImportedFileType.unknown,
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}

/// Unified cross-platform service for importing and decoding files
/// (SVGs, raster images, and JSON project files) from drag-and-drop or file pickers.
class FileImportService {
  const FileImportService._();

  /// Supported file extensions for nixSVG imports.
  static const List<String> supportedExtensions = [
    'svg',
    'png',
    'jpg',
    'jpeg',
    'webp',
    'gif',
    'json',
    'nixsvg',
  ];

  /// Checks if the given filename or path is a supported import format.
  static bool isSupportedFile(String fileName) {
    final lower = fileName.toLowerCase();
    return supportedExtensions.any((ext) => lower.endsWith('.$ext'));
  }

  /// Imports an individual file from in-memory byte buffer.
  ///
  /// If [targetCanvasPoint] is provided, vector shapes and raster images are
  /// positioned centered at that exact coordinate in canvas world space.
  static Future<ImportedFileResult> importFileFromBytes({
    required String fileName,
    required Uint8List bytes,
    Offset? targetCanvasPoint,
  }) async {
    try {
      final lowerName = fileName.toLowerCase();
      final isSvg = lowerName.endsWith('.svg') ||
          (bytes.length > 5 &&
              utf8.decode(bytes.take(100).toList(), allowMalformed: true).contains('<svg'));

      // 1. Process SVG Vector Graphic
      if (isSvg) {
        final svgContent = utf8.decode(bytes);
        final shapes = SvgImportService.parseSvg(
          svgContent,
          targetOrigin: targetCanvasPoint,
        );

        if (shapes.isEmpty) {
          return ImportedFileResult.failure(
            fileName: fileName,
            errorMessage: 'No vector paths or shapes found in $fileName',
          );
        }

        return ImportedFileResult(
          fileName: fileName,
          type: ImportedFileType.svg,
          shapes: shapes,
        );
      }

      // 2. Process nixSVG / JSON Project File
      if (lowerName.endsWith('.json') || lowerName.endsWith('.nixsvg')) {
        try {
          final jsonString = utf8.decode(bytes);
          final decoded = jsonDecode(jsonString);

          if (decoded is Map<String, dynamic>) {
            // Check if it represents a ProjectModel
            if (decoded.containsKey('shapes') || decoded.containsKey('canvasSize')) {
              final project = ProjectModel.fromJson(decoded);
              return ImportedFileResult(
                fileName: fileName,
                type: ImportedFileType.project,
                project: project,
                shapes: project.shapes,
              );
            }
          } else if (decoded is List) {
            // Decoded list of shapes
            final shapes = decoded
                .map((e) => VectorShape.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
            return ImportedFileResult(
              fileName: fileName,
              type: ImportedFileType.svg,
              shapes: shapes,
            );
          }
        } catch (e) {
          debugPrint('FileImportService: not a valid project JSON, falling back to raster test: $e');
        }
      }

      // 3. Process Raster Bitmap (PNG, JPG, WebP, GIF)
      // Preserves exact original dimensions and natural aspect ratio.
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final decodedImage = frame.image;

      final double width = decodedImage.width.toDouble();
      final double height = decodedImage.height.toDouble();

      final origin = targetCanvasPoint != null
          ? Offset(targetCanvasPoint.dx - width / 2, targetCanvasPoint.dy - height / 2)
          : Offset.zero;

      final imageShape = VectorShape(
        id: 'shape-img-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Image $fileName',
        type: ShapeType.image,
        rect: Rect.fromLTWH(origin.dx, origin.dy, width, height),
        imageBytes: bytes,
        decodedImage: decodedImage,
      );

      return ImportedFileResult(
        fileName: fileName,
        type: ImportedFileType.image,
        shapes: [imageShape],
      );
    } catch (e) {
      debugPrint('FileImportService error importing $fileName: $e');
      return ImportedFileResult.failure(
        fileName: fileName,
        errorMessage: 'Failed to decode $fileName: $e',
      );
    }
  }

  /// Imports a dropped [XFile] / [DropItem] by reading its byte stream.
  static Future<ImportedFileResult> importDropItem(
    XFile item, {
    Offset? targetCanvasPoint,
  }) async {
    try {
      final bytes = await item.readAsBytes();
      return await importFileFromBytes(
        fileName: item.name,
        bytes: bytes,
        targetCanvasPoint: targetCanvasPoint,
      );
    } catch (e) {
      return ImportedFileResult.failure(
        fileName: item.name,
        errorMessage: 'Could not read dropped file: $e',
      );
    }
  }

  /// Batch imports multiple dropped files concurrently with cascaded placement offsets.
  static Future<List<ImportedFileResult>> importDropItems(
    List<XFile> items, {
    Offset? targetCanvasPoint,
  }) async {
    final results = <ImportedFileResult>[];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      // Stagger position slightly for multi-file drops so elements do not overlap completely
      final staggeredPoint = targetCanvasPoint != null
          ? targetCanvasPoint + Offset(i * 32.0, i * 32.0)
          : null;

      final result = await importDropItem(
        item,
        targetCanvasPoint: staggeredPoint,
      );
      results.add(result);
    }

    return results;
  }
}
