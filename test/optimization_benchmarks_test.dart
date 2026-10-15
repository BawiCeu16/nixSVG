import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nixsvg/calculations/canvas_hit_test.dart';
import 'package:nixsvg/models/vector_shape.dart';
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
  });
}
