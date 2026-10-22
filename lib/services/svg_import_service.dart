import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nixsvg/calculations/svg_path_parser.dart';
import 'package:nixsvg/models/vector_shape.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:xml/xml.dart';

/// Style context passed down the SVG XML hierarchy (cascaded from `<g>` elements).
class _SvgStyleContext {
  final Color? fillColor;
  final bool? isFilled;
  final double fillOpacity;
  final PaintFillType? fillType;
  final ShapeGradient? fillGradient;

  final Color? strokeColor;
  final bool? isStroked;
  final double strokeWidth;
  final double strokeOpacity;
  final StrokeStyle strokeStyle;
  final StrokeCap strokeCap;
  final double strokeDashLength;
  final double strokeDashGap;

  final double opacity;
  final vm.Matrix4 transform;
  final String? groupId;
  final String? groupName;

  _SvgStyleContext({
    this.fillColor = const Color(0xFF000000),
    this.isFilled = true,
    this.fillOpacity = 1.0,
    this.fillType = PaintFillType.solid,
    this.fillGradient,
    this.strokeColor,
    this.isStroked = false,
    this.strokeWidth = 1.0,
    this.strokeOpacity = 1.0,
    this.strokeStyle = StrokeStyle.solid,
    this.strokeCap = StrokeCap.butt,
    this.strokeDashLength = 5.0,
    this.strokeDashGap = 5.0,
    this.opacity = 1.0,
    vm.Matrix4? transform,
    this.groupId,
    this.groupName,
  }) : transform = transform ?? vm.Matrix4.identity();

  _SvgStyleContext copyWith({
    Color? fillColor,
    bool? isFilled,
    double? fillOpacity,
    PaintFillType? fillType,
    ShapeGradient? fillGradient,
    Color? strokeColor,
    bool? isStroked,
    double? strokeWidth,
    double? strokeOpacity,
    StrokeStyle? strokeStyle,
    StrokeCap? strokeCap,
    double? strokeDashLength,
    double? strokeDashGap,
    double? opacity,
    vm.Matrix4? transform,
    String? groupId,
    String? groupName,
  }) {
    return _SvgStyleContext(
      fillColor: fillColor ?? this.fillColor,
      isFilled: isFilled ?? this.isFilled,
      fillOpacity: fillOpacity ?? this.fillOpacity,
      fillType: fillType ?? this.fillType,
      fillGradient: fillGradient ?? this.fillGradient,
      strokeColor: strokeColor ?? this.strokeColor,
      isStroked: isStroked ?? this.isStroked,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeOpacity: strokeOpacity ?? this.strokeOpacity,
      strokeStyle: strokeStyle ?? this.strokeStyle,
      strokeCap: strokeCap ?? this.strokeCap,
      strokeDashLength: strokeDashLength ?? this.strokeDashLength,
      strokeDashGap: strokeDashGap ?? this.strokeDashGap,
      opacity: opacity ?? this.opacity,
      transform: transform ?? this.transform.clone(),
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
    );
  }
}

/// Service that parses standard SVG documents and XML snippets into native nixSVG [VectorShape] models.
class SvgImportService {
  const SvgImportService._();

  /// Parses [svgString] into a list of [VectorShape] models.
  /// If [targetOrigin] is supplied, centers the collective bounds of the imported shapes at [targetOrigin].
  static List<VectorShape> parseSvg(
    String svgString, {
    Offset? targetOrigin,
  }) {
    final shapes = <VectorShape>[];
    if (svgString.trim().isEmpty) return shapes;

    try {
      final document = XmlDocument.parse(svgString);
      final svgElement = document.findAllElements('svg').firstOrNull ?? document.rootElement;

      final gradientMap = <String, ShapeGradient>{};
      _parseDefs(document, gradientMap);

      final initialContext = _SvgStyleContext();
      _traverseElement(svgElement, initialContext, gradientMap, shapes);

      if (shapes.isEmpty) return shapes;

      // Center around targetOrigin if requested
      if (targetOrigin != null) {
        Rect combined = shapes.first.getBoundingBox();
        for (int i = 1; i < shapes.length; i++) {
          combined = combined.expandToInclude(shapes[i].getBoundingBox());
        }

        final delta = targetOrigin - combined.center;
        for (final s in shapes) {
          s.rect = s.rect.shift(delta);
          if (s.customPath != null) {
            s.customPath = s.customPath!.shift(delta);
          }
          if (s.pathData != null) {
            final p = SvgPathParser.parse(s.pathData!).shift(delta);
            s.pathData = SvgPathParser.pathToSvgData(p);
          }
          s.invalidateCache();
        }
      }
    } catch (e) {
      debugPrint('SvgImportService parse error: $e');
    }

    return shapes;
  }

