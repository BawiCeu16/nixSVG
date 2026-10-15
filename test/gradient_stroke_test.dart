import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/services/svg_export_service.dart';

void main() {
  group('Gradients, Stroke Styles & Opacity Tests', () {
    test('VectorShape defaults for stroke styles and opacity', () {
      final shape = VectorShape(
        id: 'shape-1',
        name: 'Default Shape',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(10, 10, 100, 100),
      );

      expect(shape.fillType, PaintFillType.solid);
      expect(shape.strokeType, PaintFillType.solid);
      expect(shape.strokeOpacity, 1.0);
      expect(shape.strokeStyle, StrokeStyle.solid);
      expect(shape.strokeDashLength, 8.0);
      expect(shape.strokeDashGap, 6.0);
    });

    test(
      'VectorShape copyWith & serialization with Linear and Radial Gradients',
      () {
        final gradient = ShapeGradient(
          type: PaintFillType.linearGradient,
          stops: const [
            GradientColorStop(offset: 0.0, color: Color(0xFF6366F1)),
            GradientColorStop(offset: 0.5, color: Color(0xFFA855F7)),
            GradientColorStop(offset: 1.0, color: Color(0xFFEC4899)),
          ],
          angle: 45.0,
        );

        final shape = VectorShape(
          id: 'shape-grad',
          name: 'Gradient Shape',
          type: ShapeType.ellipse,
          rect: const Rect.fromLTWH(0, 0, 200, 200),
          fillType: PaintFillType.linearGradient,
          fillGradient: gradient,
          strokeType: PaintFillType.radialGradient,
          strokeGradient: const ShapeGradient(
            type: PaintFillType.radialGradient,
            stops: [
              GradientColorStop(offset: 0.0, color: Color(0xFFFFFFFF)),
              GradientColorStop(offset: 1.0, color: Color(0xFF000000)),
            ],
          ),
          strokeOpacity: 0.75,
          strokeStyle: StrokeStyle.dashed,
          isStroked: true,
        );

        final json = shape.toJson();
        expect(json['fillType'], 'linearGradient');
        expect(json['strokeType'], 'radialGradient');
        expect(json['strokeOpacity'], 0.75);
        expect(json['strokeStyle'], 'dashed');

        final fromJson = VectorShape.fromJson(json);
        expect(fromJson.fillType, PaintFillType.linearGradient);
        expect(fromJson.fillGradient!.stops.length, 3);
        expect(fromJson.fillGradient!.angle, 45.0);
        expect(fromJson.strokeType, PaintFillType.radialGradient);
        expect(fromJson.strokeOpacity, 0.75);
        expect(fromJson.strokeStyle, StrokeStyle.dashed);
      },
    );

    test(
      'SvgExportService includes <defs> and gradient URLs for fill & stroke',
      () {
        final fillGrad = const ShapeGradient(
          type: PaintFillType.linearGradient,
          stops: [
            GradientColorStop(offset: 0.0, color: Color(0xFFFF0000)),
            GradientColorStop(offset: 1.0, color: Color(0xFF0000FF)),
          ],
          angle: 90.0,
        );

        final strokeGrad = const ShapeGradient(
          type: PaintFillType.radialGradient,
          stops: [
            GradientColorStop(offset: 0.0, color: Color(0xFF00FF00)),
            GradientColorStop(offset: 1.0, color: Color(0xFFFFFF00)),
          ],
        );

        final shape = VectorShape(
          id: 'svg-grad-1',
          name: 'Gradient Rect',
          type: ShapeType.rectangle,
          rect: const Rect.fromLTWH(50, 50, 200, 150),
          isFilled: true,
          fillType: PaintFillType.linearGradient,
          fillGradient: fillGrad,
          isStroked: true,
          strokeType: PaintFillType.radialGradient,
          strokeGradient: strokeGrad,
          strokeOpacity: 0.8,
          strokeStyle: StrokeStyle.dashed,
        );

        final svg = SvgExportService.generateSvg([shape]);

        expect(svg.contains('<defs>'), isTrue);
        expect(svg.contains('id="grad-svg-grad-1-fill"'), isTrue);
        expect(svg.contains('id="grad-svg-grad-1-stroke"'), isTrue);
        expect(svg.contains('fill="url(#grad-svg-grad-1-fill)"'), isTrue);
        expect(svg.contains('stroke="url(#grad-svg-grad-1-stroke)"'), isTrue);
        expect(svg.contains('stroke-opacity="0.8"'), isTrue);
        expect(svg.contains('stroke-dasharray='), isTrue);
      },
    );

    test('SvgExportService dotted stroke export', () {
      final shape = VectorShape(
        id: 'dotted-shape',
        name: 'Dotted Line',
        type: ShapeType.line,
        rect: const Rect.fromLTWH(0, 0, 100, 100),
        isStroked: true,
        strokeWidth: 4.0,
        strokeStyle: StrokeStyle.dotted,
        strokeOpacity: 0.5,
      );

      final svg = SvgExportService.generateSvg([shape]);
      expect(svg.contains('stroke-opacity="0.5"'), isTrue);
      expect(svg.contains('stroke-dasharray="4.0 6.0"'), isTrue);
    });

    test('VectorShape StrokeAlign inside, center, outside serialization', () {
      final shapeInside = VectorShape(
        id: 'align-test',
        name: 'Inside Align Rect',
        type: ShapeType.rectangle,
        rect: const Rect.fromLTWH(0, 0, 50, 50),
        strokeAlign: StrokeAlign.inside,
        strokeDashLength: 12.0,
        strokeDashGap: 4.0,
      );

      final json = shapeInside.toJson();
      expect(json['strokeAlign'], 'inside');
      expect(json['strokeDashLength'], 12.0);
      expect(json['strokeDashGap'], 4.0);

      final fromJson = VectorShape.fromJson(json);
      expect(fromJson.strokeAlign, StrokeAlign.inside);
      expect(fromJson.strokeDashLength, 12.0);
      expect(fromJson.strokeDashGap, 4.0);

      final shapeOutside = shapeInside.copyWith(
        strokeAlign: StrokeAlign.outside,
      );
      expect(shapeOutside.strokeAlign, StrokeAlign.outside);
    });
  });
}
