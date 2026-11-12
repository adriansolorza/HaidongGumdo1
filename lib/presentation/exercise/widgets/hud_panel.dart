import 'package:flutter/widgets.dart';

import '../../theme.dart';

/// Panel translúcido del HUD (Spec 004, FR-015; research R11): fondo oscuro
/// translúcido, borde blanco tenue y esquinas redondeadas. Sin desenfoque de
/// fondo (el boceto no lo usa y es caro por cuadro, research R13).
class HudPanel extends StatelessWidget {
  const HudPanel({
    super.key,
    required this.scale,
    required this.child,
    this.strong = false,
    this.alignment = CrossAxisAlignment.start,
    this.padding,
  });

  /// Escala del HUD (`SceneLayout.hudScale`).
  final double scale;
  final Widget child;

  /// Panel central (segundos): fondo y borde un poco más marcados.
  final bool strong;

  final CrossAxisAlignment alignment;

  /// Por defecto, 10 · s vertical y 22 · s horizontal.
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: strong ? AppColors.panelStrong : AppColors.panel,
        border: Border.all(
          color: strong ? AppColors.panelBorderStrong : AppColors.panelBorder,
          width: 1.5 * scale,
        ),
        borderRadius: BorderRadius.circular((strong ? 18 : 14) * scale),
      ),
      child: Padding(
        padding:
            padding ??
            EdgeInsets.symmetric(vertical: 10 * scale, horizontal: 22 * scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: alignment,
          children: [child],
        ),
      ),
    );
  }
}