  static void _parseDefs(XmlDocument doc, Map<String, ShapeGradient> gradientMap) {
    for (final defs in doc.findAllElements('defs')) {
      for (final grad in defs.children.whereType<XmlElement>()) {
        final id = grad.getAttribute('id');
        if (id == null) continue;

        final stops = <GradientColorStop>[];
        for (final stopElem in grad.findElements('stop')) {
          final offsetStr = stopElem.getAttribute('offset') ?? '0';
          double offset = 0.0;
          if (offsetStr.endsWith('%')) {
            offset = (double.tryParse(offsetStr.replaceAll('%', '')) ?? 0.0) / 100.0;
          } else {
            offset = double.tryParse(offsetStr) ?? 0.0;
          }

          final stopColorStr = stopElem.getAttribute('stop-color') ?? '#000000';
          final stopOpacityStr = stopElem.getAttribute('stop-opacity') ?? '1.0';
          final stopOpacity = (double.tryParse(stopOpacityStr) ?? 1.0).clamp(0.0, 1.0);
          final baseColor = _parseColor(stopColorStr) ?? Colors.black;
          final color = baseColor.withValues(alpha: stopOpacity);

          stops.add(GradientColorStop(offset: offset.clamp(0.0, 1.0), color: color));
        }

        if (stops.isEmpty) {
          stops.add(const GradientColorStop(offset: 0.0, color: Color(0xFF6366F1)));
          stops.add(const GradientColorStop(offset: 1.0, color: Color(0xFF38BDF8)));
        }

        if (grad.name.local == 'linearGradient') {
          gradientMap[id] = ShapeGradient(
            type: PaintFillType.linearGradient,
            stops: stops,
            angle: 90.0,
          );
        } else if (grad.name.local == 'radialGradient') {
          gradientMap[id] = ShapeGradient(
            type: PaintFillType.radialGradient,
            stops: stops,
          );
        }
      }
    }
  }

  static void _traverseElement(
    XmlElement element,
    _SvgStyleContext parentContext,
    Map<String, ShapeGradient> gradients,
    List<VectorShape> output,
  ) {
    final currentContext = _buildStyleContext(element, parentContext, gradients);

    final localName = element.name.local.toLowerCase();

    switch (localName) {
      case 'rect':
        _parseRect(element, currentContext, output);
        break;
      case 'circle':
        _parseCircle(element, currentContext, output);
        break;
      case 'ellipse':
        _parseEllipse(element, currentContext, output);
        break;
      case 'line':
        _parseLine(element, currentContext, output);
        break;
      case 'polygon':
        _parsePolygon(element, currentContext, output, isClosed: true);
        break;
      case 'polyline':
        _parsePolygon(element, currentContext, output, isClosed: false);
        break;
      case 'path':
        _parsePath(element, currentContext, output);
        break;
      case 'text':
        _parseText(element, currentContext, output);
        break;
      case 'g':
      case 'svg':
        for (final child in element.children.whereType<XmlElement>()) {
          _traverseElement(child, currentContext, gradients, output);
        }
        break;
    }
  }

