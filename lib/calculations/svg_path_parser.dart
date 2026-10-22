import 'dart:math' as math;
import 'dart:ui';

/// High-precision SVG path data parser and serializer.
/// Supports standard SVG path commands: M, m, L, l, H, h, V, v, C, c, S, s, Q, q, T, t, A, a, Z, z.
class SvgPathParser {
  const SvgPathParser._();

  /// Parses an SVG path data string ([d]) into a Flutter [Path].
  static Path parse(String d) {
    final path = Path();
    if (d.trim().isEmpty) return path;

    final tokens = _tokenize(d);
    if (tokens.isEmpty) return path;

    double currentX = 0.0;
    double currentY = 0.0;
    double startX = 0.0;
    double startY = 0.0;
    double lastControlX = 0.0;
    double lastControlY = 0.0;
    String lastCommand = '';

    int i = 0;
    while (i < tokens.length) {
      final token = tokens[i];
      if (_isCommand(token)) {
        lastCommand = token;
        i++;
      }

      switch (lastCommand) {
        case 'M':
          if (i + 1 < tokens.length && !_isCommand(tokens[i])) {
            final x = double.tryParse(tokens[i++]) ?? currentX;
            final y = double.tryParse(tokens[i++]) ?? currentY;
            path.moveTo(x, y);
            currentX = x;
            currentY = y;
            startX = x;
            startY = y;
            lastControlX = x;
            lastControlY = y;
            // Subsequent coordinate pairs after M are treated as implicit Lineto (L)
            lastCommand = 'L';
          }
          break;

        case 'm':
          if (i + 1 < tokens.length && !_isCommand(tokens[i])) {
            final dx = double.tryParse(tokens[i++]) ?? 0.0;
            final dy = double.tryParse(tokens[i++]) ?? 0.0;
            final x = currentX + dx;
            final y = currentY + dy;
            path.moveTo(x, y);
            currentX = x;
            currentY = y;
            startX = x;
            startY = y;
            lastControlX = x;
            lastControlY = y;
            lastCommand = 'l';
          }
          break;

        case 'L':
          while (i + 1 < tokens.length && !_isCommand(tokens[i])) {
            final x = double.tryParse(tokens[i++]) ?? currentX;
            final y = double.tryParse(tokens[i++]) ?? currentY;
            path.lineTo(x, y);
            currentX = x;
            currentY = y;
            lastControlX = x;
            lastControlY = y;
          }
          break;

        case 'l':
          while (i + 1 < tokens.length && !_isCommand(tokens[i])) {
            final dx = double.tryParse(tokens[i++]) ?? 0.0;
            final dy = double.tryParse(tokens[i++]) ?? 0.0;
            final x = currentX + dx;
            final y = currentY + dy;
            path.lineTo(x, y);
            currentX = x;
            currentY = y;
            lastControlX = x;
            lastControlY = y;
          }
          break;

        case 'H':
          while (i < tokens.length && !_isCommand(tokens[i])) {
            final x = double.tryParse(tokens[i++]) ?? currentX;
            path.lineTo(x, currentY);
            currentX = x;
            lastControlX = x;
            lastControlY = currentY;
          }
          break;

        case 'h':
          while (i < tokens.length && !_isCommand(tokens[i])) {
            final dx = double.tryParse(tokens[i++]) ?? 0.0;
            final x = currentX + dx;
            path.lineTo(x, currentY);
            currentX = x;
            lastControlX = x;
            lastControlY = currentY;
          }
          break;

        case 'V':
          while (i < tokens.length && !_isCommand(tokens[i])) {
            final y = double.tryParse(tokens[i++]) ?? currentY;
            path.lineTo(currentX, y);
            currentY = y;
            lastControlX = currentX;
            lastControlY = y;
          }
          break;

        case 'v':
          while (i < tokens.length && !_isCommand(tokens[i])) {
            final dy = double.tryParse(tokens[i++]) ?? 0.0;
            final y = currentY + dy;
            path.lineTo(currentX, y);
            currentY = y;
            lastControlX = currentX;
            lastControlY = y;
          }
          break;

        case 'C':
          while (i + 5 < tokens.length && !_isCommand(tokens[i])) {
            final x1 = double.tryParse(tokens[i++]) ?? currentX;
            final y1 = double.tryParse(tokens[i++]) ?? currentY;
            final x2 = double.tryParse(tokens[i++]) ?? currentX;
            final y2 = double.tryParse(tokens[i++]) ?? currentY;
            final x = double.tryParse(tokens[i++]) ?? currentX;
            final y = double.tryParse(tokens[i++]) ?? currentY;
            path.cubicTo(x1, y1, x2, y2, x, y);
            lastControlX = x2;
            lastControlY = y2;
            currentX = x;
            currentY = y;
          }
          break;

        case 'c':
          while (i + 5 < tokens.length && !_isCommand(tokens[i])) {
            final dx1 = double.tryParse(tokens[i++]) ?? 0.0;
            final dy1 = double.tryParse(tokens[i++]) ?? 0.0;
            final dx2 = double.tryParse(tokens[i++]) ?? 0.0;
            final dy2 = double.tryParse(tokens[i++]) ?? 0.0;
            final dx = double.tryParse(tokens[i++]) ?? 0.0;
            final dy = double.tryParse(tokens[i++]) ?? 0.0;
            final x1 = currentX + dx1;
            final y1 = currentY + dy1;
            final x2 = currentX + dx2;
            final y2 = currentY + dy2;
            final x = currentX + dx;
            final y = currentY + dy;
            path.cubicTo(x1, y1, x2, y2, x, y);
            lastControlX = x2;
            lastControlY = y2;
            currentX = x;
            currentY = y;
          }
          break;

        case 'S':
          while (i + 3 < tokens.length && !_isCommand(tokens[i])) {
            final x1 = 2 * currentX - lastControlX;
            final y1 = 2 * currentY - lastControlY;
            final x2 = double.tryParse(tokens[i++]) ?? currentX;
            final y2 = double.tryParse(tokens[i++]) ?? currentY;
            final x = double.tryParse(tokens[i++]) ?? currentX;
            final y = double.tryParse(tokens[i++]) ?? currentY;
            path.cubicTo(x1, y1, x2, y2, x, y);
            lastControlX = x2;
            lastControlY = y2;
            currentX = x;
            currentY = y;
          }
          break;

        case 's':
          while (i + 3 < tokens.length && !_isCommand(tokens[i])) {
            final x1 = 2 * currentX - lastControlX;
            final y1 = 2 * currentY - lastControlY;
            final dx2 = double.tryParse(tokens[i++]) ?? 0.0;
            final dy2 = double.tryParse(tokens[i++]) ?? 0.0;
            final dx = double.tryParse(tokens[i++]) ?? 0.0;
            final dy = double.tryParse(tokens[i++]) ?? 0.0;
            final x2 = currentX + dx2;
            final y2 = currentY + dy2;
            final x = currentX + dx;
            final y = currentY + dy;
            path.cubicTo(x1, y1, x2, y2, x, y);
            lastControlX = x2;
            lastControlY = y2;
            currentX = x;
            currentY = y;
          }
          break;

        case 'Q':
          while (i + 3 < tokens.length && !_isCommand(tokens[i])) {
            final x1 = double.tryParse(tokens[i++]) ?? currentX;
            final y1 = double.tryParse(tokens[i++]) ?? currentY;
            final x = double.tryParse(tokens[i++]) ?? currentX;
            final y = double.tryParse(tokens[i++]) ?? currentY;
            path.quadraticBezierTo(x1, y1, x, y);
            lastControlX = x1;
            lastControlY = y1;
            currentX = x;
            currentY = y;
          }
          break;

        case 'q':
          while (i + 3 < tokens.length && !_isCommand(tokens[i])) {
            final dx1 = double.tryParse(tokens[i++]) ?? 0.0;
            final dy1 = double.tryParse(tokens[i++]) ?? 0.0;
            final dx = double.tryParse(tokens[i++]) ?? 0.0;
            final dy = double.tryParse(tokens[i++]) ?? 0.0;
            final x1 = currentX + dx1;
            final y1 = currentY + dy1;
            final x = currentX + dx;
            final y = currentY + dy;
            path.quadraticBezierTo(x1, y1, x, y);
            lastControlX = x1;
            lastControlY = y1;
            currentX = x;
            currentY = y;
          }
          break;

        case 'T':
          while (i + 1 < tokens.length && !_isCommand(tokens[i])) {
            final x1 = 2 * currentX - lastControlX;
            final y1 = 2 * currentY - lastControlY;
            final x = double.tryParse(tokens[i++]) ?? currentX;
            final y = double.tryParse(tokens[i++]) ?? currentY;
            path.quadraticBezierTo(x1, y1, x, y);
            lastControlX = x1;
            lastControlY = y1;
            currentX = x;
            currentY = y;
          }
          break;

        case 't':
          while (i + 1 < tokens.length && !_isCommand(tokens[i])) {
            final x1 = 2 * currentX - lastControlX;
            final y1 = 2 * currentY - lastControlY;
            final dx = double.tryParse(tokens[i++]) ?? 0.0;
            final dy = double.tryParse(tokens[i++]) ?? 0.0;
            final x = currentX + dx;
            final y = currentY + dy;
            path.quadraticBezierTo(x1, y1, x, y);
            lastControlX = x1;
            lastControlY = y1;
            currentX = x;
            currentY = y;
          }
          break;

        case 'A':
          while (i + 6 < tokens.length && !_isCommand(tokens[i])) {
            final rx = (double.tryParse(tokens[i++]) ?? 0.0).abs();
            final ry = (double.tryParse(tokens[i++]) ?? 0.0).abs();
            final xAxisRotation = double.tryParse(tokens[i++]) ?? 0.0;
            final largeArcFlag = (int.tryParse(tokens[i++]) ?? 0) != 0;
            final sweepFlag = (int.tryParse(tokens[i++]) ?? 0) != 0;
            final x = double.tryParse(tokens[i++]) ?? currentX;
            final y = double.tryParse(tokens[i++]) ?? currentY;

            _arcToCubic(
              path,
              currentX,
              currentY,
              rx,
              ry,
              xAxisRotation,
              largeArcFlag,
              sweepFlag,
              x,
              y,
            );
            currentX = x;
            currentY = y;
            lastControlX = x;
            lastControlY = y;
          }
          break;

        case 'a':
          while (i + 6 < tokens.length && !_isCommand(tokens[i])) {
            final rx = (double.tryParse(tokens[i++]) ?? 0.0).abs();
            final ry = (double.tryParse(tokens[i++]) ?? 0.0).abs();
            final xAxisRotation = double.tryParse(tokens[i++]) ?? 0.0;
            final largeArcFlag = (int.tryParse(tokens[i++]) ?? 0) != 0;
            final sweepFlag = (int.tryParse(tokens[i++]) ?? 0) != 0;
            final dx = double.tryParse(tokens[i++]) ?? 0.0;
            final dy = double.tryParse(tokens[i++]) ?? 0.0;
            final x = currentX + dx;
            final y = currentY + dy;

            _arcToCubic(
              path,
              currentX,
              currentY,
              rx,
              ry,
              xAxisRotation,
              largeArcFlag,
              sweepFlag,
              x,
              y,
            );
            currentX = x;
            currentY = y;
            lastControlX = x;
            lastControlY = y;
          }
          break;

        case 'Z':
        case 'z':
          path.close();
          currentX = startX;
          currentY = startY;
          lastControlX = startX;
          lastControlY = startY;
          break;

        default:
          i++;
          break;
      }
    }

    return path;
  }

