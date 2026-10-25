import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:remixicon/remixicon.dart';

/// Lightweight custom painter widget rendering a miniature visual preview of shapes
/// for recent project cards.
class MiniProjectPreview extends StatefulWidget {
  final List<VectorShape> shapes;

  const MiniProjectPreview({super.key, required this.shapes});

  @override
  State<MiniProjectPreview> createState() => _MiniProjectPreviewState();
}

class _MiniProjectPreviewState extends State<MiniProjectPreview> {
  @override
  void initState() {
    super.initState();
    _decodeImages();
  }

  @override
  void didUpdateWidget(covariant MiniProjectPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shapes != widget.shapes) {
      _decodeImages();
    }
  }

  void _decodeImages() {
    for (final shape in widget.shapes) {
      if (shape.type == ShapeType.image &&
          shape.decodedImage == null &&
          shape.imageBytes != null &&
          shape.imageBytes!.isNotEmpty) {
        shape.ensureImageDecoded(onDecoded: () {
          if (mounted) setState(() {});
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.shapes.isEmpty) {
      return Center(
        child: Icon(
          RemixIcons.artboard_line,
          size: 28,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        ),
      );
    }

    return ClipRect(
      child: CustomPaint(
        painter: _MiniCanvasPainter(
          shapes: widget.shapes,
          colorScheme: colorScheme,
          onImageDecoded: () {
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }
}

class _MiniCanvasPainter extends CustomPainter {
  final List<VectorShape> shapes;
  final ColorScheme colorScheme;
  final VoidCallback? onImageDecoded;

  _MiniCanvasPainter({
    required this.shapes,
    required this.colorScheme,
    this.onImageDecoded,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (shapes.isEmpty) return;

    // Calculate collective bounding box of visible shapes
    Rect? bounds;
    for (final s in shapes) {
      if (!s.isVisible) continue;
      bounds = bounds == null ? s.rect : bounds.expandToInclude(s.rect);
    }

    if (bounds == null || bounds.isEmpty) {
      bounds = const Rect.fromLTWH(0, 0, 800, 600);
    }

    // Add padding around content
    final paddedBounds = bounds.inflate(40.0);

    // Compute scale and translate to fit nicely centered in the thumbnail area
    final scaleX = size.width / paddedBounds.width;
    final scaleY = size.height / paddedBounds.height;
    final scale = math.min(scaleX, scaleY).clamp(0.01, 1.0);

    final dx =
        (size.width - paddedBounds.width * scale) / 2 -
        paddedBounds.left * scale;
    final dy =
        (size.height - paddedBounds.height * scale) / 2 -
        paddedBounds.top * scale;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);

    for (final shape in shapes) {
      if (!shape.isVisible) continue;

      canvas.save();
      if (shape.rotation != 0.0) {
        final center = shape.rect.center;
        canvas.translate(center.dx, center.dy);
        canvas.rotate(shape.rotation * math.pi / 180.0);
        canvas.translate(-center.dx, -center.dy);
      }

      final fillPaint = Paint()
        ..color = shape.fillColor.withValues(alpha: shape.fillOpacity)
        ..style = PaintingStyle.fill;

      final strokePaint = Paint()
        ..color = shape.strokeColor
        ..strokeWidth = math.max(1.0, shape.strokeWidth)
        ..style = PaintingStyle.stroke;

      switch (shape.type) {
        case ShapeType.rectangle:
          final maxR = math.min(shape.rect.width, shape.rect.height) / 2;
          final hasRadius =
              shape.cornerRadius > 0 || shape.hasIndependentCorners;
          if (hasRadius) {
            if (shape.cornerSmoothing > 0.0) {
              final path = shape.getPath();
              if (shape.isFilled) canvas.drawPath(path, fillPaint);
              if (shape.isStroked) canvas.drawPath(path, strokePaint);
            } else {
              final rrect = shape.hasIndependentCorners
                  ? RRect.fromRectAndCorners(
                      shape.rect,
                      topLeft: Radius.circular(
                        shape.effectiveTopLeftRadius.clamp(0.0, maxR),
                      ),
                      topRight: Radius.circular(
                        shape.effectiveTopRightRadius.clamp(0.0, maxR),
                      ),
                      bottomRight: Radius.circular(
                        shape.effectiveBottomRightRadius.clamp(0.0, maxR),
                      ),
                      bottomLeft: Radius.circular(
                        shape.effectiveBottomLeftRadius.clamp(0.0, maxR),
                      ),
                    )
                  : RRect.fromRectAndRadius(
                      shape.rect,
                      Radius.circular(shape.cornerRadius.clamp(0.0, maxR)),
                    );
              if (shape.isFilled) canvas.drawRRect(rrect, fillPaint);
              if (shape.isStroked) canvas.drawRRect(rrect, strokePaint);
            }
          } else {
            if (shape.isFilled) canvas.drawRect(shape.rect, fillPaint);
            if (shape.isStroked) canvas.drawRect(shape.rect, strokePaint);
          }
          break;

        case ShapeType.roundedRectangle:
          final maxR = math.min(shape.rect.width, shape.rect.height) / 2;
          if (shape.cornerSmoothing > 0.0) {
            final path = shape.getPath();
            if (shape.isFilled) canvas.drawPath(path, fillPaint);
            if (shape.isStroked) canvas.drawPath(path, strokePaint);
          } else {
            final rrect = shape.hasIndependentCorners
                ? RRect.fromRectAndCorners(
                    shape.rect,
                    topLeft: Radius.circular(
                      shape.effectiveTopLeftRadius.clamp(0.0, maxR),
                    ),
                    topRight: Radius.circular(
                      shape.effectiveTopRightRadius.clamp(0.0, maxR),
                    ),
                    bottomRight: Radius.circular(
                      shape.effectiveBottomRightRadius.clamp(0.0, maxR),
                    ),
                    bottomLeft: Radius.circular(
                      shape.effectiveBottomLeftRadius.clamp(0.0, maxR),
                    ),
                  )
                : RRect.fromRectAndRadius(
                    shape.rect,
                    Radius.circular(shape.cornerRadius.clamp(0.0, maxR)),
                  );
            if (shape.isFilled) canvas.drawRRect(rrect, fillPaint);
            if (shape.isStroked) canvas.drawRRect(rrect, strokePaint);
          }
          break;

        case ShapeType.ellipse:
          if (shape.isFilled) canvas.drawOval(shape.rect, fillPaint);
          if (shape.isStroked) canvas.drawOval(shape.rect, strokePaint);
          break;

        case ShapeType.star:
        case ShapeType.polygon:
        case ShapeType.path:
          final path = shape.getPath();
          if (shape.isFilled) canvas.drawPath(path, fillPaint);
          if (shape.isStroked) canvas.drawPath(path, strokePaint);
          break;

        case ShapeType.line:
          canvas.drawLine(
            shape.rect.topLeft,
            shape.rect.bottomRight,
            strokePaint,
          );
          break;

        case ShapeType.text:
          final textPainter = TextPainter(
            text: TextSpan(
              text: shape.textContent,
              style: TextStyle(
                color: shape.fillColor,
                fontSize: shape.fontSize,
                fontWeight: shape.fontWeight,
                fontFamily: shape.fontFamily,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout(maxWidth: shape.rect.width);
          textPainter.paint(canvas, shape.rect.topLeft);
          break;

        case ShapeType.image:
          if (shape.decodedImage != null) {
            final srcRect = Rect.fromLTWH(
              0,
              0,
              shape.decodedImage!.width.toDouble(),
              shape.decodedImage!.height.toDouble(),
            );
            canvas.save();
            canvas.clipRRect(
              RRect.fromRectAndRadius(shape.rect, const Radius.circular(8)),
            );
            canvas.drawImageRect(
              shape.decodedImage!,
              srcRect,
              shape.rect,
              Paint()..filterQuality = FilterQuality.medium,
            );
            canvas.restore();
          } else {
            if (shape.imageBytes != null && shape.imageBytes!.isNotEmpty) {
              shape.ensureImageDecoded(onDecoded: onImageDecoded);
            }
            canvas.drawRRect(
              RRect.fromRectAndRadius(shape.rect, const Radius.circular(8)),
              fillPaint,
            );
          }
          break;
      }

      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MiniCanvasPainter oldDelegate) {
    if (oldDelegate.shapes.length != shapes.length) return true;
    for (int i = 0; i < shapes.length; i++) {
      if (oldDelegate.shapes[i].decodedImage != shapes[i].decodedImage ||
          oldDelegate.shapes[i].revision != shapes[i].revision) {
        return true;
      }
    }
    return oldDelegate.shapes != shapes;
  }
}
