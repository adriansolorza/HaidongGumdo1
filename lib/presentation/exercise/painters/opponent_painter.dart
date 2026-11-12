import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../../../domain/catalog/catalog.dart';
import '../../../domain/exercise/attack.dart';
import '../../../domain/exercise/exercise_snapshot.dart';
import '../../../domain/exercise/opponent_motion.dart';
import '../../scene/scene_layout.dart';
import '../../theme.dart';

/// Oponente virtual de frente, con equipo de competencia (casco con rejilla,
/// peto, coderas y guantes sobre dobok y *hakama*), y su sable con brillo
/// (Spec 004, FR-008 a FR-012; data-model §4 y §5).
///
/// Las posturas del sable salen del patrón (`guard`, `cut.start`, `cut.end`) y
/// el tramo actual, de `snapshot.motion` (Spec 001, plan.md D3). Solo los
/// brazos, los guantes y el sable siguen la postura; el cuerpo es fijo.
/// Geometría en unidades `u` desde `layout.origin`, convertida del boceto
/// `Retro.dc.html` (u = 241 px, origen en (640, 413)).
class OpponentPainter extends CustomPainter {
  const OpponentPainter({
    required this.layout,
    required this.saberColor,
    required this.guard,
    required this.cut,
    required this.motion,
  });

  /// Unidad y origen de la figura, compartidos con las señales y el HUD
  /// (Spec 004, research R5).
  final SceneLayout layout;
  final SaberColor saberColor;
  final SaberPose guard;
  final CutMotion cut;
  final OpponentMotion motion;

  /// Diámetro de la punta vista de frente, en unidades de la figura, según la
  /// longitud visible de la hoja: crece al acortarse por el escorzo para que
  /// el color se lea a 3 m (Spec 002, plan.md D2; Spec 004, FR-011).
  static double tipDiameter(double visibleLength) {
    const full = 0.8; // hoja larga: sin punta
    const short = 0.2; // hoja muy corta: punta máxima
    const maxDiameter = 0.3;
    final t = ((full - visibleLength) / (full - short)).clamp(0.0, 1.0);
    return maxDiameter * t;
  }

  // ── Sable (data-model §5), en u ──
  static const _bladeWidth = 0.09;
  static const _glowWidth = 0.11;
  static const _glowSigma = 0.025;
  static const _glowOpacity = 0.6;
  static const _highlightWidth = 0.02;
  static const _highlightOffset = 0.02;
  static const _gripFraction = 0.23;
  static const _gripWidth = 0.07;
  static const _tsubaHalfAlong = 0.03;
  static const _tsubaHalfAcross = 0.095;

  /// Por debajo de este largo visible el sable apunta al usuario: solo se ve
  /// el disco de la punta.
  static const _minVisibleLength = 0.05;

  // ── Figura (data-model §4), en u ──
  static const _shoulders = [Point2(-0.20, -0.49), Point2(0.20, -0.49)];
  static const _armWidth = 0.137;
  static const _gloveRadius = 0.087;
  static const _rimWidth = 0.012;

