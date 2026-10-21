import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nixsvg/calculations/canvas_geometry.dart';

enum ShapeType { rectangle, roundedRectangle, ellipse, line, star, text, image }

enum EditorMode {
  select,
  pan,
  drawRectangle,
  drawRoundedRectangle,
  drawEllipse,
  drawLine,
  drawCurve,
  drawStar,
  drawText,
}

enum ResizeHandle {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  topCenter,
  bottomCenter,
  centerLeft,
  centerRight,
  rotation,
  radiusTopLeft,
  radiusTopRight,
  radiusBottomLeft,
  radiusBottomRight,
  none,
}

extension ResizeHandleExt on ResizeHandle {
  bool get isRadius =>
      this == ResizeHandle.radiusTopLeft ||
      this == ResizeHandle.radiusTopRight ||
      this == ResizeHandle.radiusBottomLeft ||
      this == ResizeHandle.radiusBottomRight;

  bool get isCorner =>
      this == ResizeHandle.topLeft ||
      this == ResizeHandle.topRight ||
      this == ResizeHandle.bottomLeft ||
      this == ResizeHandle.bottomRight;

  bool get isEdge =>
      this == ResizeHandle.topCenter ||
      this == ResizeHandle.bottomCenter ||
      this == ResizeHandle.centerLeft ||
      this == ResizeHandle.centerRight;
}

enum LineCapStyle { none, round, square, arrow, circle }

enum TextVerticalAlign { top, center, bottom }

enum TextCase { original, uppercase, lowercase, titleCase }

enum PaintFillType { solid, linearGradient, radialGradient }

enum StrokeStyle { solid, dashed, dotted }

enum StrokeAlign { inside, center, outside }

class GradientColorStop {
  final double offset;
  final Color color;

  const GradientColorStop({required this.offset, required this.color});

  GradientColorStop copyWith({double? offset, Color? color}) {
    return GradientColorStop(
      offset: offset ?? this.offset,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() => {
    'offset': offset,
    'color': color.toARGB32(),
  };

  factory GradientColorStop.fromJson(Map<String, dynamic> json) =>
      GradientColorStop(
        offset: (json['offset'] as num?)?.toDouble() ?? 0.0,
        color: json['color'] != null
            ? Color(json['color'] as int)
            : const Color(0xFF6366F1),
      );
}

class ShapeGradient {
  final PaintFillType type; // linearGradient or radialGradient
  final List<GradientColorStop> stops;
  final double angle; // in degrees (for linear gradient, e.g. 0 to 360)

  const ShapeGradient({
    this.type = PaintFillType.linearGradient,
    this.stops = const [
      GradientColorStop(offset: 0.0, color: Color(0xFF6366F1)),
      GradientColorStop(offset: 1.0, color: Color(0xFF38BDF8)),
    ],
    this.angle = 90.0,
  });

  ShapeGradient copyWith({
    PaintFillType? type,
    List<GradientColorStop>? stops,
    double? angle,
  }) {
    return ShapeGradient(
      type: type ?? this.type,
      stops: stops ?? this.stops,
      angle: angle ?? this.angle,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'stops': stops.map((s) => s.toJson()).toList(),
    'angle': angle,
  };

  factory ShapeGradient.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'linearGradient';
    final type = PaintFillType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => PaintFillType.linearGradient,
    );
    final stopsRaw = json['stops'] as List<dynamic>? ?? [];
    final stops = stopsRaw
        .map((s) => GradientColorStop.fromJson(s as Map<String, dynamic>))
        .toList();
    return ShapeGradient(
      type: type,
      stops: stops.isNotEmpty
          ? stops
          : const [
              GradientColorStop(offset: 0.0, color: Color(0xFF6366F1)),
              GradientColorStop(offset: 1.0, color: Color(0xFF38BDF8)),
            ],
      angle: (json['angle'] as num?)?.toDouble() ?? 90.0,
    );
  }
}

class VectorShape {
  final String id;
  String name;
  ShapeType type;
  Rect rect;
  double rotation; // In degrees
  Color fillColor;
  double fillOpacity;
  PaintFillType fillType;
  ShapeGradient? fillGradient;
  Color strokeColor;
  double strokeWidth;
  double strokeOpacity;
  StrokeStyle strokeStyle;
  StrokeAlign strokeAlign;
  double strokeDashLength;
  double strokeDashGap;
  PaintFillType strokeType;
  ShapeGradient? strokeGradient;
  StrokeCap strokeCap;
  LineCapStyle startCap;
  LineCapStyle endCap;
  bool isCurved;
  double curvature;
  bool isFilled;
  bool isStroked;
  double cornerRadius;
  double? topLeftRadius;
  double? topRightRadius;
  double? bottomRightRadius;
  double? bottomLeftRadius;

  bool get hasIndependentCorners =>
      topLeftRadius != null ||
      topRightRadius != null ||
      bottomRightRadius != null ||
      bottomLeftRadius != null;

  double get effectiveTopLeftRadius => topLeftRadius ?? cornerRadius;
  double get effectiveTopRightRadius => topRightRadius ?? cornerRadius;
  double get effectiveBottomRightRadius => bottomRightRadius ?? cornerRadius;
  double get effectiveBottomLeftRadius => bottomLeftRadius ?? cornerRadius;

