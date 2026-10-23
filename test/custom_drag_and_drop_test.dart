import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/models/project_model.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/services/file_import_service.dart';
import 'package:nixsvg/widgets/nix_file_drop_zone.dart';

Future<Uint8List> createTestPngBytes(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas =
      Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = Colors.green,
  );
  final picture = recorder.endRecording();
  final img = await picture.toImage(width, height);
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

void main() {
  group('FileImportService Tests', () {
    test('Imports SVG and centers/places at targetCanvasPoint', () async {
      const svgContent = '''
<svg width="200" height="100" xmlns="http://www.w3.org/2000/svg">
  <rect x="0" y="0" width="200" height="100" fill="#FF0000"/>
</svg>
''';
      final bytes = Uint8List.fromList(utf8.encode(svgContent));
      final result = await FileImportService.importFileFromBytes(
        fileName: 'test_graphic.svg',
        bytes: bytes,
        targetCanvasPoint: const Offset(400, 300),
      );

      expect(result.type, ImportedFileType.svg);
      expect(result.isSuccess, isTrue);
      expect(result.shapes, isNotEmpty);

      // Shapes should be positioned near target point (400, 300)
      final shape = result.shapes.first;
      expect(shape.rect.center.dx, closeTo(400, 10));
      expect(shape.rect.center.dy, closeTo(300, 10));
    });

    test('Imports raster PNG with exact original dimensions and target coordinates', () async {
      final bytes = await createTestPngBytes(640, 360);
      final result = await FileImportService.importFileFromBytes(
        fileName: 'preview.png',
        bytes: bytes,
        targetCanvasPoint: const Offset(500, 500),
      );

      expect(result.type, ImportedFileType.image);
      expect(result.isSuccess, isTrue);
      expect(result.shapes.length, 1);

      final shape = result.shapes.first;
      expect(shape.type, ShapeType.image);
      expect(shape.rect.width, 640.0);
      expect(shape.rect.height, 360.0);
      expect(shape.rect.center, const Offset(500, 500));
      expect(shape.decodedImage, isNotNull);
    });

    test('Imports JSON project file into ProjectModel', () async {
      final sampleProject = ProjectModel(
        id: 'imported-proj-1',
        name: 'Project Alpha',
        lastModified: DateTime.now(),
        shapes: [
          VectorShape(
            id: 's1',
            name: 'Rect 1',
            type: ShapeType.rectangle,
            rect: const Rect.fromLTWH(50, 50, 150, 100),
          ),
        ],
      );

      final jsonStr = jsonEncode(sampleProject.toJson());
      final bytes = Uint8List.fromList(utf8.encode(jsonStr));

      final result = await FileImportService.importFileFromBytes(
        fileName: 'project.nixsvg',
        bytes: bytes,
      );

      expect(result.type, ImportedFileType.project);
      expect(result.isSuccess, isTrue);
      expect(result.project, isNotNull);
      expect(result.project!.name, 'Project Alpha');
      expect(result.project!.shapes.length, 1);
    });

    test('Handles batch imports with cascaded offsets', () async {
      final png1 = await createTestPngBytes(100, 100);
      final png2 = await createTestPngBytes(150, 150);

      final results = await FileImportService.importDropItems(
        [
          XFile.fromData(png1, name: 'item1.png'),
          XFile.fromData(png2, name: 'item2.png'),
        ],
        targetCanvasPoint: const Offset(200, 200),
      );

      expect(results.length, 2);
      expect(results[0].shapes.first.rect.center, const Offset(200, 200));
      // Second item should have 32px staggered offset
      expect(results[1].shapes.first.rect.center, const Offset(232, 232));
    });

    test('Handles corrupted or unsupported files gracefully', () async {
      final invalidBytes = Uint8List.fromList([0, 1, 2, 3]);
      final result = await FileImportService.importFileFromBytes(
        fileName: 'unknown.xyz',
        bytes: invalidBytes,
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, isNotNull);
    });
  });

  group('NixFileDropZone Widget Tests', () {
    testWidgets('Renders child content normally when idle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NixFileDropZone(
              onFilesDropped: (files, offset) {},
              child: const Center(
                child: Text('Canvas Active', key: Key('canvas-child')),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('canvas-child')), findsOneWidget);
      expect(find.text('Drop files to import onto canvas'), findsNothing);
    });

    testWidgets('Drop overlay displays M3 Expressive indicators when active', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: NixFileDropZone(
              onFilesDropped: (files, offset) {},
              title: 'Release anywhere to place at cursor',
              child: const SizedBox.expand(
                child: Text('Underlying Canvas'),
              ),
            ),
          ),
        ),
      );

      // Inspect drop zone state
      final dropZoneFinder = find.byType(NixFileDropZone);
      expect(dropZoneFinder, findsOneWidget);

      final state = tester.state<NixFileDropZoneState>(dropZoneFinder);
      // Trigger dragging state manually on notifier to simulate hover
      state.isDraggingNotifier.value = true;
      await tester.pumpAndSettle();

      // Should now render the frosted drop target overlay
      expect(find.text('Release anywhere to place at cursor'), findsOneWidget);
      expect(find.text('SVG'), findsOneWidget);
      expect(find.text('PNG'), findsOneWidget);
      expect(find.text('JSON'), findsOneWidget);

      // Dismiss dragging state
      state.isDraggingNotifier.value = false;
      await tester.pumpAndSettle();

      expect(find.text('Release anywhere to place at cursor'), findsNothing);
    });
  });
}
