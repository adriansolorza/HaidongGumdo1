import 'package:flutter/material.dart';

import '../../theme.dart';

/// Número de la cuenta regresiva: grande, blanco y con contorno negro, para
/// leerse a 3 m sobre el dojang (Spec 004, FR-018).
///
/// El contorno se pinta con un `TextPainter` detrás del `Text` del relleno:
/// así hay un solo `Text` con el número en el árbol.
class CountdownText extends StatelessWidget {
  const CountdownText({super.key, required this.value});

  final int value;

  /// Grosor del contorno, en dp.
  static const strokeWidth = 10.0;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.displayLarge!
        .copyWith(color: AppColors.textPrimary, height: 1);
    final text = '$value';
    return CustomPaint(
      painter: _OutlinePainter(
        text: text,
        style: style,
        textScaler: MediaQuery.textScalerOf(context),
        textDirection: Directionality.of(context),
      ),
      child: Text(text, style: style),
    );
  }
}

class _OutlinePainter extends CustomPainter {
  _OutlinePainter({
    required this.text,
    required this.style,
    required this.textScaler,
    required this.textDirection,
  });

  final String text;
  final TextStyle style;
  final TextScaler textScaler;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(
          color: null,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = CountdownText.strokeWidth
            ..strokeJoin = StrokeJoin.round
            ..color = AppColors.outline,
        ),
      ),
      textDirection: textDirection,
      textScaler: textScaler,
    )..layout(maxWidth: size.width);
    painter
      ..paint(canvas, Offset.zero)
      ..dispose();
  }

  @override
  bool shouldRepaint(_OutlinePainter oldDelegate) =>
      oldDelegate.text != text ||
      oldDelegate.style != style ||
      oldDelegate.textScaler != textScaler ||
      oldDelegate.textDirection != textDirection;
}