  String textContent;
  double fontSize;
  String fontFamily;
  bool isBold;
  bool isItalic;
  bool isUnderline;
  bool isStrikethrough;
  TextAlign textAlign;
  TextVerticalAlign textVerticalAlign;
  double letterSpacing;
  double lineHeight;
  TextCase textCase;
  FontWeight fontWeight;
  bool isVisible;
  bool isLocked;
  Uint8List? imageBytes;
  ui.Image? decodedImage;

  // Self-invalidating geometry and rendering caches
  Path? _cachedPath;
  Rect? _lastPathRect;
  double? _lastPathRadius;
  double? _lastTlRadius;
  double? _lastTrRadius;
  double? _lastBrRadius;
  double? _lastBlRadius;
  double? _lastPathCurvature;
  bool? _lastPathIsCurved;
  ShapeType? _lastPathType;

  Path? _cachedDashedPath;
  double? _lastDashLength;
  double? _lastDashGap;
  StrokeStyle? _lastDashStyle;

  Rect? _cachedBoundingBox;
  Rect? _lastBBRect;
  double? _lastBBRotation;
  double? _lastBBStrokeWidth;
  bool? _lastBBIsStroked;
  ShapeType? _lastBBType;

  TextPainter? _cachedTextPainter;
  String? _lastTextContent;
  double? _lastTextFontSize;
  String? _lastTextFontFamily;
  FontWeight? _lastTextFontWeight;
  bool? _lastTextIsItalic;
  bool? _lastTextIsUnderline;
  bool? _lastTextIsStrikethrough;
  TextAlign? _lastTextAlign;
  double? _lastTextLetterSpacing;
  double? _lastTextLineHeight;
  TextCase? _lastTextCase;
  Color? _lastTextColor;
  PaintFillType? _lastTextFillType;
  ShapeGradient? _lastTextFillGradient;
  double? _lastTextFillOpacity;
  double? _lastTextRectWidth;

  VectorShape({
    required this.id,
    required this.name,
    required this.type,
    required this.rect,
    this.rotation = 0.0,
    this.fillColor = const Color(0xFF6366F1),
    this.fillOpacity = 1.0,
    this.fillType = PaintFillType.solid,
    this.fillGradient,
    this.strokeColor = const Color(0xFF38BDF8),
    this.strokeWidth = 2.0,
    this.strokeOpacity = 1.0,
    this.strokeStyle = StrokeStyle.solid,
    this.strokeAlign = StrokeAlign.center,
    this.strokeDashLength = 8.0,
    this.strokeDashGap = 6.0,
    this.strokeType = PaintFillType.solid,
    this.strokeGradient,
    this.strokeCap = StrokeCap.butt,
    this.startCap = LineCapStyle.none,
    this.endCap = LineCapStyle.none,
    this.isCurved = false,
    this.curvature = 0.0,
    this.isFilled = true,
    this.isStroked = false,
    this.cornerRadius = 12.0,
    this.topLeftRadius,
    this.topRightRadius,
    this.bottomRightRadius,
    this.bottomLeftRadius,
    this.textContent = 'Text Element',
    this.fontSize = 24.0,
    this.fontFamily = 'Roboto',
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrikethrough = false,
    this.textAlign = TextAlign.left,
    this.textVerticalAlign = TextVerticalAlign.top,
    this.letterSpacing = 0.0,
    this.lineHeight = 1.2,
    this.textCase = TextCase.original,
    FontWeight? fontWeight,
    this.isVisible = true,
    this.isLocked = false,
    this.imageBytes,
    this.decodedImage,
  }) : fontWeight =
           fontWeight ?? (isBold ? FontWeight.bold : FontWeight.normal);

