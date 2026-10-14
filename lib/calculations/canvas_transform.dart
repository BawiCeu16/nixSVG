import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Matrix4 transformations and zoom calculations for the vector canvas.
class CanvasTransformHelper {
  const CanvasTransformHelper._();

  static const double minScale = 0.05; // 5% minimum zoom
  static const double maxScale = 32.0; // 3200% maximum zoom

  /// Extracts the 2D uniform canvas scale (ignoring 3D Z-axis).
  static double getScale(Matrix4 matrix) {
    final m0 = matrix.storage[0];
    final m1 = matrix.storage[1];
    final scale = math.sqrt(m0 * m0 + m1 * m1);
    return (scale <= 0.0 || scale.isNaN || scale.isInfinite) ? 1.0 : scale;
  }

  /// Translates the viewport directly by the screen delta (in pixels).
  /// Using the matrix translation components (storage[12] and storage[13])
  /// guarantees 1:1 cursor tracking at ANY zoom scale without drift or precision loss.
  static Matrix4 panMatrix(Matrix4 currentMatrix, Offset screenDelta) {
    final matrix = currentMatrix.clone();
    matrix.storage[12] += screenDelta.dx;
    matrix.storage[13] += screenDelta.dy;
    return matrix;
  }

  /// Calculates focal-point zoom around a canvas coordinate [focalCanvasPoint].
  ///
  /// Mathematical Invariance:
  /// The screen position of [focalCanvasPoint] remains 100% stationary before and after zoom.
  /// Screen pos: S = currentScale * C + currentT = newScale * C + newT
  /// => newT = currentT + currentScale * C * (1.0 - effectiveFactor)
  static Matrix4 zoomAtCanvasPoint(
    Matrix4 currentMatrix,
    Offset focalCanvasPoint,
    double zoomFactor, {
    double min = minScale,
    double max = maxScale,
  }) {
    final double currentScale = getScale(currentMatrix);
    if (currentScale <= 0.0 || currentScale.isNaN || currentScale.isInfinite) {
      return Matrix4.identity();
    }
    if (zoomFactor <= 0.0 || zoomFactor.isNaN || zoomFactor.isInfinite) {
      return currentMatrix;
    }

    final double newScale = (currentScale * zoomFactor).clamp(min, max);
    final double effectiveFactor = newScale / currentScale;
    if ((effectiveFactor - 1.0).abs() < 1e-7) {
      return currentMatrix;
    }

    final double currentTx = currentMatrix.storage[12];
    final double currentTy = currentMatrix.storage[13];

    final double newTx =
        currentTx + currentScale * focalCanvasPoint.dx * (1.0 - effectiveFactor);
    final double newTy =
        currentTy + currentScale * focalCanvasPoint.dy * (1.0 - effectiveFactor);

    final matrix = currentMatrix.clone();
    matrix.storage[0] = newScale;
    matrix.storage[5] = newScale;
    matrix.storage[12] = newTx;
    matrix.storage[13] = newTy;
    return matrix;
  }

  /// Calculates focal-point zoom around a screen/viewport coordinate [focalScreenPoint].
  static Matrix4 zoomAtScreenPoint(
    Matrix4 currentMatrix,
    Offset focalScreenPoint,
    double zoomFactor, {
    double min = minScale,
    double max = maxScale,
  }) {
    final double currentScale = getScale(currentMatrix);
    if (currentScale <= 0.0 || currentScale.isNaN || currentScale.isInfinite) {
      return Matrix4.identity();
    }
    final double currentTx = currentMatrix.storage[12];
    final double currentTy = currentMatrix.storage[13];

    final double canvasX = (focalScreenPoint.dx - currentTx) / currentScale;
    final double canvasY = (focalScreenPoint.dy - currentTy) / currentScale;

    return zoomAtCanvasPoint(
      currentMatrix,
      Offset(canvasX, canvasY),
      zoomFactor,
      min: min,
      max: max,
    );
  }

  /// Scales canvas zoom with multiplier centered around [focalCanvasPoint] or [focalScreenPoint].
  static Matrix4 applyZoom(
    Matrix4 currentMatrix,
    double factor, {
    Offset? focalCanvasPoint,
    Offset? focalScreenPoint,
    Size? viewportSize,
  }) {
    if (focalCanvasPoint != null) {
      return zoomAtCanvasPoint(currentMatrix, focalCanvasPoint, factor);
    }
    if (focalScreenPoint != null) {
      return zoomAtScreenPoint(currentMatrix, focalScreenPoint, factor);
    }
    if (viewportSize != null && !viewportSize.isEmpty) {
      return zoomAtScreenPoint(
        currentMatrix,
        Offset(viewportSize.width / 2, viewportSize.height / 2),
        factor,
      );
    }
    return zoomAtCanvasPoint(
      currentMatrix,
      const Offset(1600.0, 1200.0),
      factor,
    );
  }

  /// Calculates focal-point scroll zoom.
  /// [position] is the local canvas coordinate received from pointer event localPosition.
  static Matrix4 scrollZoom(
    Matrix4 currentMatrix,
    Offset position,
    double zoomFactor, {
    double min = minScale,
    double max = maxScale,
  }) {
    return zoomAtCanvasPoint(
      currentMatrix,
      position,
      zoomFactor,
      min: min,
      max: max,
    );
  }

  /// Calculates a matrix that centers and fits [targetBounds] within [viewportSize].
  static Matrix4 zoomToFit(Rect targetBounds, Size viewportSize, {double padding = 80.0}) {
    if (targetBounds.isEmpty || viewportSize.isEmpty) return Matrix4.identity();
    final double availW = (viewportSize.width - padding * 2).clamp(100.0, 10000.0);
    final double availH = (viewportSize.height - padding * 2).clamp(100.0, 10000.0);
    final double scaleX = availW / targetBounds.width;
    final double scaleY = availH / targetBounds.height;
    final double scale = (scaleX < scaleY ? scaleX : scaleY).clamp(minScale, 4.0);

    final double transX = (viewportSize.width - targetBounds.width * scale) / 2 - targetBounds.left * scale;
    final double transY = (viewportSize.height - targetBounds.height * scale) / 2 - targetBounds.top * scale;

    final matrix = Matrix4.identity();
    matrix.storage[0] = scale;
    matrix.storage[5] = scale;
    matrix.storage[12] = transX;
    matrix.storage[13] = transY;
    return matrix;
  }

  /// Sets matrix zoom to an absolute [targetScale] centered on [focalPoint].
  static Matrix4 setZoomScale(
    Matrix4 currentMatrix,
    double targetScale,
    Offset focalPoint, {
    bool isCanvasPoint = true,
  }) {
    final currentScale = getScale(currentMatrix);
    if (currentScale <= 0) return currentMatrix;
    final factor = targetScale / currentScale;
    return isCanvasPoint
        ? zoomAtCanvasPoint(currentMatrix, focalPoint, factor)
        : zoomAtScreenPoint(currentMatrix, focalPoint, factor);
  }
}