  /// Converts a Flutter [Path] to an SVG path data string (`d="..."`).
  /// Accurately extracts contours and outputs clean SVG path commands.
  static String pathToSvgData(Path path, {double tolerance = 1.5}) {
    final buffer = StringBuffer();
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      if (metric.length == 0) continue;

      final startTangent = metric.getTangentForOffset(0.0);
      if (startTangent == null) continue;

      buffer.write('M ${startTangent.position.dx.toStringAsFixed(2)} ${startTangent.position.dy.toStringAsFixed(2)} ');

      final step = math.max(0.5, tolerance);
      double distance = step;
      while (distance < metric.length) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          buffer.write('L ${tangent.position.dx.toStringAsFixed(2)} ${tangent.position.dy.toStringAsFixed(2)} ');
        }
        distance += step;
      }

      final endTangent = metric.getTangentForOffset(metric.length);
      if (endTangent != null) {
        buffer.write('L ${endTangent.position.dx.toStringAsFixed(2)} ${endTangent.position.dy.toStringAsFixed(2)} ');
      }

      if (metric.isClosed) {
        buffer.write('Z ');
      }
    }

    return buffer.toString().trim();
  }

  static bool _isCommand(String token) {
    if (token.length != 1) return false;
    return 'MmLlHhVvCcSsQqTtAaZz'.contains(token);
  }

  static List<String> _tokenize(String pathStr) {
    final tokens = <String>[];
    final regExp = RegExp(r'([MmLlHhVvCcSsQqTtAaZz]|[-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?)');
    for (final match in regExp.allMatches(pathStr)) {
      final matchStr = match.group(0);
      if (matchStr != null && matchStr.isNotEmpty) {
        tokens.add(matchStr);
      }
    }
    return tokens;
  }

  /// W3C SVG Arc to cubic Bézier curve decomposition.
  static void _arcToCubic(
    Path path,
    double x1,
    double y1,
    double rx,
    double ry,
    double angleDegrees,
    bool largeArcFlag,
    bool sweepFlag,
    double x2,
    double y2,
  ) {
    if (x1 == x2 && y1 == y2) return;
    if (rx == 0 || ry == 0) {
      path.lineTo(x2, y2);
      return;
    }

    final phi = angleDegrees * (math.pi / 180.0);
    final cosPhi = math.cos(phi);
    final sinPhi = math.sin(phi);

    final dxHalf = (x1 - x2) / 2.0;
    final dyHalf = (y1 - y2) / 2.0;
    final x1Prime = cosPhi * dxHalf + sinPhi * dyHalf;
    final y1Prime = -sinPhi * dxHalf + cosPhi * dyHalf;

    double rxSquare = rx * rx;
    double rySquare = ry * ry;
    final x1PrimeSquare = x1Prime * x1Prime;
    final y1PrimeSquare = y1Prime * y1Prime;

    final radiiCheck = (x1PrimeSquare / rxSquare) + (y1PrimeSquare / rySquare);
    if (radiiCheck > 1.0) {
      final scale = math.sqrt(radiiCheck);
      rx *= scale;
      ry *= scale;
      rxSquare = rx * rx;
      rySquare = ry * ry;
    }

    final sign = (largeArcFlag == sweepFlag) ? -1.0 : 1.0;
    final numerator = rxSquare * rySquare - rxSquare * y1PrimeSquare - rySquare * x1PrimeSquare;
    final denom = rxSquare * y1PrimeSquare + rySquare * x1PrimeSquare;
    final sNumerator = math.max(0.0, numerator);
    final coef = (denom > 0) ? sign * math.sqrt(sNumerator / denom) : 0.0;

    final cxPrime = coef * ((rx * y1Prime) / ry);
    final cyPrime = coef * -((ry * x1Prime) / rx);

    final cx = cosPhi * cxPrime - sinPhi * cyPrime + (x1 + x2) / 2.0;
    final cy = sinPhi * cxPrime + cosPhi * cyPrime + (y1 + y2) / 2.0;

    final ux = (x1Prime - cxPrime) / rx;
    final uy = (y1Prime - cyPrime) / ry;
    final vx = (-x1Prime - cxPrime) / rx;
    final vy = (-y1Prime - cyPrime) / ry;

    double theta1 = _vectorAngle(1.0, 0.0, ux, uy);
    double dTheta = _vectorAngle(ux, uy, vx, vy);

    if (!sweepFlag && dTheta > 0) {
      dTheta -= 2.0 * math.pi;
    } else if (sweepFlag && dTheta < 0) {
      dTheta += 2.0 * math.pi;
    }

    final segments = (dTheta.abs() / (math.pi / 2.0)).ceil();
    final dDelta = dTheta / segments;
    final alpha = 4.0 / 3.0 * math.tan(dDelta / 4.0);

    double currentAngle = theta1;
    for (int seg = 0; seg < segments; seg++) {
      final nextAngle = currentAngle + dDelta;

      final cosCur = math.cos(currentAngle);
      final sinCur = math.sin(currentAngle);
      final cosNext = math.cos(nextAngle);
      final sinNext = math.sin(nextAngle);

      final p1x = rx * cosCur;
      final p1y = ry * sinCur;
      final p2x = rx * cosNext;
      final p2y = ry * sinNext;

      final cp1x = p1x - alpha * ry * sinCur;
      final cp1y = p1y + alpha * rx * cosCur;
      final cp2x = p2x + alpha * ry * sinNext;
      final cp2y = p2y - alpha * rx * cosNext;

      final pC1 = _rotateAndTranslate(cp1x, cp1y, cosPhi, sinPhi, cx, cy);
      final pC2 = _rotateAndTranslate(cp2x, cp2y, cosPhi, sinPhi, cx, cy);
      final pEnd = _rotateAndTranslate(p2x, p2y, cosPhi, sinPhi, cx, cy);

      path.cubicTo(pC1.dx, pC1.dy, pC2.dx, pC2.dy, pEnd.dx, pEnd.dy);
      currentAngle = nextAngle;
    }
  }

  static double _vectorAngle(double ux, double uy, double vx, double vy) {
    final dot = ux * vx + uy * vy;
    final len = math.sqrt(ux * ux + uy * uy) * math.sqrt(vx * vx + vy * vy);
    if (len == 0.0) return 0.0;
    double angle = math.acos((dot / len).clamp(-1.0, 1.0));
    if ((ux * vy - uy * vx) < 0.0) {
      angle = -angle;
    }
    return angle;
  }

  static Offset _rotateAndTranslate(
    double x,
    double y,
    double cosPhi,
    double sinPhi,
    double cx,
    double cy,
  ) {
    return Offset(
      cosPhi * x - sinPhi * y + cx,
      sinPhi * x + cosPhi * y + cy,
    );
  }
}