  VectorShape copyWith({
    String? id,
    String? name,
    ShapeType? type,
    Rect? rect,
    double? rotation,
    Color? fillColor,
    double? fillOpacity,
    PaintFillType? fillType,
    ShapeGradient? fillGradient,
    Color? strokeColor,
    double? strokeWidth,
    double? strokeOpacity,
    StrokeStyle? strokeStyle,
    StrokeAlign? strokeAlign,
    double? strokeDashLength,
    double? strokeDashGap,
    PaintFillType? strokeType,
    ShapeGradient? strokeGradient,
    StrokeCap? strokeCap,
    LineCapStyle? startCap,
    LineCapStyle? endCap,
    bool? isCurved,
    double? curvature,
    bool? isFilled,
    bool? isStroked,
    double? cornerRadius,
    double? topLeftRadius,
    double? topRightRadius,
    double? bottomRightRadius,
    double? bottomLeftRadius,
    bool clearIndependentCorners = false,
    String? textContent,
    double? fontSize,
    String? fontFamily,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    bool? isStrikethrough,
    TextAlign? textAlign,
    TextVerticalAlign? textVerticalAlign,
    double? letterSpacing,
    double? lineHeight,
    TextCase? textCase,
    FontWeight? fontWeight,
    bool? isVisible,
    bool? isLocked,
    Uint8List? imageBytes,
    ui.Image? decodedImage,
  }) {
    final effectiveIsBold =
        isBold ??
        (fontWeight != null
            ? (fontWeight.value >= FontWeight.w700.value)
            : this.isBold);
    final effectiveFontWeight =
        fontWeight ??
        (isBold != null
            ? (isBold ? FontWeight.bold : FontWeight.normal)
            : this.fontWeight);
    return VectorShape(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      rect: rect ?? this.rect,
      rotation: rotation ?? this.rotation,
      fillColor: fillColor ?? this.fillColor,
      fillOpacity: fillOpacity ?? this.fillOpacity,
      fillType: fillType ?? this.fillType,
      fillGradient: fillGradient ?? this.fillGradient,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeOpacity: strokeOpacity ?? this.strokeOpacity,
      strokeStyle: strokeStyle ?? this.strokeStyle,
      strokeAlign: strokeAlign ?? this.strokeAlign,
      strokeDashLength: strokeDashLength ?? this.strokeDashLength,
      strokeDashGap: strokeDashGap ?? this.strokeDashGap,
      strokeType: strokeType ?? this.strokeType,
      strokeGradient: strokeGradient ?? this.strokeGradient,
      strokeCap: strokeCap ?? this.strokeCap,
      startCap: startCap ?? this.startCap,
      endCap: endCap ?? this.endCap,
      isCurved: isCurved ?? this.isCurved,
      curvature: curvature ?? this.curvature,
      isFilled: isFilled ?? this.isFilled,
      isStroked: isStroked ?? this.isStroked,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      topLeftRadius: clearIndependentCorners
          ? null
          : (topLeftRadius ?? this.topLeftRadius),
      topRightRadius: clearIndependentCorners
          ? null
          : (topRightRadius ?? this.topRightRadius),
      bottomRightRadius: clearIndependentCorners
          ? null
          : (bottomRightRadius ?? this.bottomRightRadius),
      bottomLeftRadius: clearIndependentCorners
          ? null
          : (bottomLeftRadius ?? this.bottomLeftRadius),
      textContent: textContent ?? this.textContent,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      isBold: effectiveIsBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      isStrikethrough: isStrikethrough ?? this.isStrikethrough,
      textAlign: textAlign ?? this.textAlign,
      textVerticalAlign: textVerticalAlign ?? this.textVerticalAlign,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineHeight: lineHeight ?? this.lineHeight,
      textCase: textCase ?? this.textCase,
      fontWeight: effectiveFontWeight,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      imageBytes: imageBytes ?? this.imageBytes,
      decodedImage: decodedImage ?? this.decodedImage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'rect': {
        'left': rect.left,
        'top': rect.top,
        'width': rect.width,
        'height': rect.height,
      },
      'rotation': rotation,
      'fillColor': fillColor.toARGB32(),
      'fillOpacity': fillOpacity,
      'fillType': fillType.name,
      'fillGradient': fillGradient?.toJson(),
      'strokeColor': strokeColor.toARGB32(),
      'strokeWidth': strokeWidth,
      'strokeOpacity': strokeOpacity,
      'strokeStyle': strokeStyle.name,
      'strokeAlign': strokeAlign.name,
      'strokeDashLength': strokeDashLength,
      'strokeDashGap': strokeDashGap,
      'strokeType': strokeType.name,
      'strokeGradient': strokeGradient?.toJson(),
      'strokeCap': strokeCap.name,
      'startCap': startCap.name,
      'endCap': endCap.name,
      'isCurved': isCurved,
      'curvature': curvature,
      'isFilled': isFilled,
      'isStroked': isStroked,
      'cornerRadius': cornerRadius,
      'topLeftRadius': topLeftRadius,
      'topRightRadius': topRightRadius,
      'bottomRightRadius': bottomRightRadius,
      'bottomLeftRadius': bottomLeftRadius,
      'textContent': textContent,
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'isBold': isBold,
      'isItalic': isItalic,
      'isUnderline': isUnderline,
      'isStrikethrough': isStrikethrough,
      'textAlign': textAlign.name,
      'textVerticalAlign': textVerticalAlign.name,
      'letterSpacing': letterSpacing,
      'lineHeight': lineHeight,
      'textCase': textCase.name,
      'fontWeight': fontWeight.value,
      'isVisible': isVisible,
      'isLocked': isLocked,
      'imageBytes': imageBytes != null ? base64Encode(imageBytes!) : null,
    };
  }

  factory VectorShape.fromJson(Map<String, dynamic> json) {
    final rectMap = json['rect'] as Map<String, dynamic>? ?? {};
    final rect = Rect.fromLTWH(
      (rectMap['left'] as num?)?.toDouble() ?? 0.0,
      (rectMap['top'] as num?)?.toDouble() ?? 0.0,
      (rectMap['width'] as num?)?.toDouble() ?? 100.0,
      (rectMap['height'] as num?)?.toDouble() ?? 100.0,
    );

    final typeStr = json['type'] as String? ?? 'rectangle';
    final type = ShapeType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => ShapeType.rectangle,
    );

    final fillTypeStr = json['fillType'] as String? ?? 'solid';
    final fillType = PaintFillType.values.firstWhere(
      (e) => e.name == fillTypeStr,
      orElse: () => PaintFillType.solid,
    );
    final fillGradMap = json['fillGradient'] as Map<String, dynamic>?;
    final fillGradient = fillGradMap != null
        ? ShapeGradient.fromJson(fillGradMap)
        : null;

