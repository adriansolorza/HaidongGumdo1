import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../theme.dart';
import 'scene_layout.dart';

/// Fondo del dojang (Spec 004, FR-006, FR-007, research R6).
///
/// Coordenadas del boceto `docs/design/bocetos/Retro.dc.html` convertidas a
/// unidades `u` de la figura desde `layout.origin` (en el boceto, u = 241 px y
/// el origen está en (640, 413)), así que el fondo no se estira: las bandas
/// horizontales cubren todo el ancho y los elementos puntuales pueden
/// recortarse en las orillas. La viñeta va en esta capa, debajo del oponente y
/// las señales, para no oscurecer la flecha cerca del borde (FR-003).
class DojangPainter extends CustomPainter {
  const DojangPainter({required this.layout});

  final SceneLayout layout;

  // Alturas en u (del boceto).
  static const _beamTop = -1.266;
  static const _beamBottom = -1.166;
  static const _beamShadowTop = -1.174;
  static const _beamShadowBottom = -1.158;
  static const _baseboardTop = 0.527;
  static const _floorTop = 0.618;
  static const _jointBottomY = 1.606;

  // Columnas: x interior y exterior (lado derecho; la izquierda se refleja).
  static const _columnInner = 1.320;
  static const _columnOuter = 1.494;
  static const _columnShadowFrom = 1.427; // derecha
  static const _columnShadowFromLeft =
      -1.386; // izquierda (sombra a la derecha)

  // Estandartes (lado derecho; la izquierda se refleja).
  static const _bannerInner = 1.793;
  static const _bannerOuter = 2.124;
  static const _bannerCenter = 1.959;
  static const _bannerTop = -1.091;
  static const _bannerBottom = 0.154;
  static const _bannerFont = 0.174;
  static const _bannerBaselines = [-0.793, -0.544, -0.295, -0.046];

  // Juntas de la duela: separación arriba y abajo.
  static const _jointTopStep = 0.332;
  static const _jointBottomStep = 0.730;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final u = layout.unit;
    final o = layout.origin;
    double y(double v) => o.dy + v * u;
    double x(double v) => o.dx + v * u;

    final wallBottom = y(_baseboardTop);
    final floorTop = y(_floorTop);

