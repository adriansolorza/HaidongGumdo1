import 'dart:math' show pow, sqrt;
import 'dart:ui' show lerpDouble;

import 'package:flutter/rendering.dart';

import '../../../domain/catalog/catalog.dart';
import '../../../domain/exercise/attack.dart';
import '../../../domain/exercise/exercise_snapshot.dart';
import '../../../domain/exercise/opponent_motion.dart';
import '../../theme.dart';

/// Oponente virtual de frente, centrado, con el sable como trazo grueso
/// (research R12). Las posturas salen del patrón (`guard`, `cut.start`,
/// `cut.end`) y el tramo actual, de `snapshot.motion` (plan.md D3).
class OpponentPainter extends CustomPainter {
  const OpponentPainter({
    required this.saberColor,
    required this.guard,
    required this.cut,
    required this.motion,
  });

  final SaberColor saberColor;
  final SaberPose guard;
  final CutMotion cut;
  final OpponentMotion motion;

  /// Unidad de la figura: u = 0.27 × alto del lienzo. Pública para que la
  /// señal de evasión respete el alcance del oponente (Spec 003, plan.md D4).
  static const unitFraction = 0.27;

  /// Diámetro de la punta vista de frente, en unidades de la figura, según la
  /// longitud visible de la hoja: crece al acortarse por el escorzo para que
  /// el color se lea a 3 m (plan.md D2).
  static double tipDiameter(double visibleLength) {
    const full = 0.8; // hoja larga: sin punta
    const short = 0.2; // hoja muy corta: punta máxima
    const maxDiameter = 0.3;
    final t = ((full - visibleLength) / (full - short)).clamp(0.0, 1.0);
    return maxDiameter * t;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Unidad = media altura de la figura. Se deja sitio para la punta en y = −1.6.
    final unit = size.height * unitFraction;
    final origin = Offset(size.width / 2, size.height * 0.58);
    Offset toScreen(Point2 p) => origin + Offset(p.x * unit, p.y * unit);

    final pose = _currentPose();
    final hilt = toScreen(pose.hilt);
    final tip = toScreen(pose.tip);

    final outline = Paint()
      ..color = AppColors.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = kOutlineWidth
      ..strokeJoin = StrokeJoin.round;
    final body = Paint()..color = const Color(0xFF8A8F98);

    // Torso.
    final torso = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        origin.dx - 0.38 * unit,
        origin.dy - 0.6 * unit,
        origin.dx + 0.38 * unit,
        origin.dy + 1.0 * unit,
      ),
      Radius.circular(0.15 * unit),
    );
    canvas
      ..drawRRect(torso, body)
      ..drawRRect(torso, outline);

    // Cabeza.
    final headCenter = toScreen(const Point2(0, -0.8));
    final headRadius = 0.2 * unit;
    canvas
      ..drawCircle(headCenter, headRadius, body)
      ..drawCircle(headCenter, headRadius, outline);

    // Brazos: de cada hombro a las manos, que están en la empuñadura.
    final armWidth = 0.14 * unit;
    for (final shoulder in [
      toScreen(const Point2(-0.36, -0.5)),
      toScreen(const Point2(0.36, -0.5)),
    ]) {
      _strokeWithOutline(canvas, shoulder, hilt, armWidth, body.color);
    }

    // Sable y manos.
    final bladeWidth = 0.09 * unit;
    _strokeWithOutline(canvas, hilt, tip, bladeWidth, _saberColor);
    final handRadius = 0.1 * unit;
    canvas
      ..drawCircle(hilt, handRadius, body)
      ..drawCircle(hilt, handRadius, outline);

    // Punta vista de frente cuando la hoja se ve corta. Más estrecha que la
    // hoja no se vería (solo dejaría un anillo del contorno en la punta).
    final diameter = tipDiameter(_length(pose)) * unit;
    if (diameter > bladeWidth) {
      canvas
        ..drawCircle(tip, diameter / 2, Paint()..color = _saberColor)
        ..drawCircle(tip, diameter / 2, outline);
    }
  }

  SaberPose _currentPose() {
    final from = _resolve(motion.from);
    final to = _resolve(motion.to);
    return SaberPose(
      hilt: _lerp(from.hilt, to.hilt, motion.progress),
      tip: _lerp(from.tip, to.tip, motion.progress),
    );
  }

  /// La guardia es común a ambos lados; la postura de ataque y el fin del
  /// corte se reflejan si el patrón lo pide (plan.md D5).
  SaberPose _resolve(PoseKey key) {
    final pose = switch (key) {
      PoseKey.guard => guard,
      PoseKey.stance => cut.start,
      PoseKey.cutEnd => cut.end,
    };
    final mirrored =
        key != PoseKey.guard && cut.mirroredBySide && motion.side == Side.left;
    if (!mirrored) return pose;
    return SaberPose(
      hilt: Point2(-pose.hilt.x, pose.hilt.y),
      tip: Point2(-pose.tip.x, pose.tip.y),
    );
  }

  static double _length(SaberPose pose) =>
      sqrt(pow(pose.tip.x - pose.hilt.x, 2) + pow(pose.tip.y - pose.hilt.y, 2));

  static Point2 _lerp(Point2 a, Point2 b, double t) =>
      Point2(lerpDouble(a.x, b.x, t)!, lerpDouble(a.y, b.y, t)!);

  /// Trazo grueso relleno con contorno negro de al menos [kOutlineWidth].
  static void _strokeWithOutline(
    Canvas canvas,
    Offset from,
    Offset to,
    double width,
    Color color,
  ) {
    canvas
      ..drawLine(
        from,
        to,
        Paint()
          ..color = AppColors.outline
          ..strokeWidth = width + 2 * kOutlineWidth
          ..strokeCap = StrokeCap.round,
      )
      ..drawLine(
        from,
        to,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
  }

  Color get _saberColor => switch (saberColor) {
    SaberColor.white => AppColors.saberWhite,
    SaberColor.yellow => AppColors.saberYellow,
    SaberColor.blue => AppColors.saberBlue,
    SaberColor.red => AppColors.saberRed,
  };

  @override
  bool shouldRepaint(OpponentPainter oldDelegate) =>
      oldDelegate.saberColor != saberColor ||
      oldDelegate.guard != guard ||
      oldDelegate.cut != cut ||
      oldDelegate.motion != motion;
}