  static _SvgStyleContext _buildStyleContext(
    XmlElement element,
    _SvgStyleContext parent,
    Map<String, ShapeGradient> gradients,
  ) {
    // Parse style attribute if present
    final styleMap = <String, String>{};
    final styleAttr = element.getAttribute('style');
    if (styleAttr != null) {
      for (final part in styleAttr.split(';')) {
        final kv = part.split(':');
        if (kv.length == 2) {
          styleMap[kv[0].trim().toLowerCase()] = kv[1].trim();
        }
      }
    }

    String? getAttr(String name) => styleMap[name] ?? element.getAttribute(name);

    Color? fillColor = parent.fillColor;
    bool isFilled = parent.isFilled ?? true;
    double fillOpacity = parent.fillOpacity;
    PaintFillType fillType = parent.fillType ?? PaintFillType.solid;
    ShapeGradient? fillGradient = parent.fillGradient;

    final fillStr = getAttr('fill');
    if (fillStr != null) {
      if (fillStr == 'none') {
        isFilled = false;
      } else if (fillStr.startsWith('url(#') && fillStr.endsWith(')')) {
        final gradId = fillStr.substring(5, fillStr.length - 1);
        if (gradients.containsKey(gradId)) {
          fillGradient = gradients[gradId];
          fillType = fillGradient!.type;
          isFilled = true;
        }
      } else {
        final c = _parseColor(fillStr);
        if (c != null) {
          fillColor = c;
          isFilled = true;
          fillType = PaintFillType.solid;
        }
      }
    }

    final fillOpStr = getAttr('fill-opacity');
    if (fillOpStr != null) {
      fillOpacity = (double.tryParse(fillOpStr) ?? fillOpacity).clamp(0.0, 1.0);
    }

    Color? strokeColor = parent.strokeColor;
    bool isStroked = parent.isStroked ?? false;
    double strokeWidth = parent.strokeWidth;
    double strokeOpacity = parent.strokeOpacity;
    StrokeStyle strokeStyle = parent.strokeStyle;
    StrokeCap strokeCap = parent.strokeCap;
    double strokeDashLength = parent.strokeDashLength;
    double strokeDashGap = parent.strokeDashGap;

    final strokeStr = getAttr('stroke');
    if (strokeStr != null) {
      if (strokeStr == 'none') {
        isStroked = false;
      } else {
        final c = _parseColor(strokeStr);
        if (c != null) {
          strokeColor = c;
          isStroked = true;
        }
      }
    }

    final strokeWidthStr = getAttr('stroke-width');
    if (strokeWidthStr != null) {
      strokeWidth = (double.tryParse(strokeWidthStr.replaceAll('px', '')) ?? strokeWidth).clamp(0.5, 100.0);
      if (strokeStr == null && parent.isStroked == true) {
        isStroked = true;
      }
    }

    final strokeOpStr = getAttr('stroke-opacity');
    if (strokeOpStr != null) {
      strokeOpacity = (double.tryParse(strokeOpStr) ?? strokeOpacity).clamp(0.0, 1.0);
    }

    final dashStr = getAttr('stroke-dasharray');
    if (dashStr != null && dashStr != 'none') {
      final parts = dashStr.split(RegExp(r'[\s,]+')).map((s) => double.tryParse(s) ?? 5.0).toList();
      if (parts.isNotEmpty) {
        strokeDashLength = parts[0];
        strokeDashGap = parts.length > 1 ? parts[1] : parts[0];
        strokeStyle = StrokeStyle.dashed;
      }
    }

    final capStr = getAttr('stroke-linecap');
    if (capStr != null) {
      if (capStr == 'round') strokeCap = StrokeCap.round;
      if (capStr == 'square') strokeCap = StrokeCap.square;
    }

    double opacity = parent.opacity;
    final opStr = getAttr('opacity');
    if (opStr != null) {
      opacity *= (double.tryParse(opStr) ?? 1.0).clamp(0.0, 1.0);
    }

    // Accumulate transform
    var matrix = parent.transform.clone();
    final transformStr = getAttr('transform');
    if (transformStr != null) {
      final localMatrix = _parseTransform(transformStr);
      matrix = matrix * localMatrix;
    }

    String? groupId = parent.groupId;
    String? groupName = parent.groupName;
    if (element.name.local == 'g') {
      groupId = element.getAttribute('id') ?? groupId;
      groupName = element.getAttribute('name') ?? element.getAttribute('id') ?? groupName;
    }

    return parent.copyWith(
      fillColor: fillColor,
      isFilled: isFilled,
      fillOpacity: fillOpacity,
      fillType: fillType,
      fillGradient: fillGradient,
      strokeColor: strokeColor,
      isStroked: isStroked,
      strokeWidth: strokeWidth,
      strokeOpacity: strokeOpacity,
      strokeStyle: strokeStyle,
      strokeCap: strokeCap,
      strokeDashLength: strokeDashLength,
      strokeDashGap: strokeDashGap,
      opacity: opacity,
      transform: matrix,
      groupId: groupId,
      groupName: groupName,
    );
  }

