import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/calculations/canvas_geometry.dart';
import 'package:nixsvg/calculations/canvas_hit_test.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/widgets/properties_sidebar.dart';

void main() {
  group('Star Points & Ratio Geometry Tests', () {
    test('createStarPath generates valid path with default 5 points and 0.4 ratio', () {
      const rect = Rect.fromLTWH(0, 0, 100, 100);
      final path = CanvasGeometry.createStarPath(rect);
      expect(path, isNotNull);
      final bounds = path.getBounds();
      expect(bounds.width, closeTo(95.1, 1.0));
      expect(bounds.height, closeTo(90.5, 1.0));
    });

    test('createStarPath respects custom point counts (3, 6, 8, 12)', () {
      const rect = Rect.fromLTWH(0, 0, 100, 100);
      for (final pts in [3, 4, 6, 8, 12]) {
        final path = CanvasGeometry.createStarPath(rect, points: pts);
        expect(path, isNotNull);
        final bounds = path.getBounds();
        expect(bounds.isEmpty, isFalse);
      }
    });

    test('createStarPath respects custom innerRadiusRatio and cornerRadius fillets', () {
      const rect = Rect.fromLTWH(0, 0, 200, 200);
      // Sharp star
      final sharpPath = CanvasGeometry.createStarPath(
        rect,
        points: 5,
        innerRadiusRatio: 0.3,
        cornerRadius: 0.0,
      );
      // Rounded star with fillet
      final roundedPath = CanvasGeometry.createStarPath(
        rect,
        points: 5,
        innerRadiusRatio: 0.3,
        cornerRadius: 15.0,
      );

      expect(sharpPath.getBounds().isEmpty, isFalse);
      expect(roundedPath.getBounds().isEmpty, isFalse);

      // SVG path exports
      final sharpSvg = CanvasGeometry.generateStarPointsSvg(
        rect,
        points: 5,
        innerRadiusRatio: 0.3,
      );
      expect(sharpSvg, contains(','));
      expect(sharpSvg.split(' ').length, 10); // 5 points * 2 vertices

      final roundedSvg = CanvasGeometry.generateStarSvgPathData(
        rect,
        points: 5,
        innerRadiusRatio: 0.3,
        cornerRadius: 15.0,
      );
      expect(roundedSvg.startsWith('M'), isTrue);
      expect(roundedSvg.contains('Q'), isTrue);
      expect(roundedSvg.endsWith('Z'), isTrue);
    });
  });

  group('VectorShape Star & Radius Features', () {
    test('VectorShape stores and copies pointCount and innerRadiusRatio', () {
      final star = VectorShape(
        id: 'star-1',
        name: 'Star 1',
        type: ShapeType.star,
        rect: const Rect.fromLTWH(50, 50, 120, 120),
        pointCount: 7,
        innerRadiusRatio: 0.55,
        cornerRadius: 8.0,
      );

      expect(star.pointCount, 7);
      expect(star.innerRadiusRatio, 0.55);
      expect(star.cornerRadius, 8.0);

      final updated = star.copyWith(pointCount: 9, innerRadiusRatio: 0.6);
      expect(updated.pointCount, 9);
      expect(updated.innerRadiusRatio, 0.6);
      expect(updated.cornerRadius, 8.0);

      final json = star.toJson();
      expect(json['pointCount'], 7);
      expect(json['innerRadiusRatio'], 0.55);
      expect(json['cornerRadius'], 8.0);

      final deserialized = VectorShape.fromJson(json);
      expect(deserialized.pointCount, 7);
      expect(deserialized.innerRadiusRatio, 0.55);
      expect(deserialized.cornerRadius, 8.0);
    });

    test('All elements (rectangle, image, star) can have cornerRadius', () {
      final rect = VectorShape(
        id: 'rect-1',
        name: 'Rect',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(0, 0, 100, 100),
        cornerRadius: 16.0,
      );
      expect(rect.cornerRadius, 16.0);
      final rectPath = rect.getPath();
      expect(rectPath.getBounds().width, closeTo(100, 0.1));

      final img = VectorShape(
        id: 'img-1',
        name: 'Img',
        type: ShapeType.image,
        rect: const Rect.fromLTWH(0, 0, 200, 150),
        cornerRadius: 12.0,
      );
      expect(img.cornerRadius, 12.0);
      final imgPath = img.getPath();
      expect(imgPath.getBounds().width, closeTo(200, 0.1));

      final star = VectorShape(
        id: 'star-1',
        name: 'Star',
        type: ShapeType.star,
        rect: const Rect.fromLTWH(0, 0, 100, 100),
        cornerRadius: 10.0,
      );
      expect(star.cornerRadius, 10.0);
      final starPath = star.getPath();
      expect(starPath.getBounds().width, closeTo(95.1, 1.0));
    });

    test('CanvasHitTester provides radius handle for star and image', () {
      final star = VectorShape(
        id: 'star-1',
        name: 'Star',
        type: ShapeType.star,
        rect: const Rect.fromLTWH(100, 100, 200, 200),
        cornerRadius: 10.0,
      );
      final starHandles = CanvasHitTester.getRadiusHandlePositions(star);
      expect(starHandles.containsKey(ResizeHandle.radiusTopLeft), isTrue);

      final img = VectorShape(
        id: 'img-1',
        name: 'Image',
        type: ShapeType.image,
        rect: const Rect.fromLTWH(100, 100, 200, 200),
        cornerRadius: 10.0,
      );
      final imgHandles = CanvasHitTester.getRadiusHandlePositions(img);
      expect(imgHandles.length, 4);
    });

    test('SVG export formats rounded star and rounded rectangle properly', () {
      final roundedStar = VectorShape(
        id: 'star-svg',
        name: 'Star SVG',
        type: ShapeType.star,
        rect: const Rect.fromLTWH(0, 0, 100, 100),
        pointCount: 6,
        innerRadiusRatio: 0.45,
        cornerRadius: 8.0,
      );
      final starSvg = roundedStar.toSvgElement();
      expect(starSvg, contains('<path d="M'));

      final roundedRect = VectorShape(
        id: 'rect-svg',
        name: 'Rect SVG',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(0, 0, 100, 100),
        cornerRadius: 14.0,
      );
      final rectSvg = roundedRect.toSvgElement();
      expect(rectSvg, contains('rx="14.0"'));
    });
  });

  group('PropertiesSidebar Controls for Star & Radius', () {
    testWidgets('Shows R and Star Properties for Star element', (tester) async {
      final star = VectorShape(
        id: 'star-widget',
        name: 'Star',
        type: ShapeType.star,
        rect: const Rect.fromLTWH(100, 100, 200, 200),
        pointCount: 5,
        innerRadiusRatio: 0.4,
        cornerRadius: 0.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertiesSidebar(
              selectedShape: star,
              onShapeChanged: (_) {},
              onOpenColorPickerFill: ([_]) {},
              onOpenColorPickerStroke: ([_]) {},
              onDuplicateShape: () {},
              onDeleteSelected: () {},
              onAlignShape: (_) {},
              totalShapesCount: 1,
              zoomScale: 1.0,
              isPanMode: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify 'R' field is present for Star
      expect(find.text('R'), findsOneWidget);

      // Verify 'STAR' section is present
      expect(find.text('STAR'), findsOneWidget);
      expect(find.text('PTS'), findsOneWidget);
      expect(find.text('5 Points'), findsOneWidget);
      expect(find.text('Ratio'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
    });

    testWidgets('Shows R and independent corners button for Rectangle', (tester) async {
      final rect = VectorShape(
        id: 'rect-widget',
        name: 'Rect',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(100, 100, 200, 200),
        cornerRadius: 0.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertiesSidebar(
              selectedShape: rect,
              onShapeChanged: (_) {},
              onOpenColorPickerFill: ([_]) {},
              onOpenColorPickerStroke: ([_]) {},
              onDuplicateShape: () {},
              onDeleteSelected: () {},
              onAlignShape: (_) {},
              totalShapesCount: 1,
              zoomScale: 1.0,
              isPanMode: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify 'R' field is present for Rectangle
      expect(find.text('R'), findsOneWidget);
      // Independent corners button tooltip message present
      expect(find.byTooltip('Independent Corner Radii'), findsOneWidget);
    });
  });
}