    final strokeStyleStr = json['strokeStyle'] as String? ?? 'solid';
    final strokeStyle = StrokeStyle.values.firstWhere(
      (e) => e.name == strokeStyleStr,
      orElse: () => StrokeStyle.solid,
    );
    final strokeAlignStr = json['strokeAlign'] as String? ?? 'center';
    final strokeAlign = StrokeAlign.values.firstWhere(
      (e) => e.name == strokeAlignStr,
      orElse: () => StrokeAlign.center,
    );
    final strokeTypeStr = json['strokeType'] as String? ?? 'solid';
    final strokeType = PaintFillType.values.firstWhere(
      (e) => e.name == strokeTypeStr,
      orElse: () => PaintFillType.solid,
    );
    final strokeGradMap = json['strokeGradient'] as Map<String, dynamic>?;
    final strokeGradient = strokeGradMap != null
        ? ShapeGradient.fromJson(strokeGradMap)
        : null;

    final strokeCapStr = json['strokeCap'] as String? ?? 'butt';
    final strokeCap = StrokeCap.values.firstWhere(
      (e) => e.name == strokeCapStr,
      orElse: () => StrokeCap.butt,
    );

    final startCapStr = json['startCap'] as String? ?? 'none';
    final startCap = LineCapStyle.values.firstWhere(
      (e) => e.name == startCapStr,
      orElse: () => LineCapStyle.none,
    );

    final endCapStr = json['endCap'] as String? ?? 'none';
    final endCap = LineCapStyle.values.firstWhere(
      (e) => e.name == endCapStr,
      orElse: () => LineCapStyle.none,
    );

    final textAlignStr = json['textAlign'] as String? ?? 'left';
    final textAlign = TextAlign.values.firstWhere(
      (e) => e.name == textAlignStr,
      orElse: () => TextAlign.left,
    );

    final textVerticalAlignStr = json['textVerticalAlign'] as String? ?? 'top';
    final textVerticalAlign = TextVerticalAlign.values.firstWhere(
      (e) => e.name == textVerticalAlignStr,
      orElse: () => TextVerticalAlign.top,
    );

    final textCaseStr = json['textCase'] as String? ?? 'original';
    final textCase = TextCase.values.firstWhere(
      (e) => e.name == textCaseStr,
      orElse: () => TextCase.original,
    );

    final fontWeightVal = json['fontWeight'] as int?;
    final fontWeight = fontWeightVal != null
        ? FontWeight.values.firstWhere(
            (w) => w.value == fontWeightVal,
            orElse: () => FontWeight.normal,
          )
        : null;

    final imageBytesStr = json['imageBytes'] as String?;
    Uint8List? imageBytes;
    if (imageBytesStr != null && imageBytesStr.isNotEmpty) {
      try {
        imageBytes = base64Decode(imageBytesStr);
      } catch (_) {}
    }

    return VectorShape(
      id:
          json['id'] as String? ??
          'shape-${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Shape',
      type: type,
      rect: rect,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      fillColor: json['fillColor'] != null
          ? Color(json['fillColor'] as int)
          : const Color(0xFF6366F1),
      fillOpacity: (json['fillOpacity'] as num?)?.toDouble() ?? 1.0,
      fillType: fillType,
      fillGradient: fillGradient,
      strokeColor: json['strokeColor'] != null
          ? Color(json['strokeColor'] as int)
          : const Color(0xFF38BDF8),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
      strokeOpacity: (json['strokeOpacity'] as num?)?.toDouble() ?? 1.0,
      strokeStyle: strokeStyle,
      strokeAlign: strokeAlign,
      strokeDashLength: (json['strokeDashLength'] as num?)?.toDouble() ?? 8.0,
      strokeDashGap: (json['strokeDashGap'] as num?)?.toDouble() ?? 6.0,
      strokeType: strokeType,
      strokeGradient: strokeGradient,
      strokeCap: strokeCap,
      startCap: startCap,
      endCap: endCap,
      isCurved: json['isCurved'] as bool? ?? false,
      curvature: (json['curvature'] as num?)?.toDouble() ?? 0.0,
      isFilled: json['isFilled'] as bool? ?? true,
      isStroked: json['isStroked'] as bool? ?? false,
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 12.0,
      topLeftRadius: (json['topLeftRadius'] as num?)?.toDouble(),
      topRightRadius: (json['topRightRadius'] as num?)?.toDouble(),
      bottomRightRadius: (json['bottomRightRadius'] as num?)?.toDouble(),
      bottomLeftRadius: (json['bottomLeftRadius'] as num?)?.toDouble(),
      textContent: json['textContent'] as String? ?? 'Text Element',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 24.0,
      fontFamily: json['fontFamily'] as String? ?? 'Roboto',
      isBold: json['isBold'] as bool? ?? false,
      isItalic: json['isItalic'] as bool? ?? false,
      isUnderline: json['isUnderline'] as bool? ?? false,
      isStrikethrough: json['isStrikethrough'] as bool? ?? false,
      textAlign: textAlign,
      textVerticalAlign: textVerticalAlign,
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0.0,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.2,
      textCase: textCase,
      fontWeight: fontWeight,
      isVisible: json['isVisible'] as bool? ?? true,
      isLocked: json['isLocked'] as bool? ?? false,
      imageBytes: imageBytes,
    );
  }

