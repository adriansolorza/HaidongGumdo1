import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/catalog/catalog.dart';
import '../../../domain/exercise/session.dart';
import '../../providers.dart';
import '../../scene/scene_layout.dart';
import '../../theme.dart';
import '../exercise_controller.dart';
import 'hud_panel.dart';

/// HUD superior del ejercicio (Spec 004, FR-015; data-model §7):
/// - izquierda: nivel en mayúsculas y su respuesta;
/// - centro: segundos restantes y barra de progreso respecto de la duración;
/// - derecha: patrón en mayúsculas y la secuencia postura → corte.
///
/// Todos los textos salen de la sesión y del catálogo (Spec 001, SC-009). Todo
/// el HUD queda dentro de la franja `[0, layout.hudBottom]` (FR-017).
class ExerciseHud extends ConsumerWidget {
  const ExerciseHud({
    super.key,
    required this.layout,
    required this.session,
    required this.catalog,
  });

  final SceneLayout layout;
  final Session session;

  /// Para el hangul de los términos; si no está, solo la romanización.
  final Catalog? catalog;

  static const levelPanelKey = Key('hud-level');
  static const timerPanelKey = Key('hud-timer');
  static const patternPanelKey = Key('hud-pattern');
  static const progressKey = Key('hud-progress');

  /// Ancho del panel central en el boceto.
  static const _timerWidth = 150.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = layout.hudScale;
    final w = layout.size.width;
    final remaining = ref.watch(
      exerciseControllerProvider.select((snapshot) => snapshot.remaining),
    );
    final duration = ref.watch(exerciseParametersProvider).duration;
    final progress = (1 - remaining.inMicroseconds / duration.inMicroseconds)
        .clamp(0.0, 1.0);
    final seconds = (remaining.inMilliseconds / 1000).ceil();

    // Ancho máximo de los paneles laterales: no tocan el central.
    final sideMax = (w - _timerWidth * s) / 2 - 36 * s - 16 * s;

    TextStyle title() => TextStyle(
      fontSize: 30 * s,
      fontWeight: FontWeight.w700,
      letterSpacing: 2 * s,
      height: 1.1,
      color: AppColors.textPrimary,
    );
    TextStyle subtitle() => TextStyle(
      fontSize: 16 * s,
      fontWeight: FontWeight.w500,
      height: 1.2,
      color: AppColors.textSecondary,
    );

    Widget side(Key key, String top, String bottom, CrossAxisAlignment align) =>
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: sideMax > 0 ? sideMax : 0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: align == CrossAxisAlignment.end
                ? Alignment.topRight
                : Alignment.topLeft,
            child: HudPanel(
              key: key,
              scale: s,
              alignment: align,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: align,
                children: [
                  Text(top, style: title()),
                  Text(bottom, style: subtitle()),
                ],
              ),
            ),
          ),
        );

    final pattern = session.pattern;
    return Stack(
      children: [
        Positioned(
          left: 36 * s,
          top: 24 * s,
          child: side(
            levelPanelKey,
            session.level.name.toUpperCase(),
            session.level.responseLabel,
            CrossAxisAlignment.start,
          ),
        ),
        Positioned(
          right: 36 * s,
          top: 24 * s,
          child: side(
            patternPanelKey,
            pattern.name.toUpperCase(),
            '${_termLabel(pattern.stanceTermId)} → '
            '${_termLabel(pattern.cutTermId)}',
            CrossAxisAlignment.end,
          ),
        ),
        Positioned(
          top: 18 * s,
          left: (w - _timerWidth * s) / 2,
          width: _timerWidth * s,
          child: HudPanel(
            key: timerPanelKey,
            scale: s,
            strong: true,
            alignment: CrossAxisAlignment.center,
            padding: EdgeInsets.fromLTRB(16 * s, 8 * s, 16 * s, 12 * s),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Alto fijo de 64 · s; si el número no cabe a lo ancho (p. ej.
                // tres cifras), se reduce en lugar de partirse en dos líneas.
                SizedBox(
                  height: 64 * s,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$seconds',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 64 * s,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 6 * s),
                Container(
                  height: 6 * s,
                  decoration: BoxDecoration(
                    color: AppColors.progressTrack,
                    borderRadius: BorderRadius.circular(3 * s),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    key: progressKey,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.progressFill,
                        borderRadius: BorderRadius.circular(3 * s),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Romanización seguida del hangul, si el término lo tiene (Principio IX).
  String _termLabel(String termId) {
    final term = catalog?.term(termId);
    if (term == null) return termId;
    return term.hangul == null
        ? term.romanization
        : '${term.romanization} ${term.hangul}';
  }
}
