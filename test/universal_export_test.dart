import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/services/svg_export_service.dart';
import 'package:nixsvg/services/vector_export_service.dart';
import 'package:nixsvg/widgets/export_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleShapes = [
    VectorShape(
      id: 'rect_1',
      name: 'Blue Rectangle',
      type: ShapeType.rectangle,
      rect: const Rect.fromLTWH(50, 60, 200, 100),
      fillColor: const Color(0xFF2196F3),
      strokeColor: const Color(0xFF0D47A1),
      strokeWidth: 2.0,
      cornerRadius: 12.0,
    ),
    VectorShape(
      id: 'circle_2',
      name: 'Red Circle',
      type: ShapeType.ellipse,
      rect: const Rect.fromLTWH(300, 200, 150, 150),
      fillColor: const Color(0xFFF44336),
    ),
  ];

  group('VectorExportService Universal Export Tests', () {
    test('Exports valid SVG format', () async {
      final bytes = await VectorExportService.exportToBytes(
        shapes: sampleShapes,
        format: ExportFormat.svg,
        canvasSize: const Size(1920, 1080),
        scope: SvgExportScope.canvas,
      );

      final svgString = utf8.decode(bytes);
      expect(svgString, contains('<svg'));
      expect(svgString, contains('</svg>'));
      expect(svgString, contains('<rect'));
      expect(svgString, contains('<ellipse'));
    });

    test('Exports valid PNG format with magic bytes', () async {
      final bytes = await VectorExportService.exportToBytes(
        shapes: sampleShapes,
        format: ExportFormat.png,
        canvasSize: const Size(800, 600),
        scope: SvgExportScope.artwork,
        exportScale: 1.0,
      );

      expect(bytes.length, greaterThan(8));
      // PNG signature: 0x89 0x50 0x4E 0x47 0x0D 0x0A 0x1A 0x0A
      expect(bytes[0], equals(0x89));
      expect(bytes[1], equals(0x50)); // 'P'
      expect(bytes[2], equals(0x4E)); // 'N'
      expect(bytes[3], equals(0x47)); // 'G'
    });

    test('Exports valid JPEG format with magic bytes', () async {
      final bytes = await VectorExportService.exportToBytes(
        shapes: sampleShapes,
        format: ExportFormat.jpeg,
        canvasSize: const Size(800, 600),
        scope: SvgExportScope.artwork,
        jpegQuality: 0.85,
      );

      expect(bytes.length, greaterThan(4));
      // JPEG SOI marker: 0xFF 0xD8 0xFF
      expect(bytes[0], equals(0xFF));
      expect(bytes[1], equals(0xD8));
      expect(bytes[2], equals(0xFF));
    });

    test('Exports valid PDF format with magic bytes', () async {
      final bytes = await VectorExportService.exportToBytes(
        shapes: sampleShapes,
        format: ExportFormat.pdf,
        canvasSize: const Size(800, 600),
        scope: SvgExportScope.canvas,
      );

      expect(bytes.length, greaterThan(5));
      // PDF signature: %PDF-
      final header = String.fromCharCodes(bytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('PNG 2x scaling produces larger raster output than 1x', () async {
      final bytes1x = await VectorExportService.exportToBytes(
        shapes: sampleShapes,
        format: ExportFormat.png,
        scope: SvgExportScope.artwork,
        exportScale: 1.0,
      );

      final bytes2x = await VectorExportService.exportToBytes(
        shapes: sampleShapes,
        format: ExportFormat.png,
        scope: SvgExportScope.artwork,
        exportScale: 2.0,
      );

      expect(bytes2x.length, greaterThan(bytes1x.length));
    });

    test('Selection scope correctly bounds only selected shapes', () async {
      final bounds = VectorExportService.computeExportScopeRect(
        shapes: sampleShapes,
        scope: SvgExportScope.selection,
        selectedShapeIds: {'rect_1'},
        canvasSize: const Size(1920, 1080),
      );

      expect(bounds.left, equals(50.0));
      expect(bounds.top, equals(60.0));
      expect(bounds.width, equals(200.0));
      expect(bounds.height, equals(100.0));
    });
  });

  group('ExportDialog Widget Tests', () {
    testWidgets('Renders format tabs (.png, .jpeg, .svg, .pdf) and switches formats', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: ExportDialog(
              shapes: sampleShapes,
              selectedShapeIds: const {'rect_1'},
              canvasSize: const Size(1920, 1080),
              fileName: 'test_graphic.svg',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Check format options exist
      expect(find.text('PNG'), findsWidgets);
      expect(find.text('JPEG'), findsWidgets);
      expect(find.text('SVG'), findsWidgets);
      expect(find.text('PDF'), findsWidgets);

      // Check scale options exist
      expect(find.text('1x'), findsOneWidget);
      expect(find.text('2x'), findsOneWidget);
      expect(find.text('3x'), findsOneWidget);
      expect(find.text('4x'), findsOneWidget);

      // Switch to JPEG
      await tester.tap(find.text('JPEG'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Quality'), findsOneWidget);
      expect(find.text('.jpeg'), findsOneWidget);

      // Switch to SVG
      await tester.tap(find.text('SVG'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('XML Header'), findsOneWidget);
      expect(find.text('.svg'), findsOneWidget);
      expect(find.text('Copy SVG'), findsOneWidget);

      // Switch to PDF
      await tester.tap(find.text('PDF'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('.pdf'), findsOneWidget);
      expect(find.text('Export PDF'), findsOneWidget);
    });
  });
}
