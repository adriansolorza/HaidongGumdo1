import 'dart:ui' show lerpDouble;

import 'package:flutter/rendering.dart';

import '../../../domain/catalog/catalog.dart';
import '../../../domain/exercise/attack.dart';
import '../../../domain/exercise/exercise_snapshot.dart';
import '../../theme.dart';

/// Oponente virtual de frente, centrado, con el sable como trazo grueso
/// (research R12). La postura y el corte salen de `pattern.cut` del catálogo.
class OpponentPainter extends CustomPainter {
  const OpponentPainter({
    required this.saberColor,
    required this.inStance,
    required this.cut,
    this.side,
    this.cutProgress,
  });

  final SaberColor saberColor;

  /// `false` antes de *Si-jak* (reposo, sable bajo); `true` desde *Si-jak*.
  final bool inStance;

  final CutMotion cut;
  final Side? side;

  /// En [0, 1] durante el corte; `null` fuera de él (postura fija).
  final double? cutProgress;

  /// Reposo genérico, igual para todos los patrones: sable bajo y en diagonal.
  static const _restPose = SaberPose(
    hilt: Point2(0.25, 0.15),
    tip: Point2(0.9, 0.75),
  );

  @override
  void paint(Canvas canvas, Size size) {
    // Unidad = media altura de la figura. Se deja sitio para la punta en y = −1.6.
    final unit = size.height * 0.27;
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
    _strokeWithOutline(canvas, hilt, tip, 0.09 * unit, _saberColor);
    final handRadius = 0.1 * unit;
    canvas
      ..drawCircle(hilt, handRadius, body)
      ..drawCircle(hilt, handRadius, outline);
  }

  SaberPose _currentPose() {
    if (!inStance) return _restPose;
    final progress = cutProgress;
    final pose = progress == null
        ? cut.start
        : SaberPose(
            hilt: _lerp(cut.start.hilt, cut.end.hilt, progress),
            tip: _lerp(cut.start.tip, cut.end.tip, progress),
          );
    if (!(cut.mirroredBySide && side == Side.left)) return pose;
    return SaberPose(
      hilt: Point2(-pose.hilt.x, pose.hilt.y),
      tip: Point2(-pose.tip.x, pose.tip.y),
    );
  }

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
      oldDelegate.inStance != inStance ||
      oldDelegate.cut != cut ||
      oldDelegate.side != side ||
      oldDelegate.cutProgress != cutProgress;
}