  static void _parseRect(
    XmlElement elem,
    _SvgStyleContext ctx,
    List<VectorShape> output,
  ) {
    final x = double.tryParse(elem.getAttribute('x') ?? '0') ?? 0.0;
    final y = double.tryParse(elem.getAttribute('y') ?? '0') ?? 0.0;
    final w = double.tryParse(elem.getAttribute('width') ?? '0') ?? 0.0;
    final h = double.tryParse(elem.getAttribute('height') ?? '0') ?? 0.0;
    if (w <= 0 || h <= 0) return;

    final rxStr = elem.getAttribute('rx');
    final ryStr = elem.getAttribute('ry');
    final rx = double.tryParse(rxStr ?? ryStr ?? '0') ?? 0.0;

    final localRect = Rect.fromLTWH(x, y, w, h);
    final (transformedRect, rotation) = _transformRect(localRect, ctx.transform);

    final name = elem.getAttribute('id') ?? 'Rectangle ${output.length + 1}';
    output.add(
      VectorShape(
        id: 'shape-${DateTime.now().millisecondsSinceEpoch}-${output.length}',
        name: name,
        type: rx > 0 ? ShapeType.roundedRectangle : ShapeType.rectangle,
        rect: transformedRect,
        cornerRadius: rx,
        rotation: rotation,
        fillColor: ctx.fillColor ?? Colors.black,
        isFilled: ctx.isFilled ?? true,
        fillOpacity: (ctx.fillOpacity * ctx.opacity).clamp(0.0, 1.0),
        fillType: ctx.fillType ?? PaintFillType.solid,
        fillGradient: ctx.fillGradient,
        strokeColor: ctx.strokeColor ?? Colors.black,
        isStroked: ctx.isStroked ?? false,
        strokeWidth: ctx.strokeWidth,
        strokeOpacity: (ctx.strokeOpacity * ctx.opacity).clamp(0.0, 1.0),
        strokeStyle: ctx.strokeStyle,
        strokeCap: ctx.strokeCap,
        strokeDashLength: ctx.strokeDashLength,
        strokeDashGap: ctx.strokeDashGap,
        groupId: ctx.groupId,
        groupName: ctx.groupName,
      ),
    );
  }

  static void _parseCircle(
    XmlElement elem,
    _SvgStyleContext ctx,
    List<VectorShape> output,
  ) {
    final cx = double.tryParse(elem.getAttribute('cx') ?? '0') ?? 0.0;
    final cy = double.tryParse(elem.getAttribute('cy') ?? '0') ?? 0.0;
    final r = double.tryParse(elem.getAttribute('r') ?? '0') ?? 0.0;
    if (r <= 0) return;

    final localRect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    final (transformedRect, rotation) = _transformRect(localRect, ctx.transform);

    final name = elem.getAttribute('id') ?? 'Circle ${output.length + 1}';
    output.add(
      VectorShape(
        id: 'shape-${DateTime.now().millisecondsSinceEpoch}-${output.length}',
        name: name,
        type: ShapeType.ellipse,
        rect: transformedRect,
        rotation: rotation,
        fillColor: ctx.fillColor ?? Colors.black,
        isFilled: ctx.isFilled ?? true,
        fillOpacity: (ctx.fillOpacity * ctx.opacity).clamp(0.0, 1.0),
        fillType: ctx.fillType ?? PaintFillType.solid,
        fillGradient: ctx.fillGradient,
        strokeColor: ctx.strokeColor ?? Colors.black,
        isStroked: ctx.isStroked ?? false,
        strokeWidth: ctx.strokeWidth,
        strokeOpacity: (ctx.strokeOpacity * ctx.opacity).clamp(0.0, 1.0),
        strokeStyle: ctx.strokeStyle,
        strokeCap: ctx.strokeCap,
        strokeDashLength: ctx.strokeDashLength,
        strokeDashGap: ctx.strokeDashGap,
        groupId: ctx.groupId,
        groupName: ctx.groupName,
      ),
    );
  }

