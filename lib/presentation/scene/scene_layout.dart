import 'dart:math' as math;
import 'dart:ui';

import '../../domain/catalog/catalog.dart';
import '../../domain/exercise/attack.dart';

/// Geometría compartida por el dojang, el oponente, las señales y el HUD
/// (Spec 004, data-model §2, research R5).
///
/// Se calcula una vez por tamaño de pantalla y patrón. Por construcción:
/// - toda la figura y el sable, en cualquier postura del patrón, quedan entre
///   [hudBottom] y el límite del piso, así que el HUD superior no los tapa;
/// - los carriles de señal quedan fuera del alcance del oponente y por encima
///   de las zonas de botón.
///
/// Unidades: `u` = [unit] (media altura de la figura, la misma de `Point2`);
/// `s` = [hudScale] (escala de las medidas del boceto de 1280 × 800).
final class SceneLayout {
  SceneLayout._({
    required this.size,
    required this.pattern,
    required this.hudScale,
    required this.hudBottom,
    required this.unit,
    required this.origin,
    required this.reachX,
    required this.leftLane,
    required this.rightLane,
    required this.bottomLeftButton,
    required this.bottomRightButton,
  });

  factory SceneLayout.compute(Size size, Pattern pattern) {
    final w = size.width;
    final h = size.height;

    final s = (h / designHeight).clamp(0.7, 1.4);
    final hudBottom = (hudBandDesignPx + hudGapDesignPx) * s;

    final points = [
      pattern.guard.hilt,
      pattern.guard.tip,
      pattern.cut.start.hilt,
      pattern.cut.start.tip,
      pattern.cut.end.hilt,
      pattern.cut.end.tip,
    ];
    final topReach = math.min(-1.6, points.map((p) => p.y).reduce(math.min));
    final reachX =
        math.max(1.3, points.map((p) => p.x.abs()).reduce(math.max)) +
        saberExtent;

    final floorLimit = floorLimitFraction * h;
    final edgeMargin = edgeMarginFraction * w;
    final uV =
        (floorLimit - hudBottom) / (saberExtent - topReach + figureBottom);
    final uH =
        (w / 2 - edgeMargin - minLaneWidthFraction * h) / (reachX + laneGap);
    final unit = math.max(0.0, math.min(uV, uH));

    final origin = Offset(w / 2, hudBottom + (saberExtent - topReach) * unit);

    // Botones primero: los carriles terminan por encima de ellos (FR-017).
    final bottomLeftButton = Rect.fromLTWH(
      36 * s,
      h - (28 + 48) * s,
      200 * s,
      48 * s,
    );
    final bottomRightButton = Rect.fromLTRB(
      w - bottomLeftButton.right,
      bottomLeftButton.top,
      w - bottomLeftButton.left,
      bottomLeftButton.bottom,
    );

    final rightLane = Rect.fromLTRB(
      origin.dx + (reachX + laneGap) * unit,
      hudBottom,
      w - edgeMargin,
      bottomLeftButton.top - 12 * s,
    );
    final leftLane = Rect.fromLTRB(
      w - rightLane.right,
      rightLane.top,
      w - rightLane.left,
      rightLane.bottom,
    );

    return SceneLayout._(
      size: size,
      pattern: pattern,
      hudScale: s,
      hudBottom: hudBottom,
      unit: unit,
      origin: origin,
      reachX: reachX,
      leftLane: leftLane,
      rightLane: rightLane,
      bottomLeftButton: bottomLeftButton,
      bottomRightButton: bottomRightButton,
    );
  }

  /// Medio ancho de la hoja (0.045 u) más su brillo, en `u`.
  static const saberExtent = 0.13;

  /// Borde inferior de la figura (pies con contorno), en `u`.
  static const figureBottom = 1.42;

  /// Límite inferior de los pies, como fracción del alto.
  static const floorLimitFraction = 0.965;

  /// Margen entre el alcance del oponente y el carril de señal, en `u`.
  static const laneGap = 0.02;

  /// Margen exterior del carril respecto al ancho (Spec 003).
  static const edgeMarginFraction = 0.04;

  /// Ancho mínimo del carril, como fracción del alto.
  static const minLaneWidthFraction = 0.20;

  /// Fin de la franja superior del HUD en el boceto (panel de los segundos).
  static const hudBandDesignPx = 117.0;

  /// Margen bajo la franja del HUD en el boceto.
  static const hudGapDesignPx = 12.0;

  /// Alto del boceto de referencia (1280 × 800).
  static const designHeight = 800.0;

  final Size size;
  final Pattern pattern;

  /// Escala del HUD respecto al boceto: `clamp(alto / 800, 0.7, 1.4)`.
  final double hudScale;

  /// Fin de la franja superior del HUD, con margen.
  final double hudBottom;

  /// Unidad de la figura `u`, en dp.
  final double unit;

  /// Origen de la figura en pantalla.
  final Offset origin;

  /// Alcance horizontal del oponente, con el brillo del sable, en `u`.
  final double reachX;

  final Rect leftLane;
  final Rect rightLane;

  /// Zona de Detener y Volver.
  final Rect bottomLeftButton;

  /// Zona de Repetir.
  final Rect bottomRightButton;

  /// Carril de señal de la mitad [screenSide] vista por el usuario.
  Rect laneFor(Side screenSide) => switch (screenSide) {
    Side.left => leftLane,
    Side.right => rightLane,
  };

  /// Punto de la figura (en `u`, desde el origen) en pantalla.
  Offset toScreen(Point2 p) => origin + Offset(p.x * unit, p.y * unit);

  @override
  bool operator ==(Object other) =>
      other is SceneLayout && other.size == size && other.pattern == pattern;

  @override
  int get hashCode => Object.hash(size, pattern);
}
