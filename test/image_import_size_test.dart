import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/models/vector_shape.dart';

Future<Uint8List> createTestPngBytes(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas =
      Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = Colors.blue,
  );
  final picture = recorder.endRecording();
  final img = await picture.toImage(width, height);
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

void main() {
  group('Image Import Original Size Tests', () {
    test('Raster image decoding accurately preserves non-square 16:9 dimensions', () async {
      const originalWidth = 1920;
      const originalHeight = 1080;

      final bytes = await createTestPngBytes(originalWidth, originalHeight);
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final decodedImage = frame.image;

      final double width = decodedImage.width.toDouble();
      final double height = decodedImage.height.toDouble();

      expect(width, 1920.0);
      expect(height, 1080.0);
      expect(width == height, isFalse);

      final shape = VectorShape(
        id: 'test-image',
        name: 'Test Image',
        type: ShapeType.image,
        rect: Rect.fromLTWH(0, 0, width, height),
        imageBytes: bytes,
        decodedImage: decodedImage,
      );

      expect(shape.rect.width, 1920.0);
      expect(shape.rect.height, 1080.0);
      expect(shape.rect.size.aspectRatio, closeTo(1920 / 1080, 0.001));
    });

    test('Raster image decoding accurately preserves non-square portrait dimensions', () async {
      const originalWidth = 450;
      const originalHeight = 1200;

      final bytes = await createTestPngBytes(originalWidth, originalHeight);
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final decodedImage = frame.image;

      final double width = decodedImage.width.toDouble();
      final double height = decodedImage.height.toDouble();

      expect(width, 450.0);
      expect(height, 1200.0);
      expect(width == height, isFalse);

      final shape = VectorShape(
        id: 'test-image-portrait',
        name: 'Test Portrait Image',
        type: ShapeType.image,
        rect: Rect.fromLTWH(100, 100, width, height),
        imageBytes: bytes,
        decodedImage: decodedImage,
      );

      expect(shape.rect.width, 450.0);
      expect(shape.rect.height, 1200.0);
    });
  });
}
