import 'package:flutter/material.dart';

import '../../domain/settings/parameter_editor.dart';
import '../theme.dart';

/// Fila de un parámetro: nombre y pistas a la izquierda; `[−] valor [+]` a la
/// derecha (Spec 005, FR-004a, FR-005; contrato §4; research R7, R8).
class ParameterRow extends StatelessWidget {
  const ParameterRow({
    super.key,
    required this.field,
    required this.label,
    required this.hints,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    required this.scale,
    this.footer,
  });

  final ParameterField field;
  final String label;

  /// Explicación y rango, una línea cada uno.
  final List<String> hints;
  final String value;

  /// null desactiva el botón (mínimo o máximo vigente).
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final double scale;

  /// Contenido opcional debajo de las pistas (aviso de ajuste, US2).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Padding(
      key: Key('param-${field.name}'),
      padding: EdgeInsets.symmetric(vertical: 12 * s),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 24 * s,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                for (final hint in hints)
                  Text(
                    hint,
                    style: TextStyle(
                      fontSize: 16 * s,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (footer != null) ...[SizedBox(height: 8 * s), footer!],
              ],
            ),
          ),
          SizedBox(width: 16 * s),
          _StepButton(
            buttonKey: Key('dec-${field.name}'),
            icon: Icons.remove,
            semanticLabel: 'Bajar $label',
            onPressed: onDecrement,
            scale: s,
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: 120 * s),
            child: Text(
              value,
              key: Key('value-${field.name}'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28 * s,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          _StepButton(
            buttonKey: Key('inc-${field.name}'),
            icon: Icons.add,
            semanticLabel: 'Subir $label',
            onPressed: onIncrement,
            scale: s,
          ),
        ],
      ),
    );
  }
}

/// Botón circular − o +. Desactivado: borde tenue e ícono gris al 40 %, sin
/// rojo, azul ni amarillo (FR-018).
class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.buttonKey,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    required this.scale,
  });

  /// Va en el `OutlinedButton`, para que las pruebas lean `onPressed`
  /// (contrato §4).
  final Key buttonKey;
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final double scale;

  @override
  Widget build(BuildContext context) {
    // Al menos 48 dp para tocarlo con facilidad.
    final size = (56 * scale).clamp(48.0, double.infinity);
    final enabled = onPressed != null;
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: enabled,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: OutlinedButton(
          key: buttonKey,
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
            backgroundColor: AppColors.panelStrong,
            disabledBackgroundColor: AppColors.panel,
            foregroundColor: AppColors.textPrimary,
            disabledForegroundColor: AppColors.textTertiary.withValues(
              alpha: 0.4,
            ),
            side: BorderSide(
              color: enabled
                  ? AppColors.buttonBorder
                  : AppColors.cardIdleBorder,
              width: 1.5,
            ),
            splashFactory: enabled ? null : NoSplash.splashFactory,
          ),
          child: Icon(icon, size: size * 0.5),
        ),
      ),
    );
  }
}
