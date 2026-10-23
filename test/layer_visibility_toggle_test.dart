import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:nixsvg/painters/vector_canvas_painter.dart';

void main() {
  group('Layer Visibility & Lock Toggle Tests', () {
    test('setVisible and setLocked increment revision and clear caches', () {
      final shape = VectorShape(
        id: 'rect-1',
        name: 'Rectangle 1',
        rect: const Rect.fromLTWH(20, 20, 100, 100),
        type: ShapeType.rectangle,
      );

      final initialRevision = shape.revision;
      expect(shape.isVisible, isTrue);

      shape.setVisible(false);
      expect(shape.isVisible, isFalse);
      expect(shape.revision, greaterThan(initialRevision));

      final intermediateRevision = shape.revision;
      shape.setLocked(true);
      expect(shape.isLocked, isTrue);
      expect(shape.revision, greaterThan(intermediateRevision));
    });

    test('VectorCanvasPainter.shouldRepaint returns true when layer visibility changes', () {
      final shape = VectorShape(
        id: 'shape-1',
        name: 'Circle',
        rect: const Rect.fromLTWH(50, 50, 80, 80),
        type: ShapeType.ellipse,
      );

      final shapes = [shape];
      const colorScheme = ColorScheme.light();

      final painter1 = VectorCanvasPainter(
        shapes: shapes,
        selectedShapeIds: {'shape-1'},
        colorScheme: colorScheme,
        currentMode: EditorMode.select,
      );

      // Mutate visibility via setVisible
      shape.setVisible(false);

      final painter2 = VectorCanvasPainter(
        shapes: shapes,
        selectedShapeIds: {},
        colorScheme: colorScheme,
        currentMode: EditorMode.select,
      );

      expect(painter2.shapesRevision, isNot(equals(painter1.shapesRevision)));
      expect(painter2.shouldRepaint(painter1), isTrue);
    });

    test('VectorCanvasPainter.shouldRepaint returns true when layer lock changes', () {
      final shape = VectorShape(
        id: 'shape-2',
        name: 'Star',
        rect: const Rect.fromLTWH(100, 100, 120, 120),
        type: ShapeType.star,
      );

      final shapes = [shape];
      const colorScheme = ColorScheme.dark();

      final painter1 = VectorCanvasPainter(
        shapes: shapes,
        selectedShapeIds: {'shape-2'},
        colorScheme: colorScheme,
        currentMode: EditorMode.select,
      );

      // Mutate lock via setLocked
      shape.setLocked(true);

      final painter2 = VectorCanvasPainter(
        shapes: shapes,
        selectedShapeIds: {'shape-2'},
        colorScheme: colorScheme,
        currentMode: EditorMode.select,
      );

      expect(painter2.shapesRevision, isNot(equals(painter1.shapesRevision)));
      expect(painter2.shouldRepaint(painter1), isTrue);
    });

    test('VectorCanvasPainter.shouldRepaint detects layer reordering', () {
      final s1 = VectorShape(
        id: 's-1',
        name: 'Layer 1',
        rect: const Rect.fromLTWH(10, 10, 50, 50),
        type: ShapeType.rectangle,
      );
      final s2 = VectorShape(
        id: 's-2',
        name: 'Layer 2',
        rect: const Rect.fromLTWH(40, 40, 50, 50),
        type: ShapeType.rectangle,
      );

      const colorScheme = ColorScheme.light();

      final painterOriginal = VectorCanvasPainter(
        shapes: [s1, s2],
        selectedShapeIds: {},
        colorScheme: colorScheme,
        currentMode: EditorMode.select,
      );

      final painterReordered = VectorCanvasPainter(
        shapes: [s2, s1],
        selectedShapeIds: {},
        colorScheme: colorScheme,
        currentMode: EditorMode.select,
      );

      expect(painterReordered.shapesRevision, isNot(equals(painterOriginal.shapesRevision)));
      expect(painterReordered.shouldRepaint(painterOriginal), isTrue);
    });
  });
}