  static void _parseEllipse(
    XmlElement elem,
    _SvgStyleContext ctx,
    List<VectorShape> output,
  ) {
    final cx = double.tryParse(elem.getAttribute('cx') ?? '0') ?? 0.0;
    final cy = double.tryParse(elem.getAttribute('cy') ?? '0') ?? 0.0;
    final rx = double.tryParse(elem.getAttribute('rx') ?? '0') ?? 0.0;
    final ry = double.tryParse(elem.getAttribute('ry') ?? '0') ?? 0.0;
    if (rx <= 0 || ry <= 0) return;

    final localRect = Rect.fromLTWH(cx - rx, cy - ry, rx * 2, ry * 2);
    final (transformedRect, rotation) = _transformRect(localRect, ctx.transform);

    final name = elem.getAttribute('id') ?? 'Ellipse ${output.length + 1}';
    output.add(
      VectorShape(
        id: 'shape-${DateTime.now().millisecondsSinceEpoch}-${output.length}',
        name: name,
        type: ShapeType.ellipse,
        rect: transformedRect,
        rotation: rotation,
        fillColor: ctx.fillColor ?? Colors.black,
        isFilled: ctx.isFilled ?? true,
        fillOpacity: (ctx.fillOpacity * ctx.opacity).clamp(0.0, 1.0),
        fillType: ctx.fillType ?? PaintFillType.solid,
        fillGradient: ctx.fillGradient,
        strokeColor: ctx.strokeColor ?? Colors.black,
        isStroked: ctx.isStroked ?? false,
        strokeWidth: ctx.strokeWidth,
        strokeOpacity: (ctx.strokeOpacity * ctx.opacity).clamp(0.0, 1.0),
        strokeStyle: ctx.strokeStyle,
        strokeCap: ctx.strokeCap,
        strokeDashLength: ctx.strokeDashLength,
        strokeDashGap: ctx.strokeDashGap,
        groupId: ctx.groupId,
        groupName: ctx.groupName,
      ),
    );
  }

  static void _parseLine(
    XmlElement elem,
    _SvgStyleContext ctx,
    List<VectorShape> output,
  ) {
    final x1 = double.tryParse(elem.getAttribute('x1') ?? '0') ?? 0.0;
    final y1 = double.tryParse(elem.getAttribute('y1') ?? '0') ?? 0.0;
    final x2 = double.tryParse(elem.getAttribute('x2') ?? '0') ?? 0.0;
    final y2 = double.tryParse(elem.getAttribute('y2') ?? '0') ?? 0.0;

    final p1 = _transformOffset(Offset(x1, y1), ctx.transform);
    final p2 = _transformOffset(Offset(x2, y2), ctx.transform);

    final rect = Rect.fromPoints(p1, p2);
    final name = elem.getAttribute('id') ?? 'Line ${output.length + 1}';

    output.add(
      VectorShape(
        id: 'shape-${DateTime.now().millisecondsSinceEpoch}-${output.length}',
        name: name,
        type: ShapeType.line,
        rect: rect,
        strokeColor: ctx.strokeColor ?? ctx.fillColor ?? Colors.black,
        isStroked: true,
        isFilled: false,
        strokeWidth: ctx.strokeWidth,
        strokeOpacity: (ctx.strokeOpacity * ctx.opacity).clamp(0.0, 1.0),
        strokeStyle: ctx.strokeStyle,
        strokeCap: ctx.strokeCap,
        strokeDashLength: ctx.strokeDashLength,
        strokeDashGap: ctx.strokeDashGap,
        groupId: ctx.groupId,
        groupName: ctx.groupName,
      ),
    );
  }

