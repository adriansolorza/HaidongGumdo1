import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../../../domain/catalog/enums.dart';
import '../../../domain/exercise/attack.dart';
import '../../../domain/exercise/exercise_snapshot.dart';
import '../../../domain/exercise/signal.dart';
import '../../scene/scene_layout.dart';
import '../../theme.dart';
import 'signal_shapes.dart';

/// Señal de respuesta en la mitad de la pantalla que indica `signal.screenSide`
/// (Spec 001: FR-015, FR-016; Spec 003: FR-006 a FR-009; Spec 004: FR-002,
/// FR-013, FR-014; data-model §6, research R10).
///
/// Las dos señales van dentro del carril de su lado (`SceneLayout`), fuera del
/// alcance del oponente y por encima de los botones; ningún píxel, incluidos
/// el brillo y la estela, sale del carril. Se dibujan del color del sable:
/// - evasión: flecha corta y gruesa con estela, apuntando al borde exterior;
/// - defensa: sable en diagonal visto desde arriba, con la punta arriba y
///   hacia el borde exterior, hoja delgada del color del sable, guarda gris y
///   empuñadura más gruesa.
///
/// Se construye la señal del lado derecho y se refleja en `x` para la
/// izquierda.
class SignalPainter extends CustomPainter {
  const SignalPainter({
    required this.layout,
    required this.signal,
    required this.saberColor,
  });

  /// Carriles de señal (Spec 004, research R5).
  final SceneLayout layout;

  final Signal signal;

  /// Color del sable en el mismo snapshot: la señal toma ese color
  /// (Spec 003, research R3; Spec 004, FR-014).
  final SaberColor saberColor;

  /// Largo máximo de la flecha respecto al alto.
  static const _maxArrowFraction = 0.30;

  /// σ del brillo de la flecha respecto a su largo.
  static const _arrowGlowSigma = 0.04;

  /// σ del brillo de la defensa respecto al alto (análisis U2).
  static const _defenseGlowSigma = 0.009;

  /// Alto máximo del símbolo de defensa respecto al alto.
  static const _maxDefenseFraction = 0.45;

  @override
  void paint(Canvas canvas, Size size) {
    final color = switch (saberColor) {
      SaberColor.blue => AppColors.saberBlue,
      SaberColor.red => AppColors.saberRed,
      SaberColor.white || SaberColor.yellow => null,
    };
    // Con señal visible el sable siempre es azul o rojo (Spec 003, FR-009).
    assert(color != null, 'Señal con sable $saberColor');
    if (color == null) return;

    canvas.save();
    if (signal.screenSide == Side.left) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    switch (signal.responseType) {
      case ResponseType.defense:
        _paintDefense(canvas, size, color);
      case ResponseType.evasion:
        _paintEvasion(canvas, size, color);
    }
    canvas.restore();
  }