  @override
  void paint(Canvas canvas, Size size) {
    final u = layout.unit;
    if (u <= 0) return;
    Offset p(double x, double y) => layout.toScreen(Point2(x, y));

    final figureOutline = math.max(0.0145 * u, 2.0);
    final outlinePaint = Paint()
      ..color = AppColors.figureOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = figureOutline
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    void fillAndOutline(Path path, Paint fill) {
      canvas
        ..drawPath(path, fill)
        ..drawPath(path, outlinePaint);
    }

    /// Luz de contorno: franja clara justo dentro del borde de [path], que
    /// separa la silueta oscura de los fondos oscuros (research R7).
    void rimLight(Path path) {
      canvas
        ..save()
        ..clipPath(path)
        ..drawPath(
          path,
          Paint()
            ..color = AppColors.rimLight
            ..style = PaintingStyle.stroke
            ..strokeWidth = figureOutline + 2 * _rimWidth * u
            ..strokeJoin = StrokeJoin.round,
        )
        ..restore();
    }

    Paint horizontalGradient(double left, double right, Color a, Color b) =>
        Paint()..shader = ui.Gradient.linear(p(left, 0), p(right, 0), [a, b]);

    // Sombra en la duela.
    canvas.drawOval(
      Rect.fromCenter(center: p(0, 1.365), width: 1.58 * u, height: 0.124 * u),
      Paint()..color = AppColors.floorShadow,
    );

    // Pies.
    for (final x in const [-0.38, 0.38]) {
      final foot = Path()
        ..addOval(
          Rect.fromCenter(
            center: p(x, 1.357),
            width: 0.282 * u,
            height: 0.092 * u,
          ),
        );
      fillAndOutline(foot, Paint()..color = AppColors.skin);
    }

    // Hakama, con pliegues y luz de contorno.
    final hakama = _polygon(p, const [
      Point2(-0.282, 0.079),
      Point2(0.282, 0.079),
      Point2(0.685, 1.336),
      Point2(0.091, 1.336),
      Point2(0, 0.651),
      Point2(-0.091, 1.336),
      Point2(-0.685, 1.336),
    ]);
    canvas.drawPath(hakama, Paint()..color = AppColors.hakama);
    final fold = Paint()
      ..color = AppColors.hakamaFold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.012 * u
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(p(-0.166, 0.162), p(-0.394, 1.307), fold)
      ..drawLine(p(0.166, 0.162), p(0.394, 1.307), fold);
    rimLight(hakama);
    canvas.drawPath(hakama, outlinePaint);

    // Dobok (tronco).
    final dobok = Path()
      ..moveTo(p(-0.228, -0.544).dx, p(-0.228, -0.544).dy)
      ..quadraticBezierTo(
        p(0, -0.61).dx,
        p(0, -0.61).dy,
        p(0.228, -0.544).dx,
        p(0.228, -0.544).dy,
      )
      ..lineTo(p(0.307, 0.112).dx, p(0.307, 0.112).dy)
      ..lineTo(p(-0.307, 0.112).dx, p(-0.307, 0.112).dy)
      ..close();
    fillAndOutline(
      dobok,
      horizontalGradient(
        -0.307,
        0.307,
        AppColors.sleeveLight,
        AppColors.sleeveShade,
      ),
    );

    // Peto, con ribete interior y dos líneas.
    final peto = Path()
      ..moveTo(p(-0.216, -0.485).dx, p(-0.216, -0.485).dy)
      ..quadraticBezierTo(
        p(0, -0.535).dx,
        p(0, -0.535).dy,
        p(0.216, -0.485).dx,
        p(0.216, -0.485).dy,
      )
      ..lineTo(p(0.266, 0.021).dx, p(0.266, 0.021).dy)
      ..quadraticBezierTo(
        p(0, 0.095).dx,
        p(0, 0.095).dy,
        p(-0.266, 0.021).dx,
        p(-0.266, 0.021).dy,
      )
      ..close();
    fillAndOutline(
      peto,
      horizontalGradient(
        -0.266,
        0.266,
        AppColors.petoLight,
        AppColors.petoShade,
      ),
    );
    final trim = Path()
      ..moveTo(p(-0.174, -0.44).dx, p(-0.174, -0.44).dy)
      ..quadraticBezierTo(
        p(0, -0.481).dx,
        p(0, -0.481).dy,
        p(0.174, -0.44).dx,
        p(0.174, -0.44).dy,
      )
      ..lineTo(p(0.216, -0.021).dx, p(0.216, -0.021).dy)
      ..quadraticBezierTo(
        p(0, 0.041).dx,
        p(0, 0.041).dy,
        p(-0.216, -0.021).dx,
        p(-0.216, -0.021).dy,
      )
      ..close();
    canvas.drawPath(
      trim,
      Paint()
        ..color = AppColors.helmetLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.010 * u
        ..strokeJoin = StrokeJoin.round,
    );
    final petoLine = Paint()
      ..color = AppColors.petoLines
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.008 * u
      ..strokeCap = StrokeCap.round;
    for (final (y, control) in const [(-0.261, -0.295), (-0.129, -0.162)]) {
      canvas.drawPath(
        Path()
          ..moveTo(p(-0.191, y).dx, p(-0.191, y).dy)
          ..quadraticBezierTo(
            p(0, control).dx,
            p(0, control).dy,
            p(0.191, y).dx,
            p(0.191, y).dy,
          ),
        petoLine,
      );
    }

    // Cinturón con nudo y luz de contorno.
    final belt = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromPoints(p(-0.324, 0.029), p(0.324, 0.137)),
          Radius.circular(0.02 * u),
        ),
      );
    final knot = Path()
      ..addPath(
        _polygon(p, const [
          Point2(-0.058, 0.129),
          Point2(-0.133, 0.344),
          Point2(-0.050, 0.344),
          Point2(0, 0.145),
        ]),
        Offset.zero,
      )
      ..addPath(
        _polygon(p, const [
          Point2(0.058, 0.129),
          Point2(0.116, 0.336),
          Point2(0.199, 0.328),
          Point2(0.091, 0.137),
        ]),
        Offset.zero,
      );
    for (final part in [belt, knot]) {
      canvas.drawPath(part, Paint()..color = AppColors.belt);
      rimLight(part);
      canvas.drawPath(part, outlinePaint);
    }

    // Casco con rejilla.
    final helmet = Path()
      ..moveTo(p(-0.199, -0.734).dx, p(-0.199, -0.734).dy)
      ..quadraticBezierTo(
        p(-0.216, -1.008).dx,
        p(-0.216, -1.008).dy,
        p(0, -1.017).dx,
        p(0, -1.017).dy,
      )
      ..quadraticBezierTo(
        p(0.216, -1.008).dx,
        p(0.216, -1.008).dy,
        p(0.199, -0.734).dx,
        p(0.199, -0.734).dy,
      )
      ..lineTo(p(0.166, -0.627).dx, p(0.166, -0.627).dy)
      ..quadraticBezierTo(
        p(0, -0.568).dx,
        p(0, -0.568).dy,
        p(-0.166, -0.627).dx,
        p(-0.166, -0.627).dy,
      )
      ..close();
    fillAndOutline(
      helmet,
      horizontalGradient(
        -0.2,
        0.2,
        AppColors.helmetLight,
        AppColors.helmetShade,
      ),
    );
    final grille = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromPoints(p(-0.112, -0.867), p(0.112, -0.643)),
          Radius.circular(0.041 * u),
        ),
      );
    fillAndOutline(grille, Paint()..color = AppColors.helmetGrille);
    final bar = Paint()
      ..color = AppColors.helmetBars
      ..strokeWidth = 0.010 * u
      ..strokeCap = StrokeCap.round;
    for (final x in const [-0.054, 0.0, 0.054]) {
      canvas.drawLine(p(x, -0.859), p(x, -0.651), bar);
    }
    for (final y in const [-0.788, -0.714]) {
      canvas.drawLine(p(-0.104, y), p(0.104, y), bar);
    }

    // Brazos con coderas, de cada hombro a la empuñadura.
    final pose = _currentPose();
    final hilt = layout.toScreen(pose.hilt);
    final tip = layout.toScreen(pose.tip);
    for (final shoulder in _shoulders) {
      final from = layout.toScreen(shoulder);
      canvas
        ..drawLine(
          from,
          hilt,
          Paint()
            ..color = AppColors.figureOutline
            ..strokeWidth = _armWidth * u + 2 * figureOutline
            ..strokeCap = StrokeCap.round,
        )
        ..drawLine(
          from,
          hilt,
          Paint()
            ..color = AppColors.sleeveLight
            ..strokeWidth = _armWidth * u
            ..strokeCap = StrokeCap.round,
        );
      final elbowPad = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset.lerp(from, hilt, 0.5)!,
            width: 0.18 * u,
            height: 0.21 * u,
          ),
        );
      fillAndOutline(elbowPad, Paint()..color = AppColors.sleeveLight);
    }

    // Sable (sin la punta de frente, que va al final).
    final visibleLength = _length(pose);
    if (visibleLength >= _minVisibleLength) {
      _paintSaber(canvas, hilt, tip, u, figureOutline);
    }

    // Guantes sobre la empuñadura.
    final glove = Path()
      ..addOval(Rect.fromCircle(center: hilt, radius: _gloveRadius * u));
    canvas.drawPath(glove, Paint()..color = AppColors.glove);
    rimLight(glove);
    canvas.drawPath(glove, outlinePaint);

    // Punta de frente: disco del color del sable cuando la hoja se ve corta
    // (FR-011). Va encima de los guantes: a la mitad del barrido transversal
    // la punta coincide con la empuñadura.
    final diameter = tipDiameter(visibleLength) * u;
    if (diameter > _bladeWidth * u) {
      _paintTipDisc(canvas, tip, diameter / 2, u);
    }
  }

  /// Hoja con brillo, contorno y reflejo; empuñadura y tsuba (data-model §5).
  void _paintSaber(
    Canvas canvas,
    Offset hilt,
    Offset tip,
    double u,
    double figureOutline,
  ) {
    final axis = tip - hilt;
    final direction = axis / axis.distance;
    // Normal hacia arriba de la pantalla (o hacia la izquierda si es vertical).
    var normal = Offset(direction.dy, -direction.dx);
    if (normal.dy > 0 || (normal.dy == 0 && normal.dx > 0)) normal = -normal;
    final gripEnd = hilt + axis * _gripFraction;
    final color = _saberColor;

    // Brillo.
    canvas
      ..drawLine(
        gripEnd,
        tip,
        Paint()
          ..color = color.withValues(alpha: _glowOpacity)
          ..strokeWidth = _glowWidth * u
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, _glowSigma * u),
      )
      // Contorno y hoja.
      ..drawLine(
        gripEnd,
        tip,
        Paint()
          ..color = AppColors.outline
          ..strokeWidth = _bladeWidth * u + 2 * kOutlineWidth
          ..strokeCap = StrokeCap.round,
      )
      ..drawLine(
        gripEnd,
        tip,
        Paint()
          ..color = color
          ..strokeWidth = _bladeWidth * u
          ..strokeCap = StrokeCap.round,
      );

    // Reflejo.
    final blade = tip - gripEnd;
    final shift = normal * (_highlightOffset * u);
    canvas.drawLine(
      gripEnd + blade * 0.05 + shift,
      gripEnd + blade * 0.95 + shift,
      Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.55)
        ..strokeWidth = _highlightWidth * u
        ..strokeCap = StrokeCap.round,
    );

    // Empuñadura con marcas.
    canvas
      ..drawLine(
        hilt,
        gripEnd,
        Paint()
          ..color = AppColors.outline
          ..strokeWidth = _gripWidth * u + 2 * kOutlineWidth
          ..strokeCap = StrokeCap.round,
      )
      ..drawLine(
        hilt,
        gripEnd,
        Paint()
          ..color = AppColors.grip
          ..strokeWidth = _gripWidth * u
          ..strokeCap = StrokeCap.round,
      );
    final wrap = Paint()
      ..color = AppColors.gripWrap
      ..strokeWidth = 0.01 * u
      ..strokeCap = StrokeCap.round;
    final across = normal * (_gripWidth * u / 2);
    for (final t in const [0.25, 0.5, 0.75]) {
      final c = Offset.lerp(hilt, gripEnd, t)!;
      canvas.drawLine(c - across, c + across + direction * (0.02 * u), wrap);
    }

    // Tsuba: elipse perpendicular a la hoja.
    canvas
      ..save()
      ..translate(gripEnd.dx, gripEnd.dy)
      ..rotate(math.atan2(direction.dy, direction.dx));
    final tsuba = Rect.fromCenter(
      center: Offset.zero,
      width: 2 * _tsubaHalfAlong * u,
      height: 2 * _tsubaHalfAcross * u,
    );
    canvas
      ..drawOval(tsuba, Paint()..color = AppColors.tsuba)
      ..drawOval(
        tsuba,
        Paint()
          ..color = AppColors.figureOutline
          ..style = PaintingStyle.stroke
          ..strokeWidth = figureOutline,
      )
      ..restore();
  }

  /// Disco de la punta de frente con brillo, contorno y reflejo (FR-011).
  void _paintTipDisc(Canvas canvas, Offset center, double radius, double u) {
    final color = _saberColor;
    canvas
      ..drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: _glowOpacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, _glowSigma * u),
      )
      ..drawCircle(center, radius, Paint()..color = color)
      ..drawCircle(
        center,
        radius,
        Paint()
          ..color = AppColors.outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = kOutlineWidth,
      )
      ..drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.6),
        math.pi * 1.2,
        math.pi * 0.6,
        false,
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(radius * 0.18, 1)
          ..strokeCap = StrokeCap.round,
      );
  }

  static Path _polygon(Offset Function(double, double) p, List<Point2> points) {
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final o = p(points[i].x, points[i].y);
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }
    return path..close();
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
  /// corte se reflejan si el patrón lo pide (Spec 002, plan.md D5).
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

  static double _length(SaberPose pose) => math.sqrt(
    math.pow(pose.tip.x - pose.hilt.x, 2) +
        math.pow(pose.tip.y - pose.hilt.y, 2),
  );

  static Point2 _lerp(Point2 a, Point2 b, double t) =>
      Point2(ui.lerpDouble(a.x, b.x, t)!, ui.lerpDouble(a.y, b.y, t)!);

  Color get _saberColor => switch (saberColor) {
    SaberColor.white => AppColors.saberWhite,
    SaberColor.yellow => AppColors.saberYellow,
    SaberColor.blue => AppColors.saberBlue,
    SaberColor.red => AppColors.saberRed,
  };

  @override
  bool shouldRepaint(OpponentPainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.saberColor != saberColor ||
      oldDelegate.guard != guard ||
      oldDelegate.cut != cut ||
      oldDelegate.motion != motion;
}
