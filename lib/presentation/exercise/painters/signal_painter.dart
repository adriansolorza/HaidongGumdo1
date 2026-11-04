import 'package:flutter/rendering.dart';

import '../../../domain/catalog/enums.dart';
import '../../../domain/exercise/attack.dart';
import '../../../domain/exercise/signal.dart';
import '../../theme.dart';

/// Señal de respuesta en la mitad de la pantalla que indica `signal.screenSide`
/// (research R12, FR-015, FR-016).
class SignalPainter extends CustomPainter {
  const SignalPainter({required this.signal});

  final Signal signal;

  /// Alto del símbolo respecto al alto disponible (mínimo 30 %, FR-016).
  static const _heightFraction = 0.6;

  @override
  void paint(Canvas canvas, Size size) {
    switch (signal.responseType) {
      case ResponseType.defense:
        _paintDefenseSaber(canvas, size);
    }
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
  bool shouldRepaint(SignalPainter oldDelegate) => oldDelegate.signal != signal;
}