  /// Returns SVG `<defs>` elements if this shape utilizes gradients for fill or stroke.
  String toSvgDefs() {
    if (!isVisible) return '';
    final defs = StringBuffer();

    if (isFilled && fillType != PaintFillType.solid && fillGradient != null) {
      defs.writeln(_gradientToSvgDef('grad-$id-fill', fillGradient!));
    }
    if (isStroked &&
        strokeType != PaintFillType.solid &&
        strokeGradient != null) {
      defs.writeln(_gradientToSvgDef('grad-$id-stroke', strokeGradient!));
    }

    if (type == ShapeType.line && isStroked) {
      final hexColor = _colorToHex(strokeColor);
      final opacity = strokeOpacity.toStringAsFixed(2);
      if (startCap == LineCapStyle.arrow) {
        defs.writeln(
          '    <marker id="arrow-start-$id" viewBox="0 0 10 10" refX="2" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">',
        );
        defs.writeln(
          '      <path d="M 10 2 L 2 5 L 10 8 z" fill="$hexColor" fill-opacity="$opacity" />',
        );
        defs.writeln('    </marker>');
      }
      if (endCap == LineCapStyle.arrow) {
        defs.writeln(
          '    <marker id="arrow-end-$id" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto">',
        );
        defs.writeln(
          '      <path d="M 0 2 L 8 5 L 0 8 z" fill="$hexColor" fill-opacity="$opacity" />',
        );
        defs.writeln('    </marker>');
      }
    }

    return defs.toString();
  }

  static String _gradientToSvgDef(String gradId, ShapeGradient grad) {
    final sb = StringBuffer();
    if (grad.type == PaintFillType.linearGradient) {
      // Convert angle to x1, y1, x2, y2 percentages
      final rad = grad.angle * math.pi / 180.0;
      final x1 = (0.5 - 0.5 * math.cos(rad)) * 100;
      final y1 = (0.5 - 0.5 * math.sin(rad)) * 100;
      final x2 = (0.5 + 0.5 * math.cos(rad)) * 100;
      final y2 = (0.5 + 0.5 * math.sin(rad)) * 100;
      sb.writeln(
        '    <linearGradient id="$gradId" x1="${x1.toStringAsFixed(1)}%" y1="${y1.toStringAsFixed(1)}%" x2="${x2.toStringAsFixed(1)}%" y2="${y2.toStringAsFixed(1)}%">',
      );
      for (final stop in grad.stops) {
        sb.writeln(
          '      <stop offset="${(stop.offset * 100).toStringAsFixed(1)}%" stop-color="${_colorToHex(stop.color)}" stop-opacity="${(stop.color.a).toStringAsFixed(2)}" />',
        );
      }
      sb.write('    </linearGradient>');
    } else {
      sb.writeln(
        '    <radialGradient id="$gradId" cx="50%" cy="50%" r="50%" fx="50%" fy="50%">',
      );
      for (final stop in grad.stops) {
        sb.writeln(
          '      <stop offset="${(stop.offset * 100).toStringAsFixed(1)}%" stop-color="${_colorToHex(stop.color)}" stop-opacity="${(stop.color.a).toStringAsFixed(2)}" />',
        );
      }
      sb.write('    </radialGradient>');
    }
    return sb.toString();
  }

