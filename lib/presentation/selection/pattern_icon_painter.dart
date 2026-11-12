import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../../domain/catalog/catalog.dart';
import '../theme.dart';

/// Silueta de un patrón para su tarjeta en la selección, generada a partir de
/// la postura de ataque del catálogo (`cut.start`): un patrón nuevo tiene
/// ícono sin cambiar código (Spec 004, FR-022; data-model §8).
///
/// Cuerpo de palitos fijo; los brazos van de los hombros a la empuñadura y el
/// sable, de la empuñadura a la punta. Todo se escala para caber en el lienzo.
class PatternIconPainter extends CustomPainter {
  const PatternIconPainter({required this.pattern});

  final Pattern pattern;

  static const _head = Point2(0, -0.8);
  static const _headRadius = 0.2;
  static const _neck = Point2(0, -0.55);
  static const _hip = Point2(0, 0.1);
  static const _feet = [Point2(-0.3, 1.3), Point2(0.3, 1.3)];
  static const _shoulders = [Point2(-0.2, -0.49), Point2(0.2, -0.49)];

  /// Margen respecto al lado del lienzo.
  static const _margin = 0.10;

  @override
  void paint(Canvas canvas, Size size) {
    final hilt = pattern.cut.start.hilt;
    final tip = pattern.cut.start.tip;

    // Caja de todos los puntos (la cabeza cuenta con su radio).
    final points = [
      Point2(_head.x - _headRadius, _head.y - _headRadius),
      Point2(_head.x + _headRadius, _head.y + _headRadius),
      _neck,
      _hip,
      ..._feet,
      ..._shoulders,
      hilt,
      tip,
    ];
    var left = points.first.x, right = left;
    var top = points.first.y, bottom = top;
    for (final p in points) {
      left = math.min(left, p.x);
      right = math.max(right, p.x);
      top = math.min(top, p.y);
      bottom = math.max(bottom, p.y);
    }

    final side = size.shortestSide;
    final stroke = 0.055 * side;
    final available = side * (1 - 2 * _margin) - stroke;
    final scale = available / math.max(right - left, bottom - top);
    final center = size.center(Offset.zero);
    final mid = Offset((left + right) / 2, (top + bottom) / 2);
    Offset at(Point2 p) => center + (Offset(p.x, p.y) - mid) * scale;

    final body = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas
      ..drawCircle(
        at(_head),
        _headRadius * scale,
        Paint()..color = AppColors.textPrimary,
      )
      ..drawLine(at(_neck), at(_hip), body)
      ..drawLine(at(_shoulders[0]), at(_shoulders[1]), body);
    for (final foot in _feet) {
      canvas.drawLine(at(_hip), at(foot), body);
    }
    for (final shoulder in _shoulders) {
      canvas.drawLine(at(shoulder), at(hilt), body);
    }
    canvas.drawLine(at(hilt), at(tip), body..strokeWidth = 0.75 * stroke);
  }

  @override
  bool shouldRepaint(PatternIconPainter oldDelegate) =>
      oldDelegate.pattern != pattern;
}