  /// Flecha corta y gruesa anclada al borde exterior del carril, con estela
  /// hacia el centro (FR-013).
  void _paintEvasion(Canvas canvas, Size size, Color color) {
    final lane = layout.rightLane;
    final h = size.height;
    // L + 0.6 L de estela mínima + 2 × 3σ de brillo = 1.84 L.
    final l = math.min(
      _maxArrowFraction * h,
      lane.width / (1.6 + 2 * 3 * _arrowGlowSigma),
    );
    if (l <= 0) return;
    final sigma = _arrowGlowSigma * l;
    final glowExtent = 3 * sigma;
    final cy = _clampedCenterY(
      lane,
      h,
      SignalShapes.arrowHeadHeight * l / 2 + glowExtent,
    );

    final box = Rect.fromLTRB(
      lane.right - glowExtent - l,
      cy - SignalShapes.arrowHeadHeight * l / 2,
      lane.right - glowExtent,
      cy + SignalShapes.arrowHeadHeight * l / 2,
    );
    final arrow = SignalShapes.evasionArrow(box);
    final bodyHalf = SignalShapes.arrowBodyHeight * l / 2;

    // Estela: de la cola hacia el centro, del color del sable, que se
    // desvanece (85 % → 0 %).
    final trailLength = math.min(l, box.left - (lane.left + glowExtent));
    if (trailLength > 0) {
      final tail = box.left;
      final end = tail - trailLength;
      Paint fade(double opacity) => Paint()
        ..shader = ui.Gradient.linear(Offset(tail, 0), Offset(end, 0), [
          color.withValues(alpha: 0.85 * opacity),
          color.withValues(alpha: 0),
        ]);
      final endHalf = 0.84 * bodyHalf;
      canvas.drawPath(
        Path()
          ..moveTo(tail, cy - bodyHalf)
          ..lineTo(end, cy - endHalf)
          ..lineTo(end, cy + endHalf)
          ..lineTo(tail, cy + bodyHalf)
          ..close(),
        fade(1),
      );
      // Líneas de movimiento arriba y abajo del cuerpo.
      final streakEnd = tail - 0.75 * trailLength;
      final streak = 0.04 * l;
      for (final s in [-1.0, 1.0]) {
        final y0 = cy + s * (bodyHalf + 0.06 * l);
        canvas.drawPath(
          Path()
            ..moveTo(tail, y0 - streak / 2)
            ..lineTo(streakEnd, y0 - streak / 4)
            ..lineTo(streakEnd, y0 + streak / 4)
            ..lineTo(tail, y0 + streak / 2)
            ..close(),
          fade(0.7),
        );
      }
    }

    // Brillo, relleno, contorno y reflejo.
    final headBase = box.right - SignalShapes.arrowHeadLength * l;
    final headHalf = SignalShapes.arrowHeadHeight * l / 2;
    canvas
      ..drawPath(
        arrow,
        Paint()
          ..color = color.withValues(alpha: 0.6)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
      )
      ..drawPath(arrow, Paint()..color = color)
      ..drawPath(
        arrow,
        Paint()
          ..color = AppColors.outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * kOutlineWidth
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawPath(
        Path()
          ..moveTo(box.left + 0.05 * l, cy - bodyHalf + 0.07 * l)
          ..lineTo(headBase + 0.04 * l, cy - bodyHalf + 0.07 * l)
          ..lineTo(headBase + 0.04 * l, cy - headHalf + 0.17 * l)
          ..lineTo(headBase + 0.33 * l, cy - 0.06 * l),
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.035 * l
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
  }

  /// Sable en diagonal con la hoja del color del sable (FR-014).
  void _paintDefense(Canvas canvas, Size size, Color color) {
    final h = size.height;
    final sigma = _defenseGlowSigma * h;
    final glowExtent = 3 * sigma;
    final inner = layout.rightLane.deflate(glowExtent);
    if (inner.isEmpty) return;
    var box = SignalShapes.fitDefense(
      inner,
      _maxDefenseFraction * h - 2 * glowExtent,
    );
    if (box.isEmpty) return;
    // Centrado en y = h / 2 sin salir del carril.
    final cy = _clampedCenterY(inner, h, box.height / 2);
    box = box.shift(Offset(0, cy - box.center.dy));

    final saber = SignalShapes.defenseSaber(box);
    final outline = Paint()
      ..color = AppColors.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = kOutlineWidth
      ..strokeJoin = StrokeJoin.round;
    final highlightShift = Offset(
      -(saber.bladeTip - saber.bladeBase).dy,
      (saber.bladeTip - saber.bladeBase).dx,
    ).scale(-0.012, -0.012);

    canvas
      // Brillo de la hoja.
      ..drawPath(
        saber.blade,
        Paint()
          ..color = color.withValues(alpha: 0.6)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
      )
      ..drawPath(saber.grip, Paint()..color = AppColors.grip)
      ..drawPath(saber.grip, outline)
      ..drawPath(saber.blade, Paint()..color = color)
      ..drawPath(saber.blade, outline)
      ..drawLine(
        Offset.lerp(saber.bladeBase, saber.bladeTip, 0.1)! + highlightShift,
        Offset.lerp(saber.bladeBase, saber.bladeTip, 0.8)! + highlightShift,
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.55)
          ..strokeWidth = math.max(0.004 * h, 1)
          ..strokeCap = StrokeCap.round,
      )
      ..drawPath(saber.guard, Paint()..color = AppColors.tsuba)
      ..drawPath(saber.guard, outline);
  }

  /// Centro vertical en `h / 2`, desplazado lo justo para que una señal de
  /// medio alto [halfExtent] no salga de [lane].
  static double _clampedCenterY(Rect lane, double h, double halfExtent) {
    final lo = lane.top + halfExtent;
    final hi = lane.bottom - halfExtent;
    if (lo > hi) return lane.center.dy;
    return (h / 2).clamp(lo, hi);
  }

  @override
  bool shouldRepaint(SignalPainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.signal != signal ||
      oldDelegate.saberColor != saberColor;
}