  // Generate SVG string representation for this shape
  String toSvgElement() {
    if (!isVisible) return '';

    String fillAttr;
    if (!isFilled) {
      fillAttr = 'fill="none"';
    } else if (fillType != PaintFillType.solid && fillGradient != null) {
      fillAttr = 'fill="url(#grad-$id-fill)" fill-opacity="$fillOpacity"';
    } else {
      final fillHex = _colorToHex(fillColor);
      fillAttr = 'fill="$fillHex" fill-opacity="$fillOpacity"';
    }

    String strokeAttr;
    if (!isStroked) {
      strokeAttr = 'stroke="none"';
    } else {
      String strokeSource;
      if (strokeType != PaintFillType.solid && strokeGradient != null) {
        strokeSource = 'url(#grad-$id-stroke)';
      } else {
        strokeSource = _colorToHex(strokeColor);
      }

      var dashAttr = '';
      if (strokeStyle == StrokeStyle.dashed) {
        dashAttr =
            ' stroke-dasharray="${strokeDashLength.toStringAsFixed(1)} ${strokeDashGap.toStringAsFixed(1)}"';
      } else if (strokeStyle == StrokeStyle.dotted) {
        dashAttr =
            ' stroke-dasharray="${strokeWidth.toStringAsFixed(1)} ${(strokeWidth * 1.5).toStringAsFixed(1)}"';
      }

      strokeAttr =
          'stroke="$strokeSource" stroke-width="$strokeWidth" stroke-opacity="$strokeOpacity"$dashAttr';
    }

    final transformAttr = rotation != 0.0
        ? ' transform="rotate($rotation ${rect.center.dx} ${rect.center.dy})"'
        : '';

    switch (type) {
      case ShapeType.rectangle:
        return '  <rect x="${rect.left}" y="${rect.top}" width="${rect.width}" height="${rect.height}" $fillAttr $strokeAttr$transformAttr />';
      case ShapeType.roundedRectangle:
        if (hasIndependentCorners) {
          final maxR = math.min(rect.width, rect.height) / 2;
          final tl = effectiveTopLeftRadius.clamp(0.0, maxR);
          final tr = effectiveTopRightRadius.clamp(0.0, maxR);
          final br = effectiveBottomRightRadius.clamp(0.0, maxR);
          final bl = effectiveBottomLeftRadius.clamp(0.0, maxR);
          final d = 'M ${rect.left + tl} ${rect.top} '
              'H ${rect.right - tr} '
              '${tr > 0 ? 'A $tr $tr 0 0 1 ${rect.right} ${rect.top + tr} ' : ''}'
              'V ${rect.bottom - br} '
              '${br > 0 ? 'A $br $br 0 0 1 ${rect.right - br} ${rect.bottom} ' : ''}'
              'H ${rect.left + bl} '
              '${bl > 0 ? 'A $bl $bl 0 0 1 ${rect.left} ${rect.bottom - bl} ' : ''}'
              'V ${rect.top + tl} '
              '${tl > 0 ? 'A $tl $tl 0 0 1 ${rect.left + tl} ${rect.top} ' : ''}'
              'Z';
          return '  <path d="$d" $fillAttr $strokeAttr$transformAttr />';
        }
        return '  <rect x="${rect.left}" y="${rect.top}" width="${rect.width}" height="${rect.height}" rx="$cornerRadius" ry="$cornerRadius" $fillAttr $strokeAttr$transformAttr />';
      case ShapeType.ellipse:
        final cx = rect.center.dx;
        final cy = rect.center.dy;
        final rx = rect.width / 2;
        final ry = rect.height / 2;
        return '  <ellipse cx="$cx" cy="$cy" rx="$rx" ry="$ry" $fillAttr $strokeAttr$transformAttr />';
      case ShapeType.line:
        if (!isStroked) return '';
        final capStr = strokeCap == StrokeCap.round
            ? 'round'
            : (strokeCap == StrokeCap.square ? 'square' : 'butt');
        final markerStart = startCap == LineCapStyle.arrow
            ? ' marker-start="url(#arrow-start-$id)"'
            : '';
        final markerEnd = endCap == LineCapStyle.arrow
            ? ' marker-end="url(#arrow-end-$id)"'
            : '';
        if (isCurved || curvature != 0.0) {
          final p1 = rect.topLeft;
          final p2 = rect.bottomRight;
          final mid = (p1 + p2) / 2;
          final dx = p2.dx - p1.dx;
          final dy = p2.dy - p1.dy;
          final len = math.sqrt(dx * dx + dy * dy);
          final perp = len > 0 ? Offset(-dy / len, dx / len) : Offset.zero;
          final ctrl = mid + perp * curvature;
          return '  <path d="M ${p1.dx} ${p1.dy} Q ${ctrl.dx} ${ctrl.dy} ${p2.dx} ${p2.dy}" fill="none" $strokeAttr stroke-linecap="$capStr"$markerStart$markerEnd$transformAttr />';
        }
        return '  <line x1="${rect.left}" y1="${rect.top}" x2="${rect.right}" y2="${rect.bottom}" $strokeAttr stroke-linecap="$capStr"$markerStart$markerEnd$transformAttr />';
      case ShapeType.star:
        final points = _generateStarPointsSvg(rect);
        return '  <polygon points="$points" $fillAttr $strokeAttr$transformAttr />';
      case ShapeType.text:
        String displayText = textContent;
        switch (textCase) {
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

        final weight = ' font-weight="${fontWeight.value}"';
        final style = isItalic ? ' font-style="italic"' : '';

        // Horizontal text-anchor & position X
        String textAnchor = 'start';
        double posX = rect.left;
        if (textAlign == TextAlign.center) {
          textAnchor = 'middle';
          posX = rect.center.dx;
        } else if (textAlign == TextAlign.right) {
          textAnchor = 'end';
          posX = rect.right;
        }
        final anchorAttr = ' text-anchor="$textAnchor"';

        // Vertical dominant-baseline & position Y
        String dominantBaseline = 'hanging';
        double posY = rect.top;
        if (textVerticalAlign == TextVerticalAlign.center) {
          dominantBaseline = 'central';
          posY = rect.center.dy;
        } else if (textVerticalAlign == TextVerticalAlign.bottom) {
          dominantBaseline = 'auto';
          posY = rect.bottom;
        }
        final baselineAttr = ' dominant-baseline="$dominantBaseline"';

        final letterSpacingAttr = letterSpacing != 0.0
            ? ' letter-spacing="${letterSpacing}px"'
            : '';

        final decList = <String>[];
        if (isUnderline) decList.add('underline');
        if (isStrikethrough) decList.add('line-through');
        final decAttr = decList.isNotEmpty
            ? ' text-decoration="${decList.join(' ')}"'
            : '';

        return '  <text x="$posX" y="$posY" font-family="$fontFamily" font-size="$fontSize" $fillAttr$weight$style$anchorAttr$baselineAttr$letterSpacingAttr$decAttr$transformAttr>${_escapeXml(displayText)}</text>';
      case ShapeType.image:
        if (imageBytes != null) {
          final b64 = base64Encode(imageBytes!);
          return '  <image href="data:image/png;base64,$b64" x="${rect.left}" y="${rect.top}" width="${rect.width}" height="${rect.height}"$transformAttr />';
        }
        return '  <rect x="${rect.left}" y="${rect.top}" width="${rect.width}" height="${rect.height}" fill="#333"$transformAttr />';
    }
  }

  static String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String _generateStarPointsSvg(Rect rect) {
    final center = rect.center;
    final outerRadius = math.min(rect.width, rect.height) / 2;
    final innerRadius = outerRadius * 0.4;
    final pointsList = <String>[];
    const double angleStep = math.pi / 5;

    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? outerRadius : innerRadius;
      final angle = i * angleStep - math.pi / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      pointsList.add('${x.toStringAsFixed(1)},${y.toStringAsFixed(1)}');
    }
    return pointsList.join(' ');
  }

