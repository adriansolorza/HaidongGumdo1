import 'dart:math' as math;
import 'dart:ui';

/// Formas de las señales, sin color ni `Canvas`: solo geometría (Spec 004,
/// data-model §6, research R10). Las usan `SignalPainter` (con color, brillo y
/// estela) y los íconos de nivel de la selección (en blanco).
///
/// Cada forma se construye para el lado derecho de la pantalla; quien la
/// dibuja la refleja en `x` para el lado izquierdo.
abstract final class SignalShapes {
  // ── Flecha de evasión (proporciones del boceto Retro.dc.html) ──

  /// Largo de la punta respecto al largo `L` de la flecha.
  static const arrowHeadLength = 0.54;

  /// Alto de la punta respecto a `L`.
  static const arrowHeadHeight = 1.06;

  /// Alto del cuerpo respecto a `L`.
  static const arrowBodyHeight = 0.46;

  /// Flecha que apunta a la derecha y ocupa [box]: `L = box.width`, con la
  /// punta (vértice en `box.centerRight`) de largo 0.54 L y alto 1.06 L y el
  /// cuerpo de largo 0.46 L y alto 0.46 L, centrados en vertical.
  static Path evasionArrow(Rect box) {
    final l = box.width;
    final cy = box.center.dy;
    final headBase = box.right - arrowHeadLength * l;
    final headHalf = arrowHeadHeight * l / 2;
    final bodyHalf = arrowBodyHeight * l / 2;
    return Path()
      ..moveTo(box.left, cy - bodyHalf)
      ..lineTo(headBase, cy - bodyHalf)
      ..lineTo(headBase, cy - headHalf)
      ..lineTo(box.right, cy)
      ..lineTo(headBase, cy + headHalf)
      ..lineTo(headBase, cy + bodyHalf)
      ..lineTo(box.left, cy + bodyHalf)
      ..close();
  }

  // ── Símbolo de defensa: sable en diagonal visto desde arriba ──

  /// Ángulo del eje sobre la horizontal (65°: en 4:3 el símbolo llega al
  /// 30 % del alto, research R10).
  static const defenseAngleDegrees = 65.0;

  /// Tramos a lo largo del eje, como fracción del largo total: empuñadura
  /// (26 %), guarda y hoja (70 %).
  static const _gripEnd = 0.26;
  static const _bladeStart = 0.30;

  /// Anchos respecto al largo total.
  static const _gripWidth = 0.09;
  static const _bladeWidth = _gripWidth * 0.55;
  static const _guardWidth = 0.26;
  static const _guardThickness = 0.035;

  /// Sable en diagonal con la punta arriba a la derecha, ajustado a [box]
  /// (centrado y con su proporción). Devuelve la hoja, la guarda, la
  /// empuñadura y los extremos del eje de la hoja (para el reflejo).
  static ({
    Path blade,
    Path guard,
    Path grip,
    Offset bladeBase,
    Offset bladeTip,
  })
  defenseSaber(Rect box) {
    final unit = _defenseUnitBounds();
    final scale = math.min(box.width / unit.width, box.height / unit.height);
    // Origen del eje (extremo de la empuñadura) en la caja.
    final offset =
        box.center - Offset(unit.center.dx * scale, unit.center.dy * scale);
    Offset at(double along, double across) {
      final local = _axisPoint(along, across);
      return offset + local * scale;
    }

    Path quad(double a0, double a1, double halfWidth) => Path()
      ..moveTo(at(a0, -halfWidth).dx, at(a0, -halfWidth).dy)
      ..lineTo(at(a1, -halfWidth).dx, at(a1, -halfWidth).dy)
      ..lineTo(at(a1, halfWidth).dx, at(a1, halfWidth).dy)
      ..lineTo(at(a0, halfWidth).dx, at(a0, halfWidth).dy)
      ..close();

    // Hoja: recta y estrecha que termina en punta (2 anchos de hoja).
    const tipStart = 1.0 - 2 * _bladeWidth;
    final blade = Path()
      ..moveTo(
        at(_bladeStart, -_bladeWidth / 2).dx,
        at(_bladeStart, -_bladeWidth / 2).dy,
      )
      ..lineTo(
        at(tipStart, -_bladeWidth / 2).dx,
        at(tipStart, -_bladeWidth / 2).dy,
      )
      ..lineTo(at(1, 0).dx, at(1, 0).dy)
      ..lineTo(
        at(tipStart, _bladeWidth / 2).dx,
        at(tipStart, _bladeWidth / 2).dy,
      )
      ..lineTo(
        at(_bladeStart, _bladeWidth / 2).dx,
        at(_bladeStart, _bladeWidth / 2).dy,
      )
      ..close();
    final guardCenter = (_gripEnd + _bladeStart) / 2;
    final guard = quad(
      guardCenter - _guardThickness / 2,
      guardCenter + _guardThickness / 2,
      _guardWidth / 2,
    );
    final grip = quad(0, _gripEnd, _gripWidth / 2);
    return (
      blade: blade,
      guard: guard,
      grip: grip,
      bladeBase: at(_bladeStart, 0),
      bladeTip: at(1, 0),
    );
  }

  /// Mayor caja con la proporción del símbolo de defensa que cabe en [lane]
  /// con alto ≤ [maxHeight], centrada en [lane].
  static Rect fitDefense(Rect lane, double maxHeight) {
    final unit = _defenseUnitBounds();
    final aspect = unit.width / unit.height;
    var height = math.min(maxHeight, lane.height);
    if (height * aspect > lane.width) height = lane.width / aspect;
    if (height <= 0) {
      return Rect.fromCenter(center: lane.center, width: 0, height: 0);
    }
    return Rect.fromCenter(
      center: lane.center,
      width: height * aspect,
      height: height,
    );
  }

  /// Punto a [along] del eje (0 = extremo de la empuñadura, 1 = punta) y a
  /// [across] de él (positivo hacia abajo a la derecha), con largo total 1.
  static Offset _axisPoint(double along, double across) {
    final a = defenseAngleDegrees * math.pi / 180;
    final dir = Offset(math.cos(a), -math.sin(a)); // arriba a la derecha
    final normal = Offset(-dir.dy, dir.dx);
    return dir * along + normal * across;
  }

  /// Caja del símbolo con largo total 1, en las coordenadas de [_axisPoint].
  static Rect _defenseUnitBounds() {
    const tipStart = 1.0 - 2 * _bladeWidth;
    final guardCenter = (_gripEnd + _bladeStart) / 2;
    final points = [
      for (final s in [-1.0, 1.0]) ...[
        _axisPoint(0, s * _gripWidth / 2),
        _axisPoint(_gripEnd, s * _gripWidth / 2),
        _axisPoint(guardCenter - _guardThickness / 2, s * _guardWidth / 2),
        _axisPoint(guardCenter + _guardThickness / 2, s * _guardWidth / 2),
        _axisPoint(tipStart, s * _bladeWidth / 2),
      ],
      _axisPoint(1, 0),
    ];
    var left = points.first.dx, right = left;
    var top = points.first.dy, bottom = top;
    for (final p in points) {
      left = math.min(left, p.dx);
      right = math.max(right, p.dx);
      top = math.min(top, p.dy);
      bottom = math.max(bottom, p.dy);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }
}
