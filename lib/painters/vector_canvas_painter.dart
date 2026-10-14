import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nixsvg/models/vector_shape.dart';

class VectorCanvasPainter extends CustomPainter {
  final List<VectorShape> shapes;
  final Set<String> selectedShapeIds;
  final Offset? draftStartPoint;
  final Offset? draftCurrentPoint;
  final ShapeType? draftShapeType;
  final Rect? marqueeRect;
  final EditorMode currentMode;
  final Offset? snapGuidelineX;
  final Offset? snapGuidelineY;
  final ColorScheme colorScheme;

  VectorCanvasPainter({
    required this.shapes,
    required this.selectedShapeIds,
    this.draftStartPoint,
    this.draftCurrentPoint,
    this.draftShapeType,
    this.marqueeRect,
    required this.currentMode,
    this.snapGuidelineX,
    this.snapGuidelineY,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw existing vector shapes
    for (final shape in shapes) {
      if (!shape.isVisible) continue;
      _drawShape(canvas, shape);
    }

    // 2. Draw selection overlays for selected shapes
    if (selectedShapeIds.length > 1) {
      Rect? combinedBounds;
      for (final shape in shapes) {
        if (selectedShapeIds.contains(shape.id) && shape.isVisible) {
          _drawIndividualSelectionOutline(canvas, shape);
          combinedBounds = combinedBounds == null
              ? shape.rect
              : combinedBounds.expandToInclude(shape.rect);
        }
      }
      if (combinedBounds != null) {
        _drawMultiSelectionBoundingBox(canvas, combinedBounds);
      }
    } else {
      for (final shape in shapes) {
        if (selectedShapeIds.contains(shape.id) && shape.isVisible) {
          _drawSelectionBox(canvas, shape);
        }
      }
    }

    // 3. Draw draft shape being created
    if (draftStartPoint != null && draftCurrentPoint != null && draftShapeType != null) {
      final draftRect = draftShapeType == ShapeType.line
          ? Rect.fromLTRB(
              draftStartPoint!.dx,
              draftStartPoint!.dy,
              draftCurrentPoint!.dx,
              draftCurrentPoint!.dy,
            )
          : Rect.fromPoints(draftStartPoint!, draftCurrentPoint!);
      _drawDraftShape(canvas, draftRect, draftShapeType!);
      _drawDimensionBadge(canvas, draftRect);
    }


    // 4. Draw marquee selection box if dragging marquee
    if (marqueeRect != null) {
      final marqueePaint = Paint()
        ..color = colorScheme.primaryContainer.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      final marqueeBorder = Paint()
        ..color = colorScheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawRect(marqueeRect!, marqueePaint);
      canvas.drawRect(marqueeRect!, marqueeBorder);
    }

    // 5. Draw snap guidelines
    if (snapGuidelineX != null) {
      final snapPaint = Paint()
        ..color = colorScheme.tertiary
        ..strokeWidth = 1.2;
      canvas.drawLine(snapGuidelineX!, Offset(snapGuidelineX!.dx, size.height), snapPaint);
    }
    if (snapGuidelineY != null) {
      final snapPaint = Paint()
        ..color = colorScheme.tertiary
        ..strokeWidth = 1.2;
      canvas.drawLine(snapGuidelineY!, Offset(size.width, snapGuidelineY!.dy), snapPaint);
    }
  }

  void _drawShape(Canvas canvas, VectorShape shape) {
    canvas.save();

    final center = shape.rect.center;
    if (shape.rotation != 0.0) {
      canvas.translate(center.dx, center.dy);
      canvas.rotate(shape.rotation * math.pi / 180.0);
      canvas.translate(-center.dx, -center.dy);
    }

    final fillPaint = Paint()
      ..color = shape.fillColor.withValues(alpha: shape.fillOpacity)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = shape.strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = shape.strokeWidth;

    switch (shape.type) {
      case ShapeType.rectangle:
        if (shape.isFilled) canvas.drawRect(shape.rect, fillPaint);
        if (shape.isStroked) canvas.drawRect(shape.rect, strokePaint);
        break;

      case ShapeType.roundedRectangle:
        final rrect = RRect.fromRectAndRadius(shape.rect, Radius.circular(shape.cornerRadius));
        if (shape.isFilled) canvas.drawRRect(rrect, fillPaint);
        if (shape.isStroked) canvas.drawRRect(rrect, strokePaint);
        break;

      case ShapeType.ellipse:
        if (shape.isFilled) canvas.drawOval(shape.rect, fillPaint);
        if (shape.isStroked) canvas.drawOval(shape.rect, strokePaint);
        break;

      case ShapeType.line:
        if (!shape.isStroked) break;

        final linePaint = Paint()
          ..color = shape.strokeColor
          ..strokeWidth = shape.strokeWidth
          ..strokeCap = shape.strokeCap
          ..style = PaintingStyle.stroke;
        final p1 = shape.rect.topLeft;
        final p2 = shape.rect.bottomRight;

        if (shape.isCurved || shape.curvature != 0.0) {
          final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
          final dx = p2.dx - p1.dx;
          final dy = p2.dy - p1.dy;
          final len = math.sqrt(dx * dx + dy * dy);
          final perp = len > 0 ? Offset(-dy / len, dx / len) : Offset.zero;
          final controlPt = mid + perp * shape.curvature;

          final path = Path()
            ..moveTo(p1.dx, p1.dy)
            ..quadraticBezierTo(controlPt.dx, controlPt.dy, p2.dx, p2.dy);
          canvas.drawPath(path, linePaint);

          _drawLineCapMarker(canvas, p1, controlPt, shape.startCap, shape);
          _drawLineCapMarker(canvas, p2, controlPt, shape.endCap, shape);
        } else {
          canvas.drawLine(p1, p2, linePaint);
          _drawLineCapMarker(canvas, p1, p2, shape.startCap, shape);
          _drawLineCapMarker(canvas, p2, p1, shape.endCap, shape);
        }
        break;

      case ShapeType.star:
        final path = _generateStarPath(shape.rect);
        if (shape.isFilled) canvas.drawPath(path, fillPaint);
        if (shape.isStroked) canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.text:
        String displayText = shape.textContent;
        switch (shape.textCase) {
          case TextCase.uppercase:
            displayText = displayText.toUpperCase();
            break;
          case TextCase.lowercase:
            displayText = displayText.toLowerCase();
            break;
          case TextCase.titleCase:
            displayText = _toTitleCase(displayText);
            break;
          case TextCase.original:
            break;
        }

        final textDecorations = <TextDecoration>[];
        if (shape.isUnderline) textDecorations.add(TextDecoration.underline);
        if (shape.isStrikethrough) textDecorations.add(TextDecoration.lineThrough);
        final decoration = textDecorations.isNotEmpty
            ? TextDecoration.combine(textDecorations)
            : TextDecoration.none;

        final textColor = shape.fillColor.withValues(alpha: shape.fillOpacity);
        TextStyle textStyle;
        try {
          textStyle = GoogleFonts.getFont(
            shape.fontFamily,
            color: textColor,
            fontSize: shape.fontSize,
            fontWeight: shape.fontWeight,
            fontStyle: shape.isItalic ? FontStyle.italic : FontStyle.normal,
            letterSpacing: shape.letterSpacing != 0.0 ? shape.letterSpacing : null,
            height: shape.lineHeight,
            decoration: decoration,
            decorationColor: textColor,
          );
        } catch (_) {
          textStyle = TextStyle(
            color: textColor,
            fontSize: shape.fontSize,
            fontWeight: shape.fontWeight,
            fontStyle: shape.isItalic ? FontStyle.italic : FontStyle.normal,
            fontFamily: shape.fontFamily,
            letterSpacing: shape.letterSpacing != 0.0 ? shape.letterSpacing : null,
            height: shape.lineHeight,
            decoration: decoration,
            decorationColor: textColor,
          );
        }

        final textSpan = TextSpan(text: displayText, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textAlign: shape.textAlign,
          textDirection: TextDirection.ltr,
        );
        final layoutWidth = math.max(10.0, shape.rect.width);
        textPainter.layout(minWidth: layoutWidth, maxWidth: layoutWidth);

        // Vertical alignment calculation within shape.rect
        double offsetY = shape.rect.top;
        if (shape.textVerticalAlign == TextVerticalAlign.center) {
          offsetY = shape.rect.top + math.max(0.0, (shape.rect.height - textPainter.height) / 2);
        } else if (shape.textVerticalAlign == TextVerticalAlign.bottom) {
          offsetY = shape.rect.top + math.max(0.0, shape.rect.height - textPainter.height);
        }

        textPainter.paint(canvas, Offset(shape.rect.left, offsetY));
        break;

      case ShapeType.image:
        if (shape.decodedImage != null) {
          final srcRect = Rect.fromLTWH(
            0,
            0,
            shape.decodedImage!.width.toDouble(),
            shape.decodedImage!.height.toDouble(),
          );
          canvas.drawImageRect(shape.decodedImage!, srcRect, shape.rect, Paint());
        } else {
          canvas.drawRect(shape.rect, fillPaint);
        }
        if (shape.isStroked) canvas.drawRect(shape.rect, strokePaint);
        break;
    }

    canvas.restore();
  }

  Path _generateStarPath(Rect rect) {
    final path = Path();
    final center = rect.center;
    final outerRadius = math.min(rect.width, rect.height) / 2;
    final innerRadius = outerRadius * 0.4;
    const double angleStep = math.pi / 5;

    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? outerRadius : innerRadius;
      final angle = i * angleStep - math.pi / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  void _drawSelectionBox(Canvas canvas, VectorShape shape) {
    canvas.save();

    final center = shape.rect.center;
    if (shape.rotation != 0.0) {
      canvas.translate(center.dx, center.dy);
      canvas.rotate(shape.rotation * math.pi / 180.0);
      canvas.translate(-center.dx, -center.dy);
    }

    final handleFill = Paint()
      ..color = colorScheme.surface
      ..style = PaintingStyle.fill;
    final handleBorder = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    if (shape.type == ShapeType.line) {
      final startPt = shape.rect.topLeft;
      final endPt = shape.rect.bottomRight;

      final linePaint = Paint()
        ..color = colorScheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      if (shape.isCurved || shape.curvature != 0.0) {
        final mid = Offset((startPt.dx + endPt.dx) / 2, (startPt.dy + endPt.dy) / 2);
        final dx = endPt.dx - startPt.dx;
        final dy = endPt.dy - startPt.dy;
        final len = math.sqrt(dx * dx + dy * dy);
        final perp = len > 0 ? Offset(-dy / len, dx / len) : Offset.zero;
        final controlPt = mid + perp * shape.curvature;

        final path = Path()
          ..moveTo(startPt.dx, startPt.dy)
          ..quadraticBezierTo(controlPt.dx, controlPt.dy, endPt.dx, endPt.dy);
        canvas.drawPath(path, linePaint);

        // Guide dash line
        final guidePaint = Paint()
          ..color = colorScheme.primary.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawLine(startPt, controlPt, guidePaint);
        canvas.drawLine(endPt, controlPt, guidePaint);

        // Circular Bend Handle
        canvas.drawCircle(controlPt, 6, handleFill);
        canvas.drawCircle(controlPt, 6, handleBorder);
      } else {
        canvas.drawLine(startPt, endPt, linePaint);
      }

      for (final pt in [startPt, endPt]) {
        final handleRect = Rect.fromCenter(center: pt, width: 10, height: 10);
        canvas.drawRect(handleRect, handleFill);
        canvas.drawRect(handleRect, handleBorder);
      }

      canvas.restore();
      return;
    }

    final rect = shape.rect;
    final boxPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawRect(rect, boxPaint);

    final handlePoints = [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
      rect.topCenter,
      rect.bottomCenter,
      rect.centerLeft,
      rect.centerRight,
    ];

    for (final pt in handlePoints) {
      final handleRect = Rect.fromCenter(center: pt, width: 10, height: 10);
      canvas.drawRect(handleRect, handleFill);
      canvas.drawRect(handleRect, handleBorder);
    }

    // Top rotation handle
    final rotCenter = Offset(rect.topCenter.dx, rect.topCenter.dy - 20);
    final linePaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 1.5;
    canvas.drawLine(rect.topCenter, rotCenter, linePaint);
    canvas.drawCircle(rotCenter, 5, handleFill);
    canvas.drawCircle(rotCenter, 5, handleBorder);

    // Figma-style corner radius handles inside rectangles
    if ((shape.type == ShapeType.rectangle || shape.type == ShapeType.roundedRectangle) &&
        rect.width >= 40 &&
        rect.height >= 40) {
      final radiusInset = math.min(16.0, math.min(rect.width, rect.height) * 0.2);
      final radiusHandleFill = Paint()
        ..color = colorScheme.surface
        ..style = PaintingStyle.fill;
      final radiusHandleBorder = Paint()
        ..color = colorScheme.primary.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      final radiusHandles = [
        Offset(rect.left + radiusInset, rect.top + radiusInset),
        Offset(rect.right - radiusInset, rect.top + radiusInset),
        Offset(rect.left + radiusInset, rect.bottom - radiusInset),
        Offset(rect.right - radiusInset, rect.bottom - radiusInset),
      ];
      for (final pt in radiusHandles) {
        canvas.drawCircle(pt, 3.5, radiusHandleFill);
        canvas.drawCircle(pt, 3.5, radiusHandleBorder);
      }
    }

    canvas.restore();
  }

  void _drawIndividualSelectionOutline(Canvas canvas, VectorShape shape) {
    canvas.save();
    final center = shape.rect.center;
    if (shape.rotation != 0.0) {
      canvas.translate(center.dx, center.dy);
      canvas.rotate(shape.rotation * math.pi / 180.0);
      canvas.translate(-center.dx, -center.dy);
    }
    final outlinePaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(shape.rect, outlinePaint);
    canvas.restore();
  }

  void _drawMultiSelectionBoundingBox(Canvas canvas, Rect bounds) {
    final boxPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawRect(bounds, boxPaint);

    final handleFill = Paint()
      ..color = colorScheme.surface
      ..style = PaintingStyle.fill;
    final handleBorder = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final handlePoints = [
      bounds.topLeft,
      bounds.topRight,
      bounds.bottomLeft,
      bounds.bottomRight,
      bounds.topCenter,
      bounds.bottomCenter,
      bounds.centerLeft,
      bounds.centerRight,
    ];

    for (final pt in handlePoints) {
      final handleRect = Rect.fromCenter(center: pt, width: 9, height: 9);
      canvas.drawRect(handleRect, handleFill);
      canvas.drawRect(handleRect, handleBorder);
    }
  }

  void _drawDraftShape(Canvas canvas, Rect rect, ShapeType type) {
    final fillPaint = Paint()
      ..color = colorScheme.primaryContainer.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    switch (type) {
      case ShapeType.rectangle:
      case ShapeType.text:
      case ShapeType.image:
        canvas.drawRect(rect, fillPaint);
        canvas.drawRect(rect, strokePaint);
        break;
      case ShapeType.roundedRectangle:
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
        canvas.drawRRect(rrect, fillPaint);
        canvas.drawRRect(rrect, strokePaint);
        break;
      case ShapeType.ellipse:
        canvas.drawOval(rect, fillPaint);
        canvas.drawOval(rect, strokePaint);
        break;
      case ShapeType.line:
        canvas.drawLine(rect.topLeft, rect.bottomRight, strokePaint);
        break;
      case ShapeType.star:
        final path = _generateStarPath(rect);
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        break;
    }
  }

  void _drawDimensionBadge(Canvas canvas, Rect rect) {
    final width = rect.width.abs().round();
    final height = rect.height.abs().round();
    final textSpan = TextSpan(
      text: '$width × $height',
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final left = math.min(rect.left, rect.right);
    final bottom = math.max(rect.top, rect.bottom);
    final badgePos = Offset(left, bottom + 8);
    final bgRect = Rect.fromLTWH(
      badgePos.dx - 6,
      badgePos.dy - 3,
      textPainter.width + 12,
      textPainter.height + 6,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
      Paint()..color = colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
      Paint()
        ..color = colorScheme.outlineVariant.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    textPainter.paint(canvas, badgePos);
  }

  void _drawLineCapMarker(
    Canvas canvas,
    Offset point,
    Offset toward,
    LineCapStyle capStyle,
    VectorShape shape,
  ) {
    if (capStyle == LineCapStyle.none) return;

    final dx = point.dx - toward.dx;
    final dy = point.dy - toward.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist == 0) return;

    final angle = math.atan2(dy, dx);
    final color = shape.strokeColor;
    final size = math.max(10.0, shape.strokeWidth * 3.0);

    canvas.save();
    canvas.translate(point.dx, point.dy);
    canvas.rotate(angle);

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (capStyle) {
      case LineCapStyle.arrow:
        final path = Path()
          ..moveTo(0, 0)
          ..lineTo(-size, -size * 0.4)
          ..lineTo(-size * 0.7, 0)
          ..lineTo(-size, size * 0.4)
          ..close();
        canvas.drawPath(path, fillPaint);
        break;
      case LineCapStyle.circle:
        final radius = math.max(4.0, shape.strokeWidth * 1.5);
        canvas.drawCircle(Offset.zero, radius, fillPaint);
        break;
      case LineCapStyle.square:
        final squareSize = math.max(6.0, shape.strokeWidth * 2.0);
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: squareSize,
          height: squareSize,
        );
        canvas.drawRect(rect, fillPaint);
        break;
      case LineCapStyle.round:
        final radius = math.max(4.0, shape.strokeWidth * 1.5);
        canvas.drawCircle(Offset.zero, radius, fillPaint);
        break;
      case LineCapStyle.none:
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant VectorCanvasPainter oldDelegate) {
    return true;
  }

  static String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() +
          (word.length > 1 ? word.substring(1).toLowerCase() : '');
    }).join(' ');
  }
}