  static void _parsePolygon(
    XmlElement elem,
    _SvgStyleContext ctx,
    List<VectorShape> output, {
    required bool isClosed,
  }) {
    final pointsStr = elem.getAttribute('points');
    if (pointsStr == null || pointsStr.trim().isEmpty) return;

    final tokens = pointsStr.trim().split(RegExp(r'[\s,]+')).where((s) => s.isNotEmpty).toList();
    if (tokens.length < 4) return;

    final path = Path();
    final firstX = double.tryParse(tokens[0]) ?? 0.0;
    final firstY = double.tryParse(tokens[1]) ?? 0.0;
    path.moveTo(firstX, firstY);

    for (int i = 2; i + 1 < tokens.length; i += 2) {
      final x = double.tryParse(tokens[i]) ?? 0.0;
      final y = double.tryParse(tokens[i + 1]) ?? 0.0;
      path.lineTo(x, y);
    }
    if (isClosed) path.close();

    final transformedPath = path.transform(ctx.transform.storage);
    final bounds = transformedPath.getBounds();
    final svgData = SvgPathParser.pathToSvgData(transformedPath);

    final name = elem.getAttribute('id') ?? (isClosed ? 'Polygon ${output.length + 1}' : 'Polyline ${output.length + 1}');

    output.add(
      VectorShape(
        id: 'shape-${DateTime.now().millisecondsSinceEpoch}-${output.length}',
        name: name,
        type: ShapeType.path,
        rect: bounds,
        pathData: svgData,
        customPath: transformedPath,
        fillColor: ctx.fillColor ?? Colors.black,
        isFilled: isClosed ? (ctx.isFilled ?? true) : false,
        fillOpacity: (ctx.fillOpacity * ctx.opacity).clamp(0.0, 1.0),
        fillType: ctx.fillType ?? PaintFillType.solid,
        fillGradient: ctx.fillGradient,
        strokeColor: ctx.strokeColor ?? Colors.black,
        isStroked: ctx.isStroked ?? (!isClosed),
        strokeWidth: ctx.strokeWidth,
        strokeOpacity: (ctx.strokeOpacity * ctx.opacity).clamp(0.0, 1.0),
        strokeStyle: ctx.strokeStyle,
        strokeCap: ctx.strokeCap,
        strokeDashLength: ctx.strokeDashLength,
        strokeDashGap: ctx.strokeDashGap,
        groupId: ctx.groupId,
        groupName: ctx.groupName,
      ),
    );
  }

  static void _parsePath(
    XmlElement elem,
    _SvgStyleContext ctx,
    List<VectorShape> output,
  ) {
    final d = elem.getAttribute('d');
    if (d == null || d.trim().isEmpty) return;

    final parsedPath = SvgPathParser.parse(d);
    final transformedPath = parsedPath.transform(ctx.transform.storage);
    final bounds = transformedPath.getBounds();
    if (bounds.width <= 0 && bounds.height <= 0) return;

    final svgData = SvgPathParser.pathToSvgData(transformedPath);
    final name = elem.getAttribute('id') ?? 'Path ${output.length + 1}';

    output.add(
      VectorShape(
        id: 'shape-${DateTime.now().millisecondsSinceEpoch}-${output.length}',
        name: name,
        type: ShapeType.path,
        rect: bounds,
        pathData: svgData,
        customPath: transformedPath,
        fillColor: ctx.fillColor ?? Colors.black,
        isFilled: ctx.isFilled ?? true,
        fillOpacity: (ctx.fillOpacity * ctx.opacity).clamp(0.0, 1.0),
        fillType: ctx.fillType ?? PaintFillType.solid,
        fillGradient: ctx.fillGradient,
        strokeColor: ctx.strokeColor ?? Colors.black,
        isStroked: ctx.isStroked ?? false,
        strokeWidth: ctx.strokeWidth,
        strokeOpacity: (ctx.strokeOpacity * ctx.opacity).clamp(0.0, 1.0),
        strokeStyle: ctx.strokeStyle,
        strokeCap: ctx.strokeCap,
        strokeDashLength: ctx.strokeDashLength,
        strokeDashGap: ctx.strokeDashGap,
        groupId: ctx.groupId,
        groupName: ctx.groupName,
      ),
    );
  }

