import 'package:flutter/rendering.dart';

import '../../../domain/catalog/enums.dart';
import '../../../domain/exercise/attack.dart';
import '../../../domain/exercise/exercise_snapshot.dart';
import '../../../domain/exercise/signal.dart';
import '../../scene/scene_layout.dart';
import '../../theme.dart';

/// Señal de respuesta en la mitad de la pantalla que indica `signal.screenSide`
/// (Spec 001: research R12, FR-015, FR-016). Defensa: sable blanco en planta.
/// Evasión (Spec 003, FR-006 a FR-009): flecha horizontal del color del sable,
/// apuntando al borde exterior, dentro del carril de `SceneLayout` (Spec 004).
class SignalPainter extends CustomPainter {
  const SignalPainter({
    required this.layout,
    required this.signal,
    required this.saberColor,
  });

  /// Carriles de señal fuera del alcance del oponente (Spec 004, research R5).
  final SceneLayout layout;

  final Signal signal;

  /// Color del sable en el mismo snapshot; solo lo usa la evasión
  /// (research R3).
  final SaberColor saberColor;

  /// Alto del símbolo respecto al alto disponible (mínimo 30 %, FR-016).
  static const _heightFraction = 0.6;

  /// Largo máximo de la flecha respecto al alto de la pantalla.
  static const _maxLengthFraction = 0.36;

  @override
  void paint(Canvas canvas, Size size) {
    switch (signal.responseType) {
      case ResponseType.defense:
        _paintDefenseSaber(canvas, size);
      case ResponseType.evasion:
        _paintEvasionArrow(canvas, size);
    }
  }

  /// Flecha horizontal (cuerpo rectangular y punta triangular), centrada en
  /// vertical, en el tramo entre el alcance del oponente y el 4 % del ancho
  /// desde el borde, anclada al borde exterior (data-model.md, research R4).
  /// Se construye la de la derecha y se refleja en `x` para la izquierda.
  void _paintEvasionArrow(Canvas canvas, Size size) {
    final fill = switch (saberColor) {
      SaberColor.blue => AppColors.saberBlue,
      SaberColor.red => AppColors.saberRed,
      SaberColor.white || SaberColor.yellow => null,
    };
    // Con señal visible el sable siempre es azul o rojo (FR-009).
    assert(fill != null, 'Señal de evasión con sable $saberColor');
    if (fill == null) return;

    final w = size.width;
    final h = size.height;
    // Se construye la flecha de la derecha en el carril derecho y se refleja.
    // El contorno sobresale media línea: se descuenta en los dos extremos
    // para que ningún píxel salga del carril.
    final lane = layout.rightLane;
    const halfStroke = kOutlineWidth / 2;
    final outer = lane.right - halfStroke;
    final innerLimit = lane.left + halfStroke;
    final length = (outer - innerLimit).clamp(0.0, h * _maxLengthFraction);
    if (length <= 0) return;

    final centerY = h / 2;
    final tail = outer - length;
    final tipBase = outer - 0.42 * length;
    final tipHalfHeight = 0.62 * length / 2;
    final bodyHalfHeight = 0.24 * length / 2;
    final mirror = signal.screenSide == Side.left;
    double x(double right) => mirror ? w - right : right;

    final arrow = Path()
      ..moveTo(x(tail), centerY - bodyHalfHeight)
      ..lineTo(x(tipBase), centerY - bodyHalfHeight)
      ..lineTo(x(tipBase), centerY - tipHalfHeight)
      ..lineTo(x(outer), centerY)
      ..lineTo(x(tipBase), centerY + tipHalfHeight)
      ..lineTo(x(tipBase), centerY + bodyHalfHeight)
      ..lineTo(x(tail), centerY + bodyHalfHeight)
      ..close();
    canvas
      ..drawPath(arrow, Paint()..color = fill)
      ..drawPath(
        arrow,
        Paint()
          ..color = AppColors.outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = kOutlineWidth
          ..strokeJoin = StrokeJoin.round,
      );
  }

  /// Ancho de la hoja respecto al de la empuñadura (FR-025a, plan.md D6).
  static const bladeToGripWidth = 0.75;

  /// Sable vertical visto desde arriba, en planta (FR-025a): hoja estrecha
  /// (se ve el lomo) que termina en punta, guarda vista de canto y empuñadura
  /// más gruesa. Relleno blanco con contorno.
  void _paintDefenseSaber(Canvas canvas, Size size) {
    final height = size.height * _heightFraction;
    // Centro de la mitad izquierda o derecha de la pantalla, vista por el usuario.
    final centerX = signal.screenSide == Side.left
        ? size.width * 0.18
        : size.width * 0.82;
    final top = (size.height - height) / 2;

    final gripWidth = height * 0.09;
    final bladeWidth = gripWidth * bladeToGripWidth;
    final bladeHeight = height * 0.7;
    final tipLength = bladeWidth * 2;
    final guardWidth = height * 0.26;
    final guardHeight = height * 0.045;

    final blade = Path()
      ..moveTo(centerX, top)
      ..lineTo(centerX + bladeWidth / 2, top + tipLength)
      ..lineTo(centerX + bladeWidth / 2, top + bladeHeight)
      ..lineTo(centerX - bladeWidth / 2, top + bladeHeight)
      ..lineTo(centerX - bladeWidth / 2, top + tipLength)
      ..close();
    final guard = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, top + bladeHeight + guardHeight / 2),
        width: guardWidth,
        height: guardHeight,
      ),
      Radius.circular(guardHeight / 2),
    );
    final grip = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        centerX - gripWidth / 2,
        top + bladeHeight + guardHeight,
        centerX + gripWidth / 2,
        top + height,
      ),
      Radius.circular(gripWidth / 2),
    );

    final symbol = Path()
      ..addPath(blade, Offset.zero)
      ..addRRect(guard)
      ..addRRect(grip);
    canvas
      ..drawPath(symbol, Paint()..color = AppColors.saberWhite)
      ..drawPath(
        symbol,
        Paint()
          ..color = AppColors.outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = kOutlineWidth
          ..strokeJoin = StrokeJoin.round,
      );
  }

  @override
  bool shouldRepaint(SignalPainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.signal != signal ||
      oldDelegate.saberColor != saberColor;
}
