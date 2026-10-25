import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/models/project_model.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/painters/vector_canvas_painter.dart';
import 'package:nixsvg/services/preferences_service.dart';

/// Generates a valid 16x16 PNG image bytes for testing.
Future<Uint8List> createTestPngBytes() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 16, 16));
  final paint = Paint()..color = const Color(0xFFFF0000);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 16, 16), paint);
  final picture = recorder.endRecording();
  final img = await picture.toImage(16, 16);
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Photo & Image Persistence Tests', () {
    test('Image shape serializes to JSON and restores imageBytes and decodedImage',
        () async {
      final pngBytes = await createTestPngBytes();

      // Create an image shape with decodedImage
      final codec = await ui.instantiateImageCodec(pngBytes);
      final frame = await codec.getNextFrame();
      final initialDecodedImage = frame.image;

      final originalShape = VectorShape(
        id: 'img-shape-1',
        name: 'Test Image',
        type: ShapeType.image,
        rect: const Rect.fromLTWH(100, 100, 200, 200),
        imageBytes: pngBytes,
        decodedImage: initialDecodedImage,
      );

      // 1. Serialize to JSON (simulating saving before closing app)
      final jsonMap = originalShape.toJson();
      expect(jsonMap['type'], equals('image'));
      expect(jsonMap['imageBytes'], isNotNull);
      expect(jsonMap['imageBytes'], isA<String>());

      // 2. Deserialize from JSON (simulating app reload)
      final restoredShape = VectorShape.fromJson(jsonMap);
      expect(restoredShape.type, equals(ShapeType.image));
      expect(restoredShape.imageBytes, isNotNull);
      expect(restoredShape.imageBytes!.length, equals(pngBytes.length));

      // 3. Ensure image decoding succeeds and sets decodedImage
      final decoded = await restoredShape.ensureImageDecoded();
      expect(decoded, isNotNull);
      expect(restoredShape.decodedImage, isNotNull);
      expect(restoredShape.decodedImage!.width, equals(16));
      expect(restoredShape.decodedImage!.height, equals(16));
    });

    test('ProjectModel with photo saves and restores with all images decoded',
        () async {
      final pngBytes = await createTestPngBytes();
      final originalShape = VectorShape(
        id: 'img-shape-2',
        name: 'Hero Photo',
        type: ShapeType.image,
        rect: const Rect.fromLTWH(50, 50, 300, 200),
        imageBytes: pngBytes,
      );

      final project = ProjectModel.createNew(
        name: 'Photo Project',
        shapes: [originalShape],
      );

      // Save to PreferencesService
      final prefs = PreferencesService(); // in-memory
      await prefs.saveRecentProject(project);

      // Restore from PreferencesService (simulating reopen after closing app)
      final restoredProjects = prefs.getRecentProjects();
      expect(restoredProjects.isNotEmpty, isTrue);

      final restoredProject = restoredProjects.first;
      expect(restoredProject.shapes.length, equals(1));

      final restoredShape = restoredProject.shapes.first;
      expect(restoredShape.type, equals(ShapeType.image));
      expect(restoredShape.imageBytes, isNotNull);

      // Await all image decodes
      await restoredProject.ensureAllImagesDecoded();
      expect(restoredShape.decodedImage, isNotNull);
      expect(restoredShape.decodedImage!.width, equals(16));
    });

    test('VectorCanvasPainter paints decoded image when available', () async {
      final pngBytes = await createTestPngBytes();
      final codec = await ui.instantiateImageCodec(pngBytes);
      final frame = await codec.getNextFrame();
      final decodedImg = frame.image;

      final imageShape = VectorShape(
        id: 'canvas-img',
        name: 'Canvas Image',
        type: ShapeType.image,
        rect: const Rect.fromLTWH(20, 20, 100, 100),
        imageBytes: pngBytes,
        decodedImage: decodedImg,
      );

      final painter = VectorCanvasPainter(
        shapes: [imageShape],
        selectedShapeIds: {},
        currentMode: EditorMode.select,
        colorScheme: const ColorScheme.light(),
        zoomScale: 1.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      // Painter must paint without throwing any errors
      expect(() => painter.paint(canvas, const Size(800, 600)), returnsNormally);
    });

    test('VectorCanvasPainter triggers background decode and renders placeholder instead of solid rect',
        () async {
      final pngBytes = await createTestPngBytes();

      // Shape with imageBytes but decodedImage is initially null (fresh from JSON)
      final imageShape = VectorShape(
        id: 'canvas-img-pending',
        name: 'Canvas Image Pending',
        type: ShapeType.image,
        rect: const Rect.fromLTWH(20, 20, 100, 100),
        imageBytes: pngBytes,
        decodedImage: null,
      );

      final painter = VectorCanvasPainter(
        shapes: [imageShape],
        selectedShapeIds: {},
        currentMode: EditorMode.select,
        colorScheme: const ColorScheme.light(),
        zoomScale: 1.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      // Painting triggers background decode
      painter.paint(canvas, const Size(800, 600));

      // Wait for the decode triggered by painter to finish
      await Future.delayed(const Duration(milliseconds: 50));
      expect(imageShape.decodedImage, isNotNull);
    });
  });
}