  static void _parseText(
    XmlElement elem,
    _SvgStyleContext ctx,
    List<VectorShape> output,
  ) {
    final x = double.tryParse(elem.getAttribute('x') ?? '0') ?? 0.0;
    final y = double.tryParse(elem.getAttribute('y') ?? '0') ?? 0.0;
    final fontSize = double.tryParse(elem.getAttribute('font-size')?.replaceAll('px', '') ?? '16') ?? 16.0;
    final fontFamily = elem.getAttribute('font-family') ?? 'Google Sans';
    final text = elem.innerText.trim();
    if (text.isEmpty) return;

    final pt = _transformOffset(Offset(x, y), ctx.transform);
    final rect = Rect.fromLTWH(pt.dx, pt.dy, text.length * fontSize * 0.6, fontSize * 1.3);

    final name = elem.getAttribute('id') ?? 'Text ${output.length + 1}';

    output.add(
      VectorShape(
        id: 'shape-${DateTime.now().millisecondsSinceEpoch}-${output.length}',
        name: name,
        type: ShapeType.text,
        rect: rect,
        textContent: text,
        fontFamily: fontFamily,
        fontSize: fontSize,
        fillColor: ctx.fillColor ?? Colors.black,
        isFilled: true,
        fillOpacity: (ctx.fillOpacity * ctx.opacity).clamp(0.0, 1.0),
        isStroked: false,
        groupId: ctx.groupId,
        groupName: ctx.groupName,
      ),
    );
  }

  static vm.Matrix4 _parseTransform(String transform) {
    var matrix = vm.Matrix4.identity();
    final regExp = RegExp(r'(\w+)\s*\(([^)]+)\)');
    for (final match in regExp.allMatches(transform)) {
      final name = match.group(1)?.toLowerCase();
      final argsStr = match.group(2) ?? '';
      final args = argsStr.split(RegExp(r'[\s,]+')).where((s) => s.isNotEmpty).map((s) => double.tryParse(s) ?? 0.0).toList();

      switch (name) {
        case 'translate':
          if (args.isNotEmpty) {
            final tx = args[0];
            final ty = args.length > 1 ? args[1] : 0.0;
            matrix = matrix * vm.Matrix4.translationValues(tx, ty, 0.0);
          }
          break;
        case 'scale':
          if (args.isNotEmpty) {
            final sx = args[0];
            final sy = args.length > 1 ? args[1] : sx;
            matrix = matrix * vm.Matrix4.diagonal3Values(sx, sy, 1.0);
          }
          break;
        case 'rotate':
          if (args.isNotEmpty) {
            final deg = args[0];
            final rad = deg * (math.pi / 180.0);
            if (args.length >= 3) {
              final cx = args[1];
              final cy = args[2];
              matrix = matrix * vm.Matrix4.translationValues(cx, cy, 0.0);
              matrix = matrix * vm.Matrix4.rotationZ(rad);
              matrix = matrix * vm.Matrix4.translationValues(-cx, -cy, 0.0);
            } else {
              matrix = matrix * vm.Matrix4.rotationZ(rad);
            }
          }
          break;
        case 'matrix':
          if (args.length == 6) {
            final a = args[0];
            final b = args[1];
            final c = args[2];
            final d = args[3];
            final e = args[4];
            final f = args[5];
            final affine = vm.Matrix4.fromList([
              a, b, 0, 0,
              c, d, 0, 0,
              0, 0, 1, 0,
              e, f, 0, 1,
            ]);
            matrix = matrix * affine;
          }
          break;
      }
    }
    return matrix;
  }

