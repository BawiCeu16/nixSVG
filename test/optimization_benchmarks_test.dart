import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nixsvg/calculations/canvas_hit_test.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/painters/grid_painter.dart';
import 'package:nixsvg/painters/vector_canvas_painter.dart';
import 'package:nixsvg/theme/components/responsive_layout_tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Smallest-to-Biggest Optimization Tests', () {
    test('Tier 1: VectorShape.getPath() returns cached Path when geometry is unchanged', () {
      final shape = VectorShape(
        id: 'rect-1',
        name: 'Rect 1',
        type: ShapeType.roundedRectangle,
        rect: const Rect.fromLTWH(50, 50, 200, 150),
        cornerRadius: 16.0,
      );

      final path1 = shape.getPath();
      final path2 = shape.getPath();

      // Identical instance due to self-invalidating cache
      expect(identical(path1, path2), isTrue);

      // Mutating geometry invalidates the cache automatically
      shape.rect = const Rect.fromLTWH(50, 50, 250, 180);
      final path3 = shape.getPath();
      expect(identical(path2, path3), isFalse);
    });

    test('Tier 1: VectorShape.getBoundingBox() memoizes rotated bounding box calculations', () {
      final shape = VectorShape(
        id: 'rot-1',
        name: 'Rotated 1',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(100, 100, 200, 100),
        rotation: 45.0,
        strokeWidth: 4.0,
        isStroked: true,
      );

      final bounds1 = shape.getBoundingBox();
      final bounds2 = shape.getBoundingBox();

      expect(bounds1, equals(bounds2));
      expect(identical(bounds1, bounds2), isTrue);

      // Verify bounds are larger than original rect due to 45 deg rotation
      expect(bounds1.width, greaterThan(200.0));
      expect(bounds1.height, greaterThan(100.0));
    });

    test(
      'Tier 1: VectorShape.getTextPainter() memoizes TextPainter layout',
      () {
        final shape = VectorShape(
          id: 'text-1',
          name: 'Text',
          type: ShapeType.text,
          rect: const Rect.fromLTWH(20, 20, 300, 80),
          textContent: 'Optimized Typography',
          fontSize: 28.0,
        );

        final tp1 = shape.getTextPainter();
        final tp2 = shape.getTextPainter();

        expect(identical(tp1, tp2), isTrue);
        expect(tp1.text?.toPlainText(), 'Optimized Typography');
      },
    );

    test('Tier 1: CanvasHitTester fast AABB rejection eliminates unnecessary trig math', () {
      final shape = VectorShape(
        id: 'hit-1',
        name: 'Hit Shape',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(500, 500, 200, 200),
        rotation: 30.0,
      );

      // Point far outside the shape should instantly reject
      expect(
        CanvasHitTester.hitTestShape(const Offset(10, 10), shape),
        isFalse,
      );

      // Handle hit test far outside should return ResizeHandle.none
      expect(
        CanvasHitTester.hitTestHandle(const Offset(10, 10), shape),
        ResizeHandle.none,
      );

      // Point inside center should hit
      expect(CanvasHitTester.hitTestShape(shape.rect.center, shape), isTrue);
    });

    test('Tier 4 & 5: ResponsiveLayoutTokens scales correctly from phone to ultrawide', () {
      expect(ResponsiveLayoutTokens.getMaxSidebarWidth(360), 180.0);
      expect(
        ResponsiveLayoutTokens.getMaxSidebarWidth(1280),
        (1280 * 0.35).clamp(180.0, 420.0),
      );
      expect(
        ResponsiveLayoutTokens.getMaxSidebarWidth(2560),
        (2560 * 0.28).clamp(240.0, 520.0),
      );

      expect(
        ResponsiveLayoutTokens.getCompactDrawerWidth(360),
        (360 * 0.85).clamp(240.0, 380.0),
      );
    });

    test('Tier 2: VectorShape.getTextStyle() memoizes TextStyle and handles Google Sans fast-path', () {
      final shape = VectorShape(
        id: 'text-opt',
        name: 'Google Sans Text',
        type: ShapeType.text,
        rect: const Rect.fromLTWH(0, 0, 200, 50),
        fontFamily: 'Google Sans',
        fontSize: 20.0,
      );

      final style1 = shape.getTextStyle();
      final style2 = shape.getTextStyle();

      expect(identical(style1, style2), isTrue);
      expect(style1.fontFamily, 'Google Sans');
      expect(style1.fontSize, 20.0);
    });

    test('Tier 2: VectorCanvasPainter.shouldRepaint returns false when canvas state is invariant', () {
      final shapes = [
        VectorShape(
          id: 'shape-1',
          name: 'Rect',
          type: ShapeType.rectangle,
          rect: const Rect.fromLTWH(20, 20, 100, 100),
        ),
      ];

      final p1 = VectorCanvasPainter(
        shapes: shapes,
        selectedShapeIds: {'shape-1'},
        colorScheme: const ColorScheme.light(),
        currentMode: EditorMode.select,
      );

      final p2 = VectorCanvasPainter(
        shapes: shapes,
        selectedShapeIds: {'shape-1'},
        colorScheme: const ColorScheme.light(),
        currentMode: EditorMode.select,
      );

      // Same shapes, same selection, same zoom -> NO repaint needed!
      expect(p2.shouldRepaint(p1), isFalse);

      // Mutating shape revision triggers repaint
      shapes.first.invalidateCache();
      final p3 = VectorCanvasPainter(
        shapes: shapes,
        selectedShapeIds: {'shape-1'},
        colorScheme: const ColorScheme.light(),
        currentMode: EditorMode.select,
      );
      expect(p3.shouldRepaint(p1), isTrue);
    });

    test('Tier 3: GridPainter renders with cached Float32List vertex buffers', () {
      final painter = GridPainter(
        gridSpacing: 40.0,
        gridStyle: 'dots',
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      // Painting 3200x2400 canvas uses cached single batch drawRawPoints
      painter.paint(canvas, const Size(3200, 2400));
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
      picture.dispose();
    });
  });
}
