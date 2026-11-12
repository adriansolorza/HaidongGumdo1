import 'package:flutter/material.dart';

import '../../domain/catalog/enums.dart';
import '../exercise/painters/signal_shapes.dart';
import '../theme.dart';

/// Ícono de un nivel: la señal de su tipo de respuesta, en blanco, sin brillo
/// ni estela de color (Spec 004, FR-021; data-model §6, "Íconos de nivel").
class LevelIcon extends StatelessWidget {
  const LevelIcon({super.key, required this.type, required this.size});

  final ResponseType type;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _LevelIconPainter(type));
}

class _LevelIconPainter extends CustomPainter {
  const _LevelIconPainter(this.type);

  final ResponseType type;

  /// Margen respecto al lado del ícono.
  static const _margin = 0.10;

  @override
  void paint(Canvas canvas, Size size) {
    final box = (Offset.zero & size).deflate(_margin * size.shortestSide);
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
  bool shouldRepaint(_LevelIconPainter oldDelegate) => oldDelegate.type != type;
}