  static (Rect, double) _transformRect(Rect rect, vm.Matrix4 matrix) {
    if (matrix.isIdentity()) return (rect, 0.0);
    final p1 = _transformOffset(rect.topLeft, matrix);
    final p2 = _transformOffset(rect.topRight, matrix);
    final p3 = _transformOffset(rect.bottomLeft, matrix);
    final p4 = _transformOffset(rect.bottomRight, matrix);

    final minX = math.min(math.min(p1.dx, p2.dx), math.min(p3.dx, p4.dx));
    final maxX = math.max(math.max(p1.dx, p2.dx), math.max(p3.dx, p4.dx));
    final minY = math.min(math.min(p1.dy, p2.dy), math.min(p3.dy, p4.dy));
    final maxY = math.max(math.max(p1.dy, p2.dy), math.max(p3.dy, p4.dy));

    return (Rect.fromLTRB(minX, minY, maxX, maxY), 0.0);
  }

  static Offset _transformOffset(Offset offset, vm.Matrix4 matrix) {
    final v = matrix.transform3(vm.Vector3(offset.dx, offset.dy, 0.0));
    return Offset(v.x, v.y);
  }

  static Color? _parseColor(String? colorStr) {
    if (colorStr == null) return null;
    final trimmed = colorStr.trim().toLowerCase();
    if (trimmed == 'none' || trimmed == 'transparent') return Colors.transparent;

    const namedColors = <String, Color>{
      'black': Colors.black,
      'white': Colors.white,
      'red': Colors.red,
      'green': Colors.green,
      'blue': Colors.blue,
      'yellow': Colors.yellow,
      'cyan': Colors.cyan,
      'magenta': Colors.purpleAccent,
      'purple': Colors.purple,
      'orange': Colors.orange,
      'gray': Colors.grey,
      'grey': Colors.grey,
      'pink': Colors.pink,
      'teal': Colors.teal,
      'indigo': Colors.indigo,
      'brown': Colors.brown,
      'amber': Colors.amber,
      'lime': Colors.lime,
      'navy': Color(0xFF000080),
      'gold': Color(0xFFFFD700),
      'silver': Color(0xFFC0C0C0),
      'maroon': Color(0xFF800000),
      'olive': Color(0xFF808000),
      'coral': Color(0xFFFF7F50),
      'salmon': Color(0xFFFA8072),
      'khaki': Color(0xFFF0E68C),
      'violet': Color(0xFFEE82EE),
      'turquoise': Color(0xFF40E0D0),
      'plum': Color(0xFFDDA0DD),
    };

    if (namedColors.containsKey(trimmed)) {
      return namedColors[trimmed];
    }

    if (trimmed.startsWith('#')) {
      final hex = trimmed.substring(1);
      if (hex.length == 3) {
        final r = int.parse(hex[0] + hex[0], radix: 16);
        final g = int.parse(hex[1] + hex[1], radix: 16);
        final b = int.parse(hex[2] + hex[2], radix: 16);
        return Color.fromARGB(255, r, g, b);
      } else if (hex.length == 4) {
        final r = int.parse(hex[0] + hex[0], radix: 16);
        final g = int.parse(hex[1] + hex[1], radix: 16);
        final b = int.parse(hex[2] + hex[2], radix: 16);
        final a = int.parse(hex[3] + hex[3], radix: 16);
        return Color.fromARGB(a, r, g, b);
      } else if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    }

    if (trimmed.startsWith('rgb')) {
      final match = RegExp(r'rgba?\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)(?:\s*,\s*([\d.]+))?\s*\)').firstMatch(trimmed);
      if (match != null) {
        final r = int.tryParse(match.group(1)!) ?? 0;
        final g = int.tryParse(match.group(2)!) ?? 0;
        final b = int.tryParse(match.group(3)!) ?? 0;
        final a = (double.tryParse(match.group(4) ?? '1.0') ?? 1.0).clamp(0.0, 1.0);
        return Color.fromRGBO(r, g, b, a);
      }
    }

    return null;
  }
}
