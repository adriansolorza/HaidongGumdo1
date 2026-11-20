import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/catalog/enums.dart';
import '../exercise/painters/signal_shapes.dart';
import '../theme.dart';

/// Ícono de un nivel: las señales de sus tipos de respuesta, lado a lado y en
/// blanco (Spec 004, FR-021; Spec 006, FR-013; Spec 007, FR-016: el
/// contraataque es la flecha con el sable vertical junto a la punta). Sin
/// brillo ni estela de color (data-model §6 de la Spec 004, "Íconos de nivel").
class LevelIcon extends StatelessWidget {
  const LevelIcon({super.key, required this.types, required this.size});

  /// En el orden del catálogo; uno por celda.
  final List<ResponseType> types;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: LevelIconPainter(types));
}

/// Pintor del ícono de nivel. Público para que las pruebas lo pinten sin
/// montar el widget.
class LevelIconPainter extends CustomPainter {
  const LevelIconPainter(this.types);

  final List<ResponseType> types;

  /// Margen respecto al lado del ícono.
  static const _margin = 0.10;

  /// Separación entre celdas, respecto al ancho de la caja útil.
  static const _gap = 0.08;

  @override
  void paint(Canvas canvas, Size size) {
    final box = (Offset.zero & size).deflate(_margin * size.shortestSide);
    final n = types.length;
    final gap = n > 1 ? _gap * box.width : 0.0;
    final cellWidth = (box.width - gap * (n - 1)) / n;
    for (final (i, type) in types.indexed) {
      // Con n = 1 la celda es la caja completa: la imagen no cambia.
      final cell = Rect.fromLTWH(
        box.left + i * (cellWidth + gap),
        box.top,
        cellWidth,
        box.height,
      );
      final side = math.min(cell.width, cell.height);
      _paintGlyph(
        canvas,
        Rect.fromCenter(center: cell.center, width: side, height: side),
        type,
      );
    }
  }

  /// El glifo de [type] dentro de [box], con las fórmulas de la Spec 004.
  static void _paintGlyph(Canvas canvas, Rect box, ResponseType type) {
    final white = Paint()..color = AppColors.textPrimary;
    switch (type) {
      case ResponseType.evasion:
        // Flecha a la derecha con 3 líneas de movimiento a su izquierda; la
        // flecha ocupa 1 / 1.45 del ancho.
        final l = box.width / 1.45;
        final arrowHeight = SignalShapes.arrowHeadHeight * l;
        final arrow = Rect.fromLTWH(
          box.right - l,
          box.center.dy - arrowHeight / 2,
          l,
          arrowHeight,
        );
        canvas.drawPath(SignalShapes.evasionArrow(arrow), white);
        final line = Paint()
          ..color = AppColors.textPrimary
          ..strokeWidth = 0.09 * l
          ..strokeCap = StrokeCap.round;
        final gap = 0.04 * l;
        for (final (dy, start) in const [
          (-0.18, 0.10),
          (0.0, 0.0),
          (0.18, 0.10),
        ]) {
          final y = box.center.dy + dy * l;
          canvas.drawLine(
            Offset(box.left + start * l + line.strokeWidth / 2, y),
            Offset(arrow.left - gap - line.strokeWidth / 2, y),
            line,
          );
        }
      case ResponseType.counter:
        // Líneas de movimiento, flecha y sable vertical junto a la punta; el
        // conjunto mide ≈ 1.80 L de ancho (Spec 007, research R7).
        final l = box.width / 1.80;
        final arrowHeight = SignalShapes.arrowHeadHeight * l;
        final saberHeight = 1.10 * arrowHeight;
        final saberWidth =
            saberHeight *
            SignalShapes.saberAspect(SignalShapes.counterAngleDegrees);
        final saberBox = Rect.fromLTWH(
          box.right - saberWidth,
          box.center.dy - saberHeight / 2,
          saberWidth,
          saberHeight,
        );
        final arrow = Rect.fromLTWH(
          saberBox.left - 0.10 * l - l,
          box.center.dy - arrowHeight / 2,
          l,
          arrowHeight,
        );
        canvas.drawPath(SignalShapes.evasionArrow(arrow), white);
        final line = Paint()
          ..color = AppColors.textPrimary
          ..strokeWidth = 0.09 * l
          ..strokeCap = StrokeCap.round;
        final gap = 0.04 * l;
        for (final (dy, start) in const [
          (-0.18, 0.10),
          (0.0, 0.0),
          (0.18, 0.10),
        ]) {
          final y = box.center.dy + dy * l;
          canvas.drawLine(
            Offset(box.left + start * l + line.strokeWidth / 2, y),
            Offset(arrow.left - gap - line.strokeWidth / 2, y),
            line,
          );
        }
        final saber = SignalShapes.saber(
          saberBox,
          angleDegrees: SignalShapes.counterAngleDegrees,
        );
        canvas
          ..drawPath(saber.grip, white)
          ..drawPath(saber.guard, white)
          ..drawPath(saber.blade, white);
      case ResponseType.defense:
        final saber = SignalShapes.defenseSaber(
          SignalShapes.fitDefense(box, box.height),
        );
        canvas
          ..drawPath(saber.grip, white)
          ..drawPath(saber.guard, white)
          ..drawPath(saber.blade, white);
    }
  }

  @override
  bool shouldRepaint(LevelIconPainter oldDelegate) =>
      !listEquals(oldDelegate.types, types);
}