    // Pared.
    canvas.drawRect(
      Rect.fromLTRB(0, 0, w, wallBottom),
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, wallBottom), [
          AppColors.wallTop,
          AppColors.wallBottom,
        ]),
    );

    // Haces de luz.
    for (final (top1, top2, bottom2, bottom1, alpha) in const [
      (-1.079, -0.498, 0.581, -0.332, 0.07),
      (-0.332, -0.083, 1.079, 0.664, 0.05),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(x(top1), 0)
          ..lineTo(x(top2), 0)
          ..lineTo(x(bottom2), wallBottom)
          ..lineTo(x(bottom1), wallBottom)
          ..close(),
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: alpha),
      );
    }

    // Viga.
    canvas
      ..drawRect(
        Rect.fromLTRB(0, y(_beamTop), w, y(_beamBottom)),
        Paint()..color = AppColors.beam,
      )
      ..drawRect(
        Rect.fromLTRB(0, y(_beamShadowTop), w, y(_beamShadowBottom)),
        Paint()..color = AppColors.beamShadow,
      );

    // Columnas.
    final wood = Paint()..color = AppColors.wood;
    final woodShadow = Paint()..color = AppColors.woodShadow;
    canvas
      ..drawRect(
        Rect.fromLTRB(x(-_columnOuter), 0, x(-_columnInner), wallBottom),
        wood,
      )
      ..drawRect(
        Rect.fromLTRB(
          x(_columnShadowFromLeft),
          0,
          x(-_columnInner),
          wallBottom,
        ),
        woodShadow,
      )
      ..drawRect(
        Rect.fromLTRB(x(_columnInner), 0, x(_columnOuter), wallBottom),
        wood,
      )
      ..drawRect(
        Rect.fromLTRB(x(_columnShadowFrom), 0, x(_columnOuter), wallBottom),
        woodShadow,
      );

    // Estandartes con 해동검도 (izquierda) y 海東劍道 (derecha).
    for (final (sign, text) in const [(-1.0, '해동검도'), (1.0, '海東劍道')]) {
      final center = x(sign * _bannerCenter);
      canvas
        ..drawLine(
          Offset(center, y(_beamBottom)),
          Offset(center, y(_bannerTop)),
          Paint()
            ..color = AppColors.beamShadow
            ..strokeWidth = 0.012 * u,
        )
        ..drawRRect(
          RRect.fromLTRBR(
            x(sign < 0 ? -_bannerOuter : _bannerInner),
            y(_bannerTop),
            x(sign < 0 ? -_bannerInner : _bannerOuter),
            y(_bannerBottom),
            Radius.circular(4 * layout.hudScale),
          ),
          Paint()..color = AppColors.bannerCloth,
        );
      for (var i = 0; i < text.length; i++) {
        final glyph = TextPainter(
          text: TextSpan(
            text: text[i],
            style: TextStyle(
              color: AppColors.bannerText,
              fontSize: _bannerFont * u,
              height: 1,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final baseline = glyph.computeDistanceToActualBaseline(
          TextBaseline.alphabetic,
        );
        glyph
          ..paint(
            canvas,
            Offset(center - glyph.width / 2, y(_bannerBaselines[i]) - baseline),
          )
          ..dispose();
      }
    }

    // Zócalo.
    canvas.drawRect(
      Rect.fromLTRB(0, wallBottom, w, floorTop),
      Paint()..color = AppColors.baseboard,
    );

    // Duela.
    canvas.drawRect(
      Rect.fromLTRB(0, floorTop, w, h),
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, floorTop), Offset(0, h), [
          AppColors.floorBack,
          AppColors.floorFront,
        ]),
    );

    // Juntas de la duela, en perspectiva desde el centro, hasta cubrir el ancho.
    final joint = Paint()
      ..color = AppColors.floorJoint
      ..strokeWidth = 0.012 * u;
    final jointSlope =
        (_jointBottomStep - _jointTopStep) /
        (_jointBottomY - _floorTop); // u de x por u de y, por paso
    final yBottom = (h - o.dy) / u; // borde inferior de la pantalla, en u
    final kMax = (o.dx / (_jointTopStep * u)).ceil() + 1;
    for (var k = -kMax; k <= kMax; k++) {
      final xTop = k * _jointTopStep;
      final xBottom = k * (_jointTopStep + jointSlope * (yBottom - _floorTop));
      canvas.drawLine(Offset(x(xTop), floorTop), Offset(x(xBottom), h), joint);
    }

    // Foco de luz sobre la duela.
    _drawEllipseGradient(
      canvas,
      center: Offset(o.dx, y(1.191)),
      radiusX: 1.909 * u,
      radiusY: 0.456 * u,
      colors: [AppColors.spotLight, AppColors.spotLight.withValues(alpha: 0)],
      stops: const [0, 1],
    );

    // Viñeta.
    _drawEllipseGradient(
      canvas,
      center: Offset(w / 2, 0.45 * h),
      radiusX: 0.78 * w,
      radiusY: 0.78 * h,
      colors: const [Color(0x00000000), Color(0x00000000), Color(0x80000000)],
      stops: const [0, 0.62, 1],
      cover: Rect.fromLTWH(0, 0, w, h),
    );
  }

  /// Degradado radial elíptico: se dibuja en un espacio escalado. Con [cover]
  /// se rellena ese rectángulo (y lo que queda fuera del radio toma el último
  /// color); sin él, solo la elipse.
  static void _drawEllipseGradient(
    Canvas canvas, {
    required Offset center,
    required double radiusX,
    required double radiusY,
    required List<Color> colors,
    required List<double> stops,
    Rect? cover,
  }) {
    if (radiusX <= 0 || radiusY <= 0) return;
    final paint = Paint()
      ..shader = ui.Gradient.radial(Offset.zero, 1, colors, stops);
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..scale(radiusX, radiusY);
    if (cover == null) {
      canvas.drawCircle(Offset.zero, 1, paint);
    } else {
      canvas.drawRect(
        Rect.fromLTRB(
          (cover.left - center.dx) / radiusX,
          (cover.top - center.dy) / radiusY,
          (cover.right - center.dx) / radiusX,
          (cover.bottom - center.dy) / radiusY,
        ),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(DojangPainter oldDelegate) => oldDelegate.layout != layout;
}
