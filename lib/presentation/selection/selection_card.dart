import 'package:flutter/material.dart';

import '../theme.dart';

/// Tarjeta de nivel o patrón de la selección (Spec 004, FR-021 a FR-023;
/// contrato §3). La seleccionada se distingue por fondo blanco translúcido,
/// borde blanco, un anillo exterior y una palomita; nada amarillo.
class SelectionCard extends StatelessWidget {
  const SelectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.lines,
    required this.selected,
    required this.onTap,
    required this.scale,
  });

  final Widget icon;

  /// Ya en mayúsculas.
  final String title;

  /// Una o dos líneas de detalle.
  final List<String> lines;
  final bool selected;
  final VoidCallback onTap;

  /// Escala del boceto (`SceneLayout.hudScale`).
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final radius = BorderRadius.circular(18 * s);
    return Semantics(
      button: true,
      selected: selected,
      label: [title, ...lines].join(', '),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.cardSelectedRing,
                    spreadRadius: 4 * s,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: selected ? AppColors.cardSelected : AppColors.cardIdle,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: selected
                  ? AppColors.cardSelectedBorder
                  : AppColors.cardIdleBorder,
              width: 2 * s,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: AppColors.cardSelectedRing,
            highlightColor: AppColors.cardSelectedRing,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: 104 * s),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 14 * s,
                  horizontal: 20 * s,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 72 * s,
                      height: 72 * s,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.iconTile,
                        borderRadius: BorderRadius.circular(14 * s),
                      ),
                      child: SizedBox.square(dimension: 56 * s, child: icon),
                    ),
                    SizedBox(width: 18 * s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 28 * s,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2 * s,
                              height: 1.1,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          for (final (i, line) in lines.indexed)
                            Text(
                              line,
                              style: TextStyle(
                                fontSize: (i == 0 ? 17 : 15) * s,
                                fontWeight: FontWeight.w500,
                                color: i == 0
                                    ? AppColors.textSecondary
                                    : AppColors.textTertiary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (selected) ...[
                      SizedBox(width: 12 * s),
                      _Check(size: 30 * s),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Palomita blanca de la tarjeta seleccionada.
class _Check extends StatelessWidget {
  const _Check({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('selection-check'),
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: AppColors.textPrimary,
      shape: BoxShape.circle,
    ),
    child: Icon(
      Icons.check_rounded,
      size: size * 0.75,
      color: AppColors.onPrimaryButton,
    ),
  );
}