  static String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() +
              (word.length > 1 ? word.substring(1).toLowerCase() : '');
        })
        .join(' ');
  }

  /// Returns a cached [Path] representation of this shape's geometry.
  /// Automatically invalidates whenever rect, cornerRadius, or curvature changes.
  Path getPath() {
    if (_cachedPath != null &&
        _lastPathRect == rect &&
        _lastPathRadius == cornerRadius &&
        _lastTlRadius == topLeftRadius &&
        _lastTrRadius == topRightRadius &&
        _lastBrRadius == bottomRightRadius &&
        _lastBlRadius == bottomLeftRadius &&
        _lastPathCurvature == curvature &&
        _lastPathIsCurved == isCurved &&
        _lastPathType == type) {
      return _cachedPath!;
    }

    final path = Path();
    switch (type) {
      case ShapeType.rectangle:
        path.addRect(rect);
        break;
      case ShapeType.roundedRectangle:
        final maxR = math.min(rect.width, rect.height) / 2;
        if (hasIndependentCorners) {
          path.addRRect(
            RRect.fromRectAndCorners(
              rect,
              topLeft: Radius.circular(effectiveTopLeftRadius.clamp(0.0, maxR)),
              topRight: Radius.circular(effectiveTopRightRadius.clamp(0.0, maxR)),
              bottomRight: Radius.circular(effectiveBottomRightRadius.clamp(0.0, maxR)),
              bottomLeft: Radius.circular(effectiveBottomLeftRadius.clamp(0.0, maxR)),
            ),
          );
        } else {
          path.addRRect(
            RRect.fromRectAndRadius(
              rect,
              Radius.circular(cornerRadius.clamp(0.0, maxR)),
            ),
          );
        }
        break;
      case ShapeType.ellipse:
        path.addOval(rect);
        break;
      case ShapeType.star:
        path.addPath(CanvasGeometry.createStarPath(rect), Offset.zero);
        break;
      case ShapeType.line:
        final p1 = rect.topLeft;
        final p2 = rect.bottomRight;
        if (isCurved || curvature != 0.0) {
          final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
          final dx = p2.dx - p1.dx;
          final dy = p2.dy - p1.dy;
          final len = math.sqrt(dx * dx + dy * dy);
          final perp = len > 0 ? Offset(-dy / len, dx / len) : Offset.zero;
          final controlPt = mid + perp * curvature;
          path.moveTo(p1.dx, p1.dy);
          path.quadraticBezierTo(controlPt.dx, controlPt.dy, p2.dx, p2.dy);
        } else {
          path.moveTo(p1.dx, p1.dy);
          path.lineTo(p2.dx, p2.dy);
        }
        break;
      case ShapeType.text:
      case ShapeType.image:
        path.addRect(rect);
        break;
    }

    _cachedPath = path;
    _lastPathRect = rect;
    _lastPathRadius = cornerRadius;
    _lastTlRadius = topLeftRadius;
    _lastTrRadius = topRightRadius;
    _lastBrRadius = bottomRightRadius;
    _lastBlRadius = bottomLeftRadius;
    _lastPathCurvature = curvature;
    _lastPathIsCurved = isCurved;
    _lastPathType = type;
    return path;
  }

  /// Returns a cached dashed [Path] given [dashLength] and [dashGap].
  Path getDashedPath(double dashLength, double dashGap, StrokeStyle style) {
    final base = getPath();
    if (_cachedDashedPath != null &&
        _lastDashLength == dashLength &&
        _lastDashGap == dashGap &&
        _lastDashStyle == style) {
      return _cachedDashedPath!;
    }
    _cachedDashedPath = CanvasGeometry.dashPath(
      base,
      dashLength: dashLength,
      dashGap: dashGap,
    );
    _lastDashLength = dashLength;
    _lastDashGap = dashGap;
    _lastDashStyle = style;
    return _cachedDashedPath!;
  }

  /// Returns the axis-aligned bounding box accounting for stroke width and rotation.
  /// Computed once and cached until geometry changes.
  Rect getBoundingBox() {
    if (_cachedBoundingBox != null &&
        _lastBBRect == rect &&
        _lastBBRotation == rotation &&
        _lastBBStrokeWidth == strokeWidth &&
        _lastBBIsStroked == isStroked &&
        _lastBBType == type) {
      return _cachedBoundingBox!;
    }

    final rawRect = Rect.fromLTRB(
      math.min(rect.left, rect.right),
      math.min(rect.top, rect.bottom),
      math.max(rect.left, rect.right),
      math.max(rect.top, rect.bottom),
    );

    final strokePadding = type == ShapeType.line
        ? math.max(3.0, strokeWidth / 2)
        : (isStroked ? strokeWidth / 2 : 0.0);
    final paddedRect = rawRect.inflate(strokePadding);

    if (rotation == 0.0) {
      _cachedBoundingBox = paddedRect;
      _lastBBRect = rect;
      _lastBBRotation = rotation;
      _lastBBStrokeWidth = strokeWidth;
      _lastBBIsStroked = isStroked;
      _lastBBType = type;
      return paddedRect;
    }

    final center = rect.center;
    final rad = rotation * math.pi / 180.0;
    final cosVal = math.cos(rad);
    final sinVal = math.sin(rad);

    final tlX = paddedRect.left - center.dx;
    final tlY = paddedRect.top - center.dy;
    final r1X = center.dx + tlX * cosVal - tlY * sinVal;
    final r1Y = center.dy + tlX * sinVal + tlY * cosVal;

    final trX = paddedRect.right - center.dx;
    final trY = paddedRect.top - center.dy;
    final r2X = center.dx + trX * cosVal - trY * sinVal;
    final r2Y = center.dy + trX * sinVal + trY * cosVal;

    final brX = paddedRect.right - center.dx;
    final brY = paddedRect.bottom - center.dy;
    final r3X = center.dx + brX * cosVal - brY * sinVal;
    final r3Y = center.dy + brX * sinVal + brY * cosVal;

    final blX = paddedRect.left - center.dx;
    final blY = paddedRect.bottom - center.dy;
    final r4X = center.dx + blX * cosVal - blY * sinVal;
    final r4Y = center.dy + blX * sinVal + blY * cosVal;

    final minX = math.min(math.min(r1X, r2X), math.min(r3X, r4X));
    final maxX = math.max(math.max(r1X, r2X), math.max(r3X, r4X));
    final minY = math.min(math.min(r1Y, r2Y), math.min(r3Y, r4Y));
    final maxY = math.max(math.max(r1Y, r2Y), math.max(r3Y, r4Y));

    final computed = Rect.fromLTRB(minX, minY, maxX, maxY);
    _cachedBoundingBox = computed;
    _lastBBRect = rect;
    _lastBBRotation = rotation;
    _lastBBStrokeWidth = strokeWidth;
    _lastBBIsStroked = isStroked;
    _lastBBType = type;
    return computed;
  }

  /// Returns the resolved [TextStyle] for typography shapes matching canvas metrics.
  TextStyle getTextStyle({Paint? fillPaint}) {
    final effectiveColor = fillColor.withValues(alpha: fillOpacity);
    final textDecorations = <TextDecoration>[];
    if (isUnderline) textDecorations.add(TextDecoration.underline);
    if (isStrikethrough) textDecorations.add(TextDecoration.lineThrough);
    final decoration = textDecorations.isNotEmpty
        ? TextDecoration.combine(textDecorations)
        : TextDecoration.none;

    final isGradientText =
        fillType != PaintFillType.solid && fillGradient != null;

    try {
      return GoogleFonts.getFont(
        fontFamily,
        color: isGradientText ? null : effectiveColor,
        foreground: isGradientText ? fillPaint : null,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
        letterSpacing: letterSpacing != 0.0 ? letterSpacing : null,
        height: lineHeight,
        decoration: decoration,
        decorationColor: effectiveColor,
      );
    } catch (_) {
      return TextStyle(
        color: isGradientText ? null : effectiveColor,
        foreground: isGradientText ? fillPaint : null,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
        fontFamily: fontFamily,
        letterSpacing: letterSpacing != 0.0 ? letterSpacing : null,
        height: lineHeight,
        decoration: decoration,
        decorationColor: effectiveColor,
      );
    }
  }

  /// Returns cached [TextPainter] for typography shapes.
  TextPainter getTextPainter({Paint? fillPaint}) {
    final effectiveColor = fillColor.withValues(alpha: fillOpacity);
    if (_cachedTextPainter != null &&
        _lastTextContent == textContent &&
        _lastTextFontSize == fontSize &&
        _lastTextFontFamily == fontFamily &&
        _lastTextFontWeight == fontWeight &&
        _lastTextIsItalic == isItalic &&
        _lastTextIsUnderline == isUnderline &&
        _lastTextIsStrikethrough == isStrikethrough &&
        _lastTextAlign == textAlign &&
        _lastTextLetterSpacing == letterSpacing &&
        _lastTextLineHeight == lineHeight &&
        _lastTextCase == textCase &&
        _lastTextColor == effectiveColor &&
        _lastTextFillType == fillType &&
        _lastTextFillGradient == fillGradient &&
        _lastTextFillOpacity == fillOpacity &&
        _lastTextRectWidth == rect.width) {
      return _cachedTextPainter!;
    }

    String displayText = textContent;
    switch (textCase) {
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

    final textStyle = getTextStyle(fillPaint: fillPaint);

    final layoutWidth = math.max(10.0, rect.width);
    final painter = TextPainter(
      text: TextSpan(text: displayText, style: textStyle),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    );
    painter.layout(minWidth: layoutWidth, maxWidth: layoutWidth);

    _cachedTextPainter = painter;
    _lastTextContent = textContent;
    _lastTextFontSize = fontSize;
    _lastTextFontFamily = fontFamily;
    _lastTextFontWeight = fontWeight;
    _lastTextIsItalic = isItalic;
    _lastTextIsUnderline = isUnderline;
    _lastTextIsStrikethrough = isStrikethrough;
    _lastTextAlign = textAlign;
    _lastTextLetterSpacing = letterSpacing;
    _lastTextLineHeight = lineHeight;
    _lastTextCase = textCase;
    _lastTextColor = effectiveColor;
    _lastTextFillType = fillType;
    _lastTextFillGradient = fillGradient;
    _lastTextFillOpacity = fillOpacity;
    _lastTextRectWidth = rect.width;

    return painter;
  }

  /// Clears all memoized caches when shape undergoes deep modifications.
  void invalidateCache() {
    _cachedPath = null;
    _cachedDashedPath = null;
    _cachedBoundingBox = null;
    _cachedTextPainter = null;
  }
}
